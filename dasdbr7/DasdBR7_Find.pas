unit DasdBR7_Find;


{
   caution - may cancel by error

   search for dataset/pds member names

   list
   in list double click open volume

}

interface

uses
  DASDbr7_DM,
  graphics,Windows, Messages, SysUtils,  Classes,  Forms,
  Dialogs, StdCtrls, ExtCtrls, Controls, ComCtrls;
const
  use_threads=false;
type
  TF_Find = class(TForm)
    MM: TMemo;
    L_Msg: TLabel;
    GroupBox1: TGroupBox;
    Label3: TLabel;
    Label6: TLabel;
    Edit2: TEdit;
    Edit3: TEdit;
    PC: TPageControl;
    TS_Dsn: TTabSheet;
    Label5: TLabel;
    B_FIndDSN: TButton;
    RG_DsnType: TRadioGroup;
    RG_dsn_opt: TRadioGroup;
    E_dsn_dsn: TEdit;
    TS_Member: TTabSheet;
    Label4: TLabel;
    Label2: TLabel;
    Label8: TLabel;
    E_mem_mem: TEdit;
    B_FIndText: TButton;
    RG_mem_opt: TRadioGroup;
    E_mem_dsn: TEdit;
    E_mem_txt: TEdit;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    Label7: TLabel;
    E_mem_max: TEdit;
    E_mem_vol: TEdit;
    GroupBox3: TGroupBox;
    Label9: TLabel;
    Label10: TLabel;
    E_dsn_max: TEdit;
    E_dsn_vol: TEdit;
    procedure Button2Click(Sender: TObject);
    procedure B_FindClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure MMDblClick(Sender: TObject);
    procedure T_DSNameKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure T_DsnPdsNameKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure T_DSNameEnter(Sender: TObject);
    procedure T_DSNameExit(Sender: TObject);
  private
    { Private declarations }
    find_max:integer;
    //ft:TFind;
    tracks_read:integer;
    t1,t2,hz:int64;
    in_find:boolean;

    find_parms:array of t_find_struct;


  public
    ft_num:integer;
    find_at_dsn,
    find_at_vol:string;


  end;

var
  F_Find: TF_Find;

implementation



{$R *.dfm}
procedure TF_Find.Button2Click(Sender: TObject);
begin
   ModalResult:=mrCancel;
end;







procedure TF_Find.B_FindClick(Sender: TObject);
var dsn_name,member_name,limit_volume,find_text:string;
    options,i:integer;
    ts:TStringList;

begin

   if in_find then exit;

   if PC.ActivePage=TS_Dsn then
   begin
      options:=option_find_dataset;

      limit_volume:=UpperCase(trim(E_dsn_vol.Text));

      val(E_dsn_max.Text,find_max,i);
      if i>0 then
      begin
         ShowMessage('error 767 - max value not numeric');
         exit;
      end;

      dsn_name:=UpperCase(trim(E_dsn_dsn.Text));
      if RG_dsn_opt.ItemIndex=0
      then options:=options or option_find_initial
      else options:=options or option_find_partial;
      if RG_DsnType.ItemIndex=0 then options:=options+option_type_all else
      if RG_DsnType.ItemIndex=1 then options:=options+option_type_pds else
      if RG_DsnType.ItemIndex=2 then options:=options+option_type_ps  else
      if RG_DsnType.ItemIndex=3 then options:=options+option_type_vsam else
      if RG_DsnType.ItemIndex=4 then options:=options+option_type_hps else
      if RG_DsnType.ItemIndex=5 then options:=options+option_type_pdse;
   end
   else
   begin
      E_mem_dsn.Text:=UpperCase(E_mem_dsn.Text);
      E_mem_mem.Text:=UpperCase(E_mem_mem.Text);
      E_mem_vol.Text:=UpperCase(E_mem_vol.Text);

      options:=option_find_text;
      dsn_name:=trim(E_mem_dsn.Text);
      find_text:=trim(E_mem_txt.Text);
      member_name:=trim(E_mem_mem.Text);

      limit_volume:=UpperCase(trim(E_mem_vol.Text));
      {
      if length(dsn_name)<3 then
      begin
         ShowMessage('error 768 - min 3 chars in dsname');
         exit;
      end;
      }
      if RG_mem_opt.ItemIndex=0
      then options:=options or option_find_initial
      else options:=options or option_find_partial;
      val(E_mem_max.Text,find_max,i);
      if i>0 then
      begin
         ShowMessage('error 767 - max value not numeric');
         exit;
      end;
   end;

   tracks_read:=0;
   ft_num:=0;
   MM.Lines.Clear;
   QueryPerformanceCounter(t1);

   SetLength(find_parms,0);
   SetLength(find_parms,high(DM.mvs_volumes)+2);

   for i:=0 to high(DM.mvs_volumes) do
   begin
      if (limit_volume<>'') and
         (pos(limit_volume,UpperCase(DM.mvs_volumes[i]))=0)
      then continue;
      inc(ft_num);

      find_parms[i].rc:=-1;
      find_parms[i].count_find:=0;
      find_parms[i].options:=options;
      find_parms[i].fname:=DM.mvs_volumes[i];
      find_parms[i].dsname:=dsn_name;
      find_parms[i].member_name:=member_name;
      find_parms[i].text:=find_text;
      find_parms[i].max_found:=find_max;
      find_parms[i].count_find:=0;
      find_parms[i].pds_read:=0;
      find_parms[i].dscb_count:=0;
      find_parms[i].trk_read:=0;
      find_parms[i].rc:=-1;         // not processed
   end;

   if ft_num=0 then
   begin
      ShowMessage('nothing to do');
      exit;
   end;

   Screen.Cursor:=crHourGlass;

   in_find:=true;

   ts:=DM.find_dataset_dsorg(options,find_max,dsn_name,member_name,find_text,L_Msg);   // process find

   Screen.Cursor:=crDefault;
   QueryPerformanceCounter(t2);
   QueryPerformanceFrequency(hz);
   if ts.Count=0 then;

   //ts.Sorted:=true;
   //ts.Sort;
   MM.Lines.BeginUpdate;
   MM.Lines:=ts;
   ts.Free;
   MM.Lines.EndUpdate;

   L_Msg.Caption:=format('... direct found count=%d  t=%.3f read=%d',[MM.Lines.Count,(t2-t1)/hz,DM.volume_data.tracks_read]);

   in_find:=false;
end;


procedure TF_Find.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
   if key=VK_ESCAPE
   then ModalResult:=mrCancel;
end;



procedure TF_Find.MMDblClick(Sender: TObject);
var
  CurrentLine: integer;
  s:string;
begin
  CurrentLine := MM.Perform(EM_LINEFROMCHAR, -1, 0);
  MM.SelStart := MM.Perform(EM_LINEINDEX, CurrentLine, 0);
  MM.SelLength := Length(MM.Lines[CurrentLine]);
  s:=MM.Lines[CurrentLine];
  delete(s,pos(' ',s),maxint);
  if s<>''
  then find_at_vol:=s;

  s:=MM.Lines[CurrentLine];
  delete(s,1,pos(' ',s));
  s:=trim(s);
  if pos(' ',s)>0                         // find text ....
  then delete(s,pos(' ',s),MaxInt);

  //find_at_dsn:=copy(s,1,pos(' ',s)-1);
  find_at_dsn:=trim(s);

  ModalResult:=mrRetry;
end;

procedure TF_Find.T_DSNameKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
   if key=VK_RETURN
   then B_FindClick(B_FIndDSN);
end;


function copy_until_eol(s:string):string;
begin
   Result:=copy(s,1,pos('|',s)-1);
end;




procedure TF_Find.T_DsnPdsNameKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
   if key=VK_RETURN
   then B_FindClick(B_FIndText);
end;

procedure TF_Find.T_DSNameEnter(Sender: TObject);
begin
   TEdit(Sender).Font.Color:=clRed;
end;

procedure TF_Find.T_DSNameExit(Sender: TObject);
begin
   TEdit(Sender).Font.Color:=clBlue;
end;

end.
