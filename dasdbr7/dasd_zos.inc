// structures and constants

const
 PDS_ALIAS  = $80;       //* Bit 0: Name is an alias   */
 PDS2_NTTR  = $60;       //* Bits 1-2: User TTR count  */
 PDS2_SHIFT =   5;       //* Shift count for NTTR      */
 PDS2_LUSR  = $1F;       //* Bits 3-7: User halfwords  */
 PDSDIR_LEN = 8+3+1;     // sizeof(pdsdir.name)+sizeof(pdsdir.ttr)+sizeof(pdsdir.ind);
 USER_DATA_ISPF = $10;

 MAX_TRK_LEN = 56664;      // for model 3390-3
 hexa_tab : array[0..15] of char =('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
 DS1COMPR = $80;


       // to calcule julian date
 d365 : array[1..12] of integer =(31,59,90,120,151,181,212,243,273,304,334,999);
 d366 : array[1..12] of integer =(31,60,91,121,152,182,213,244,274,305,335,999);

 six_ff : array[0..7] of byte = ($ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff);

 max_l1_tab=1920;



type


p_find_struct=^t_find_struct;       // used for find dsn pdf members and text
t_find_struct=record
   threadId,
   options,
   count_find,
   max_found,
   rc,                  // return code
   pds_read,
   trk_read,
   dscb_count:integer;
   fname,
   volid,
   dsname,
   member_name,
   text,
   resp_string,
   resp_dataset,
   resp_member,
   resp_line:string;
   ended:boolean;
end;


// ibm dasd extent
t_extent = packed record
    typeind : byte;                    // extent type indicator
    seqno   : byte;                    // extent sequence number
    l_cyl,                             // starting point of this extent
    l_trk,
    h_cyl,                             // ending point of this extent
    h_trk : word;
end;

file_exts= array[0..255] of t_extent;
p_file_ext= ^file_exts;
p_one_extent=^t_extent;


// resume -> like t_extent but typeind dont comport filenum>255
t_extent_resume= record
  filenum,seqno,l_cyl,l_trk,h_cyl,h_trk:word;
end;
p_resume=^t_extent_resume;


t_string_array=array of string;
p_string_array=^t_string_array;

// ibm vtoc information  - original ibm format
t_cyl_trk_rec=packed record
   cyl,trk:word;
   rec:byte;
end;

// count key data - work used with cyl,track to identify one data record
// read field assigned to total track len read
tckd = record
   cyl,
   trk,nrec,read:integer;
end;
p_ckd=^tckd;




// volume global data
t_volume_global= record
   tracks_total,
   tracks_allocated,
   tracks_read,
   num_dscbs,
   trk_size,
   total_members_pds80,
   filesize,
   ix_extent:integer;
   num_cyl,
   trk_per_cyl:word;
   vtoc_init,
   vtoc_end:t_cyl_trk_rec;
   dscb_ext: t_extent;
   ellapse_open:single;
   fn,
   volid,
   compress,
   model:string;
end;
p_volume_global=^t_volume_global;







{ from hercules source:

typedef struct _CKDDEV {                /* CKD Device table entry    */
        char   *name;                   /* Device name               */
        U16     devt;                   /* Device type               */
        BYTE    model;                  /* Device model              */
        BYTE    class;                  /* Device class              */
        BYTE    code;                   /* Device code               */
        U16     cyls;                   /* Number primary cylinders  */
        U16     altcyls;                /* Number alternate cylinders*/
        U16     heads;                  /* Number heads (trks/cyl)   */

#define HDL_SIZE_DEVBLK   sizeof(DEVBLK)
        DEVBLK *nextdev;                /* -> next device block      */
        REGS   *regs;                   /* -> REGS if syncio         */
        LOCK    lock;                   /* Device block lock         */
        int     allocated;              /* Device block free/in use  */

        /*  device identification                                    */

        U16     ssid;                   /* Subsystem ID incl. lcssid */
        U16     subchan;                /* Subchannel number         */
        U16     devnum;                 /* Device number             */
        U16     devtype;                /* Device type               */
        U16     chanset;                /* Channel Set to which this
                                           device is connected S/370 */
        char    *typname;               /* Device type name          */


}





//* possible pointer to f2 or f3 DSCB */
h_CCTTR = packed record
    cc,
    hh : word;
    r  : byte;
end;


// in pds dir --> ttr nrec to find member data
h_TTR = packed record
    hh : word;
    r  : byte;
end;


// pds user data: https://www.ibm.com/docs/en/zos/2.1.0?topic=di-ispf-statistics-entry-in-pds-directory

t_pds_user_data = packed record
  vers,level,flag : byte;          // flag Bit 3 Indicates ISPF extended statistics exist.
  seg : byte;
  created : array[0..3] of byte;
  lastUsed : array[0..3] of byte;
  hour,minute :  byte;
  size,                            // Current number of lines
  init_size,                       // Initial number of lines
  mod_size : word;                 // Number of modified lines
  uid : array[0..9] of char;
  blank_blank:array[0..15] of char;
end;
p_pds_user_data = ^t_pds_user_data;




// in all tracks - record header
// fill with FF --> end track
// klen=0 and dlen=0 --> EOF
rec_header = record                 //* Record header             */
    cyl : word;                     //* Cylinder number           */
    head: word;                     //* Head number               */
    rec : byte;                     //* Record number             */
    klen: byte;                     //* Key length                */
    dlen: word;                     //* Data length               */
end;
p_rec_header=^rec_header;


t_track_home_address= packed record   //* Track home address        */
    bin : byte;                       //* Bin number                */
    cyl : word;                       //* Cylinder number           */
    head: word;                       //* Head number               */
end;



//  exemple pds dir userdata   //* User data (0-31 halfwords)*/
     // 000018000000000002E20001F801F8000000880001010100
// doc: DFSMS using data set - PDS

// PDS dir entry
t_pdsdir = packed record
     name : array[0..7] of char;     //* Member name               */
     ttr  : h_TTR;                   //* TTR of first block        */
     ind  : byte;                    //* Indicator byte            */
     udata: array [0..61] of byte;   //* User data (0-31 halfwords)*/
end;

p_save_pds_dir=array of t_pdsdir;
p_one_dir=^t_pdsdir;




// ps dir header
dasd_pdsdir=packed record            // disk pds directory - first word = dir len
   key_name: array[0..7] of char;
   dirlen:word;
   one_dir:t_pdsdir;
end;
p_dasd_pdsdir=^dasd_pdsdir;


vtoc_dev_const = packed record           //  device constants */
  dc_vsam_time : array[0..7] of byte;    // VSAM time stamp
  dc_vsam_ind  : array[0..2] of byte;    // VSAM catalog indicator
  dc_vsam_cat  : array[0..7] of byte;    // VSAM volume/catalog match time stamp
  dc_res       : array[0..4] of byte;    // reserv
  dc_f6_ptr    : array[0..4] of byte;    // pointer to first format 6 DSCB
end;




{
    A sequential data set can have 16 extents on each volume.
    An extended-format sequential data set can have 123 extents per volume.
    A PDS can have 16 extents.
    A direct data set can have 16 extents on each volume.
    A non-system-managed VSAM data set can have up to 255 extents per component. System-managed VSAM data sets can have this limit removed if the associated data class has extent constraint removal specified.
    A system-managed VSAM data set can have up to 255 extents per stripe. This limit can be removed if the associated data class has extent constraint removal specified.
    A PDSE can have 123 extents.
    An HFS data set can have 123 extents on each volume.

   extent type indicator:

   X'81' 	  	  	Extent on cylinder boundaries.
  	X'80' 	  	  	Extent described is sharing cylinder (no longer supported).
  	X'40' 	  	  	First extent describes the user labels and is not counted in DS1NOEPV.
  	X'04' 	  	  	Index area extent (ISAM).
  	X'02' 	  	  	Overflow area extent (ISAM).
  	X'01' 	  	  	User's data block extent, or a prime area extent (ISAM).
  	X'00' 	  	  	This is not an extent.
}



 vol_struct = packed record
   DS4DSCYL,            //DS4DSCYL	Number of logical cylinders including alternates
   DS4DSTRK,            //DS4DEVTK	Device track length.
   DS4DEVTK : word;     //DS4DEVOV	Keyed record overhead.
   DS4DEVI,             //DS4DEVI	Non-last-keyed record overhead.
   DS4DEVL,             //DS4DEVL	Last keyed record overhead.
   DS4DEVK,             //Non-keyed record overhead differential.
   DS4DEVFG :byte ;     //DS4DEVFG	Flag byte
   DS4DEVTL : word;     //DS4DEVTL	Device tolerance.
   DS4DEVDT,            //DS4DEVDT	Number of DSCBs per track.
   DS4DEVDB : byte;     //DS4DEVDB	Number of PDS directory blocks per track.
end;


{ record format
 10 . . . . . . DS1RECFF Fixed length.
 01 . . . . . . DS1RECFV Variable length.
 11 . . . . . . DS1RECFU Undefined length.
. . 1 . . . . . DS1RECFT Track overflow.
. . . 1 . . . . DS1RECFB Blocked; cannot occur with undefined.
. . . . 1 . . . DS1RECFS
                  Fixed length: standard blocks; no truncated blocks or unfilled tracks except possible the last block and track.
                  Variable length: spanned records.
}



p_dscb1=^dscb_1;
dscb_1 =packed record
  dsn : array[0..43] of char;       //  key code for VTOC labels: 44 times 0x04
  idfmt : byte;                     // format identifier
  f1_ser_num : array[0..5] of char; // data set serial number
  f1_vol_seq : word;                // vol seq num          used to point to dscb3 extents....
  f1_cre_year: byte;
  f1_cre_day : word;
  f1_exp_year: byte;
  f1_exp_day : word;
  f1_extents : byte;
  f1_NOBDB   : byte;
  f1_DS1FLAG1: byte;
  f1_syscd   : array[0..12] of byte;
  f1_last_year:byte;
  f1_last_day : word;
  f1_DS1SMSFG : byte;                   //* system managed storage indicators */
  f1_DS1SCXTF : array[0..2] of byte;    //* sec. space extension flag byte */
  f1_DS1DSRG1 : byte;                   //* data set organisation byte 1 */
  f1_DS1DSRG2 : byte;                   //* data set organisation byte 2 */
  f1_DS1RECFM : byte;                   //* record format */
  f1_DS1OPTCD : byte;                   //* option code */
  f1_DS1BLKL  : word;                   //* block length */
  f1_DS1LRECL : word;                   //* record length */
  f1_DS1KEYL  : byte;                   //* key length */
  f1_DS1RKP   : word;                   //* relative key position */
  f1_DS1DSIND : byte;                   //* data set indicators */
  f1_DS1SCAL1 : byte;                   //* secondary allocation flag byte */
  f1_DS1SCAL3 : array[0..2] of byte;    //* secondary allocation quantity */
  f1_DS1LSTAR  : h_TTR;                 //* last used track and block on track */
  f1_DS1TRBAL  : word;
  f1_res1     :word;                    //* reserved */
  f1_DS1EXT1,                           //* first extent description */
  f1_DS1EXT2,                           //* second extent description */
  f1_DS1EXT3 : t_extent;                //* third extent description */
  f1_DS1PTRDS: h_CCTTR;                 //* possible pointer to f2 or f3 DSCB */
end;



// dscb 4 - multiples extents
p_dscb3=^dscb_3;
dscb_3 =packed record
  id03 : array[0..3] of byte;       //  key code for VTOC labels: 4 times 0x03
  f3_ext1 : array [0..3] of t_extent;
  idfmt : byte;                     // format identifier
  f3_ext2 : array [0..8] of t_extent;
  f3_DS1PTRDS: h_CCTTR;         //* possible pointer to f2 or f3 DSCB */
end;






// dscb4 - volume descriptor
p_dscb4= ^dscb_4;
dscb_4 =packed record
  keycd : array[0..43] of byte;  //  key code for VTOC labels: 44 times 0x04
  idfmt : byte;                  // format identifier
  f4_high_dscb:t_cyl_trk_rec;    // highest address of a format 1 DSCB
  f4_n_dscb : word;              // number of available DSCBs
  f4_aalt_cc,
  f4_aalt_hh : word;             // CCHH of next available alternate track */
  f4_n_rem_at: word;             // number of remaining alternate tracks
  f4_v_ind  ,                    // VTOC indicators
  f4_n_ext  ,                    // number of extents in VTOC
  f4_sms_i  ,                    // system managed storage indicators
  f4_devac  : byte;              // number of alternate cylinders.
  f4_dev_c  : vol_struct;
  f4_vsam_time : array[0..7] of byte;    // VSAM time stamp
  f4_vsam_ind  : array[0..2] of byte;    // VSAM catalog indicator
  f4_vsam_cat  : array[0..7] of byte;    // VSAM volume/catalog match time stamp
  f4_res       : array[0..4] of byte;    // reserv
  f4_f6_ptr    : array[0..4] of byte;    // pointer to first format 6 DSCB
  f4_vtoc_extent : t_extent;
  f4_res2      : array[0..9] of byte;
  f4_eflvl     : byte;                   // extended free-space management level
  f4_fs_cc,                              // pointer to extended free-space info
  f4_fs_hh     : word;
  f4_fs_bb     : byte;
  f4_res3      : array[0..8] of byte;
end;



p_dscb5= ^dscb_5;
dscb_5 =packed record
  f5_id05 : array[0..3] of byte;       //  key code for VTOC labels: 4 times 0x05
  f5_ex05 : array[0..7] of h_CCTTR;    //  Available  extents
  f5_idfmt : byte;                     // format identifier $F5
  f5_ex08: array[0..17] of h_CCTTR;   // 18 entries
  f5_next_05 : h_CCTTR;
end;



t_hercules_header = packed record
      dev_id : array[1..8] of char;               //* Device identifier
      dev_head,                                   //* #of heads per cylinder
      dev_trk_size  : integer; //  rev_int;       //* Track size
      dev_type,                                   //* Last 2 digits of device type  (0x80=3380, 0x90=3390)
      dev_seq : byte;                             //* CKD image file sequence no.   (0x00=only file, 0x01=first
      dev_highcyl : word;                         //* Highest cylinder number on  this file, or zero if this   is the last or only file
      reserv : array[1..492] of byte;
end;
{
CKDDASD_DEVHDR=packed record            // {                 /* Device header             */
        devid:array[0..7] of char;      // Device identifier         */
        heads:integer;                  //* #of heads per cylinder
        trksize:integer;                //* Track size (reverse order)*/
        devtype,                        // Last 2 digits of device type
                                        //   (0x80=3380, 0x90=3390)    */
        fileseq:byte;                   // CKD image file sequence no.
                                        //   (0x00=only file, 0x01=first file of multiple files)   */
        highcy:word;                    ///* Highest cylinder number on this file, or zero if this is the last or only file
end;


cdevhdr.numl1tab = (volcyls * heads + 255) / 256;
(3339*15)/256

cdevhdr.numl2tab = 256;

}

t_hercules_device = packed record          //* Compress device header    */
   c_vrm : array[1..3] of char;            //* Version Release Modifier  */
   c_options: byte;                        //* Options byte              */
   c_numl1tab,                             //* Size of lvl 1 table       */
   c_numl2tab,                             //* Size of lvl 2 tables      */
   c_size,                                 //* File size                 */
   c_used,                                 //* File used                 */
   c_free,                                 //* Position to free space    */
   c_free_total,                           //* Total free space          */
   c_free_largest,                         //* Largest free space        */
   c_free_number,                          //* Number free spaces        */
   c_free_imbed:integer;                   //* Imbedded free space       */
   c_cyls : integer;                       //* Cylinders on device       */
   c_nullfmt :byte;                        //* Null track format         */
   c_compress:byte;                        //* Compression algorithm     */
   c_compress_parm:word;                   //* Compression parameter     */
   c_resv2 :array[1..464] of byte;         //* Reserved                  */
   end;


  vol_label =  packed record
      volkey : array[0..3] of char;       // volume label
      vollbl : array[0..3] of char;       // relative volume group $f1
      vol_id : array[0..5] of char;       // volid
      volsecurity : byte;                 // secur
      vtoc_pointer: t_cyl_trk_rec;        // pointer to first vtoc trk rec

      res01  : array[1..5] of byte;
      cisize,
      lbl_ci,
      lab_ci,
      res02 :cardinal;
      vtoc_owner :array[1..14] of char;
end;
p_volume=^vol_label;
 // The HA contains 0CCHH, that is, a byte of zeroes,
 // 2 bytes indicating the cylinder of the track, and
 // 2 bytes indicating the head of the track on the cylinder.
 // Both CC and HH are stored in big-endian byte order. The track is computed by
 // trk = (((CC[0] << 8) + CC[1]) * trks_per_cyl) + (HH[0] << 8) + HH[1]

{
c_HA  = packed record = cckddiag
    tipo : byte;
    cyl,
    trk : word;
    end;
}

type

// hercules dasd track compression
c_l1_tab = packed record           //  device constants */
  ptr   : array[0..max_l1_tab] of integer;
end;

p_l2_tab=^c_l2_tab;
c_l2_tab = packed record          //* Level 2 table entry       */
   pos  : cardinal;               //* Track offset              */
   len,                           //* Track length              */
   x: word;                       //* Track size [deprecated]   */
end;


t_CKDDASD_TRKHDR=packed record   //* Track home address        */
   bin:byte;                     //* Bin number                */
   cyl,                          //* Cylinder number           */
   head:word;                    //* Head number               */
end;

t_bdw=packed record              // variable block
 blocklen:word;
 may31bit:word;                  // bit 0 =1 --> len = 31 bits
end;

t_rdw=packed record              // ibm variable record
   reclen:word;
   reserved:word;
end;


const


ebcdic_to_ascii : array[0..255] of char = (
//0   1   2   3   4   5   6   7   8   9   a   b   c   d   e   f
 '.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.',   // 0
 '.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.',   // 1
 '.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.',   // 2
 '.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.',   // 3
 ' ','.','.','.','.','.','.','.','.','.','.','.','<','(','+','!',   // 4 4B = dot
 '&','.','.','.','.','.','.','.','.','.','!','$','*',')',';','.',   // 5
 '-','/','.','.','.','.','.','.','.','.','.',',','%','_','>','?',   // 6
 '.','.','.','.','.','.','.','.','.','.',':','#','@',#39,'=','"',   // 7
 '.','a','b','c','d','e','f','g','h','i','.','.','.','.','.','.',   // 8
 '.','j','k','l','m','n','o','p','q','r','.','.','.','.','.','.',   // 9
 '.','.','s','t','u','v','w','x','y','z','.','.','.','.','.','.',   // A
 '.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.',   // B
 '{','A','B','C','D','E','F','G','H','I','.','.','.','.','.','.',   // C
 '}','J','K','L','M','N','O','P','Q','R','.','.','.','.','.','.',   // D
 '\','.','S','T','U','V','W','X','Y','Z','.','.','.','.','.','.',   // E
 '0','1','2','3','4','5','6','7','8','9','.','.','.','.','.','.');  // F

ascii_to_ebcdic:array [0..255] of byte=(
//0 1   2   3   4   5   6    7   8   9   a    b   c   d   e   f
000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000, //0
000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000, //1
064,090,127,123,091,108,080,125,077,093,092,078,107,096,075,097, //2
240,241,242,243,244,245,246,247,248,249,122,094,076,126,110,111, //3
124,193,194,195,196,197,198,199,200,201,209,210,211,212,213,214, //4
215,216,217,226,227,228,229,230,231,232,233,000,224,000,000,109, //5
000,129,130,131,132,133,134,135,136,137,145,146,147,148,149,150, //6
151,152,153,162,163,164,165,166,167,168,169,192,000,208,000,000, //7
000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000, //8
000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,
000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,
000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,
000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,
000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,
000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,
000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000);

// units
  s_giga=1024 * 1024 * 1024;
  s_mega=1024 * 1024;
  s_kilo=1024;


// main option flags
  option_po_size=1;
  option_po_linkeddate=2;
  option_po_recs=4;
  option_filter_80=8;
  option_filter_U=16;

  // for show PO
  option_show_trk=8;
  option_show_rec=16;
  option_show_len=32;
  option_show_hexa=64;
  option_show_alias=128;
  option_only_open=256;       // for multiples process - vtoc list, member find etc..
  option_find_initial=512;
  option_find_partial=1024;
  option_find_dataset=2048;
  option_find_text   =4096;
  option_type_all=8192;
  option_type_pds=16384;
  option_type_ps =32768;
  option_type_vsam=65536;
  option_type_hps=65536*2;
  option_type_pdse=65536*4;




// recfm
  recfm_F=1;
  recfm_V=2;
  recfm_U=4;
  recfm_VB=8;
  recfm_VBS=16;

{  disks parameters

   hercules use until 3390-3 or 3399 cyl / 15 tracks

xdev_cap = packed record
     cap_type:word;
     cap_byte:byte;
     cap_model:byte;
     cap_cyl : word;
     cap_alt : byte;
     cap_trk_cyl : word;
     cap_trk : word;
end;


dsk_tab : array[1..12] of  dev_cap = (
(cap_type : 2305;cap_byte:$05; cap_model:     0;cap_cyl:       48;cap_alt:       6;cap_trk_cyl:       8;cap_trk:    14136;),
(cap_type : 2305;cap_byte:$05; cap_model:     2;cap_cyl:       96;cap_alt:      12;cap_trk_cyl:       8;cap_trk:    14660;),
(cap_type : 2311;cap_byte:$11; cap_model:     0;cap_cyl:      200;cap_alt:       3;cap_trk_cyl:      10;cap_trk:     3625;),
(cap_type : 2314;cap_byte:$14; cap_model:     0;cap_cyl:      200;cap_alt:       3;cap_trk_cyl:      10;cap_trk:     7294;),
(cap_type : 3330;cap_byte:$30; cap_model:     0;cap_cyl:      404;cap_alt:       7;cap_trk_cyl:      19;cap_trk:    13165;),
(cap_type : 3330;cap_byte:$30; cap_model:     2;cap_cyl:      808;cap_alt:       7;cap_trk_cyl:      19;cap_trk:    13165;),
(cap_type : 3340;cap_byte:$40; cap_model:     0;cap_cyl:      348;cap_alt:       1;cap_trk_cyl:      12;cap_trk:     8535;),
(cap_type : 3340;cap_byte:$40; cap_model:     2;cap_cyl:      696;cap_alt:       2;cap_trk_cyl:      12;cap_trk:     8535;),
(cap_type : 3380;cap_byte:$80; cap_model:     0;cap_cyl:      885;cap_alt:       1;cap_trk_cyl:      15;cap_trk:    47476;),
(cap_type : 3390;cap_byte:$90; cap_model:     1;cap_cyl:     1113;cap_alt:       1;cap_trk_cyl:      15;cap_trk:    56664;),
(cap_type : 3390;cap_byte:$90; cap_model:     2;cap_cyl:     3339;cap_alt:       1;cap_trk_cyl:      15;cap_trk:    56664;),
(cap_type : 3390;cap_byte:$90; cap_model:    27;cap_cyl:    32760;cap_alt:       1;cap_trk_cyl:      15;cap_trk:    56664;));

//* name        type model clas code prime a hd    r0    r1 har0   len sec    rps  f f1  f2   f3   f4 f5 f6  cu */



ibm_products:array[0..60] of string=(



  '360S-AS-036|S/360 OS ASSEMBLER (E)|360SAS037',
  '360S-AS-037|S/360 OS ASSEMBLER (F)|360SAS037',
  '5734-AS1|OS ASSEMBLER H|5734AS100',
  '5752-SC103|OS/VS ASSEMBLER (XF)|5741SC103',
  '5668-962|ASSEMBLER H V2|566896201',
  '5696-234|HIGH-LEVEL ASSEMBLER|569623400',
  '360S-CO-503|S/360 OS COBOL (E)|360SCO503',
  '360S-CB-524|S/360 OS COBOL (F)|360SCB524',
  '360S-CB-545|S/360 OS FULL ANS COBOL V1 V2|360S-CB-545',
  '5734-CB1|OS FULL ANS COBOL V3  (ANS3)|5734CB1',
  '5734-CB2|OS FULL ANS COBOL V4  (ANS4)|5740CB1',
  '5740-CB1|OS/VS COBOL R2M3 R2M4 (VSR1)|5740CB103',
  '5668-958|VS COBOL II|566895801',
  '5688-197|COBOL/370 or COBOL for MVS & VM|566895807',
  '5648-A25|COBOL for OS/390 and VM V2|5648A2500',
  '5655-G53|Enterprise COBOL for z/OS V3|5655G5300',
  '5655-S71|Enterprise COBOL for z/OS V4|5655S7100',
  '360S-FO-092|S/360 OS FORTRAN IV (E)|',
  '360S-FO-520|S/360 OS FORTRAN IV (G)|',
  '360S-FO-500|	S/360 OS FORTRAN IV (H)|',
  '5734-FO1|FORTRAN CODE AND GO COMPILER|',
  '5734-FO2|FORTRAN IV G1|',
  '5734-FO3|FORTRAN IV H EXTENDED|',
  '5799-AAW|FORTRAN IV H EXTENDED PLUS|',
  '5748-FO3|VS FORTRAN V1|',
  '5668-806|VS FORTRAN V2 (COMP/LIB/DEBUG)|5668-806',
  '5688-087|VS FORTRAN V2 (COMP/LIB)|',
  '5796-PKR|Ext. Exponent Range for FORTRAN|5796-PKR',
  '360S-NL-511|S/360 OS PL/1 (F)|',
  '5734-PL1|OS PL/I OPTIMIZING COMPILER V1|5734-PL1',
  '5734-PL2|OS PL/I CHECKOUT COMPILER|',
  '5734-PL3|OS PL/I Opt Comp Lib Kanji Name Support|',
  '5668-909|OS PL/I V2 (COMP/LIB/TEST)|',
  '5668-910|OS PL/I V2 (COMP/LIB)|5668-910',
  '5668-911|OS PL/I V2 (Library)|',
  '5688-235|PL/I for MVS AND VM V1|5688-235',
  '5655-B22|VisualAge PL/I for OS/390 V2|5655-B22',
  '5655-H31|Enterprise PL/I for z/OS V3|5655-H31',
  '5713-AAG|C for SYSTEM/370 (MVS)|',
  '5688-040|C/370 COMPILER V1|5688040',
  '5688-187|C/370 COMPILER V2|5688187',
  '5688-216|SAA AD/Cycle C/370|5688216',
  '5655-121|C/C++ for MVS/ESA|5688216',
  '5645-001|C/C++ OS/390 R2|5645001',
  '5647-A01|C/C++ OS/390 R4|5647A01',
  '5694-A01|C/C++ z/OS R5|5694A01',
  '5668-899|APL2 VERSION 1|5688-899',
  '5688-228|APL2 VERSION 2|5688-228',
  '5668-767|VS PASCAL|566876701',
  '5695-013|REXX/370|569501301',
  '5744-AN1|ACF/NCP|5744AN101',
  '|ACF/NCP|566893801',
  '|ASSEMBLER H V2 (bizarre)|516896201',
  '360S-ED-521|S/360 OS LINKAGE EDITOR (F)|360SED521',
  '5752-SC104|OS/VS LINKAGE EDITOR|5752SC104',
  '5665-284|DFP/XA LINKAGE EDITOR|566528408',
  '5665-295|DFP/370 LINKAGE EDITOR|566529508',
  '5695-DF1|DFSMS/MVS BINDER|5695DF108',
  '5695-PMB|z/OS BINDER|5695PMB01',
  '|SAS/C|SDS080888',
  '|SAS/C|BLD121988');


 }
