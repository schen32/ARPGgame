using UnityEngine;

/// <summary>Builds a tiny playable arena when the starter scene starts.</summary>
public sealed class StarterScene : MonoBehaviour
{
    private void Awake()
    {
        GameObject ground = GameObject.CreatePrimitive(PrimitiveType.Cube);
        ground.name = "Ground";
        ground.transform.position = new Vector3(0f, -0.55f, 0f);
        ground.transform.localScale = new Vector3(20f, 1f, 20f);

        GameObject player = GameObject.CreatePrimitive(PrimitiveType.Capsule);
        player.name = "Player";
        player.tag = "Player";
        player.transform.position = new Vector3(0f, 0.5f, 0f);
        player.AddComponent<PlayerMovement>();

        Camera camera = Camera.main;
        if (camera == null)
        {
            GameObject cameraObject = new GameObject("Main Camera");
            cameraObject.tag = "MainCamera";
            camera = cameraObject.AddComponent<Camera>();
        }

        camera.orthographic = true;
        camera.orthographicSize = 8f;
        camera.transform.position = new Vector3(0f, 12f, -10f);
        camera.transform.rotation = Quaternion.Euler(50f, 0f, 0f);
    }
}
