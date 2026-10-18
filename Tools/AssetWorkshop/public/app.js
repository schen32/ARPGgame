const $ = id => document.getElementById(id);
const escape = value => String(value ?? '').replace(/[&<>"']/g, c => ({ '&':'&amp;', '<':'&lt;', '>':'&gt;', '"':'&quot;', "'":'&#39;' }[c]));
let state, current = null, revision = null, selectedReference = null, pending = false;
let subscription = { checking:true, connected:false }, noticeTimer, saveTimer, saveChain = Promise.resolve();
const preset = () => state.presets.find(p => p.id === $('preset').value) || state.presets[0];
const candidate = id => state.candidates.find(c => c.id === id);
function notice(message, error = false) { clearTimeout(noticeTimer); $('notice').textContent = message; $('notice').className = error ? 'error' : ''; $('notice').hidden = false; noticeTimer = setTimeout(() => $('notice').hidden = true, error ? 16000 : 5000); }
function action(fn) { return async event => { try { await fn(event); } catch (error) { notice(error.message, true); } }; }
async function api(route, body) {
  const response = await fetch(`/api/${route}`, body === undefined ? {} : { method:'POST', headers:{'Content-Type':'application/json','X-Workshop-Token':state.token}, body:JSON.stringify(body) });
  const result = await response.json(); if (!response.ok) throw new Error(result.error || 'Request failed.'); return result;
}
async function refreshState() { state = await api('state'); $('history-count').textContent = state.candidates.length; }
function saveStatus(text, error = false) { $('save-status').textContent = text; $('save-status').classList.toggle('error', error); }
function styleDirty() { return state?.workspace && $('style').value.trim() !== state.workspace.style; }
function flushStyle() {
  clearTimeout(saveTimer);
  saveChain = saveChain.catch(() => {}).then(async () => {
    try {
      while (styleDirty()) {
        const style = $('style').value.trim(); if (!style) throw new Error('Add a short style description so your assets stay consistent.');
        saveStatus('Saving…'); state.workspace = await api('workspace', {style});
      }
      saveStatus('All changes saved');
    } catch (error) { saveStatus('Could not save', true); throw error; }
  });
  return saveChain;
}
$('style').oninput = () => { clearTimeout(saveTimer); saveStatus('Saving…'); saveTimer = setTimeout(() => flushStyle().catch(error => notice(error.message, true)), 650); };
$('style').onblur = action(flushStyle);
function updateConnection() {
  $('connection').classList.toggle('connected', subscription.connected);
  $('connection').querySelector('span').textContent = subscription.checking ? 'Connecting…' : subscription.connected ? 'Subscription ready' : 'Sign in to Codex';
  $('connection-help').hidden = subscription.checking || subscription.connected;
  $('connection-message').textContent = subscription.message || 'Run codex login and choose ChatGPT, then check the connection.';
  $('subscription-message').textContent = subscription.checking ? 'Checking your Codex sign-in…' : subscription.connected ? `Connected with your ${subscription.plan} plan.` : subscription.message;
}
async function refreshSubscription() {
  subscription.checking = true; updateConnection();
  try { subscription = await api('subscription/status'); }
  catch (error) { subscription = {connected:false,message:error.message}; }
  updateConnection();
}
$('connection').onclick = () => $('settings-dialog').showModal();
$('refresh-subscription').onclick = action(refreshSubscription); $('retry-connection').onclick = action(refreshSubscription);
$('open-settings').onclick = () => $('settings-dialog').showModal();
document.querySelectorAll('[data-close]').forEach(button => button.onclick = () => $(button.dataset.close).close());
function renderReferences() {
  const refs = state.workspace.referenceIds.map(id => state.references.find(r => r.id === id)).filter(Boolean);
  $('references').innerHTML = refs.length ? refs.map(r => `<button class="reference-tile" data-reference="${r.id}" aria-label="Edit reference ${escape(r.name)}"><img src="${r.url}" alt="${escape(r.name)}"><span>${escape(({style:'Style',moodboard:'Mood',composition:'Shape'})[r.role])}</span></button>`).join('') : '<div class="reference-empty">Drop in the look you love.<small>Add a moodboard or an approved asset.</small></div>';
  $('references').querySelectorAll('[data-reference]').forEach(button => button.onclick = () => { selectedReference = state.references.find(r => r.id === button.dataset.reference); $('reference-title').textContent = selectedReference.name; $('reference-image').src = selectedReference.url; $('reference-role').value = selectedReference.role; $('reference-dialog').showModal(); });
}
$('reference-role').onchange = action(async () => { await flushStyle(); await api('references/role', {useWorkspace:true,referenceId:selectedReference.id,role:$('reference-role').value}); await refreshState(); renderReferences(); notice('Reference updated.'); });
$('remove-reference').onclick = action(async () => { await flushStyle(); await api('references/detach', {useWorkspace:true,referenceId:selectedReference.id}); await refreshState(); renderReferences(); $('reference-dialog').close(); });
async function readFile(file) {
  if (file.size > 15 * 1024 * 1024) throw new Error('Choose a PNG, JPEG, or WebP smaller than 15 MB.');
  return new Promise((resolve,reject) => { const reader = new FileReader(); reader.onload = () => resolve(reader.result); reader.onerror = () => reject(new Error('Cannot read this image.')); reader.readAsDataURL(file); });
}
async function uploadReference(file) { await flushStyle(); await api('references', {useWorkspace:true,name:file.name,role:'style',dataUrl:await readFile(file)}); await refreshState(); renderReferences(); }
$('upload-reference').onclick = () => $('reference-file').click();
$('reference-file').onchange = action(async event => { const file = event.target.files[0]; event.target.value=''; if(file)await uploadReference(file); });
$('references').ondragover = event => event.preventDefault();
$('references').ondrop = action(async event => { event.preventDefault(); const file=event.dataTransfer.files[0]; if(file)await uploadReference(file); });
$('add-project-reference').onclick = action(async () => { if(!$('project-image').value)throw new Error('Choose a project image first.'); await flushStyle(); await api('references/project', {useWorkspace:true,path:$('project-image').value,role:'style'}); await refreshState(); renderReferences(); $('settings-dialog').close(); notice('Reference added.'); });
function renderRevision() { $('revision').hidden=!revision; $('generate').innerHTML=revision?'Apply changes <span>↗</span>':'Generate <span>↗</span>'; if(!revision)$('instruction').value=''; }
$('cancel-revision').onclick=()=>{revision=null;renderRevision();};
$('preset').onchange=()=>{revision=null;renderRevision();};
function brief() { return {presetId:preset().id,useWorkspace:true,description:$('description').value,parentId:revision?.id,instruction:$('instruction').value}; }
function busy(value) { pending=value; $('progress').hidden=!value; for(const id of ['generate','keep','refine','another'])$(id).disabled=value; if(value)$('generate').textContent='Generating…';else renderRevision(); }
async function generate() {
  if(pending||state.busy)throw new Error('An image is already being generated.');
  if(!$('description').value.trim()){$('description').focus();throw new Error('Describe the asset you want to make.');}
  if(revision&&!$('instruction').value.trim()){$('instruction').focus();throw new Error('Describe what should change.');}
  busy(true);
  try {
    await flushStyle(); if(!subscription.connected)await refreshSubscription();
    if(!subscription.connected){$('settings-dialog').showModal();return;}
    const result=await api('generate',{...brief(),provider:'subscription',quality:'medium',count:1});
    await refreshState(); revision=null; current=candidate(result.candidates[0].id); renderRevision(); renderResult(); notice(result.warning||'Your image is ready.',Boolean(result.warning));
  }finally{busy(false);}
}
$('generate').onclick=action(generate);
function selectCandidate(c) { current=c;revision=null;$('description').value=c.description;$('preset').value=c.presetId;renderRevision();renderResult(); }
function renderResult() {
  $('result-controls').hidden=!current; $('stage').classList.toggle('has-image',Boolean(current));
  if(!current){$('result-heading').textContent='Your next asset';$('result-kind').textContent='';renderRecent();return;}
  $('result-heading').textContent=current.approved?'Kept in your collection':'Make it yours';$('result-kind').textContent=current.presetSnapshot.name;
  $('stage').innerHTML=`<img src="${current.url}" alt="${escape(current.description)}">`;
  $('keep').hidden=current.approved;$('download').hidden=!current.approved;$('use-reference').hidden=!current.approved;
  const p=current.presetSnapshot,exact=`${p.width}x${p.height}`;
  $('export-size').querySelectorAll('[data-original]').forEach(option=>option.remove());
  if(p.width===p.height&&[32,64,128,256,512].includes(p.width))$('export-size').value=String(p.width);
  else{const option=new Option(`${p.width} × ${p.height}`,exact);option.dataset.original='true';$('export-size').add(option);$('export-size').value=exact;}
  $('pixelated').checked=p.pixelated;$('actual-image').src=current.url;updateActualSize();renderRecent();
}
function exportDimensions(){const v=$('export-size').value.split('x').map(Number);return{width:v[0],height:v[1]||v[0]};}
function updateActualSize(){if(!current)return;const{width,height}=exportDimensions(),scale=Math.min(1,80/Math.max(width,height));$('actual-image').width=Math.round(width*scale);$('actual-image').height=Math.round(height*scale);$('actual-image').style.imageRendering=$('pixelated').checked?'pixelated':'auto';$('actual-label').textContent=`${width} × ${height}${scale<1?' preview':' actual size'}`;}
$('export-size').onchange=updateActualSize;$('pixelated').onchange=updateActualSize;
$('keep').onclick=action(async()=>{if(!current)return;await api('candidates/approve',{id:current.id,approved:true});const id=current.id;await refreshState();current=candidate(id);renderResult();notice('Kept. Download it whenever you’re ready.');});
$('refine').onclick=()=>{if(!current)return;revision=current;$('preset').value=current.presetId;$('description').value=current.description;renderRevision();$('instruction').focus();};
$('another').onclick=action(async()=>{if(!current)return;$('preset').value=current.presetId;$('description').value=current.description;revision=null;renderRevision();await generate();});
$('use-reference').onclick=action(async()=>{await flushStyle();await api('candidates/reference',{id:current.id,useWorkspace:true});await refreshState();renderReferences();notice('Added to your project’s style references.');});
$('download').onclick=action(async()=>{
  $('download').disabled=true;
  try{
    const c=current,{width,height}=exportDimensions(),pixelated=$('pixelated').checked;
    const image=new Image();image.src=c.url;await image.decode();
    const canvas=document.createElement('canvas');canvas.width=width;canvas.height=height;
    const ctx=canvas.getContext('2d');ctx.imageSmoothingEnabled=!pixelated;ctx.imageSmoothingQuality='high';
    const scale=Math.min(width/image.naturalWidth,height/image.naturalHeight),w=Math.round(image.naturalWidth*scale),h=Math.round(image.naturalHeight*scale);
    ctx.drawImage(image,Math.floor((width-w)/2),Math.floor((height-h)/2),w,h);
    const result=await api('export',{id:c.id,dataUrl:canvas.toDataURL('image/png'),width,height,pixelated});
    const link=document.createElement('a');link.href=result.image;link.download=`${result.name}.png`;document.body.append(link);link.click();link.remove();notice('PNG downloaded. A generation record is saved beside the export.');
  }finally{$('download').disabled=false;}
});
function renderRecent(){const recent=state.candidates.slice(0,8);$('recent').innerHTML=recent.length>1?recent.map(c=>`<button data-select="${c.id}" class="${c.id===current?.id?'active':''}" aria-label="View ${escape(c.description)}"><img src="${c.url}" alt="${escape(c.description)}"></button>`).join(''):'';bindSelections($('recent'));}
function bindSelections(container){container.querySelectorAll('[data-select]').forEach(b=>b.onclick=()=>{selectCandidate(candidate(b.dataset.select));$('history-dialog').close();});}
function renderHistory(){const term=$('search').value.toLowerCase();const items=state.candidates.filter(c=>c.description.toLowerCase().includes(term)&&($('history-filter').value!=='kept'||c.approved));$('history').innerHTML=items.length?items.map(c=>`<button class="history-item" data-select="${c.id}"><img src="${c.url}" alt="${escape(c.description)}" loading="lazy"><p>${escape(c.description)}</p><small>${c.approved?'✓ Kept':escape(c.presetSnapshot.name)}</small></button>`).join(''):'<p class="history-empty">Your images will be saved here as you create them.</p>';bindSelections($('history'));}
$('open-history').onclick=()=>{renderHistory();$('history-dialog').showModal();};$('search').oninput=renderHistory;$('history-filter').onchange=renderHistory;
$('import-candidate').onclick=()=>$('candidate-file').click();
$('candidate-file').onchange=action(async event=>{const file=event.target.files[0];event.target.value='';if(!file)return;await flushStyle();const result=await api('candidates/import',{presetId:preset().id,useWorkspace:true,description:$('description').value.trim()||file.name.replace(/\.[^.]+$/,''),dataUrl:await readFile(file)});await refreshState();selectCandidate(candidate(result.id));$('history-dialog').close();});
$('prompt-details').ontoggle=action(async()=>{if(!$('prompt-details').open)return;if(!$('description').value.trim()){$('prompt-preview').textContent='Describe an asset first.';return;}await flushStyle();$('prompt-preview').textContent=(await api('prompt',brief())).prompt;});
window.addEventListener('beforeunload',event=>{if(styleDirty()||pending){event.preventDefault();event.returnValue='';}});
try{
  await refreshState();
  if(!state.workspace) {
    // Older running servers serve the current static files. Send their browser
    // to the updated backend before allowing any writes to the shared library.
    if(location.port==='4317')location.replace(`${location.protocol}//${location.hostname}:4319/`);
    throw new Error('Opening the updated workshop. If it does not open, run Start-Workshop.cmd.');
  }
  $('style').value=state.workspace.style;
  $('preset').innerHTML=state.presets.map(p=>`<option value="${escape(p.id)}">${escape(p.name)}</option>`).join('');renderReferences();
  if(state.candidates.length)selectCandidate(state.candidates[0]);else renderRecent();
  refreshSubscription();const images=await api('project-images');$('project-image').innerHTML+=images.map(i=>`<option value="${escape(i.path)}">${escape(i.path)}</option>`).join('');
  if(state.busy){busy(true);const poll=setInterval(async()=>{try{await refreshState();if(!state.busy){clearInterval(poll);busy(false);if(state.candidates[0])selectCandidate(state.candidates[0]);}}catch{clearInterval(poll);busy(false);notice('Reload to check the running generation.',true);}},4000);}
}catch(error){notice(`Could not load workshop: ${error.message}`,true);}
