unit DasdBR7_dump;
{

   create, fill and show bitmap data dump
   show one track or screen lines capacity



}

interface

uses
  DasdBR7_DM,
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Menus;

type
  TF_Dump = class(TForm)
    IM: TImage;
    Label1: TLabel;
    MainMenu1: TMainMenu;
    Cyl1: TMenuItem;
    Trk1: TMenuItem;
    Quit1: TMenuItem;
    Options1: TMenuItem;
    Offsetinmouse1: TMenuItem;
    Nextnonzerotrak1: TMenuItem;
    Save1: TMenuItem;
    Save: TMenuItem;
    Withtrkheader1: TMenuItem;
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Quit1Click(Sender: TObject);
    procedure Cyl1Click(Sender: TObject);
    procedure Trk1Click(Sender: TObject);
    procedure IMMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormResize(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure SaveClick(Sender: TObject);
  private
    procedure dump_track_data(init_page:boolean);
    procedure WMEraseBkgnd(var m: TWMEraseBkgnd); message WM_ERASEBKGND; // flicker free
  public



  end;

var
  F_Dump: TF_Dump;

  ckd : tckd;           // actual cyl,trk,nrec
  line_offset:integer;  // offset in screen
  bm : TBitmap;         // graphics data
  mark_char_at,char_len,x_save :integer;

  first_dump_rec:byte;  // for left/righ move on screen

  pagerec_index:integer;
  pagerecs:array[0..255] of byte;

  no_more_data:boolean;
  line_len:integer=128;
  line_hei:integer=16;


implementation

uses DB;



{$R *.DFM}


// input global :  ckd    and   line offset

procedure TF_Dump.dump_track_data(init_page:boolean);
var ss,h1,h2,cab,filename,fileEOF : string;
    line,col,trk_offset,
    i,k,slen,perc_free: integer;
    hrec : rec_header;
    pb,pw:pByte;
begin


   line:=0;
   col:=0;
   no_more_data:=false;
   if init_page
   then ckd.nrec:=0;

   bm.Canvas.Pen.Color:=clWhite;
   bm.Canvas.Brush.Color:=clBlack;
   bm.Canvas.FillRect(Rect(0,0,bm.Width,bm.Height));
   first_dump_rec:=ckd.nrec;

   filename:=DM.get_filename_from_cyl_trk(ckd.cyl,ckd.trk);

   //pb:=DM.read_raw_track(@ckd);        // hercules has cache for track
   pb:=DM.direct_read_cyl_trk(@ckd);

   if pb=nil
   then exit;

   DM.find_next_record(pb,ckd.nrec,@hrec);

   if hrec.cyl=$FFFF then             // ajust page records if not end of track
   begin
      //exit;
   end
   else
   begin
      if ckd.nrec=0
      then pagerec_index:=0
      else inc(pagerec_index);
      pagerecs[pagerec_index]:=ckd.nrec;
   end;


   trk_offset:=0;
   i:=0;

   while true do
   begin
      trk_offset:=DM.find_next_record(pb,ckd.nrec,@hrec);

      if hrec.cyl=$FFFF
      then break;
      if (hrec.klen=0) and (hrec.dlen=0)
      then fileEOF:=' -----> EOF'
      else fileEOF:='';

      cab:=format('C %d T %d R %d    KL %d    DL %d  Ofs %d [%X]   Track offset [%X] %s',
         [hrec.cyl,hrec.head,hrec.rec,hrec.klen,hrec.dlen,line_offset,line_offset,trk_offset,fileEOF]);

      if i>0 then
      inc(line,line_hei);              // always show track header
      if (hrec.klen=0) and (hrec.dlen=0)
      then bm.Canvas.Font.Color:=clFuchsia
      else bm.Canvas.Font.Color:=clWhite;
      bm.Canvas.TextOut(col,line,cab);
      inc(line,line_hei);



      ss:='';
      h1:='';h2:='';

      pw:=pb;                       // work pointer = pb + current offset
      inc(pw,trk_offset);
      inc(pw,sizeof(rec_header));    //+hrec.klen+hrec.dlen);
      inc(pw,line_offset);

      slen:=hrec.dlen+hrec.klen;    // line dump len...
      slen:=slen-line_offset;



      if slen>0 then                    // dump if data len < offset
      begin
         ss:=DM.ebcdic_ascii_ptr(pw,slen,line_len);

         SetLength(h1,line_len);
         SetLength(h2,line_len);

         FillMemory(@h1[1],line_len,32);
         FillMemory(@h2[1],line_len,32);

         for k:=1 to slen do
         begin
            if k<=line_len then
            begin
               h1[k]:=hexa_tab[(pw^ shr 4)];
               h2[k]:=hexa_tab[pw^ and 15];
            end;
            inc(pw);
         end;

         bm.Canvas.Font.Color:=clAqua;
         bm.Canvas.TextOut(col,line,ss);
         inc(line,line_hei);

         bm.Canvas.Font.Color:=clLime;
         bm.Canvas.TextOut(col,line,h1);
         inc(line,line_hei);

         bm.Canvas.TextOut(col,line,h2);
         inc(line,line_hei);
      end
      else
      begin
         inc(line,line_hei);
      end;

      if line+(line_hei*5)>=bm.Height
      then break;

      inc(ckd.nrec);
   end;


   if hrec.cyl<>$FFFF then    // next track = end of track?
   begin
      DM.find_next_record(pb,ckd.nrec,@hrec);
   end;
   if hrec.cyl=$FFFF then
   begin
      no_more_data:=true;
      inc(trk_offset,sizeof(rec_header)+sizeof(t_CKDDASD_TRKHDR));
      perc_free:=100 - (trk_offset * 100 div DM.volume_data.trk_size);
      inc(line,line_hei);
      ss:=format('<End of track at %d [%X] free %d %%>',[trk_offset,trk_offset,perc_free]);
      bm.Canvas.Font.Color:=clSilver;
      bm.Canvas.TextOut(col,line,ss);
   end;

   Caption:='MVS EXPLORER - DUMP (F4 - Left F5 - Rigth)    ['+filename+']';


   IM.Picture.Assign(bm);
   Label1.Caption:='';

   if Offsetinmouse1.Checked then
   if (mark_char_at>line_offset) and
      (mark_char_at<(line_offset+line_len)) then
   begin
      IM.Canvas.Pen.Color:=clYellow;
      IM.Canvas.MoveTo(x_save,0);//,x+char_len,y+line_hei*3));
      IM.Canvas.LineTo(x_save,IM.Height);//,x+char_len,y+line_hei*3));
      IM.Canvas.MoveTo(x_save+char_len,IM.Height);//,x+char_len,y+line_hei*3));
      IM.Canvas.LineTo(x_save+char_len,0);//,x+char_len,y+line_hei*3));

      i:=(x_save div char_len)+line_offset;
      Label1.Caption:=format('offset:  %5d (%4X)',[i,i]);
   end;
end;










procedure TF_Dump.FormShow(Sender: TObject);
var
    fileno,seqno:integer;
    exts:p_resume;

begin
   if DM.TK_F.IsEmpty then close();


   Label1.Caption:='';
   fileno:=DM.TK_F.FieldByName('dscb').AsInteger;
   seqno:=0;
   exts:=DM.get_file_extents(fileno,seqno);
   if exts=nil then exit;


   ckd.cyl:=exts.l_cyl;
   ckd.trk:=exts.l_trk;
   ckd.nrec:=0;

   line_offset:=0;
   first_dump_rec:=0;

   OnResize:=FormResize;      // may not fire event resize....

end;

function get_next_non_zero():boolean;   // CTMG07 pds deletado em cyl 1155 trk 13   / 1446/0
var pb:PByte;
    hrec:p_rec_header;
begin
   Result:=false;
   if ckd.cyl>=DM.volume_data.num_cyl then   // show lasst cyl
   begin
      ckd.trk:=0;
      Result:=true;
      exit;
   end;


   while true do
   begin
      pb:=DM.direct_read_cyl_trk(@ckd);
      //pb:=DM.read_raw_track(@ckd);        // hercules has cache for track

      if pb=nil then exit;
      hrec:=pointer(pb);
      inc(pb,hrec^.klen+hrec.dlen+sizeof(rec_header));

      hrec:=pointer(pb);

      if hrec.dlen<>0 then
      begin
         Result:=true;
         break;
      end;
      inc(ckd.trk);
      if ckd.trk=DM.volume_data.trk_per_cyl then
      begin

         if ckd.cyl>=DM.volume_data.num_cyl
         then break;
         inc(ckd.cyl);
         ckd.trk:=0;
      end;

   end;
   if ckd.cyl>=DM.volume_data.num_cyl then
   begin
      ckd.cyl:=DM.volume_data.num_cyl;
      ckd.trk:=0;
      Result:=true;
   end;   

end;

procedure TF_Dump.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
    update_data:boolean;


begin

   update_data:=false;

   case key of
   VK_ESCAPE: ModalResult:=mrRetry;

   VK_LEFT:
      begin
         if pagerec_index>0 then
         begin
            dec(pagerec_index);
            ckd.nrec:=pagerecs[pagerec_index];
            dec(pagerec_index);
            update_data:=true;
         end;
       end;

   VK_RIGHT:
      begin
         if no_more_data
         then exit;
         inc(ckd.nrec);
         update_data:=true;
       end;

   VK_DOWN: begin
          inc(ckd.trk);
          ckd.nrec:=0;
          if ckd.trk=DM.volume_data.trk_per_cyl then
          begin
             inc(ckd.cyl);
             ckd.trk:=0;
          end;

          if Nextnonzerotrak1.Checked then
          begin
             screen.Cursor:=crHourGlass;
             update_data:=get_next_non_zero();
             screen.Cursor:=crDefault;
          end
          else update_data:=true;
       end;

   VK_UP:
      begin
         if ckd.trk=0 then
         begin
            if ckd.cyl=0 then exit;
            dec(ckd.cyl);
            ckd.trk:=14;
            ckd.nrec:=0;
            update_data:=true;
         end
         else
         begin
            dec(ckd.trk);
            ckd.nrec:=0;
            update_data:=true;
         end;
       end;
     VK_F4 : begin
              if line_offset>=line_len then
              begin
                 ckd.nrec:=first_dump_rec;   // dump again...
                 dec(line_offset,line_len);
                 update_data:=true;
              end;
           end;
     VK_F5: begin
               ckd.nrec:=first_dump_rec;     // dump again
               inc(line_offset,line_len);
               update_data:=true;
            end;
   end;

   if update_data then
   begin
      dump_track_data(false);
   end;
end;


procedure TF_Dump.FormCreate(Sender: TObject);
begin
   bm:=TBitmap.Create;
   bm.Dormant;
end;


procedure TF_Dump.FormDestroy(Sender: TObject);
begin
   bm.Free;
end;

procedure TF_Dump.Quit1Click(Sender: TObject);
begin
  ModalResult:=mrok;
end;

procedure TF_Dump.Cyl1Click(Sender: TObject);
var ss : string;
    i,newcyl  : integer;
begin
   ss:=IntToStr(ckd.cyl);
   if not InputQuery('Seek cyl','',ss) then exit;
   val(ss,newcyl,i);
   if newcyl>DM.volume_data.num_cyl then
   begin
      ShowMessage('error - cyl invalid');
      exit;
   end;
   ckd.cyl:=newcyl;
   ckd.trk:=0;
   ckd.nrec:=0;
   dump_track_data(true);
end;

procedure TF_Dump.Trk1Click(Sender: TObject);
var ss : string;
    i,newtrk  : integer;

begin
   ss:=IntToStr(ckd.trk);
   if not InputQuery('Seek Track','',ss) then exit;
   val(ss,newtrk,i);
   if newtrk>=DM.volume_data.trk_per_cyl then
   begin
      ShowMessage('error - trk invalid');
      exit;
   end;

   ckd.trk:=newtrk;
   ckd.nrec:=0;
   dump_track_data(true);
end;


procedure TF_Dump.IMMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
   if not Offsetinmouse1.Checked then exit;
   IM.Picture.Assign(bm);
   mark_char_at:=(X div char_len)+line_offset;
   Label1.Caption:=format('offset:  %5d (%4X)',[mark_char_at,mark_char_at]);

   //x:=mark_char_at*char_len;
   x_save:=X;
   IM.Canvas.Pen.Color:=clYellow;
   IM.Canvas.MoveTo(x,0);
   IM.Canvas.LineTo(x,IM.Height);
   IM.Canvas.LineTo(x+char_len,IM.Height);
   IM.Canvas.LineTo(x+char_len,0);
end;

procedure TF_Dump.WMEraseBkgnd(var m: TWMEraseBkgnd);
begin
   m.Result := LRESULT(1);
end;


procedure TF_Dump.FormResize(Sender: TObject);
begin

   bm.Width:=IM.Width;
   bm.Height:=IM.Height;
   bm.Canvas.Font.size:=10;
   bm.Canvas.Font.Name:='SYSTEM';
   bm.Canvas.Font.Pitch:=fpFixed;
   bm.Canvas.Font.Style:=[fsBOld];
   bm.Canvas.Font.Style:=[];
   char_len:=bm.Canvas.TextWidth('0');
   line_len:=(bm.Width div char_len) -2;
   dump_track_data(true);

end;

procedure TF_Dump.FormClose(Sender: TObject; var Action: TCloseAction);
begin
   OnResize:=nil;
end;



procedure TF_Dump.SaveClick(Sender: TObject);
var with_header:boolean;
   
   fn:string;
begin
   with_header:=TMenuItem(Sender).Tag=1;
   screen.Cursor:=crHourGlass;
   fn:=DM.temp_folder+DM.volume_data.volid+'_'+DM.TK_F.FieldByName('name').AsString+'.dat';

   screen.Cursor:=crHourGlass;
   if not DM.save_raw_data(with_header,fn) then
   begin
      screen.Cursor:=crDefault;
      ShowMessage('error in save raw data');
      exit;
   end;
   screen.Cursor:=crDefault;

   ShowMessage('save raw data => '+fn);
end;

end.
