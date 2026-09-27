# Gorilla3D - Blank Project

The smallest complete Gorilla3D scene.

## What is on the form

| Component | Purpose |
|---|---|
| `TGorillaViewport` | render surface and root of the 3D scene |
| `TGorillaLight` | a single directional light |
| `TGorillaCube` | a 2x2x2 cube |
| `TGorillaBlinnMaterialSource` | the cube's material |

There is deliberately **no camera** on the form.

## The design camera

`TGorillaViewport.UsingDesignCamera` stays at its default `True`, so the
viewport renders through its own design camera. Its
`TGorillaSmoothCameraController` is active at runtime as well and gives you the
standard navigation for free:

| Input | Action |
|---|---|
| left mouse button | orbit |
| right mouse button | pan |
| mouse wheel | zoom |

Only the starting distance has to be set, because the design camera and its
pivot both start at the origin - that is the single line in `FormCreate`:

```pascal
GorillaViewport1.GetDesignCamera().Position.Z := -8;
```

As soon as you want your own point of view, drop a `TGorillaCamera` into the
viewport, assign it to `Viewport.Camera` and set `UsingDesignCamera := False`.
**Without that last step the assigned camera has no effect** - the viewport
keeps rendering through the design camera. See the First Person, Third Person
and Physics templates for that setup.

## Things worth knowing

* In FireMonkey the **Y axis points down**, so "up" is negative Y.
* `TGorillaBlinnMaterialSource` is a Blinn-Phong material. It derives from the
  node based `TGorillaDefaultMaterialSource` but re-publishes only the subset
  that makes sense for that shading model. `UseTexture0` is switched off here,
  because the cube has no texture - leaving it on costs a sampler and a white
  default bitmap for nothing.

## Where to go from here

* Add more meshes: `TGorillaSphere`, `TGorillaPlane`, `TGorillaTerrain`, ...
* Load a model with `TGorillaModel` (glTF, FBX, OBJ, COLLADA, STL and more).
* Enable shadows via `Viewport.Shadows` and `Light.CastShadow`.
* For camera navigation and character movement see the **First Person**,
  **Third Person** and **Physics Character** templates.

## GpuPreference.pas

On Windows laptops with hybrid graphics the application may otherwise start on
the integrated GPU. `GpuPreference.pas` registers the executable for the
dedicated GPU; the setting takes effect on the **next** launch. Switch the
profile in the project source (`{$define HIPERF}` / `{$define POWERSAVE}`).
