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
    private Camera gameCamera;

    private float playerHealth = 100f;
    private float enemyHealth = 100f;
    private float nextPlayerAttack;
    private float nextEnemyAttack;
    private float nextDash;
    private float nextPulse;
    private float nextHeal;
    private float ringVisibleUntil;
    private float enemyRespawnAt;
    private bool enemyAlive = true;
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
    UpdatePlayerActions();

    if (attackRing != null && Time.time > ringVisibleUntil)
        attackRing.SetActive(false);
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
        water.GetComponent<Renderer>().material.color = new Color(0.02f, 0.62f, 0.78f);
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

                GameObject tile = (x == 0 || z == 0) ? pathTileAsset : grassTileAsset;
                SpawnModel(tile, island.transform, (x == 0 || z == 0) ? "Path Tile" : "Grass Tile",
                    new Vector3(x, 0f, z), Quaternion.identity, Vector3.one);
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
    gameCamera.orthographicSize = 9.6f;
    gameCamera.transform.position = player.transform.position + new Vector3(12f, 12f, -12f);
    gameCamera.transform.LookAt(player.transform.position + Vector3.up * 0.6f);
    gameCamera.clearFlags = CameraClearFlags.SolidColor;
    gameCamera.backgroundColor = new Color(0.02f, 0.66f, 0.80f);

    Light sceneLight = FindObjectOfType<Light>();
    if (sceneLight == null)
    {
        GameObject lightObject = new GameObject("Directional Light");
        sceneLight = lightObject.AddComponent<Light>();
        sceneLight.type = LightType.Directional;
    }

    sceneLight.transform.rotation = Quaternion.Euler(50f, -30f, 0f);
    sceneLight.intensity = 1.35f;
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
            TryDamageSlime(34f, 2.2f);
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
            TryDamageSlime(26f, 4.8f);
        }

        if (keyboard != null && keyboard.rKey.wasPressedThisFrame && Time.time >= nextHeal &&
            playerHealth < 100f)
        {
            nextHeal = Time.time + 7f;
            playerHealth = Mathf.Min(100f, playerHealth + 32f);
        }
    }

    private void TryDamageSlime(float damage, float range)
    {
        if (!enemyAlive || Vector3.Distance(player.transform.position, slime.transform.position) > range)
            return;

        enemyHealth -= damage;
        attackRing.transform.position = new Vector3(slime.transform.position.x, GroundTop + 0.025f,
            slime.transform.position.z);
        attackRing.SetActive(true);
        ringVisibleUntil = Time.time + 0.18f;

        if (enemyHealth <= 0f)
        {
            enemyAlive = false;
            slimeVisual.gameObject.SetActive(false);
            enemyRespawnAt = Time.time + 2.4f;
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

    private void OnGUI()
    {
        if (player == null || gameCamera == null)
            return;

        GUI.color = new Color(0.055f, 0.07f, 0.075f, 0.92f);
        GUI.DrawTexture(new Rect(18f, 18f, 260f, 76f), Texture2D.whiteTexture);
        GUI.color = Color.white;
        GUI.Label(new Rect(32f, 23f, 230f, 26f), "VOXEL ISLAND");
        GUI.Label(new Rect(32f, 51f, 230f, 24f), "Defeat the slime  |  WASD to move");

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

        float panelWidth = 560f;
        float panelX = (Screen.width - panelWidth) * 0.5f;
        float panelY = Screen.height - 102f;
        GUI.color = new Color(0.055f, 0.07f, 0.075f, 0.94f);
        GUI.DrawTexture(new Rect(panelX, panelY, panelWidth, 82f), Texture2D.whiteTexture);
        GUI.color = Color.white;
        GUI.Label(new Rect(panelX + 18f, panelY + 10f, 72f, 20f), "HEALTH");
        DrawBar(new Rect(panelX + 18f, panelY + 36f, 235f, 28f), playerHealth / 100f,
            new Color(0.94f, 0.12f, 0.16f));

        DrawAbility(panelX + 292f, panelY + 13f, "Q", "DASH", Time.time < nextDash);
        DrawAbility(panelX + 365f, panelY + 13f, "E", "PULSE", Time.time < nextPulse);
        DrawAbility(panelX + 438f, panelY + 13f, "R", "HEAL", Time.time < nextHeal);
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
