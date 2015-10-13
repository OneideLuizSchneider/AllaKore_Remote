{


      This source has created by Maickonn Richard.
      Any questions, contact-me: senjaxus@gmail.com

      My Github: https://www.github.com/Senjaxus

      Are totally free!



}


unit Form_Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, AppEvnts, IdBaseComponent, IdComponent,
  IdTCPServer, IdMappedPortTCP, XPMan;


// Thread to Define type connection, if Main, Desktop Remote, Download or Upload Files.
type
  TThreadConnection_Define = class(TThread)
  private
    AThread_Define: TIdPeerThread;
  public
    constructor Create(AThread: TIdPeerThread); overload;
    procedure Execute; override;
  end;

// Thread to Define type connection are Main.
type
  TThreadConnection_Main = class(TThread)
  private
    AThread_Main: TIdPeerThread;
    AThread_Main_Target: TIdPeerThread;
    ID, Password, TargetID, TargetPassword: string;
    StartPing, EndPing: Integer;
  public
    constructor Create(AThread: TIdPeerThread); overload;
    procedure Execute; override;
    procedure AddItems;
    procedure InsertTargetID;
    procedure InsertPing;
  end;

// Thread to Define type connection are Desktop.
type
  TThreadConnection_Desktop = class(TThread)
  private
    AThread_Desktop: TIdPeerThread;
    AThread_Desktop_Target: TIdPeerThread;
    AThread_Main_OnDesktop: TIdPeerThread;
    MyID: string;
  public
    constructor Create(AThread: TIdPeerThread; ID: string); overload;
    procedure Execute; override;
  end;

// Thread to Define type connection are Keyboard.
type
  TThreadConnection_Keyboard = class(TThread)
  private
    AThread_Keyboard: TIdPeerThread;
    AThread_Keyboard_Target: TIdPeerThread;
    MyID: string;
  public
    constructor Create(AThread: TIdPeerThread; ID: string); overload;
    procedure Execute; override;
  end;

// Thread to Define type connection are Files.
type
  TThreadConnection_Files = class(TThread)
  private
    AThread_Files: TIdPeerThread;
    AThread_Files_Target: TIdPeerThread;
    MyID: string;
  public
    constructor Create(AThread: TIdPeerThread; ID: string); overload;
    procedure Execute; override;
  end;

type
  Tfrm_Main = class(TForm)
    Splitter1: TSplitter;
    Logs_Memo: TMemo;
    Connections_ListView: TListView;
    ApplicationEvents1: TApplicationEvents;
    Main_IdTCPServer: TIdTCPServer;
    Ping_Timer: TTimer;
    procedure ApplicationEvents1Exception(Sender: TObject; E: Exception);
    procedure FormCreate(Sender: TObject);
    procedure Main_IdTCPServerExecute(AThread: TIdPeerThread);
    procedure Main_IdTCPServerConnect(AThread: TIdPeerThread);
    procedure Ping_TimerTimer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frm_Main: Tfrm_Main;

const
  Port = 3898; // Port for Indy Socket;


implementation

{$R *.dfm}

constructor TThreadConnection_Define.Create(AThread: TIdPeerThread);
begin
  inherited Create(true);
  AThread_Define := AThread;
  FreeOnTerminate := True;
end;

constructor TThreadConnection_Main.Create(AThread: TIdPeerThread);
begin
  inherited Create(true);
  AThread_Main := AThread;
  FreeOnTerminate := True;
end;

constructor TThreadConnection_Desktop.Create(AThread: TIdPeerThread; ID: string);
begin
  inherited Create(true);
  AThread_Desktop := AThread;
  MyID := ID;
  FreeOnTerminate := True;
end;

constructor TThreadConnection_Keyboard.Create(AThread: TIdPeerThread; ID: string);
begin
  inherited Create(true);
  AThread_Keyboard := AThread;
  MyID := ID;
  FreeOnTerminate := True;
end;

constructor TThreadConnection_Files.Create(AThread: TIdPeerThread; ID: string);
begin
  inherited Create(true);
  AThread_Files := AThread;
  MyID := ID;
  FreeOnTerminate := True;
end;

function GenerateID(): string;
var
  i: Integer;
  ID: string;
  Exists: Boolean;
begin
  Exists := false;

  while true do
  begin
    Randomize;
    ID := IntToStr(Random(9)) + IntToStr(Random(9)) + IntToStr(Random(9)) + IntToStr(Random(9)) + IntToStr(Random(9)) + IntToStr(Random(9)) + IntToStr(Random(9)) + IntToStr(Random(9));

    i := 0;
    while i < frm_Main.Connections_ListView.Items.Count - 1 do
    begin

      if (frm_Main.Connections_ListView.Items.Item[i].SubItems[2] = ID) then
      begin
        Exists := True;
        break;
      end
      else
        Exists := false;

      Inc(i);
    end;
    if not (Exists) then
      Break;
  end;

  Result := ID;

end;

function GeneratePassword(): string;
begin
  Randomize;
  Result := IntToStr(Random(9)) + IntToStr(Random(9)) + IntToStr(Random(9)) + IntToStr(Random(9));
end;

function FindListItemID(ID: string): TListItem;
var
  i: Integer;
begin
  i := 0;
  while i < frm_Main.Connections_ListView.Items.Count do
  begin
    if (frm_Main.Connections_ListView.Items.Item[i].SubItems[1] = ID) then
      break;

    Inc(i);
  end;

  Result := frm_Main.Connections_ListView.Items.Item[i];
end;

function CheckIDExists(ID: string): Boolean;
var
  i: Integer;
  Exists: Boolean;
begin
  Exists := false;
  i := 0;
  while i < frm_Main.Connections_ListView.Items.Count do
  begin
    if (frm_Main.Connections_ListView.Items.Item[i].SubItems[1] = ID) then
    begin
      Exists := true;
      break;
    end;

    Inc(i);
  end;

  Result := Exists;
end;

function CheckIDPassword(ID, Password: string): Boolean;
var
  i: Integer;
  Correct: Boolean;
begin
  Correct := false;
  i := 0;
  while i < frm_Main.Connections_ListView.Items.Count do
  begin
    if (frm_Main.Connections_ListView.Items.Item[i].SubItems[1] = ID) and (frm_Main.Connections_ListView.Items.Item[i].SubItems[2] = Password) then
    begin
      Correct := true;
      break;
    end;

    Inc(i);
  end;

  Result := Correct;
end;

procedure Tfrm_Main.ApplicationEvents1Exception(Sender: TObject; E: Exception);
begin
  Logs_Memo.Lines.Add(' ');
  Logs_Memo.Lines.Add(' ');
  Logs_Memo.Lines.Add(E.Message);
end;

procedure Tfrm_Main.FormCreate(Sender: TObject);
begin
  Main_IdTCPServer.DefaultPort := Port;
  Main_IdTCPServer.Active := true;
end;

procedure Tfrm_Main.Main_IdTCPServerExecute(AThread: TIdPeerThread);
begin
  Sleep(5); // Avoids using 100% CPU
end;

{ TThreadConnection_Define }
// Here it will be defined the type of connection.
procedure TThreadConnection_Define.Execute;
var
  s, s2, ID: string;
  ThreadMain: TThreadConnection_Main;
  ThreadDesktop: TThreadConnection_Desktop;
  ThreadKeyboard: TThreadConnection_Keyboard;
  ThreadFiles: TThreadConnection_Files;
begin
  inherited;

  try
    while AThread_Define.Connection.Connected do
    begin
      s := AThread_Define.Connection.CurrentReadBuffer;

      if (Pos('<|MAINSOCKET|>', s) > 0) then
      begin
      // Create the Thread for Main Socket
        ThreadMain := TThreadConnection_Main.Create(AThread_Define);
        ThreadMain.Resume;

        Destroy; // Destroy this Thread
      end;

      if (Pos('<|DESKTOPSOCKET|>', s) > 0) then
      begin
        s2 := s;

        Delete(s2, 1, Pos('<|DESKTOPSOCKET|>', s) + 16);
        ID := Copy(s2, 1, Pos('<<|', s2) - 1);

      // Create the Thread for Desktop Socket
        ThreadDesktop := TThreadConnection_Desktop.Create(AThread_Define, ID);
        ThreadDesktop.Resume;

        Destroy; // Destroy this Thread
      end;

      if (Pos('<|KEYBOARDSOCKET|>', s) > 0) then
      begin
        s2 := s;

        Delete(s2, 1, Pos('<|KEYBOARDSOCKET|>', s) + 17);
        ID := Copy(s2, 1, Pos('<<|', s2) - 1);

      // Create the Thread for Keyboard Socket
        ThreadKeyboard := TThreadConnection_Keyboard.Create(AThread_Define, ID);
        ThreadKeyboard.Resume;

        Destroy; // Destroy this Thread
      end;

      if (Pos('<|FILESSOCKET|>', s) > 0) then
      begin
        s2 := s;

        Delete(s2, 1, Pos('<|FILESSOCKET|>', s) + 14);
        ID := Copy(s2, 1, Pos('<<|', s2) - 1);

      // Create the Thread for Keyboard Socket
        ThreadFiles := TThreadConnection_Files.Create(AThread_Define, ID);
        ThreadFiles.Resume;

        Destroy; // Destroy this Thread
      end;
    end;
  except
    Destroy;
  end;

end;

{ TThreadConnection_Main }

procedure TThreadConnection_Main.AddItems;
var
  L: TListItem;
begin
  ID := GenerateID;
  Password := GeneratePassword;
  L := frm_Main.Connections_ListView.Items.Add;
  L.Caption := IntToStr(AThread_Main.Handle);
  L.SubItems.Add(AThread_Main.Connection.Socket.Binding.PeerIP);
  L.SubItems.Add(ID);
  L.SubItems.Add(Password);
  L.SubItems.Add('');
  L.SubItems.Add('Calculating...');
  L.SubItems.Objects[4] := TObject(0);
end;

// The connection type is the main.
procedure TThreadConnection_Main.Execute;
var
  s, s2: string;
  L, L2: TListItem;
begin
  inherited;

  Synchronize(AddItems);

  L := frm_Main.Connections_ListView.FindCaption(0, IntToStr(AThread_Main.Handle), false, true, false);
  L.SubItems.Objects[0] := TObject(Self);

  AThread_Main.Connection.Write('<|ID|>' + ID + '<|>' + Password + '<<|');

  try
    while AThread_Main.Connection.Connected do
    begin
      s := AThread_Main.Connection.CurrentReadBuffer;

      if (Length(s) < 1) then
      begin
        L := FindListItemID(ID);
        L.Delete;
        AThread_Main_Target.Connection.Write('<|DISCONNECTED|>');
      end;

      if (Pos('<|FINDID|>', s) > 0) then
      begin
        s2 := s;
        Delete(s2, 1, Pos('<|FINDID|>', s2) + 9);

        TargetID := Copy(s2, 1, Pos('<<|', s2) - 1);

        if (CheckIDExists(TargetID)) then
          if (FindListItemID(TargetID).SubItems[3] = '') then
            AThread_Main.Connection.Write('<|IDEXISTS!REQUESTPASSWORD|>')
          else
            AThread_Main.Connection.Write('<|ACCESSBUSY|>')
        else
          AThread_Main.Connection.Write('<|IDNOTEXISTS|>');
      end;

      if (Pos('<|PONG|>', s) > 0) then
      begin
        EndPing := GetTickCount - StartPing;
        Synchronize(InsertPing);
      end;

      if (Pos('<|CHECKIDPASSWORD|>', s) > 0) then
      begin
        s2 := s;
        Delete(s2, 1, Pos('<|CHECKIDPASSWORD|>', s2) + 18);

        TargetID := Copy(s2, 1, Pos('<|>', s2) - 1);
        Delete(s2, 1, Pos('<|>', s2) + 2);

        TargetPassword := Copy(s2, 1, Pos('<<|', s2) - 1);

        if (CheckIDPassword(TargetID, TargetPassword)) then
        begin
          AThread_Main.Connection.Write('<|ACCESSGRANTED|>');
        end
        else
          AThread_Main.Connection.Write('<|ACCESSDENIED|>');
      end;

      if (Pos('<|RELATION|>', s) > 0) then
      begin
        s2 := s;
        Delete(s2, 1, Pos('<|RELATION|>', s2) + 11);

        ID := Copy(s2, 1, Pos('<|>', s2) - 1);
        Delete(s2, 1, Pos('<|>', s2) + 2);

        TargetID := Copy(s2, 1, Pos('<<|', s2) - 1);

        L := FindListItemID(ID);
        L2 := FindListItemID(TargetID);

        Synchronize(InsertTargetID);

      // Relates the main Sockets
        (L.SubItems.Objects[0] as TThreadConnection_Main).AThread_Main_Target := (L2.SubItems.Objects[0] as TThreadConnection_Main).AThread_Main;
        (L2.SubItems.Objects[0] as TThreadConnection_Main).AThread_Main_Target := (L.SubItems.Objects[0] as TThreadConnection_Main).AThread_Main;

      // Relates the Remote Desktop
        (L.SubItems.Objects[1] as TThreadConnection_Desktop).AThread_Desktop_Target := (L2.SubItems.Objects[1] as TThreadConnection_Desktop).AThread_Desktop;
        (L2.SubItems.Objects[1] as TThreadConnection_Desktop).AThread_Desktop_Target := (L.SubItems.Objects[1] as TThreadConnection_Desktop).AThread_Desktop;

      // Relates the Keyboard Socket
        (L.SubItems.Objects[2] as TThreadConnection_Keyboard).AThread_Keyboard_Target := (L2.SubItems.Objects[2] as TThreadConnection_Keyboard).AThread_Keyboard;

      // Relates the Share Files
        (L.SubItems.Objects[3] as TThreadConnection_Files).AThread_Files_Target := (L2.SubItems.Objects[3] as TThreadConnection_Files).AThread_Files;
        (L2.SubItems.Objects[3] as TThreadConnection_Files).AThread_Files_Target := (L.SubItems.Objects[3] as TThreadConnection_Files).AThread_Files;

      // Get first screenshot
        (L.SubItems.Objects[1] as TThreadConnection_Desktop).AThread_Desktop_Target.Connection.Write('<|GETFULLSCREENSHOT|><|NEWRESOLUTION|>996<|>528<<|');         //<|NEWRESOLUTION|>996<|>528<<|

      // Warns Access
        (L.SubItems.Objects[0] as TThreadConnection_Main).AThread_Main_Target.Connection.Write('<|ACCESSING|>');
      end;




    // Redirect commands
      if (Pos('<|REDIRECT|>', s) > 0) then
      begin
        s2 := s;
        Delete(s2, 1, Pos('<|REDIRECT|>', s2) + 11);

        AThread_Main_Target.Connection.Write(s2);
      end;

    end;
  except
    Destroy;
  end;
end;

procedure TThreadConnection_Main.InsertPing;
var
  L: TListItem;
begin

  L := frm_Main.Connections_ListView.FindCaption(0, IntToStr(AThread_Main.Handle), false, true, false);
  if (L <> nil) then
    L.SubItems[4] := intToStr(EndPing)+' ms';

end;

procedure TThreadConnection_Main.InsertTargetID;
var
  L, L2: TListItem;
begin
  L := frm_Main.Connections_ListView.FindCaption(0, IntToStr(AThread_Main.Handle), false, true, false);
  if (L <> nil) then
  begin
    L2 := FindListItemID(TargetID);

    L.SubItems[3] := TargetID;
    L2.SubItems[3] := ID;
  end;

end;

{ TThreadConnection_Desktop }
// The connection type is the Desktop Screens
procedure TThreadConnection_Desktop.Execute;
var
  s: string;
  L: TListItem;
begin
  inherited;

  L := FindListItemID(MyID);
  AThread_Main_OnDesktop := (L.SubItems.Objects[0] as TThreadConnection_Main).AThread_Main;
  L.SubItems.Objects[1] := TObject(Self);

  try
    while AThread_Desktop.Connection.Connected do
    begin
      s := AThread_Desktop.Connection.CurrentReadBuffer;

      AThread_Desktop_Target.Connection.Write(s);
    end;
  except
    destroy;
  end;
end;

// The connection type is the Keyboard Remote
procedure TThreadConnection_Keyboard.Execute;
var
  s: string;
  L: TListItem;
begin
  inherited;

  L := FindListItemID(MyID);
  L.SubItems.Objects[2] := TObject(Self);

  try
    while AThread_Keyboard.Connection.Connected do
    begin
      s := AThread_Keyboard.Connection.CurrentReadBuffer;

      AThread_Keyboard_Target.Connection.Write(s);
    end;
  except
    destroy;
  end;
end;

{ TThreadConnection_Files }
// The connection type is to Share Files
procedure TThreadConnection_Files.Execute;
var
  s: string;
  L: TListItem;
begin
  inherited;

  L := FindListItemID(MyID);
  L.SubItems.Objects[3] := TObject(Self);

  try
    while AThread_Files.Connection.Connected do
    begin
      s := AThread_Files.Connection.CurrentReadBuffer;

      AThread_Files_Target.Connection.Write(s);

    end;
  except
    Destroy
  end;
end;

procedure Tfrm_Main.Main_IdTCPServerConnect(AThread: TIdPeerThread);
var
  Connection: TThreadConnection_Define;
begin
  // Create Defines Thread of Connections
  Connection := TThreadConnection_Define.Create(AThread);
  Connection.Resume;
end;

procedure Tfrm_Main.Ping_TimerTimer(Sender: TObject);
var
  i: Integer;
begin
  i := 0;
  while i < Connections_ListView.Items.Count do
  begin
    try
      (Connections_ListView.Items.Item[i].SubItems.Objects[0] as TThreadConnection_Main).AThread_Main.Connection.Write('<|PING|>');
      (Connections_ListView.Items.Item[i].SubItems.Objects[0] as TThreadConnection_Main).StartPing := GetTickCount;
    except
      Connections_ListView.Items.Item[i].Delete;
      Dec(i);
    end;
    Inc(i);
  end;

end;

end.

