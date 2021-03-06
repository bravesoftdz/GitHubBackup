unit uMain;

(*
  JD GitHub Backup Main Form

  Fundamental usage of this form is to display a list of repositories,
  allow the user to check which ones they wish to back up, and
  download all of them in one go. Additional tools are provided to
  assist user in filtering, sorting, and deciding which ones they want.
  Then, download all at once and monitor progress.
*)

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellApi,
  System.SysUtils, System.Variants, System.Classes,
  System.Generics.Collections, System.Generics.Defaults,
  System.UITypes, System.Win.TaskbarCore, System.Actions,
  System.Types, System.Win.ComObj, Winapi.ShlObj,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons,
  Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.Taskbar, Vcl.CheckLst,
  Vcl.Menus, Vcl.PlatformDefaultStyleActnCtrls,
  Vcl.ActnList, Vcl.ActnMan, System.ImageList, Vcl.ImgList,
  Vcl.AppEvnts, Vcl.ToolWin, Vcl.HtmlHelpViewer,

  Vcl.Styles, Vcl.Themes,

  Vcl.Styles.Fixes,
  Vcl.Styles.Hooks,
  Vcl.Styles.Utils.Menus,
  Vcl.Styles.Utils.Forms,
  Vcl.Styles.Utils.StdCtrls,
  Vcl.Styles.Utils.ComCtrls,
  Vcl.Styles.Utils.ScreenTips,
  Vcl.Styles.Utils.SysControls,
  Vcl.Styles.Utils.SysStyleHook,
  Vcl.Styles.FontAwesome, //Used to include font for icon glyphs
  Vcl.Styles.NC, //Used for main menu

  JD.GitHub,
  JD.IndyUtils,
  JD.GitHub.Common,
  JD.DownloadThread,
  uSetup,
  uRepoDetail,
  uDM,
  uAbout,
  XSuperObject;

type
  {$WARN SYMBOL_PLATFORM OFF}
  TfrmMain = class(TForm)
    Stat: TStatusBar;
    tmrDisplay: TTimer;
    Acts: TActionManager;
    actSetup: TAction;
    actRefresh: TAction;
    actConfigCols: TAction;
    actCheckAll: TAction;
    actCheckNone: TAction;
    actCheckSelected: TAction;
    actDownloadRepos: TAction;
    actExit: TAction;
    actCancelDownload: TAction;
    actSortAZ: TAction;
    pRepoTop: TPanel;
    btnListRepos: TButton;
    btnDownload: TButton;
    btnCancel: TButton;
    lstRepos: TListView;
    spErrorLog: TSplitter;
    pErrorLog: TPanel;
    pErrorLogTitle: TPanel;
    lblErrorLogTitle: TLabel;
    btnCloseErrorLog: TButton;
    txtErrorLog: TMemo;
    chkCheckAll: TCheckBox;
    Prog: TProgressBar;
    actAbout: TAction;
    actHelpContents: TAction;
    AppEvents: TApplicationEvents;
    mRepos: TPopupMenu;
    MenuItem17: TMenuItem;
    MenuItem18: TMenuItem;
    CheckAll3: TMenuItem;
    CheckNone3: TMenuItem;
    CheckSelected3: TMenuItem;
    Cancel3: TMenuItem;
    N11: TMenuItem;
    Exit3: TMenuItem;
    mOptions: TPopupMenu;
    MenuItem20: TMenuItem;
    mView: TPopupMenu;
    MenuItem38: TMenuItem;
    mHelp: TPopupMenu;
    MenuItem56: TMenuItem;
    ConfigureColumns1: TMenuItem;
    About1: TMenuItem;
    actMenuRepos: TAction;
    actMenuOptions: TAction;
    actMenuView: TAction;
    actMenuHelp: TAction;
    mSort: TMenuItem;
    mSortAsc: TMenuItem;
    mSortDesc: TMenuItem;
    N1: TMenuItem;
    tmrFilter: TTimer;
    Panel1: TPanel;
    btnClearFilter: TButton;
    txtFilter: TEdit;
    actFind: TAction;
    actClearFilter: TAction;
    Panel2: TPanel;
    mProfiles: TMenuItem;
    Setup1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    pSort: TPanel;
    btnSortDir: TButton;
    cboSort: TComboBox;
    Label4: TLabel;
    actSetupProfiles: TAction;
    procedure actRefreshExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure actDownloadReposExecute(Sender: TObject);
    procedure lstReposClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure chkCheckAllClick(Sender: TObject);
    procedure tmrDisplayTimer(Sender: TObject);
    procedure actCancelDownloadExecute(Sender: TObject);
    procedure btnSortDirClick(Sender: TObject);
    procedure cboSortClick(Sender: TObject);
    procedure lstReposItemChecked(Sender: TObject; Item: TListItem);
    procedure btnCloseErrorLogClick(Sender: TObject);
    procedure actExitExecute(Sender: TObject);
    procedure actCheckAllExecute(Sender: TObject);
    procedure actCheckNoneExecute(Sender: TObject);
    procedure actCheckSelectedExecute(Sender: TObject);
    procedure actConfigColsExecute(Sender: TObject);
    procedure actSetupExecute(Sender: TObject);
    procedure ActsUpdate(Action: TBasicAction; var Handled: Boolean);
    procedure lstReposDblClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure mSortAscOrDescClick(Sender: TObject);
    procedure actAboutExecute(Sender: TObject);
    procedure actHelpContentsExecute(Sender: TObject);
    function AppEventsHelp(Command: Word; Data: NativeInt;
      var CallHelp: Boolean): Boolean;
    procedure MenuReposClick(Sender: TObject);
    procedure MenuOptionsClick(Sender: TObject);
    procedure MenuViewClick(Sender: TObject);
    procedure MenuHelpClick(Sender: TObject);
    procedure tmrFilterTimer(Sender: TObject);
    procedure txtFilterChange(Sender: TObject);
    procedure actClearFilterExecute(Sender: TObject);
    procedure lstReposColumnClick(Sender: TObject; Column: TListColumn);
    procedure actFindExecute(Sender: TObject);
    procedure actSetupProfilesExecute(Sender: TObject);
  private
    FEnabled: Boolean; //Whether UI controls should be enabled, used for busy state
    FRepos: TGitHubRepos; //Master list of repositories
    FCurFile: TDownloadFile; //Current file being downloaded, nil if none
    FCurPos: Integer; //Download progress current value
    FCurMax: Integer; //Download progress max value
    FThreadCancel: TThreadCancelEvent; //Pointer to thread procedure to cancel
    FNCControls: TNCControls; //Non-client menu buttons
    FTaskbarList: ITaskbarList;
    FTaskbarList2: ITaskbarList2;
    FTaskbarList3: ITaskbarList3;
    FTaskbarList4: ITaskbarList4;

    procedure SetupNC;
    procedure SetTitle;
    procedure DpiChanged(var Msg: TWMDpi); message WM_DPICHANGED;
    procedure CloseHelpWnd;
    function OpenHelp(const AContextID: Integer): Boolean;

    procedure LoadConfig;
    procedure SaveConfig;
    function AppIsConfigured: Boolean;

    procedure PopulateProfiles;
    procedure ProfileMenuClick(Sender: TObject);
    procedure SetProfileIndex(const Index: Integer);

    function GetRepos(const PageNum: Integer): TGitHubRepos;
    procedure GetRepoPage(const PageNum: Integer);
    procedure SortRepos;
    procedure DisplayRepos;
    procedure ClearRepos;
    procedure PopulateMainMenuSort;
    function RepoSort: Integer;
    procedure MenuSortClick(Sender: TObject);

    procedure UpdateCheckAll;
    function CheckedCount: Integer;
    function VisibleCount: Integer;
    function VisibleCheckedCount: Integer;
    procedure UpdateDownloadAction;
    procedure SetEnabledState(const Enabled: Boolean);

    function CreateDownloadThread: TDownloadThread;
    procedure ThreadBegin(Sender: TObject);
    procedure ThreadDone(Sender: TObject);
    procedure ThreadException(Sender: TObject; const CurFile: TDownloadFile);
    procedure ThreadProgress(Sender: TObject; const Cur, Max: Integer;
      const CurFile: TDownloadFile);

    procedure ShowErrorLog(const AShow: Boolean = True);
  public
  end;
  {$WARN SYMBOL_PLATFORM ON}

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses
  System.IOUtils, System.DateUtils, System.Math, System.StrUtils;

type
  PRepoRec = ^TRepoRec;

  TRepoRec = packed record
    Repo: TGitHubRepo;
  end;

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
{$IFDEF DEBUG}
var
  T: String;
{$ENDIF}
begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown:= True;
  {$ENDIF}

  FRepos:= TGitHubRepos.Create(True);


  //Issue #46 - TTaskbar bugs
  //http://www.drbob42.com/examines/examinC5.htm
  FTaskbarList:= CreateComObject(CLSID_TaskbarList) as ITaskbarList3;
  FTaskbarList.HrInit;
  Supports(FTaskbarList, IID_ITaskbarList2, FTaskbarList2);
  Supports(FTaskbarList, IID_ITaskbarList3, FTaskbarList3);
  Supports(FTaskbarList, IID_ITaskbarList4, FTaskbarList4);


  {$IFDEF DEBUG}
  //If debug build, use CHM from release folder
  T:= IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName));
  T:= T + '..\..\..\Bin\Win32\';
  T:= TPath.Combine(T, 'JDGitHubBackupHelp.chm');
  Application.HelpFile:= T;
  {$ELSE}
  Application.HelpFile:= TPath.Combine(ExtractFilePath(Application.ExeName), 'JDGitHubBackupHelp.chm');
  {$ENDIF}

  //Prepare UI Controls
  lstRepos.Align:= alClient;
  txtErrorLog.Align:= alClient;
  SetEnabledState(True);
  ShowErrorLog(False);
  SetupNC;

  //Populate list of columns that can be sorted
  cboSort.Items.Clear;
  ListRepoFields(cboSort.Items);
  cboSort.ItemIndex:= 0;
  PopulateMainMenuSort;

end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FRepos);
  CloseHelpWnd;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  LoadConfig;
  PopulateProfiles;
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveConfig;
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  //Protect from closing app while busy
  //TODO: Prompt to cancel download if in progress
  if not FEnabled then begin
    CanClose:= False;
    MessageDlg('Cannot close while download is in progress.', mtError, [mbOK], 0);
  end;
end;

procedure TfrmMain.SetupNC;
begin
 FNCControls := TNCControls.Create(Self);
 //NCControls.Images := Img24;
 FNCControls.ShowSystemMenu:= False;

 FNCControls.Controls.AddEx<TNCButton>;
 FNCControls[0].GetAs<TNCButton>.Style := nsSplitButton;
 FNCControls[0].GetAs<TNCButton>.ImageStyle := isGrayHot;
 FNCControls[0].GetAs<TNCButton>.ImageIndex := 71;
 FNCControls[0].BoundsRect := Rect(1,1,120,32);
 FNCControls[0].Caption := '&Repositories';
 FNCControls[0].GetAs<TNCButton>.DropDownMenu:= mRepos;
 FNCControls[0].GetAs<TNCButton>.OnClick := MenuReposClick;

 FNCControls.Controls.AddEx<TNCButton>;
 FNCControls[1].GetAs<TNCButton>.Style := nsSplitButton;
 FNCControls[1].GetAs<TNCButton>.ImageStyle := isGrayHot;
 FNCControls[1].GetAs<TNCButton>.ImageIndex := 33;
 FNCControls[1].BoundsRect := Rect(121,1,220,32);
 FNCControls[1].Caption := '&Options';
 FNCControls[1].GetAs<TNCButton>.DropDownMenu:= mOptions;
 FNCControls[1].GetAs<TNCButton>.OnClick := MenuOptionsClick;

 FNCControls.Controls.AddEx<TNCButton>;
 FNCControls[2].GetAs<TNCButton>.Style := nsSplitButton;
 FNCControls[2].GetAs<TNCButton>.ImageStyle := isGrayHot;
 FNCControls[2].GetAs<TNCButton>.ImageIndex := 55;
 FNCControls[2].BoundsRect := Rect(221,1,300,32);
 FNCControls[2].Caption := '&View';
 FNCControls[2].GetAs<TNCButton>.DropDownMenu:= mView;
 FNCControls[2].GetAs<TNCButton>.OnClick := MenuViewClick;

 FNCControls.Controls.AddEx<TNCButton>;
 FNCControls[3].GetAs<TNCButton>.Style := nsSplitButton;
 FNCControls[3].GetAs<TNCButton>.ImageStyle := isGrayHot;
 FNCControls[3].GetAs<TNCButton>.ImageIndex := 94;
 FNCControls[3].BoundsRect := Rect(301,1,380,32);
 FNCControls[3].Caption := '&Help';
 FNCControls[3].GetAs<TNCButton>.DropDownMenu:= mHelp;
 FNCControls[3].GetAs<TNCButton>.OnClick := MenuHelpClick;

end;

procedure TfrmMain.MenuReposClick(Sender: TObject);
var
  P: TPoint;
begin
  P.X:= FNCControls[0].Left - 6;
  P.Y:= 0;
  P:= ClientToScreen(P);
  mRepos.Popup(P.X, P.Y);
end;

procedure TfrmMain.MenuOptionsClick(Sender: TObject);
var
  P: TPoint;
begin
  P.X:= FNCControls[1].Left - 6;
  P.Y:= 0;
  P:= ClientToScreen(P);
  mOptions.Popup(P.X, P.Y);
end;

procedure TfrmMain.MenuViewClick(Sender: TObject);
var
  P: TPoint;
begin
  P.X:= FNCControls[2].Left - 6;
  P.Y:= 0;
  P:= ClientToScreen(P);
  mView.Popup(P.X, P.Y);
end;

procedure TfrmMain.MenuHelpClick(Sender: TObject);
var
  P: TPoint;
begin
  P.X:= FNCControls[3].Left - 6;
  P.Y:= 0;
  P:= ClientToScreen(P);
  mHelp.Popup(P.X, P.Y);
end;

procedure TfrmMain.LoadConfig;
begin
  frmSetup.LoadFromConfig;
  //TODO: If app is not yet configured, clearly notify user, and enter setup

  cboSort.ItemIndex:= DM.Config.I['sortCol'];
  btnSortDir.Tag:= DM.Config.I['sortDir'];
  case btnSortDir.Tag of
    0: btnSortDir.Caption:= 'A..Z';
    1: btnSortDir.Caption:= 'Z..A';
  end;
  SortRepos;
  SetTitle;
end;

procedure TfrmMain.SaveConfig;
begin
  DM.Config.I['sortCol']:= cboSort.ItemIndex;
  DM.Config.I['sortDir']:= btnSortDir.Tag;
  frmSetup.SaveToConfig; //TODO: Is this the best place for this?
  SetTitle;
end;

function TfrmMain.RepoSort: Integer;
begin
  //Which column index to sort by
  Result:= cboSort.ItemIndex;
end;

function TfrmMain.GetRepos(const PageNum: Integer): TGitHubRepos;
begin
  //Fetch repository list from API for a given page number...
  Result:= nil;
  DM.GitHub.Token:= frmSetup.Token; //TODO: Find a better place for this
  case frmSetup.UserType of
    gaUser:         Result:= DM.GitHub.GetUserRepos(frmSetup.User, PageNum);
    gaOrganization: Result:= DM.GitHub.GetOrgRepos(frmSetup.User, PageNum);
  end;
end;

procedure TfrmMain.GetRepoPage(const PageNum: Integer);
var
  Lst: TGitHubRepos;
  X: Integer;
  Cont: Boolean;
begin
  //Fetches a single page of repositories
  Application.ProcessMessages; //TODO: Eliminate the need for this garbage

  try
    //Fetch actual page of repositories
    Lst:= GetRepos(PageNum);
    try
      for X := 0 to Lst.Count-1 do begin
        FRepos.Add(Lst[X]);
      end;
      Cont:= Lst.Count > 0;
    finally
      FreeAndNil(Lst);
    end;
    if Cont then
      GetRepoPage(PageNum+1); //RECURSIVE - Get next page
  except
    on E: Exception do begin
      if E <> nil then
        MessageDlg('Error getting repositories: '+E.Message, mtError, [mbOK], 0)
      else
        MessageDlg('CRITICAL Error getting repositories!!!', mtError, [mbOK], 0);
    end;
  end;
end;

procedure TfrmMain.SortRepos;
var
  X: Integer;
begin
  //TODO: Support virtually any column...

  case btnSortDir.Tag of
    0: mSortAsc.Checked:= True;
    1: mSortDesc.Checked:= True;
  end;

  //Select sorting field in main menu
  for X := 0 to mSort.Count-1 do begin
    if (mSort.Items[X].GroupIndex = 1) and (mSort.Items[X].Tag = cboSort.ItemIndex) then begin
      mSort.Items[X].Checked:= True;
    end;
  end;

  FRepos.Sort(TComparer<TGitHubRepo>.Construct(
    function (const L, R: TGitHubRepo): Integer
    var
      Dir: Integer;
    begin

      //Asc = 1, Desc = -1
      if btnSortDir.Tag = 0 then
        Dir:= 1
      else
        Dir:= -1;

      case RepoSort of
        REPO_FLD_NAME: begin
          Result:= CompareText(L.Name, R.Name) * Dir;
        end;
        REPO_FLD_FULLNAME: begin
          Result:= CompareText(L.FullName, R.FullName) * Dir;
        end;
        REPO_FLD_CREATED: begin
          Result:= CompareDateTime(L.Created, R.Created) * Dir;
        end;
        REPO_FLD_UPDATED: begin
          Result:= CompareDateTime(L.Updated, R.Updated) * Dir;
        end;
        REPO_FLD_PUSHED: begin
          Result:= CompareDateTime(L.Pushed, R.Pushed) * Dir;
        end;
        REPO_FLD_LANGUAGE: begin
          Result:= CompareText(L.Language, R.Language) * Dir;
        end;
        REPO_FLD_DEFAULT_BRANCH: begin
          Result:= CompareText(L.DefaultBranch, R.DefaultBranch) * Dir;
        end;
        REPO_FLD_SIZE: begin
          Result:= CompareValue(L.Size, R.Size) * Dir;
        end;
        REPO_FLD_DESCRIPTION: begin
          Result:= CompareText(L.Description, R.Description) * Dir;
        end;
        else begin
          Result:= 0;
        end;
      end;
    end
  ));
  DisplayRepos;
end;

procedure TfrmMain.DisplayRepos;
var
  X: Integer;
  O: TGitHubRepo;
  I: TListItem;
begin
  //Populates list view with repository items
  //TODO: Change entire mechanism to use Add/Edit/Delete events
  lstRepos.Items.BeginUpdate;
  try
    lstRepos.Items.Clear;
    lstRepos.OnItemChecked:= nil;
    try
      for X := 0 to FRepos.Count-1 do begin
        O:= FRepos[X];

        if (txtFilter.Text = '') or
          ((txtFilter.Text <> '') and  (ContainsText(O.Name, txtFilter.Text))) then
        begin

          I:= lstRepos.Items.Add;
          I.Data:= O;
          I.Caption:= O.Name;
          I.SubItems.Add(O.DefaultBranch);
          if O.IsPrivate = True then
            I.SubItems.Add('Private')
          else
            I.SubItems.Add('Public');
          I.SubItems.Add(O.Language);
          I.SubItems.Add(DataSizeStr(O.Size * 1024)); //TODO: NOT RELIABLE!!!
          I.SubItems.Add(FormatDateTime('yyyy-mm-dd h:nn ampm', O.Pushed));
          I.SubItems.Add(O.Description);
          I.Checked:= O.Checked;

        end;
      end;
    finally
      lstRepos.OnItemChecked:= lstReposItemChecked;
    end;
  finally
    lstRepos.Items.EndUpdate;
  end;

  if txtFilter.Text = '' then begin
    Stat.Panels[0].Text:= IntToStr(FRepos.Count)+' Repositories';
  end else begin
    Stat.Panels[0].Text:= IntToStr(VisibleCount)+' of '+IntToStr(FRepos.Count)+' Repositories';
  end;

  UpdateCheckAll;

end;

procedure TfrmMain.DpiChanged(var Msg: TWMDpi);
begin
  //TODO: Fix alignment issue #47 when Windows DPI settings change and
  //control alignment gets messed up.
  inherited;

  //Actually, we don't need to do anything here because I changed these controls
  //to not be aligned in teh first place.

end;

procedure TfrmMain.CloseHelpWnd;
var
  HlpWind: HWND;
const
  HelpTitle = 'JD GitHub Backup Help';
begin
  //Fix for Help Window: https://stackoverflow.com/questions/44378837/chm-file-not-displaying-correctly-when-delphi-vcl-style-active?rq=1
  HlpWind := FindWindow('HH Parent', HelpTitle);
  if HlpWind <> 0 then PostMessage(HlpWind, WM_Close, 0, 0);
end;

function TfrmMain.OpenHelp(const AContextID: Integer): Boolean;
var
  Params: String;
  R: Integer;
begin
  //Fix for Help Window: https://stackoverflow.com/questions/44378837/chm-file-not-displaying-correctly-when-delphi-vcl-style-active?rq=1
  CloseHelpWnd;

  Params:= '';
  if AContextID > 0 then begin
    Params:= Params + ' -mapid ' + IntToStr(AContextID);
  end else begin
    Params:= Params + ' -mapid 1000';
  end;
  Params:= Params + ' ms-its:' + Application.HelpFile;

  R:= ShellExecuteW(0, 'open', 'hh.exe', PWideChar(Params), nil, SW_SHOW);
  Result := R = 32;
end;

function TfrmMain.AppEventsHelp(Command: Word; Data: NativeInt;
  var CallHelp: Boolean): Boolean;
begin
  //Fix for Help Window: https://stackoverflow.com/questions/44378837/chm-file-not-displaying-correctly-when-delphi-vcl-style-active?rq=1
  Result:= OpenHelp(Data);
  CallHelp := False;
end;

function TfrmMain.AppIsConfigured: Boolean;
var
  P: TGitHubProfile;
begin
  //TODO: Implement auth and repo accounts...

  P:= frmSetup.CurProfile;
  Result:= P.AccountName <> '';
  if Result then
    Result:= P.DownloadDir <> '';
end;

procedure TfrmMain.actRefreshExecute(Sender: TObject);
begin
  //Performs actual refresh of repository list
  if AppIsConfigured then begin
    Screen.Cursor:= crHourglass;
    try
      SetEnabledState(False);
      try
        Stat.Panels[1].Text:= 'Listing Repos...';
        try
          FRepos.Clear;

          //Start with page 1, will automatically traverse to all pages...
          GetRepoPage(1);

          Application.ProcessMessages;
          SortRepos;
        finally
          Stat.Panels[1].Text:= 'Ready';
        end;
      finally
        SetEnabledState(True);
      end;
    finally
      Screen.Cursor:= crDefault;
    end;
  end else begin
    MessageDlg('Application has not yet been fully configured. Please visit the Setup and fill it out.', mtError, [mbOK], 0);
    actSetup.Execute;
  end;

  UpdateDownloadAction;
  UpdateCheckAll;
end;

procedure TfrmMain.btnSortDirClick(Sender: TObject);
begin
  //Change between ascending and descending
  case btnSortDir.Tag of
    0: begin
      btnSortDir.Tag:= 1;
      btnSortDir.Caption:= 'Z..A';
    end;
    1: begin
      btnSortDir.Tag:= 0;
      btnSortDir.Caption:= 'A..Z';
    end;
  end;
  SortRepos;
end;

procedure TfrmMain.cboSortClick(Sender: TObject);
begin
  SortRepos;
end;

procedure TfrmMain.UpdateDownloadAction;
var
  C: Integer;
begin
  //Change download option depending on selection
  C:= CheckedCount;
  if C > 0 then begin
    actDownloadRepos.Caption:= 'Download '+IntToStr(C)+' Checked';
    actDownloadRepos.Enabled:= FEnabled;
  end else begin
    actDownloadRepos.Caption:= 'Download';
    actDownloadRepos.Enabled:= False;
  end;
end;

function TfrmMain.VisibleCheckedCount: Integer;
var
  X: Integer;
begin
  Result:= 0;
  for X := 0 to VisibleCount-1 do
    if lstRepos.Items[X].Checked then
      Inc(Result);
end;

function TfrmMain.VisibleCount: Integer;
begin
  Result:= lstRepos.Items.Count;
end;

procedure TfrmMain.UpdateCheckAll;
var
  C: Integer;
begin
  //Change check all option depending on selection
  chkCheckAll.Tag:= 1;
  try
    C:= VisibleCheckedCount;
    if C = 0 then begin
      chkCheckAll.State:= TCheckBoxState.cbUnchecked;
    end else
    if C = VisibleCount then begin
      chkCheckAll.State:= TCheckBoxState.cbChecked;
    end else begin
      chkCheckAll.State:= TCheckBoxState.cbGrayed;
    end;

  finally
    chkCheckAll.Tag:= 0;
  end;
end;

procedure TfrmMain.lstReposClick(Sender: TObject);
begin
  if FEnabled then begin
    UpdateDownloadAction;
    UpdateCheckAll;
  end;
end;

procedure TfrmMain.lstReposColumnClick(Sender: TObject; Column: TListColumn);
begin
  //TODO: Sort by given column...
  case Column.Index of
    0: begin
      //Name

    end;
    1: begin
      //Default Branch

    end;
    2: begin
      //Visibility

    end;
    3: begin
      //Language

    end;
    4: begin
      //Size

    end;
    5: begin
      //Last Pushed

    end;
    6: begin
      //Description

    end;
  end;
end;

procedure TfrmMain.lstReposDblClick(Sender: TObject);
var
  I: TListItem;
  R: TGitHubRepo;
  F: TfrmRepoDetail;
begin
  //Open details of repository
  I:= lstRepos.Selected;
  if Assigned(I) then begin
    R:= TGitHubRepo(I.Data);
    F:= TfrmRepoDetail.Create(nil);
    try
      F.LoadRepo(R);
      F.ShowModal;
    finally
      F.Free;
    end;
  end;
end;

procedure TfrmMain.lstReposItemChecked(Sender: TObject; Item: TListItem);
var
  R: TGitHubRepo;
begin
  //User checked or unchecked a repo...
  if lstRepos.Tag <> 0 then begin
    //Revert back to prior state
    lstRepos.OnItemChecked:= nil;
    try
      Item.Checked:= not Item.Checked;
    finally
      lstRepos.OnItemChecked:= lstReposItemChecked;
    end;
  end else begin
    if FEnabled then begin
      R:= TGitHubRepo(Item.Data);
      R.Checked:= Item.Checked;
      UpdateDownloadAction;
      UpdateCheckAll;
    end;
  end;
end;

procedure TfrmMain.PopulateMainMenuSort;
var
  L: TStringList;
  X: Integer;
  M: TMenuItem;
begin
  //Populate menu items in the main menu for column sorting...
  //IMPORTANT: This shall be a one-time thing, due to the nature
  //of how this particular submenu is formatted.

  L:= TStringList.Create;
  try
    ListRepoFields(L);
    for X := 0 to L.Count-1 do begin
      //mSort
      M:= TMenuItem.Create(mSort);
      M.Caption:= L[X];
      M.Tag:= X;
      M.AutoCheck:= True;
      M.RadioItem:= True;
      M.GroupIndex:= 1;
      M.OnClick:= MenuSortClick;
      if X = cboSort.ItemIndex then
        M.Checked:= True;
      mSort.Add(M);
    end;
  finally
    L.Free;
  end;

end;

procedure TfrmMain.PopulateProfiles;
var
  M: TMenuItem;
  X: Integer;
  P: TGitHubProfile;
begin
  //First clear the old ones...
  for X := mProfiles.Count-1 downto 0 do begin
    M:= mProfiles.Items[X];
    if M.GroupIndex = 1 then
      mProfiles.Delete(X);
  end;

  for X := 0 to frmSetup.Profiles.Count-1 do begin
    P:= frmSetup.Profiles[X];
    M:= TMenuItem.Create(mProfiles);
    M.Caption:= P.Title;
    M.Tag:= X;
    M.AutoCheck:= True;
    M.RadioItem:= True;
    M.GroupIndex:= 1;
    M.OnClick:= ProfileMenuClick;
    if X = frmSetup.ProfileIndex then begin
      M.Checked:= True;
    end;
    mProfiles.Add(M);
  end;

  //SetProfileIndex(frmSetup.ProfileIndex);

end;

procedure TfrmMain.SetProfileIndex(const Index: Integer);
var
  X: Integer;
  M: TMenuItem;
begin
  frmSetup.ProfileIndex:= Index;
  DM.Config.I['profileIndex']:= Index;
  for X := 0 to mProfiles.Count-1 do begin
    M:= mProfiles.Items[X];
    if (M.GroupIndex = 1) and (M.Tag = X) then begin
      M.Checked:= True;
      Break;
    end;
  end;
  SetTitle;
  ClearRepos;
end;

procedure TfrmMain.ProfileMenuClick(Sender: TObject);
begin
  SetProfileIndex(TMenuItem(Sender).Tag);
end;

procedure TfrmMain.MenuSortClick(Sender: TObject);
var
  M: TMenuItem;
begin
  M:= TMenuItem(Sender);
  Self.cboSort.ItemIndex:= M.Tag;
  Self.SortRepos;
end;

procedure TfrmMain.mSortAscOrDescClick(Sender: TObject);
begin
  if mSortAsc.Checked then begin
    Self.btnSortDir.Caption:= 'A..Z';
    Self.btnSortDir.Tag:= 0;
  end else begin
    Self.btnSortDir.Caption:= 'Z..A';
    Self.btnSortDir.Tag:= 1;
  end;
  Self.SortRepos;
end;

procedure TfrmMain.actCheckAllExecute(Sender: TObject);
begin
  //Check All...
  Self.chkCheckAll.Checked:= True;
end;

procedure TfrmMain.actCheckNoneExecute(Sender: TObject);
begin
  //Check None...
  Self.chkCheckAll.Checked:= False;
end;

procedure TfrmMain.actCheckSelectedExecute(Sender: TObject);
begin
  //Check Selected...
  if Self.lstRepos.ItemIndex >= 0 then begin
    lstRepos.Selected.Checked:= not lstRepos.Selected.Checked;
  end;
end;

procedure TfrmMain.ClearRepos;
begin
  Screen.Cursor:= crHourglass;
  try
    SetEnabledState(False);
    try
      Stat.Panels[1].Text:= 'Clearing Repos...';
      try
        FRepos.Clear;
        Application.ProcessMessages;
        SortRepos;
      finally
        Stat.Panels[1].Text:= 'Ready';
      end;
    finally
      SetEnabledState(True);
    end;
  finally
    Screen.Cursor:= crDefault;
  end;
end;

procedure TfrmMain.actSetupExecute(Sender: TObject);
//var
  //P: TGitHubProfile;
begin
  //Setup App...

  frmSetup.LoadFromConfig;
  if frmSetup.ShowModal = mrOK then begin
    frmSetup.SaveToConfig;

    if frmSetup.lstProfiles.ItemIndex >= 0 then begin
      SetProfileIndex(frmSetup.lstProfiles.ItemIndex);
    end;

    //TODO: Clear list if accounts change #45
    //if (not SameText(frmSetup.User, FCurAccount)) or (frmSetup.UserType <> Integer(FCurAccountType)) then begin
      ClearRepos;
    //end;

    PopulateProfiles;

  end;
end;

procedure TfrmMain.actSetupProfilesExecute(Sender: TObject);
begin
  frmSetup.Pages.ActivePageIndex:= 1; //Profile page
  actSetup.Execute;
end;

procedure TfrmMain.actConfigColsExecute(Sender: TObject);
begin
  //Configure Columns...

end;

procedure TfrmMain.actExitExecute(Sender: TObject);
begin
  //Terminate application
  //NOTE: Close will initiate a prompt if it's currently busy
  //which may prevent the user from exiting
  Close;
end;

procedure TfrmMain.actFindExecute(Sender: TObject);
begin
  try
    txtFilter.SetFocus;
    txtFilter.SelectAll;
  except
  end;
end;

procedure TfrmMain.actHelpContentsExecute(Sender: TObject);
begin
  //Open the help file to its default topic
  Application.HelpContext(0);
end;

function TfrmMain.CheckedCount: Integer;
var
  X: Integer;
begin
  //Returns number of checked repos
  Result:= 0;
  for X := 0 to FRepos.Count-1 do begin
    if FRepos[X].Checked then
      Inc(Result);
  end;
end;

procedure TfrmMain.chkCheckAllClick(Sender: TObject);
var
  X: Integer;
  R: TGitHubRepo;
begin
  //User clicked on check all checkbox at top of list
  //NOTE: This is also triggered when "Check All" or "Check None"
  //  actions are executed.
  if chkCheckAll.Tag = 0 then begin
    lstRepos.OnItemChecked:= nil;
    try
      lstRepos.Items.BeginUpdate;
      try
        for X := 0 to VisibleCount-1 do begin
          lstRepos.Items[X].Checked:= chkCheckAll.Checked;
          R:= TGitHubRepo(lstRepos.Items[X].Data);
          R.Checked:= chkCheckAll.Checked;
        end;
      finally
        lstRepos.Items.EndUpdate;
      end;
      UpdateDownloadAction;
    finally
      lstRepos.OnItemChecked:= lstReposItemChecked;
    end;
  end;
end;

procedure TfrmMain.ActsUpdate(Action: TBasicAction; var Handled: Boolean);
begin
  //Adjust actions based on current state of application...
  SetEnabledState(FEnabled);
end;

procedure TfrmMain.SetEnabledState(const Enabled: Boolean);
begin
  //Set UI enabled controls based on current state
  FEnabled:= Enabled;
  actRefresh.Enabled:= Enabled;
  chkCheckAll.Enabled:= Enabled;
  actCheckAll.Enabled:= Enabled;
  actCheckNone.Enabled:= Enabled;
  actCheckSelected.Enabled:= Enabled;
  actSetup.Enabled:= Enabled;
  cboSort.Enabled:= Enabled;
  mSort.Enabled:= Enabled;
  btnSortDir.Enabled:= Enabled;
  txtFilter.Enabled:= Enabled;
  btnClearFilter.Enabled:= Enabled;
  mProfiles.Enabled:= Enabled;
  UpdateDownloadAction;
end;

procedure TfrmMain.SetTitle;
var
  S: String;
begin
  Caption:= 'JD GitHub Backup';
  S:= frmSetup.Title + ' (' + frmSetup.User + ')';
  if S <> '' then
    Caption:= Caption + ' - ' + S;
end;

procedure TfrmMain.ThreadBegin(Sender: TObject);
begin
  //Triggered when download thread begins work
  SetEnabledState(False);
  txtErrorLog.Lines.Clear;
  ShowErrorLog(False);
  actCancelDownload.Enabled:= True;
  Stat.Panels[1].Text:= 'Downloading...';
  Prog.Visible:= True;
  Prog.Position:= 0;
  UpdateDownloadAction;
  lstRepos.Tag:= 1;
end;

procedure TfrmMain.ThreadDone(Sender: TObject);
begin
  //Triggered when download thread is done with all work
  FCurFile:= nil;
  FThreadCancel:= nil;
  actCancelDownload.Enabled:= False;
  lstRepos.Tag:= 0;
  SetEnabledState(True);
  Stat.Panels[1].Text:= 'Ready';
  Prog.Visible:= False;
  Stat.Panels[2].Text:= '';

  //If any errors, show...
  if txtErrorLog.Lines.Text <> '' then begin
    ShowErrorLog(True);
    MessageDlg('Download completed with errors.', mtWarning, [mbOK], 0);
  end else begin
    MessageDlg('Download completed successfully.', mtInformation, [mbOK], 0);
  end;
  UpdateDownloadAction;
end;

procedure TfrmMain.ThreadProgress(Sender: TObject; const Cur: Integer;
  const Max: Integer; const CurFile: TDownloadFile);
begin
  //Triggered when download thread makes progress
  FCurFile:= CurFile;
  FCurPos:= Cur;
  FCurMax:= Max;
end;

procedure TfrmMain.tmrDisplayTimer(Sender: TObject);
begin
  //Issue #46 - TTaskbar bugs

  //Displays UI status/progress
  if Assigned(FCurFile) then begin
    if Assigned(FTaskbarList3) then
      FTaskbarList3.SetProgressState(Self.Handle, TBPF_NORMAL);

    //FTaskbarList.ProgressState:= TTaskbarProgressState.Normal;
    Prog.Max:= FCurMax;
    Prog.Position:= FCurPos;
    if Assigned(FTaskbarList3) then
      FTaskbarList3.SetProgressValue(Self.Handle, FCurPos, FCurMax);
    //Taskbar.ProgressMaxValue:= FCurMax;
    //Taskbar.ProgressValue:= FCurPos;
    Stat.Panels[1].Text:= 'Downloading '+IntToStr(FCurPos)+' of '+IntToStr(FCurMax)+'...';
    Stat.Panels[2].Text:= FCurFile.Name;
  end else begin
    if Assigned(FTaskbarList3) then
      FTaskbarList3.SetProgressState(Self.Handle, TBPF_NOPROGRESS);
    //Taskbar.ProgressState:= TTaskbarProgressState.None;
  end;
end;

procedure TfrmMain.tmrFilterTimer(Sender: TObject);
begin
  tmrFilter.Enabled:= False;
  //Apply filter...
  Self.DisplayRepos;
end;

procedure TfrmMain.txtFilterChange(Sender: TObject);
begin
  tmrFilter.Enabled:= False;
  tmrFilter.Enabled:= True;
end;

procedure TfrmMain.ThreadException(Sender: TObject;
  const CurFile: TDownloadFile);
begin
  //Error occurred in download thread
  txtErrorLog.Lines.Append('EXCEPTION on file '+CurFile.Name+': '+CurFile.Error);
end;

function TfrmMain.CreateDownloadThread: TDownloadThread;
begin
  //Create a new instance of download thread
  Result:= TDownloadThread.Create;
  Result.Username:= frmSetup.Token;
  Result.OnDownloadBegin:= ThreadBegin;
  Result.OnDownloadDone:= ThreadDone;
  Result.OnProgress:= ThreadProgress;
  Result.OnException:= ThreadException;
  Result.FreeOnTerminate:= True;
  FThreadCancel:= Result.Cancel;
end;

procedure TfrmMain.actAboutExecute(Sender: TObject);
begin
  frmAbout.ShowModal;
end;

procedure TfrmMain.actCancelDownloadExecute(Sender: TObject);
begin
  //User wants to cancel download
  if MessageDlg('Are you sure you want to cancel download?',
    mtConfirmation, [mbYes,mbNo], 0) = mrYes then
  begin
    if Assigned(FThreadCancel) then
      FThreadCancel;
  end;
end;

procedure TfrmMain.actClearFilterExecute(Sender: TObject);
begin
  //Clear the filter text
  txtFilter.Text:= '';
end;

procedure TfrmMain.btnCloseErrorLogClick(Sender: TObject);
begin
  //User is closing error log
  ShowErrorLog(False);
end;

procedure TfrmMain.ShowErrorLog(const AShow: Boolean = True);
begin
  //Either show or hide error log
  pErrorLog.Visible:= AShow;
  spErrorLog.Visible:= AShow;
  if AShow then begin
    //This should force these controls to align in proper order on bottom
    pErrorLog.Top:= 0;
    spErrorLog.Top:= 0; // pErrorLog.Top - 10;
    if Prog.Visible then
      Prog.Top:= 0;
  end;
end;

procedure TfrmMain.actDownloadReposExecute(Sender: TObject);
var
  C: Integer;
  O: TGitHubRepo;
  X: Integer;
  T: TDownloadThread;
begin
  //Actual downloading of checked repos
  try
    //Attempt to create destination directory, if not already...
    ForceDirectories(frmSetup.BackupDir);
  except
    on E: Exception do begin
      if not DirectoryExists(frmSetup.BackupDir) then begin
        MessageDlg('Invalid destination directory!', mtError, [mbOK], 0);
        Application.ProcessMessages;
        actSetup.Execute;
        Exit;
      end;
    end;
  end;
  C:= CheckedCount;
  if C > 0 then begin
    //Download all checked repos...
    T:= CreateDownloadThread;
    for X := 0 to FRepos.Count-1 do begin
      if FRepos[X].Checked then begin
        O:= FRepos[X];
        T.AddFile(O.S['html_url']+'/archive/'+O.S['default_branch']+'.zip',
          TPath.Combine(frmSetup.BackupDir, MakeFilenameValid(O.S['name']+'-'+O.S['default_branch']+'.zip')));
      end;
    end;
    T.Start;
    //DO NOT REFER TO T AFTER THIS!
  end else begin
    //Nothing selected, nothing to download, shouldn't be possible...
    MessageDlg('Nothing is selected to download!', mtError, [mbOK], 0);
  end;
end;

initialization
  UseLatestCommonDialogs:= True;
  TStyleManager.Engine.RegisterStyleHook(TButton, TButtonStyleHookFix);
end.
