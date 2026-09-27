# Gorilla3D - First Person Scene

A walkable first person scene, ready to run.

## What is on the form

| Component | Purpose |
|---|---|
| `TGorillaViewport` | render surface and root of the 3D scene |
| `TGorillaInputController` | keyboard / mouse / gamepad capture |
| `TGorillaFirstPersonController` | turns input into character movement |
| `TGorillaCamera` | child of the controller - the eyes |
| `TGorillaPlane` | the ground |
| `TGorillaCube` x3 | landmarks, so movement is visible |
| `TGorillaLight` | a single directional light |

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
| Mouse | look around |
| Gamepad | D-Pad / thumbsticks / A-B-X-Y |

Rebind them through `GorillaInputController1.HotKeys` (names such as
`KEY_FORWARD`, `KEY_JUMP`, `MOUSE_LEFTBUTTON`, `GAMEPAD_JUMP`).

## Two settings that make or break the feel

| Property | Value | Why |
|---|---|---|
| `UseCameraDirection` | `True` | The movement direction is taken from the linked camera instead of from the controller itself, so `W` always walks where you are looking. **The component's own default is `False`** - `AfterConstruction` resets what the constructor set - so it has to be spelled out on the form. |
| `Speed` | `0.25` | With `UseCameraDirection` on, the movement runs through a different code path and the same numeric speed covers far more ground. `0.25` is a walking pace here; `5` would be a teleport. |

## Two things that are easy to get wrong

* `TGorillaViewport.UsingDesignCamera` must be **False**. As long as it is True
  the viewport keeps rendering through its internal design camera and the
  assigned `Camera` has no effect.
* `TGorillaInputController.Enabled` is **False** on the form on purpose. An
  enabled input controller installs keyboard and mouse hooks - inside the IDE
  designer that would swallow your keystrokes. It is switched on in `FormShow`
  and off again in `FormClose`.

## Notes

* In FireMonkey the **Y axis points down**, so "up" is negative Y. That is why
  the camera sits at `Position.Y = -1.75` (eye height) inside the controller.
* This template is purely kinematic - there is no physics backend attached.
  For collisions and gravity combine the controller with
  `TGorillaPhysicsCharacterController` and a `TGorillaPhysicsSystem`
  (Jolt or Q3 backend).

## GpuPreference.pas

On Windows laptops with hybrid graphics the application may otherwise start on
the integrated GPU. `GpuPreference.pas` registers the executable for the
dedicated GPU; the setting takes effect on the **next** launch. Switch the
profile in the project source (`{$define HIPERF}` / `{$define POWERSAVE}`).
