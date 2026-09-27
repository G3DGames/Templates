program GorillaThirdPerson;

uses
  System.StartUpCopy,
  Gorilla.Context.Backend,
{$IFDEF MSWINDOWS}
  Windows,
{$ENDIF}
  FMX.Forms,
  Unit1 in 'Unit1.pas' {Form1};
  
  {$SetPEFlags IMAGE_FILE_LARGE_ADDRESS_AWARE}
  
begin
  TGorillaSystem.ForceToUseNVIDIAorAMDGPU();
  // Shows a warning dialog when render GPU <> display GPU
  TGorillaSystem.CheckHybridGraphicsState();

  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
