
{
   show vsam structures and data like idcams print

   todo: vsam more detail

vsam asm access:

http://www.edwardbosworth.com/My3121Textbook_HTM/MyText3121_Ch28_V01.htm

}

unit DasdBR7_Vsam;

interface

uses
  DasdBR7_DM,
  DasdBR7_DV,
  DasdBR7_Show,
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, DBGrids, ExtCtrls, StdCtrls, Menus, DB;

{$i vsam.Inc}

type
  TF_VSAM = class(TForm)
    DBGrid1: TDBGrid;
    MainMenu1: TMainMenu;
    Option1: TMenuItem;
    Onlywithrecs1: TMenuItem;
    DS_VSAM: TDataSource;
    procedure FormActivate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure DBGrid1TitleClick(Column: TColumn);
    procedure DBGrid1CellClick(Column: TColumn);
    procedure DBGrid1KeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure DBGrid1KeyUp(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure Onlywithrecs1Click(Sender: TObject);
  private
    { Private declarations }
    is_shift:boolean; // smart index
  public
    { Public declarations }

    //ckd:tckd;
  end;

var
  F_VSAM: TF_VSAM;
  //ckd : tckd;
  datalen : word;
  hrec : rec_header;

  tracks_read : integer;
  pb :Pbyte;


implementation





{$R *.DFM}
function Swap4(a:cardinal):cardinal; asm bswap eax end;




function get_record(var ckd:tckd):PByte;
var save_trk,fileno,seqno : integer;
    exts:p_resume;


   function read_data:boolean;
   begin
      Result:=false;
      datalen:=0;
      ckd.read:=0;
      pb:=DM.read_one_track(-1,@ckd,false);
      if pb=nil then exit;
      move(pb^,hrec,sizeof(hrec));
      inc(pb,sizeof(hrec)+hrec.klen);
      datalen:=swap(hrec.dlen);
      if datalen=0 then exit;
      if swap(hrec.cyl)=$FFFF then exit;
      ckd.read:=datalen;
      Result:=true;
   end;





begin
   Result:=nil;
   datalen:=0;
   save_trk:=ckd.cyl * ckd.trk;
   fileno:=DM.TK_F.FieldByName('dscb').AsInteger;
   seqno:=0;


   // no more data in track.... so...

   if read_data=false then
   begin

      // 1 - try next track
      inc (ckd.trk);
      ckd.nrec:=1;
      ckd.read:=0;

      if read_data=false then
      begin
         // 2 - try next cyl
         inc (ckd.cyl);
         ckd.trk:=1;
         ckd.nrec:=1;
         ckd.read:=0;
         if read_data=false then
         begin
            // 3 - get next extent?
            inc(seqno);
            exts:=DM.get_file_extents(fileno,seqno);
            if exts=nil then
            begin
               datalen:=0; // invalid data
               Exit;
            end;

            ckd.cyl:=exts.l_cyl;
            ckd.trk:=exts.l_trk;
            ckd.nrec:=1;
            ckd.read:=0;

            // 4 - read next extent
            if read_data=false
            then exit;
         end;
      end;
   end;


   if datalen=0 then Exit;





   // update ckd
   ckd.cyl:=swap(hrec.cyl);
   ckd.trk:=swap(hrec.head);
   ckd.nrec:=hrec.rec;

   // to calc end of file

   if save_trk<>(ckd.cyl * ckd.trk)
   then inc(tracks_read);

   Result:=pb;
end;







procedure TF_VSAM.FormActivate(Sender: TObject);
begin
   Caption:='VSAM DATASETS IN VOL '+DM.volume_data.volid;
   if DM.TK_F.FieldByName('name').AsString='' then;
   DV.VSAM_statistics_table;
   DM.set_table_index(DM.TK_V,'num','i_num');
   DS_VSAM.DataSet:=DM.TK_V;
end;



procedure TF_VSAM.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
   if key=27 then ModalResult:=mrOK;

end;

procedure TF_VSAM.DBGrid1TitleClick(Column: TColumn);
var s:string;
begin
   s:=Column.FieldName;
   if is_shift then
   begin
      s:=DM.TK_V.IndexFieldNames;
      if pos(Column.FieldName,s)>0 then exit; // ja temos este index
      s:=DM.TK_V.IndexFieldNames+';'+Column.FieldName;
   end;
   DM.set_table_index(DM.TK_V,s,'i_'+s);
end;


procedure TF_VSAM.DBGrid1CellClick(Column: TColumn);
begin
   if Column.Field.FieldName='name' then
   begin
      if DM.TK_F.Locate('name',DM.TK_V.FieldByName('name').AsString,[]) then
      begin
         F_Show.Caption:=DM.TK_F.FieldByName('name').AsString;
         F_Show.proctype:='VSAM';
         F_Show.ShowModal;
      end;
   end;
   // save vsam data dump by ca data len..
   if Column.Field.FieldName='trk_ci' then
   begin
      if DM.TK_V.FieldByName('rec_tot').AsInteger=0 then
      begin
         ShowMessage('empty...');
         exit;
      end;
      if MessageDlg('Save data format as vsam ci ?',
         mtConfirmation, [mbYes, mbNo],  0) <> mrYes then exit;

      DM.Dump_Vsam_by_CI;
   end;
end;



procedure TF_VSAM.DBGrid1KeyDown(Sender: TObject; var Key: Word;  Shift: TShiftState);
begin
   is_shift:=Shift=[ssShift];
   if key=VK_RETURN then
   begin
      if DM.TK_F.Locate('name',DM.TK_V.FieldByName('name').AsString,[]) then
      begin
         F_Show.Caption:=DM.TK_F.FieldByName('name').AsString;
         F_Show.proctype:='VSAM';
         F_Show.ShowModal;
      end;
   end;
end;


procedure TF_VSAM.DBGrid1KeyUp(Sender: TObject; var Key: Word;  Shift: TShiftState);
begin
   is_shift:=false;
end;

procedure TF_VSAM.Onlywithrecs1Click(Sender: TObject);
begin
   FormActivate(F_VSAM);
end;

{ IDCMAS

  LISTC ENT(CICSTS23.SAMPLE.DFHCTCUS) ALL
0CLUSTER ------- CICSTS23.SAMPLE.DFHCTCUS
      IN-CAT --- USERCAT.Z16.CICS
      HISTORY
        DATASET-OWNER-----(NULL)     CREATION--------2004.315
        RELEASE----------------2     EXPIRATION------0000.000
        BWO STATUS--------(NULL)     BWO TIMESTAMP-----(NULL)
        BWO---------------(NULL)
      PROTECTION-PSWD-----(NULL)     RACF----------------(NO)
      ASSOCIATIONS
        DATA-----CICSTS23.SAMPLE.DFHCTCUS.DATA
        INDEX----CICSTS23.SAMPLE.DFHCTCUS.INDEX
        AIX------CICSTS23.SAMPLE.DFHCTAIX
0   DATA ------- CICSTS23.SAMPLE.DFHCTCUS.DATA
      IN-CAT --- USERCAT.Z16.CICS
      HISTORY
        DATASET-OWNER-----(NULL)     CREATION--------2004.315
        RELEASE----------------2     EXPIRATION------0000.000
        ACCOUNT-INFO-----------------------------------(NULL)
      PROTECTION-PSWD-----(NULL)     RACF----------------(NO)
      ASSOCIATIONS''''' 

        CLUSTER--CICSTS23.SAMPLE.DFHCTCUS
      ATTRIBUTES
        KEYLEN-----------------8     AVGLRECL-------------227     BUFSPACE------------1536     CISIZE---------------512
        RKP--------------------0     MAXLRECL-------------227     EXCPEXIT----------(NULL)     CI/CA-----------------49
        SHROPTNS(4,3)   RECOVERY     UNIQUE           NOERASE     INDEXED       NOWRITECHK     NOIMBED       NOREPLICAT
        UNORDERED        NOREUSE     NONSPANNED
      STATISTICS
        REC-TOTAL-------------37     SPLITS-CI--------------0     EXCPS-----------------39
        REC-DELETED------------0     SPLITS-CA--------------0     EXTENTS----------------1
        REC-INSERTED-----------0     FREESPACE-%CI----------0     SYSTEM-TIMESTAMP:
        REC-UPDATED------------0     FREESPACE-%CA----------0          X'BC1A31F75083B742'
        REC-RETRIEVED---------37     FREESPC------------15360
      ALLOCATION
        SPACE-TYPE---------TRACK     HI-A-RBA-----------25088
        SPACE-PRI--------------1     HI-U-RBA-----------25088
        SPACE-SEC--------------1
      VOLUME
        VOLSER------------Z6CIC1     PHYREC-SIZE----------512     HI-A-RBA-----------25088     EXTENT-NUMBER----------1
        DEVTYPE------X'3010200F'     PHYRECS/TRK-----------49     HI-U-RBA-----------25088     EXTENT-TYPE--------X'00'
        VOLFLAG------------PRIME     TRACKS/CA--------------1
        EXTENTS:
        LOW-CCHH-----X'05AF0001'     LOW-RBA----------------0     TRACKS-----------------1
        HIGH-CCHH----X'05AF0001'     HIGH-RBA-----------25087
0   INDEX ------ CICSTS23.SAMPLE.DFHCTCUS.INDEX
      IN-CAT --- USERCAT.Z16.CICS
      HISTORY
1IDCAMS  SYSTEM SERVICES                                           TIME: 13:09:18        12/27/23     PAGE      2
0       DATASET-OWNER-----(NULL)     CREATION--------2004.315
        RELEASE----------------2     EXPIRATION------0000.000
      PROTECTION-PSWD-----(NULL)     RACF----------------(NO)
      ASSOCIATIONS
        CLUSTER--CICSTS23.SAMPLE.DFHCTCUS
      ATTRIBUTES
        KEYLEN-----------------8     AVGLRECL---------------0     BUFSPACE---------------0     CISIZE---------------512
        RKP--------------------0     MAXLRECL-------------505     EXCPEXIT----------(NULL)     CI/CA-----------------49
        SHROPTNS(4,3)   RECOVERY     UNIQUE           NOERASE     NOWRITECHK       NOIMBED     NOREPLICAT     UNORDERED
        NOREUSE
      STATISTICS
        REC-TOTAL--------------1     SPLITS-CI--------------0     EXCPS------------------4     INDEX:
        REC-DELETED------------0     SPLITS-CA--------------0     EXTENTS----------------1     LEVELS-----------------1
        REC-INSERTED-----------0     FREESPACE-%CI----------0     SYSTEM-TIMESTAMP:            ENTRIES/SECT-----------7
        REC-UPDATED------------0     FREESPACE-%CA----------0          X'BC1A31F75083B742'     SEQ-SET-RBA------------0
        REC-RETRIEVED----------0     FREESPC------------24576                                  HI-LEVEL-RBA-----------0
      ALLOCATION
        SPACE-TYPE---------TRACK     HI-A-RBA-----------25088
        SPACE-PRI--------------1     HI-U-RBA-------------512
        SPACE-SEC--------------1
      VOLUME
        VOLSER------------Z6CIC1     PHYREC-SIZE----------512     HI-A-RBA-----------25088     EXTENT-NUMBER----------1
        DEVTYPE------X'3010200F'     PHYRECS/TRK-----------49     HI-U-RBA-------------512     EXTENT-TYPE--------X'00'
        VOLFLAG------------PRIME     TRACKS/CA--------------1
        EXTENTS:
        LOW-CCHH-----X'05AF0002'     LOW-RBA----------------0     TRACKS-----------------1
        HIGH-CCHH----X'05AF0002'     HIGH-RBA-----------25087
}
end.
