unit DasdBR7_DM;


{
   Version 7
   - no dll
   - direct read and decompress
   - no hercules function
   - use memory table for performance


  VERIFY:
  functions
  read dscb filtered
  read pds member filtered

   read and ajust data track   ??
   mount tables
   process VTOC / dscb / dates / ebcdic


}

interface

uses
  kbmMemTable,SynBzPas,zlib,
  shellapi,
  StdCtrls,DB,extctrls,
  Windows,Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  menus;

{$I dasd_zos.inc}
{$i vsam.Inc}


type
  TDM = class(TDataModule)
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);


  private

   volume_label : vol_label;
   volume:t_volume_global;

   all_extents:array of t_extent_resume;
   all_dscbs:array of dscb_1;
   fn_opened:boolean;
   t1,t2,hz:int64;

// process dasd read cyl trk direct

   hercules_dasd_header:t_hercules_header;
   iFileHandle,
   track_in_cache_bytes,
   track_in_cache:integer;                   // trk num in cache
   p_deco,
   p_trk:pbyte;                              // last trk data area MAX_TRK_LEN (56664)

   pl1 : c_l1_tab;
   device_header:t_hercules_device;


    // insert one extent in extent list
    function insert_extent(file_num:integer;ext:t_extent):integer;
    function process_dscb1(pd1:p_dscb1;file_num:word;options:integer): boolean;
    function process_dscb4(pp:pointer): boolean;

    // mount in memory all dscb
    function read_all_dscb(vtoc_init:t_cyl_trk_rec;dsn_filter:string;options:integer):integer;

    // seek file using SetFilePointerex - original seek dont work with filesize > maxint
    function file_seek(seek_pos:int64;filehandle:thandle): boolean;






  public
    TK_F,TK_PDS,TK_V,TK_S:TkbmMemTable;
    temp_folder : string;
    mvs_volumes:t_string_array;

    // open dasd file and fill volume data
    function open_zos(options:integer;fn:string):boolean;

    // read cylk track - decompress if needed
    function direct_read_cyl_trk(ckd:p_ckd): pointer;

    // mount table dscb with options
    function mount_table_dscb(options:integer):boolean;


    // dataset has a valid extent?
    function  has_extent:boolean;

    // dataset is empty?
    function  is_dataset_empty:boolean;

    // converte date julian in date
    function  Julian_date(yy,dd:word):TDateTime;

    // get dataset extents
    function  get_file_extents(filenum,seqnum:integer):p_resume;

    // read track - process rec header - optional read next valid track
    function  read_one_track(filenum:integer;ckd:p_ckd; next_track:boolean): pointer;

    // conversion ansi ebcdic ansi
    function  ebcdic_ascii_ptr(pb:pbyte;len,max:integer) :string;
    procedure ebcdic_inplace(var ac : array of char;len:word);

    // process store clock
    function  gmt_stck(pb:pbyte):double;

    // ajust litle ending
    function  get_BYTE3(px:PByte):cardinal;

    // sort table columns
    procedure set_table_index(kb:TkbmMemTable;fn,index_name:string);

    // error
    procedure Error_Show(cod:word;reason:string);

    // show vsam by CI
    procedure Dump_Vsam_by_CI;


    // used by visual modules

    // create menu item for disk volumes
    function  set_menu_disks(dasd_dir:string;menu:TMainMenu;DisksClick:TNotifyEvent):boolean;

    // dataset extent ok?
    function  get_extent_sequence(fileno:integer;cyl,trk:word):p_resume;

    // mount a text list with PS or PDS member to show
    function  show_data_text(options,lines_max,col_max:integer):TStringList;

    // reverse function to find what dataset using a cyl track
    function  get_filename_from_cyl_trk(cyl,trk:word):string;

    // find dataset name or pds member name in all hercules volumes in folder
    function  find_dataset_dsorg(options,find_max:integer;dsn_filter,member_filter,find_text:string;msg:TLabel):TStringList;

    // return string with extents
    function  dataset_extents:string;

    // mount a list with all extents - sort by cyl
    procedure show_volume_allocation;

    // save a text file with all tracks allocation for a dataset
    procedure map_generate;

    // save a text file with VTOC data
    procedure vtoc_print_all(msg:TForm);

    // get a filename from a volid
    function  get_volume_fname(vol:string):string;

    // dataset dlen+klen used
    function calculate_space_used(ckd:tckd):integer;

    // compute e set next track
    function set_next_track(fileno:integer;ckd:p_ckd):boolean;

    // set next record header
    function get_next_header(var pb:pbyte;key_data_len:integer):rec_header;

    // list with all pds directory
    function read_all_pds_dir(ckd:p_ckd;options:integer;name_filter:string):TList;


    procedure free_dir_list(pl:TList);


    procedure close_file;

    // save a dasd file in bin format
    procedure save_binary(fn:string);
    function save_raw_data(with_header:boolean;fn:string):boolean;

    // get record num from cyl trk rec map
    function find_next_record(pb:pbyte;rec_required:byte;hrec:p_rec_header):integer;

    // return datase format
    function format_file_date(dt:TDateTime):string;

    // show dataset dump by cyl/trk/rec
    function dump_data(pb: pbyte; init, len: integer): string;


    // global properties
    property volume_data   : t_volume_global read volume;               // global statistics and data
    property volume_pds_rec: integer write volume.total_members_pds80;  // update by pds unit

  end;

var
  DM: TDM;

implementation

function SetFilePointerEx(hFile: THandle; liDistanceToMove: Int64;
    lpNewFilePointer: PInt64; dwMoveMethod: DWORD): BOOL;
    stdcall; external 'kernel32.dll';

{$R *.DFM}

{ TDM }


{
   data module create:
   get track read area
   create tables structures

}
procedure TDM.DataModuleCreate(Sender: TObject);
begin

   temp_folder:=GetEnvironmentVariable('TEMP')+'\';;
   volume.tracks_total:=0;

   GetMem(p_trk,65536);
   GetMem(p_deco,65536);
   QueryPerformanceFrequency(hz);

   volume.tracks_read:=0;
   TK_F:=TkbmMemTable.Create(self);
   with TK_F.FieldDefs do
   begin
      Add('dscb',ftInteger);
      Add('name',ftString,44);
      Add('dsorg',ftString,6);
      Add('recfm',ftString,6);
      Add('lrecl',ftInteger);
      Add('blk',ftInteger);
      Add('recs',ftInteger);
      Add('createdate',ftDateTime);
      Add('lastdate',ftDateTime);
      Add('extents',ftInteger);
      Add('last_tt',ftInteger);
      Add('last_r',ftInteger);
      Add('trks',ftInteger);
      Add('alloc',ftInteger);
      Add('ocup',ftInteger);
      Add('first_extent',ftInteger);
      Add('first_cyl',ftInteger);
   end;
   TK_F.CreateTable;
   with TK_F.FieldByName('createdate') as  TDateTimeField  do DisplayFormat:='yyyy/mm/dd';
   with TK_F.FieldByName('lastdate') as  TDateTimeField  do DisplayFormat:='yyyy/mm/dd';

   TK_PDS:=TkbmMemTable.Create(self);
   with TK_PDS.FieldDefs do
   begin
      Add('cod',ftInteger);
      Add('name',ftString,8);
      Add('size',ftInteger);
      Add('created',ftDateTime);
      Add('lastused',ftDateTime);
      Add('userid',ftString,8);
      Add('alias',ftBoolean);
      Add('extra',ftString,128);
      Add('vers',ftString,8);
      Add('cyl',ftInteger);
      Add('trk',ftInteger);
      Add('ttr',ftInteger);
      Add('n',ftInteger);
   end;
   TK_PDS.CreateTable;

   with TK_PDS.FieldByName('created') as  TDateTimeField  do DisplayFormat:='yyyy/mm/dd';
   with TK_PDS.FieldByName('lastused') as  TDateTimeField  do DisplayFormat:='yyyy/mm/dd hh:nn';


   TK_V:=TkbmMemTable.Create(self);
   with TK_V.FieldDefs do
   begin
      Add('num',ftInteger);
      Add('name',ftString,44);
      Add('maxrecl',ftInteger);
      Add('cisize',ftInteger);
      Add('ci_ca',ftInteger);
      Add('keyl',ftInteger);
      Add('rpk',ftInteger);
      Add('rec_tot',ftInteger);
      Add('rec_del',ftInteger);
      Add('rec_ins',ftInteger);
      Add('rec_upd',ftInteger);
      Add('rec_retr',ftInteger);
      Add('pri_sp',ftInteger);
      Add('sec_sp',ftInteger);
      Add('alloc',ftString,8);
      Add('create',ftDateTime);
      Add('excp',ftInteger);
      Add('extents',ftInteger);
      Add('base',ftString,44);
      Add('h_urba',ftInteger);
      Add('h_arba',ftInteger);
      Add('trk_ci',ftInteger);
      Add('t',ftString,8);
      Add('ix_lev',ftInteger);
      Add('perc',ftFloat);
      Add('ix_ofs',ftInteger);
   end;
   TK_V.CreateTable;
   with TK_V.FieldByName('perc') as  TFloatField  do DisplayFormat:='#.0';


   TK_S:=TkbmMemTable.Create(self);
   with TK_S.FieldDefs do
   begin
      Add('num',ftInteger);
      Add('lrecl',ftString,44);
      Add('line',ftString,1024);// to do var
   end;
   TK_S.CreateTable;
   TK_S.Open;
   set_table_index(TK_S,'num','i_num');
   TK_S.Close;

end;


function Swap4(a:cardinal):cardinal; asm bswap eax end;


// next rec header in track
function TDM.get_next_header(var pb:pbyte;key_data_len:integer):rec_header;
var hrec:rec_header;
begin
   inc(pb,key_data_len);
   move(pb^,hrec,sizeof(rec_header));
   hrec.cyl:=swap(hrec.cyl);
   hrec.head:=swap(hrec.head);
   hrec.dlen:=swap(hrec.dlen);
   inc(pb,sizeof(rec_header));
   result:=hrec;
end;


//convert ibm julian date to tdatetime
function TDM.julian_date(yy,dd:word):TDateTime;
var mm,last_mo : word;
begin
   Result:=0;
   if yy>2090 then exit;
   if yy<1900 then inc(yy,1900);
   if yy<1970 then inc(yy,100); // 2001 - 2050
   if yy<1970 then exit;
   mm:=1;
   last_mo:=0;
   if IsLeapYear(yy)
   then while dd>d366[mm] do begin inc(mm); last_mo:=d366[mm-1]; end
   else while dd>d365[mm] do begin inc(mm); last_mo:=d365[mm-1]; end;
   dec(dd,last_mo);
   if (dd>0) and (dd<32) and (mm>0) and (mm<13)
   then Result:=EncodeDate(yy,mm,dd);
end;




// read one track - option to read next if end of record
// this function has internal track cache
// return -->  data pointer... and ckd.read with read data length

function TDM.read_one_track(filenum:integer;ckd:p_ckd; next_track:boolean): pointer; // versao read raw track
var pb: Pbyte;
    hrec:rec_header;
begin
   Result:=nil;

   if ckd^.cyl=0 then
   if ckd^.trk=0 then
   if ckd^.nrec=0 then exit;      // error

   if (volume.num_cyl>0) then
   if (ckd^.cyl>volume.num_cyl) or (ckd.trk>volume.trk_per_cyl) then
   begin
      Error_Show(99,'');
      exit;
   end;
   try
   pb:=direct_read_cyl_trk(ckd);                  // cache in dasd.dll ...
   except end;
   if pb=nil then                            // not found - try next...
   begin
      if next_track=false
      then exit;

      if not set_next_track(filenum,ckd)
      then exit;

      pb:=direct_read_cyl_trk(ckd);
      if pb=nil then exit;                      // next track not found - byebye
      //inc(volume.tracks_read);                  // statistics: num tracks read
   end;


   hrec:=DM.get_next_header(pb,0);
   if hrec.cyl<>ckd.cyl then
   begin
      ShowMessage('error 397 - hrec invalid');
      exit;
   end;

   while hrec.rec<>ckd.nrec do
   begin                                           // search for record num
      if hrec.cyl=$ffff then
      begin
         if hrec.cyl=$ffff then
         begin
            if next_track=false
            then exit;

            if not set_next_track(filenum,ckd)
            then exit;
            pb:=direct_read_cyl_trk(ckd);
            if pb=nil then exit;                   // next track not found - byebye
            hrec:=DM.get_next_header(pb,0);
            continue;
         end;
      end;
      inc(pb,hrec.klen+hrec.dlen);
      hrec:=DM.get_next_header(pb,0);
   end;

   dec(pb,sizeof(rec_header));                     // ajust result pointer to rec_header
   Result:=pb;                                     // point to rec header

end;


procedure TDM.Error_Show(cod:word;reason:string);
var ms : string;
begin
   ms:='Error '+format('%.3d',[cod])+' - ';
   case cod of
   2   : ms:=ms+'Not a CDK 370 file';
   3   : ms:=ms+'PDS Dir not found';
   4   : ms:=ms+'VOL not initialized';
   12  : ms:=ms+'Extent not found??';
   51  : ms:=ms+'Compress trk read error';
   55  : ms:=ms+'Compression mode unknow';
   56  : ms:=ms+'Compression table too large';
   81  : ms:=ms+'Read error';
   92  : ms:=ms+'Seek error';
   94  : ms:=ms+'Read error';
   95  : ms:=ms+'Empty file';
   96  : ms:=ms+'HA trk <> trkl';
   97  : ms:=ms+'HA cyl <> cyl';
   98  : ms:=ms+'Decompress error';
   99  : ms:=ms+'ckd read invalid';
   102 : ms:=ms+'Read vtoc';
   103 : ms:=ms+'DSCB 4 not found';
   104 : ms:=ms+'Read vtoc';
   121 : ms:=ms+'Rec num no found';
   122 : ms:=ms+'Rec not found';
   123 : ms:=ms+'Not PDS ';
   601 : ms:=ms+'PDS dir > 256';
   602 : ms:=ms+'No members found';
   902 : ms:=ms+'Not a CDK 370 file';
   end;
   ShowMessage(ms+' '+reason);
end;









function get_vtoc_dsorg(pd1 :p_dscb1):string;
begin

   if (pd1^.f1_DS1DSRG1 and $80)>0 then Result:='IS' else
   if (pd1^.f1_DS1DSRG1 and $40)>0 then Result:='PS' else
   if (pd1^.f1_DS1DSRG1 and $20)>0 then Result:='DA' else
   if (pd1^.f1_DS1DSRG1 and $02)>0 then Result:='PO' else
   if (pd1^.f1_DS1DSRG1 and $01)>0 then Result:='U' else
   if (pd1^.f1_DS1DSRG2 and $08)>0 then Result:='VSAM'
   else Result:='???';

   if (pd1^.f1_DS1SMSFG )>0 then
   if (pd1^.f1_DS1SMSFG and 8 )>0 then
   begin
      if (pd1^.f1_DS1SMSFG and 2)>0
      then Result:='HFS'
      else Result:='PDSE';
   end;

   if (pd1^.f1_DS1FLAG1 and DS1COMPR)>0
   then Result:=Result+'_C';
end;


function get_vtoc_recfm(pd1 :p_dscb1):string;
begin
   if (pd1.f1_DS1RECFM and $C0)=$C0    then  Result:= 'U' else
   if (pd1.f1_DS1RECFM and $80)=$80    then
   begin
      Result:= 'F';
      if (pd1.f1_DS1RECFM and $10)=$10
      then  Result:='FB';
   end
   else

   if (pd1.f1_DS1RECFM and $40)=$40    then
   begin
      Result:= 'V';
      if (pd1.f1_DS1RECFM and $10)=$10 then
      begin
         Result:='VB';
         if (pd1.f1_DS1RECFM and $80)=$80
         then  Result:='VBS';
      end;
   end
   else Result:='?';
   // asa ou machine carriage control
   if (pd1.f1_DS1RECFM and $04)=4      then  Result:=Result+ 'A';
   if (pd1.f1_DS1RECFM and $02)=2      then  Result:=Result+ 'M';
end;



// create volume extents array in all_extents
// update volume_tracks

function TDM.Insert_extent(file_num:integer;ext:t_extent):integer;
var ucc,lcc,utt,ltt : word;
    extent_init,extent_end:integer;
begin
   Result:=0;
   if (ext.typeind=0) then exit; // not extent

   lcc:=swap(ext.l_cyl);
   ucc:=swap(ext.h_cyl);

   ltt:=swap(ext.l_trk);
   utt:=swap(ext.h_trk);

   extent_init:=(lcc * volume.trk_per_cyl)+ltt;
   extent_end :=(ucc * volume.trk_per_cyl)+utt;
   Result:=(extent_end - extent_init +1);

   inc(volume.tracks_allocated,Result);

   all_extents[volume.ix_extent].filenum:=file_num;
   all_extents[volume.ix_extent].seqno:=ext.seqno;
   all_extents[volume.ix_extent].l_cyl:=lcc;
   all_extents[volume.ix_extent].l_trk:=ltt;
   all_extents[volume.ix_extent].h_cyl:=ucc;
   all_extents[volume.ix_extent].h_trk:=utt;
   inc(volume.ix_extent);

   if volume.ix_extent=high(all_extents)
   then SetLength(all_extents,high(all_extents)+2048);

end;



// dscb type 3 - extent collection
function process_dscb_type3(ckd:p_ckd;fileno:integer):integer;
var pb:pbyte;
    dscb3  : p_dscb3;
    hrec:rec_header;
    i : word;
begin
   Result:=0;
   pb:=DM.read_one_track(-1,ckd,false);
   if pb=nil then exit;
   hrec:=DM.get_next_header(pb,0);   //   pb point to data
   dscb3:=p_dscb3(pb);


   if Dscb3^.idfmt=$f3 then
   begin
      for i:=0 to 3 do
      if dscb3.f3_ext1[i].typeind>0
      then inc(Result,DM.Insert_extent(fileno,dscb3.f3_ext1[i]));
      for i:=0 to 8 do
      begin
         if dscb3.f3_ext2[i].typeind=0
         then break;
         inc(Result,DM.Insert_extent(fileno,dscb3.f3_ext2[i]));
      end;
   end;
   if (dscb3.f3_DS1PTRDS.cc<>0) or                  // possible pointer to f2 or f3 DSCB */
      (dscb3.f3_DS1PTRDS.hh<>0) then
      begin
         ckd.cyl  :=swap(dscb3.f3_DS1PTRDS.cc);
         ckd.trk  :=swap(dscb3.f3_DS1PTRDS.hh);
         ckd.nrec :=     dscb3.f3_DS1PTRDS.r;
         inc(Result,process_dscb_type3(ckd,fileno));
      end;

end;



// dataset get all extents
// return dastaset tracks alloc

function get_all_extents(fileno:integer;pd1:p_dscb1):integer;
var ckd:tckd;
begin
   Result:=0;
   if pd1^.f1_extents>0
   then inc(Result,DM.insert_extent(fileno,pd1.f1_DS1EXT1));

   if pd1.f1_extents>1
   then inc(Result,DM.Insert_extent(fileno,pd1.f1_DS1EXT2));

   if pd1.f1_extents>2 then
   begin
      inc(Result,DM.Insert_extent(fileno,pd1.f1_DS1EXT3));
      if (pd1.f1_DS1PTRDS.cc<>0) or                  // possible pointer to f2 or f3 DSCB */
         (pd1.f1_DS1PTRDS.hh<>0) then
      begin
         ckd.cyl:=swap(pd1.f1_DS1PTRDS.cc);
         ckd.trk:=swap(pd1.f1_DS1PTRDS.hh);
         ckd.nrec:=pd1.f1_DS1PTRDS.r;
         inc(Result,process_dscb_type3(@ckd,fileno));
      end;
   end;

end;




// dscb1 - dataset information
function TDM.process_dscb1(pd1:p_dscb1;file_num:word;options:integer): boolean;
var blkl,recl,dsn_tracks:integer;
    recfm,
    dsorg,
    ss  : string;
    file_date : TDateTime;
begin
   ss:=pd1^.dsn;
   ss:=trim(ss);

   dsorg:=get_vtoc_dsorg(pd1);
   recfm:=get_vtoc_recfm(pd1);
   blkl:=swap(pd1.f1_DS1BLKL);
   recl:=swap(pd1.f1_DS1LRECL);

   TK_F.Insert;
   TK_F.FieldByName('first_extent').AsInteger:=volume.ix_extent;
   TK_F.FieldByName('dscb').AsInteger:=file_num;
   TK_F.FieldByName('name').AsString:=ss;
   TK_F.FieldByName('dsorg').AsString:=dsorg;
   TK_F.FieldByName('recfm').AsString:=recfm;
   TK_F.FieldByName('extents').AsInteger:=pd1.f1_extents;
   if recl>0
   then TK_F.FieldByName('lrecl').AsInteger:=recl;
   if blkl>0
   then TK_F.FieldByName('blk').AsInteger:=blkl;
   if pd1.f1_cre_year>0 then
   begin
    file_date:=julian_date(pd1.f1_cre_year,swap(pd1.f1_cre_day));
    if file_date>0
    then TK_F.FieldByName('createdate').AsDateTime:=file_date;
   end;

   if pd1.f1_last_year>0 then
   begin
      file_date:=julian_date(pd1.f1_last_year,swap(pd1.f1_last_day));
      if file_date>0
      then TK_F.FieldByName('lastdate').AsDateTime:=file_date;
   end;

   if (swap(pd1.f1_DS1LSTAR.hh)>0) or (pd1.f1_DS1LSTAR.r>0) then
   begin
      TK_F.FieldByName('last_tt').AsInteger:=swap(pd1.f1_DS1LSTAR.hh);
      TK_F.FieldByName('last_r').AsInteger:=pd1.f1_DS1LSTAR.r;
   end;

   TK_F.FieldByName('first_cyl').AsInteger:= swap(pd1.f1_DS1EXT1.l_cyl);

   dsn_tracks:=get_all_extents(file_num,pd1);

   TK_F.FieldByName('trks').AsInteger:=dsn_tracks;
   if dsn_tracks>0
   then TK_F.FieldByName('ocup').AsInteger:=((TK_F.FieldByName('last_tt').AsInteger+1) * 100) div dsn_tracks;
   TK_F.FieldByName('alloc').AsInteger:=(dsn_tracks*(volume.trk_size div 1024));
   TK_F.Post;
   Result:=True;
end;


// dscb4 - volume descriptor
function TDM.process_dscb4(pp:pointer): boolean;
var pd4 : ^dscb_4;
    v_dscb:t_extent;
    extent_init,extent_end:integer;
begin
   pd4:=pp;

   volume.num_dscbs:=swap(pd4^.f4_n_dscb);
   volume.num_cyl:=swap(pd4^.f4_dev_c.DS4DSCYL);
   volume.tracks_total:=volume.num_cyl*volume.trk_per_cyl;

   v_dscb.l_cyl:=swap(pd4^.f4_vtoc_extent.l_cyl);
   v_dscb.l_trk:=swap(pd4^.f4_vtoc_extent.l_trk);
   v_dscb.h_cyl:=swap(pd4^.f4_vtoc_extent.h_cyl);
   v_dscb.h_trk:=swap(pd4^.f4_vtoc_extent.h_trk);

   volume.dscb_ext.h_cyl:=v_dscb.h_cyl;
   volume.dscb_ext.h_trk:=v_dscb.h_trk;

   volume.vtoc_end.cyl:=swap(pd4^.f4_high_dscb.cyl);
   volume.vtoc_end.trk:=swap(pd4^.f4_high_dscb.trk);
   volume.vtoc_end.rec:=pd4^.f4_high_dscb.rec;

   extent_init:=(v_dscb.l_cyl * volume.trk_per_cyl)+v_dscb.l_trk;
   extent_end :=(v_dscb.h_cyl * volume.trk_per_cyl)+v_dscb.h_trk;
   inc(volume.tracks_allocated,(extent_end - extent_init +1));
   if swap(pd4^.f4_high_dscb.cyl)=0 then;
   Result := true;
end;


// list all volumes VTOC                          }
//'seq dsn                                          dsorg recfm lrecl  blkl extents tracks
//'  1 SYS1.VTOCIX.Z6DIS1                           PS    F     2048   2048       1     15'

procedure TDM.vtoc_print_all(msg:TForm);
var
   fn,fnsai,s,dsorg,recfm,savecaption:string;
   i,k,count,dataset_tracks:integer;
   pd1 : dscb_1;
   ts:TStringList;
   extents,blkl,recl,
   seq:integer;
   dsn:string;
begin

   ts:=TStringList.Create;
   count:=0;
   fnsai:='';
   savecaption:=msg.Caption;
   close_file;

   SetLength(all_extents,128);                  // max 128 extent per dataset

   for i:=0 to high(mvs_volumes) do
   begin
      fn:=mvs_volumes[i];
      volume.fn:='???';

      if not open_zos(0,fn)
      then continue;
      inc(count);
      if fnsai=''
      then fnsai:=ExtractFilePath(fn)+'ALL_VTOC.txt';

      volume.fn:=fn;

      msg.Caption:='process '+fn;


      ts.Add('');
      s:=format('****** volume %s  cyls=%d dscbs=%d filename %s ',[volume.volid,volume.num_cyl,volume.num_dscbs,fn]);
      ts.Add(s);
      ts.Add('');

      s:='seq dsn                                          dsorg recfm lrecl  blkl  extents tracks';
      ts.Add(s);
      seq:=0;

      for k:=0 to high(all_dscbs) do
      begin
         pd1:=all_dscbs[k];
         if pd1.idfmt=241 then
         begin
            volume.ix_extent:=0;
            dataset_tracks:=get_all_extents(0,@pd1);
            extents:=volume.ix_extent;

            inc(seq);
            dsn:=trim(pd1.dsn);
            dsorg:=get_vtoc_dsorg(@pd1);
            recfm:=get_vtoc_recfm(@pd1);
            blkl:=swap(pd1.f1_DS1BLKL);
            recl:=swap(pd1.f1_DS1LRECL);

            s:=format('%3d %-44s %-4s  %-4s %6d %6d  %6d %6d',
               [seq,dsn,dsorg,recfm,recl,blkl,extents,dataset_tracks]);
            ts.Add(s);
         end;
      end;
      close_file;
   end;

   if ts.Count=0 then
   begin
      ShowMessage('warning - none found ???');
   end
   else
   begin
      ts.SaveToFile(fnsai);
      ShowMessage(format('OK - saved files=%d  saved --> %s',[count,fnsai]));
      ShellExecute(0,'OPEN',pchar(fnsai),#0,pchar(temp_folder),SHOW_FULLSCREEN);
   end;
   ts.Free;
   SetLength(all_extents,0);
   volume.fn:='???';
   msg.Caption:=savecaption;
end;




// return data from storeclock
function TDM.gmt_stck(pb:pbyte):double;  // 7 bytes - remove first byte -- signal
var tt : array[0..7] of byte;
    pti : ^TLargeInteger;
    dtgmt : TDateTime;
begin
   //dtgmt:=EncodeTime(abs(gmt_offset),0,0,0);
   dtgmt:=EncodeTime(0,0,0,0);
   tt[7]:=0;
   tt[6]:=pb^; inc(pb);
   tt[5]:=pb^; inc(pb);
   tt[4]:=pb^; inc(pb);
   tt[3]:=pb^; inc(pb);
   tt[2]:=pb^; inc(pb);
   tt[1]:=pb^; inc(pb);
   tt[0]:=pb^;
   pti:=@tt[0];
   Result:=(pti^ / $141DD760000)+2-dtgmt;
end;




// CD_V enabled and valid
procedure TDM.Dump_Vsam_by_CI;
var   cchhr:tckd;
      fout : TFileStream;
      name,fn:string;
      //pRid,
      pc:pbyte;
      fileno,seqno,
      ci_trk,
      ci_size:integer;
      hrec:rec_header;
      exts:p_resume;

begin
   if TK_V.IsEmpty then exit;
   fileno:=TK_F.FieldByName('dscb').AsInteger;
   seqno:=0;
   TK_V.FieldByName('trk_ci').AsInteger;
   ci_trk:=TK_V.FieldByName('trk_ci').AsInteger;
   if ci_trk=0 then exit;
   ci_size:=TK_V.FieldByName('cisize').AsInteger;
   if ci_size=0 then exit;
   name:=TK_V.FieldByName('name').AsString;

   if not TK_F.Locate('Name',name,[]) then exit;

   if TK_F.FieldByName('name').AsString<>name then exit;

   fn:=temp_folder+'\VSAM_CA_'+TK_V.FieldByName('name').AsString+'.dat';
   fout:=TFileStream.Create(fn,fmCreate);

   while true do
   begin
      exts:=get_file_extents(fileno,seqno);
      if exts=nil then exit;
      cchhr.cyl:=exts.l_cyl;
      cchhr.trk:=exts.l_trk;
      cchhr.nrec:=1;
      while (cchhr.cyl<=exts.h_cyl) and (cchhr.trk<=exts.h_trk) do
      begin

        pc:=read_one_track(fileno,@cchhr,false);
        if pc=nil then
        begin
           Error_show(81,'');
           Break;
        end;

         move(pc^,hrec,sizeof(rec_header));
         hrec.cyl:=swap(hrec.cyl);
         hrec.head:=swap(hrec.head);
         hrec.dlen:=swap(hrec.dlen);

         if hrec.cyl<>$FFFF then
         if hrec.dlen>8
         then fout.write(pc^,hrec.dlen);

         inc(cchhr.nrec);

         if hrec.cyl=$FFFF then
         begin
            cchhr.nrec:=1;
            inc(cchhr.trk);
         end;

        if cchhr.trk>=volume.trk_per_cyl then
        begin
           cchhr.trk:=1;
           inc(cchhr.cyl);
        end;
     end;
   end;

   fout.Free;

   ShowMessage('ok created '+fn);
end;


function TDM.get_BYTE3(px:PByte):cardinal;
var pc :^cardinal;
    ri : array[0..3] of byte;
begin
   // - 3 bytes..
   ri[3]:=0;
   ri[2]:=px^; inc(px);
   ri[1]:=px^; inc(px);
   ri[0]:=px^;
   pc:=@ri;
   Result:=pc^;
end;

// ibm unpacked data
function unpack(bb:byte):word; begin  Result:=(bb shr 4) * 10 + (bb and $f) end;

// $01 $04 $32 $3F  --> 2004 / 11/ 18
function get_datap(aa:array of byte):TDateTime;
var yy,dd : word;
begin
   yy:=unpack(aa[0]) * 100;
   yy:=yy+unpack(aa[1])+1900;
   dd:=unpack(aa[2]) * 10;
   dd:=dd + (aa[3] shr 4);
   Result:=DM.Julian_date(yy,dd);
end;


// mount dataset volume menu
// read all disk header in hercules folder
// change to read file - tfilestream read all disk - need only header...
function TDM.set_menu_disks(dasd_dir:string;menu:TMainMenu;DisksClick:TNotifyEvent):boolean;
var ok,count:integer;
    sr:TSearchRec;
    //fa:TFileStream;
    iFileLength:int64;
    iBytesRead,
    iFileHandle: Integer;

    hercules_header:t_hercules_header;
    s:string;
    ti:TMenuItem;
begin
   menu.Items[0].Clear;
   count:=0;
   SetLength(mvs_volumes,256);
   ok:=FindFirst(dasd_dir+'*.*',faArchive,sr);
   while ok=0 do
   begin

      if (sr.Name[1]<>'.') and (sr.FindData.nFileSizeLow>100*1024) then  // only size greater than 100K
      begin
         iFileHandle := FileOpen(dasd_dir+sr.name,fmOpenRead+fmShareDenyNone);
         iFileLength:=FileSeek(iFileHandle,int64(0),2);
         FileSeek(iFileHandle,0,0);
         if iFileLength>sizeof(t_hercules_header) then
         begin
            hercules_header.dev_id[1]:=' ';
            iBytesRead := FileRead(iFileHandle, hercules_header, sizeof(hercules_header));
            if iBytesRead<>sizeof(hercules_header)
            then break;

            s:=hercules_header.dev_id;
            if (s='CKD_P370') or (s='CKD_C370') then
            begin
               s:=sr.name;
               ti:=TMenuItem.Create(menu);
               ti.Caption:=s;
               ti.OnClick:=DisksClick;
               menu.Items[0].Add(ti);
               mvs_volumes[count]:=UpperCase(dasd_dir+sr.Name);        // save all fn for mvs volumes
               inc(count);
            end;
         end;
         FileClose(iFileHandle);
      end;
      ok:=FindNext(sr);
   end;
   FindClose(sr);
   SetLength(mvs_volumes,count);
   Result:=true;
end;




// volume extent map
procedure TDM.map_generate;
var used_bytes,
    avg_count,avg_sum,fileno,seqno,
    trk_used,trk_count:integer;
    pb:pbyte;
    hrec:rec_header;
    s:string;
    ts:TStringList;
    exts:p_resume;
    ckd:tckd;

begin
   if not TK_F.Active then exit;

   ts:=TStringList.Create;
   s:=TK_F.FieldByName('name').AsString;
   ts.add(s);

   fileno:=TK_F.FieldByName('dscb').AsInteger;
   seqno:=0;

   trk_count:=0;
   avg_count:=0;
   avg_sum:=0;

   while true do
   begin
      exts:=get_file_extents(fileno,seqno);
      inc(seqno);
      if exts=nil then break;
      if exts.filenum<>fileno then break;
      ts.Add('');
      s:=format('-------->  extent %d  from %d/%d to %d/%d',[seqno,exts.l_cyl,exts.l_trk,exts.h_cyl,exts.h_trk]);
      ts.Add(s);
      ts.Add('');
      ckd.cyl:=exts.l_cyl;
      ckd.trk:=exts.l_trk;
      ckd.nrec:=0;
      ckd.read:=0;


      while true do
      begin
         if (ckd.cyl>exts.h_cyl)
         then break;

         pb:=read_one_track(fileno,@ckd,true);
         if pb=nil then break;
         hrec:=get_next_header(pb,0);


         if (ckd.cyl=exts.h_cyl) and (ckd.trk>exts.h_trk) then
         begin
            if (ckd.cyl=exts^.h_cyl) and (ckd.trk>exts.h_trk) then
            break;
         end;
         used_bytes:=sizeof(t_CKDDASD_TRKHDR);
         // process one track...

         inc(trk_count);

         while true do
         begin
            if ((hrec.klen=$ff) and (hrec.dlen=$ffff)) then
            begin
               inc(used_bytes,sizeof(rec_header));
               trk_used:=used_bytes * 100 div  volume.trk_size;
               inc(avg_count);
               inc(avg_sum,trk_used);
               s:=format('<end  track %d at %d (%4X) used %3d %% >'+#10,[trk_count,used_bytes,used_bytes,trk_used]);
               ts.Add(s);
               break;
            end;
            inc(used_bytes,hrec.klen+hrec.dlen+sizeof(rec_header));

            s:=format('cyl %.4d trk %.2d nrec %.2d klen %.3d dlen %.5d used %.6d (%X)',
                 [hrec.cyl,hrec.head,hrec.rec,hrec.klen,hrec.dlen,used_bytes,used_bytes]);
            ts.Add(s);

            if (hrec.klen=$ff) and (hrec.dlen=$ffff) then break;
            hrec:=get_next_header(pb,hrec.dlen+hrec.klen);
         end;


         inc(ckd.trk);
         if ckd.trk=volume.trk_per_cyl then
         begin
            inc(ckd.cyl);
            ckd.trk:=0;
         end;
      end;
   end;

   s:=format('---> file avg used %d %%',[(avg_sum div avg_count)]);
   ts.Add(s);

   s:=temp_folder+'\'+volume.volid+'_map.txt';
   ts.SaveToFile(s);
   ts.Free;

   ShellExecute(0,'OPEN',pchar(s),#0,pchar(temp_folder),SHOW_FULLSCREEN);
end;


// sort grid columns
procedure TDM.set_table_index(kb:TkbmMemTable;fn,index_name:string);
var i:integer;
    desc:boolean;
begin

   kb.DisableControls;
   desc:=false;

   for i:=0 to kb.IndexDefs.Count-1                   // change index order?
   do desc:=(kb.IndexDefs.Items[i].Fields=fn) and
            not (ixDescending in kb.IndexDefs.Items[i].Options);

   for i:=kb.IndexFieldCount-1 downto 0               // delete all index
   do  kb.DeleteIndex(kb.IndexName);

   kb.UpdateIndexes;

   if desc
   then kb.AddIndex(index_name,fn,[ixDescending])     // create new index
   else kb.AddIndex(index_name,fn,[]);

   kb.IndexFieldNames:=fn;
   kb.EnableControls;
   kb.First;
end;


// get extent by file  num / sequential
function TDM.get_file_extents(fileNum,seqnum:integer):p_resume;
var i,i_init:integer;
begin
   Result:=nil;
   if seqnum>0 then
   if seqnum>0 then;
   if TK_F.RecordCount>0
   then i_init:=TK_F.FieldByName('first_extent').AsInteger
   else i_init:=0;

   for i:=i_init to volume.ix_extent do
   begin
      if all_extents[i].filenum<filenum
      then continue;
      if all_extents[i].filenum>filenum
      then break;
      if all_extents[i].seqno<seqnum
      then continue;
      Result:=@all_extents[i];
      break;
   end;
end;

// return dataset name from a cyl/trk

function TDM.get_filename_from_cyl_trk(cyl,trk:word):string;
var i:integer;
    l_cyltrk,h_cyltrk,cyltrk:integer;
begin
   Result:='not allocated';
   cyltrk:=cyl  * volume.trk_per_cyl+trk;
   for i:=0 to high(all_extents) do
   begin

      l_cyltrk:=all_extents[i].l_cyl * volume.trk_per_cyl + all_extents[i].l_trk;
      h_cyltrk:=all_extents[i].h_cyl * volume.trk_per_cyl + all_extents[i].h_trk;
      if cyltrk>=l_cyltrk then
      if cyltrk<=h_cyltrk then
      begin
         if not TK_F.Locate('dscb',all_extents[i].filenum,[]) then exit;
         Result:=IntToStr(TK_F.FieldByName('dscb').AsInteger)+'  '+
                 TK_F.FieldByName('name').AsString;
         break;
      end;
   end;
end;

// verify dataset extent

function TDM.get_extent_sequence(fileno:integer;cyl,trk:word):p_resume;
var ttr_req,ttr_high,ttr_low,seqno:integer;
    exts:p_resume;

begin

   Result:=nil;

   seqno:=0;
   ttr_req:=(cyl * volume.trk_per_cyl)+trk;

   while true do
   begin
      exts:=get_file_extents(fileno,seqno);
      if exts=nil then break;

      ttr_high:=(exts.h_cyl * volume.trk_per_cyl)+exts.h_trk;
      ttr_low :=(exts.l_cyl * volume.trk_per_cyl)+exts.l_trk;

      if (ttr_req<=ttr_high) and (ttr_req>=ttr_low) then
      begin
         Result:=exts;
         break;
      end;
      inc(seqno);
   end;

end;


// ansi conversion in place
procedure   TDM.ebcdic_inplace(var ac : array of char;len:word);
var i : word;
    cc: byte;
begin
   if len=0 then exit;
   for i:=0 to len-1 do
   begin
      cc:=ord(ac[i]);
      ac[i]:=ebcdic_to_ascii[cc];
   end;
end;


// ansi conversion to string - max=0 to all bytes or limited to max
function TDM.ebcdic_ascii_ptr(pb:pbyte;len,max:integer) :string;
var s:string;
    i:integer;
begin
   if (max>0) and (len>max)
   then len:=max;
   SetLength(s,len);
   for i:=1 to len do
   begin
      s[i]:=ebcdic_to_ascii[pb^];
      inc(pb);
   end;
   Result:=s;
end;

// filter dataset type
function is_dsn_type(options:integer;dsn_filter:string;pd1:p_dscb1):boolean;
var s:string;
begin
   Result:=true;
   s:=get_vtoc_dsorg(pd1);

   if (options and option_type_all)>0 then exit;
   if (options and option_type_pds)>0 then
      if s='PO' then exit;
   if (options and option_type_ps)>0 then
      if s='PS' then exit;
   if (options and option_type_vsam)>0 then
      if s='VSAM' then exit;
   if (options and option_type_hps)>0 then
      if s='HFS' then exit;
   if (options and option_type_pdse)>0 then
      if s='PDSE' then exit;
   Result:=false;
end;



function is_dsn_filter(options:integer;dsn_filter:string;pd1:p_dscb1):boolean;
var dscb_name:string;
begin
   Result:=true;
   if dsn_filter='' then exit;
   dscb_name:=DM.ebcdic_ascii_ptr(@pd1.dsn,44,44);

   if (options and option_find_initial)>0
   then Result:=copy(dscb_name,1,length(dsn_filter))=dsn_filter
   else
   begin
      if (options and option_find_partial)>0
      then Result:=pos(dsn_filter,dscb_name)>0
      else Result:=dsn_filter=dscb_name;
   end;
end;

function is_member_filtered(options:integer;member_filter,member_name:string):boolean;

begin
   if (options and option_find_initial)>0
   then Result:=copy(member_name,1,length(member_filter))=member_filter
   else
   begin
      if (options and option_find_partial)>0
      then Result:=pos(member_filter,member_name)>0
      else Result:=member_filter=member_name;
   end;
end;

// read all dscb in arrays all_dscb;
// assume vtoc has only one extent
function TDM.read_all_dscb(vtoc_init:t_cyl_trk_rec;dsn_filter:string;options:integer):integer;
var pb,pdscb:pbyte;
    q:integer;
    dscb_count_zeros:integer;
    ckd:tckd;
    recfm:string;
    hrec:rec_header;
    vtoc_end:t_cyl_trk_rec;
    pd1:p_dscb1;
    dscb5:p_dscb5;
begin
   SetLength(all_dscbs,0);
   dsn_filter:=UpperCase(dsn_filter);

   Result:=0;

   // read first track from vtoc
   ckd.cyl:=vtoc_init.cyl;
   ckd.trk:=vtoc_init.trk;
   ckd.nrec:=vtoc_init.rec;
   ckd.read:=0;

   pb:=read_one_track(-1,@ckd,false);

   if pb=nil then
   begin
      Error_Show(102,'- not found vtoc');
      exit;
   end;

   hrec:=get_next_header(pb,0);   //   pb point to data

   if hrec.dlen<>96 then
   begin
      Error_Show(102,' no dscb4 found');
      exit;
   end;

   q:=0;
   dscb_count_zeros:=0;
   SetLength(all_dscbs,2048); // 1024 * 140 =  286720 bytes

   while hrec.dlen=96 do
   begin

      pdscb:=pb;
      inc(pdscb,44);

      case pdscb^ of
         0 : inc(dscb_count_zeros);
         $f1:
         begin
            pd1:=p_dscb1(pb);

            if pd1.f1_DS1RKP<>0 then
            if pd1.f1_DS1RKP<>0 then;


            if (options and option_find_text)>0 then        //find text for only pds lrecl 80
            begin

               if (get_vtoc_dsorg(pd1)='PO') and          // is a pds dataset
                  (swap(pd1.f1_DS1LRECL)=80) then
               begin
                  recfm:=get_vtoc_recfm(pd1);
                  if (recfm='F') or (recfm='FB') then
                  begin
                     if is_dsn_filter(options,dsn_filter,p_dscb1(pb)) then
                     begin
                        all_dscbs[q]:=pd1^;
                        ebcdic_inplace(all_dscbs[q].dsn,44);
                        inc(q);
                     end;
                  end;
               end;
            end
            else
            begin
               if ((options and option_find_initial)>0) or
                  ((options and option_find_partial)>0) then      // find process?
               begin
                  if is_dsn_type(options,dsn_filter,p_dscb1(pb)) then
                  begin
                     if is_dsn_filter(options,dsn_filter,p_dscb1(pb)) then
                     begin
                        all_dscbs[q]:=pd1^;
                        ebcdic_inplace(all_dscbs[q].dsn,44);
                        inc(q);
                     end;
                  end;
               end
               else
               begin
                  all_dscbs[q]:=pd1^;
                  ebcdic_inplace(all_dscbs[q].dsn,44);
                  inc(q);
               end;
            end;
            dscb_count_zeros:=0;
         end;
         $f4:
         begin
            process_dscb4(pb);            // get vtoc end and others parms...
            vtoc_end:=volume.vtoc_end;
            all_dscbs[q]:=p_dscb1(pb)^;   // here dscb 4
            inc(q);
         end;
         $f5:
         begin
            dscb5:=p_dscb5(pb);           // dscb5 - nothing to do
            if dscb5^.f5_ex05[0].cc=0 then;
         end;
      end;
      if dscb_count_zeros>99              // two track zeros - no more dscb
      then break;

      if (hrec.cyl=vtoc_end.cyl) and
         (hrec.head=vtoc_end.trk) and
         (hrec.rec=vtoc_end.rec) then
      begin
         break;
      end;

      hrec:=get_next_header(pb,hrec.klen+hrec.dlen);

      if hrec.cyl=$FFFF then
      begin
         inc(ckd.trk);

         if ckd.trk=hercules_dasd_header.dev_head then   // vtoc has only one extent ...
         begin
            inc(ckd.cyl);            // should not occurs
            ckd.trk:=0;
         end;
         ckd.nrec:=1;
         pb:=read_one_track(-1,@ckd,false);
         if pb=nil
         then break;
         hrec:=get_next_header(pb,0);
      end;
   end;
   SetLength(all_dscbs,q);
   Result:=q;
end;




// set next track
// may be in next extent

function TDM.set_next_track(fileno:integer;ckd:p_ckd):boolean;
var exts:p_resume;
begin
   Result:=false;
   if fileno>=0 then
   begin
      exts:=get_extent_sequence(fileno,ckd.cyl,ckd.trk);
      if exts=nil then exit;
      if (exts^.h_cyl=ckd.cyl) and  (exts^.h_trk=ckd.trk)  then  // last track in extent
      begin
         exts:=get_file_extents(fileno,exts.seqno+1);
         if exts=nil then exit;                          // exists?
         ckd.cyl:=exts.l_cyl;                          // ok - get new cyl/trk
         ckd.trk:=exts.l_trk;
         ckd.nrec:=1;
         Result:=true;
         exit;
      end;
   end;

   inc(ckd.trk);

   if ckd.trk<volume.trk_per_cyl then
   begin
      ckd.nrec:=1;
      result:=true;
   end
   else
   begin
      inc(ckd.cyl);
      ckd.trk:=0;
      ckd.nrec:=1;
      result:=true;
   end;
end;


function TDM.is_dataset_empty:boolean;
begin
   Result:=false;
   if (TK_F.FieldByName('last_tt').AsInteger=0) and
      (TK_F.FieldByName('last_r').AsInteger=0)
   then Result:=true;
end;





// mount text line based on options

procedure mount_one_text_line(ps:pbyte;options,lrecl,recnum,col_max,line_max:integer;ts:TStringList);
var s,opt1,opt2,h1,h2:string;
    i:integer;
begin
   opt1:='';
   opt2:='';

   if (options and option_show_rec)>0
   then opt1:=format('%.4d ',[recnum]);

   if (options and option_show_len)>0
   then opt2:=format('%.3d ',[lrecl]);

   s:=opt1+opt2+DM.ebcdic_ascii_ptr(ps,lrecl,col_max);
   ts.Add(s);

   if (options and option_show_hexa)=0    // show hexa??
   then exit;

   if lrecl>col_max
   then lrecl:=col_max;
   SetLength(h1,lrecl);
   SetLength(h2,lrecl);
   FillMemory(@h1[1],lrecl,32);
   FillMemory(@h2[1],lrecl,32);
   for i:=1 to lrecl do
   begin
      h1[i]:=hexa_tab[(ps^ shr 4)];
      h2[i]:=hexa_tab[(ps^ and 15)];
      inc(ps);
   end;
   SetLength(s,length(opt1)+length(opt2));
   if length(s)>0
   then FillChar(s[1],length(s),32);
   ts.Add(s+h1);
   ts.Add(s+h2);
   ts.Add('');
end;



// show data text
// options show lrecl,recnum,ckd...
//    fixed or var blk
//    need tk_f
// result tstringlist

function TDM.show_data_text(options,lines_max,col_max:integer):TStringList;
var i,recnum,recfmtype,fileno,sum_lrecl,reason,
    reclen,lrecl,bytes_read:integer;
    s,recfm:string;
    pb,ps:pbyte;
    no_more_data:boolean;
    hrec:rec_header;
    ckd:tckd;
    exts:p_resume;
    bdw:t_bdw;                // for variable block
    rdw:t_rdw;
begin

   Result:=TStringList.Create;
   recnum:=0;
   sum_lrecl:=0;
   pb:=nil;
   fileno:=TK_F.FieldByName('dscb').AsInteger;
   s:=TK_F.FieldByName('dsorg').AsString;
   if s='PO' then
   begin
      ckd.cyl:=TK_PDS.FieldByName('cyl').AsInteger;
      ckd.trk:=TK_PDS.FieldByName('trk').AsInteger;
      ckd.nrec:=TK_PDS.FieldByName('n').AsInteger;
      ckd.read:=0;
   end
   else
   begin
      exts:=get_file_extents(fileno,0);
      ckd.cyl:=exts.l_cyl;
      ckd.trk:=exts.l_trk;
      ckd.nrec:=1;
      ckd.read:=0;
   end;

   lrecl:=TK_F.FieldByName('lrecl').AsInteger;

   recfm:=TK_F.FieldByName('recfm').AsString;
   recfmtype:=recfm_F;                                // default recfm fixed
   if copy(recfm,1,2)='VBS'then recfmtype:=recfm_VBS else
   if copy(recfm,1,2)='VB' then recfmtype:=recfm_VB else
   if copy(recfm,1,1)='V'  then recfmtype:=recfm_V else
   if copy(recfm,1,1)='U'  then recfmtype:=recfm_U;


   pb:=read_one_track(fileno,@ckd,false);          // get data
   if pb=nil then exit;                            // track not found??
   hrec:=get_next_header(pb,0);
   reason:=1;
   if hrec.cyl=$ffff then                         // end of track
   begin
      Result.Add('<---------  first data track not found ---------->');
      exit;
   end;
   if hrec.dlen=0 then                             // nodata
   begin
      Result.Add('<---------  empty dataset ---------->');
      exit;
   end;

   while true do
   begin
      ps:=pb;                          // save pb for next record
      bytes_read:=ckd.read;
      no_more_data:=false;

      while (bytes_read>0) and (hrec.dlen>0) do    // process all track data
      begin
         if hrec.cyl=$ffff then break;

         if (options and option_show_trk)>0 then
         begin
            Result.Add('');
            s:=format('---------------  C %.4d  T %.2d  R %.2d KL %d DL %d   ------------',
            [hrec.cyl,hrec.head,hrec.rec,hrec.klen,hrec.dlen]);
            Result.Add(s);
            Result.Add('');
         end;

         reclen:=hrec.dlen;
         if recfmtype in [recfm_U,recfm_F] then
         begin
            if recfmtype=recfm_U             // undefinied lrecl = datalen
            then lrecl:=hrec.dlen;

            i:=reclen div lrecl;
            while i>0 do
            begin
               inc(recnum);
               if recnum>=lines_max then break;
               mount_one_text_line(ps,options,lrecl,recnum,col_max,lines_max,Result);
               inc(ps,lrecl);
               inc(sum_lrecl,lrecl);
               dec(i);
           end;
         end
         else
         begin
            move(ps^,bdw,sizeof(t_bdw));      // record formar V  block = BDW --> record RDW
            bdw.blocklen:=swap(bdw.blocklen);
            bdw.may31bit:=swap(bdw.may31bit);
            if (bdw.may31bit and $8000) >0 then
            begin
               ShowMessage('erro 1233 - VB 31 bits block - to do');
               exit;
            end;

            if bdw.blocklen=0 then
            begin
               no_more_data:=true;
               break;
            end;

            reclen:=bdw.blocklen;            // for next ckd rec
            dec(bdw.blocklen,4);
            inc(ps,4);
            while true do                    // loop for all var rec len
            begin
               move(ps^,rdw,sizeof(t_rdw));
               rdw.reclen:=swap(rdw.reclen)-4;
               inc(recnum);
               inc(ps,4);
               if recnum>=lines_max then break;
               mount_one_text_line(ps,options,rdw.reclen,recnum,col_max,lines_max,Result);

               dec(bdw.blocklen,rdw.reclen+4);
               if bdw.blocklen<=4 then               // until block len < 4
               begin
                  //no_more_data:=true;
                  break;
               end;
               inc(sum_lrecl,reclen);
               inc(ps,rdw.reclen);
            end;
         end;
         dec(bytes_read,reclen);
         hrec:=get_next_header(pb,hrec.dlen+hrec.klen);
         ps:=pb;
      end;

      reason:=2;
      if no_more_data
      then break;

      reason:=3;
      if recnum>=lines_max
      then break;

      reason:=2;
      if hrec.dlen=0                               // EOF
      then break;
                                                   //  next rec in track

      if set_next_track(fileno,@ckd)=false then    // set next track
      begin
         Result.Add('------- end of extents ');
         break;
      end;

      pb:=read_one_track(fileno,@ckd,false);       // get data
      reason:=4;
      if pb=nil then break;                        // track not found??
      hrec:=get_next_header(pb,0);                 // first header....
      reason:=1;
      if hrec.cyl=$ffff
      then break;                                     // end of track
      reason:=2;
      if hrec.dlen=0
      then break;                                    // end of track data
   end;
   if (options and option_show_len)>0
   then Result.Add(format('sum lrecl  %.4d ',[sum_lrecl]));

   case reason of
   1:Result.Add('<---------  end of track ---------->');
   2:Result.Add('<---------  end of data     ---------->');
   3:Result.Add('<---------  max lines found ---------->');
   4:Result.Add('<---------  track data not found ---------->');
   end;
end;




// string with dataset extents
// tk_f needed

function TDM.dataset_extents:string;
var s,unit_size:string;
    fileno,extno,tracks,alloc:integer;
    exts:p_resume;
begin
   s:='             Extents'+#10+#10;
   extno:=0;
   fileno:=TK_F.FieldByName('dscb').AsInteger;
   while true do
   begin
      exts:=get_file_extents(fileno,extno);
      if exts=nil then break;
      tracks:=((exts.h_cyl * volume.trk_per_cyl) + exts.h_trk) -
              ((exts.l_cyl * volume.trk_per_cyl) + exts.l_trk)+1;
      if extno<33 then
      s:=s+  format('%.2d   Cyl  trk     %.4d/%.4d    -    %.2d/%.2d     --> tks %d'+#10,
      [extno+1,
      exts.l_cyl,
      exts.h_cyl,
      exts.l_trk,
      exts.h_trk,tracks]);
      inc(extno);
   end;
   alloc:=(TK_F.FieldByName('trks').AsInteger*volume.trk_size div 1024);
   unit_size:='K';
   if alloc>1024 then
   begin
      alloc:=alloc div 1024;
      unit_size:='M';
   end;
   s:=s+#10+format('Last TTR  %d %d'+#10+#10,
         [TK_F.FieldByName('last_tt').AsInteger,TK_F.FieldByName('last_r').AsInteger]);
   s:=s+#10+format('Total trk %d'+#10+' Alloc  = %d %s'+#10,
      [TK_F.FieldByName('trks').AsInteger,alloc,unit_size]);
   if extno>30
   then s:=s+#10+' show only first 30 extents';
   Result:=s;
end;



procedure TDM.close_file;
begin
   if fn_opened
   then FileClose(iFileHandle);

   fn_opened:=false;
   volume.fn:='';
end;







// calc cyl trk from member ttr
// maybe in next extent...
//  output ckd and boolean
function po_calc_cyl_trk_from_ttr(ttr:word;fileno:integer;ckd:p_ckd):boolean;
var i,trk_in_ext,cyl_plus:integer;
    exts:p_resume;
    no_heads:word;
begin
   Result:=false;
   no_heads:=DM.volume.trk_per_cyl;
   for i:=0 to DM.volume.ix_extent do
   begin
      exts:=DM.get_file_extents(fileno,i);
      if exts=nil
      then break;

      ckd.cyl:=exts^.l_cyl;
      ckd.trk:=exts^.l_trk;
      ckd.nrec:=0;

      trk_in_ext:=(exts.h_cyl - exts.l_cyl) * no_heads + exts.h_trk - exts.l_trk +1 ; // ex cyl 36 trk 5 --> cyl 35 trk 5
      if ttr=trk_in_ext then
      if ttr=trk_in_ext then;



      if ttr<trk_in_ext then   // ttr in this  extent
      begin
         inc(ttr,exts.l_trk);
         cyl_plus:=ttr div no_heads;
         inc(ckd.cyl,cyl_plus);
         ckd.trk:=ttr mod no_heads;
         Result:=true;
         exit;
      end
      else
      begin                      // ttr in another extent
         dec(ttr,trk_in_ext);
         ckd.trk:=0;
         continue;
      end;
   end;
end;


// assume pds dir in first extent....
// result - first line number of pds member where text is found
//        - or -1 if not found

function search_for_member_text(pd1:p_dscb1;ttr:h_ttr;find_text:string;var line_text:string):integer;
var ckd:tckd;
    pb,pend,savepb,p2:pbyte;
    hrec:rec_header;
    find_len,init_line,
    i,num_extent,count_line,count_row:integer;
    relative_track:word;
    ebcdic_to_find:array[0..80] of byte;
    found:boolean;
    s:string;

begin
   Result:=-1;
   DM.volume.ix_extent:=0;

   if pd1^.f1_extents=0 then exit;
   s:=trim(pd1.dsn);

   num_extent:=get_all_extents(0,pd1);
   if num_extent=0 then exit;

   relative_track:=swap(ttr.hh);

   if not po_calc_cyl_trk_from_ttr(relative_track,0,@ckd) then
   begin
      DM.Error_Show(12,'xxx');
      exit;
   end;
   ckd.nrec:=ttr.r;
   find_len:=length(find_text);

   for i:=0 to find_len-1
   do ebcdic_to_find[i]:=ascii_to_ebcdic[ord(find_text[i+1])];

   count_line:=0;

   // read extent first track

   pb:=DM.read_one_track(0,@ckd,false);
   if pb=nil then exit;
   hrec:=DM.get_next_header(pb,0);
   savepb:=pb;


   while true do
   begin
      pend:=pb;
      inc(pend,hrec.dlen - length(find_text));

      while integer(pb)<integer(pend) do //hrec.dlen>0 do
      begin
         found:=CompareMem(pb,@ebcdic_to_find,find_len);
         if found then
         begin
            count_row:=integer(pb) - integer(savepb);
            count_line:=count_line  + (count_row div 80);
            init_line:=(count_row div 80)*80;
            if init_line=0 then;
            p2:=savepb;
            inc(p2,init_line);
            line_text:=DM.ebcdic_ascii_ptr(p2,80,80);
            Result:=count_line+1;
            Exit;
         end;
         inc(pb);
      end;

      pb:=savepb;
      count_line:=count_line + (hrec.dlen div 80);

      hrec:=DM.get_next_header(pb,hrec.klen+hrec.dlen);
      savepb:=pb;

      if hrec.dlen=0
      then break;

      if hrec.dlen=$ffff then                         // end of track
      begin
         if not DM.set_next_track(0,@ckd)
         then break;
         pb:=DM.read_one_track(0,@ckd,false);         // read next track
         if pb=nil then exit;                         // track not found??
         hrec:=DM.get_next_header(pb,0);
         if hrec.dlen=0 then exit;
         savepb:=pb;
      end;
   end;
   Result:=-1;
end;




procedure TDM.free_dir_list(pl:TList);
var i:integer;
    d:p_one_dir;
begin
   for i:=0 to pl.Count-1 do
   begin
      d:=pl[i];
      Dispose(d);
   end;
   pl.Free;
end;


// find dsname or pds member - read all volumes vtoc -
// if pds member - read directory too
// limited to find_max items


function  TDM.find_dataset_dsorg(options,find_max:integer;dsn_filter,member_filter,find_text:string;msg:TLabel):TStringList;
var
   fn,member_name,
   s,line_text,dsn,member_found:string;
   i,k,j,count,
   line_text_found:integer;
   ckd:tckd;
   pd1 : dscb_1;
   pdir:p_one_dir;
   one_extent:p_resume;
   pl:TList;
   ttr:h_TTR;


begin
   TK_F.Close;
   TK_PDS.Close;
   Result:=TStringList.Create;

   count:=0;

   member_found:='';
   close_file;

   for i:=0 to high(mvs_volumes) do
   begin
      fn:=mvs_volumes[i];

      volume.fn:='???';

      if not open_zos(0,fn)    // open and find only dsn filtered
      then continue;

      msg.Caption:=ExtractFileName(fn);
      msg.Update;


      if read_all_dscb(volume.vtoc_init,dsn_filter,options) =0
      then continue;

      volume.fn:=fn;
      for k:=0 to high(all_dscbs) do
      begin
         pd1:=all_dscbs[k];
         if pd1.idfmt<>241
         then continue;
         if pd1.f1_extents=0                                // should not occurs
         then  continue;

         // search for dsname


         dsn:=trim(pd1.dsn);
         if (options and option_find_dataset)>0 then
         begin
            Result.Add(volume.volid+'  '+dsn);
            inc(count);
            continue;
         end;

         msg.Caption:=volume.volid+' '+dsn;
         msg.Update;
         // search for text in pds

         SetLength(all_extents,128);                  // max 128 extent per dataset

         volume.ix_extent:=0;

         get_all_extents(0,@pd1);

         SetLength(all_extents,volume.ix_extent);

         one_extent:=get_file_extents(0,0);

         ckd.cyl:=one_extent.l_cyl;
         ckd.trk:=one_extent.l_trk;
         ckd.nrec:=1;


         dsn:=pd1.dsn;

         pl:=DM.read_all_pds_dir(@ckd,options,member_filter);
         if pl.Count=0 then
         begin
            free_dir_list(pl);
            continue;
         end;

         s:=volume.volid+'  '+dsn;

         for j:=0 to pl.Count-1 do              // member filtered so lets find text
         begin
            pdir:=pl[j];
            if (pdir.ind  and  PDS_ALIAS)>0 then
            if (pdir.ind  and  PDS_ALIAS)=PDS_ALIAS
            then continue;
            line_text_found:=search_for_member_text(@pd1,pdir.ttr,find_text,line_text);
            if line_text_found>0 then
            begin
               member_name:=ebcdic_ascii_ptr(pbyte(@pdir.name),8,8);
               ttr:=pdir.ttr;
               ttr.hh:=swap(ttr.hh);
               s:=format('%s %-30s (%-8s) --> text found line %d     ttr(%d %d)\',
                        [volume.volid,dsn,member_name,line_text_found,ttr.hh,ttr.r]);
               Result.Add(s);
               Result.Add(line_text);
               Result.Add('');
               inc(count);
               if count>=find_max then break;
            end;
         end;

         free_dir_list(pl);
         if count>=find_max then break;
      end;
   close_file;
   if count>=find_max then break;
   end;
end;

function TDM.has_extent:boolean;
var fileno:integer;
    pd1:p_dscb1;
begin
   Result:=false;
   if not TK_F.Active then exit;
   if high(all_dscbs)=-1 then exit;

   fileno:=TK_F.Fields[0].AsInteger;

   pd1:=@all_dscbs[fileno];
   Result:=pd1^.f1_extents>0;
end;

// sort extents
function extent_compare(p1, p2: Pointer): Integer;       // list sort
begin
   if p_resume(p1).l_cyl=p_resume(p2).l_cyl then             // same cyl - see track
   begin
      if p_resume(p1).l_trk=p_resume(p2).l_trk then Result:=0 else
      if p_resume(p1).l_trk>p_resume(p2).l_trk then Result:=1 else
      Result:=-1;
   end
   else
   begin
      if p_resume(p1).l_cyl>p_resume(p2).l_cyl then Result:=1 else
      Result:=-1;
   end;
end;


// mount a list with all extents - sort by cyl/trk
procedure TDM.show_volume_allocation;
var i,tot_free,init_trk,end_trk,num_trk:integer;
    ts:TStringList;
    s,fn:string;
    pext:p_resume;
    last_extent:p_resume;
    lext:TList;
begin

   tot_free:=0;
   ts:=TStringList.Create;
   s:='l_cyl l_trk h_cyl h_trk dsn';
   ts.Add(s);

   lext:=TList.Create;                       // list of extents
   lext.Capacity:=high(all_extents)+1;       // help performance
   for i:=0 to high(all_extents) do
   begin
      lext.Add(@all_extents[i]);
   end;
   lext.Sort(@extent_compare);
   last_extent:=lext.Items[0];

   for i:=0 to lext.Count-1 do
   begin
      pext:=lext.Items[i];
      if i>0 then
      begin
         if pext^.l_cyl>(last_extent^.h_cyl+1) then
         begin
            s:=format('%d  free from cyl=%d to %d  q=%d ',
             [i,last_extent.h_cyl+1,pext.l_cyl-1,
             (pext.l_cyl-last_extent.h_cyl)-1]);
             inc(tot_free,(pext.l_cyl-last_extent.h_cyl)-1);
            ts.add(s);
            ts.Add('');
         end;

         init_trk:=(pext.l_cyl * volume.trk_per_cyl)+pext.l_trk;
         end_trk :=(last_extent.h_cyl * volume.trk_per_cyl)+last_extent.h_trk;
         num_trk:=init_trk - end_trk-1;
         if (num_trk>1) then
         begin
            s:=format('-------->   %d free tracks ',[num_trk]);
            ts.add(s);
         end;
      end;

      if not TK_F.Locate('dscb',pext^.filenum,[])
      then break;

      fn:=TK_F.FieldByName('name').AsString;
      s:=format('%.5d %.5d %.5d %.5d %s',
      [pext.l_cyl,pext.l_trk,
      pext.h_cyl,pext.h_trk,fn]);
      ts.Add(s);
      last_extent:=pext;
   end;

   if (last_extent.h_cyl+1<volume.num_cyl) then
   begin
      s:=format('free from cyl=%d to %d  q=%d ',

      [last_extent.h_cyl+1,volume.num_cyl,(volume.num_cyl - last_extent.h_cyl)-1]);

      inc(tot_free,(volume.num_cyl - last_extent.h_cyl)-1);
      ts.add(s);
   end;
   s:=format('total %d free cyl',[tot_free]);
   ts.Add(s);
   s:=temp_folder+volume.volid+'_alloc.txt';
   ts.SaveToFile(s);
   ts.Free;
   lext.Free;
   ShellExecute(0,'OPEN',pchar(s),#0,pchar(temp_folder),SHOW_FULLSCREEN);
end;



// given a volid return filename
function  TDM.get_volume_fname(vol:string):string;
var i:integer;
begin
   Result:='';
   for i:=0 to high(mvs_volumes) do
   begin
      if pos(vol,mvs_volumes[i])>0 then
      begin
         Result:=mvs_volumes[i];
         break;
      end;
   end;
end;


// calc space used
// for  (recfm='U') and not alias

function TDM.calculate_space_used(ckd:tckd):integer;
var len:integer;
    pb:pbyte;
    hrec:rec_header;
begin
   Result:=0;
   pb:=DM.read_one_track(-1,@ckd,true);            // get data
   if pb=nil then exit;                         // track not found??
   hrec:=get_next_header(pb,0);
   while true do
   begin
      if hrec.cyl=$ffff then                    // end track?
      begin
         set_next_track(-1,@ckd);
         pb:=DM.read_one_track(-1,@ckd,true);      // get next data
         if pb=nil then exit;                   // track not found??
         hrec:=get_next_header(pb,0);
      end;

      len:=hrec.dlen;
      if len=0 then break;                      // EOF
      inc(Result,len);
      hrec:=get_next_header(pb,hrec.klen+hrec.dlen);
   end;

end;



// list of all pds dir - needed for read another track

function TDM.read_all_pds_dir(ckd:p_ckd;options:integer;name_filter:string):TList;
var ptr_all_dir:p_dasd_pdsdir;
    pdir:p_one_dir;
    lendir,offset_dir:word;
    pds_user:word;
    pb:pbyte;
    hrec:rec_header;
    last_dir,no_more_data:boolean;
    member_name:string;
    new_dir:p_one_dir;
    pl:TList;

begin
   Result:=nil;
   pb:=read_one_track(-1,ckd,false);                  // read pds dir
   if pb=nil then exit;
   hrec:=get_next_header(pb,0);
   no_more_data:=false;
   pl:=TList.Create;
   while true do
   begin
      if (hrec.klen<>8) and (hrec.dlen<>256)          // not a pds dir
      then break;

      ptr_all_dir:=p_dasd_pdsdir(pb);                 // all dir struct

      if ptr_all_dir^.dirlen=0 then                   // no pds dir data
      begin
         break;
      end;
      last_dir:=ptr_all_dir.key_name[0]=chr($ff);
      lendir:=swap(ptr_all_dir^.dirlen)-2;            // dec dirlen from total length

      pdir:=@ptr_all_dir.one_dir;
      while lendir>0 do
      begin
         if pdir^.name[0]=#255   then                  // last dir entry?
         begin
            no_more_data:=true;
            break;
         end;

         pds_user:=pdir.ind and  PDS2_LUSR;              // calc user data len
         offset_dir:=PDSDIR_LEN+pds_user*2;              // here so pb is dirty in text search

         if pdir^.name[0]=#0   then                      // deleted member??
         begin
            if offset_dir>lendir
            then break;

            dec(lendir,offset_dir);                      // dec processed data
            inc(pbyte(pdir),offset_dir);                 // --> next dir
            continue;
         end;
         member_name:=ebcdic_ascii_ptr(pbyte(@pdir.name),8,8);

         if (name_filter='') or (pos(name_filter,member_name)>0) then
         begin
            new(new_dir);
            move(pdir^,new_dir^,sizeof(t_pdsdir));                // name+ttr+ind+user*2
            pl.Add(new_dir);
         end;

         if offset_dir>lendir then
         if offset_dir>lendir 
         then break;

         dec(lendir,offset_dir);                         // dec processed data
         inc(pbyte(pdir),offset_dir);                    // --> next dir
      end;
      if no_more_data
      then break;
      if last_dir
      then break;
      hrec:=get_next_header(pb,hrec.klen+hrec.dlen);

      if (hrec.dlen=$FFFF) then
      begin
         if not set_next_track(-1,ckd)
         then break;

         pb:=read_one_track(-1,ckd,false);
         if pb=nil then break;

         hrec:=get_next_header(pb,0);
         if (hrec.klen<>8) and (hrec.dlen<>256)          // not a pds dir
         then break;
      end;
    end;
    Result:=pl;
end;





// save dataset in bin format
procedure TDM.save_binary(fn:string);
var pb:pbyte;
    hrec:rec_header;
    ckd:tckd;
    fileno:integer;
    s:string;
    ms:TMemoryStream;
begin


   fileno:=TK_F.FieldByName('dscb').AsInteger;
   s:=TK_F.FieldByName('dsorg').AsString;
   if s<>'PO' then
   begin
      ShowMessage('only for PDS MEMBER');
      exit;
   end;
   ckd.cyl:=TK_PDS.FieldByName('cyl').AsInteger;
   ckd.trk:=TK_PDS.FieldByName('trk').AsInteger;
   ckd.nrec:=TK_PDS.FieldByName('n').AsInteger;
   ckd.read:=0;
   ms:=TMemoryStream.Create;

   pb:=read_one_track(fileno,@ckd,false);          // get data
   if pb=nil then
   begin
      ShowMessage('error 1933 - track not found???');
      exit;
   end;

   hrec:=get_next_header(pb,0);
   while true do
   begin
      if (hrec.cyl=$ffff) or (hrec.dlen=0)
      then break;

      ms.Write(hrec.dlen,2);
      ms.Write(pb^,hrec.dlen);

      hrec:=get_next_header(pb,hrec.dlen+hrec.klen);
      if (hrec.cyl=$ffff) then
      begin
         if set_next_track(fileno,@ckd)=false
         then break;

         pb:=read_one_track(fileno,@ckd,false);
         if pb=nil then break;                        // track not found??
         hrec:=get_next_header(pb,0);                 // first header....
      end;
   end;

   ms.SaveToFile(fn);
   ShowMessage('save as binary --> '+fn);

   ms.Free;
end;

// get next header
function TDM.find_next_record(pb: pbyte; rec_required: byte;hrec: p_rec_header): integer;
var track_offset:integer;
begin
   track_offset:=0;
   move(pb^,hrec^,sizeof(rec_header));

   while true do
   begin
      hrec^.cyl:=swap(hrec.cyl);
      hrec.head:=swap(hrec.head);
      hrec.dlen:=swap(hrec.dlen);
      if rec_required=hrec.rec then break;
      if hrec.cyl=$ffff        then
      begin
         Result:=1;
         exit;
      end;
      inc(track_offset,hrec.klen+hrec.dlen+sizeof(rec_header));
      inc(pb,hrec.klen+hrec.dlen+sizeof(rec_header));
      move(pb^,hrec^,sizeof(rec_header));
   end;
   result:=track_offset;

end;

// save dataset data optional with ckd header
function TDM.save_raw_data(with_header:boolean;fn:string):boolean;
var ckd : tckd;
   trk_offset,fileno,seqno:integer;
   exts:p_resume;
   hrec : rec_header;
   pb,p2:pByte;
   fs:TFileStream;

begin
   Result:=false;
   fileno:=DM.TK_F.FieldByName('dscb').AsInteger;
   seqno:=0;
   exts:=DM.get_file_extents(fileno,seqno);
   if exts=nil then exit;


   ckd.cyl:=exts^.l_cyl;
   ckd.trk:=exts^.l_trk;
   ckd.nrec:=1;
   pb:=direct_read_cyl_trk(@ckd);       // dbs ver ha

   if pb=nil
   then exit;

   find_next_record(pb,ckd.nrec,@hrec);

   if hrec.cyl=$FFFF then             // ajust page records if not end of track
   begin
      ShowMessage('empty');
      exit;
   end;
   fs:=TFileStream.Create(fn,fmCreate);

   while true do
   begin


      trk_offset:=find_next_record(pb,ckd.nrec,@hrec);

      if trk_offset=-1 then break;

      if hrec.cyl=$FFFF then
      begin
         if DM.set_next_track(fileno,@ckd) then
         begin
            pb:=DM.direct_read_cyl_trk(@ckd);
            if pb=nil then break;
            trk_offset:=find_next_record(pb,ckd.nrec,@hrec);
         end;
         if hrec.cyl=$FFFF
         then break;
      end;

      if (hrec.klen=0) and (hrec.dlen=0)
      then break;

      if with_header
      then fs.Write(pb^,hrec.klen+hrec.dlen)
      else
      begin
         p2:=pb;                       // work pointer = pb + current offset
         inc(p2,trk_offset);
         inc(p2,sizeof(rec_header));    //+hrec.klen+hrec.dlen);
         fs.Write(p2^,hrec.klen+hrec.dlen); // zero len??
      end;
      inc(ckd.nrec);
      if trk_offset=0 then;
   end;
   fs.Free;
   Result:=true;
end;



//-rwxrwxrwx 1 dbs  dbs  8031269 Dec 23  2021  PSR730E.pdf
//-rwxrwxrwx 1 dbs  dbs     6984 Mar 14 16:54  securyhealt.reg
function TDM.format_file_date(dt:TDateTime):string;
var yy,mm,dd,hh,min,sec,msec:word;
begin
   if dt=0 then
   begin
      Result:='            ';
      exit;
   end;
   DecodeDate(dt,yy,mm,dd);
   DecodeTime(dt,hh,min,sec,msec);
   if yy=2025 then
   begin
      Result:= FormatDateTime('mmm dd hh:nn',dt);
      exit;
   end;
   Result:=    FormatDateTime('mmm dd  yyyy',dt);
end;

function TDM.dump_data(pb: pbyte; init, len: integer): string;
var i,count:integer;
    s:string;
begin

   if len>=100
   then len:=100;

   count:=0;
   for i:=init to len-1 do
   begin
      s:=s+IntToHex(pb^,2);
      inc(count);
      if count=4 then
      begin
         s:=s+' ';
         count:=0;
      end;
      inc(pb);
   end;
   Result:=s;
end;


// open dasd dataset
// fill volume information

function TDM.open_zos(options:integer;fn:string):boolean;
var pb:PByte;
    ckd:tckd;
    devid:string;
    is_compressed:boolean;
    sr:TSearchRec;
begin
   Result:=false;
   track_in_cache:=-1;
   if fn_opened
   then close_file;

   if FindFirst(fn,faArchive,sr)<>0 then
   begin
      Error_Show(101,'file not found -> '+fn);
      exit;
   end;
   volume.filesize:=cardinal(sr.Size) div 1024;
   FindClose(sr);



   try
     iFileHandle := FileOpen(fn,fmOpenRead+fmShareDenyNone);
   except
     Error_Show(102,'open file ');
     exit;
   end;

   FileRead(iFileHandle,hercules_dasd_header,sizeof(t_hercules_header));

   devid:=hercules_dasd_header.dev_id;

   if (copy(devid,1,4)<>'CKD_') then
   begin
      Error_Show(101,'not a CKD file -> '+fn);
      exit;
   end;

   is_compressed:=devid[5]='C';  // C=compressed P=only header+data

   if is_compressed then
   begin

      FileRead(iFileHandle,device_header,sizeof(t_hercules_device));

      if not (device_header.c_compress in [1,2]) then
      begin
         Error_Show(103,'invalid device header');
         exit;
      end;
      FileSeek(iFileHandle,$400,0);
      FileRead(iFileHandle,pl1,device_header.c_numl1tab*4);
   end;

   ckd.cyl:=0;
   ckd.trk:=0;
   ckd.nrec:=3;

   pb:=direct_read_cyl_trk(@ckd);               // read volume label
   if pb=nil then exit;
   inc(pb,sizeof(rec_header));


   move(pb^,volume_label,sizeof(vol_label));
   ebcdic_inplace(volume_label.volkey,4);
   ebcdic_inplace(volume_label.vollbl,4);
   ebcdic_inplace(volume_label.vol_id,6);
   ebcdic_inplace(volume_label.vtoc_owner,14);



   volume.trk_per_cyl:=hercules_dasd_header.dev_head;
   volume.trk_size   :=hercules_dasd_header.dev_trk_size;
   volume.num_cyl    :=3339; // guess - type 3390 max cyl
   volume.tracks_allocated:=0;
   volume.tracks_read:=0;

   volume.volid:=volume_label.vol_id;
   volume.vtoc_init.cyl:=swap(volume_label.vtoc_pointer.cyl);
   volume.vtoc_init.trk:=swap(volume_label.vtoc_pointer.trk);
   volume.vtoc_init.rec:=volume_label.vtoc_pointer.rec;
   volume.fn:=fn;
   if is_compressed then
   begin
      if device_header.c_compress=1
      then volume.compress:='zlib'
      else volume.compress:='bz2';
   end
   else
   begin
      volume.compress:='No';
   end;

   Result:=mount_table_dscb(options);

end;


// return pointer or null if rec not found in track
function position_on_cyl_trk_rec(pb:pbyte;ckd:p_ckd):pbyte;
var hrec:rec_header;
begin
   Result:=nil;
   hrec:=DM.get_next_header(pb,0);
   while hrec.rec<>ckd^.nrec do                    // search for record num
   begin
      if hrec.cyl=$ffff                            // at end of track?
      then exit;
      inc(pb,hrec.klen+hrec.dlen);
      hrec:=DM.get_next_header(pb,0);
   end;
   dec(pb,sizeof(rec_header));               // return pb to hrec
   Result:=pb;
end;




// read cyl track - decompress if needed
// return pointer to data (p_deco or p_trk)

function TDM.direct_read_cyl_trk(ckd:p_ckd): pointer;
var trk_256 : cardinal;
    pl2 : c_l2_tab;
    pack_trk_len : word;
    pos_read,file_size:int64;
    trk_to_read,deco_len:integer;
    compressed:boolean;
    pb:pbyte;
    trk_bin:byte;
    tm:TMemoryStream;
begin
   Result:=nil;
   file_size:=cardinal(volume.filesize)*1024;


   compressed:=(hercules_dasd_header.dev_id[5]= 'C');

   trk_to_read:=(ckd^.cyl * hercules_dasd_header.dev_head) + ckd^.trk;

   if trk_to_read=track_in_cache then
   begin
      if compressed then
      begin
         pb:=p_deco;
         ckd^.read:=track_in_cache_bytes;
         Result:=position_on_cyl_trk_rec(pb,ckd);
         exit;
      end;
      pb:=p_trk;
      inc(pb,sizeof(t_track_home_address));
      ckd^.read:=track_in_cache_bytes;
      Result:=position_on_cyl_trk_rec(pb,ckd);
      exit;
   end;
   inc(volume.tracks_read);

   if not compressed then           // disk image not compressed ...
   begin
      pos_read:=trk_to_read;
      pos_read:=pos_read * hercules_dasd_header.dev_trk_size;
      pos_read:=pos_read+sizeof(t_hercules_header);
      if pos_read>file_size then
      begin
         Error_Show(260,'seek > filesize  '+IntToStr(pos_read));
         Exit;

      end;

      //if FileSeek(iFileHandle,int64(pos_read),0)<>integer(pos_read) then
      if not file_seek(pos_read,iFileHandle) then
      begin
         Error_Show(260,'seek error at '+IntToStr(pos_read));
         Exit;
      end;
      ckd^.read:=FileRead(iFileHandle,p_trk^, hercules_dasd_header.dev_trk_size);
      track_in_cache:=trk_to_read;
      track_in_cache_bytes:=ckd^.read;

      pb:=p_trk;
      inc(pb,sizeof(t_track_home_address));
      Result:=position_on_cyl_trk_rec(pb,ckd);
      exit;
   end;

   // disk image compressed
   // read pl1 and pl2

   trk_256:=trk_to_read shr 8;
   pos_read:=pl1.ptr[trk_256];
   pos_read:=pos_read + longint((trk_to_read and 255)*sizeof(c_l2_tab));

   if FileSeek(iFileHandle,int64(pos_read),0)<>pos_read then               // seek pl2 table
   begin
      Error_Show(261,'seek_error');
      Exit;
   end;

   if FileRead(iFileHandle,pl2, sizeof(c_l2_tab))<>sizeof(c_l2_tab) then  // read pl2 table
   begin
      Error_Show(262,'read error');
      Exit;
   end;


   pos_read:=pl2.pos;
   pack_trk_len:=pl2.len;


   if pos_read=0 then                // track empty not a error....
   begin
      //Error_Show(263,'empty track');
      exit;
   end;
   if FileSeek(iFileHandle,int64(pos_read),0)<>integer(pos_read) then   // seek data pointed by pl2
   begin
      Error_Show(264,'seek error');
      Exit;
   end;

   if FileRead(iFileHandle,p_trk^, pack_trk_len)<>pack_trk_len then     // read seekdata pointed by pl2
   begin
      Error_Show(265,'read error');
      Exit;
   end;
   track_in_cache:=trk_to_read;

   pb:=p_trk;
   trk_bin:=pb^;                    // save HA bin

   dec(pack_trk_len,5);

   inc(pb,5);                       // skip HA

   case trk_bin of
      0:                            // not a compressed trk
      begin
         ckd^.read:=pack_trk_len;   // result in pb
         track_in_cache_bytes:=ckd^.read;
      end;
      1:                            // zlib
      begin
         deco_len:=65535;

         DecompressBuf(pb,integer(pack_trk_len),deco_len,pointer(p_deco),deco_len);

         ckd^.read:=deco_len;
         track_in_cache_bytes:=ckd^.read;
         pb:=p_deco;
      end;
      2:                            // bzlib
      begin
         deco_len:=hercules_dasd_header.dev_trk_size;
         tm:=UnCompressBzMem(pchar(pb),pack_trk_len,deco_len);
         if (tm=nil) or (tm.size=0) or (deco_len=0) then
         begin
            Error_Show(266,'decompress zero length');
            exit;
         end;
         tm.Seek(0,0);
         tm.Read(p_deco^,deco_len);
         tm.Free;
         ckd^.read:=deco_len;
         track_in_cache_bytes:=ckd^.read;
         pb:=p_deco;
      end;
      else
      begin
         Error_Show(266,'unknow compress type');
         Exit;
      end;
   end;
   Result:=position_on_cyl_trk_rec(pb,ckd);
end;


procedure TDM.DataModuleDestroy(Sender: TObject);
begin
   FreeMem(p_trk);
   FreeMem(p_deco);
end;


function TDM.mount_table_dscb(options:integer):boolean;
var i,numfile:integer;
    pd1:p_dscb1;
begin
   Result:=false;
   QueryPerformanceCounter(t1);

   TK_F.Close;
   TK_F.Open;

   // VTOC - 2 pass


   volume.total_members_pds80:=0;

   fn_opened:=true;

   if (options and option_only_open)>0 then  // option to only read dscb
   begin
      Result:=true;
      exit;
   end;

   // pass 1 read all dscb in memory


   volume.num_dscbs:=read_all_dscb(volume.vtoc_init,'',options);
   if volume.num_dscbs=0 then
   begin
      Error_Show(103,'');
      exit;
   end;
   if volume.num_cyl=2226 then volume.model:='3390-2' else
   if volume.num_cyl=3339 then volume.model:='3390-3' else
   volume.model:='??????';



   // pas 2 process dscb1 - mount file table/extents

   numfile:=0;

   SetLength(all_extents,2048);
   volume.ix_extent:=0;


   for i:=0 to volume.num_dscbs-1 do
   begin
      pd1:=@all_dscbs[i];
      if pd1^.idfmt=241 then
      begin
         process_dscb1(pd1,numfile,options);
         inc(numfile);
      end;
   end;

   SetLength(all_extents,volume.ix_extent);



   if TK_F.IndexName=''
   then set_table_index(TK_F,'dscb','i_dscb');

   QueryPerformanceCounter(t2);
   volume.ellapse_open:=(t2-t1) /hz;
   Result:=fn_opened;
end;

// original seek with error if offset>max_int --> use  64bit SetFilePointerex
function TDM.file_seek(seek_pos:int64;filehandle:thandle): boolean;
var highseek:int64;
begin
   if seek_pos>maxint
   then highseek:=seek_pos - maxint        //$7FFFFC01   $00 $FC $FF $FF $00 $00 $00 $00
   else highseek:=0;
   Result:=SetFilePointerex(filehandle,seek_pos,@highseek,FILE_BEGIN);
end;
end.

