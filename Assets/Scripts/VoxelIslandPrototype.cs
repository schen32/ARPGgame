using UnityEngine;
using UnityEngine.InputSystem;

/// <summary>
/// Builds a small voxel island combat prototype when Main enters Play mode.
/// Controls: WASD/Arrows move, Space or Left Click attacks, Q dashes, E pulses, R heals.
/// </summary>
public sealed class VoxelIslandPrototype : MonoBehaviour
{
    private const int IslandRadius = 8;
    private const float GroundTop = 1f;

    private GameObject assetPack;
    private GameObject grassTileAsset;
    private GameObject pathTileAsset;
    private GameObject stoneAsset;
    private GameObject heroAsset;
    private GameObject slimeAsset;
    private GameObject player;
    private GameObject slime;
    private Transform slimeVisual;
    private GameObject attackRing;
    private GameObject slashEffect;
    private GameObject skeleton;
    private Transform skeletonVisual;
    private Camera gameCamera;

    private float playerHealth = 100f;
    private float enemyHealth = 100f;
    private float skeletonHealth = 140f;
    private float nextPlayerAttack;
    private float nextEnemyAttack;
    private float nextDash;
    private float nextPulse;
    private float nextHeal;
    private float ringVisibleUntil;
    private float enemyRespawnAt;
    private float skeletonRespawnAt;
    private bool enemyAlive = true;
    private bool skeletonAlive = true;
    private float skeletonAttackAt;
    private Vector3 playerSpawn;

    private void Awake()
    {
        assetPack = Resources.Load<GameObject>("PrototypeVoxelAssets");
        if (assetPack == null)
        {
            Debug.LogError("Voxel prototype could not load Resources/PrototypeVoxelAssets.fbx.");
            return;
        }

        grassTileAsset = FindAsset("Block_GrassTile");
        pathTileAsset = FindAsset("Block_PathTile");
        stoneAsset = FindAsset("Block_Stone");
        heroAsset = FindAsset("Hero_MainCharacter");
        slimeAsset = FindAsset("Enemy_RedSlime");

        if (grassTileAsset == null || pathTileAsset == null || stoneAsset == null ||
            heroAsset == null || slimeAsset == null)
        {
            Debug.LogError("Voxel prototype is missing one or more named models in PrototypeVoxelAssets.fbx.");
            return;
        }

        BuildWater();
        BuildIsland();
        BuildCharacters();
        SetupCameraAndLighting();
        BuildAttackRing();
    }

private void Update()
{
    if (player == null || slime == null || gameCamera == null)
        return;

    Vector3 playerPosition = player.transform.position;
    playerPosition.x = Mathf.Clamp(playerPosition.x, -IslandRadius + 0.45f, IslandRadius - 0.45f);
    playerPosition.z = Mathf.Clamp(playerPosition.z, -IslandRadius + 0.45f, IslandRadius - 0.45f);
    playerPosition.y = GroundTop;
    player.transform.position = playerPosition;

    UpdateSlime();
    UpdateSkeleton();
    UpdatePlayerActions();

    if (attackRing != null && Time.time > ringVisibleUntil)
        attackRing.SetActive(false);
    if (slashEffect != null && Time.time > slashEffect.GetComponent<SlashLifetime>().ExpiresAt)
        slashEffect.SetActive(false);
}

private void LateUpdate()
{
    if (player == null || gameCamera == null)
        return;

    Vector3 cameraTarget = player.transform.position + Vector3.up * 0.6f;
    gameCamera.transform.position = cameraTarget + new Vector3(12f, 12f, -12f);
    gameCamera.transform.LookAt(cameraTarget);
}

    private GameObject FindAsset(string objectName)
    {
        Transform[] objects = assetPack.GetComponentsInChildren<Transform>(true);
        for (int i = 0; i < objects.Length; i++)
        {
            if (objects[i].name == objectName)
                return objects[i].gameObject;
        }
        return null;
    }

    private GameObject SpawnModel(GameObject source, Transform parent, string instanceName,
        Vector3 localPosition, Quaternion localRotation, Vector3 localScale)
    {
        GameObject instance = Instantiate(source, parent);
        instance.name = instanceName;
        instance.transform.localPosition = localPosition;
        instance.transform.localRotation = localRotation;
        instance.transform.localScale = localScale;
        return instance;
    }

    private void BuildWater()
    {
        GameObject water = GameObject.CreatePrimitive(PrimitiveType.Cube);
        water.name = "Ocean";
        water.transform.position = new Vector3(0f, -1.45f, 0f);
        water.transform.localScale = new Vector3(60f, 0.35f, 60f);
        water.GetComponent<Renderer>().material.color = new Color(0.035f, 0.58f, 0.72f);
    }

    private void BuildIsland()
    {
        GameObject island = new GameObject("Voxel Island");
        for (int x = -IslandRadius; x <= IslandRadius; x++)
        {
            for (int z = -IslandRadius; z <= IslandRadius; z++)
            {
                if (Mathf.Abs(x) == IslandRadius && Mathf.Abs(z) == IslandRadius)
                    continue;

                bool path = Mathf.Abs(x) <= 1 || Mathf.Abs(z) <= 1;
                GameObject tile = path ? pathTileAsset : grassTileAsset;
                SpawnModel(tile, island.transform, path ? "Warm Sand Path" : "Grass Tile",
                    new Vector3(x, 0f, z), Quaternion.identity, Vector3.one);
            }
        }

        // Layer the floating island with chunky dirt blocks beneath the grassy rim.
        GameObject dirtAsset = FindAsset("Block_Dirt");
        for (int x = -IslandRadius; x <= IslandRadius; x++)
        {
            for (int z = -IslandRadius; z <= IslandRadius; z++)
            {
                if (Mathf.Abs(x) != IslandRadius && Mathf.Abs(z) != IslandRadius) continue;
                for (int layer = 0; layer < 2; layer++)
                {
                    Vector3 edge = new Vector3(x, -0.43f - layer * 0.48f, z);
                    if (dirtAsset != null)
                        SpawnModel(dirtAsset, island.transform, "Layered Island Earth", edge, Quaternion.identity, Vector3.one);
                    else
                        CreateColorCube("Layered Island Earth", edge, new Vector3(1f, .48f, 1f), new Color(.48f, .29f, .18f));
                }
            }
        }

        // One simple invisible collider lets the player walk over the decorative mesh tiles.
        GameObject walkable = GameObject.CreatePrimitive(PrimitiveType.Cube);
        walkable.name = "Walkable Island Surface";
        walkable.transform.position = new Vector3(0f, 0.86f, 0f);
        walkable.transform.localScale = new Vector3(IslandRadius * 2f + 0.9f, 0.28f, IslandRadius * 2f + 0.9f);
        walkable.GetComponent<Renderer>().enabled = false;

        // Small stone piles echo the reference scene and give the island some landmarks.
        SpawnModel(stoneAsset, island.transform, "Stone Pile Lower", new Vector3(5.9f, 0f, 5.4f),
            Quaternion.identity, new Vector3(0.78f, 0.78f, 0.78f));
        SpawnModel(stoneAsset, island.transform, "Stone Pile Upper", new Vector3(6.05f, 0.72f, 5.4f),
            Quaternion.identity, new Vector3(0.58f, 0.58f, 0.58f));
        SpawnModel(stoneAsset, island.transform, "Stone Pile Side", new Vector3(6.45f, 0f, 5.5f),
            Quaternion.identity, new Vector3(0.68f, 0.68f, 0.68f));
        SpawnModel(stoneAsset, island.transform, "Stone Marker", new Vector3(-6.4f, 0f, -5.6f),
            Quaternion.identity, new Vector3(0.88f, 0.88f, 0.88f));

        // Keep the central fighting lanes open and cluster voxel foliage around the perimeter.
        Vector3[] treeSpots = { new Vector3(-6f, 0f, 6f), new Vector3(6f, 0f, -6f), new Vector3(-7f, 0f, -2f), new Vector3(7f, 0f, 3f) };
        foreach (Vector3 spot in treeSpots) CreateVoxelTree(island.transform, spot);
        for (int i = 0; i < 22; i++)
        {
            Vector2 p = Random.insideUnitCircle.normalized * Random.Range(5.5f, 7.8f);
            if (Mathf.Abs(p.x) < 2.2f || Mathf.Abs(p.y) < 2.2f) continue;
            CreateBush(island.transform, new Vector3(p.x, 0f, p.y));
        }
        CreateRockCluster(island.transform, new Vector3(2.9f, 0f, -3.1f));
        CreateRockCluster(island.transform, new Vector3(-4.2f, 0f, 4.4f));
    }

    private void CreateVoxelTree(Transform parent, Vector3 position)
    {
        CreateColorCube("Tree Trunk", position + Vector3.up * .75f, new Vector3(.72f, 1.5f, .72f), new Color(.39f, .22f, .12f), parent);
        Color[] greens = { new Color(.25f, .62f, .12f), new Color(.31f, .72f, .15f), new Color(.19f, .53f, .11f) };
        Vector3[] canopy = { Vector3.up * 1.8f, Vector3.up * 2.5f, new Vector3(.62f, 2.1f, 0f), new Vector3(-.62f, 2.1f, 0f), new Vector3(0f, 2.1f, .62f), new Vector3(0f, 2.1f, -.62f) };
        for (int i = 0; i < canopy.Length; i++)
            CreateColorCube("Tree Canopy", position + canopy[i], Vector3.one * (i == 0 ? 1.25f : .95f), greens[i % greens.Length], parent);
    }

    private void CreateBush(Transform parent, Vector3 position)
    {
        CreateColorCube("Voxel Shrub", position + Vector3.up * .38f, new Vector3(.72f, .76f, .72f), new Color(.26f, .61f, .13f), parent);
        CreateColorCube("Voxel Shrub", position + new Vector3(.42f, .28f, .08f), new Vector3(.5f, .55f, .52f), new Color(.34f, .72f, .16f), parent);
    }

    private void CreateRockCluster(Transform parent, Vector3 position)
    {
        Vector3[] offsets = { Vector3.zero, new Vector3(.55f, .32f, .1f), new Vector3(-.42f, .25f, -.18f), new Vector3(.12f, .62f, -.1f) };
        for (int i = 0; i < offsets.Length; i++)
            SpawnModel(stoneAsset, parent, "Broken Stone", position + offsets[i], Quaternion.Euler(0f, i * 31f, 0f), Vector3.one * (i == 3 ? .55f : .7f));
    }

    private void CreateColorCube(string name, Vector3 position, Vector3 size, Color color, Transform parent = null)
    {
        GameObject cube = GameObject.CreatePrimitive(PrimitiveType.Cube);
        cube.name = name;
        cube.transform.position = position;
        cube.transform.localScale = size;
        if (parent != null) cube.transform.SetParent(parent, true);
        cube.GetComponent<Renderer>().material.color = color;
    }

    private void BuildCharacters()
    {
        playerSpawn = new Vector3(-1.2f, GroundTop, -4.2f);
        player = new GameObject("Player");
        player.tag = "Player";
        player.transform.position = playerSpawn;
        player.AddComponent<CapsuleCollider>();
        player.AddComponent<PlayerMovement>();
        SpawnModel(heroAsset, player.transform, "Hero Visual", Vector3.zero,
            Quaternion.Euler(0f, 180f, 0f), Vector3.one);

        slime = new GameObject("Enemy - Red Slime");
        slime.transform.position = new Vector3(1.8f, GroundTop, 2.1f);
        slime.AddComponent<BoxCollider>().size = new Vector3(0.8f, 0.9f, 0.7f);
        slimeVisual = SpawnModel(slimeAsset, slime.transform, "Red Slime Visual", Vector3.zero,
            Quaternion.identity, Vector3.one).transform;

        skeleton = new GameObject("Enemy - Bone Guard");
        skeleton.transform.position = new Vector3(5.1f, GroundTop, 2.4f);
        skeletonVisual = CreateSkeletonVisual(skeleton.transform);
        BoxCollider skeletonHitbox = skeleton.AddComponent<BoxCollider>();
        skeletonHitbox.center = new Vector3(0f, .77f, 0f);
        skeletonHitbox.size = new Vector3(1.2f, 1.56f, .55f);
    }

private void SetupCameraAndLighting()
{
    gameCamera = Camera.main;
    if (gameCamera == null)
    {
        GameObject cameraObject = new GameObject("Main Camera");
        cameraObject.tag = "MainCamera";
        gameCamera = cameraObject.AddComponent<Camera>();
    }

    gameCamera.orthographic = true;
    gameCamera.orthographicSize = 10.2f;
    gameCamera.transform.position = player.transform.position + new Vector3(12f, 12f, -12f);
    gameCamera.transform.LookAt(player.transform.position + Vector3.up * 0.6f);
    gameCamera.clearFlags = CameraClearFlags.SolidColor;
    gameCamera.backgroundColor = new Color(0.02f, 0.66f, 0.80f);

    Light sceneLight = FindFirstObjectByType<Light>();
    if (sceneLight == null)
    {
        GameObject lightObject = new GameObject("Directional Light");
        sceneLight = lightObject.AddComponent<Light>();
        sceneLight.type = LightType.Directional;
    }

    sceneLight.transform.rotation = Quaternion.Euler(50f, -30f, 0f);
    sceneLight.intensity = 1.35f;
    sceneLight.shadows = LightShadows.Soft;
    RenderSettings.ambientLight = new Color(.78f, .84f, .9f);
}

    private void BuildAttackRing()
    {
        attackRing = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
        attackRing.name = "Slime Target Ring";
        attackRing.transform.localScale = new Vector3(1.25f, 0.018f, 1.25f);
        attackRing.GetComponent<Renderer>().material.color = new Color(1f, 0.55f, 0.04f);
        Collider ringCollider = attackRing.GetComponent<Collider>();
        if (ringCollider != null)
            Destroy(ringCollider);
        attackRing.SetActive(false);

        slashEffect = GameObject.CreatePrimitive(PrimitiveType.Cube);
        slashEffect.name = "Golden Sword Arc";
        slashEffect.transform.localScale = new Vector3(1.8f, .08f, .18f);
        slashEffect.GetComponent<Renderer>().material.color = new Color(1f, .72f, .18f);
        Destroy(slashEffect.GetComponent<Collider>());
        SlashLifetime lifetime = slashEffect.AddComponent<SlashLifetime>();
        lifetime.HideAfter(.17f);
        slashEffect.SetActive(false);
    }

    private Transform CreateSkeletonVisual(Transform root)
    {
        GameObject visual = new GameObject("Bone Guard Model");
        visual.transform.SetParent(root, false);
        Color bone = new Color(.86f, .82f, .69f);
        CreateLocalColorCube("Skull", new Vector3(0f, 1.25f, 0f), new Vector3(.55f, .58f, .48f), bone, visual.transform);
        CreateLocalColorCube("Rib Cage", new Vector3(0f, .72f, 0f), new Vector3(.48f, .57f, .34f), bone, visual.transform);
        CreateLocalColorCube("Pelvis", new Vector3(0f, .37f, 0f), new Vector3(.5f, .22f, .34f), bone, visual.transform);
        CreateLocalColorCube("Left Leg", new Vector3(-.14f, .12f, 0f), new Vector3(.16f, .42f, .18f), bone, visual.transform);
        CreateLocalColorCube("Right Leg", new Vector3(.14f, .12f, 0f), new Vector3(.16f, .42f, .18f), bone, visual.transform);
        CreateLocalColorCube("Left Arm", new Vector3(-.38f, .68f, 0f), new Vector3(.16f, .6f, .17f), bone, visual.transform);
        CreateLocalColorCube("Right Arm", new Vector3(.38f, .68f, 0f), new Vector3(.16f, .6f, .17f), bone, visual.transform);
        CreateLocalColorCube("Rusty Blade", new Vector3(.52f, .65f, .12f), new Vector3(.12f, .82f, .12f), new Color(.48f, .55f, .57f), visual.transform);
        CreateLocalColorCube("Eye", new Vector3(-.13f, 1.29f, -.245f), new Vector3(.09f, .1f, .035f), new Color(.78f, .12f, .08f), visual.transform);
        CreateLocalColorCube("Eye", new Vector3(.13f, 1.29f, -.245f), new Vector3(.09f, .1f, .035f), new Color(.78f, .12f, .08f), visual.transform);
        return visual.transform;
    }

    private static void CreateLocalColorCube(string name, Vector3 localPosition, Vector3 localSize, Color color, Transform parent)
    {
        GameObject cube = GameObject.CreatePrimitive(PrimitiveType.Cube);
        cube.name = name;
        cube.transform.SetParent(parent, false);
        cube.transform.localPosition = localPosition;
        cube.transform.localRotation = Quaternion.identity;
        cube.transform.localScale = localSize;
        cube.GetComponent<Renderer>().material.color = color;
    }

    private void UpdatePlayerActions()
    {
        Keyboard keyboard = Keyboard.current;
        Mouse mouse = Mouse.current;
        bool basicAttack = keyboard != null && keyboard.spaceKey.wasPressedThisFrame;
        basicAttack |= mouse != null && mouse.leftButton.wasPressedThisFrame;

        if (basicAttack && Time.time >= nextPlayerAttack)
        {
            nextPlayerAttack = Time.time + 0.42f;
            TryDamageNearest(34f, 2.2f, false);
        }

        if (keyboard != null && keyboard.qKey.wasPressedThisFrame && Time.time >= nextDash)
        {
            nextDash = Time.time + 2.8f;
            Vector3 dashDirection = player.transform.forward;
            dashDirection.y = 0f;
            if (dashDirection.sqrMagnitude < 0.01f)
                dashDirection = Vector3.forward;
            player.transform.position += dashDirection.normalized * 1.55f;
        }

        if (keyboard != null && keyboard.eKey.wasPressedThisFrame && Time.time >= nextPulse)
        {
            nextPulse = Time.time + 3.5f;
            TryDamageNearest(26f, 4.8f, true);
        }

        if (keyboard != null && keyboard.rKey.wasPressedThisFrame && Time.time >= nextHeal &&
            playerHealth < 100f)
        {
            nextHeal = Time.time + 7f;
            playerHealth = Mathf.Min(100f, playerHealth + 32f);
        }
    }

    private void TryDamageNearest(float damage, float range, bool area)
    {
        GameObject target = null;
        float nearest = range;
        if (enemyAlive)
        {
            float distance = Vector3.Distance(player.transform.position, slime.transform.position);
            if (distance < nearest) { nearest = distance; target = slime; }
        }
        if (skeletonAlive)
        {
            float distance = Vector3.Distance(player.transform.position, skeleton.transform.position);
            if (distance < nearest) { nearest = distance; target = skeleton; }
        }
        if (target == null) return;

        bool hitSlime = target == slime;
        if (hitSlime) enemyHealth -= damage;
        else skeletonHealth -= damage;

        Vector3 targetPosition = target.transform.position;
        attackRing.transform.position = new Vector3(targetPosition.x, GroundTop + 0.025f, targetPosition.z);
        attackRing.transform.localScale = area ? new Vector3(2.7f, .018f, 2.7f) : new Vector3(1.25f, .018f, 1.25f);
        attackRing.SetActive(true);
        ringVisibleUntil = Time.time + (area ? .32f : .18f);
        slashEffect.transform.position = targetPosition + Vector3.up * .9f;
        slashEffect.transform.rotation = Quaternion.Euler(0f, Random.Range(-40f, 40f), 35f);
        slashEffect.SetActive(!area);
        slashEffect.GetComponent<SlashLifetime>().ShowFor(.17f);

        if (hitSlime && enemyHealth <= 0f)
        {
            enemyAlive = false;
            slimeVisual.gameObject.SetActive(false);
            enemyRespawnAt = Time.time + 2.4f;
        }
        else if (!hitSlime && skeletonHealth <= 0f)
        {
            skeletonAlive = false;
            skeletonVisual.gameObject.SetActive(false);
            skeletonRespawnAt = Time.time + 3f;
        }
    }

    private void UpdateSlime()
    {
        if (!enemyAlive)
        {
            if (Time.time >= enemyRespawnAt)
            {
                enemyAlive = true;
                enemyHealth = 100f;
                slime.transform.position = new Vector3(1.8f, GroundTop, 2.1f);
                slimeVisual.gameObject.SetActive(true);
            }
            return;
        }

        Vector3 direction = player.transform.position - slime.transform.position;
        direction.y = 0f;
        float distance = direction.magnitude;
        if (distance > 1.18f)
            slime.transform.position += direction.normalized * (1.05f * Time.deltaTime);

        if (distance < 1.4f && Time.time >= nextEnemyAttack)
        {
            nextEnemyAttack = Time.time + 1.0f;
            playerHealth = Mathf.Max(0f, playerHealth - 9f);
            if (playerHealth <= 0f)
            {
                playerHealth = 100f;
                player.transform.position = playerSpawn;
            }
        }
    }

    private void UpdateSkeleton()
    {
        if (!skeletonAlive)
        {
            if (Time.time >= skeletonRespawnAt)
            {
                skeletonAlive = true;
                skeletonHealth = 140f;
                skeleton.transform.position = new Vector3(5.1f, GroundTop, 2.4f);
                skeletonVisual.gameObject.SetActive(true);
            }
            return;
        }
        Vector3 direction = player.transform.position - skeleton.transform.position;
        direction.y = 0f;
        float distance = direction.magnitude;
        if (distance > 1.3f) skeleton.transform.position += direction.normalized * (.82f * Time.deltaTime);
        if (distance < 1.55f && Time.time >= skeletonAttackAt)
        {
            skeletonAttackAt = Time.time + 1.4f;
            playerHealth = Mathf.Max(0f, playerHealth - 13f);
            if (playerHealth <= 0f) { playerHealth = 100f; player.transform.position = playerSpawn; }
        }
    }

    private void OnGUI()
    {
        if (player == null || gameCamera == null)
            return;

        GUI.color = new Color(0.055f, 0.07f, 0.075f, 0.92f);
        GUI.DrawTexture(new Rect(18f, 18f, 260f, 76f), Texture2D.whiteTexture);
        GUI.color = Color.white;
        GUI.Label(new Rect(32f, 23f, 230f, 26f), "ISLAND ARENA");
        GUI.Label(new Rect(32f, 51f, 230f, 24f), "Defeat the monsters  |  WASD to move");

        if (enemyAlive)
        {
            Vector3 screen = gameCamera.WorldToScreenPoint(slime.transform.position + Vector3.up * 1.18f);
            if (screen.z > 0f)
            {
                float x = screen.x - 52f;
                float y = Screen.height - screen.y;
                DrawBar(new Rect(x, y, 104f, 13f), enemyHealth / 100f, new Color(0.96f, 0.12f, 0.13f));
            }
        }
        if (skeletonAlive)
        {
            Vector3 screen = gameCamera.WorldToScreenPoint(skeleton.transform.position + Vector3.up * 1.75f);
            if (screen.z > 0f) DrawBar(new Rect(screen.x - 42f, Screen.height - screen.y, 84f, 10f), skeletonHealth / 140f, new Color(.78f, .72f, .53f));
        }

        float panelWidth = 650f;
        float panelX = (Screen.width - panelWidth) * 0.5f;
        float panelY = Screen.height - 104f;
        GUI.color = new Color(0.055f, 0.07f, 0.075f, 0.94f);
        GUI.DrawTexture(new Rect(panelX, panelY, panelWidth, 84f), Texture2D.whiteTexture);
        GUI.color = Color.white;
        GUI.Label(new Rect(panelX + 18f, panelY + 10f, 72f, 20f), "HEALTH");
        DrawBar(new Rect(panelX + 18f, panelY + 36f, 250f, 28f), playerHealth / 100f,
            new Color(0.94f, 0.12f, 0.16f));

        DrawAbility(panelX + 304f, panelY + 13f, "Q", "DASH", Time.time < nextDash);
        DrawAbility(panelX + 378f, panelY + 13f, "E", "PULSE", Time.time < nextPulse);
        DrawAbility(panelX + 452f, panelY + 13f, "R", "HEAL", Time.time < nextHeal);
        DrawAbility(panelX + 556f, panelY + 13f, "LMB", "STRIKE", false);
        GUI.Label(new Rect(panelX + 18f, panelY + 65f, 250f, 18f), "SPACE / LEFT CLICK  ATTACK");
    }

    private void DrawBar(Rect rect, float fraction, Color fill)
    {
        GUI.color = new Color(0.025f, 0.035f, 0.04f, 1f);
        GUI.DrawTexture(rect, Texture2D.whiteTexture);
        GUI.color = fill;
        GUI.DrawTexture(new Rect(rect.x + 3f, rect.y + 3f,
            Mathf.Max(0f, (rect.width - 6f) * Mathf.Clamp01(fraction)), rect.height - 6f),
            Texture2D.whiteTexture);
        GUI.color = Color.white;
    }

    private void DrawAbility(float x, float y, string key, string label, bool coolingDown)
    {
        GUI.color = coolingDown ? new Color(0.28f, 0.31f, 0.32f, 1f) : new Color(0.16f, 0.2f, 0.22f, 1f);
        GUI.DrawTexture(new Rect(x, y, 58f, 56f), Texture2D.whiteTexture);
        GUI.color = Color.white;
        GUI.Label(new Rect(x, y + 5f, 58f, 22f), key);
        GUI.Label(new Rect(x - 5f, y + 31f, 68f, 20f), label);
    }
}

public sealed class SlashLifetime : MonoBehaviour
{
    public float ExpiresAt { get; private set; }
    public void HideAfter(float seconds) { ExpiresAt = Time.time + seconds; }
    public void ShowFor(float seconds) { ExpiresAt = Time.time + seconds; }
}
