
unit DasdBR7_HFSV2;
{


alguns erros 612 ????


}

interface

uses
  DASDbr7_DM,shellapi,
  DateUtils,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Menus, ComCtrls, ExtCtrls, ImgList;


{ $ I dasd_zos.inc}
{$I hfsV2.inc}


type
  TF_HFS = class(TForm)
    MM: TMemo;
    Label1: TLabel;
    MainMenu1: TMainMenu;
    TV: TTreeView;
    Splitter1: TSplitter;
    ImageList1: TImageList;
    Timer1: TTimer;
    Options1: TMenuItem;
    SaveBinary1: TMenuItem;
    SaveAscii1: TMenuItem;
    ShowAscii1: TMenuItem;
    Autoopen1: TMenuItem;
    Quit1: TMenuItem;
    procedure FormActivate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure TVDblClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Quit1Click(Sender: TObject);
    procedure TVKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    hz,t1,t2:int64;
    tsb:TStringList;                   // sb ordered list (removed duplicates)
    pags:t_list_blocks;

//    block_list:t_list_blocks;
    page0    :t_hfs_page_zero;
    page1    :t_hfs_page1;
    env_type,max_inode:integer;        // environment type 1=hfs 2=pdse
    inode_data:array of t_inode_data;

    temp_folder,
    fn:string;

    show_igw,
    show_sb,
    show_parms:boolean;
    tm:TMemoryStream;



    function  get_page_matrix(only_first_page:boolean;pb:pbyte):boolean;
    function  disk_map(option:integer): Integer;

    procedure hfs_sb_map;
    procedure pdse_sb_map;

    procedure inode_sb_dir(inode:integer;tn:TTreeNode);
    procedure inode_show_data(option,inode:integer;fn:string);

    procedure sb_sort_entry();

    procedure inode_list_pad(pb:pbyte);
    procedure inode_list_page2;

    procedure dump_page0(MM: TMemo);
    procedure dump_page1(MM: TMemo);
    procedure dump_page2(MM: TMemo);
    function  get_page0():boolean;
    procedure get_page1();


  public
    stand_alone :boolean;
    { Public declarations }

  end;

var
  F_HFS: TF_HFS;

implementation


{$R *.dfm}


function Swap4(a:cardinal):cardinal; asm bswap eax end;


procedure TF_HFS.Timer1Timer(Sender: TObject);
var s:string;
begin
   Timer1.Enabled:=false;
   F_HFS.Caption:='HFS V3 '+ExtractFileName(fn);


   tm:=TMemoryStream.Create;

   tm.LoadFromFile(fn);
   if (tm=nil) or (tm.Size=0) then
   begin
      ShowMessage('error in save raw data');
      exit;
   end;


   //prepare_mount_point;

   if not get_page0()
   then exit;
   {
   if page0.qtd_superblock=1 then
   begin
      ShowMessage('This is a valid empty fs - canceled' );
      tm.Free;
      close();
      exit;
   end;
   }
   get_page1();
   //dump_page2(MM);


   s:=format('****  %s size=%d blocks=%d (%x) block0=%d',
      [ExtractFileName(fn),tm.size div 1024,page1.blkcount,page1.blkcount,page0.xblocks]);
   MM.Lines.Add(s);

   MM.Lines.BeginUpdate;
   sb_sort_entry;
   MM.Lines.EndUpdate;

   MM.Lines.BeginUpdate;
   if env_type=ENV_HFS  then
   begin
     hfs_sb_map();
     inode_sb_dir(3,nil);
   end
   else
   begin
      pdse_sb_map();
   end;

   MM.Lines.EndUpdate;
   tsb.Free;

end;




procedure TF_HFS.FormActivate(Sender: TObject);
begin
   QueryPerformanceFrequency(hz);
   QueryPerformanceCounter(t1);
   show_igw:=true;
   show_sb:=true;
   show_parms:=true;
   t2:=t1;
   max_inode:=0;
   FreeAndNil(tm);
   TV.Items.Clear;

   temp_folder:=GetEnvironmentVariable('TEMP')+'\';

   {
   fn:=HFS_FOLDER+'Z9USS1_HFS.WEB.dat';         //ok


   fn:=HFS_FOLDER+'Z9USS1_HFS.ADCD.HFS.dat';
   {
   fn:=HFS_FOLDER+'Z9USS1_HFS.USR.MAIL.dat';       // empty

   fn:=HFS_FOLDER+'Z9USS1_HFS.ADCDPL.ROOT.dat';

   fn:=HFS_FOLDER+'Z9USS1_HFS.U.DB8G.dat';         // empty



   fn:=HFS_FOLDER+'Z9USS1_HFS.ADCD.ETC.dat';
   }
   fn:=HFS_FOLDER+'Z9USS1_HFS.USERS.dat';
   {
   fn:=HFS_FOLDER+'Z9RES1_DBS.TEST.HFS.dat';
   fn:=HFS_FOLDER+'Z9RES1_DBS.WORK.HFS.dat';
   fn:=HFS_FOLDER+'Z9RES1_AUT310.HFS.dat';


   fn:=HFS_FOLDER+'Z9RES2_JVB500.HFS.dat';
   fn:=HFS_FOLDER+'Z9RES2_CSQ600.MQM.HFS.dat';
   fn:=HFS_FOLDER+'Z9RES2_JVA500.HFS.dat';
   fn:=HFS_FOLDER+'Z9RES2_HPJ200.HFS.dat';
   fn:=HFS_FOLDER+'Z9RES2_IEL360.HFS.dat';
   fn:=HFS_FOLDER+'Z9RES2_IGY340.HFS.dat';
   fn:=HFS_FOLDER+'Z9RES2_NET520.HFS.dat';



   {
   fn:=HFS_FOLDER+'Z9DB81_DSN810.SDESHFS.dat';

   fn:=HFS_FOLDER+'Z9DB81_DSN810.SDSNWORF.dat';

   fn:=HFS_FOLDER+'Z9DB81_DSN810.SDMBHFS.dat';
   fn:=HFS_FOLDER+'Z9DB81_DSN810.SJVAHFS.dat';
   fn:=HFS_FOLDER+'Z9DB81_DSN810.SERDB2.dat';      // empty
   fn:=HFS_FOLDER+'Z9DB81_DSN810.SRDB2TX.dat';
   fn:=HFS_FOLDER+'Z9DB81_DSN810.SDMBHFS.dat';
   fn:=HFS_FOLDER+'Z9DB81_DSN810.SDSNHFS.dat';
   fn:=HFS_FOLDER+'Z9DB81_DSN810.SDSNHF1.dat';

   fn:=HFS_FOLDER+'Z9DB81_DSN810.SJVAHFS.dat';
   }

  // fn:='G:\Temp\SYS1.AIEALNKE.dat';
   //fn:='G:\Temp\ZFS.ADCD.DEV.DATA.dat';
   fn:=HFS_FOLDER+'JAUSS1_HFS.USERS.dat';
   //fn:=HFS_FOLDER+'Z9USS1_HFS.ADCD.ETC.dat';
   if not stand_alone then
   begin
      show_igw:=false;
      show_sb:=false;
      show_parms:=false;
      fn:='H:\temp\HFS\'+DM.volume_data.volid+'_'+DM.TK_F.FieldByName('name').AsString+'.dat';

      if not FileExists(fn) then
      begin
         if not DM.save_raw_data(false,fn) then
         begin
            ShowMessage('file not loaded '+fn);
            exit;
         end;
      end;
   end;

   if not FileExists(fn) then
   begin
      ShowMessage('file not found '+fn);
      exit;
   end;
   Timer1.Enabled:=true;

   exit;

    dump_page0(MM);  // keep satisfied compiler
    dump_page1(MM);
    dump_page2(MM);
    disk_map(0);
    inode_list_page2;


end;





procedure TF_HFS.FormKeyDown(Sender: TObject; var Key: Word;   Shift: TShiftState);
begin
   if key=VK_ESCAPE then close; //ModalResult:=mrOK;

end;



//file type and permissions
// d for directory, - for regular file, l for symbolic link).
function get_file_permission(flags:cardinal;a1,a2,a3:byte):string;
var s:string;
begin
   s:='-----------';
   if a1 and 4 >0 then s[2]:='r';
   if a1 and 2 >0 then s[3]:='w';
   if a1 and 1 >0 then s[4]:='x';
   if a2 and 4 >0 then s[5]:='r';
   if a2 and 2 >0 then s[6]:='w';
   if a2 and 1 >0 then s[7]:='x';
   if a3 and 4 >0 then s[8]:='r';
   if a3 and 2 >0 then s[9]:='w';
   if a3 and 1 >0 then
   if flags and $04000000 > 0
   then s[10]:='t';                // stick bit

   if flags and $80 > 0
   then s[1]:='d'                 // is dir
   else s[10]:='x';
   Result:=s;
end;



function xget_parm_type(pad:p_hfs_AD_pad):integer;
var k:integer;
    padlen:word;
begin

   padlen:=swap(pad^.len);
   Result:=9;
   if padlen=232 then exit;
   Result:=12;
   if padlen=233 then exit;

   Result:=22;
   if (pad^.f1=$09c0) and      // multi blocks
      (pad^.f5=$0370)
   then exit;
   Result:=-1;
   

   for k:=0 to high(parm_type) do
   begin
      padlen:=swap(pad^.len);
      if parm_type[k].tip=9 then              // node x blocknum
      if (padlen=parm_type[k].len) then
      if pad.f1=swap(parm_type[k].f1) then
      begin
         Result:=k;
         exit;
      end;
//  (len:  0;f1:$c009;f2:$0370;f3:$0000;tip: 9;ofs:18), //13 FPMHFSPERF inode num +blocknum type 13
// blocks

      if pad^.f1=$09c0 then
      if pad^.f5=$0370 then
      begin
         if padlen=9 then;
         Result:=k;
         exit;
      end;


      if (padlen=parm_type[k].len) then
      if pad.f1=swap(parm_type[k].f1) then
      if pad.f2=swap(parm_type[k].f2) then
      if pad.f3=swap(parm_type[k].f3) then
      begin
         //if (padlen=parm_type[k].len) then;
         Result:=k;
         exit;
      end;
      if parm_type[k].tip=2 then              //variable
      if padlen=$e3 then
      if pad.f1=swap(parm_type[k].f1) then
      begin
         Result:=k;
         exit;
      end;
      if parm_type[k].tip=3 then              //symbolic link
      if pad.f1=swap(parm_type[k].f1) then
      if pad.f2=swap(parm_type[k].f2) then
      begin
         Result:=k;
         exit;
      end;
   end;
end;


{
function ebcdic_ascii_ptr(pb:pbyte;len,max:integer) :string;
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
 }





function get_list_file(folder,filter:string): TStringList;
var sr:TSearchRec;
    ok:integer;
    fn:string;
    ts:TStringList;
begin
   ts:=TStringList.Create;
   ok:=FindFirst(folder+filter,faArchive,sr);
   while ok=0 do
   begin
      fn:=folder+sr.Name;
      if sr.Name[1]='.' then
      begin
         ok:=FindNext(sr);
         continue;
      end;
      ts.Add(fn);
      ok:=FindNext(sr);
   end;
   FindClose(sr);
   Result:=ts;
end;

procedure TF_HFS.dump_page0(MM: TMemo);
var filter:string;
    ts:TStringList;
    i:integer;
    tm:TMemoryStream; //time =0,3
    s:string;

begin

   filter:='*.dat';
   ts:=get_list_file(HFS_FOLDER,filter);
   for i:=0 to ts.Count-1
   do MM.Lines.Add(format('%2d %s',[i+1,ts[i]]));

   for i:=0 to ts.Count-1 do
   begin

      tm:=TMemoryStream.Create;
      tm.LoadFromFile(ts[i]);

      move(tm.Memory^,page0,sizeof(t_hfs_page_zero));
      s:=format('%2d %s',[i+1,DM.dump_data(@page0,0,128)]);
      MM.Lines.Add(s);
      tm.Free;
   end;
   ts.Free;
   QueryPerformanceCounter(t2);
   MM.Lines.Add(format('t=%.4f',[(t2 -t1)/hz]));
end;


procedure TF_HFS.dump_page1(MM: TMemo);
var filter:string;
    ts:TStringList;
    tm:TMemoryStream;
    pb:pbyte;
    i:integer;
    s:string;

begin
   filter:='*.dat';
   ts:=get_list_file(HFS_FOLDER,filter);
   for i:=0 to ts.Count-1
   do MM.Lines.Add(format('%2d %s',[i+1,ts[i]]));

   for i:=0 to ts.Count-1 do
   begin
      tm:=TMemoryStream.Create;
      tm.LoadFromFile(ts[i]);
      pb:=tm.Memory;
      inc(pb,4096);
      s:=format('%2d %s',[i+1,DM.dump_data(pb,0,128)]);
      MM.Lines.Add(s);
      tm.Free;
   end;
   ts.Free;
   QueryPerformanceCounter(t2);
   MM.Lines.Add(format('t=%.4f',[(t2 -t1)/hz]));
end;


function has_inode_zero_in_page(pb:pbyte):boolean;
var AD_page:p_hfs_AD_header;
    group_qtd:byte;
    AD_groups:word;
    g:integer;
    padlen:word;
    inode:cardinal;
    pw:pbyte;

    pad:p_hfs_AD_pad;
    pigw:p_igwpfar;

begin
   Result:=false;
   AD_page:=p_hfs_AD_header(pb);
   inc(pb,HFS_FIRST_OFFSET);        // point first group

   if p_group(pb)^.g1 <> p_group(pb).g2 then
   begin
      ShowMessage('inital group not found');
      exit;
   end;
   AD_groups:=swap(AD_page.size);
   group_qtd:=p_group(pb)^.gq;
   if group_qtd=0 then exit;
   inc(pb,sizeof(t_group));
   while AD_groups>0 do
   begin
      if group_qtd=0 then break;
      for g:=0 to group_qtd-1 do
      begin
         pad:=p_hfs_AD_pad(pb);
         padlen:=swap(pad^.len);
         if padlen in [227,230,232,233] then
         begin
            pw:=pb;
            if padlen=227    then inc(pw,11) else    //point to IGWPFAR - verify!!!
            if padlen=233    then inc(pw,17) else    //
            if padlen=232    then inc(pw,16);        //point to IGWPFAR

            if padlen=230    then
            begin
               inode:=swap(pad.f2);
               if inode>0 then
               begin
                  Result:=true;
                  exit;
               end;
            end;

            pigw:=p_igwpfar(pw);
            inode:=swap4(pigw^.inode); // inode + 256 = original
            if inode=0 then
            begin
               Result:=true;
               exit;
            end;
         end;
         inc(pb,padlen);
      end;
      dec(AD_groups,group_qtd);
      if AD_groups=0
      then break;
      if p_group(pb)^.g1 <> p_group(pb).g2
      then exit;
      group_qtd:=p_group(pb)^.gq;
      inc(pb,sizeof(t_group));

   end;
end;

procedure TF_HFS.dump_page2(MM: TMemo);
var filter:string;
    ts:TStringList;
    tm:TMemoryStream;
    pb:pbyte;
    i:integer;
    s:string;

begin
   filter:='*.dat';
   ts:=get_list_file(HFS_FOLDER,filter);
   for i:=0 to ts.Count-1
   do MM.Lines.Add(format('%2d %s',[i+1,ts[i]]));

   for i:=0 to ts.Count-1 do
   begin
      tm:=TMemoryStream.Create;
      tm.LoadFromFile(ts[i]);
      pb:=tm.Memory;
      inc(pb,4096*2);
      s:=format('%2d %s',[i+1,DM.dump_data(pb,0,127)]);
      MM.Lines.Add(s);
      tm.Free;
   end;
   ts.Free;
   QueryPerformanceCounter(t2);
   MM.Lines.Add(format('t=%.4f',[(t2 -t1)/hz]));
end;




procedure TF_HFS.sb_sort_entry;
var i,k:integer;
    pb:pbyte;
    s:string;
    AD_page:p_hfs_AD_header;
    inode:cardinal;
    sb:cardinal;
    found_first_block:boolean;
begin
   QueryPerformanceCounter(t1);

   tsb:=TStringList.Create;
   tsb.Sorted:=true;
   tsb.Duplicates:=dupIgnore; // default;

   sb:=0;
   inode:=0;
   //first_two:=0;
   found_first_block:=false;

   for k:=0 to page0.qtd_superblock-1 do
   begin
      if page0.superblocks[k].sb=0
      then continue;
      sb:=page0.superblocks[k].sb;


      pb:=tm.Memory;
      inc(pb,sb*4096);
      AD_page:=p_hfs_AD_header(pb);

      if show_sb then
      begin
         s:=format('sb %d (%4x) min (%4X) max (%4x) ',[sb,sb,swap4(AD_page^.min),swap4(AD_page^.max)]);
         MM.Lines.Add(s);
         s:=format('%s',[DM.dump_data(pb,0,127)]);
         MM.Lines.Add(s);
      end;
      if AD_page^.max=$FFFFFFFF
      then AD_page^.max:=256*256;

      //if AD_page^.max<>$FFFFFFFF then
      begin
         inode :=swap4(AD_page^.max);
         found_first_block:=has_inode_zero_in_page(pb);
         if found_first_block then
         begin
            Label1.Caption:=('error 601 - not found first inode on page '+IntToStr(sb) );
            break;
         end;
      end;

   end;
   {
   if not found_first_block then
   begin
      ShowMessage('error 601 - not found first inode on page '+IntToStr );
      //exit;
   end;
   }
   if not found_first_block
   then sb:=2;


   tsb.AddObject(format('%8x',[inode]),TObject(sb));
   for k:=0 to page0.qtd_superblock-1 do
   begin
      if page0.superblocks[k].sb=0
      then continue;
      sb:=page0.superblocks[k].sb;
      pb:=tm.Memory;
      inc(pb,sb*4096);
      AD_page:=p_hfs_AD_header(pb);
      if AD_page^.max<>$FFFFFFFF then
      begin
         inode :=swap4(AD_page^.max);
         if inode>0 then
         tsb.AddObject(format('%8x',[inode]),TObject(sb));
      end;
   end;

  // if show_sb then
   begin
      //MM.Lines.BeginUpdate;
      for i:=0 to tsb.Count-1 do
      begin
         sb:=cardinal(tsb.Objects[i]);
         pb:=tm.Memory;
         inc(pb,sb*4096);
         AD_page:=p_hfs_AD_header(pb);

         if show_sb then
         begin
            if AD_page^.max<>$FFFFFFFF then
            begin
               inode :=swap4(AD_page^.max);
               s:=format('max(%4x)  min(%4x) sb =%4d (%4x) %4d (%4x) ',
               [swap4(AD_page.max),swap4(AD_page.min),sb,sb,inode,inode]);
               MM.Lines.Add(s);
            end;
         end;
      end;
      //MM.Lines.EndUpdate;
      QueryPerformanceCounter(t2);
      MM.Lines.Add(format('time sb sort t=%.4f',[(t2 -t1)/hz]));
   end;
end;




function TF_HFS.get_page0():boolean;
var pb:pbyte;
    i:integer;
begin
   Result:=false;
   pb:=tm.Memory;
   move(pb^,page0,sizeof(t_hfs_page_zero));

   if page0.c1=$F1E6F0E2 then                   // type SOW1
   begin
      ShowMessage('error 101 - type S0W1 not suported');
      exit;
   end;

   page0.xblocks:=swap4(page0.xblocks);


   for i:=0 to page0.qtd_superblock-1 do
   if page0.superblocks[i].sb<>0
   then page0.superblocks[i].sb:=(swap4(page0.superblocks[i].sb)-256);
   Result:=true;
end;


procedure TF_HFS.get_page1();
var pb:pbyte;
begin
   pb:=tm.Memory;
   inc(pb,4096);

   move(pb^,page1,sizeof(t_hfs_page1));

   if CompareMem(@page1.dsn[36],@FORMAT1_LITERAL,4)
   then env_type:=ENV_PDSE
   else env_type:=ENV_HFS;

   page1.blkcount:=swap4(cardinal(page1.blkcount));

   DM.ebcdic_inplace(page1.TWO,4);
   if page1.dsn[0]<>#0 then
   DM.ebcdic_inplace(page1.dsn,44);

   max_inode:=page1.blkcount * (HFS_PAGELEN div 512); // min 1 block 1 inode
end;






{
procedure TF_HFS.prepare_mount_point;
var  ts:TStringList;
     i:integer;
     s:string;
begin
   if not FileExists(HFS_FOLDER+'Mount_point.txt') then
   begin
      ShowMessage('mount point file config not found ');
      exit;
   end;
   ts:=TStringList.Create;
   ts.LoadFromFile(HFS_FOLDER+'Mount_point.txt');
   for i:=0 to ts.Count-1 do
   begin
      s:=ts[i];
      s:=trim(s);
      mount_point[i].name:=copy(s,1,pos(' ',s)-1);
      delete(s,1,pos('/',s));
      mount_point[i].mounted_at:=s;
      mounted_file:=i+1;
   end;
   //if mount_point[0].name='' then;
end;


function TF_HFS.get_mounted_point(fn: string): string;
var s,filename:string;
    i:integer;
begin
   Result:='';
   filename:=ExtractFileName(fn);

   delete(filename,1,pos('_',filename));
   s:=ExtractFileExt(fn);
   delete(filename,pos(s,filename),maxint);
   for i:=0 to high (mount_point) do
   begin
      if mount_point[i].name=filename then
      begin
         Result:=mount_point[i].mounted_at;
         exit;
      end;
   end;

end;
}




function TF_HFS.disk_map(option:integer): Integer;
var pb,p2,p3:pbyte;
    max_block,
    i,k:integer;
    s:string;
    block_num:cardinal;
    tag_NDB,
    tag_NDZ,
    tag:array[0..18] of char;
    p_pageAD:p_page_ND_blank;
begin
   Result:=page1.blkcount;
   max_block:=page1.blkcount;
   pb:=tm.Memory;
   inc(pb,HFS_PAGE0_TAG_OFFSET);       // tag position
   move(pb^,tag,19);              // tag ebcdic - subtag ='A' in pos 10...

   tag_NDB:=tag;
   tag_NDB[9]:=chr($d5);
   tag_NDB[10]:=chr($c4);
   tag_NDB[11]:=chr($40);

   tag_NDZ:=tag;
   tag_NDZ[9]:=chr($d5);
   tag_NDZ[10]:=chr($c4);
   tag_NDZ[11]:=chr(0);
   tag_NDZ[12]:=chr(0);
   tag_NDZ[13]:=chr(0);

   s:='blocks '+IntToHex(page0.qtd_superblock,2)+' --> ';

   for i:=0 to page0.qtd_superblock-1 do
   begin
      if page0.superblocks[i].sb=0
      then continue;
      block_num:=page0.superblocks[i].sb;
      s:=s+IntToHex(block_num,4)+' ';
   end;
   MM.Lines.Add(s);
   MM.Lines.Add('');
   //MM.Lines.BeginUpdate;
   k:=3;
   p2:=tm.Memory;
   inc(p2,k*4096);
   s:=format('ND page %4d (%4x) %s',[k,k,DM.dump_data(p2,0,52)]);
   MM.Lines.Add(s);
   inc(k);
   p2:=tm.Memory;
   inc(p2,k*4096);
   s:=format('ND page %4d (%4x) %s',[k,k,DM.dump_data(p2,0,52)]);
   MM.Lines.Add(s);


   for k:=2 to max_block do
   begin
      if (k*4096)>tm.Size then
      begin
         MM.Lines.Add('EOF');
         break;
      end;
      p2:=tm.Memory;
      inc(p2,k*4096);
      p_pageAD:=p_page_ND_blank(p2);
      if p_pageAD^.tag[0]=0 then;


      if option=1 then
      begin
         //p3:=p2;
         //inc(p3,2);
         //if CompareMem(p3,@tag_NDZ[0],6) then //ex ADCD01
         begin
            p3:=p2;
            inc(p3,11);
            if CompareMem(p3,@tag_NDZ[9],5) then
            begin
               s:=format('ND page %4d (%4x) %s',[k,k,DM.dump_data(p2,0,52)]);
               MM.Lines.Add(s);
            end;
         end;
         continue;
      end;

      if CompareMem(@p_pageAD^.tag[0],@tag_NDB[0],12) then
      begin
         s:=format('block NDB at page %4d (%4x)',[k,k]);
         MM.Lines.Add(s);
         continue;
      end;
      if p2^=255 then
      begin
         s:=format('******free******* %4d (%4x)',[k,k]);
         MM.Lines.Add(s);
         continue;
      end;
      p3:=p2;
      inc(p3);
      if (p2^=0) and (p3^=0) then
      begin
         s:=format('======empty====== %4d (%4x)',[k,k]);
         MM.Lines.Add(s);
         continue;
      end;

      s:=DM.ebcdic_ascii_ptr(p2,80,80);
      s:=format('block data   page %4d (%4x) %s' ,[k,k,s]);
      MM.Lines.Add(s);

   end;
   //MM.Lines.EndUpdate;
end;






procedure TF_HFS.TVDblClick(Sender: TObject);
var inode,option:integer;


begin
   if TV.Selected=nil then exit;
   if TV.Selected.Data=nil then exit;
   inode:=integer(TV.Selected.Data);
   if inode =-1 then TV.Selected:=TV.Selected.Parent;
   if inode =-2 then TV.Selected:=TV.TopItem.Parent;
   if inode<0 then exit;


   Screen.Cursor:=crHourGlass;
   MM.Lines.Clear;
   MM.Lines.BeginUpdate;
   if inode_data[inode].flags and HFS_FLAG_DIR>0
   then inode_sb_dir(inode,tv.Selected) else
   begin
      if SaveBinary1.Checked then option:=OPTION_SAVE_BINARY else
      if SaveAscii1.Checked  then option:=OPTION_SAVE_ASCII else
      if ShowAscii1.Checked  then option:=OPTION_SHOW_ASCII else option:=0;
      if Autoopen1.Checked then option:=option or OPTION_AUTO_OPEN;
      inode_show_data(option,inode,tv.Selected.Text);
   end;
   MM.Lines.EndUpdate;
   Screen.Cursor:=crDefault;
end;





function is_symbolic(pad:p_hfs_AD_pad):boolean;
var pb:pbyte;
begin
   Result:=false;
   pb:=pbyte(pad);
   inc(pb,swap(pad^.len));
   pad:=p_hfs_AD_pad(pb);
   if p_group(pb)^.g1 = p_group(pb).g2 then
   begin
      inc(pb,sizeof(t_group));
      pad:=p_hfs_AD_pad(pb);
   end;

   // ex 001AC009 00080000 00009005 00000000 01000000 00046182 8995
   if (pad.f1=swap($c009))  and  (pad.f5=swap($9005))
   then Result:=true;

   // ex 018C00F 00050000 00000100 00000008 61A28194 979385A2
   if (pad.f1=swap($c00f)) and  (pad.f2=swap($0005))
   then Result:=true;
end;










procedure TF_HFS.hfs_sb_map;         // inode page in map_page ex inode=3 page=4
var i,k,g,block,bytes_processed,high_inode,
    count_sym,count_dir,count_fil,file_len,first_block,dumplen,
    group_qtd,flags,igw_ofs,page_offset:integer;
    pb,pw,p2:PByte;
    s,n,f:string;

    AD_groups,
    inode,padlen:word;
    date_time:double;

    AD_page:p_hfs_AD_header;
    pad:p_hfs_AD_pad;
    pigw:p_igwpfar;
   // block_set:p_block_set;
begin
   QueryPerformanceCounter(t1);
   inode:=0;
   padlen:=0;
   high_inode:=0;
   flags:=HFS_FLAG_ACTIVE;
   file_len:=0;
   first_block:=0;
   igw_ofs:=0;
   page_offset:=0;
   //page_qtd:=0;
   date_time:=0;
   for i:=0 to tsb.Count-1 do
   begin
      block:=integer(tsb.Objects[i]);
      pb:=tm.Memory;
      inc(pb,block*4096);

      AD_page:=p_hfs_AD_header(pb);
      AD_groups:=swap(AD_page^.size);

      inc(pb,HFS_FIRST_OFFSET);        // point first group

      if p_group(pb)^.g1 <> p_group(pb).g2 then
      begin
         ShowMessage('inital group not found');
         exit;
      end;
      group_qtd:=p_group(pb)^.gq;
      if show_igw then
      begin
         MM.Lines.Add('');
         s:=format('************block %6x size %4d  *********',[block,AD_groups]);
         MM.Lines.Add(s);

         s:=format('group %4x  %d',[p_group(pb)^.g1,group_qtd]);
         MM.Lines.Add(s);

      end;

      inc(pb,sizeof(t_group));
      bytes_processed:=HFS_FIRST_OFFSET+sizeof(t_group);
      SetLength(inode_data,inode+1024);


      // loop all pad in groups
      while AD_groups>0 do
      begin
         if group_qtd=0 then break;


         for g:=0 to group_qtd-1 do
         begin
            pad:=p_hfs_AD_pad(pb);
            padlen:=swap(pad^.len);
            if padlen=0
            then break;

            if get_page_matrix(true,pb) then
            begin
               k:=high(pags.bnum);
               if k<0 then
               begin
                  ShowMessage('error 609 - not found blocks ');
                  exit;
               end;
               first_block:=pags.bnum[0];
               page_offset:=integer(pb)-integer(tm.Memory);
            end;



            if show_igw
            then inode_list_pad(pb);


            case padlen of
               80:
               begin
                  if swap4(p_parm_80(pad).flag)=1
                  then flags:=flags or HFS_FLAG_NEXT_INODE;
               end;
               227,230,232,233:
               begin
                  pw:=pb;
                  if padlen=227    then inc(pw,11) else    //point to IGWPFAR - verify!!!
                  if padlen=230    then inc(pw,14) else    //
                  if padlen=233    then inc(pw,17) else    //
                  if padlen=232    then inc(pw,16);        //point to IGWPFAR
                  pigw:=p_igwpfar(pw);
                  igw_ofs:=integer(pw)-integer(tm.Memory);
                  if igw_ofs>tm.Size then
                  if igw_ofs>tm.Size then;

                  inode:=swap(pigw^.inode); // inode + 256 = original


                  if padlen=230
                  then inode:=swap(pad.f2);


                  //if inode=8 then
                  //if inode=149 then;
                  //pigw^.time1;

                  p2:=@pigw^.laccess;
                  //p2:=@pigw^.time2;
                  //if p2^>0 then dec(p2);
                  //p2:=@pigw^.time2;
                  date_time:=DM.gmt_stck(p2);


                  if (padlen=227) and (inode=0) then
                  begin
                     inode:=3;
                     first_block:=3;
                     flags:=flags or HFS_FLAG_DIR;
                  end;

                  inc(pw,OFFSET_IFSP); // verify    dbs


                  if CompareMem(pw,@IFSP_EBCDIC,4) then
                  begin
                     if p_IFSP_data(pw).IFSP_FLAG and $80 >0
                     then flags:=flags or HFS_FLAG_DIR;
                  end;

                  file_len:=swap4(pigw^.len);

                  if inode=3                          // ajust file for inode 3
                  then file_len:=8192;
               end;
            end;


            if (inode>0) then             // inser inode data
            begin
               if inode>high(inode_data)
               then SetLength(inode_data,inode+1024);
               inode_data[inode].symb_offset:=0;

               if inode_data[inode].flags and HFS_FLAG_ACTIVE=0 then            // do not repeat
               begin
                  if is_symbolic(pad) then               // next parm is symbolic?
                  begin
                     flags:=flags or HFS_FLAG_SYMBOLIC;
                     pw:=pbyte(pad);
                     inc(pw,padlen);
                     if p_group(pw)^.g1 = p_group(pw).g2 // group ??
                     then inc(pw,sizeof(t_group));
                     inode_data[inode].symb_offset:=integer(pw)-integer(tm.Memory);
                  end;
                  inode_data[inode].page:=first_block;
                  inode_data[inode].flags:=flags;
                  inode_data[inode].igw:=igw_ofs;
                  inode_data[inode].len:=file_len;
                  inode_data[inode].page_offset:=page_offset;
                  if igw_ofs>tm.Size then
                  if igw_ofs>tm.Size then;


                  inode_data[inode].dt:=date_time;
                  if show_igw then
                  begin
                     s:=format('inode %6d (%6x) page %d (%4x)',
                     [inode,inode,first_block,first_block]);
                     MM.Lines.Add(s);
                  end;
               end;


               if high_inode<inode
               then high_inode:=inode;

               first_block:=0;                     // prepare to next inode data
               flags:=HFS_FLAG_ACTIVE;
               igw_ofs:=0;
               inode:=0;
               file_len:=0;
               date_time:=0;
               page_offset:=0;
            end;

            inc(pb,padlen);
            inc(bytes_processed,padlen);
            if bytes_processed>HFS_PAGELEN then    // housekeping
            begin
               ShowMessage('invalid bytes processed');
               //SetLength(inode_data,0);
               exit;
            end;
         end;
         dec(AD_groups,group_qtd);
         if AD_groups=0 then                       // group end??
         begin
            if padlen=g then;
            if block=group_qtd then;
            break;
         end;
         if p_group(pb)^.g1=0
         then break;


         if p_group(pb)^.g1 <> p_group(pb).g2 then
         begin
            ShowMessage('error 1234 invalid group ');
            if block=group_qtd then;
            if padlen=g then;
            //SetLength(inode_data,0);
            exit;
         end;
         group_qtd:=p_group(pb)^.gq;
         if show_igw then
         begin
            s:=format('group %4x  %d',[p_group(pb)^.g1,group_qtd]);
            MM.Lines.Add(s);
         end;

         inc(pb,sizeof(t_group));
         inc(bytes_processed, sizeof(t_group));
      end;

   end;

   SetLength(inode_data,high_inode+1); //dbs ???
   QueryPerformanceCounter(t2);

   s:=format('INODE DATA  -  high inode=%d (%x)  t=%.4f',[high_inode,high_inode,(t2-t1) / hz]);
end;









procedure TF_HFS.inode_sb_dir(inode: integer;tn:TTreeNode);
var pb,pw:pbyte;
    pc:PChar;
    page_num,
    i,k,g,entry_offset,count_entry,
    entry_len,
    entry_inode,
    entry_page,
    xND_offset:integer;
    group_size,pnd_qtd_dir:word;
    group_qtd,name_len,
    pnd_qtd_grp:byte;
    name_plus_symbolic,
    s,entry_dt,entry_name,entry_sym,
    entry_attr,oldname:string;
    //pointers
    pnd:p_page_ND_blank;
    phfs:p_hfs_dir_name;
    b:byte;
    w:word;
    dt:TDateTime;
    n:TTreeNode;
    ts_dir_name,
    ts_dir_data:TStringList;

begin
   QueryPerformanceCounter(t1);
   {
   if inode=0 then
   begin
      ShowMessage('warninge - page directory inode 0 - assume 3');
      inode:=3;
   end;
   }

   if inode_data[inode].page=0 then
   begin
      ShowMessage('error 501 - page directory not found');
      exit;
   end;
   if inode_data[inode].flags and HFS_FLAG_DIR=0 then
   begin
      ShowMessage('error 502 - not a directory');
      exit;
   end;



   if tn=nil then
   begin
      TV.Items.Clear;
      n:=TV.Items.AddChildObjectFirst(nil,trim(page1.dsn),TObject(inode_data[inode].page));
   end
   else
   begin
      n:=tn;
      tn.DeleteChildren;
   end;

   page_num:=inode_data[inode].page;
  // if (inode_data[inode].flags and HFS_FLAG_NEXT_INODE>0)
  // then inc(page_num);

   if inode=3 then                  // special - pag 3 -> pages 3,4 constant
   begin
      SetLength(pags.bnum,2);
      pags.bnum[0]:=3;
      pags.bnum[1]:=4;              // maybe next inode flags
   end
   else
   begin
      pb:=tm.Memory;
      inc(pb,inode_data[inode].page_offset);
      if not get_page_matrix(false,pb) then
      begin
         ShowMessage('error 501 - no pages pool found');
         exit;
      end;
   end;
   ts_dir_name:=TStringList.Create;
   ts_dir_name.Sorted:=true;
   //ts_dir_name.Duplicates:=dupAccept;
   ts_dir_data:=TStringList.Create;

   i:=0;
{
   process first page
   if HFS_FLAG_NEXT_INODE  take second page - and skip first
   else take first
}
   if (inode_data[inode].flags and HFS_FLAG_NEXT_INODE>0) then
   begin
      if high(pags.bnum)=0 then     // has enought pages?
      begin
         ShowMessage('error 504 - no second page foud');
         exit;
      end;
      pags.bnum[0]:=0;                       // skip first page
   end
   else
   begin
      pags.bnum[1]:=0;                       // skip second page
   end;


   while i<=high(pags.bnum) do
   begin
      page_num:=pags.bnum[i];
      inc(i);
      if page_num=0
      then continue;                         // eureka
//      MM.Lines.Add('process page '+IntToStr(page_num));


      pb:=tm.Memory;
      inc(pb,page_num*4096);
      pw:=pb;
      inc(pw,OFFSET_TAG_ND_AD);        // point to ND tag

      if not CompareMem(pw,@HFS_ND_TAG,2) then
      begin
         ShowMessage('error 505 - invalid ND page');
         exit;
      end;


      pnd:=p_page_ND_blank(pb);


      pnd_qtd_dir:=swap(pnd^.qtd_dirs);
      pnd_qtd_grp:=pnd^.qtd_groups;

      oldname:='';

      inc(pb,HFS_DIRNAME_TEMPLATE);       // b -> nd page
      if pb^<>0 then                      // oldname index
      begin
         while pb^<>255 do                // has repeat
         begin
            oldname:=oldname+ebcdic_to_ascii[pb^];
            inc(pb);
         end;
      end;

      //group_offset:=ND_offset+OFFSET_NDB_FIRST; // -> first group entry
      pb:=tm.Memory;
      inc(pb,page_num*4096);
      inc(pb,OFFSET_NDB_FIRST);

      count_entry:=0;

      for g:=0 to pnd_qtd_grp-1 do            // for allgroups
      begin
         entry_offset:=integer(pb)-integer(tm.Memory);
         group_qtd:=p_group_entry(pb).qtd;      // this group quantity
         inc(pb,sizeof(t_group_entry));

         while group_qtd>0 do
         begin
            phfs:=p_hfs_dir_name(pb);
            group_size:=swap(phfs^.size);

            if phfs^.const_c0<>HFS_CO then
            begin
               ShowMessage('error 506 - dir entry  not c0 constant');
               break;
            end;
            if phfs^.name_len=0 then
            begin
               dec(pnd_qtd_dir);
               inc (pb,group_size);
               dec (group_qtd);
               continue;
            end;

            //******** entry name************
            name_len:=($FF - phfs^.name_len);
            pw:=pb;
            inc(pw,HFS_NAME_OFFSET);
            entry_name:=DM.ebcdic_ascii_ptr(pw,(name_len-phfs^.name_repeat),(name_len-phfs^.name_repeat));
            if phfs^.name_repeat>0
            then entry_name:=copy(oldname,1,phfs^.name_repeat)+entry_name;
            oldname:=entry_name;

            //******** entry inode************
            inc(pw,name_len-phfs^.name_repeat);


            if p_hfs_post_name(pw)^.tipo=1
            then entry_inode:=swap4(p_hfs_post_name(pw)^.inode)
            else entry_inode:=swap4(p_hfs_post_name_27(pw)^.inode);

            if entry_inode>max_inode
            then break;

            if (inode_data[entry_inode].page_offset>tm.Size) or
               (inode_data[entry_inode].igw>tm.Size) or
               (inode_data[entry_inode].symb_offset>tm.Size) then
            begin
               s:=format('error 612 - invalid offset for %s inode %d',[entry_name,entry_inode]);
               MM.Lines.Add(s);
               dec(pnd_qtd_dir);
               inc (pb,group_size);
               dec (group_qtd);
               continue;
            end;





            if entry_inode=inode then
            if entry_inode=inode then;

            if p_hfs_post_name(pw)^.tipo=0 then
            begin
               MM.Lines.Add(format('skip hfs post type 0 %d %d ',[entry_inode,inode]));
               dec(pnd_qtd_dir);
               inc (pb,group_size);
               dec (group_qtd);
               continue;

            end;


            if (entry_inode=0) and (count_entry<3)
            then entry_inode:=inode;

            //if inode_data[entry_inode].flags and HFS_FLAG_NEXT_INODE>0
            //then inc(entry_inode);

            //*********** page & len ************
            entry_len:=0;
            entry_page:=0;

            if entry_inode>0 then
            begin
               entry_len:=inode_data[entry_inode].len;
               entry_page:=inode_data[entry_inode].page;
            end;
            if entry_inode=8 then
            if entry_inode=23 then;


            //*********** symbolic ************
            entry_sym:='';
            if inode_data[entry_inode].flags and HFS_FLAG_SYMBOLIC >0 then
            begin
               pw:=tm.Memory;
               inc(pw,inode_data[entry_inode].symb_offset);    // point to symb parm (see is_symbolic)

               if (p_symbolic1(pw)^.w[0]=swap($c009)) and
                  (p_symbolic1(pw)^.w[4]=swap($9005)) then
               begin
                  w:=swap(p_symbolic1(pw)^.lsym);
                  entry_sym:=DM.ebcdic_ascii_ptr(@p_symbolic1(pw).symb,w,w);
               end
               else
               if (p_symbolic2(pw)^.w[0]=swap($c00f)) and
                  (p_symbolic2(pw)^.w[1]=swap($0005)) then
               begin
                  w:=swap(p_symbolic2(pw)^.lsym);
                  entry_sym:=DM.ebcdic_ascii_ptr(@p_symbolic2(pw).symb,w,w);
               end
               else
               begin
                  s:=format('error 507 - symbolic not found inode %d %s',[entry_inode,entry_name]);

                  ShowMessage(s);
                  if pw^=0 then;
               end;
            end;

            //************ attribute ***********
            pw:=tm.Memory;
            inc(pw,inode_data[entry_inode].igw+OFFSET_IFSP);

            if CompareMem(pw,@IFSP_EBCDIC,4) then
            begin
               entry_attr:=get_file_permission(p_IFSP_data(pw).IFSP_FLAG,p_IFSP_data(pw).IFSP_OWNER,p_IFSP_data(pw).IFSP_GROUP,p_IFSP_data(pw).IFSP_OTHER);
            end;


            //*************date time
            entry_dt:=DM.format_file_date(inode_data[entry_inode].dt);


            inc(count_entry);

            if entry_sym<>'' then
            begin
               name_plus_symbolic:=entry_name+' -> '+entry_sym;
               entry_attr[1]:='l';
            end
            else
               name_plus_symbolic:=entry_name;

            s:=format('%4d %s  1 OMVSKERN SYS1    %8d %13s %-34s %4x  %4x ',
            [entry_inode,entry_attr,entry_len,entry_dt,name_plus_symbolic,entry_offset,entry_page]);

            if ts_dir_name.Find(entry_name,k) then
            if s=ts_dir_data[k] then;
            ts_dir_name.AddObject(entry_name,TObject(ts_dir_data.Add(s)));





            if count_entry=0 then;
            dec(pnd_qtd_dir);
            if pnd_qtd_dir=0 then;

            inc (pb,group_size);
            dec (group_qtd);
         end;
      end;
   end;

   //MM.Lines.BeginUpdate;
   for i:=0 to ts_dir_name.Count-1 do
   begin

      k:=integer(ts_dir_name.Objects[i]);
      s:=ts_dir_name[i];
      //if s='..' then continue;
      //if s='.'  then continue;
      if s=''  then continue;
      s:=ts_dir_data[k];
      MM.Lines.Add(s);
      s:=trim(s);
      delete(s,pos(' ',s),MaxInt);
      k:=StrToInt(s);


      with TV.Items.AddChildObject(n,ts_dir_name[i],TObject(k)) do
      begin

         if inode_data[k].flags and HFS_FLAG_SYMBOLIC >0
         then ImageIndex:=6  else
         if inode_data[k].flags and HFS_FLAG_DIR >0
         then ImageIndex:=1 else
         if inode_data[k].len=0
         then ImageIndex:=5 else
              ImageIndex:=3;

      end;
   end;
   //MM.Lines.EndUpdate;


   if (tn=nil)  then
   begin

      s:='inode increment ';
      for i:=0 to high(inode_data) do
      begin
         if inode_data[i].flags and HFS_FLAG_NEXT_INODE>0
         then s:=s+IntToStr(i)+' ';
      end;
      MM.Lines.Add(s);
      TV.FullExpand;
   end
   else n.Expanded:=true;

   QueryPerformanceCounter(t2);
   Label1.Caption:=format('t=%.4f   data page %d blocks=%d',[(t2 -t1)/hz,inode_data[inode].page,page1.blkcount]);

end;
{ ex   2 types:               f1   f2  f3   f4  f5
1A285E parm   134 (  86) 0086C00E 00700300 00000000 000B - 12 pages
 F8440 parm    39 (  27) 0027C009 00750000 00007003 00000000 000001 - 2 pages
}


function TF_HFS.get_page_matrix(only_first_page:boolean;pb:pbyte):boolean;
var pm:p_page_matrix;
    i,k,page,q:integer;
    block_qtd:word;
    pad:p_hfs_AD_pad;
    block_set:p_block_set;

begin
   Result:=false;
   SetLength(pags.bnum,0);

   q:=0;
   pad:=p_hfs_AD_pad(pb);       // get pad
   block_set:=nil;


   if (pad^.f1=swap($c00e)) and  (pad^.f2=swap($0070)) and (pad^.f3=swap($0300))        // type 3
   then block_set:=@p_blocks_type3(pb)^.qtd
   else
      if (pad^.f1=swap($c009)) and  (pad^.f5=swap($7003)) // type 1
      then block_set:=@p_blocks_type1(pb)^.qtd
      else
         if (swap(pad^.len)=1520) and (pad^.f1=swap($c012))  // type 2
         then block_set:=@p_blocks_type2(pb)^.qtd
         else
            if (swap(pad^.len)=40) and (pad^.f5=swap($0070)) and (pad^.f6=swap($0300))
            then block_set:=@p_blocks_type4(pb)^.qtd;


   if block_set=nil then exit;



   pm:=p_page_matrix(@block_set^.pages);
   if pm^.page=0 then exit;;
   page:=0;

   if only_first_page
   then SetLength(pags.bnum,1)
   else SetLength(pags.bnum,2048);

   block_qtd:=swap(block_set^.qt);

   for i:=0 to block_qtd-1 do
   begin
      page:=swap4(pm.page)-256;
      if page> max_inode
      then break;

      if pm^.q <> 255 then
      for k:=0 to pm.q do
      begin
         pags.bnum[q]:=page;
         if only_first_page then
         begin
            Result:=true;
            exit;
         end;

         inc(q);
         if q>high(pags.bnum) then
         begin
            ShowMessage('more than 1024 blocks ');
            if q>high(pags.bnum) then;
            Result:=true;
            exit;
         end;

         inc(page);
      end;
      inc(pm);
   end;
   if page> max_inode then
   begin
      ShowMessage('error 620 - invalid page in page set');
      SetLength(pags.bnum,0);
      exit;
   end;

   SetLength(pags.bnum,q);
   if q>0 then
   if pags.bnum[0]=0 then;

   if pad^.f1=0 then;
   if pb^=0 then;
   Result:=true;

end;


procedure TF_HFS.inode_show_data(option,inode:integer;fn:string);
var s,filenamesave:string;
    i,k,file_size,count_pages,index_buf,
    blocknum,lines:integer;
    pb:pbyte;
    ts:TStringList;
    buf:array[0..1023] of char;
    savestream:TFileStream;
begin
   QueryPerformanceCounter(t1);
   if inode_data[inode].flags and HFS_FLAG_SYMBOLIC>0 then
   begin
      Label1.Caption:='******** symbolic link y********';
      exit;
   end;



   file_size:=inode_data[inode].len;
   if file_size=0 then
   begin
      Label1.Caption:='********file empty********';
      exit;
   end;
   if inode_data[inode].page_offset>tm.Size then
   begin
      Label1.Caption:='********error 608 - INVALID DATA BLOCK ********';
      exit;
   end;
   s:='';
   lines:=0;
   count_pages:=0;

   pb:=tm.Memory;
   inc(pb,inode_data[inode].page_offset);

   get_page_matrix(false,pb);

   if high(pags.bnum)<0 then
   begin
      ShowMessage('error 608 - no data');
      exit;
   end;
   filenamesave:=temp_folder+fn;

   if option and OPTION_SAVE_BINARY>0 then
   begin
      savestream:=TFileStream.Create(filenamesave,fmCreate);
      for i:=0 to high(pags.bnum) do
      begin
         blocknum:=pags.bnum[i];
         pb:=tm.Memory;
         inc(pb,blocknum*4096);
         savestream.Write(pb^,4096);
      end;
      savestream.Free;
      QueryPerformanceCounter(t2);
      Label1.Caption:=(format('SAVED: %s  t=%.4f',[filenamesave,(t2 -t1)/hz]));
      if option and OPTION_AUTO_OPEN >0
      then ShellExecute(0,'OPEN',pchar(filenamesave),#0,nil,SHOW_FULLSCREEN);
      exit;
   end;

   if option and (OPTION_SAVE_ASCII+OPTION_SHOW_ASCII)>0 then
   begin
      if option and OPTION_SHOW_ASCII>0
      then MM.Lines.Clear;

      index_buf:=0;
      ts:=TStringList.Create;


      for i:=0 to high(pags.bnum) do
      begin
         blocknum:=pags.bnum[i];
         inc(count_pages);
         //blk:=blk+format('%4x',[blocknum]);
         //MM.Lines.Add(format('paage %5d (%6x)',[blocknum,blocknum]));
         pb:=tm.Memory;
         inc(pb,blocknum*4096);

         for k:=0 to 4095 do
         begin
            if file_size=0
            then break;

            if (pb^=$15) or (index_buf=1023) then
            begin
               if index_buf>0 then
               begin
                  SetLength(s,index_buf);
                  move(buf[0],s[1],index_buf);
                  ts.Add(s);
                  inc(lines);
               end;
               index_buf:=-1;          // will be inc +1
               if option and OPTION_SHOW_ASCII>0 then
               if lines>1999 then
               begin
                  ts.Add('***************** more than 2000 lines  ************');
                  file_size:=0;
                  break;
               end;
            end
            else
            begin
               buf[index_buf]:=ebcdic_to_ascii[pb^];
            end;
            dec(file_size);
            inc(pb);
            inc(index_buf);
         end;
         if file_size=0
         then break;


         if blocknum=-1
         then break
      end;
      if index_buf>0 then
      begin
         SetLength(s,index_buf);
         move(buf[0],s[1],index_buf);
         ts.Add(s);
      end;
      if option and OPTION_SHOW_ASCII=0 then
      if option and OPTION_SAVE_ASCII>0 then
      begin
         if ExtractFileExt(filenamesave)<>'.txt'
         then filenamesave:=filenamesave+'.txt';
         ts.SaveToFile(filenamesave);
         QueryPerformanceCounter(t2);
         Label1.Caption:=(format('SAVED: %s  t=%.4f',[filenamesave,(t2 -t1)/hz]));
         ts.Free;

         if option and OPTION_AUTO_OPEN >0
         then ShellExecute(0,'OPEN',pchar(filenamesave),#0,nil,SHOW_FULLSCREEN);

         exit;
      end;

      //MM.Lines.BeginUpdate;
      MM.Lines.Assign(ts);
      ts.free;
      MM.Lines.Add('');
      if file_size>0 then;
      if inode_data[inode].page_offset=0 then;

      s:=format('----------------  end of data - lines=%d size=%d  (%x) pages=%d ----------',
        [lines,inode_data[inode].len,inode_data[inode].len,count_pages]);
      MM.Lines.Add(s);
      //MM.Lines.EndUpdate;
      QueryPerformanceCounter(t2);
      Label1.Caption:=(format('total pages=%d t=%.4f',[high(pags.bnum),(t2 -t1)/hz]));
      if file_size=0 then;
   end;
end;


procedure TF_HFS.Quit1Click(Sender: TObject);
begin
   close();
end;



// ex:  109540 parm    39 (  27) 0027C009 00950000 00007003 ...
procedure TF_HFS.inode_list_pad(pb: pbyte);
var pad:p_hfs_AD_pad;
    len:integer;
    padlen:word;
    nlen:byte;
    s,pdse_name:string;
begin
   pad:=p_hfs_AD_pad(pb);
   padlen:=swap(pad^.len);
   pdse_name:='';
   if (env_type=ENV_PDSE) and (padlen=26) then
   begin
      nlen:=p_pdse_dir_entry(pb)^.name[8];
      pdse_name:=DM.ebcdic_ascii_ptr(@p_pdse_dir_entry(pb)^.name[9],nlen,nlen);


     // pdse_name:=pchar_ebcdic_ascii(@p_pdse_dir_entry(pb)^.name[2]);
      //pdse_name:=pchar_ebcdic_ascii(@p_pdse_dir_entry(pb)^.name[2]);
   end;

   if padlen>60
   then len:=127
   else len:=padlen;
   s:=format('%6x parm  %4d (%4x) %s %s',
   [integer(pad)-integer(tm.memory),padlen,padlen,DM.dump_data(pb,0,len),pdse_name]);
   MM.Lines.Add(s);
end;


// list pad - page 2 - ex: 204D parm     9 (   9) 0009C014 00000000 05
procedure TF_HFS.inode_list_page2;
var pb:pbyte;
    AD_page:p_hfs_AD_header;
    group_qtd:byte;
    AD_groups:word;
    g:integer;
    padlen:word;
    pad:p_hfs_AD_pad;
begin
   pb:=tm.Memory;
   inc(pb,2*4096);
   AD_page:=p_hfs_AD_header(pb);
   inc(pb,HFS_FIRST_OFFSET);        // point first group

   if p_group(pb)^.g1 <> p_group(pb).g2 then
   begin
      ShowMessage('inital group not found');
      exit;
   end;
   AD_groups:=swap(AD_page.size);
   group_qtd:=p_group(pb)^.gq;
   if group_qtd=0 then exit;
   inc(pb,sizeof(t_group));
   while AD_groups>0 do
   begin
      if group_qtd=0 then break;
      for g:=0 to group_qtd-1 do
      begin
         inode_list_pad(pb);
         pad:=p_hfs_AD_pad(pb);
         padlen:=swap(pad^.len);
         inc(pb,padlen);
      end;
      dec(AD_groups,group_qtd);
      if AD_groups=0
      then break;
      if p_group(pb)^.g1 <> p_group(pb).g2
      then exit;
      group_qtd:=p_group(pb)^.gq;
      inc(pb,sizeof(t_group));
   end;
end;

procedure TF_HFS.TVKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
   if not TV.Focused then exit;
   if TV.Selected=nil then exit;
   if key = VK_RETURN
   then TVDblClick(tv);
end;


procedure TF_HFS.FormClose(Sender: TObject; var Action: TCloseAction);
begin
   SetLength(inode_data,0);
   FreeAndNil(tm);
end;


procedure TF_HFS.pdse_sb_map;
var i,g,sb:integer;
    pb:pbyte;
    AD_groups,padlen:word;
    group_qtd:byte;
    s:string;

    AD_page:p_pdse_AD_header;
    pad:p_hfs_AD_pad;

begin
   for i:=0 to page0.qtd_superblock-1 do
   begin
      if page0.superblocks[i].sb=0
      then continue;
      sb:=page0.superblocks[i].sb;


      pb:=tm.Memory;
      inc(pb,sb*4096);

      AD_page:=p_pdse_AD_header(pb);
      AD_groups:=swap(AD_page^.size);

      inc(pb,HFS_FIRST_OFFSET);        // point first group

      if p_group(pb)^.g1 <> p_group(pb).g2 then
      begin
         ShowMessage('inital group not found');
         exit;
      end;
      group_qtd:=p_group(pb)^.gq;
      if show_igw then
      begin
         MM.Lines.Add('');
         s:=format('************block %6x size %4d  *********',[sb,AD_groups]);
         MM.Lines.Add(s);

         s:=format('group %4x  %d',[p_group(pb)^.g1,group_qtd]);
         MM.Lines.Add(s);

      end;

      inc(pb,sizeof(t_group));


      // loop all pad in groups
      while AD_groups>0 do
      begin
         if group_qtd=0 then break;


         for g:=0 to group_qtd-1 do
         begin
            pad:=p_hfs_AD_pad(pb);
            padlen:=swap(pad^.len);
            if padlen=0
            then break;

            if show_igw
            then inode_list_pad(pb);

            inc(pb,padlen);
         end;





         dec(AD_groups,group_qtd);
         if AD_groups=0 then                       // group end??
         begin
            if sb=group_qtd then;
            break;
         end;
         if p_group(pb)^.g1=0
         then break;


         if p_group(pb)^.g1 <> p_group(pb).g2 then
         begin
            ShowMessage('error 1234 invalid group ');
            exit;
         end;
         group_qtd:=p_group(pb)^.gq;
         if show_igw then
         begin
            s:=format('group %4x  %d',[p_group(pb)^.g1,group_qtd]);
            MM.Lines.Add(s);
         end;

         inc(pb,sizeof(t_group));
      end;
   end;
end;

end.
