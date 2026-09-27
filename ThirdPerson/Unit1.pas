unit Unit1;

///
/// Gorilla3D - Third Person Scene Template
///
/// A third person scene with a capsule standing in for the player character:
///   TGorillaViewport               - render surface and root of the 3D scene
///   TGorillaInputController        - keyboard / mouse / gamepad input
///   TGorillaThirdPersonController  - turns that input into character movement
///   TGorillaCapsule                - the character body (replace with your model)
///   TGorillaCamera                 - child of the controller = the chase camera
///   TGorillaPlane / TGorillaCube   - ground and a few landmarks
///   TGorillaLight                  - a directional light
///
/// Default controls (registered automatically by the character controller
/// as soon as its InputController property is assigned):
///   W / A / S / D    move
///   Space            jump
///   Left Ctrl        crouch
///   AltGr            crawl
///   Left Shift       run
///   Mouse            orbit the camera
///   Mouse wheel      camera distance
///
/// Both the capsule and the camera are children of the controller, so they
/// move and turn with the character. To use a real character, drop a
/// TGorillaModel next to the capsule and hide the capsule.
///
/// Two things are easy to get wrong:
///   * TGorillaViewport.UsingDesignCamera must be False, otherwise the
///     viewport keeps rendering through its internal design camera and the
///     assigned Camera has no effect.
///   * TGorillaInputController.Enabled is False at design time on purpose -
///     an enabled controller would hook the keyboard inside the IDE.
///     It is switched on in FormShow.
///
/// Remember that in FireMonkey the Y axis points DOWN, so "up" is negative Y.
///

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Types3D,
  Gorilla.Viewport, Gorilla.Camera, Gorilla.Light, Gorilla.Plane, Gorilla.Cube,
  Gorilla.Capsule, Gorilla.Material.Blinn, Gorilla.Controller.Input,
  Gorilla.Controller.Input.ThirdPerson;

type
  TForm1 = class(TForm)
    GorillaViewport1: TGorillaViewport;
    GorillaLight1: TGorillaLight;
    GorillaPlane1: TGorillaPlane;
    GorillaGroundMaterial: TGorillaBlinnMaterialSource;
    GorillaCube1: TGorillaCube;
    GorillaCube2: TGorillaCube;
    GorillaCube3: TGorillaCube;
    GorillaCubeMaterial: TGorillaBlinnMaterialSource;
    GorillaThirdPersonController1: TGorillaThirdPersonController;
    GorillaCapsule1: TGorillaCapsule;
    GorillaCharacterMaterial: TGorillaBlinnMaterialSource;
    GorillaCamera1: TGorillaCamera;
    GorillaInputController1: TGorillaInputController;
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

procedure TForm1.FormShow(Sender: TObject);
begin
  // Start capturing input only once the form is actually on screen.
  GorillaInputController1.Enabled := True;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  // Release the input hooks before the scene goes away.
  GorillaInputController1.Enabled := False;
end;

end.
