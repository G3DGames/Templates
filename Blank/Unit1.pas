unit Unit1;

///
/// Gorilla3D - Blank Project Template
///
/// The smallest complete Gorilla3D scene:
///   TGorillaViewport  - render surface and root of the 3D scene
///   TGorillaLight     - a directional light
///   TGorillaCube      - a cube using a TGorillaBlinnMaterialSource
///
/// There is no TGorillaCamera on the form. As long as
/// TGorillaViewport.UsingDesignCamera stays True the viewport renders through
/// its own design camera and its TGorillaSmoothCameraController provides the
/// standard navigation at runtime as well:
///
///   left mouse button    orbit
///   right mouse button   pan
///   mouse wheel          zoom
///
/// Only the starting distance has to be set, because the design camera and its
/// pivot both start at the origin - see FormCreate.
///
/// As soon as you want your own point of view, drop a TGorillaCamera into the
/// viewport, assign it to Viewport.Camera and set UsingDesignCamera to False.
/// Without that last step the assigned camera has no effect.
///

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Types3D,
  Gorilla.Viewport, Gorilla.Light, Gorilla.Cube, Gorilla.Material.Blinn;

type
  TForm1 = class(TForm)
    GorillaViewport1: TGorillaViewport;
    GorillaLight1: TGorillaLight;
    GorillaCube1: TGorillaCube;
    GorillaBlinnMaterialSource1: TGorillaBlinnMaterialSource;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

uses
  Gorilla.Camera;

procedure TForm1.FormCreate(Sender: TObject);
var
  LCamera : TGorillaCamera;
begin
  // Pull the design camera away from its pivot at the origin, otherwise it
  // sits inside the cube. Negative Z is "towards the viewer" in FireMonkey.
  LCamera := GorillaViewport1.GetDesignCamera();
  if Assigned(LCamera) then
    LCamera.Position.Z := -8;
end;

end.
