unit Form_ShareFiles;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.ImgList,
  Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Buttons;

type
  Tfrm_ShareFiles = class(TForm)
    ShareFiles_ListView: TListView;
    ImageList1: TImageList;
    Menu_Panel: TPanel;
    UploadProgress_Label: TLabel;
    DownloadProgress_Label: TLabel;
    Download_BitBtn: TBitBtn;
    Upload_BitBtn: TBitBtn;
    Upload_ProgressBar: TProgressBar;
    Download_ProgressBar: TProgressBar;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    Directory_Label: TLabel;
    Directory_Edit: TEdit;
    Bevel1: TBevel;
    SizeDownload_Label: TLabel;
    SizeUpload_Label: TLabel;
    procedure FormShow(Sender: TObject);
    procedure Directory_EditKeyPress(Sender: TObject; var Key: Char);
    procedure ShareFiles_ListViewDblClick(Sender: TObject);
    procedure ShareFiles_ListViewKeyPress(Sender: TObject; var Key: Char);
    procedure Download_BitBtnClick(Sender: TObject);
    procedure Upload_BitBtnClick(Sender: TObject);
  private
    procedure WMGetMinMaxInfo(var Message: TWMGetMinMaxInfo); message WM_GETMINMAXINFO;
    procedure GoToDirectory(Directory: string);
    procedure EnterInDirectory;
    { Private declarations }
  public
    DirectoryToSaveFile: string;
    { Public declarations }
  end;

var
  frm_ShareFiles: Tfrm_ShareFiles;

implementation

{$R *.dfm}

uses
  Form_Main;

function MemoryStreamToString(M: TMemoryStream): AnsiString;
begin
  SetString(Result, PAnsiChar(M.Memory), M.Size);
end;

procedure Tfrm_ShareFiles.GoToDirectory(Directory: string);
begin
  ShareFiles_ListView.Enabled := false;
  Directory_Edit.Enabled := false;
  if not (Directory[Length(Directory)] = '\') then
  begin
    Directory := Directory + '\';
    Directory_Edit.Text := Directory;
  end;

  frm_Main.Main_Socket.Socket.SendText('<|REDIRECT|><|GETFOLDERS|>' + Directory + '<<|');
end;

procedure Tfrm_ShareFiles.Download_BitBtnClick(Sender: TObject);
begin
  if (ShareFiles_ListView.ItemIndex = -1) then
    exit;

  if not (ShareFiles_ListView.Selected.ImageIndex = 0) and not (ShareFiles_ListView.Selected.ImageIndex = 1) then
  begin
    SaveDialog1.FileName := '';
    SaveDialog1.Filter := 'File (*' + ExtractFileExt(ShareFiles_ListView.Selected.Caption) + ')|*' + ExtractFileExt(ShareFiles_ListView.Selected.Caption);
    if (SaveDialog1.Execute()) then
    begin
      DirectoryToSaveFile := SaveDialog1.FileName + ExtractFileExt(ShareFiles_ListView.Selected.Caption);
      frm_Main.Main_Socket.Socket.SendText('<|REDIRECT|><|DOWNLOADFILE|>' + Directory_Edit.Text + ShareFiles_ListView.Selected.Caption + '<<|');
      Download_BitBtn.Enabled := false;
    end;
  end;
end;

procedure Tfrm_ShareFiles.EnterInDirectory;
var
  Directory: string;
begin
  if (ShareFiles_ListView.ItemIndex = -1) then
    Exit;

  if (ShareFiles_ListView.Selected.ImageIndex = 0) or (ShareFiles_ListView.Selected.ImageIndex = 1) then
  begin
    if (ShareFiles_ListView.Selected.Caption = 'Return') then
    begin
      Directory := Directory_Edit.Text;
      Delete(Directory, Length(Directory), Length(Directory));
      Directory_Edit.Text := ExtractFilePath(Directory + '..');
    end
    else
      Directory_Edit.Text := Directory_Edit.Text + ShareFiles_ListView.Selected.Caption + '\';

    GoToDirectory(Directory_Edit.Text);
  end;
end;

procedure Tfrm_ShareFiles.ShareFiles_ListViewDblClick(Sender: TObject);
begin
  EnterInDirectory;
end;

procedure Tfrm_ShareFiles.ShareFiles_ListViewKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #13) then
    EnterInDirectory;
end;

procedure Tfrm_ShareFiles.Upload_BitBtnClick(Sender: TObject);
var
  FileName: string;
  FileStream: TMemoryStream;
begin
  OpenDialog1.FileName := '';
  if (OpenDialog1.Execute()) then
  begin
    FileStream := TMemoryStream.Create;
    FileStream.LoadFromFile(OpenDialog1.FileName);
    FileName := ExtractFileName(OpenDialog1.FileName);
    Upload_ProgressBar.Max := FileStream.Size;
    frm_Main.Files_Socket.Socket.SendText('<|DIRECTORYTOSAVE|>' + Directory_Edit.Text + FileName + '<|><|SIZE|>' + intToStr(FileStream.Size) + '<<|' + MemoryStreamToString(FileStream));
    FreeAndNil(FileStream);
    Upload_BitBtn.Enabled := false;
  end;
end;

procedure Tfrm_ShareFiles.Directory_EditKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #13) then
  begin
    GoToDirectory(Directory_Edit.Text);
    Key := #0;
  end;
end;

procedure Tfrm_ShareFiles.FormShow(Sender: TObject);
begin
  GoToDirectory(Directory_Edit.Text);
end;

procedure Tfrm_ShareFiles.WMGetMinMaxInfo(var Message: TWMGetMinMaxInfo);
{sets Size-limits for the Form}
var
  MinMaxInfo: PMinMaxInfo;
begin
  inherited;
  MinMaxInfo := Message.MinMaxInfo;

  MinMaxInfo^.ptMinTrackSize.X := 515; // Minimum Width
  MinMaxInfo^.ptMinTrackSize.Y := 460; // Minimum Height
end;

end.

