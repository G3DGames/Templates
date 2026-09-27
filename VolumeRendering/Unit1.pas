unit Unit1;

///
/// Gorilla3D - Volume Rendering Template
///
/// Direct volume rendering (ray casting) of a 3D data set with
/// TGorillaVolumetricMesh.
///
/// How it works
/// ------------
/// The volume is rendered by marching a ray through a 3D texture. For every
/// screen pixel the shader needs the entry and the exit point of that ray in
/// the volume's local space - those come from two pre render passes that draw
/// the bounding shape's positions into textures:
///
///   TGorillaRenderPassFace, FaceKind = FrontFace  -> ray entry  points
///   TGorillaRenderPassFace, FaceKind = BackFace   -> ray exit   points
///
/// Both passes are created in code (they are not design time components),
/// assigned to the mesh via FrontFaceRenderPass / BackFaceRenderPass, and each
/// pass has to be told which control it may render - AllowControl(FVolume).
/// Without those two passes the volume stays invisible.
///
/// Feeding your own 3D data
/// ------------------------
/// BuildProceduralVolume below is the complete round trip:
///
///   1. Sizes / CustomWidth|Height|Depth  - the voxel grid
///   2. DataType                          - bytes per voxel (vmdtUInt8,
///                                          vmdtUInt16, vmdtFloat,
///                                          vmdtRGBAUInt8, ...)
///   3. fill a linear buffer, index = X + Y * W + Z * W * H
///   4. SetRawData(@Buffer[0], Length(Buffer))  - copies and uploads
///
/// Wrap steps 1 and 2 in BeginUpdate / EndUpdate, otherwise the internal 3D
/// texture is rebuilt once per property.
///
/// The component can also read prepared data directly:
///   LoadFromRawFile(name, w, h, d, vmdtUInt8)   raw voxel dump
///   LoadFromRawStream(...)                      the same from a stream
///   LoadFromNRRDFile(name)                      NRRD (header + data)
///   LoadFromImageSlices(path, pattern, ...)     a folder of 2D slices
///
/// Tuning
/// ------
///   Details      ray-march steps per axis; 1 is coarse, 3 is smooth. Raising
///                it also makes the medium look denser, because the per step
///                alpha stays the same.
///   RayStop      early ray termination once enough opacity is accumulated
///   IsoSurfaceLimit / Gamut / GamutMode   transfer function and iso surface
///   Dithering    jitters the ray start and removes the "onion ring" banding
///   SetEmissionAbsorptionBlend(scale)     physically based Beer-Lambert
///                compositing, recommended for fog / clouds / smoke
///   SetLinearBlend()                      back to the default blend
///

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Math, System.Math.Vectors,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Types3D,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.ListBox,
  Gorilla.Viewport, Gorilla.Camera, Gorilla.Light,
  Gorilla.Volumetric.Mesh, Gorilla.Controller.Passes.Face;

type
  TForm1 = class(TForm)
    ToolBar1: TToolBar;
    LblDataSet: TLabel;
    CmbDataSet: TComboBox;
    LblDetails: TLabel;
    TrkDetails: TTrackBar;
    ChkDithering: TCheckBox;
    GorillaViewport1: TGorillaViewport;
    GorillaLight1: TGorillaLight;
    LblStatus: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure CmbDataSetChange(Sender: TObject);
    procedure TrkDetailsChange(Sender: TObject);
    procedure ChkDitheringChange(Sender: TObject);
  private
    { Private declarations }
    FFrontFacePass : TGorillaRenderPassFace;
    FBackFacePass  : TGorillaRenderPassFace;
    FVolume        : TGorillaVolumetricMesh;

    procedure BuildFacePasses();
    procedure BuildVolume();
    procedure BuildProceduralVolume(const AKind : Integer);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

const
  /// Voxel grid of the generated data sets. 128^3 with one byte per voxel is
  /// 2 MB - large enough to look good, small enough to rebuild instantly.
  VOL_W = 128;
  VOL_H = 128;
  VOL_D = 128;

procedure TForm1.FormCreate(Sender: TObject);
var
  LCamera : TGorillaCamera;
begin
  LCamera := GorillaViewport1.GetDesignCamera();
  if Assigned(LCamera) then
  begin
    LCamera.Position.Z := -4;
    // A head light, so the volume is lit from wherever you look at it.
    GorillaLight1.Parent := LCamera;
    GorillaLight1.Position.Point := Point3D(0, 0, 0);
  end;

  BuildFacePasses();
  BuildVolume();
  BuildProceduralVolume(CmbDataSet.ItemIndex);
end;

/// The two pre render passes that give the ray caster its entry and exit
/// points. They are plain render pass controllers - create them once, keep
/// them alive as long as the volume lives.
procedure TForm1.BuildFacePasses();
begin
  FFrontFacePass := TGorillaRenderPassFace.Create(GorillaViewport1, 'FrontFace');
  FFrontFacePass.FaceKind := TFaceKind.FrontFace;
  FFrontFacePass.Viewport := GorillaViewport1;
  FFrontFacePass.Enabled  := True;

  FBackFacePass := TGorillaRenderPassFace.Create(GorillaViewport1, 'BackFace');
  FBackFacePass.FaceKind := TFaceKind.BackFace;
  FBackFacePass.Viewport := GorillaViewport1;
  FBackFacePass.Enabled  := True;
end;

procedure TForm1.BuildVolume();
begin
  FVolume := TGorillaVolumetricMesh.Create(GorillaViewport1);
  FVolume.Parent := GorillaViewport1;
  FVolume.SetHitTestValue(False);
  // The bounding shape is drawn by the face passes, so it must not be culled
  // away independently from them.
  FVolume.FrustumCullingCheck := False;

  FVolume.Shape := TGorillaVolumetricMeshShape.vmsCube;
  FVolume.SetSize(1, 1, 1);

  // Hand the two pre passes to the mesh ...
  FVolume.FrontFaceRenderPass := FFrontFacePass;
  FVolume.BackFaceRenderPass  := FBackFacePass;
  // ... and tell each pass that it is allowed to render this control.
  // Forgetting this leaves the volume invisible.
  FFrontFacePass.AllowControl(FVolume);
  FBackFacePass.AllowControl(FVolume);

  FVolume.Details    := TrkDetails.Value;
  FVolume.Dithering  := ChkDithering.IsChecked;
  FVolume.RayStop    := 0.97;
  FVolume.UseLighting := False;
end;

/// Generates a data set and uploads it. This is the part to replace with your
/// own data - everything else in this unit stays as it is.
procedure TForm1.BuildProceduralVolume(const AKind : Integer);
var
  LData : TArray<Byte>;
  x, y, z : Integer;
  LIdx : Integer;
  LFx, LFy, LFz, LDist, LValue : Single;
begin
  // 1 + 2 - the voxel grid and the format of a single voxel. Both rebuild the
  // internal 3D texture, so they belong into one update bracket.
  FVolume.BeginUpdate();
  try
    FVolume.Sizes       := TGorillaVolumetricMeshSize.vmsCustom;
    FVolume.CustomWidth  := VOL_W;
    FVolume.CustomHeight := VOL_H;
    FVolume.CustomDepth  := VOL_D;
    FVolume.DataType    := TGorillaVolumetricMeshDataType.vmdtUInt8;
  finally
    FVolume.EndUpdate();
  end;

  // 3 - fill a linear buffer. The layout is X fastest, then Y, then Z.
  SetLength(LData, VOL_W * VOL_H * VOL_D);

  for z := 0 to VOL_D - 1 do
  begin
    LFz := (z / (VOL_D - 1)) * 2 - 1;      // -1 .. +1
    for y := 0 to VOL_H - 1 do
    begin
      LFy := (y / (VOL_H - 1)) * 2 - 1;
      for x := 0 to VOL_W - 1 do
      begin
        LFx := (x / (VOL_W - 1)) * 2 - 1;

        case AKind of
          1 :
            begin
              // Hollow shell: a thin spherical surface
              LDist  := Sqrt(LFx * LFx + LFy * LFy + LFz * LFz);
              LValue := 1 - Min(1, Abs(LDist - 0.7) * 8);
            end;

          2 :
            begin
              // Gyroid, a triply periodic minimal surface - a good stress test
              // for the transfer function
              LValue := Sin(LFx * Pi * 3) * Cos(LFy * Pi * 3) +
                        Sin(LFy * Pi * 3) * Cos(LFz * Pi * 3) +
                        Sin(LFz * Pi * 3) * Cos(LFx * Pi * 3);
              LValue := 1 - Min(1, Abs(LValue) * 1.5);
            end;

        else
          begin
            // Solid ball with a soft falloff towards the surface
            LDist  := Sqrt(LFx * LFx + LFy * LFy + LFz * LFz);
            LValue := 1 - Min(1, LDist / 0.85);
          end;
        end;

        LIdx := x + y * VOL_W + z * VOL_W * VOL_H;
        LData[LIdx] := Byte(Round(EnsureRange(LValue, 0, 1) * 255));
      end;
    end;
  end;

  // 4 - hand the buffer over. SetRawData copies it by default and uploads the
  // 3D texture, so the local array can go out of scope right after.
  FVolume.SetRawData(@LData[0], Length(LData));

  LblStatus.Text := Format('%dx%dx%d voxels, 8 bit - %.1f MB',
    [VOL_W, VOL_H, VOL_D, Length(LData) / (1024 * 1024)]);
end;

procedure TForm1.CmbDataSetChange(Sender: TObject);
begin
  BuildProceduralVolume(CmbDataSet.ItemIndex);
end;

procedure TForm1.TrkDetailsChange(Sender: TObject);
begin
  if Assigned(FVolume) then
    FVolume.Details := TrkDetails.Value;
end;

procedure TForm1.ChkDitheringChange(Sender: TObject);
begin
  if Assigned(FVolume) then
    FVolume.Dithering := ChkDithering.IsChecked;
end;

end.
