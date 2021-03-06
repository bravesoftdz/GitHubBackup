unit JD.IndyUtils;

(*
  JD Indy Utils

  Contains customized encapsulation of Indy components for
  ease of use.

  TIndyHttpTransport - Custom TIdHTTP with built-in OpenSSL handling
*)

interface

uses
  IdURI, IdBaseComponent, IdCoder, IdCoder3to4, IdCoderMIME, IdComponent,
  IdTCPConnection, IdTCPClient, IdHTTP, IdIOHandler, IdIOHandlerSocket,
  IdIOHandlerStack, IdSSL, IdSSLOpenSSL, IdGlobal;

type

  TWorkMode = IdComponent.TWorkMode;

  TIndyHttpTransport = class(TIdCustomHTTP)
  public
    constructor Create;
  end;


implementation

{ TIndyHttpTransport }

constructor TIndyHttpTransport.Create;
var
  SSLIO: TIdSSLIOHandlerSocketOpenSSL;
begin
  inherited Create;
  {$IF Declared(IdHTTP.TIdHTTPOption.hoWantProtocolErrorContent)}
  HTTPOptions := HTTPOptions + [hoNoProtocolErrorException, hoWantProtocolErrorContent];
  {$ENDIF}
  SSLIO := TIdSSLIOHandlerSocketOpenSSL.Create(Self);
  SSLIO.SSLOptions.SSLVersions := [sslvTLSv1, sslvTLSv1_1, sslvTLSv1_2];
  SSLIO.SSLOptions.Mode        := sslmClient;
  SSLIO.SSLOptions.VerifyMode  := [];
  SSLIO.SSLOptions.VerifyDepth := 0;
  Self.IOHandler := SSLIO;
  Self.Request.BasicAuthentication:= True;
  Self.Request.Connection:= 'Keep-alive';
  Self.HandleRedirects:= True;

  //Request.UserAgent:= 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:57.0) Gecko/20100101 Firefox/57.0';
  //Request.UserAgent:= 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:57.0) Indy/10.6.2.5341 (Delphi TIdHTTP Component)';

  //TODO: Replace appropriate information as needed
  //Mozilla/5.0 (Windows NT [winver]; [winplat]; [cpuarch]; rv:[winrv]) Indy/[indyver] (Delphi TIdHTTP Component) {appname}/{appver}{;}
  Request.UserAgent:= 'Mozilla/5.0 (Compatible; Indy Library)';

end;

end.
