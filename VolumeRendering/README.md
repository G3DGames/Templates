# Gorilla3D - Volume Rendering

Direct volume rendering (ray casting) of a 3D data set with
`TGorillaVolumetricMesh`.

## What is on the form

| Component | Purpose |
|---|---|
| `TGorillaViewport` | render surface, `UsingDesignCamera` stays True |
| `TGorillaLight` | head light, re-parented to the design camera |
| `TToolBar` | data set, `Details`, `Dithering` |
| `TGorillaRenderPassFace` x2 | created in code - the front/back face pre passes |
| `TGorillaVolumetricMesh` | created in code - the volume itself |

Navigate with the design camera: left mouse orbits, right mouse pans, the wheel
zooms.

## Why two face passes

The volume is rendered by marching a ray through a 3D texture. For every screen
pixel the shader needs where that ray **enters** and where it **leaves** the
volume's bounding shape. Those two position buffers are produced by two pre
render passes that draw the shape's fragment positions:

```pascal
FFrontFacePass := TGorillaRenderPassFace.Create(GorillaViewport1, 'FrontFace');
FFrontFacePass.FaceKind := TFaceKind.FrontFace;   // ray entry points
FFrontFacePass.Viewport := GorillaViewport1;
FFrontFacePass.Enabled  := True;

FBackFacePass := TGorillaRenderPassFace.Create(GorillaViewport1, 'BackFace');
FBackFacePass.FaceKind := TFaceKind.BackFace;     // ray exit points
FBackFacePass.Viewport := GorillaViewport1;
FBackFacePass.Enabled  := True;

FVolume.FrontFaceRenderPass := FFrontFacePass;
FVolume.BackFaceRenderPass  := FBackFacePass;
FFrontFacePass.AllowControl(FVolume);
FBackFacePass.AllowControl(FVolume);
```

Three things to get right:

1. **Both** passes, front *and* back - one alone gives no ray segment.
2. `AllowControl(FVolume)` on each pass. A render pass renders nothing until it
   is told which controls it may draw, so without this the volume stays
   invisible.
3. `FVolume.FrustumCullingCheck := False`. The bounding shape is drawn by the
   pre passes; culling it independently of them produces flickering.

These passes are not design time components - create them in code and keep them
alive as long as the volume lives.

## Feeding your own 3D data

`BuildProceduralVolume` in `Unit1.pas` is the complete round trip:

```pascal
FVolume.BeginUpdate();          // both properties rebuild the 3D texture
try
  FVolume.Sizes        := TGorillaVolumetricMeshSize.vmsCustom;
  FVolume.CustomWidth  := 128;
  FVolume.CustomHeight := 128;
  FVolume.CustomDepth  := 128;
  FVolume.DataType     := TGorillaVolumetricMeshDataType.vmdtUInt8;
finally
  FVolume.EndUpdate();
end;

SetLength(LData, W * H * D);
// index = X + Y * W + Z * W * H   (X is the fastest axis)
...
FVolume.SetRawData(@LData[0], Length(LData));
```

`SetRawData` copies the buffer by default (pass `ADoCopyData = False` to hand
over ownership instead) and uploads the 3D texture, so the local array can go
out of scope right after.

`Sizes` also has ready made powers of two (`vms64x64x64`, `vms128x128x128`,
`vms256x256x256`, ...); `vmsCustom` plus `CustomWidth/Height/Depth` is the
general case. `CustomWidth/Height/Depth` round up to a multiple of two, the
`CustomSize` property does not - use it when your data really has odd
dimensions.

`DataType` is the format of a **single voxel**: `vmdtUInt8`, `vmdtUInt16`,
`vmdtHalfFloat`, `vmdtFloat`, `vmdtRGBUInt8`, `vmdtRGBAUInt8`, `vmdtRGBFloat`,
`vmdtRGBAFloat`. Scalar types give a density that the transfer function
colours; the RGB/RGBA types carry their own colour per voxel.

### Ready made loaders

| Method | Data |
|---|---|
| `LoadFromRawFile(name, w, h, d, type, byteOrder, offset)` | a raw voxel dump |
| `LoadFromRawStream(stream, ...)` | the same from a stream |
| `LoadFromNRRDFile(name)` | NRRD (header + data, common in medical imaging) |
| `LoadFromImageSlices(path, pattern, from, to, padLen, padChar, w, h, d)` | a folder of 2D slice images |

`Spacings` compensates for non-cubic voxels (CT slice distance vs. pixel
pitch).

## Tuning

| Property | Effect |
|---|---|
| `Details` | ray-march steps per axis. 1 is coarse and shows terracing, 3 is smooth. Raising it also makes the medium look **denser**, because the per step alpha stays the same - lower the density if it turns solid. |
| `Dithering` | jitters the ray start position and removes the "onion ring" banding of a fixed step ray marcher. On by default. |
| `RayStop` | early ray termination once enough opacity has accumulated |
| `IsoSurfaceLimit` | render an iso surface instead of a cloud |
| `Gamut` / `GamutMode` / `GamutFactor` | the transfer function: a 2D bitmap mapping density to colour |
| `SetEmissionAbsorptionBlend(scale)` | physically based Beer-Lambert compositing. Recommended for fog, clouds and smoke - it does not hard-saturate, so a dense medium no longer shows shell/onion-ring terraces from inside. |
| `SetLinearBlend()` | back to the default front-to-back blend |
| `Shape` | `vmsCube`, `vmsSphere`, `vmsCylinder` - the bounding shape the ray is clipped against |
| `UseLighting` | surface shading of the volume. Off here: for a soft medium it makes the bounding box faces visible. |
| `LinearFiltering` / `MipMaps` | 3D texture sampling |

## Related components

`TGorillaVolumetricNoise` derives from `TGorillaVolumetricMesh` and generates
its data itself (FBM noise) - use it for clouds, smoke and fog instead of
uploading your own buffer. It has `ApplyPreset(vnpClouds / vnpSmoke / vnpFog)`.

## Performance

A `128^3` 8 bit volume is 2 MB and rebuilds instantly. `256^3` is 16 MB, `512^3`
is 128 MB - watch GPU memory, and keep in mind the cost of the ray marching
scales with `Details` and with the screen area the volume covers, not with the
voxel count.

## GpuPreference.pas

On Windows laptops with hybrid graphics the application may otherwise start on
the integrated GPU. `GpuPreference.pas` registers the executable for the
dedicated GPU; the setting takes effect on the **next** launch. Switch the
profile in the project source (`{$define HIPERF}` / `{$define POWERSAVE}`).
