# Gorilla3D - Third Person Scene

A third person scene with a capsule standing in for the player character.

## What is on the form

| Component | Purpose |
|---|---|
| `TGorillaViewport` | render surface and root of the 3D scene |
| `TGorillaInputController` | keyboard / mouse / gamepad capture |
| `TGorillaThirdPersonController` | turns input into character movement |
| `TGorillaCapsule` | the character body - child of the controller |
| `TGorillaCamera` | the chase camera - child of the controller |
| `TGorillaPlane` | the ground |
| `TGorillaCube` x3 | landmarks, so movement is visible |
| `TGorillaLight` | a single directional light |

Capsule and camera are both children of the controller, so they move and turn
with the character.

## Default controls

The character controller registers its own hotkeys as soon as its
`InputController` property is assigned - you do not have to define them:

| Input | Action |
|---|---|
| `W` `A` `S` `D` | move |
| `Space` | jump |
| `Left Ctrl` | crouch |
| `AltGr` | crawl |
| `Left Shift` | run |
| Mouse | orbit the camera |
| Mouse wheel | camera distance (`MouseWheelSpeed`, `CameraZLimit`) |
| Gamepad | D-Pad / thumbsticks / A-B-X-Y |

Rebind them through `GorillaInputController1.HotKeys` (names such as
`KEY_FORWARD`, `KEY_JUMP`, `MOUSE_LEFTBUTTON`, `GAMEPAD_JUMP`).

## Using a real character

Drop a `TGorillaModel` next to `GorillaCapsule1`, load your model, set
`GorillaCapsule1.Visible := False` and wire a `TGorillaAnimationController`
for the idle / walk / run animations.

## Two things that are easy to get wrong

* `TGorillaViewport.UsingDesignCamera` must be **False**. As long as it is True
  the viewport keeps rendering through its internal design camera and the
  assigned `Camera` has no effect.
* `TGorillaInputController.Enabled` is **False** on the form on purpose. An
  enabled input controller installs keyboard and mouse hooks - inside the IDE
  designer that would swallow your keystrokes. It is switched on in `FormShow`
  and off again in `FormClose`.

## Notes

* In FireMonkey the **Y axis points down**, so "up" is negative Y.
* This template is purely kinematic - there is no physics backend attached.
  For collisions and gravity combine the controller with
  `TGorillaPhysicsCharacterController` and a `TGorillaPhysicsSystem`
  (Jolt or Q3 backend).

## GpuPreference.pas

On Windows laptops with hybrid graphics the application may otherwise start on
the integrated GPU. `GpuPreference.pas` registers the executable for the
dedicated GPU; the setting takes effect on the **next** launch. Switch the
profile in the project source (`{$define HIPERF}` / `{$define POWERSAVE}`).
