unit Unit1;

///
/// Gorilla3D - Model Viewer Template
///
/// Drop a 3D model file onto the viewport (or use "Open ...") and inspect it
/// with the built-in design camera.
///
///   TGorillaViewport     render surface, UsingDesignCamera stays True
///   TGorillaLight        a head light, re-parented to the design camera
///   TGorillaModel        created per load, destroyed on the next one
///
/// The camera
/// ----------
/// The viewport owns a TGorillaCamera plus a TGorillaSmoothCameraController
/// that drives it - both reachable through GetDesignCamera() and
/// GetDesignCameraController(). The controller is what this template puts
/// under user control:
///
///   NavigationProfile : cnpDefault, cnpOrbit, cnpInvOrbit, cnpBlender,
///                       cnpSketchfab - ready made mouse button layouts
///   Types             : which parts of the navigation are allowed at all
///                       (scctRotateX, scctRotateY, scctMoveY, scctZoom,
///                        scctShiftX, scctShiftY, scctShiftZ)
///
/// Setting NavigationProfile overwrites the button assignment (Shifting,
/// ShiftUp, Zooming, Rotation) and the orbiting mode, so apply the profile
/// FIRST and the Types set afterwards. The rotation types depend on that
/// mode: orbiting tilts the camera (scctRotateX), the non-orbiting default
/// profile lifts it instead (scctMoveY) - never enable both, a vertical mouse
/// move would then rotate AND move the camera up / down at the same time.
/// A profile switch also resets the camera distance, so the model is framed
/// again afterwards.
///
/// Framing the model
/// -----------------
/// Assigning the loaded model to the controller's Target and calling
/// AdjustCameraToTarget() moves the camera so the model's bounding sphere
/// exactly fills the frustum - that is the "Fit" button.
/// The Target is released right after the fitting: while a target is
/// assigned, the controller snaps back onto it on every tick, which silently
/// cancels any panning (scctShiftX/Y/Z).
///
/// Animations
/// ----------
/// Every animation the loader imported is listed in the animation combo box
/// and starts playing as soon as it is selected - the first one right after
/// loading. "Blending" crossfades from the previous pose into the new
/// animation (TGorillaAnimationManager.BlendEnabled); switch it off for rigs
/// that show limb skew during transitions.
///
/// Loading
/// -------
/// Before a model is loaded, TLoadOptionsForm.Execute (Gorilla.Utils.Dialogs)
/// shows the TGorillaLoadOptions to the user: attach additional animation
/// files, limit texture sizes and so on. Cancel keeps the current model.
/// glTF / GLB models get RotationAngle.X = 180, otherwise they stand on their
/// head.
///
/// File drop
/// ---------
/// FireMonkey routes an OS file drop to the control under the cursor, so the
/// handlers sit on the viewport, not on the form. OnDragOver has to set
/// Operation to TDragOperation.Copy, otherwise the drop is rejected.
/// The drop only queues the loading (TThread.ForceQueue): Windows keeps the
/// drag source blocked until the drop handler returns, and the modal load
/// options dialog would freeze the Explorer window meanwhile.
///

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.IOUtils, System.Math.Vectors,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Types3D,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.ListBox, FMX.Layouts,
  Gorilla.Viewport, Gorilla.Camera, Gorilla.Light, Gorilla.Model, FMX.Controls3D;

const
  MODEL_FILTER =
    'All supported|*.g3d;*.dae;*.fbx;*.gltf;*.glb;*.obj;*.stl;*.ply;*.skp;' +
    '*.babylon;*.x3d;*.x3dz;*.usd;*.usda;*.usdc;*.usdz|All files|*.*';

type
  TForm1 = class(TForm)
    ToolBar1: TToolBar;
    BtnOpen: TButton;
    BtnFit: TButton;
    LblNavigation: TLabel;
    CmbNavProfile: TComboBox;
    ChkRotate: TCheckBox;
    ChkZoom: TCheckBox;
    ChkShift: TCheckBox;
    ToolBar2: TToolBar;
    LblAnimation: TLabel;
    CmbAnimation: TComboBox;
    ChkBlending: TCheckBox;
    GorillaViewport1: TGorillaViewport;
    GorillaLight1: TGorillaLight;
    LblStatus: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure BtnOpenClick(Sender: TObject);
    procedure BtnFitClick(Sender: TObject);
    procedure CmbNavProfileChange(Sender: TObject);
    procedure ChkNavigationChange(Sender: TObject);
    procedure CmbAnimationChange(Sender: TObject);
    procedure ChkBlendingChange(Sender: TObject);
    procedure GorillaViewport1DragOver(Sender: TObject; const Data: TDragObject;
      const Point: TPointF; var Operation: TDragOperation);
    procedure GorillaViewport1DragDrop(Sender: TObject; const Data: TDragObject;
      const Point: TPointF);
  private
    { Private declarations }
    FModel : TGorillaModel;

    function  CameraController() : TGorillaSmoothCameraController;
    procedure ApplyNavigation();
    procedure LoadModel(const AFileName : String);
    function  FitToModel() : Boolean;
    procedure SetCameraDistance(const ADistance : Single);
    procedure PopulateAnimations();
    procedure PlaySelectedAnimation();
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

uses
  Gorilla.G3D.Loader,
  Gorilla.FBX.Loader,
  Gorilla.DAE.Loader,
  Gorilla.OBJ.Loader,
  Gorilla.GLB.Loader,
  Gorilla.GLTF.Loader,
  Gorilla.USD.Loader,
  Gorilla.STL.Loader,
  Gorilla.PLY.Loader,
{$IFDEF MSWINDOWS}
  {$IFDEF CPUX64}
  Gorilla.SKP.Loader,
  {$ENDIF}
{$ENDIF}
  Gorilla.X3DZ.Loader,
  Gorilla.X3D.Loader,
  Gorilla.DefTypes,
  Gorilla.Animation,
  Gorilla.Utils.Dialogs,
  System.Generics.Collections;

const
  ANIMATION_NONE = '(none)';

function TForm1.CameraController() : TGorillaSmoothCameraController;
begin
  Result := GorillaViewport1.GetDesignCameraController();
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  LCamera : TGorillaCamera;
begin
  // A head light: parented to the design camera it always shines from the
  // viewer's direction, so a model is lit from wherever you look at it.
  LCamera := GorillaViewport1.GetDesignCamera();
  if Assigned(LCamera) then
  begin
    GorillaLight1.Parent := LCamera;
    GorillaLight1.Position.Point := Point3D(0, 0, 0);
    // Pull the camera away from its pivot - both start at the origin.
    LCamera.Position.Z := -10;
  end;

  ApplyNavigation();
  PopulateAnimations();
  LblStatus.Text := 'Drop a model file here, or use "Open ..."';
end;

/// Pushes the toolbar settings into the smooth camera controller.
/// Order matters: the profile rewrites the mouse button assignment, the Types
/// set only decides which parts of the navigation are allowed at all.
procedure TForm1.ApplyNavigation();
var
  LCtrl  : TGorillaSmoothCameraController;
  LTypes : TGorillaSmoothCameraControlTypes;
begin
  LCtrl := CameraController();
  if not Assigned(LCtrl) then
    Exit;

  LCtrl.NavigationProfile :=
    TGorillaCameraNavigationProfile(CmbNavProfile.ItemIndex);

  // The profile has just set Orbiting. Orbiting tilts the camera around the
  // pivot, the default profile moves it up / down instead - enabling both
  // would apply every vertical mouse move twice.
  LTypes := [];
  if ChkRotate.IsChecked then
  begin
    if LCtrl.Orbiting then
      LTypes := LTypes + [scctRotateX, scctRotateY]
    else
      LTypes := LTypes + [scctRotateY, scctMoveY];
  end;
  if ChkZoom.IsChecked then
    LTypes := LTypes + [scctZoom];
  if ChkShift.IsChecked then
    LTypes := LTypes + [scctShiftX, scctShiftY, scctShiftZ];

  LCtrl.Types := LTypes;
end;

procedure TForm1.CmbNavProfileChange(Sender: TObject);
var
  LCamera : TGorillaCamera;
  LDist   : Single;
begin
  LCamera := GorillaViewport1.GetDesignCamera();
  LDist := 0;
  if Assigned(LCamera) then
    LDist := LCamera.Position.Point.Length;

  ApplyNavigation();

  // Switching the orbiting mode re-initializes the camera (distance, rotation
  // center), so the model has to be framed again. Without a model - or when
  // it reports no bounding box yet - keep the distance the user had.
  if not FitToModel() and (LDist > 0) then
    SetCameraDistance(LDist);
end;

/// Moves the design camera to ADistance from the pivot, keeping the viewing
/// direction. In orbiting mode the rotation center has to follow.
procedure TForm1.SetCameraDistance(const ADistance : Single);
var
  LCamera : TGorillaCamera;
  LDir    : TPoint3D;
begin
  LCamera := GorillaViewport1.GetDesignCamera();
  if not Assigned(LCamera) then
    Exit;

  LDir := LCamera.Position.Point;
  if (LDir.Length <= TEpsilon.Vector) then
    LDir := Point3D(0, 0, -1)
  else
    LDir := LDir.Normalize;

  LCamera.Position.Point := LDir * ADistance;
  if Assigned(CameraController()) and CameraController().Orbiting then
    LCamera.RotationCenter.Point := -LCamera.Position.Point;
end;

procedure TForm1.ChkNavigationChange(Sender: TObject);
begin
  ApplyNavigation();
end;

/// Frames the loaded model: the controller computes the sphere enclosing the
/// target's bounding box and moves the camera so it fills the frustum.
/// The Target is only borrowed for that: assigning it moves the pivot onto
/// the model, releasing it afterwards keeps panning alive - with a target
/// assigned the controller would snap back onto it on every tick.
function TForm1.FitToModel() : Boolean;
var
  LCtrl : TGorillaSmoothCameraController;
begin
  Result := False;
  LCtrl := CameraController();
  if not Assigned(LCtrl) or not Assigned(FModel) then
    Exit;

  LCtrl.Target := FModel;
  try
    Result := LCtrl.AdjustCameraToTarget(True);
  finally
    LCtrl.Target := nil;
  end;
end;

/// Lists the imported animations, sorted by name (the manager keeps them in
/// a dictionary without a stable order), and starts the first one.
procedure TForm1.PopulateAnimations();
var
  LNames : TArray<String>;
  LName  : String;
begin
  CmbAnimation.BeginUpdate;
  try
    CmbAnimation.Clear;
    CmbAnimation.Items.Add(ANIMATION_NONE);

    if Assigned(FModel) and Assigned(FModel.AnimationManager) then
    begin
      LNames := FModel.AnimationManager.Animations.Keys.ToArray;
      TArray.Sort<String>(LNames);
      for LName in LNames do
        CmbAnimation.Items.Add(LName);

      FModel.AnimationManager.BlendEnabled := ChkBlending.IsChecked;
    end;
  finally
    CmbAnimation.EndUpdate;
  end;

  CmbAnimation.Enabled := (CmbAnimation.Count > 1);
  ChkBlending.Enabled := CmbAnimation.Enabled;

  // Auto play: pick the first real animation, if there is any. Started
  // explicitly - PlayAnimation on the already running animation is a no-op,
  // so it does not matter whether the index change fired OnChange as well.
  if (CmbAnimation.Count > 1) then
    CmbAnimation.ItemIndex := 1
  else
    CmbAnimation.ItemIndex := 0;
  PlaySelectedAnimation();
end;

/// Starts the animation selected in the combo box. With blending enabled
/// PlayAnimation crossfades from the running animation into the new one.
procedure TForm1.PlaySelectedAnimation();
var
  LManager : TGorillaAnimationManager;
begin
  if not Assigned(FModel) or not Assigned(FModel.AnimationManager) then
    Exit;

  LManager := FModel.AnimationManager;
  if (CmbAnimation.ItemIndex <= 0) then
  begin
    // "(none)" - stop, the model stays in the pose it currently has
    if Assigned(LManager.Current) then
      LManager.Current.Stop();
    Exit;
  end;

  LManager.PlayAnimation(CmbAnimation.Items[CmbAnimation.ItemIndex]);
end;

procedure TForm1.CmbAnimationChange(Sender: TObject);
begin
  PlaySelectedAnimation();
end;

procedure TForm1.ChkBlendingChange(Sender: TObject);
begin
  if Assigned(FModel) and Assigned(FModel.AnimationManager) then
    FModel.AnimationManager.BlendEnabled := ChkBlending.IsChecked;
end;

procedure TForm1.BtnFitClick(Sender: TObject);
begin
  FitToModel();
end;

procedure TForm1.LoadModel(const AFileName : String);
var
  LOpts     : TGorillaLoadOptions;
  LFileName : String;
  LExt      : String;
begin
  if not TFile.Exists(AFileName) then
    Exit;

  // Defaults for a viewer: a model that brings its own lights or cameras
  // would fight the head light and the design camera.
  LOpts := TGorillaLoadOptions.Create(AFileName);
  LOpts.ImportLights     := False;
  LOpts.ImportCameras    := False;
  LOpts.ImportAnimations := True;

  // Let the user adjust the options before anything is touched: attach
  // additional animation files, limit texture sizes, ... Cancel keeps the
  // current model on screen.
  if not TLoadOptionsForm.Execute(LOpts) then
  begin
    LblStatus.Text := 'Loading cancelled';
    Exit;
  end;

  LFileName := LOpts.FileInfo.PathOrUID;
  LblStatus.Text := 'Loading ' + TPath.GetFileName(LFileName) + ' ...';
  Application.ProcessMessages;

  // Drop the previous model - the camera controller must not keep a dangling
  // target while the old instance goes away.
  if Assigned(FModel) then
  begin
    if Assigned(CameraController()) then
      CameraController().Target := nil;
    FreeAndNil(FModel);
  end;

  FModel := TGorillaModel.Create(GorillaViewport1);
  FModel.Parent := GorillaViewport1;
  FModel.Name   := '';   // keep it out of the form's component name space

  try
    FModel.LoadFromFile(LOpts);
    FModel.SetHitTestValue(False);
  except
    on E: Exception do
    begin
      FreeAndNil(FModel);
      PopulateAnimations();
      LblStatus.Text := 'Failed: ' + E.Message;
      Exit;
    end;
  end;

  // glTF is Y-up with a right handed coordinate system, FMX renders Y-down -
  // without flipping the model around X it stands on its head.
  LExt := TPath.GetExtension(LFileName).ToLower;
  if (LExt = '.gltf') or (LExt = '.glb') then
    FModel.RotationAngle.X := 180;

  FitToModel();
  PopulateAnimations();

  if (CmbAnimation.Count > 1) then
    LblStatus.Text := Format('%s (%d animations)',
      [TPath.GetFileName(LFileName), CmbAnimation.Count - 1])
  else
    LblStatus.Text := TPath.GetFileName(LFileName);
end;

procedure TForm1.BtnOpenClick(Sender: TObject);
var
  LDlg : TOpenDialog;
begin
  LDlg := TOpenDialog.Create(Self);
  try
    LDlg.Title   := 'Open 3D model ...';
    LDlg.Filter  := MODEL_FILTER;
    LDlg.Options := [TOpenOption.ofFileMustExist];
    if LDlg.Execute then
      LoadModel(LDlg.FileName);
  finally
    LDlg.Free;
  end;
end;

/// Without accepting the operation here the OS never delivers the drop.
procedure TForm1.GorillaViewport1DragOver(Sender: TObject;
  const Data: TDragObject; const Point: TPointF; var Operation: TDragOperation);
begin
  if Length(Data.Files) > 0 then
    Operation := TDragOperation.Copy
  else
    Operation := TDragOperation.None;
end;

/// The load options dialog is modal. Windows keeps the drag source (Explorer)
/// blocked until the drop handler returns, so the loading is queued behind
/// the drop instead of running inside of it.
procedure TForm1.GorillaViewport1DragDrop(Sender: TObject;
  const Data: TDragObject; const Point: TPointF);
var
  LFileName : String;
begin
  if Length(Data.Files) = 0 then
    Exit;

  LFileName := Data.Files[0];
  TThread.ForceQueue(nil,
    procedure
    begin
      LoadModel(LFileName);
    end);
end;

end.
