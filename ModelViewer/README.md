# Gorilla3D - Model Viewer

Drop a 3D model file onto the viewport and inspect it with the built-in design
camera.

## What is on the form

| Component | Purpose |
|---|---|
| `TGorillaViewport` | render surface, `UsingDesignCamera` stays **True** |
| `TGorillaLight` | head light, re-parented to the design camera in `FormCreate` |
| `ToolBar1` | Open / Fit, navigation profile, navigation type switches |
| `ToolBar2` | animation selection, animation blending on / off |
| `TGorillaModel` | created per load in code, freed on the next one |

## The design camera and its controller

The viewport owns a `TGorillaCamera` plus a `TGorillaSmoothCameraController`
that drives it. Both are reachable at runtime:

```pascal
GorillaViewport1.GetDesignCamera()            // TGorillaCamera
GorillaViewport1.GetDesignCameraController()  // TGorillaSmoothCameraController
```

Two properties of the controller are what this template puts under user
control:

**`NavigationProfile`** - ready made mouse button layouts:

| Profile | Rotate | Pan | Zoom | Orbiting |
|---|---|---|---|---|
| `cnpDefault` | LMB | RMB (+Shift for XY) | wheel | no |
| `cnpOrbit` | RMB | LMB (+Shift for XZ) | wheel | yes |
| `cnpInvOrbit` | LMB | RMB (+Shift for XZ) | wheel | yes |
| `cnpBlender` | Ctrl+RMB | Ctrl+LMB (+Shift for XZ) | wheel | yes |
| `cnpSketchfab` | LMB | RMB | wheel = move forward, Ctrl+RMB drag = zoom | yes |

**`Types`** - which parts of the navigation are allowed at all:
`scctRotateX`, `scctRotateY`, `scctMoveY`, `scctZoom`, `scctShiftX`,
`scctShiftY`, `scctShiftZ`.

> Setting `NavigationProfile` rewrites the button assignment (`Rotation`,
> `Shifting`, `ShiftUp`, `Zooming`) and the orbiting mode. Apply the profile
> **first** and the `Types` set afterwards - `ApplyNavigation` does exactly
> that.

> The rotation types depend on the orbiting mode the profile just set:
> orbiting profiles tilt the camera (`scctRotateX`), the default profile lifts
> it (`scctMoveY`). Never enable both - a vertical mouse move would then
> rotate **and** move the camera up / down at the same time.

A profile switch re-initializes the camera (distance, rotation center), so the
template frames the model again afterwards - or restores the previous distance
when there is nothing to frame.

Everything else about the controller is tunable too: `IntensityRotate` /
`IntensityZoom` / `IntensityUpAndDown`, the matching `Damping*` and
`ImpulseLimit*` values, and `Smooth` to turn the inertia off entirely.

## Framing a model

```pascal
Controller.Target := FModel;
Controller.AdjustCameraToTarget(True);
```

The controller takes the target's bounding box - for a `TGorillaControl` that
is the accurate box computed from the vertex data, not the coarse
width/height/depth one - wraps it in a sphere and moves the camera so the
sphere exactly fills the frustum. `AImmediate = False` animates towards the new
distance instead of jumping, and a running fitting is aborted as soon as the
user zooms.

> **Release the `Target` right after the fitting.** While a target is
> assigned, the controller snaps back onto it on every tick - any panning
> (`scctShiftX/Y/Z`) is silently cancelled. `FitToModel` therefore only
> borrows the target:
>
> ```pascal
> Controller.Target := FModel;
> try
>   Controller.AdjustCameraToTarget(True);
> finally
>   Controller.Target := nil;
> end;
> ```

`AutoAdjustCameraToTarget := True` keeps the fitting in sync with a target that
changes size (a growing model, an animation) - but it needs the target to stay
assigned, so panning is gone then.

## Animations

After loading, every imported animation is listed in the animation combo box,
sorted by name, and the first one starts playing right away. Selecting another
entry plays it immediately, `(none)` stops the playback.

```pascal
FModel.AnimationManager.PlayAnimation(AName);
FModel.AnimationManager.BlendEnabled := ChkBlending.IsChecked;
```

With **Blending** enabled, `PlayAnimation` crossfades from the current pose
into the new animation (`BlendDuration`, default 0.25 s). Switch it off for
rigs that show limb skew during transitions - the change is then a hard cut.

Animations from separate files (Mixamo clips and the like) are attached in the
load options dialog.

## Loading

`LoadModel` builds a `TGorillaLoadOptions` with viewer defaults (no imported
lights and cameras, animations on) and hands it to the user first:

```pascal
if not Gorilla.Utils.Dialogs.TLoadOptionsForm.Execute(LOpts) then
  Exit;
```

The dialog is where additional animation files are attached, texture sizes are
limited and so on. Cancel keeps the current model.

glTF / GLB models get `RotationAngle.X := 180`, otherwise they stand on their
head.

## File drop

FireMonkey routes an OS file drop to the control under the cursor
(`TCommonCustomForm.DragOver` -> `FindTarget`), so the handlers sit on the
**viewport**, not on the form. `OnDragOver` has to set
`Operation := TDragOperation.Copy`, otherwise the drop is rejected and
`OnDragDrop` never fires. `Data.Files` holds the dropped paths.

The drop handler only queues the loading (`TThread.ForceQueue`). Windows keeps
the drag source - the Explorer window - blocked until the handler returns, and
the modal load options dialog would freeze it meanwhile.

## Supported formats

g3d, dae, fbx, gltf, glb, obj, stl, ply, skp, babylon, x3d, usd/usda/usdc/usdz,
3ds, 3mf, amf, off, wrl, dxf, x - see `MODEL_FILTER` in `Unit1.pas`.

Loading goes through `TGorillaLoadOptions`, which is also where you switch off
imported lights and cameras (a model that brings its own camera would otherwise
fight the viewer) and where additional animation files are attached with
`AddAnimation`.

## Where to go from here

* A `TGorillaAssetsManager` package as second argument to
  `TGorillaLoadOptions.Create` caches meshes, materials and textures across
  loads.
* `TGorillaAnimationController` for state machines with transitions between
  animations (idle > walk > run) instead of the plain combo box selection.
* `FModel.Wireframe`, `ShowNormals` and `FModel.Meshes` for an inspector panel.

## GpuPreference.pas

On Windows laptops with hybrid graphics the application may otherwise start on
the integrated GPU. `GpuPreference.pas` registers the executable for the
dedicated GPU; the setting takes effect on the **next** launch. Switch the
profile in the project source (`{$define HIPERF}` / `{$define POWERSAVE}`).
