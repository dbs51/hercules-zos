{

show dataset/member data
   set max line len / max column len

tips:

... For  VSAM,  an  end-of-file  indicator  consists  of  a
control  interval  with  a  CIDF  equal  to  zeros.


// Move to 3rd line, Character 3:
    SelStart := Perform(EM_LINEINDEX, 2, 0) + 3;
    Memo1.SelLength := 0;
    Perform(EM_SCROLLCARET, 0, 0);
    Memo1.SetFocus;


row := SendMessage(Handle, EM_LINEFROMCHAR, SelStart, 0);
        col := SelStart - SendMessage(Handle, EM_LINEINDEX, row, 0);


}


unit DasdBR7_Show;

interface

uses
  DASDBR7_DM,
  DASDBR7_DV,
  DasdBR7_PDS,
  clipbrd,StrUtils,
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Menus;







type
  TF_Show = class(TForm)
    MM: TMemo;
    MainMenu1: TMainMenu;
    Options1: TMenuItem;
    MaxLine1: TMenuItem;
    Quit1: TMenuItem;
    Lenline1: TMenuItem;
    Showrecnum1: TMenuItem;
    Showreclen1: TMenuItem;
    SHOWCCHH1: TMenuItem;
    Showhex1: TMenuItem;
    ShowVsamRBA1: TMenuItem;
    Save1: TMenuItem;
    Index: TMenuItem;
    Find1: TMenuItem;
    ext1: TMenuItem;
    SaveBin: TMenuItem;
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormActivate(Sender: TObject);
    procedure MMKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Quit1Click(Sender: TObject);
    procedure MaxLine1Click(Sender: TObject);
    procedure Lenline1Click(Sender: TObject);
    procedure Showrecnum1Click(Sender: TObject);
    procedure Save1Click(Sender: TObject);
    procedure IndexClick(Sender: TObject);
    procedure Find1Click(Sender: TObject);
    procedure SaveBinClick(Sender: TObject);
  private
    { Private declarations }
    find_string:string;
    find_offset:cardinal;

    function  Show_Vsam :boolean;
    function  Build_line(pl:Pbyte;recl,nrec,rba:cardinal):PByte;
    procedure Copy1Click(Sender: TObject);
    procedure Show_data_text;

  public
    { Public declarations }
    proctype:string;
    lrecl,
    ttr,
    recs,
    nrec,
    cyl,trk : word;

  end;


var
  F_Show: TF_Show;
  max_line:integer=2000;
  max_col :integer =133;

implementation









{$R *.DFM}

function Swap4(a:cardinal):cardinal; asm bswap eax end;

procedure TF_Show.FormActivate(Sender: TObject);
begin
   find_offset:=0;
   MM.Lines.Clear;
   if proctype='VSAM'
   then Show_Vsam
   else Show_data_text;
   MM.SetFocus;
end;


procedure TF_Show.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key=27 then ModalResult:=mrok;
  if (key=VK_F3) and (find_offset>1)
  then Find1Click(nil);
end;





function TF_Show.Build_line(pl:Pbyte;recl,nrec,rba:cardinal):Pbyte;

var i,col_limit : integer;
    aux,ss,hex1,hex2:string;
begin
   Result:=pl;
   if (pl=nil) or (recl=0) then exit;
   if lrecl>max_col
   then col_limit:=max_col
   else col_limit:=lrecl;

   hex1:='';hex2:='';
   ss:=DM.ebcdic_ascii_ptr(pl,recl,max_col);
   if Showhex1.Checked then
   begin
      SetLength(hex1,col_limit);
      SetLength(hex2,col_limit);
      for i:=1 to col_limit do
      begin
         hex1[i]:=hexa_tab[pl^ shr 4];
         hex2[i]:=hexa_tab[pl^ and 15];
         inc(pl);
      end;
   end
   else
   begin
      inc(pl,recl);
   end;
   aux:='';

   if F_Show.Showrecnum1.Checked
   then aux:=format('%.4d ',[nrec]);

   if (proctype='VSAM') and (rba>0)
   then aux:=aux+format('rba=%.4X (%.4d) ',[rba,rba]);

   if F_Show.Showreclen1.Checked
   then aux:=aux+format('%.4d ',[recl]);

   MM.Lines.Add(aux+ss);

   if Showhex1.Checked then
   begin
       if length(aux)>0
       then FillChar(aux[1],length(aux),32);
       MM.Lines.Add(aux+hex1);
       MM.Lines.Add(aux+hex2);
       MM.Lines.Add('');
   end;
   Result:=pl;
end;




function get_record(fileno:integer;ckd:p_ckd):PByte;
var
    pb : Pbyte;
    hrec:rec_header;
begin
   Result:=nil;
   pb:=DM.read_one_track(fileno,ckd,true);
   if pb=nil then Exit;
   move(pb^,hrec,sizeof(hrec));
   hrec.dlen:=swap(hrec.dlen);
   if hrec.dlen=0 then Exit;     // empty
   Result:=pb;
end;




procedure TF_Show.Show_data_text;
var
   t1,t2,hz:int64;
   show_options:integer;

begin
   MM.Lines.Clear;
   QueryPerformanceFrequency(hz);
   QueryPerformanceCounter(t1);

   show_options:=0;
   if F_Show.Showrecnum1.Checked
   then show_options:=show_options or option_show_rec;

   if F_Show.Showreclen1.Checked
   then show_options:=show_options or option_show_len;

   if F_Show.SHOWCCHH1.Checked
   then show_options:=show_options or option_show_trk;

   if F_Show.Showhex1.Checked
   then show_options:=show_options or option_show_hexa;

   MM.Lines.BeginUpdate;
   screen.Cursor:=crHourGlass;

   MM.Lines:=DM.show_data_text(show_options,max_line,max_col);

   screen.Cursor:=crDefault;
   MM.Lines.EndUpdate;
   if MM.Lines.Count=0 then
   begin
      ShowMessage('...empty...');
      ModalResult:=mrCancel;
      exit;
   end;

   QueryPerformanceCounter(t2);

   F_Show.Caption:=format('%s (%s) recs=%d t=%.3f',
   [DM.TK_F.FieldByName('name').AsString,DM.TK_PDS.FieldByName('name').AsString,recs,(t2-t1)/hz]);
end;


procedure TF_Show.Copy1Click(Sender: TObject);
var tc : tclipboard;
    ss : string;
    i : integer;
begin
   if MM.Lines.Count<1 then exit;
   ss:='';
   for i:=0 to MM.Lines.Count -1
   do ss:=ss+MM.Lines[i]+#10;
   tc:=TClipboard.Create;
   tc.SetTextBuf(pchar(ss));
   tc.free;
end;




procedure TF_Show.MMKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if  ssCtrl in Shift then
  begin
     if (key=67) then Copy1Click(nil);
  end;
end;




procedure TF_Show.Quit1Click(Sender: TObject);
begin
  ModalResult:=mrok
end;

procedure TF_Show.MaxLine1Click(Sender: TObject);
var ss : string;
    i : integer;
begin
   ss:=IntToStr(max_line);
   if InputQuery('Max num of lines','',ss)=false then exit;
   val(ss,max_line,i);

   if proctype='VSAM'
   then Show_Vsam
   else Show_data_text;
end;

procedure TF_Show.Lenline1Click(Sender: TObject);
var ss : string;
    i : integer;
begin
   ss:=IntToStr(max_col);
   if InputQuery('Max length of line','',ss)=false then exit;
   val(ss,max_col,i);
   if proctype='VSAM'
   then Show_Vsam
   else Show_data_text;
end;

function valid_vvdr(pv:Pbyte):boolean;
var ss:string;
    vvr: t_vdr_valid;
begin
   Result:=false;
   move(pv^,vvr,sizeof(t_vdr_valid));
   if vvr.blklen=0 then exit;
   if vvr.rlen=0 then exit;
   DM.ebcdic_inplace(vvr.name,4);
   ss:=vvr.name;
   if ss='VVCR'
   then Result:=true;
end;



function get_BYTE3(px:PByte):cardinal;
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




function TF_Show.Show_VSAM:boolean;
var
    pRID,//p_next_rec,
    pb,pg,pgetmem : PByte;
    CIDF:t_CIDF;
    ckd : tckd;
    s:string;

    rba:cardinal;

    vsam_eof : boolean;
    cipartial,
    i,k,fileno,seqno,rdflen,cisize:integer;
    exts:p_resume;
    hrec:rec_header;
    lrdf:t_rdf_list;
    //cibuf:array[0..65535] of byte;

    cisize_greater:boolean;


   function vsam_next_ci:boolean;
   var s:string;
   begin
      Result:=false;

      // next record
      hrec:=DM.get_next_header(pb,hrec.klen+hrec.dlen);


      if hrec.cyl=$FFFF then // next track
      begin
         vsam_eof:=true;
         exit;
      end;

      rba:=0;

      pRID:=pb;
      inc(pRID,hrec.dlen-4);
      Move(prid^,CIDF,sizeof(t_CIDF));
      CIDF.ofs:=swap(CIDF.ofs);
      CIDF.len:=swap(CIDF.len);
      //ci_bytes:=CIDF.len;
      //vpos:=pos_read;

      if F_Show.SHOWCCHH1.Checked then
      begin
         s:=format('C %.4d  T%.2d  R%.2d  DL %d    KL %d   CIDF(%X %d)',
          [ckd.cyl,ckd.trk,ckd.nrec,ckd.read,hrec.klen,CIDF.ofs,CIDF.len]);
         MM.Lines.Add(s);
      end;

      //... For  VSAM,  an  end-of-file  indicator  consists  of  a
      //control  interval  with  a  CIDF  equal  to  zeros.

      if (CIDF.ofs=0) and (CIDF.len=0)
      then vsam_eof:=true
      else Result:=True;
   end;



begin

   recs:=1;
   Result:=false;
   MM.Lines.Clear;
   SetLength(lrdf,0);
   cisize:=DM.TK_V.FieldByName('cisize').AsInteger;
   //'IMS810.DFSIVD34.DATA' vol ims1 negative
   if DM.TK_F.FieldByName('name').AsString='' then;

   fileno:=DM.TK_F.FieldByName('dscb').AsInteger;
   // DM.TK_V.FieldByName('cisize').AsInteger:=amsd.ci_size;
   seqno:=0;
   exts:=DM.get_file_extents(fileno,seqno);
   if exts=nil then exit;


   ckd.cyl:=exts.l_cyl;
   ckd.trk:=exts.l_trk;
   ckd.nrec:=2;

   // calculate if cisize fill in one record ? use record 2

   pb:=DM.read_one_track(fileno,@ckd,true);
   if pb=nil then
   begin
      ShowMessage('Empty...');
      Result:=false;
      ModalResult:=mrRetry;
      exit;
   end;
   hrec:=DM.get_next_header(pb,0);
   cisize_greater:=cisize>hrec.dlen;
   ckd.nrec:=0;
   pgetmem:=nil;

   if cisize_greater then
   begin
      GetMem(pgetmem,65535);
   end;


   screen.Cursor:=crHourGlass;
   MM.Lines.BeginUpdate;


   while true do
   begin
      inc(ckd.nrec);
      pb:=DM.read_one_track(fileno,@ckd,true);
      if pb=nil then
      begin
         ShowMessage('Empty...');
         Result:=false;
         ModalResult:=mrRetry;
         MM.Lines.EndUpdate;

         exit;
      end;
      hrec:=DM.get_next_header(pb,0);
      if DM.get_extent_sequence(fileno,hrec.cyl,hrec.head)=nil then
      begin
         MM.Lines.Add('End of extents');
         break;
      end;


      if cisize_greater then
      begin

         pg:=pgetmem;
         move(pb^,pg^,hrec.dlen);
         inc(pg,hrec.dlen);
         cipartial:=hrec.dlen;
         while cipartial<cisize do
         begin
            inc(ckd.nrec);
            pb:=DM.read_one_track(fileno,@ckd,true);
            if pb=nil then exit; // should not occurss
            hrec:=DM.get_next_header(pb,0);
            move(pb^,pg^,hrec.dlen);
            inc(pg,hrec.dlen);
            inc(cipartial,hrec.dlen);
         end;
         pb:=pgetmem;
      end;


// In a key-sequenced data set or an RRDS, the first control interval in
//the first unused control area (if any) contains a CIDF filled with 0s. A CIDF filled
//with 0s represents the software end-of-file.

      //paux:=pb;

      // acess CIDF
      pRID:=pb;
      inc(pRID,cisize-4);
      Move(prid^,CIDF,sizeof(t_CIDF));


      CIDF.ofs:=swap(CIDF.ofs);
      CIDF.len:=swap(CIDF.len);
      CIDF.len:=CIDF.len and (not CIDF_BUSY);      // remove split busy flag




      if (CIDF.ofs>cisize) or (CIDF.len>cisize) then
      begin
         s:=format('C %.4d  T%.2d  R%.2d  KL %d    DL %d   CIDF(%X %X)',
          [hrec.cyl,hrec.head,hrec.rec,hrec.klen,hrec.dlen,CIDF.ofs,CIDF.len]);
         MM.Lines.Add(s);
         s:=format('Error 333 - CIDF invalid ofs=%d len=%d  greater than ci=%d',[CIDF.ofs,CIDF.len,cisize]);
         MM.Lines.Add(s);
         break;
      end;




      //ci_bytes:=CIDF.ofs;                       // offset free = last data byte = ci bytes
      rdflen:=cisize - (CIDF.ofs+CIDF.len) - sizeof(t_cidf);


      if F_Show.SHOWCCHH1.Checked then
      begin
         s:=format('C %.4d  T%.2d  R%.2d  KL %d    DL %d   CIDF(%d %d)',
          [hrec.cyl,hrec.head,hrec.rec,hrec.klen,hrec.dlen,CIDF.ofs,CIDF.len]);
         MM.Lines.Add(s);
      end;
      if (CIDF.ofs=0) and (CIDF.len=0) then
      begin
         MM.Lines.Add('EOF --> CIDF zero');
         break;
      end;

      if (CIDF.ofs=0) and (CIDF.len= cisize-4) then
      begin
         MM.Lines.Add('end --> CIDF zeroed');
         break;
      end;
      if rdflen=0 then
      begin
         s:='rdflen=0';
         MM.Lines.Add(s);
         break;
      end;
      if rdflen<0 then
      begin
         s:='rdflen negative???';
         MM.Lines.Add(s);
         break;
      end;

      lrdf:=DV.VSAM_RDF_list(pb,cisize); // must be div by 3
      {
      if high(lrdf)=-1 then
      begin
         s:='<---- EOF in RID --->';
         MM.Lines.Add(s);
         break;
         if hrec.cyl=0 then;
         break;
      end;
      }
      for i:=0 to high(lrdf) do
      begin

         if lrdf[i].qrec=0 then;
         for k:=1 to lrdf[i].qrec do
         begin
            lrecl:=lrdf[i].recl;
            if lrecl=0 then
            if lrecl=0 then;

            if ShowVsamRBA1.Checked
            then pb:=Build_line(pb,lrecl,recs,rba)
            else pb:=Build_line(pb,lrecl,recs,0);
            inc(recs);
            inc(rba,lrecl);
            if recs>max_line then
            begin
               if recs>max_line then
               break;
            end;
         end;
         if recs>max_line then
      break;
      end;
      if recs>max_line then
      break;
   end;
   if recs>max_line
   then MM.Lines.Add('max lines reached');
   if cisize_greater
   then FreeMem(pgetmem);

   Show_Vsam:=true;
   MM.Lines.EndUpdate;
   screen.Cursor:=crDefault;
   F_Show.Caption:=DM.TK_F.FieldByName('name').AsString+'('+DM.TK_PDS.FieldByName('name').AsString+')     recs= '+ IntToStr(recs);
end;



procedure TF_Show.Showrecnum1Click(Sender: TObject);
begin
  with Sender as TMenuItem do Checked:=not Checked;
  if proctype='VSAM'
  then Show_Vsam
  else Show_data_text;
end;







function get_idx_entry(pb:pbyte;ilen,vlen:word;var idx:t_idx_entry):boolean;
begin
   Result:=true;
   idx.ix_F:=0;idx.ix_L:=0;idx.ix_P:=0;
   // ex $00 $0A $07
   if vlen=1 then // 1 byte  vertical pointer
   begin
      idx.ix_F:=pb^;
      inc(pb);
      idx.ix_L:=pb^;
      inc(pb);
      idx.ix_P:=pb^;
   end else
   if vlen=3 then // 2 bytes verticallength
   begin
      idx.ix_F:=pb^;
      inc(pb);
      idx.ix_L:=pb^;
      inc(pb);
      idx.ix_P:=pb^ * 256;
      inc(pb);
      idx.ix_P:=idx.ix_P + pb^;
   end else
   if vlen=7 then // 3 bytes vertical length
   begin
      idx.ix_F:=pb^;
      inc(pb);
      idx.ix_L:=pb^;
      inc(pb);
      idx.ix_P:=pb^ * 256 * 256;
      inc(pb);
      idx.ix_P:=idx.ix_P + (pb^ * 256);
      inc(pb);
      idx.ix_P:=idx.ix_P + pb^;
   end;
end;



function hext_to_string(pb:pbyte;len:integer):string;

begin
   Result:='';
   dec(pb,len);
   while len>0 do
   begin
      Result:=Result+hexa_tab[pb^ shr 4]+hexa_tab[pb^ and 15];
      dec(len);
      inc(pb);
   end;
end;




procedure list_sections(pb:pbyte;idx:t_vsam_idx;MM:TMemo);
var idx_e: t_idx_entry;
    prev_section:word;
begin
   inc(pb,idx.IXHSEO);
   get_idx_entry(pb,idx.IXHFLPLN,idx.IXHPTLS,idx_e);

   dec(pb,idx_e.ix_L);
   dec(pb,2);
   prev_section:=pb^ * 16;
   inc(pb);
   inc(prev_section,pb^);
   MM.Lines.Add('section at '+IntToStr(prev_section))
end;





procedure TF_Show.IndexClick(Sender: TObject);
var
    pb : PByte;
    ckd : tckd;
    v_idx:t_vsam_idx;
    ixe:t_idx_entry;
    sumL,fileno,seqno,
    ilen,xlen:integer;
    s,prima:string;
    pw:^word;
    ixs:array of t_idx_entry;
    exts:p_resume;

begin
   MM.Lines.Clear;
   fileno:=DM.TK_F.FieldByName('dscb').AsInteger;
   seqno:=0;
   exts:=DM.get_file_extents(fileno,seqno);
   if exts=nil then exit;



   ckd.cyl:=exts.l_cyl;
   ckd.trk:=exts.l_trk;
   ckd.nrec:=1;


   MM.Lines.BeginUpdate;
   pb:=get_record(fileno,@ckd);

   while pb<>nil do
   begin

      move(pb^,v_idx,sizeof(t_vsam_idx));
      v_idx.IXHLL:=swap(v_idx.IXHLL);
      v_idx.IXHFSO:=swap(v_idx.IXHFSO);
      v_idx.IXHLEO:=swap(v_idx.IXHLEO);
      v_idx.IXHBRBA:=Swap4(v_idx.IXHBRBA);
      v_idx.IXHHP:=Swap4(v_idx.IXHHP);
      v_idx.IXHSEO:=swap(v_idx.IXHSEO);
      v_idx.IXHHBACK:=swap4(v_idx.IXHHBACK);

      if v_idx.IXHLL=0 then
      begin
         inc(ckd.nrec);
         pb:=get_record(fileno,@ckd);
         Continue;
      end;

      //if v_idx.IXHFLAG=0
      //then break; // empty??




      if not v_idx.IXHFLPLN in [3,4,5] then
      begin
         MM.Lines.EndUpdate;
         ShowMessage('fail IXHFLPLN - not 3,4,5');
         exit;
      end;

      //screen.Cursor:=crHourGlass;



      inc(pb,v_idx.IXHSEO);
      if pb=nil then break;
      if pb^=0 then;


      inc(pb,v_idx.IXHLEO);  // last
      if pb^=0 then;

      ilen:=v_idx.IXHLL - v_idx.IXHFLPLN; // --> first entry end
      ilen:=ilen -v_idx.IXHSEO; // -- init section

      if ilen=0 then;


      inc(pb,v_idx.IXHLL);
      dec(pb,v_idx.IXHFLPLN); // --> first entry = 000A00

      sumL:=ilen;

      // valid for all CI
      xlen:=3; // default ptls=1
      case v_idx.IXHPTLS of
            3 : xlen:=4;
            7 : xlen:=5;
      end;
      prima:='';


      MM.Lines.Add(format('C %.4d  T%.2d  R%.2d  DL %d',
         [ckd.cyl,ckd.trk,ckd.nrec,ckd.read]));

      s:=format(' ll=%d pln=%d plts=%d rba=%.6X hp=%.4d nxt=%d lv=%d flag=%d fso=%d leo=%d seo=%d back=%X',
      [
      v_idx.IXHLL,
      v_idx.IXHFLPLN,
      v_idx.IXHPTLS,
      v_idx.IXHBRBA,
      v_idx.IXHHP,
      v_idx.IXHFSNXT,
      v_idx.IXHLV,
      v_idx.IXHFLAG,
      v_idx.IXHFSO,
      v_idx.IXHLEO,
      v_idx.IXHSEO,
      v_idx.IXHHBACK]);
      MM.Lines.Add('');
      MM.Lines.Add(s);
      MM.Lines.Add('');

        // +'  level ='+IntToStr(v_idx.IXHLV)+' rba='+IntToHex(v_idx.IXHBRBA,8)+' hp='+IntToHex(v_idx.IXHHP,8)+' ptls='+IntToStr( v_idx.IXHPTLS)+#10);

      // level 1 --> (1017, 3, 1, 0,      1024,    0, 1, 0, 24, 462, 959, 0)
      // level 1 --> (1017, 3, 1, 737280, 3072,    0, 1, 0, 24, 462, 960, 0)
      // level 2 --> (1017, 5, 7, 0,         0,    0, 2, 0, 24, 968, 968, 0)

      //count_idx:=0;

      while v_idx.IXHLV>0 do
      begin

         get_idx_entry(pb,v_idx.IXHFLPLN,v_idx.IXHPTLS,ixe);

         if ixe.ix_F=0 then;
         if (ixe.ix_F+ixe.ix_L)=0 then
         begin

            if ixe.ix_P>0 then
            begin
               s:=copy('last                                                            ',1,30);
               MM.Lines.Add('  '+s+
                  format('     idx F=%.3d  L=%.3d  P=%.3d ',[ixe.ix_F,ixe.ix_L,ixe.ix_P+1]));
            end;
            break; // last
         end;


         if Showhex1.Checked
         then s:=hext_to_string(pb,ixe.ix_L)
         else s:=DM.ebcdic_ascii_ptr(pb,ixe.ix_L,0);

         if prima=''
         then prima:=s
         else s:=copy(prima,1,ixe.ix_F)+s;

         prima:=s;

         s:=copy(s+'                                                            ',1,30);
         MM.Lines.Add('  '+s+
               format('     idx F=%.3d  L=%.3d  P=%.3d ',[ixe.ix_F,ixe.ix_L,ixe.ix_P+1]));

         dec(pb,ixe.ix_L);

         SetLength(ixs,high(ixs)+2);
         ixs[high(ixs)]:=ixe;

         if sumL<1 then
         begin
            if s='' then ;
            dec(pb,2);
            pw:=pointer(pb);
            ilen:=swap(pw^);
            suml:=ilen;

            dec(pb,xlen);
            dec(sumL,ixe.ix_L);
            dec(sumL,xlen);
            dec(sumL,2);

            //xbuf:=integer(pb)- integer(pf)+10+9+10;
            //s:=IntToHex(xbuf,4)+'     '+IntToStr(ilen);
            //if s='' then ;
         end
         else
         begin

            dec(pb,xlen);
            dec(sumL,ixe.ix_L);
            dec(sumL,xlen);
         end;
      end;
      inc(ckd.nrec);
      pb:=get_record(fileno,@ckd);
   end;
   MM.Lines.EndUpdate;
   screen.Cursor:=crDefault;
end;

{ examples

 000400  1388C3C5 C7030E28 D7C9D7C5 40000000 000FA0C9 E7D4C9F3 F3C40312 27D6D7C5   .hCEG...PIPE ......IXMI33D...OPE
 000420  D9400000 00000303 0A26D9D6 C1D90000 00000104 0925D4D8 40404000 0000000F   R ........ROAR........MQ   .....
 000440  A0C3E2D8 C3C3D603 1124009D D3C9E2E3 40000000 00000503 0B23E2C3 40040322   .CSQCCO.....LIST .........SC ...
 000460  C9D50302 21C5C4C6 40400000 00001318 030B20C3 E3C74000 00000017 70C3E2D7   IN...EDF  .........CTG ......CSP
 000480  040D1FC4 C2C3E3D3 00000000 1388C3C4 C2D6030F 1EF70000 00001388 C2D9C7F7   ...DBCTL.....hCDBO...7.....hBRG7
 0004A0  070B1DF4 00000000 0007061C F2000000 000FA0C4 C6C8D407 0B1B0072 C3D6D4D7   ...4........2......DFHM.....COMP
 0004C0  F1000000 001388C3 C1030D1A C3D6D4D7 C1000000 0000030A 19C1C9F6 F2400000   1.....hCA...COMPA........AI62 ..
 0004E0  000010ED C3C2030D 18F0E5E9 40000000 00000504 0A17E6C2 E2D50000 00000FA0   ....CB...0VZ .........WBSN......
 000500  C4C6C85B E6C2E2C2 041216D7 C6D3C100 00000013 88D7C104 0C15C9E5 D7D30000   DFH$WBSB...PFLA.....hPA...IVPL..
 000520  21040714 C7D5C9E3 00000000 0005040A 13D3C9E5 00000000 0FA0
 C4C6

 C85BC4D3C1     051012
 0092

 C4C6C85BC4C2F240000000000FA0C4E2D5F8C3C3F1  001511
 E3E7
 000560  E3000000 00000508 10C3C6C3 E2000000 000FA0C9 C3C35BD7 040F0FC2 D9404000   T........CFCS......ICC$P...BR  .
 000580  0000000F 04090EC4 C6C85BC1 C6D3C100 00000003 E8C4C6C8 5BC1C7D2 00150D


 C9C2D4F3D4C2C50E070C 11000B

 C8C7  12020A
 C5E7  120209

 0072

 C3C5C54040404040000000000FA0C5C4C3E4C1C9C5   001508  <--- SEO
 E2D3C6           120307
 C6D3             120206
 C5C4C35BC5D2C5D2 0E0805
 F3C5C5           110304
 C9C3C5           120303
 E45BC5C5         100402
 E2C1             120201
 C3C5C54040404040000000000FA0C3C5C5E2C4D3C7  PB --->  001500       CEE   ....CEESDLG...

























$00 $02 $00 $00 $03 $F9 $03 $F9 $00 $00 $06 $E0 $00 $0B $02 $00 $04 $00 $03 $F9 $03 $01 $00
$03 $C0 $00 $00 $00 $00 $00 $00 $00 $00 $00 $01 $00 $00 $30 $03 $5B $03 $DB $3B $3A $39 $38
$37 $36 $35 $34 $33 $32 $31 $30 $2F $2E $2D $2C $2B $2A

Each section is preceded by a 2-byte field that gives the displacement from the control information
in the leftmost index entry in the section to the control information in the leftmost index entry
in the next section (to the left). The last (leftmost) section's 2-byte field contains 0s.

         00000A  - bloco 10 free..... <--- IXHLEO
F4F5 		070209
F3F4F2	070308
001A    (3B8)
F0F0F0F0F0F0F4F2F2F1  000A07  <---- IXHSEO inicio da ultima secao
F4F1F0F5	060406
F9F9F3	070305
F8F7F8	070304
F7F6F7	070303
F6F4F2	070302
F4F1F4	070301
F0F0F0F0F0F0F3F1F8F6	000A00


IXHSEO -> $00 $0A $07 $F4 $F1 $F0 $F5 $06 $04



 000000  00053600 07053600 07000000 08000000 00000000 00053600 07010004 0003F903   ..............................9.
 000020  01000000 00000000 00000000 00010000 24025302 632C2B2A 29282726 25242322   ................................
 000040  21000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000   ................................



 000240  .
 000260  00000000 00000000 00000000 00000000 00001400 10E7E8E9 D3C9E2E3 4000001D   .....................XYZLIST ...
 000280  000B20E6 C5C24040 00000000 0FA0C4C6 C8E6C2C1 C8031206 E3C5D9D4 40000000   ...WEB  ......DFHWBAH...TERM ...
 0002A0  00123AD3 F2D4F403 0F04E2C9 03020BD7 C9D7C540 00000000 0FA0C4C6 C8D7C9E2   ...L2M4...SI...PIPE ......DFHPIS
 0002C0  D5F10313 05D4D840 40400000 00001388 C3D2C4D3 030F03D3 C9E2E340 00003103   N1...MQ   .....hCKDL...LIST ....
 0002E0  0802C9E2 C3404000 0000000F A0C4C6C8 C3D9E240 03120EC5 C4C64040 00000000   ..ISC  ......DFHCRS ...EDF  ....
 000300  1318030B 01C4C3E3 C7400000 00001770 C3D1030D 13F70000 00001388 C3E6C2F6   .....DCTG ......CJ...7.....hCWB6
 000320  070B12F3 00000000 1388C3E2 D7D8070B 11D6D4D7 F2000000 00000504 0A07C3D3   ...3.....hCSPQ...OMP2.........CL
 000340  030208C1 C4C5E340 00000000 00030A0F E6C5C240 00000000 0FA0C4C6 C8F0E6C2   ...ADET ........WEB ......DFH0WB
 000360  C804110D D7C6D3C1 00000000 1388D7C1 040C0AC6 C9D3C100 00000003 040909C4   H...PFLA.....hPA...FILA........D
 000380  C2F24000 0000000F A0C4E2D5 F8C3D7F7 04110CC3 D5E2D300 00000011 040910C2   B2 ......DSN8CP7...CNSL........B
 0003A0  D4E2D700 00000013 88D7D7D2 040D15C4 C6C85BC1 C3C3E300 00000003 20000E1D   MSP.....hPPK...DFH$ACCT.........
 0003C0  E9D11102 1CE8C8D1 13031BE4 C5C3C511 041AE3C8 120219C6 C9C5E812 0418C5C4   ZJ...YHJ...UECE...TH...FIEY...ED
 0003E0  C35BC5C6 C5D10E08 177CC611 0216E45B C5E7C5D1 10061EE3 C1C21203 1FC3C5C5   C$EFEJ...@F...U$EXEJ...TAB...CEE

 000400  40404040 40000000 000FA0C3 C5C5E2C5 C1E3C800 16000003 F903F900 00053600        ......CEESEATH.....9.9.....
 000420  07020004 00000000 00000000 00000000 00000000 00000000 00000000 00000000   ................................





 000400  40404040 40000000 000FA0C3
 C5C5E2C5C1E3C8   0016 000003

           CEESEATH.....9.9.....
 F903F900 00053600        ......CEESEATH.....9.9.....
 000420  07020004 00000000 00000000 00000000 00000000 00000000 00000000 00000000   ................................


 pb = $00 $16 $00 $00 $03 $F9 $03 $F9


 CEE     ......CEESDLG     idx F=0  L=21 P=0
CEE     ......CEESSA     idx F=18  L=2 P=1
CEE     ......CEU$EE     idx F=16  L=4 P=2
CEE     ......CEESICE     idx F=18  L=3 P=3
CEE     ......CEE3EE     idx F=17  L=3 P=4
CEE     ......EDC$EKEK     idx F=14  L=8 P=5
CEE     ......CEESFL     idx F=18  L=2 P=6
CEE     ......CEESSLF     idx F=18  L=3 P=7





--->          2F49     00B4
--->          2E93     00C6



 002BC0  00000000 00000000 00

(2BC9)   --> 66                 (DIF 10)  (LEO = 2BC9)

            0000007B
C960        0102007A
E6C5C240    00040079
C9E3        01020078
C5D9C140C8  01050077
E5C1D5C4C140   00060076
E4C4           00020075
C8C9C1C7D640C1 01070074
 E3C1          00020073
               01000072
               02000071
 C9D3E5C1      01040070   A....TA............ILVA....ERGIO
 C5D9C7C9D640C4      0107006F
 E4D3D640C4          0205006E

 0070       (2C2F)   ---> C6  (DIF 1 )

 E2C1D5 C4D9C140D3   0008006D    D...?ULO D...>..SANDRA L..._SAN  (109)
 E2C1D5              0203006C
 D5C1D3C440          0205006B
 C4D9C9C7D640D7      0207006A
 D6C2C5              01030069    ...%NALD ...,DRIGO P....OBE....I
 C9C3C1D9C4D640D5    0 080068
 D640C3              05030067
 D5C1E3C140C6        02060066 CARDO N....O C....NATA F....INAL
 C9D5C1D3C4D640C6    02080065
 C5C7C9D5C140C3C5    01080064
 D9C1C9              00030063
                     01000062    DO F....EGINA CE....RAI........S
E2E3D640C7           02050061
D6D3C9               01030060
D7                   0601005F
E4D3D640C3C1         0206005E
D7C1E3D9C9C3C9C140C3 000A005D
D6E5C1D3D3C540D3C5C1 000A005C
D5C9D3               0003005B
E4                   0101005A
C9C7                 01020059
E4D9D640D1           02050058

 00C7             (2CF5)  ---> DF   (DIF 6)

 D4C1D9D3C5D5C540C3     00090057     (2D00)
 D5C140C3C1             04050056
 E5                        06010055
 D3E4C3                    06030054
 C540D3D6E4D9C4C5E240C3    070B0053
 C4C1E240C4D6D9C5E240D7C5  060C0052
 C3C1                      06020051
 C9C140C1C9                03050050
 D6D5                      0402004F
 C9D640C1                  0404004E
                           0800004D
 D9C3C5D3D640C3            0207004C
 D4C1C7C1D3C8              0006004B
 E940C6C5D9D5C1D5C4D640C1  030C004A    ...<MAGALH....Z FERNANDO A....IS
 C9E240C3                  02040049
 E4C3C9C1D5C1              01060048
 D6D9C5D5C1                01050047
 C9C4C5                    01030046    C....UCIANA....ORENA....IDE....
 D6D5C1D9C4D640C4D640C3C1D9D4D640D4C5D5C4C5E24040  02180045
 C5C9D3C140C1     01060044
 D3C1C4           00030043
 D2C1D9           00030042

 00D9       (2DD4)     ---> BF     (DIF 7)

 D1E4D3           00030041    (2DD9)
 D3C9C1D5C140C4   02070040
 E4C1             0102003F
 D4               0501003E
 C6               0501003D
 E2C540C1D5E3D6D5C9D640C4 020C003C
 D6C1D640D3       0105003B
 C5E2E2           0103003A
 D1C1D4           00030039
 E9C1C2C5D340     01060038
 C9D4C7           00030037
                  02000036
 D3               02010035
 C8C5C2           00030034   ABEL ....IMG........L....HEB....
 E2E3C1E5D640C8   02070033
 E4C9D3C8C5D9D4C540C2   010A0032
 D3C1E4C3C9C140D2       01080031
 C9D3C2                 01030030
 C7C5D6                 0003002F
 D9C5C4C5D9C9C3D640C2   010A002e   K....ILB....GEO....REDERICO B...
 D640C1                 0503002D
 D3C1E5C9C140C1         0107002C

 00C6 <--------------- (2E93)  -> B6  (DIF 2)


 C6C5D9D5C1D5C4D640C1   000A002B   92    (2E95)    (2E9E--> 000A002B)
 C5D3                   0102002A
 C6C1C2C9C1             00050029
 E4C4C5                 01030028
 D4C9                   01020027
 C9E2                   02020026
 D3C1                   01020025
 E4C1D9C4D640C7         02070024
 C5C4C5                 00030023
 C9D4                   01020022
 C5D3C1                 01030021
 C4C1D5                 00030020
 E4                     0101001F
 D9C9E2E3C9C1D5C540C2   010A001E
 E2E3C1                 0303001D
 E2C1                   0802001C
 D7C1E4D3C14040         0807001B
 D3C5                   0802001A
 C7C5D4                 08030019
 C3C1                   08020018
 D5C440C5C440C1D4       02080017
 D6D4C5D9C3C9C1D340C4   010A0016

 00B4    (2F49)

 C3D3C5C2C5D940C3          00080015    <---- SEO     (2F53)
 D3C1E4C4C9D640C101002F    60080014
 C6                        01010013
 D5E3D9D640C4C540C5        02090012
 C5C3                      01020011
 D4C5D4                    03030010
 C3C1D9D3D6E240C1D3C2C5D9E3D640C6   0010000F
 D9E4D5D640C4                       0106000E   ..CARLOS ALBERTO F....RUNO D....
 C2C5C1                             0003000D
 E4C7E4E2E3D640C3                   0108000C
 D9D3                               0102000B
 D3C9                               0802000A
 E3D6D5C9D640C3C1C5                 02090009
 D9C5C140C7D6                       03060008     ONIO CAE....REA GO....DERSON P..
 C4C5D9E2D6D540D7                   02080007
 D7C1E4D3C140D9                     04070006
 D5C140C3D3                         01050005
 D4C1C4                             01030004  ..PAULA R....NA CL....MAD....EXA
 C5E7C1                             02030003
 D3C2                               01020002
 C6                                 01010001
 C1C4C5                             00030000

 002F F92FF900 0006E000   ....LB....F....ADE......9.9...\.



 (3012)


Deusdedit B Silva                                            000000369300000010570000000000



 000400  1388C3C5 C7030E28 D7C9D7C5 40000000 000FA0C9 E7D4C9F3 F3C40312 27D6D7C5   .hCEG...PIPE ......IXMI33D...OPE
 000420  D9400000 00000303 0A26D9D6 C1D90000 00000104 0925D4D8 40404000 0000000F   R ........ROAR........MQ   .....

 000440  A0C3E2D8 C3C3D603 1124

 009D


 D3C9E2E340000000000005  030B23  (457 ->)

 E2C3 40040322   .CSQCCO.....LIST .........SC ...
 000460  C9D50302 21C5C4C6 40400000 00001318 030B20C3 E3C74000 00000017 70C3E2D7   IN...EDF  .........CTG ......CSP
 000480  040D1FC4 C2C3E3D3 00000000 1388C3C4 C2D6030F 1EF70000 00001388 C2D9C7F7   ...DBCTL.....hCDBO...7.....hBRG7
 0004A0  070B1DF4 00000000 0007061C F2000000 000FA0C4 C6C8D407 0B1B

 0072

 C3D6D4D7F1000000001388C3C1  030D1A (4c9)

 C3D6D4D7 C1000000 0000030A 19C1C9F6 F2400000   1.....hCA...COMPA........AI62 ..
 0004E0  000010ED C3C2030D 18F0E5E9 40000000 00000504 0A17E6C2 E2D50000 00000FA0   ....CB...0VZ .........WBSN......
 000500  C4C6C85B E6C2E2C2 041216D7 C6D3C100 00000013 88D7C104 0C15C9E5 D7D30000   DFH$WBSB...PFLA.....hPA...IVPL..
 000520  21040714 C7D5C9E3 00000000 0005040A 13D3C9E5 00000000 0FA0C4C6 C85BC4D3   ....GNIT.........LIV......DFH$DL
 000540  C1051012

 0092

 C4C6C85BC4C2F240000000000FA0C4E2D5F8C3C3F1  001511 (55B   ->)

 E3E7   A....kDFH$DB2 ......DSN8CC1...TX
 000560  E3000000 00000508 10C3C6C3 E2000000 000FA0C9 C3C35BD7 040F0FC2 D9404000   T........CFCS......ICC$P...BR  .
 000580  0000000F 04090EC4 C6C85BC1 C6D3C100 00000003 E8C4C6C8 5BC1C7D2 00150D

 C9C2D4F3D4C2C5   0E070C
                  11000B
 C8C7 12020A
 C5E7 120209

 0072

 C3C5C54040404040000000000FA0C5C4C3E4C1C9C5  001508     (5cd --> 001508)
 E2D3C6           120307
 C6D3             120206
 C5C4C35BC5D2C5D2 0E0805
 F3C5C5           110304
 C9C3C5           120303
 E45BC5C5         100402
 E2C1             120201

 C3C5C54040404040000000000FA0C3C5C5E2C4D3C7  001500 <---SEO


 0005 F905F900 0006E000   E     ......CEESDLG.....9.9...\.
 000620  0E020006 00000000 00000000 00000000 00000000 00000000 00000000 00000000   ................................

}

procedure TF_Show.Find1Click(Sender: TObject);
var col:integer;
begin

   if Sender<>nil then
   if not InputQuery('Find','case sensitive',find_string)
   then exit;

   inc(find_offset);
   col:=PosEx(find_string,MM.Text,find_offset);
   find_offset:=col;

   if col>0 then
   begin
      MM.SelStart := col;
      MM.SelLength := Length(find_string);
      MM.SetFocus; // necessary so highlight is visible
   end;
end;

procedure TF_Show.Save1Click(Sender: TObject);
var fn:string;
begin

   if proctype='VSAM'
   then fn:=DM.temp_folder+DM.TK_F.FieldByName('name').AsString+'.TXT'
   else fn:=DM.temp_folder+DM.TK_F.FieldByName('name').AsString+'('+DM.TK_PDS.FieldByName('name').AsString+').TXT';
   MM.Lines.SaveToFile(fn);
   ShowMessage('Saved file '+fn);
end;

procedure TF_Show.SaveBinClick(Sender: TObject);
var fn:string;
begin
   if proctype<>'PDS' then
   begin
      ShowMessage('Only for PDS member');
      exit;
   end;
   fn:=DM.temp_folder+DM.TK_F.FieldByName('name').AsString+'('+DM.TK_PDS.FieldByName('name').AsString+').DAT';
   DM.save_binary(fn);
end;

end.
