unit Unit1;

///
/// Gorilla3D - Physics Character Scene Template
///
/// A third person character walking over a procedurally generated terrain,
/// driven by the physics system:
///
///   TGorillaViewport                 render surface and root of the 3D scene
///   TGorillaTerrain                  the ground, randomly generated at startup
///   TGorillaPhysicsSystem            the Q3 physics backend
///     Colliders[0]                   ckTerrain collider for the terrain
///   TGorillaInputController          keyboard / mouse / gamepad input
///   TGorillaPhysicsCharacterController
///       TGorillaThirdPersonController   input -> movement
///           TGorillaCamera              the chase camera
///       TGorillaModel                   the character
///           TGorillaCapsule             placeholder body, see below
///   TGorillaLight                    a directional light
///
/// How the three controllers relate to each other:
///   * the TGorillaInputController captures raw input,
///   * the TGorillaThirdPersonController turns it into a movement intent and
///     owns the camera,
///   * the TGorillaPhysicsCharacterController takes that intent, applies
///     gravity and keeps the character on the ground - either through the
///     physics body or, as configured here, through a downward ray cast
///     (UseRayCasting = True, RayOffset = 100).
///
/// Order of operations matters:
///   FormCreate  generates the terrain, THEN loads the character
///   FormShow    enables the input controller and only then switches the
///               physics system Active - the ckTerrain collider is built from
///               the terrain mesh at that moment, so the terrain has to exist
///               and be final by then.
///
/// The character model:
///   Drop a rigged model into the project's assets folder and name it
///   Character.fbx (or change CHARACTER_MODEL below). Supported formats
///   include FBX, glTF/GLB, DAE, OBJ and more. As long as no model is found
///   the blue capsule inside GorillaModel1 stands in for it, so the template
///   runs out of the box.
///
/// Default controls (registered automatically by the character controller as
/// soon as its InputController property is assigned):
///   W / A / S / D    move          Space        jump
///   Left Ctrl        crouch        AltGr        crawl
///   Left Shift       run           Mouse        orbit the camera
///
/// Remember that in FireMonkey the Y axis points DOWN, so "up" is negative Y.
///

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.IOUtils, FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Types3D,
  Gorilla.Viewport, Gorilla.Camera, Gorilla.Light, Gorilla.Capsule,
  Gorilla.Terrain, Gorilla.Terrain.Algorithm, Gorilla.Material.Blinn,
  Gorilla.Model, Gorilla.Physics, Gorilla.PhysicsCharacterController,
  Gorilla.Controller.Input, Gorilla.Controller.Input.ThirdPerson;

const
  /// Put your rigged character into the assets folder under this name.
  CHARACTER_MODEL = 'Character.fbx';

type
  TForm1 = class(TForm)
    GorillaViewport1: TGorillaViewport;
    GorillaLight1: TGorillaLight;
    GorillaTerrain1: TGorillaTerrain;
    GorillaTerrainMaterial: TGorillaBlinnMaterialSource;
    GorillaPhysicsSystem1: TGorillaPhysicsSystem;
    GorillaPhysicsCharacterController1: TGorillaPhysicsCharacterController;
    GorillaThirdPersonController1: TGorillaThirdPersonController;
    GorillaCamera1: TGorillaCamera;
    GorillaModel1: TGorillaModel;
    GorillaCapsule1: TGorillaCapsule;
    GorillaCharacterMaterial: TGorillaBlinnMaterialSource;
    GorillaInputController1: TGorillaInputController;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    function  AssetsPath() : String;
    procedure BuildTerrain();
    procedure LoadCharacter();
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

uses
  Gorilla.DefTypes;

/// Returns the assets folder. Running out of the IDE the executable sits in
/// .\<Platform>\<Config> while the assets stay next to the project, so fall
/// back to two levels up.
function TForm1.AssetsPath() : String;
var
  LBase : String;
begin
{$IFDEF MSWINDOWS}
  LBase := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
{$ELSE}
  LBase := IncludeTrailingPathDelimiter(TPath.GetHomePath());
{$ENDIF}

  Result := LBase + 'assets' + PathDelim;
  if TFile.Exists(Result + CHARACTER_MODEL) then
    Exit;

  Result := LBase + '..' + PathDelim + '..' + PathDelim + 'assets' + PathDelim;
end;

/// Generates a fresh height map and rebuilds the terrain mesh. This has to
/// happen before the physics system goes Active, because the ckTerrain
/// collider is built from the finished mesh.
procedure TForm1.BuildTerrain();
begin
  Randomize();

  // Hill, DiamondSquare, Mandelbrot, PerlinNoise, Plateau, Brownian, Planar
  GorillaTerrain1.RandomTerrain(TRandomTerrainAlgorithmType.DiamondSquare);
end;

/// Loads the character model if one was placed in the assets folder, otherwise
/// the placeholder capsule stays visible.
procedure TForm1.LoadCharacter();
var
  LPath : String;
  LOpts : TGorillaLoadOptions;
begin
  LPath := AssetsPath() + CHARACTER_MODEL;
  if not TFile.Exists(LPath) then
    Exit;

  LOpts := TGorillaLoadOptions.Create(LPath);
  LOpts.ImportLights     := False;
  LOpts.ImportCameras    := False;
  LOpts.ImportAnimations := True;

  GorillaModel1.LoadFromFile(LOpts);
  GorillaModel1.SetHitTestValue(False);

  // A real character replaces the placeholder body.
  GorillaCapsule1.Visible := False;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  BuildTerrain();
  LoadCharacter();
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  // Start capturing input only once the form is actually on screen.
  GorillaInputController1.Enabled := True;

  // Builds the collider prefabs (here: the terrain) and starts the simulation.
  GorillaPhysicsSystem1.Active := True;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  // Stop the simulation and release the input hooks before the scene goes away.
  GorillaPhysicsSystem1.Active := False;
  GorillaInputController1.Enabled := False;
end;

end.
