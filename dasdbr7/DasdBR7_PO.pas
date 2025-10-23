unit DasdBR7_PO;
{
   process partiotioned dataset (PDS)
   list
   show data
    options show rec num
            show recl len
            show cyl trk
            show hexa
            etc

}

interface

uses
  DasdBR7_Show,
  DasdBR7_PDS,
  DasdBR7_DM,
  strUtils,
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Db, DBClient, Grids, DBGrids, Menus;


type
  TF_PO = class(TForm)
    DBG: TDBGrid;
    MainMenu1: TMainMenu;
    Quit1: TMenuItem;
    Extracttofolder1: TMenuItem;
    DS_PDS: TDataSource;
    Find1: TMenuItem;
    procedure FormActivate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure DBGTitleClick(Column: TColumn);
    procedure Quit1Click(Sender: TObject);
    procedure DBGDblClick(Sender: TObject);
    procedure DBGKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Extracttofolder1Click(Sender: TObject);
    procedure Find1Click(Sender: TObject);
  private
    { Private declarations }
    find_string:string;
    find_offset:cardinal;
  public
    { Public declarations }
    options:integer;
  end;

var
  F_PO: TF_PO;

implementation



{$R *.DFM}

//function reverte_word(rw : rev_word):word; begin Result:=rw[1]+(rw[0] shl 8); end;

function unpack(bb:byte):word; begin  Result:=(bb shr 4) * 10 + (bb and $f) end;


procedure Error_Show(cod:word;reason:string);
var ms : string;
begin
   ms:='Error '+format('%.3d',[cod])+' - ';
   case cod of
   871  : ms:=ms+'PDS Dir blk > 256 ' +reason;
   end;
   ShowMessage(ms);
end;






procedure TF_PO.FormActivate(Sender: TObject);
var fileno,first_extent:integer;
    recfm:string;
    t1,t2,hz:int64;

begin
   QueryPerformanceFrequency(hz);
   QueryPerformanceCounter(t1);
   fileno:=DM.TK_F.FieldByName('dscb').AsInteger;
   first_extent:=DM.TK_F.FieldByName('first_extent').AsInteger;
   find_offset:=0;
   find_string:='';


   screen.Cursor:=crHourGlass;
   DS_PDS.DataSet:=nil;
   DM.TK_PDS.DisableControls;
   DM.TK_PDS.Close;
   DM.TK_PDS.Open;

   recfm:=DM.TK_F.FieldByName('recfm').AsString;

   if copy(recfm,1,1)='U'
   then DBG.Columns[2].Title.Caption:='bytes'
   else DBG.Columns[2].Title.Caption:='lines';

   uPDS.pds_member_count_mount(true,options,fileno,first_extent);

   DM.TK_PDS.EnableControls;

   if DM.TK_PDS.IndexFieldCount=0
   then DM.set_table_index(DM.TK_PDS,'cod','i_cod');

   DM.TK_PDS.first;
   screen.Cursor:=crDefault;
   DS_PDS.DataSet:=DM.TK_PDS;
   QueryPerformanceCounter(t2);
   Caption:=Caption+format('   (t=%.4f)',[(t2-t1)/hz]);
end;


procedure TF_PO.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
   if key=27 then ModalResult:=mrOK;
end;


procedure TF_PO.DBGTitleClick(Column: TColumn);
begin
   if Column.FieldName='ttr'
   then DM.set_table_index(DM.TK_PDS,'ttr;cyl;trk;n','i_ttr')
   else DM.set_table_index(DM.TK_PDS,Column.FieldName,'i_'+Column.FieldName);
   
end;

procedure TF_PO.Quit1Click(Sender: TObject);
begin
   ModalResult:=mrok;
end;


procedure TF_PO.DBGDblClick(Sender: TObject);

begin
   if DM.TK_F.FieldByName('dsorg').AsString='PO' then
   begin
      F_Show.Caption:=DM.TK_F.FieldByName('name').AsString+'('+DM.TK_PDS.FieldByName('name').AsString+')';
      F_Show.proctype:='PDS';
      F_Show.ShowModal;
   end;
end;

procedure TF_PO.DBGKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if key=13 then DBGDblClick(nil);


end;

procedure TF_PO.FormCreate(Sender: TObject);
begin
   Top:=0;
   Height:=Screen.Height;
end;

procedure TF_PO.FormShow(Sender: TObject);
begin
   ShowWindowAsync(Handle, SW_MAXIMIZE);
end;



procedure TF_PO.Extracttofolder1Click(Sender: TObject);
begin
   Screen.Cursor:=crHourGlass;
   uPDS.pds_extract_folder;
   Screen.Cursor:=crDefault;
end;

procedure TF_PO.Find1Click(Sender: TObject);
var s:string;
begin

   if not InputQuery('Find','UPERCASE',find_string)
   then exit;
   find_string:=trim(find_string);
   find_string:=UpperCase(find_string);      // all pds member names is uperrcase

   DM.TK_PDS.DisableControls;
   DM.TK_PDS.First;
   while not DM.TK_PDS.Eof do
   begin
      s:=DM.TK_PDS.Fields[1].AsString;
      if copy(s,1,length(find_string))=find_string then
      begin
         DM.TK_PDS.EnableControls;
         exit;
      end;
      DM.TK_PDS.Next;
   end;
   DM.TK_PDS.First;
   DM.TK_PDS.EnableControls;

end;

end.


