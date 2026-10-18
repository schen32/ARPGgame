from pathlib import Path
import math, random, struct, wave

# Original, deterministic billiard-inspired impacts; no external samples.
ROOT = Path(__file__).resolve().parents[1] / 'GodotStarter' / 'audio' / 'impacts'
RATE = 44100

def impact(kind, variant):
    rng = random.Random(17021 + variant * 719 + (1000 if kind == 'ball' else 0))
    duration = 0.16 if kind == 'ball' else 0.105
    count = round(duration * RATE)
    samples = []
    low_noise = 0.0
    mode_scale = 1 + (variant - 1) * 0.065
    # Rapidly damped, inharmonic modes give a hard resin-ball clack rather than a bell.
    modes = [(510, .013, .38), (1320, .009, .27), (2730, .005, .20), (4170, .003, .12)] if kind == 'ball' else [(820, .008, .31), (1840, .0045, .25), (3470, .0028, .16)]
    for i in range(count):
        t = i / RATE
        noise = rng.uniform(-1, 1)
        low_noise += .28 * (noise - low_noise)
        attack = 1 - math.exp(-t / .00009)
        body = sum(amp * math.sin(2 * math.pi * freq * mode_scale * t) * math.exp(-t / decay) for freq, decay, amp in modes)
        contact = (noise - low_noise) * math.exp(-t / (.0015 if kind == 'ball' else .0010)) * .60
        knock = math.sin(2 * math.pi * (220 if kind == 'ball' else 360) * t) * math.exp(-t / .005) * .14
        samples.append((body + contact + knock) * attack)
    # Small, diffuse room reflections, well below the dry transient.
    dry = samples[:]
    for delay, gain in [(0.011, .055), (0.019, .035), (0.031, .018)]:
        offset = round(delay * RATE)
        for i in range(offset, count):
            samples[i] += dry[i - offset] * gain
    peak = max(abs(x) for x in samples)
    samples = [x * .76 / peak for x in samples]
    path = ROOT / f'{kind}_{variant + 1}.wav'
    with wave.open(str(path), 'wb') as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(b''.join(struct.pack('<h', round(max(-1, min(1, x)) * 32767)) for x in samples))

if __name__ == '__main__':
    ROOT.mkdir(parents=True, exist_ok=True)
    for kind in ['cue', 'ball']:
        for variant in range(3):
            impact(kind, variant)
    print('Generated six original PCM billiard-style impacts.')
