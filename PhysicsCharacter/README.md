# Gorilla3D - Physics Character Scene

A third person character walking over a procedurally generated terrain, driven
by the physics system. This is the most complete of the Gorilla3D templates.

## What is on the form

```
GorillaViewport1
├── GorillaLight1                         directional light
├── GorillaTerrain1                       the ground (random height map)
│   └── GorillaTerrainMaterial
├── GorillaPhysicsSystem1                 Q3 backend
│   └── Colliders[0] "TerrainCollider"    ckTerrain / eStaticBody -> GorillaTerrain1
└── GorillaPhysicsCharacterController1
    ├── GorillaThirdPersonController1     input -> movement, owns the camera
    │   └── GorillaCamera1                the chase camera
    └── GorillaModel1                     the character
        └── GorillaCapsule1               placeholder body

GorillaInputController1                   keyboard / mouse / gamepad
```

## How the three controllers relate

| Component | Responsibility |
|---|---|
| `TGorillaInputController` | captures raw keyboard / mouse / gamepad input |
| `TGorillaThirdPersonController` | turns that input into a movement intent, owns the camera and the character states (idle, moving, crouching, ...) |
| `TGorillaPhysicsCharacterController` | takes the intent, applies gravity and keeps the character on the ground |

Note `UseDefaultMovement = False` on the third person controller: with a physics
character controller attached, the movement is applied by the physics side, not
by the input controller itself.

Ground detection is configured as a downward ray cast
(`UseRayCasting = True`, `RayOffset = 100`) rather than a physics body, which is
the cheaper and more predictable option for a player character. The character
starts at `Position.Y = -10`, well above the terrain, and drops onto the
surface (`GroundSmoothingFactor = 0.88` smooths the landing).

## Order of operations

This is the part that is easy to get wrong:

| Where | What | Why |
|---|---|---|
| `FormCreate` | `GorillaTerrain1.RandomTerrain(...)` | the terrain mesh has to be final first |
| `FormCreate` | load the character model | |
| `FormShow` | `GorillaInputController1.Enabled := True` | hooks only once the form is on screen |
| `FormShow` | `GorillaPhysicsSystem1.Active := True` | **this** builds the collider prefabs - the `ckTerrain` collider is generated from the finished terrain mesh at that moment |

Switching the physics system Active before the terrain exists gives you a
collider for the flat default mesh, and the character will walk on an invisible
plane.

## The terrain

`RandomTerrain` generates a height map and rebuilds the mesh in one go. The
algorithms are `Hill`, `DiamondSquare`, `Mandelbrot`, `PerlinNoise`, `Plateau`,
`Brownian` and `Planar` - swap the constant in `BuildTerrain`. The extent comes
from the mesh, not from the algorithm: `Width` / `Depth` are the footprint,
`Height` is the height amplitude, `ResolutionX` / `ResolutionY` the vertex grid.

Terrain colliders are the expensive kind. If you raise `ResolutionX/Y`, watch
the physics step cost before shipping.

## The character model

Drop a rigged model into the project's `assets` folder and name it
`Character.fbx` (or change `CHARACTER_MODEL` in `Unit1.pas`). FBX, glTF/GLB,
DAE, OBJ, 3DS, COLLADA, STL and more are supported. While no model is found the
blue capsule inside `GorillaModel1` stands in for it, so the template runs out
of the box.

For animations, add a `TGorillaAnimationController`, assign it to
`GorillaPhysicsCharacterController1.AnimationController` and register
transitions between the idle and locomotion clips - the character controller
states (`fpIdle`, `fpMoving`, ...) drive them.

## Default controls

The character controller registers its own hotkeys as soon as its
`InputController` property is assigned:

| Input | Action |
|---|---|
| `W` `A` `S` `D` | move |
| `Space` | jump |
| `Left Ctrl` | crouch |
| `AltGr` | crawl |
| `Left Shift` | run |
| Mouse | orbit the camera |
| Mouse wheel | camera distance |
| Gamepad | D-Pad / thumbsticks / A-B-X-Y |

## Two things that are easy to get wrong

* `TGorillaViewport.UsingDesignCamera` must be **False**. As long as it is True
  the viewport keeps rendering through its internal design camera and the
  assigned `Camera` has no effect.
* `TGorillaInputController.Enabled` is **False** on the form on purpose. An
  enabled input controller installs keyboard and mouse hooks - inside the IDE
  designer that would swallow your keystrokes.

## Debugging aids

* `GorillaPhysicsSystem1.RenderColliders := True` draws the collider shapes.
* `GorillaTerrain1.ShowGrid` / `ShowVertices` visualise the terrain mesh.
* `GorillaPhysicsSystem1.Async` runs the simulation off the render thread;
  turn it off while debugging to get deterministic stepping.

## Notes

* In FireMonkey the **Y axis points down**, so "up" is negative Y.
* The backend is switchable: `GorillaPhysicsSystem1.Driver := JoltPhysics`
  uses Jolt instead of Q3. Jolt needs its native library deployed alongside
  the executable.

## GpuPreference.pas

On Windows laptops with hybrid graphics the application may otherwise start on
the integrated GPU. `GpuPreference.pas` registers the executable for the
dedicated GPU; the setting takes effect on the **next** launch. Switch the
profile in the project source (`{$define HIPERF}` / `{$define POWERSAVE}`).
