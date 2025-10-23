unit DasdBr7_DV;
{
   VSAM

}

interface

uses
  DasdBR7_DM,
  SysUtils, Classes,dialogs;

type

  TDV = class(TDataModule)
  private
    { Private declarations }
  public
    { Public declarations }
    function valid_vvdr(pv:Pbyte):boolean;
    function VSAM_RDF_list(pb:pbyte;ci_size:integer):t_rdf_list;
    function table_vvdr_mount(with_recs:boolean;vvr_num:integer;pb:PByte):boolean;
    function VSAM_statistics_table:boolean;
  end;

var
  DV: TDV;

implementation

{$R *.dfm}


function Swap4(a:cardinal):cardinal; asm bswap eax end;




function TDV.table_vvdr_mount(with_recs:boolean;vvr_num:integer;pb:PByte):boolean;
var dt:TDateTime;
    has_recs:boolean;
    dd:double;
    v21: vvr_h21;
    v23: vvr_h23;
    vvh :vvdr_header;
    vname:vvdr_name;

    pt,ph,pname : pbyte;
    amsd: vvdr_h60;
    space_pri,space_sec : cardinal;
    s:string;
begin
   Result:=false;


   move(pb^,vvh,sizeof(vvdr_header));
   vvh.VVRTYPE:=ebcdic_to_ascii[ord(vvh.VVRTYPE)];
   if not (vvh.VVRTYPE in ['Q','Z']) then exit;

   vvh.VVRHDLEN:=swap(vvh.VVRHDLEN);
   ph:=pb;
   inc(ph,vvh.VVRHDLEN+2);
   move(ph^,amsd,sizeof(vvdr_h60));
   amsd.blen:=swap(amsd.blen);
   //amsd_len:=vvh.VVRLEN - 2;

   pname:=pb;
   inc(pname,10); // ??? vvdr_name_offset);


   DM.TK_V.Insert;

   move(pname^,vname,vvh.VVRCMPNL);
   DM.ebcdic_inplace(vname.name,vname.len);
   s:=copy(vname.name,1,vname.len-1);

   inc(pname,vname.len+1);

   DM.TK_V.FieldByName('name').AsString:=s;

   move(pname^,vname,vvh.VVRCMPNL);
   DM.ebcdic_inplace(vname.name,vname.len);
   s:=copy(vname.name,1,vname.len-1);
   DM.TK_V.FieldByName('base').AsString:=s;



   DM.TK_V.FieldByName('num').AsInteger:=vvr_num;

   has_recs:=not with_recs;

   while  amsd.blen>0 do
   begin
      //dec(amsd_len,amsd.blen);
      //$21 =  *        V V R   D A T A S E T   I N F O R M A T I O N   C E L L      *
      if amsd.tipo=$21 then
      begin
         move(ph^,v21,sizeof(vvr_h21));

         //v21.VVRDSLEN:=swap(v21.VVRDSLEN);     // not used
         //v21.VVRDSRSV:=swap(v21.VVRDSRSV);
         //v21.VVR21DCL:=swap(v21.VVR21SCL);
         //v21.VVR21DCL:=swap(v21.VVR21DCL);
         //v21.VVR21MCL:=swap(v21.VVR21MCL);

         //v21.VVRBUFSZ:=swap4(v21.VVRBUFSZ);
         v21.VVRDSHU:=swap4(v21.VVRDSHU);
         v21.VVRDSHA:=swap4(v21.VVRDSHA);
         //v21.VVRLRECL:=swap4(v21.VVRLRECL);
         //v21.VVRDSHK:=swap4(v21.VVRDSHK);


         space_pri:=DM.get_BYTE3(@v21.VVRPRISP);
         space_sec:=DM.get_BYTE3(@v21.VVRSECSP);

         if (v21.VVRSPCFG and VVRSPTRK)=VVRSPTRK               //TRACK ALLOCATION
         then DM.TK_V.FieldByName('alloc').AsString:='Trk' else
         if (v21.VVRSPCFG and VVRSPCYL)=VVRSPCYL               //CYLINDER ALLOCATION
         then DM.TK_V.FieldByName('alloc').AsString:='Cyl' else
         if (v21.VVRSPCFG and VVRSPCOP)=VVRSPCOP               // SPACE OPTIONS
         then DM.TK_V.FieldByName('alloc').AsString:='Spc' else
              DM.TK_V.FieldByName('alloc').AsString:='???';

         DM.TK_V.FieldByName('pri_sp').AsInteger:=space_pri;
         DM.TK_V.FieldByName('sec_sp').AsInteger:=space_sec;

         DM.TK_V.FieldByName('h_urba').AsInteger:=integer(v21.VVRDSHU);
         DM.TK_V.FieldByName('h_arba').AsInteger:=integer(v21.VVRDSHA);

         dd:=v21.VVRDSHU;
         dd:=(dd * 100) / v21.VVRDSHA;
         DM.TK_V.FieldByName('perc').AsFloat:=dd;
      end;

      if amsd.tipo=$23 then
      begin
         move(ph^,v23,sizeof(vvr_h23));
         //v23.VVRVOLLN:=swap(v23.VVRVOLLN);
         v23.VVRBLKTK:=swap(v23.VVRBLKTK);
         //v23.VVRTRKAU:=swap(v23.VVRTRKAU);
         //v23.VVRXTNTL:=swap(v23.VVRXTNTL);          // not used
         //v23.VVRXSEQN:=swap(v23.VVRXSEQN);
         //v23.VVRXSC:=swap(v23.VVRXSC);
         //v23.VVRXSH:=swap(v23.VVRXSH);
         //v23.VVRXEC:=swap(v23.VVRXEC);
         //v23.VVRXEH:=swap(v23.VVRXEH);
         //v23.VVRXNTRK:=swap(v23.VVRXNTRK);
         //v23.VVRHKRBA:=swap4(v23.VVRHKRBA);
         //v23.VVRHURBA:=swap4(v23.VVRHURBA);
         //v23.VVRHARBA:=swap4(v23.VVRHARBA);
         //v23.VVRBLKSZ:=swap4(v23.VVRBLKSZ);

         //v23.VVRBYTTK:=swap4(v23.VVRBYTTK);
         //v23.VVRBYTAU:=swap4(v23.VVRBYTAU);
         //v23.VVRXSRBA:=swap4(v23.VVRXSRBA);
         //v23.VVRXERBA:=swap4(v23.VVRXERBA);

         DM.TK_V.FieldByName('trk_ci').AsInteger:=v23.VVRBLKTK;

      end;

      if amsd.tipo=$60 then
      begin
          pt:=@amsd.times[0];

          dt:=DM.gmt_stck(pt);
          if dt>2
          then DM.TK_V.FieldByName('create').AsDateTime:=dt;


          //amsd.free_b_ci:=swap4(amsd.free_b_ci);
          amsd.ci_size:=swap4(amsd.ci_size);
          amsd.max_recs:=swap4(amsd.max_recs);
          amsd.ix_seq:=swap4(amsd.ix_seq);
          //amsd.max_rrn:=swap4(amsd.max_rrn);
          //amsd.p_ardb:=swap4(amsd.p_ardb);
          amsd.n_rec:=swap4(amsd.n_rec);
          amsd.n_del:=swap4(amsd.n_del);
          amsd.n_ins:=swap4(amsd.n_ins);
          amsd.n_upd:=swap4(amsd.n_upd);
          amsd.n_retr:=swap4(amsd.n_retr);
          //amsd.free_sp:=swap4(amsd.free_sp);
          //amsd.ci_split:=swap4(amsd.ci_split);
          //amsd.ca_split:=swap4(amsd.ca_split);
          amsd.excps:=swap4(amsd.excps);
          //amsd.rlen:=swap(amsd.rlen);
          //amsd.aixrpk:=swap(amsd.aixrpk);
          amsd.irpk:=swap(amsd.irpk);
          amsd.ilen:=swap(amsd.ilen);
          amsd.ci_ca:=swap(amsd.ci_ca);
          //amsd.datab:=swap(amsd.datab);
          amsd.index_level:=swap(amsd.index_level);
          amsd.extents:=swap(amsd.extents);

          if amsd.index_level>0
          then DM.TK_V.FieldByName('ix_lev').AsInteger:=amsd.index_level;

          DM.TK_V.FieldByName('cisize').AsInteger:=amsd.ci_size;
          DM.TK_V.FieldByName('ci_ca').AsInteger:=amsd.ci_ca;
          if amsd.ilen>0
          then DM.TK_V.FieldByName('keyl').AsInteger:=amsd.ilen;
          if amsd.irpk>0
          then DM.TK_V.FieldByName('rpk').AsInteger:=amsd.irpk;

          if amsd.ix_seq>0
          then DM.TK_V.FieldByName('ix_ofs').AsInteger:=amsd.ix_seq;
          if not has_recs
          then has_recs:=amsd.n_rec>0;


          if amsd.n_rec>0
          then DM.TK_V.FieldByName('rec_tot').AsInteger:=amsd.n_rec;
          if amsd.n_del>0
          then DM.TK_V.FieldByName('rec_del').AsInteger:=amsd.n_del;
          if amsd.n_ins>0
          then DM.TK_V.FieldByName('rec_ins').AsInteger:=amsd.n_ins;
          if amsd.n_upd>0
          then DM.TK_V.FieldByName('rec_upd').AsInteger:=amsd.n_upd;
          if amsd.n_retr>0
          then DM.TK_V.FieldByName('rec_retr').AsInteger:=amsd.n_retr;

          DM.TK_V.FieldByName('excp').AsInteger:=amsd.excps;
          DM.TK_V.FieldByName('extents').AsInteger:=amsd.extents;

          if amsd.max_recs>0
          then DM.TK_V.FieldByName('maxrecl').AsInteger:=amsd.max_recs;


          if (amsd.atrib and VVRAMDST) > 0  //VVRAMDST EQU   X'80'                    //  1 => KSDS, 0 => ESDS
          then DM.TK_V.FieldByName('t').AsString:='K'
          else
          begin
            if (amsd.atrib and VVRAMRDS)>0
            then DM.TK_V.FieldByName('t').AsString:='R'
            else DM.TK_V.FieldByName('t').AsString:='E';
          end;  



          if (amsd.atrib and VVRAMSPN)=VVRAMSPN  //  SPANNED RECORDS ARE ALLOWED
          then DM.TK_V.FieldByName('t').AsString:=DM.TK_V.FieldByName('t').AsString+'s';

      end;
      inc(ph,amsd.blen);
      move(ph^,amsd,sizeof(vvdr_h60));
      amsd.blen:=swap(amsd.blen);
   end;
   DM.TK_V.Post;
   Result:=true;
   //if has_recs
   //then DM.TK_V.Post
   //else DM.TK_V.Cancel;
end;






function TDV.VSAM_RDF_list(pb:pbyte;ci_size:integer):t_rdf_list; // pb point to initial data
var lrdf:t_rdf_list;
    CIDF:t_CIDF;
    RDF:T_RDF;
    q,rdf_len:integer;
    prdf:PByte;
    //pRID:PByte;
begin
   // acess CIDF
   prdf:=pb;
   inc(prdf,ci_size-4);
   Move(prdf^,CIDF,sizeof(t_CIDF));
   //dec(prdf,sizeof(t_CIDF));
   SetLength(lrdf,0);


   CIDF.ofs:=swap(CIDF.ofs);
   CIDF.len:=swap(CIDF.len);
   if (CIDF.ofs=0) and (CIDF.len=0)
   then exit;

   rdf_len:=ci_size - (CIDF.ofs+CIDF.len) - sizeof(t_cidf);
   SetLength(lrdf,16355);

   q:=0;
   lrdf[q].qrec:=1;

   while rdf_len>0 do
   begin
      dec(prdf,3);                // poin to RDF
      move (prdf^,RDF,sizeof(t_rdf));
      RDF.Binary_Number:=swap(RDF.Binary_Number);
      RDF.Control_Field:=RDF.Control_Field and (not $83); // remove reserved bits
      if (RDF.Control_Field=0) and
         (RDF.Binary_Number=0)
      then break;


      if (RDF.Control_Field and $30)>0 then
      begin
         if RDF.Control_Field=0 then;
         continue;
      end;

      if (RDF.Control_Field and $40)>0 then
      begin
         lrdf[q].recl:=RDF.Binary_Number;       // vide next rdf for quant
         dec(prdf,3);                // poin to RDF
         move (prdf^,RDF,sizeof(t_rdf));
         RDF.Binary_Number:=swap(RDF.Binary_Number);
         lrdf[q].qrec:=RDF.Binary_Number;
         inc(q);
         dec(rdf_len,6);
         continue;
      end;

      if RDF.Control_Field=0 then
      begin
         lrdf[q].recl:=RDF.Binary_Number;
         lrdf[q].qrec:=1;
         inc(q);
         dec(rdf_len,3);
         continue;
      end;

//.... .x.. For a fixed-length RRDS, indicates whether the slot described by this
//          RDF does (0) or does not (1) contain a record.
      if RDF.Control_Field=4 then
      begin
        dec(rdf_len,3);
        continue;
      end;
      ShowMessage(format('error 328 - RID unknow %X',[RDF.Control_Field]));
      break;
   end;
   if rdf_len=0 then;
   SetLength(lrdf,q);
   if q>0 then
   if lrdf[0].qrec=0 then;
   Result:=lrdf;
end;
// valid vvdr



function TDV.valid_vvdr(pv:Pbyte):boolean;
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


// mount table with vsam statistics
// assume cisize <= datalen

function TDV.VSAM_statistics_table:boolean;
var i,k,fileno,vvr_num,cisize:integer;
    hrec:rec_header;
    exts:p_resume;
    ckd:tckd;
    pb:PByte;
    lrdf:t_rdf_list;
begin
   Result:=false;
   SetLength(lrdf,0);
   fileno:=DM.TK_F.FieldByName('dscb').AsInteger;



   exts:=DM.get_file_extents(fileno,0);
   if exts=nil then exit;

   // get extents file

   ckd.cyl:=exts.l_cyl;
   ckd.trk:=exts.l_trk;
   ckd.nrec:=1;            // rec 0=nodata rec 1=VVCR header so rec 2 = data
   ckd.read:=0;

   pb:=DM.read_one_track(fileno,@ckd,true);
   if pb=nil then
   begin
      ShowMessage('Empty...');
      exit;
   end;
   hrec:=DM.get_next_header(pb,0);
   cisize:=hrec.dlen;                   // assume dataset vvrd has cisize = datalen






   vvr_num:=1;
   DM.TK_V.Close;
   DM.TK_V.Open;


   while true do
   begin
      lrdf:=DV.VSAM_RDF_list(pb,cisize);
      if high(lrdf)=-1 then break;
      for i:=0 to high(lrdf) do
      begin
         for k:=1 to lrdf[i].qrec do
         begin
            DV.table_vvdr_mount(false,vvr_num,pb);
            inc(vvr_num);
            inc(pb,lrdf[i].recl);
         end;
      end;
      //read next record....
      inc(ckd.nrec);
      pb:=DM.read_one_track(fileno,@ckd,true);
      if pb=nil then exit;
      hrec:=DM.get_next_header(pb,0);
   end;
end;


end.
