


{

 hercules dasd  browser version 7

   VTOC/Read/dump/browse/info  -->  MVS DASDs

  Functions: Dump - by dataset/ cyl/ trk

            Vsam - show all vsam datasets info in volume (like IDCAMS)

            Browse PO and PS with options:
                        max len line,
                        max rec num,
                        hex format
                        rec num

            Info: Dasd / extents list/ percent allocated /VOLID/ Volume name /

            Find dataset/member names

            Map - list all extents use

 and more:

    Copy dataset to windows folder

    Sort on all columns

    Fast performance

    Low profile

    Dasd CKD compressed by zlib and bzip2 ou uncompressed

            by dbs - 2025


}




unit DasdBR7_Main;

interface

uses

   DasdBR7_DM,
   DasdBR7_HFSV2,
   DasdBr7_PDS,
   DsdBR7_PDSE,
   DasdBR7_PO,
   DasdBR7_Show,
   DasdBR7_dump,
   DasdBR7_Vsam,
   DasdBR7_Find,
   clipbrd,
   shellapi,
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Menus, Db,  DBGrids,
  ComCtrls, Grids;

type
  TF_Main = class(TForm)
    OD: TOpenDialog;
    MainMenu1: TMainMenu;
    Open1: TMenuItem;
    Quit1: TMenuItem;
    DBG: TDBGrid;
    Help1: TMenuItem;
    Disks1: TMenuItem;
    AllMembers1: TMenuItem;
    Utility1: TMenuItem;
    ALLVTOC: TMenuItem;
    Vsam1: TMenuItem;
    Dump1: TMenuItem;
    Option1: TMenuItem;
    POrecs1: TMenuItem;
    Mapf61: TMenuItem;
    DS_Files: TDataSource;
    Linkeddate1: TMenuItem;
    POsize1: TMenuItem;
    Statistics1: TMenuItem;
    Showvolumeallocation1: TMenuItem;
    POShowalias: TMenuItem;
    FindF31: TMenuItem;
    procedure Open1Click(Sender: TObject);
    procedure Quit1Click(Sender: TObject);
    procedure DBGTitleClick(Column: TColumn);
    procedure FormCreate(Sender: TObject);
    procedure DBGDblClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure DBGKeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure Help1Click(Sender: TObject);
    procedure ALLVTOCClick(Sender: TObject);
    procedure DBGCellClick(Column: TColumn);
    procedure Vsam1Click(Sender: TObject);
    procedure Dump1Click(Sender: TObject);
    procedure Mapf61Click(Sender: TObject);
    procedure Statistics1Click(Sender: TObject);
    procedure Showvolumeallocation1Click(Sender: TObject);
    procedure FindF31Click(Sender: TObject);

  private


    procedure open_dasd(fn:string);
    procedure DisksClick(Sender: TObject);
    procedure create_show_message(title,s:string);

  end;

const
mhelp=#10+
      'How to use:'+#10+
      '  Open a hercules dasd file '+#10+#10+
      'Clique column extent to show extents           '+#10+
      'Clique other column to show pds/ps/vsam data   '+#10+
      'F2 - Open dasd file                            '+#10+
      'F4 - Show vsam data files                      '+#10+
      'F5 - Show file dump                           '+#10+
      'F6 - Show dataset track map                    '+#10+
      'Utility:                                       '+#10+
      '  print all vtoc - text file with all vols vtoc'+#10+
      '  find dataset or pds member - show find list  '+#10+
      '  show volume allocation - allocation statistics'+#10+
      'Statistics - show current volume statistic data'+#10+
      'VTOC all files - show all vtoc in folder'+#10+#10+
      'Options - show pds count members'+#10+
      '          show modules create date'+#10+
      '          show pdf member record count'+#10+#10+#10;

var
  F_Main: TF_Main;
  file_opened: boolean = false;
  dasd_dir : string=''; // init parms

implementation



{$R *.DFM}


procedure TF_Main.FormCreate(Sender: TObject);
var
    ss:string;
    t1,t2,fq:int64;

begin
   Caption:='DASDBR - V7 (no dll) ';
   dasd_dir:=ExtractFilePath(Application.ExeName);

   if length(dasd_dir)>0 then
   if dasd_dir[length(dasd_dir)]<>'\'
   then dasd_dir:=dasd_dir+'\';

   if ParamCount>0 then
   begin
      ss:=ParamStr(1);
      if FileExists(ss) then
      begin
         dasd_dir:=ExtractFilePath(ss);
         DM.set_menu_disks(dasd_dir,MainMenu1,DisksClick);
         QueryPerformanceFrequency(fq);
         QueryPerformanceCounter(t1);
         OD.FileName:=ss;
         open_dasd(OD.FileName);
         QueryPerformanceCounter(t2);
      end;
   end;
end;



// open dasd file, mount and display data table
procedure TF_Main.open_dasd(fn:string);
var options:integer;
begin
   if FileExists(fn)=false then
   begin
      ShowMessage('Not found '+fn);
      Exit;
   end;

   DS_Files.DataSet:=nil;

   options:=0;

   if POrecs1.Checked then options:=options or option_po_recs;
   //if PDSF80.Checked  then options:=options or option_filter_80;
   //if PDSU.Checked    then options:=options or option_filter_U;

   file_opened:=DM.open_zos(options,fn);

   if file_opened then
   begin
      uPDS.pds_set_number_of_recs(options);
   end;

   DM.TK_F.EnableControls;
   DM.TK_F.First;
   DS_Files.DataSet:=DM.TK_F;
   DM.TK_F.Filter:='dsorg = '+QuotedStr('PO');
   DM.TK_F.Filtered:=true;

end;


procedure TF_Main.Quit1Click(Sender: TObject);
begin
   close;
end;






// dialog open file
procedure TF_Main.Open1Click(Sender: TObject);
var fe:string;
begin
   OD.FileName:='';
   if OD.Execute=false then exit;

   if not FileExists(OD.FileName) then exit;

   screen.Cursor:=crHourGlass;
   fe:=ExtractFilePath(OD.FileName);            // update dasd menu item
   if fe<>dasd_dir then
   begin
      dasd_dir:=fe;
      DM.set_menu_disks(dasd_dir,MainMenu1,DisksClick);
   end;
   open_dasd(OD.FileName);
   screen.Cursor:=crDefault;
end;




// set display data order
procedure TF_Main.DBGTitleClick(Column: TColumn);
begin
  DM.set_table_index(DM.TK_F,Column.FieldName,'i_'+Column.FieldName);
end;





// try list members
procedure TF_Main.DBGDblClick(Sender: TObject);
var fileno:integer;

begin
   fileno:=DM.TK_F.FieldByName('dscb').AsInteger;

   if DM.TK_F.FieldByName('dsorg').AsString='PO' then  // go list members
   begin
    if DM.is_dataset_empty then
     begin
        ShowMessage('... empty ...');
        exit;
     end;
     if not uPDS.pds_has_member(fileno) then
     begin
        ShowMessage('... no members ...');
        exit;
     end;

     F_PO.options:=0;

     if POrecs1.Checked       then F_PO.options:=F_PO.options or option_po_recs;
     if POsize1.Checked       then F_PO.options:=F_PO.options or option_po_size;
     if Linkeddate1.Checked   then F_PO.options:=F_PO.options or option_po_linkeddate;
     if POShowalias.Checked   then F_PO.options:=F_PO.options or option_show_alias;
     F_PO.Caption:=DM.TK_F.FieldByName('name').AsString;
     F_PO.ShowModal;
     Exit;
  end;


  if (DM.TK_F.FieldByName('dsorg').AsString='PS')  then  // go show data
  begin
     if DM.is_dataset_empty then
     begin
        ShowMessage('..empty...');
        exit;
     end;
     F_Show.Caption:=DM.TK_F.FieldByName('name').AsString;
     F_Show.proctype:='PS';
     F_Show.ShowModal;
     Exit;
  end;

  if DM.TK_F.FieldByName('dsorg').AsString='VSAM' then   // go to list vsam
  begin
     Vsam1Click(Vsam1);
     exit;
  end;

  if DM.TK_F.FieldByName('dsorg').AsString='HFS' then
  begin
     F_HFS.ShowModal;
     exit;
  end;

  if DM.TK_F.FieldByName('dsorg').AsString='PDSE' then
  begin
     F_PDSE.ShowModal;
     exit;
  end;
  if DM.TK_F.FieldByName('dsorg').AsString='???' then
  begin
     ShowMessage('error 101 - unknow DSORG');
     exit;
  end;

end;


procedure TF_Main.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
   if key=VK_F1 then create_show_message('Help',mhelp);
   if key=27 then Close;
end;


procedure Show_extents;
var s:string;
begin
   s:=DM.dataset_extents;
   ShowMessage(s);
end;



procedure TF_Main.DBGKeyDown(Sender: TObject; var Key: Word;   Shift: TShiftState);
begin
   if key=13 then DBGDblClick(nil);
end;



procedure TF_Main.Help1Click(Sender: TObject);
begin
   create_show_message('Help',mhelp);
end;

procedure TF_Main.DisksClick(Sender: TObject);
var ss : string;
begin
   ss:=AnsiUpperCase(dasd_dir+TMenuItem(Sender).Caption);
   if pos('&',ss)>0
   then delete(ss,pos('&',ss),1);
   OD.FileName:=ss;
   open_dasd(OD.FileName);
end;


procedure TF_Main.ALLVTOCClick(Sender: TObject);
var save_fn_actual:string;
begin
   Screen.Cursor:=crHourGlass;
   save_fn_actual:=DM.volume_data.fn;              // save actual volume
   DM.vtoc_print_all(F_Main);                      // form to show messages
   open_dasd(save_fn_actual);                      // reopen actual volume
   Screen.Cursor:=crDefault;
end;



procedure TF_Main.DBGCellClick(Column: TColumn);
begin
   if DM.TK_F.Active and (Column.FieldName='extents')
   then Show_extents;
end;


procedure TF_Main.Vsam1Click(Sender: TObject);
begin
   if not DM.TK_F.Active then
   begin
      ShowMessage('Error 8992 - no volume');
      exit;
   end;

   if not DM.has_extent then
   begin
      ShowMessage('error 810 - no extent avaliable');
      exit;
   end;

   if not DM.TK_F.Locate('Name','SYS1.VVDS.V',[loPartialKey]) then
   begin
      ShowMessage('SYS1.VVDS.Vxxxx  not found');
      exit;
   end;
   F_Vsam.ShowModal;

end;

procedure TF_Main.Dump1Click(Sender: TObject);
begin
   F_Dump.ShowModal;
end;





procedure TF_Main.Mapf61Click(Sender: TObject);
begin
   if not DM.has_extent then
   begin
      ShowMessage('error 813 - no extent avaliable');
      exit;
   end;
   Screen.Cursor:=crHourGlass;
   DM.map_generate;
   Screen.Cursor:=crDefault;
end;


procedure TF_Main.create_show_message(title,s:string);
var spaces:string;
begin
   spaces:='___________________________________'+#10;
   with CreateMessageDialog(spaces+s+spaces, mtCustom, [mbOK]) do
  try
    Font.Name := 'Courier New';//'Lucida Console';
    Font.Color := clLime;
    Font.Size := 16;

    Width:=420;
    Height:=500;
    Position:=poScreenCenter;
    Caption:=title;
    Color:=clBlack;
    Font.Size := 10;
    ShowModal;
  finally
    Free;
  end;
end;


// general system statistics - create a send message
procedure TF_Main.Statistics1Click(Sender: TObject);
var vol:p_volume_global;
    s:string;
    perc:integer;
begin
   vol:=@DM.volume_data;
   if vol.tracks_total=0 then exit;    // not opened
   if vol^.tracks_total=0 then;
   perc:=100 - (vol.tracks_allocated * 100 div vol.tracks_total);
   //DM.volume_data.
   //compress:=
   s:=format(#10+
   //'            Statistics              '+#10+
   //'____________________________________'+#10+
   '     VolName......:  %s '+#10+
   '     Model........:  %s '+#10+
   '     Num cyl......:  %d '+#10+
   '     Trk per cyl..:  %d '+#10+
   '     Track size...:  %d '+#10+
   '     Num dscb.....:  %d '+#10+
   '     Compress.....:  %s '+#10+
   '     File size(M).:  %d '+#10+
   '     Num extents .:  %d '+#10+
   '     Tracks total.:  %d '+#10+
   '     Tracks alloc.:  %d '+#10+
   '     Tracks free..:  %d '+#10+
   '     Vtoc extent..:  %d/%d %d/%d'+#10+
   '     Percent free.:  %d %% '+#10+#10+
   '     Time open....:  %.3f'+#10+
   '     Tot mem pds80:  %d'+#10+
   '     Tracks read..:  %d '+#10,
   //'____________________________________'+#10+#10,
   [vol.volid,vol.model,vol.num_cyl,vol.trk_per_cyl,
      vol.trk_size,vol.num_dscbs,
      vol.compress,
      vol.filesize div 1024,
      vol.ix_extent,vol.tracks_total,vol.tracks_allocated,
      vol.tracks_total-vol.tracks_allocated,
      vol.vtoc_init.cyl,vol.vtoc_init.trk,vol.vtoc_end.cyl,vol.vtoc_end.trk,
      perc,
      vol.ellapse_open,
      vol.total_members_pds80,
      vol.tracks_read]);
   create_show_message('Statistics',s);
end;


procedure TF_Main.Showvolumeallocation1Click(Sender: TObject);
begin
   DM.TK_F.DisableControls;
   DM.show_volume_allocation;
   DM.TK_F.EnableControls;
end;

procedure TF_Main.FindF31Click(Sender: TObject);
var save_fn_actual:string;
begin
   save_fn_actual:=DM.volume_data.fn;     // save actual volume
   DM.close_file;

   if F_Find.ShowModal=mrRetry
   then open_dasd(DM.get_volume_fname(F_Find.find_at_vol))
   else open_dasd(save_fn_actual);             // reopen actual volume

   if DM.TK_F.Active
   then DM.TK_F.Locate('name',F_Find.find_at_dsn,[]);
end;

end.

