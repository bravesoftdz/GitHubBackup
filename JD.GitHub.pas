unit JD.GitHub;

(*
  JD.GitHub.pas
  Core unit to implement all GitHub related integration

  NOTE: This unit is temporary, and will be re-written as a part of
  a much larger GitHub API wrapper library.

  Main Object: TGitHubAPI

  Usage:
  - Create an instance of TGitHubAPI
  - Assign value to Token (GitHub Personal Access Token - Optional)
    - Ommitting a token will provide public visibility
  - Use "Get" functions to fetch various information from API



*)

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  XSuperObject,
  JD.IndyUtils;

const
  REPO_FLD_NAME = 0;
  REPO_FLD_FULLNAME = 1;
  REPO_FLD_CREATED = 2;
  REPO_FLD_UPDATED = 3;
  REPO_FLD_PUSHED = 4;
  REPO_FLD_LANGUAGE = 5;
  REPO_FLD_DEFAULT_BRANCH = 6;
  REPO_FLD_SIZE = 7;
  REPO_FLD_DESCRIPTION = 8;

type
  TGitHubAPI = class;
  TGitHub = class;
  TGitHubRepo = class;
  TGitHubRepos = class;

  TGitHubAccountType = (gaUser, gaOrganization);

  TGitHubAPI = class(TObject)
  private
    FWeb: TIndyHttpTransport;
    FToken: String;
    procedure SetToken(const Value: String);
  public
    constructor Create;
    destructor Destroy; override;
    property Token: String read FToken write SetToken;
    function GetJSON(const URL: String): ISuperObject;
    function GetMyRepos(const PageNum: Integer): ISuperArray;
    function GetUserRepos(const User: String; const PageNum: Integer): ISuperArray;
    function GetOrgRepos(const Org: String; const PageNum: Integer): ISuperArray;
    function GetBranches(const Owner, Repo: String; const PageNum: Integer = 1): ISuperArray;
    function GetCommits(const Owner, Repo, Branch: String; const PageNum: Integer = 1): ISuperArray;
    function GetTree(const Owner, Repo, Sha: String; const PageNum: Integer = 1;
      const Recursive: Boolean = False): ISuperArray;
  end;

  TGitHub = class(TComponent)
  private
    FApi: TGitHubAPI;
    function GetToken: String;
    procedure SetToken(const Value: String);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Token: String read GetToken write SetToken;
    function GetUserRepos(const User: String; const PageNum: Integer = 0): TGitHubRepos;
    function GetOrgRepos(const Org: String; const PageNum: Integer = 0): TGitHubRepos;
  end;

  TGitHubRepo = class(TObject)
  private
    FObj: ISuperObject;
    function GetB(const N: String): Boolean;
    function GetF(const N: String): Double;
    function GetI(const N: String): Int64;
    function GetS(const N: String): String;
    function GetO(const N: String): ISuperObject;
    function GetCreated: TDateTime;
    function GetDefaultBranch: String;
    function GetDescription: String;
    function GetFullName: String;
    function GetIsPrivate: Boolean;
    function GetLanguage: String;
    function GetName: String;
    function GetPushed: TDateTime;
    function GetSize: Int64;
    function GetUpdated: TDateTime;
  public
    constructor Create(AObj: ISuperObject);
    destructor Destroy; override;
  public
    property S[const N: String]: String read GetS;
    property I[const N: String]: Int64 read GetI;
    property B[const N: String]: Boolean read GetB;
    property F[const N: String]: Double read GetF;
    property O[const N: String]: ISuperObject read GetO;
  public
    property Name: String read GetName;
    property FullName: String read GetFullName;
    property Created: TDateTime read GetCreated;
    property Updated: TDateTime read GetUpdated;
    property Pushed: TDateTime read GetPushed;
    property Language: String read GetLanguage;
    property DefaultBranch: String read GetDefaultBranch;
    property IsPrivate: Boolean read GetIsPrivate;
    property Size: Int64 read GetSize;
    property Description: String read GetDescription;
  end;

  TGitHubRepos = class(TObjectList<TGitHubRepo>)
  private

  public

  end;

procedure ListRepoFields(AStrings: TStrings);

implementation

uses
  System.IOUtils, System.Math, System.StrUtils, Soap.XSBuiltIns;

procedure ListRepoFields(AStrings: TStrings);
begin
  AStrings.Add('Name');
  AStrings.Add('Full Name');
  AStrings.Add('Created');
  AStrings.Add('Updated');
  AStrings.Add('Pushed');
  AStrings.Add('Language');
  AStrings.Add('Default Branch');
  AStrings.Add('Size');
  AStrings.Add('Description');
end;

{ TGitHubAPI }

constructor TGitHubAPI.Create;
begin
  FWeb:= TIndyHttpTransport.Create;
end;

destructor TGitHubAPI.Destroy;
begin
  FreeAndNil(FWeb);
  inherited;
end;

procedure TGitHubAPI.SetToken(const Value: String);
begin
  FToken := Value;
end;

function TGitHubAPI.GetJSON(const URL: String): ISuperObject;
var
  R: String;
begin
  //Root function for all interaction with GitHub API
  //Returns JSON objects via Super Object
  Result:= nil;

  //Clear authentication and provide new credentials
  if Assigned(FWeb.Request.Authentication) then begin
    FWeb.Request.Authentication.Free;
    FWeb.Request.Authentication:=nil;
  end;
  FWeb.Request.Username:= FToken;

  R:= FWeb.Get('https://api.github.com'+URL); //ACTUAL HTTP GET

  Result:= SO(R);
end;

function TGitHubAPI.GetMyRepos(const PageNum: Integer): ISuperArray;
begin
  Result:= GetJSON('/user/repos?page='+IntToStr(PageNum)).AsArray;
end;

function TGitHubAPI.GetOrgRepos(const Org: String; const PageNum: Integer): ISuperArray;
begin
  Result:= GetJSON('/orgs/'+Org+'/repos?page='+IntToStr(PageNum)).AsArray;
end;

function TGitHubAPI.GetUserRepos(const User: String; const PageNum: Integer): ISuperArray;
begin
  Result:= GetJSON('/users/'+User+'/repos?page='+IntToStr(PageNum)).AsArray;
end;

function TGitHubAPI.GetBranches(const Owner, Repo: String; const PageNum: Integer = 1): ISuperArray;
begin
  Result:= GetJSON('/repos/'+Owner+'/'+Repo+'/branches?page='+IntToStr(PageNum)).AsArray;
end;

function TGitHubAPI.GetCommits(const Owner, Repo, Branch: String; const PageNum: Integer = 1): ISuperArray;
begin
  Result:= GetJSON('/repos/'+Owner+'/'+Repo+'/commits?sha='+Branch+'&page='+IntToStr(PageNum)).AsArray;
end;

function TGitHubAPI.GetTree(const Owner, Repo, Sha: String;
  const PageNum: Integer; const Recursive: Boolean): ISuperArray;
begin
  Result:= GetJSON('/repos/'+Owner+'/'+Repo+'/git/trees/'+Sha+
    '?page='+IntToStr(PageNum)+'&recursive='+IfThen(Recursive, 'true', 'false')).AsArray;
end;

{ TGitHub }

constructor TGitHub.Create(AOwner: TComponent);
begin
  inherited;
  FApi:= TGitHubAPI.Create;
end;

destructor TGitHub.Destroy;
begin
  FreeAndNil(FApi);
  inherited;
end;

function TGitHub.GetToken: String;
begin
  Result:= FApi.Token;
end;

function TGitHub.GetUserRepos(const User: String;
  const PageNum: Integer): TGitHubRepos;
var
  Res: ISuperArray;
  O: ISuperObject;
  X: Integer;
  R: TGitHubRepo;
begin
  Result:= TGitHubRepos.Create(False);
  try
    Res:= FApi.GetUserRepos(User, PageNum);
    if Assigned(Res) then begin
      for X := 0 to Res.Length-1 do begin
        O:= Res.O[X];
        R:= TGitHubRepo.Create(O);
        Result.Add(R);
      end;
    end;
  except
    on E: Exception do begin
      Result.Free;
      raise E;
    end;
  end;
end;

function TGitHub.GetOrgRepos(const Org: String;
  const PageNum: Integer): TGitHubRepos;
var
  Res: ISuperArray;
  O: ISuperObject;
  X: Integer;
  R: TGitHubRepo;
begin
  Result:= TGitHubRepos.Create(False);
  try
    Res:= FApi.GetOrgRepos(Org, PageNum);
    if Assigned(Res) then begin
      for X := 0 to Res.Length-1 do begin
        O:= Res.O[X];
        R:= TGitHubRepo.Create(O);
        Result.Add(R);
      end;
    end;
  except
    on E: Exception do begin
      Result.Free;
      raise E;
    end;
  end;
end;

procedure TGitHub.SetToken(const Value: String);
begin
  FApi.Token:= Value;
end;

{ TGitHubRepo }

constructor TGitHubRepo.Create(AObj: ISuperObject);
begin
  FObj:= AObj;
  FObj._AddRef;
end;

destructor TGitHubRepo.Destroy;
begin
  FObj._Release;
  FObj:= nil;
  inherited;
end;

function TGitHubRepo.GetO(const N: String): ISuperObject;
begin
  Result:= FObj.O[N];
end;

function TGitHubRepo.GetS(const N: String): String;
begin
  Result:= FObj.S[N];
end;

function TGitHubRepo.GetB(const N: String): Boolean;
begin
  Result:= FObj.B[N];
end;

function TGitHubRepo.GetF(const N: String): Double;
begin
  Result:= FObj.F[N];
end;

function TGitHubRepo.GetI(const N: String): Int64;
begin
  Result:= FObj.I[N];
end;

function TGitHubRepo.GetCreated: TDateTime;
begin
  with TXSDateTime.Create do
    try
      XSToNative(S['created_at']);
      Result:= AsDateTime;
    finally
      Free;
    end;
end;

function TGitHubRepo.GetDefaultBranch: String;
begin
  Result:= S['default_branch'];
end;

function TGitHubRepo.GetDescription: String;
begin
  Result:= S['description'];
end;

function TGitHubRepo.GetFullName: String;
begin
  Result:= S['full_name'];
end;

function TGitHubRepo.GetIsPrivate: Boolean;
begin
  Result:= B['private'];
end;

function TGitHubRepo.GetLanguage: String;
begin
  Result:= S['language'];
end;

function TGitHubRepo.GetName: String;
begin
  Result:= S['name'];
end;

function TGitHubRepo.GetPushed: TDateTime;
begin
  with TXSDateTime.Create do
    try
      XSToNative(S['pushed_at']);
      Result:= AsDateTime;
    finally
      Free;
    end;
end;

function TGitHubRepo.GetSize: Int64;
begin
  Result:= I['size'];
end;

function TGitHubRepo.GetUpdated: TDateTime;
begin
  with TXSDateTime.Create do
    try
      XSToNative(S['updated_at']);
      Result:= AsDateTime;
    finally
      Free;
    end;
end;

end.
