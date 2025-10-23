unit DsdBR7_PDSE;

interface

uses
  DASDbr7_DM,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Menus, Grids, ExtCtrls;

{$I pdse.inc}
type
  TF_PDSE = class(TForm)       // 69+55+ 54
    MM: TMemo;



    Label1: TLabel;
    MainMenu1: TMainMenu;
    SaveBin: TMenuItem;
    Quit: TMenuItem;
    SG: TStringGrid;
    Splitter1: TSplitter;
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure QuitClick(Sender: TObject);
    procedure SaveBinClick(Sender: TObject);
    procedure SGSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure SGDblClick(Sender: TObject);
    procedure SGKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    tm:TMemoryStream;
    page0      :t_pdse_page0;
    page1      :t_pdse_page1;
    vol_id     : string;
    pags       :t_list_blocks;
    sg_select_col,sg_select_row,
    limit_sb:integer;
    show_parms,
    show_blocks:boolean;
    sb_ordered,
    tsname:TStringList;
    files:t_data_pdse;
    hz,t1,t2:int64;


    function  get_page0():boolean;
    function  get_page1():boolean;


    procedure create_sb_ordered;
    procedure pdse_sb_map;
    procedure pdse_list_pad(pb: pbyte);
    procedure pdse_list_nd(page:integer);
    procedure show_data(index:integer);

    function get_page_matrix(only_first_page:boolean;pb:pbyte):boolean;



  public
    fn:string;
    stand_alone :boolean;
  end;

var
  F_PDSE: TF_PDSE;

implementation

{$R *.dfm}

procedure TF_PDSE.FormActivate(Sender: TObject);
var i,k:integer;
    s:string;
begin
   QueryPerformanceFrequency(hz);
   MM.Lines.Clear;
   SetLength(files,0);

   if not stand_alone then
   begin
      //show_igw:=false;
      show_parms:=false;
      show_blocks:=false;
      fn:='H:\temp\HFS\'+DM.volume_data.volid+'_'+DM.TK_F.FieldByName('name').AsString+'.dat';

      if not FileExists(fn) then
      begin
         if not DM.save_raw_data(false,fn) then
         begin
            ShowMessage('file not loaded '+fn);
            exit;
         end;
      end;
   end
   else   //if stand_alone  then
   begin
      fn:='G:\Temp\JARES1_SYS1.SIEALNKE.dat'; // 109 files found test
   end;


   if not FileExists(fn) then
   begin
      ShowMessage('errror 002 - file not found ->'+fn);
      close();
      exit;
   end;

   tm:=TMemoryStream.Create;
   tm.LoadFromFile(fn);
   show_blocks:=false;
   show_parms:=false;


   if not get_page1 then
   begin
      ShowMessage('error 150 - not a pdse file');
      Close;
      exit;
   end;

   MM.Lines.Add('pdse v9 - '+ExtractFileName(fn));
   Caption:=ExtractFileName(fn);


   SG.ColWidths[0]:=240;
   SG.ColWidths[1]:=140;
   SG.ColWidths[2]:=140;
   SG.ColWidths[3]:=140;
   SG.Cells[0,0]:='name';
   SG.Cells[1,0]:='size (k)';
   SG.Cells[2,0]:='date';
   SG.Cells[3,0]:='alias';
   SG.Cells[4,0]:='page';
   sg_select_col:=-1;
   sg_select_row:=-1;

   get_page0;
   tsname:=TStringList.Create;
   tsname.Sorted:=true;

   sb_ordered:=TStringList.Create;
   sb_ordered.Sorted:=true;

   create_sb_ordered;

   if sb_ordered.Count=0 then
   begin
      ShowMessage('error 102 - no data found');
      exit;
   end;


   //MM.Lines.BeginUpdate;



   Screen.Cursor:=crHourGlass;
   MM.Lines.BeginUpdate;
   limit_sb:=40;


   pdse_sb_map;

   {
   if show_parms and (fn='G:\Temp\JACIC1_DFH320.CPSM.SEYUVIEW.dat')
   then pdse_list_nd(522);
   if show_parms and (fn='G:\Temp\JARES1_SYS1.SIEALNKE.dat') then
   begin
      pdse_list_nd(21);
      pdse_list_nd(22);

   end;
   }
   Screen.Cursor:=crDefault;
   MM.Lines.EndUpdate;
   if show_blocks then
   begin
      MM.Lines.Add('count names ='+IntToStr(tsname.Count));
      MM.Lines.AddStrings(tsname);
   end;


  // pdse_list_nd(3);
  //

   tsname.Free;
   sb_ordered.Free;
   SG.RowCount:=high(files)+2;


   for i:=0 to high(files) do
   begin
      k:=files[i].pages * 4096 div 1024;

      sg.Cells[0,i+1]:=files[i].name;
      sg.Cells[1,i+1]:=format('%8d',[k]);
      sg.Cells[2,i+1]:=DM.format_file_date(files[i].dt);
      sg.Cells[3,i+1]:=files[i].alias;

      if show_blocks then
      begin
         s:=format('%3d files %6x %6dk %s %s %s',
            [i+1,files[i].off_page,k,DM.format_file_date(files[i].dt),files[i].name,files[i].alias]);
         MM.Lines.Add(s);
      end;
   end;

   if show_parms then
   begin
      MM.Lines.BeginUpdate;
      for i:=0 to high(files) do
      begin
         k:=files[i].pages * 4096 div 1024;
         s:=format('%3d files %6x %6dk %s %s %s',
            [i+1,files[i].off_page,k,DM.format_file_date(files[i].dt),files[i].name,files[i].alias]);
         MM.Lines.Add(s);
      end;
      MM.Lines.EndUpdate;
   end;
   exit;
   pdse_list_nd(30);
end;


procedure TF_PDSE.FormClose(Sender: TObject; var Action: TCloseAction);
begin
   tm.Free;
   SetLength(files,0);
end;

procedure TF_PDSE.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
   if key=VK_ESCAPE then close();
end;




//***************functions*************
function Swap4(a:cardinal):cardinal; asm bswap eax end;

function TF_PDSE.get_page1: boolean;
var pb:pbyte;
begin
   Result:=false;
   pb:=tm.Memory;
   inc(pb,4096);


   move(pb^,page1,sizeof(t_pdse_page1));

   if not CompareMem(@page1.dsn[36],@FORMAT1_LITERAL,4)
   then exit;

   page1.blkcount:=swap4(cardinal(page1.blkcount));
   {
   DM.ebcdic_inplace(page1.TWO,4);
   if page1.dsn[0]<>#0 then
   DM.ebcdic_inplace(page1.dsn,44);

   max_inode:=page1.blkcount * (HFS_PAGELEN div 512); // min 1 block 1 inode
   }
   Result:=true;
end;

function  TF_PDSE.get_page0():boolean;
var pb:pbyte;
    i:integer;
begin
   Result:=false;
   pb:=tm.Memory;
   move(pb^,page0,sizeof(t_pdse_page0));

   if page0.c1=$F1E6F0E2 then                   // type SOW1
   begin
      ShowMessage('error 101 - type S0W1 not suported');
      exit;
   end;
   DM.ebcdic_inplace(page0.igw,sizeof(page0.igw));
   vol_id:=DM.ebcdic_ascii_ptr(@page0.volid,6,6);


   page0.blocks:=swap4(page0.blocks);



   for i:=0 to page0.qtd_superblock-1 do        // swapt blocks number
   if page0.superblocks[i].sb<>0
   then page0.superblocks[i].sb:=(swap4(page0.superblocks[i].sb)-256);
   Result:=true;

end;




procedure TF_PDSE.pdse_list_pad(pb: pbyte);
var pad:p_pdse_pad;
    padlen:word;
    s:string;
begin
   pad:=p_pdse_pad(pb);
   padlen:=swap(pad^.len);


   if show_parms then
   begin
      s:=format('%6x parm  %4d (%4x) %s',
      [integer(pad)-integer(tm.memory),padlen,padlen,DM.dump_data(pb,0,padlen)]);
      MM.Lines.Add(s);
   end;
end;














procedure TF_PDSE.pdse_sb_map;

var i,k,g,q,sb,count_sb,count_pages,off_order:integer;

    pb,pw:pbyte;
    AD_groups,order,padlen:word;
    file_len:cardinal;
    group_qtd:byte;
    s,pdse_name,alias_name:string;
    nlen:byte;


    AD_page:p_pdse_AD_header;
    pad:p_pdse_pad;
    dt:double;

    found_dt:boolean;
    //ts_block:TStringList;

begin
   count_sb:=0;
   q:=0;
   //ts_block:=TStringList.Create;
   //ts_block.Sorted:=true;

   if show_blocks then
   begin
      s:='sb='+inttostr(page0.qtd_superblock)+' -> ';
      for i:=0 to page0.qtd_superblock-1 do
      begin
         if page0.superblocks[i].sb=0
         then continue;
         sb:=page0.superblocks[i].sb;
         if show_blocks then
         begin
            s:=s+IntToHex(sb,4)+' ';
            if length(s)>120 then
            begin
               MM.Lines.Add(s);
               s:='';
            end;
         end;
      end;
      MM.Lines.Add(s);
   end;


   for i:=0 to sb_ordered.Count-1 do
   begin
      off_order:=integer(sb_ordered.Objects[i]);
      sb:=off_order div 4096;

      pb:=tm.Memory;
      inc(pb,off_order);
      AD_page:=p_pdse_AD_header(pb);
      AD_groups:=swap(AD_page^.size);
      {
      pw:=pb;

      AD_page:=p_pdse_AD_header(pb);
      AD_groups:=swap(AD_page^.size);
      order:=swap(AD_page^.order);
      off_order:=integer(pb)-integer(tm.Memory);
      }
      inc(pb,PDSE_FIRST_OFFSET);        // point first group
      if p_group(pb)^.g1 <> p_group(pb).g2 then
      begin
         ShowMessage('inital group not found');
         exit;
      end;
      group_qtd:=p_group(pb)^.gq;

      if show_blocks then
      begin
         MM.Lines.Add('');
         s:=format('************block %6x size %4d  *********',[sb,AD_groups]);
         MM.Lines.Add(s);

         s:=format('group %4x  %d',[p_group(pb)^.g1,group_qtd]);
         MM.Lines.Add(s);
      end;

      inc(pb,sizeof(t_group));


      // loop all pad in groups
      file_len:=0;
      dt:=0;
      found_dt:=false;
      alias_name:='';
//      count_pages:=0;
      while AD_groups>0 do
      begin
         if group_qtd=0 then break;


         for g:=0 to group_qtd-1 do
         begin
            pad:=p_pdse_pad(pb);
            padlen:=swap(pad^.len);
            if padlen=0
            then break;

            if (padlen=99) and (pad^.w1=swap($c00b)) then
            begin
               dt:=DM.gmt_stck(@p_AD_type99(pb)^.d1);
               file_len:=swap4( p_AD_type99(pb)^.size);
               found_dt:=true;
            end
            else
            if (padlen=96) and (pad^.w1=swap($c00e)) then
            begin
               dt:=DM.gmt_stck(@p_AD_type96(pb)^.d1);
               file_len:=swap4( p_AD_type96(pb)^.size);
               found_dt:=true;
            end
            else
            if (padlen=105) and (pad^.w1=swap($c005)) then
            begin
               dt:=DM.gmt_stck(@p_AD_type69(pb)^.d1);
               file_len:=swap4( p_AD_type69(pb)^.size);
               found_dt:=true;
            end;

            if get_page_matrix(false,pb) then
            begin
               if show_parms then
               begin
                  s:='===========pags ';
                  for k:=0 to high(pags.bnum) do
                  begin
                     s:=s+IntToHex(pags.bnum[k],4)+' ';
                     if length(s)>127 then
                     begin
                        MM.Lines.Add(s);
                        s:='';
                     end;
                  end;
                  MM.Lines.Add(s);
                  s:=format('===========pags  tot=%d',[high(pags.bnum)+1]);
                  MM.Lines.Add(s);
               end;
               count_pages:=high(pags.bnum)+1;
               if q>0 then
               begin
                  files[q-1].pages:=count_pages;
                  files[q-1].off_page:=integer(pb) - integer(tm.Memory);
               end;   
               // 2 files   50C1   1380k abr 30  2009 GLDCLDAP
               // GLDCLDAP                           000A9DDC   000004   00    31  ANY
               //_________ GLDCLD64                           000$90908   000005   00    64  ANY
               //_________ IWMAM43X                           00006528   000009   00    31  ANY    33 pages
            end;






            //if found_dt and (count_pages>0) and (pdse_name<>'') then
            if found_dt and (pdse_name<>'') then
            begin
               if show_parms then
               begin
                  s:=format('**********file len %5d (%4x) %s',[file_len,file_len,DM.format_file_date(dt)]);
                  MM.Lines.Add(s);
               end;
               k:=high(pags.bnum);
               if  k>0 then k:=pags.bnum[0];

               if pdse_name='' then
               begin
                  s:=format('error 814 - no name - page %d (%x)',[k,k]);
                  MM.Lines.Add(s);
               end
               else
               begin
                  if high(files)=-1
                  then SetLength(files,1024);

                  files[q].name:=pdse_name;
                  files[q].pages:=0;
                  files[q].off_page:=integer(pb) - integer(tm.Memory);
                  files[q].dt:=dt;
                  if not tsname.Find(pdse_name,k) then
                  begin
                     tsname.AddObject(pdse_name,TObject(q));
                     inc(q);
                  end;
               end;

               dt:=0;
               file_len:=0;
               pdse_name:='';
               found_dt:=false;
            end;


            if (padlen=26) and         // alias
               (pad.w1=swap($C00b)) and
               (pad.w2=swap($000e)) and
               (pad.w6=swap($0002)) then
            begin
               nlen:=p_pdse_pad_type26(pb)^.ln;
               alias_name:=DM.ebcdic_ascii_ptr(@p_pdse_pad_type26(pb)^.name,nlen,nlen);
               if show_parms
               then MM.Lines.Add('--------- alias '+alias_name+' -->'+pdse_name);
               tsname.Add(alias_name+' -->'+pdse_name);
            end
            else
            if (p_pdse_pad_type1(pb).w1=swap($C00b)) and
               (p_pdse_pad_type1(pb).w4=swap($1001)) and
               (p_pdse_pad_type1(pb).w6=0)then
            begin
               nlen:=p_pdse_pad_type1(pb)^.ln;
               pdse_name:=DM.ebcdic_ascii_ptr(@p_pdse_pad_type1(pb)^.name,nlen,nlen);
               if show_parms then
               begin
                  s:='-------------->'+pdse_name;
                  MM.Lines.Add(s);
               end;   
            end
            else
            // 002F C00E 0060
            if (padlen=47) and
               (p_pdse_pad_type47(pb).w1=swap($C00e)) and
               (p_pdse_pad_type47(pb).w2=swap($0060)) then
            begin
               if pdse_name<>''              // 'GDEKEXP '  'GLDBKCMN'
               then MM.Lines.Add('**********nao processado '+pdse_name);
               pdse_name:=DM.ebcdic_ascii_ptr(@p_pdse_pad_type47(pb)^.name,8,8);
            end
            else
            if (padlen=18) and         // alias
               (p_pdse_pad_type18(pb).w1=swap($C013)) and
               (p_pdse_pad_type18(pb).w3=swap($0100)) then
            begin
               nlen:=p_pdse_pad_type18(pb)^.ln;
               alias_name:=DM.ebcdic_ascii_ptr(@p_pdse_pad_type18(pb)^.name,nlen,nlen);
               if show_parms
               then MM.Lines.Add('--------- alias '+alias_name+' -->'+pdse_name);
               tsname.Add(alias_name+' -->'+pdse_name);
            end;

            if alias_name<>'' then
            begin
               if high(files)=-1
               then SetLength(files,1024);
               files[q].alias:=pdse_name;
               files[q].name:=alias_name;
               files[q].pages:=0;
               files[q].off_page:=0;
               files[q].dt:=0;
               inc(q);
               alias_name:='';
            end;


            //else







            if show_blocks
            then pdse_list_pad(pb);

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
         if show_blocks then
         begin
            s:=format('group %4x  %d',[p_group(pb)^.g1,group_qtd]);
            MM.Lines.Add(s);
         end;

         inc(pb,sizeof(t_group));
      end;
   end;
   SetLength(files,q);
end;



function name_end_01(pb:pbyte):string;
var pc:pchar;
    nl:integer;
    s:string;
begin
   pc:=pchar(pb);
   nl:=StrLen(pc)-1;
   s:=DM.ebcdic_ascii_ptr(pb,nl,nl);
   Result:=s;

end;












procedure TF_PDSE.pdse_list_nd(page: integer);
var  g,dir_offset,count_dir,ix,page_len:integer;
     pb,pw:pbyte;
     q_dir,entry_size:word;
     qtd_group:byte;
     dir:p_pdse_dir_entry;
     s,name,oldname:string;
begin

   pb:=tm.Memory;
   inc(pb,page*HFS_PAGELEN);
   page_len:=page*HFS_PAGELEN;
   if (p_pdse_ND(pb)^.ND_tag[0]=$d5) and
      (p_pdse_ND(pb)^.ND_tag[1]=$c4)
   then
   else

   begin
      MM.Lines.Add('error 800 - not a ND page');
      exit;
   end;



   q_dir:=swap(p_pdse_ND(pb)^.qtd_dirs);
   if p_pdse_ND(pb)^.qtd_dirs=0 then;
   if p_pdse_ND(pb)^.qtd_groups=0 then;
   count_dir:=0;
   MM.Lines.Add('');
   s:=format('******* DIR    page %d (%x) dir %d ************',[page,page,q_dir]);
   MM.Lines.Add(s);
   if q_dir>255 then
   begin
      MM.Lines.Add('error 801 - too many dirs');
      exit;
   end;



   inc(pb,PDSE_DIR_OFFSET);
   for g:=0 to q_dir-1 do             // for allgroups
   begin
      if g=20 then break;
      s:=format('%3d DIR group %4x  %d',[g,p_group(pb)^.g1,p_group(pb)^.gq]);
      MM.Lines.Add(s);

      if p_group(pb)^.g1=0
      then break;


      if p_group(pb)^.g1<>p_group(pb)^.g2 then
      begin
         ShowMessage('not a goup');
         if p_group(pb)^.g1=0 then;
         exit;
      end;
      qtd_group:=p_group(pb)^.gq;      // this group quantity
      inc(pb,sizeof(t_group));

      while qtd_group>0 do
      begin
         dir:=p_pdse_dir_entry(pb);
         entry_size:=swap(dir^.len);
         dir_offset:=integer(pb)-integer(tm.Memory);
         inc(count_dir);

         if dir^.const_38=$38 then
         begin
            name:=name_end_01(@dir^.name);
            pw:=pb;
            inc(pw,length(name)+5);
            if p_dir_part2(pw)^.i=0 then;
            ix:=swap4(p_dir_part2(pw)^.i);


            if dir^.name_rep=0
            then oldname:=name
            else name:=copy(oldname,1,dir^.name_rep)+name;
            //tsname.Add(name);
            oldname:=name;
            s:=format('%4d at %6x %4d (%4x) %s %3x %s',[count_dir, dir_offset,entry_size,entry_size,name,ix,DM.dump_data(pb,0,entry_size)]);
            MM.Lines.Add(s);
         end
         else
         begin
            s:=format('%4d at %6x %4d (%4x) %s ',[count_dir, dir_offset,entry_size,entry_size,DM.dump_data(pb,0,entry_size)]);
            MM.Lines.Add(s);
         end;

         if get_page_matrix(false,pb) then
         begin
            if pags.bnum[0]=0 then;
         end;


         inc(pb,entry_size);
         dec(qtd_group);
      end;
      if q_dir=count_dir then
      begin
         MM.Lines.Add('dir qtd end');
         break;
      end;
   end;
   dir:=p_pdse_dir_entry(pb);       // pode nao ter extra....
   entry_size:=swap(dir^.len);
   ix:=-1;
   if entry_size=26 then
   begin
      ix:=256;
   end
   else
   begin

   if p_extra_dir(pb)^.q=0 then exit;
   try
   ix:=swap4(p_extra_dir(pb)^.q);
   except
      if pb^=0 then;
   end;
   inc(pb,sizeof(t_extra_dir));
   end;

   count_dir:=0;                     //verificar 1a

   for  ix:=IX downto 0 do
   begin
      entry_size:=swap(p_pdse_pad(pb)^.len);
      dir_offset:=integer(pb)-integer(tm.Memory);
      if dir_offset>page_len+4096 then
      begin
         MM.Lines.Add('at eop---------------');
         break;
      end;
      s:=format('%4d at %6x %4d (%4x) %s ',[count_dir, dir_offset,entry_size,entry_size,DM.dump_data(pb,0,entry_size)]);
      MM.Lines.Add(s);
      inc(pb,entry_size);
      if p_group(pb)^.g1=p_group(pb)^.g2 then
      begin
         s:=format('%3d extra group %4x  %d',[ix,p_group(pb)^.g1,p_group(pb)^.gq]);
         MM.Lines.Add(s);
         if p_group(pb)^.g1=0
         then break;
         inc(pb,5);
      end;
   end;
   if count_dir=0 then;
end;









function TF_PDSE.get_page_matrix(only_first_page: boolean;   pb: pbyte): boolean;
var pm:p_page_matrix;
    i,k,q,offset_block:integer;
    page:cardinal;
    block_qtd,padlen:word;

    pad:p_pdse_pad;
    block_set:p_block_set;

begin
   Result:=false;
   SetLength(pags.bnum,0);
   offset_block:=-1;

   q:=0;
   pad:=p_pdse_pad(pb);       // get pad
   padlen:=swap(pad.len);

   //  0 1  2 3  4 5  6 7  8 9  0 1  2 3  4 5
   // 002F FA0B 0005 0000 7003 0000 0000 01 0002C6D7D4 D9C5E2C5 D9E5C500 00000000 01748B00 00000000 00000200 420000
   // 0025 C00B 000F 0000 7003 0000 0000 01 0001C6D7D4 D9C5E2C5 D9E5C500 00000000 04500000 00
   if (padlen=47) or (padlen=37) then
   if (pad^.w4=swap($7003)) then
   begin
      offset_block:=15;
   end;


   //  len   w1   w2   w3  w4    w5   w6
   //  0 1  2 3  4 5  6 7  8 9  0 1  2 3  4 5
   // 0022 C00E 0070 0300 0000 0001 0001 C6D7 D4D9C5E2 C5D9E5C5 00000000 00010A02 0000 FPMRESERVE data
   // 002C FA0E 0070 0300 0000 0001 0002 C6D7 D4D9C5E2 C5D9E5C5 00000000 000AED12 00000000 0000000B 00DC0000
   // 0022 FA0E 0070 0300 0000 0001 0001 C6D7 D4D9C5E2 C5D9E5C5 00000000 0001086B 0000

   if offset_block=-1 then
   begin
      if (pad^.w2<>swap($0070)) then exit;
      if (pad^.w3<>swap($0300)) then exit;
      if (pad^.w5<>swap($0001)) then exit;
      offset_block:=12;
   end;


   if offset_block=-1 then exit;

   inc(pb,offset_block);

   block_set:=p_block_set(pb);

   pm:=p_page_matrix(@block_set^.pages);
   page:=swap4(pm.page);

   if page<3 then exit;;

//   page:=0;

   if only_first_page
   then SetLength(pags.bnum,1)
   else SetLength(pags.bnum,2048);

   block_qtd:=swap(block_set^.qt);

   for i:=0 to block_qtd-1 do
   begin
      page:=swap4(pm.page);
      page:=page-256;
      //if page> max_inode  dbs
     // then break;

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
   {
   if page> max_inode then
   begin
      ShowMessage('error 620 - invalid page in page set');
      SetLength(pags.bnum,0);
      exit;
   end;
   }
   SetLength(pags.bnum,q);
   if q>0 then
   if pags.bnum[0]=0 then;

   if pad^.w1=0 then;
   if pb^=0 then;
   Result:=true;
end;

{ lay out ???
function TF_PDSE.get_linked_len(page: integer): integer;
var pb:pbyte;
    s:string;
    len:cardinal;
begin
   Result:=-1;
   pb:=tm.Memory;
   inc(pb,page*HFS_PAGELEN);
   s:=DM.ebcdic_ascii_ptr(pb,8,8);
   if s<>PDSE_LINKED_TAG then exit;
   try
   len:=swap4(p_linked_data(pb)^.size);
   except end;
   Result:=len;
AD=


end;
 }
procedure TF_PDSE.create_sb_ordered;
var pb,pw:pbyte;
    i,k,new_off,sb,off_order:integer;
    order:word;
    AD_page:p_pdse_AD_header;
    s,ddmmaa:string;
    tsunordered:TStringList;
    dt,dt2:double;
begin
   tsunordered:=TStringList.Create;
   for i:=0 to page0.qtd_superblock-1 do
   begin
      if page0.superblocks[i].sb=0
      then continue;
      sb:=page0.superblocks[i].sb;

      pb:=tm.Memory;
      inc(pb,sb*4096);



      AD_page:=p_pdse_AD_header(pb);

      order:=swap(AD_page^.order);
      off_order:=integer(pb)-integer(tm.Memory);

      dt:=DM.gmt_stck(@AD_page^.d1);
      ddmmaa:=FormatDateTime('dd/mm/yy hh:nn:ss',dt);


      s:=format('%8x %4x %s %s ',[off_order,sb,DM.dump_data(pb,0,72),ddmmaa]);
      tsunordered.Add(s);

      if AD_page^.b18<>$18 then
      begin
         s:=format('%8x',[order]);
         if order>0 then
         begin
            if sb_ordered.Find(s,k) then           // verify date x old date
            begin
               new_off:=integer(sb_ordered.Objects[k]);
               pw:=tm.Memory;
               inc(pw,new_off);
               dt2:=DM.gmt_stck(@p_pdse_AD_header(pw).d1);

               if dt>dt2
               then sb_ordered.Delete(k);          //delete old index with date less than dt
            end;                                   // so keep new date
         end;
         sb_ordered.AddObject(s,TObject(off_order));
      end;
   end;
   if sb_ordered.Count=0 then;
   if show_blocks then
   begin
      MM.Lines.Add('***************unorderd******************');
      MM.Lines.AddStrings(tsunordered);
      MM.Lines.Add('');

      for i:=0 to sb_ordered.Count-1 do
      begin
         off_order:=integer(sb_ordered.Objects[i]);
         pb:=tm.Memory;
         inc(pb,off_order);
         s:=format('%8x order %8s %s ',[off_order,sb_ordered[i],DM.dump_data(pb,0,72)]);
         MM.Lines.Add(s);
      end;
   end;
   tsunordered.Free;

end;

procedure TF_PDSE.QuitClick(Sender: TObject);
begin
   close();
end;

procedure TF_PDSE.SaveBinClick(Sender: TObject);
begin
   //
end;

procedure TF_PDSE.SGSelectCell(Sender: TObject; ACol, ARow: Integer;var CanSelect: Boolean);
begin
   sg_select_col:=ACol;
   sg_select_row:=ARow;
end;


procedure TF_PDSE.SGDblClick(Sender: TObject);
var i:integer;
begin
   if sg_select_col>0 then exit;
   i:=sg_select_row-1;
   if (i>=low(files)) and (i<=high(files)) then
   begin
      Screen.Cursor:=crHourGlass;
      show_data(i);
      Screen.Cursor:=crDefault;
   end;



end;

procedure TF_PDSE.show_data(index: integer);
var pb:pbyte;
    i,j,k,page,count_lines:integer;
    s:string;
    buf:array[0..1023] of char;

begin
   QueryPerformanceCounter(t1);
   count_lines:=0;
   if files[index].alias<>''
   then exit;

   pb:=tm.Memory;
   inc(pb,files[index].off_page);

   //get all pad and matrix...

   if not get_page_matrix(false,pb) then
   begin
      ShowMessage('error 870 - data not found???');
      exit;
   end;
//   inc(pb,file_size);
   if high(pags.bnum)=-1 then
   begin
      ShowMessage('error 871 - data not found???');
      exit;
   end;
   MM.Lines.Clear;
   MM.Lines.BeginUpdate;




   j:=0;
   for i:=0 to high(pags.bnum) do
   begin
      page:=pags.bnum[i];
      pb:=tm.Memory;
      inc(pb,page*HFS_PAGELEN);
      k:=0;
      while  k<HFS_PAGELEN do
      begin
         while pb^=0 do
         begin
            inc(k);
            inc(pb);
            continue;
         end;
         if count_lines>2000 then
         begin
            MM.Lines.Add('**********************max lines reached***********');
            break;
         end;

         if CompareMem(pb,@PDSE_TEXT_LITERAL,sizeof(PDSE_TEXT_LITERAL)) then
         begin
            if j>0 then
            begin
               buf[j]:=#0;
               s:=TrimRight(buf);
               MM.Lines.Add(s);
               inc(count_lines);
               j:=0;
            end;
            inc(pb,6);           // bypass c3 0 0 0 0 50
            inc(k,6);
            continue;
         end;
         buf[j]:=ebcdic_to_ascii[pb^];
         inc(j);
         if j>127 then
         begin
            buf[j]:=#0;
            s:=TrimRight(buf);
            MM.Lines.Add(s);
            inc(count_lines);
            j:=0;
         end;
         inc(k);
         inc(pb);
      end;
      if count_lines>2000
      then break;



   end;
   if j>0 then
   begin
      s:=trim(buf);
      MM.Lines.Add(s);
   end;
   MM.Lines.EndUpdate;
   QueryPerformanceCounter(t2);
   Label1.Caption:=format('lines=%d t=%.4f',[count_lines,(t2 -t1)/hz]);

end;

procedure TF_PDSE.SGKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
   if key<>VK_RETURN then exit;
   if not sg.Focused then exit;
   if SG.RowCount<3 then exit;
   if sg_select_row<1 then exit;
   SGDblClick(SG);
end;

end.
