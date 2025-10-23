program DasdBR7;
{


 nao sei onde estao os dados -group de inode / inode
 nao sei como processar data e hora





}

uses
  Forms,
  DasdBR7_DM in 'DasdBR7_DM.pas' {DM: TDataModule},
  DasdBR7_Main in 'DasdBR7_Main.pas' {F_Main},
  DasdBR7_PO in 'DasdBR7_PO.pas' {F_PO},
  DasdBR7_PDS in 'DasdBR7_PDS.pas' {uPDS: TDataModule},
  DasdBR7_Show in 'DasdBR7_Show.pas' {F_Show},
  DasdBR7_Vsam in 'DasdBR7_Vsam.pas' {F_VSAM},
  DasdBR7_Find in 'DasdBR7_Find.pas' {F_Find},
  DasdBr7_DV in 'DasdBr7_DV.pas' {DV: TDataModule},
  DasdBR7_dump in 'DasdBR7_dump.pas' {F_Dump},
  DasdBR7_HFSV2 in 'DasdBR7_HFSV2.pas' {F_HFS},
  DsdBR7_PDSE in 'DsdBR7_PDSE.pas' {F_PDSE};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Hercules dasd browser';
  Application.CreateForm(TDM, DM);
  Application.CreateForm(TF_Main, F_Main);
  Application.CreateForm(TF_PO, F_PO);
  Application.CreateForm(TuPDS, uPDS);
  Application.CreateForm(TF_Show, F_Show);
  Application.CreateForm(TF_VSAM, F_VSAM);
  Application.CreateForm(TDV, DV);
  Application.CreateForm(TF_Find, F_Find);
  Application.CreateForm(TF_Dump, F_Dump);
  Application.CreateForm(TF_HFS, F_HFS);
  Application.CreateForm(TF_PDSE, F_PDSE);
  F_HFS.stand_alone:=false;
  F_PDSE.stand_alone:=false;
  Application.Run;



end.

