unit DasdBR7_PDS;
{

   PDS Unit

   uPDS.pds_member_recs(@ckd,lrecl) and pds_linked_date(ckd:tckd;lrecl:integer)

   double read ???

}

interface

uses
  DasdBR7_DM,
  messages,dialogs,windows,stdctrls,
  SysUtils, Classes;

type
  TuPDS = class(TDataModule)
  private
    { Private declarations }
  public
    // save all pds members in a folder
    procedure pds_extract_folder;

    // calculate and save pds member record num
    procedure pds_set_number_of_recs(options:integer);

    // return pds members quantity
    function  pds_member_recs(ckd:p_ckd;lrecl:integer):integer;

    // mount table with pds members - return members count
    function  pds_member_count_mount(mount_table:boolean;options,fileno,extent_ix:integer):integer;

    // save a member pds data ina file
    function  pds_save_member(fd,fn:string;fileno:integer;ckd:tckd;dc,da:TDateTime):boolean;

    // test if a psd has members
    function  pds_has_member(fileno:integer):boolean;
  end;

var
  uPDS: TuPDS;

implementation

{$R *.dfm}


//-------------------internal funcions --------------------//

// input  pds ttr
// output ckd with cyl/trk ajusted
//   or false if ttr not found in extents

function po_calc_cyl_trk_from_ttr(ttr:word;fileno:integer;ckd:p_ckd):boolean;
var i,trk_in_ext,cyl_plus:integer;
    exts:p_resume;
    no_heads:word;
begin
   Result:=false;
   no_heads:=DM.volume_data.trk_per_cyl;
   for i:=0 to DM.volume_data.ix_extent do           // i know.. but less than 255 extents...
   begin
      exts:=DM.get_file_extents(fileno,i);
      if exts=nil
      then break;

      ckd.cyl:=exts^.l_cyl;
      ckd.trk:=exts^.l_trk;
      ckd.nrec:=0;

      trk_in_ext:=(exts.h_cyl - exts.l_cyl) * no_heads + exts.h_trk - exts.l_trk +1 ; // ex cyl 36 trk 5 --> cyl 35 trk 5

      if ttr<trk_in_ext then   // ttr in this  extent
      begin
         inc(ttr,exts.l_trk);
         cyl_plus:=ttr div no_heads;
         inc(ckd.cyl,cyl_plus);
         ckd.trk:=ttr mod no_heads;
         Result:=true;
         break;
      end;
      dec(ttr,trk_in_ext);       // ttr in another extent so dec ttr  extent trk

   end;
end;

// get linked date from module data - move to created date

function pds_linked_date(ckd:tckd;lrecl:integer):TDateTime;
var len:integer;
    pb:pbyte;
    dd,yy:word;
    hrec:rec_header;
    buf:array[0..128] of byte;
begin
   Result:=0;
   pb:=nil;
   pb:=DM.read_one_track(-1,@ckd,false);                    // get data
   if pb=nil then exit;                        // track not found??
   hrec:=DM.get_next_header(pb,0);

   while true do
   begin
      if hrec.cyl=$ffff then
      begin
         DM.set_next_track(-1,@ckd);
         pb:=DM.read_one_track(-1,@ckd,false);            // get data
         if pb=nil then exit;                        // track not found??
         hrec:=DM.get_next_header(pb,0);
      end;
      inc(ckd.nrec);                                   // next read...
      len:=hrec.dlen;
      if (len<18) or (len>22) or                  // must be 28 bytes len
         (pb^<>$80) then
      begin
         hrec:=DM.get_next_header(pb,hrec.klen+hrec.dlen);
         continue;
      end;
      if hrec.dlen=0
      then break;

      move(pb^,buf[0],18);
      if buf[0]=$80 then
      if buf[2]=4 then exit; // no linked data....

      if buf[0]=$80 then
      if buf[2]=2 then
      begin
         if len in [18,22] then // date and time -->len=18 then // only date
         begin
            // 0    1   2   3   4   5   6   7   8  9   10   1   2   3   4   5   6   7   8  9   20  21
            //$80 $15 $02 $F5 $F6 $F9 $F5 $D7 $D4 $C2 $F0 $F1 $40 $01 $10 $18 $14 $5F $01 $22 $22 $7F
            if buf[2]=2 then;
            yy:=(buf[15] shr 4) * 10;
            yy:=yy+ (buf[15] and 15);

            dd:=(buf[16] shr 4) * 100;
            dd:=dd+ (buf[16] and 15) * 10 ;
            dd:=dd+ (buf[17] shr 4);
            Result:=DM.Julian_date(yy,dd);
         end;
         break;
      end;
      hrec:=DM.get_next_header(pb,hrec.klen+hrec.dlen);
   end;
end;


// ibm unpack bytes
function unpack(bb:byte):word; begin  Result:=(bb shr 4) * 10 + (bb and $f) end;

// return tdatetime from ibm create/modified date
function get_datap(aa:array of byte):TDateTime;
var yy,dd : word;
begin
   yy:=unpack(aa[0]) * 100;
   yy:=yy+unpack(aa[1])+1900;
   dd:=unpack(aa[2]) * 10;
   dd:=dd + (aa[3] shr 4);
   Result:=DM.Julian_date(yy,dd);
end;



// mount TK_PDS table
function mount_po_table(dir:p_one_dir;options,fileno,pds_num:integer):boolean;
var k,pttr,current_num_lines,num_members,
    lrecl,memlen:integer;
    s,recfm,dsorg:string;
    ddata:TDateTime;
    user_data:p_pds_user_data;
    hour,minute,second:word;
    ckd:tckd;
    pds_user:word;
    is_alias:boolean;
begin
   Result:=false;

   if dir^.name[0]=#0
   then exit;

   s:=DM.ebcdic_ascii_ptr(pbyte(dir),8,8);
   s:=trim(s);

   lrecl:=DM.TK_F.FieldByName('lrecl').AsInteger;
   recfm:=DM.TK_F.FieldByName('recfm').AsString;
   dsorg:=DM.TK_F.FieldByName('dsorg').AsString;

   pttr:=swap(dir^.ttr.hh);                         // calc initial cyl,trn ,n
                                                    // from ttr

   is_alias:=(dir.ind  and  PDS_ALIAS)=PDS_ALIAS;

   if is_alias and ((options and option_show_alias)=0)
   then exit;

   if not po_calc_cyl_trk_from_ttr(pttr,fileno,@ckd) then
   begin
      DM.Error_Show(12,'');
      exit;
   end;
   ckd.nrec:=dir.ttr.r;
   DM.TK_PDS.Insert;
   DM.TK_PDS.FieldByName('cod').AsInteger:=pds_num;
   DM.TK_PDS.FieldByName('name').AsString:=s;
   DM.TK_PDS.FieldByName('ttr').AsInteger:=pttr;
   DM.TK_PDS.FieldByName('n').AsInteger:=dir.ttr.r;
   DM.TK_PDS.FieldByName('cyl').AsInteger:=ckd.cyl; // calc above
   DM.TK_PDS.FieldByName('trk').AsInteger:=ckd.trk;

   // alias
   if is_alias then
   begin
      DM.TK_PDS.FieldByName('alias').AsBoolean:=true;
      dir.ind:=(dir.ind- PDS_ALIAS);
   end;

   if (recfm='U') and (lrecl=0) then                  // try get compiled date
   if (options and option_po_linkeddate)>0 then
   begin
      ddata:=pds_linked_date(ckd,0);
      if ddata>0
      then DM.TK_PDS.FieldByName('created').AsDateTime:=ddata;
   end;
   current_num_lines:=0;
   if (recfm='U') and not is_alias then
   begin
      memlen:=DM.calculate_space_used(ckd);
      DM.TK_PDS.FieldByName('size').AsInteger:=memlen;
   end;

   // process user data

   if dir.ind>0 then
   begin
      user_data:=p_pds_user_data(@dir.udata);
      if user_data^.size>0 then;
      pds_user:=dir^.ind and  PDS2_LUSR;
      s:='';
      for k:=0 to (pds_user*2)-1 do
      begin
         s:=s+IntToHex(dir.udata[k],2);
         if (k>0) and ((k mod 4)=0)
         then s:=s+'-';
      end;

      DM.TK_PDS.FieldByName('extra').AsString:= s;


      if (pds_user=15) and (recfm<>'U') then
      begin
         DM.TK_PDS.FieldByName('vers').AsString:=format('%.2d.%.2d',[user_data.vers,user_data.level]);
         current_num_lines:=swap(user_data.size);
         DM.TK_PDS.FieldByName('size').AsInteger:=current_num_lines;
         ddata:=get_datap(user_data.created);
         DM.TK_PDS.FieldByName('created').AsDateTime:=ddata;
         ddata:=get_datap(user_data.lastUsed);
         hour:=unpack(user_data.hour);
         minute:=unpack(user_data.minute);
         second:=unpack(user_data.seg);
         if (hour<24) and (minute<60) and (second<60)
         then ddata:=ddata+EncodeTime(hour,minute,second,0)
         else ddata:=ddata+EncodeTime(12,0,0,0);
         DM.TK_PDS.FieldByName('lastused').AsDateTime:=ddata;
         s:=DM.ebcdic_ascii_ptr(pbyte(@user_data.uid),8,8);
         DM.TK_PDS.FieldByName('userid').AsString:=trim(s);
      end;
   end;


   if (current_num_lines=0) and                          // user data do not have count
      ((options and option_po_size)>0) and               // so count from member data
      (dsorg='PO') and (lrecl=80) then
   begin
      ckd.cyl:=DM.TK_PDS.FieldByName('cyl').AsInteger;
      ckd.trk:=DM.TK_PDS.FieldByName('trk').AsInteger;
      ckd.nrec:=DM.TK_PDS.FieldByName('n').AsInteger;
      num_members:=UPds.pds_member_recs(@ckd,lrecl);
      DM.TK_PDS.FieldByName('size').Asinteger:=num_members;

   end;

   DM.TK_PDS.Post;
   Result:=true;
end;


// set file date/time on save pds members
procedure set_file_create_acessed_date(fn:string;createdate,acesseddate:TDateTime);
var created,acessed:FILETIME;
    h:cardinal;
    st:TSystemTime;
begin
   if createdate=0 then exit;
   if acesseddate=0
   then acesseddate:=createdate;
   DateTimeToSystemTime(createdate,st);
   st.wHour:=14;               // bypass gmt offset
   SystemTimeToFileTime(st,created);
   DateTimeToSystemTime(acesseddate,st);
   SystemTimeToFileTime(st,acessed);
   h:=CreateFile(pchar(fn),GENERIC_WRITE,FILE_SHARE_READ,nil,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL, 0);
   if h=INVALID_HANDLE_VALUE then exit;
   SetFileTime(h,@created,@acessed,@acessed);
   CloseHandle(h);
end;




//-------------------public functions --------------------//


function TuPDS.pds_member_recs(ckd: p_ckd; lrecl: integer): integer;
var hrec:rec_header;
    pb:pbyte;
begin
   Result:=0;

   while true do
   begin
      pb:=DM.read_one_track(-1,ckd,true); //dbs
      if pb=nil then break;
      hrec:=DM.get_next_header(pb,0);     // first header....
      if hrec.dlen=0 then break;
      if lrecl=0
      then Result:=Result+1
      else Result:=Result+(hrec.dlen div lrecl);
      inc(ckd.nrec);
   end;
end;





// mount table with pds members - return members count
function TuPDS.pds_member_count_mount(mount_table: boolean; options, fileno,
  extent_ix: integer): integer;
var i:integer;
    exts:p_resume;
    ckd:tckd;
    pl:TList;

begin

   Result:=0;

   exts:=DM.get_file_extents(fileno,0);
   if exts=nil then
   begin
      ShowMessage('error 378 - no extent found??');
      exit;
   end;

   ckd.cyl:=exts.l_cyl;
   ckd.trk:=exts.l_trk;
   ckd.nrec:=1;

   pl:=DM.read_all_pds_dir(@ckd,0,'');
   if pl.Count=0 then exit;

   if mount_table then                          // mount after read all dir - reason read linkeddate
   begin
      for i:=0 to pl.Count-1  do
      begin
         mount_po_table(pl[i],options,fileno,i+1);
      end;
   end;
   Result:=pl.Count;
   DM.free_dir_list(pl);
end;



procedure TuPDS.pds_set_number_of_recs(options: integer);
var fileno,first_extent,
    pds_recs,tot_pds_recs:integer;

begin
   DM.TK_F.First;
   tot_pds_recs:=0;
   while not DM.TK_F.Eof do
   begin
      if (DM.TK_F.FieldByName('dsorg').AsString='PO') then
      begin
         fileno:=DM.TK_F.FieldByName('dscb').AsInteger;
         if not DM.is_dataset_empty and
            pds_has_member(fileno) then
         begin
            first_extent:=DM.TK_F.FieldByName('first_extent').AsInteger;
            pds_recs:=pds_member_count_mount(false,options,fileno,first_extent);
            if pds_recs>0 then
            begin
               DM.TK_F.Edit;
               DM.TK_F.FieldByName('recs').AsInteger:=pds_recs;
               inc(tot_pds_recs,pds_recs);
               DM.TK_F.Post;
            end;
         end;
      end;
      DM.TK_F.Next;
   end;
   DM.volume_pds_rec:=tot_pds_recs;
end;


// save a member pds data in a file
function TuPDS.pds_save_member(fd,fn:string;fileno:integer;ckd:tckd;dc,da:TDateTime):boolean;
var ts:TStringList;
begin
   Result:=true;
   fd:=DM.temp_folder+DM.TK_F.FieldByName('name').AsString;
   if not DirectoryExists(fd)
   then ForceDirectories(fd);

   ts:=DM.show_data_text(0,maxint,maxint);

   fn:=fd+'\'+fn+'.txt';
   ts.SaveToFile(fn);
   ts.Free;

   if (dc=0) and (da=0) then exit;                    // no dates create acess
   set_file_create_acessed_date(fn,dc,da);
end;


// save all pds members in a folder
procedure TuPDS.pds_extract_folder;
var t1,t2,hz:int64;
    fd,fn:string;
    ckd:tckd;
    fileno:integer;
    da,dc:TDateTime;
begin

   QueryPerformanceFrequency(hz);
   QueryPerformanceCounter(t1);

   fileno:=DM.TK_F.FieldByName('dscb').AsInteger;
   fd:=DM.temp_folder+DM.TK_F.FieldByName('name').AsString;
   if not DirectoryExists(fd)
   then ForceDirectories(fd);
   DM.TK_PDS.DisableControls;

   DM.TK_PDS.First;
   while not DM.TK_PDS.Eof do
   begin
      ckd.cyl:=DM.TK_PDS.FieldByName('cyl').AsInteger;
      ckd.trk:=DM.TK_PDS.FieldByName('trk').AsInteger;
      ckd.nrec:=DM.TK_PDS.FieldByName('n').AsInteger;
      fn:=DM.TK_PDS.FieldByName('name').AsString;
      dc:=DM.TK_PDS.FieldByName('created').AsDateTime;
      da:=DM.TK_PDS.FieldByName('lastused').AsDateTime;

      // if member has no dates -->  use dataset dates
      if dc=0 then dc:=DM.TK_F.FieldByName('createdate').AsDateTime;
      if da=0 then da:=DM.TK_F.FieldByName('lastdate').AsDateTime;

      pds_save_member(fd,fn,fileno,ckd,dc,da);
      DM.TK_PDS.Next;
   end;

   DM.TK_PDS.EnableControls;
   QueryPerformanceCounter(t2);
   ShowMessage(format('saved -  %s '+#10+'time = %.3f',[fd,(t2-t1) / hz]));
end;

function TuPDS.pds_has_member(fileno:integer):boolean;
var exts:p_resume;
    ckd:tckd;
    pb:pbyte;
    hrec:rec_header;
    dasd_po_dir:p_dasd_pdsdir;
begin
   Result:=false;
   exts:=DM.get_file_extents(fileno,0);            // read first po dir
   ckd.cyl:=exts.l_cyl;
   ckd.trk:=exts.l_trk;
   ckd.nrec:=1;
   pb:=DM.read_one_track(-1,@ckd,false);
   if pb=nil then exit;
   hrec:=DM.get_next_header(pb,0);
   if hrec.cyl=$ffff
   then exit;
   if hrec.dlen<>256
   then exit;

   dasd_po_dir:=p_dasd_pdsdir(pb);
   if dasd_po_dir^.one_dir.name[0]=#255
   then exit;

   Result:=true;
end;


end.


