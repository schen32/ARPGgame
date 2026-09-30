using UnityEngine;
using UnityEngine.InputSystem;

/// <summary>Screen-relative movement for the fixed isometric camera.</summary>
public sealed class PlayerMovement : MonoBehaviour
{
    [SerializeField, Min(0f)] private float moveSpeed = 5f;

    private void Update()
    {
        Keyboard keyboard = Keyboard.current;
        if (keyboard == null)
        {
            return;
        }

        float horizontal = 0f;
        float vertical = 0f;
        if (keyboard.aKey.isPressed || keyboard.leftArrowKey.isPressed) horizontal -= 1f;
        if (keyboard.dKey.isPressed || keyboard.rightArrowKey.isPressed) horizontal += 1f;
        if (keyboard.sKey.isPressed || keyboard.downArrowKey.isPressed) vertical -= 1f;
        if (keyboard.wKey.isPressed || keyboard.upArrowKey.isPressed) vertical += 1f;

        // These diagonals compensate for the camera's 45-degree world-space yaw.
        Vector3 screenRight = new Vector3(1f, 0f, 1f).normalized;
        Vector3 screenUp = new Vector3(-1f, 0f, 1f).normalized;
        Vector3 direction = (screenRight * horizontal + screenUp * vertical).normalized;
        transform.position += direction * (moveSpeed * Time.deltaTime);
    }
}
