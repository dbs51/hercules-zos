
const


   HFS_PAGELEN=4096;    // default hfs page len
   HFS_CO=$c0;
   HFS_ZEROS:array [0..7] of byte =(0,0,0,0,0,0,0,0);



   //HFS_ND_BLANK=$4040C4D5;             // const NDbb
   HFS_ND_TAG:array [0..1] of char=(chr($D5),chr($C4));                   // const ND
   HFS_AD_BLANK=$4040C4C1;             // const ADbb
   IFSP_LITERAL=$C9C6E2D7;             // LITERAL ID 'IFSP'
   IFSP_EBCDIC :array[0..3] of char =(chr($C9),chr($C6),chr($E2),chr($D7));         // LITERAL ID 'IFSP'
   FORMAT1_LITERAL:array[0..3] of char =(chr($C6),chr($D4),chr($E3),chr($F1));


   S_IFLNK  = $A000; // symbolic link
   S_IFREG  = $8000; // regular file
   S_IFBLK  = $6000; // block device
   S_IFDIR  = $4000; // directory
   S_IFCHR  = $2000; // character device
   S_IFIFO  = $1000; // fifo

   HFS_FLAG_ACTIVE=1;
   HFS_FLAG_NEXT_INODE=2;
   HFS_FLAG_SYMBOLIC=4;
   HFS_FLAG_DIR=8;
   OPTION_SAVE_BINARY=1;
   OPTION_SAVE_ASCII =2;
   OPTION_SHOW_ASCII=4;
   OPTION_AUTO_OPEN=8;
   
   ENV_HFS=1;
   ENV_PDSE=2;


   inode_to_print =64;

   OFFSET_TAG_ND_AD=11;
   OFFSET_DIR_VALID=$f76;
   HFS_FOLDER='H:\Temp\HFS\';

   OFFSET_IFSP=60;


   OFFSET_NDB_FIRST=307;
   HFS_NAME_OFFSET=5;
   HFS_FIRST_OFFSET= 72;  // point to first group on parms
   HFS_PAGE0_TAG_OFFSET=37;
   HFS_DIRNAME_TEMPLATE=52;   // ND repeat template at (52)


type
t_inode_data=record
   page,
   flags,            // 4 = active
   len,
   symb_offset,
   igw,
   page_offset:integer;
   dt:double;
//   page_qtd:byte;
end;


t_inode_entry=record
   inode,
   flags:integer;
   page_parm_offset,
   igw_offset,
   dir_symbolic,
   dir_inode,
   file_type,
   file_len:cardinal;
   file_date:double;
end;
t_inode_header=array of t_inode_entry;



t_hfs_dir=record
   page,
   inode:integer;
   attr:string;
   qtd_dir:integer;
   owner,
   group:string;
   size:integer;
   date:TDateTime;
   name:string;
   igw_ofs,
   parm_ofs:cardinal;
   page_block:integer;
end;


t_hfs_dir_entry=record
  page,                  //ex page 3/4 - root dir
  flags,                 // flags ??
  index:integer;         //  offset 13(d)
  qtd_dir,
  qtd_group:word;

end;
t_hfs_dir_map=array  of t_hfs_dir_entry;


t_hfs_page_zero_sb=packed record // page zero superblock list
 sb,z:cardinal;
end;

t_hfs_page_zero=packed record
   igw:array[0..7] of char;  // IGWVDFbb
   w1,w2:word;
   c1,c2,c3,c4:cardinal;
   xblocks:cardinal;
   z2:byte;
   w3,w4:word;
   volid:array[0..5] of char;
   z3:byte;
   w5:word;
   AD:array[0..9] of char;
   z4:byte;
   w6:word;
   FC:array[0..4] of cardinal;
   FW:array[0..5] of word;
   z5:byte;
   ADCD:array[0..7] of char;
   z6:array[0..2] of byte;
   qtd_superblock:byte;
   z7:array[0..2] of byte;
   superblocks:array[0..254] of t_hfs_page_zero_sb;
end;

p_hfs_page_zero=^t_hfs_page_zero;









t_hfs_page1=packed record
   blkcount:integer;
   c2:array[0..3] of Cardinal;
   TWO:array[0..3] of char;  // bTWO
   //naosei:array[0..7] of byte;
   t:int64;
   dsn:array[0..43] of char;   // optional - my be zero
   z1:byte;
   c5:array[0..4] of Cardinal;
end;
p_hfs_page1=^t_hfs_page1;


t_hfs_AD_header=packed record                  // page2
   version:word;
   volid:array[0..5] of char;
   z2:byte;
   w2:word;
   AD:array[0..9] of char;
   w3:word;
   b1,b18:byte;
   w4,w5,w6:word;
   cc:array[0..2] of cardinal;
   size:word;
   z3:byte;
   freelist:byte;
   f52:array[0..6] of byte;
   min,max:cardinal;
   f53:array[0..52-9] of byte;
   lhfsname:byte;
   hfsname:array[0..44] of char;
end;
p_hfs_AD_header=^t_hfs_AD_header;

t_pdse_AD_header=packed record                  // page2
   version:word;
   volid:array[0..5] of char;
   z2:byte;
   w2:word;
   AD:array[0..9] of byte;
   w3:word;
   b1,b18:byte;
   w4,w5,w6:word;
   cc:array[0..2] of cardinal;
   size:word;
   z3:byte;
   freelist:byte;
   f52:array[0..6] of byte;
   min,max:cardinal;
   f53:array[0..52-9] of byte;
   lhfsname:byte;
   hfsname:array[0..44] of char;
end;
p_pdse_AD_header=^t_pdse_AD_header;



t_hfs_AD_pad=packed record       // parms in AD page
   len:word;
   f1,f2,f3,f4,f5,f6:word;
   d:array[0..64] of byte;
end;
p_hfs_AD_pad=^t_hfs_AD_pad;



t_group=packed record
   g1,g2:word;
   gq:byte;
end;
p_group=^t_group;

t_list_blocks=record
 bnum:array  of integer;
end;
p_list_blocks=^t_list_blocks;











t_hfs_dir_name=packed record
 size:word;
 const_c0:byte;
 name_repeat:byte;
 name_len:byte;
 name:array[0..10] of byte;
end;
p_hfs_dir_name=^t_hfs_dir_name;
// logs phfs $00 $0D $C0 $0D $EE $D1 $A4 $93 $F0 $00 $00 $00 $0B $00 $0C $C0
//      IFSP:
//      post $C9 $C6 $E2 $D7 $01 $00 $00 $40 $00 $00 $00 $00 $00 $00 $00 $00 $07 $07 $07 $00 $80 $00 $00 $00 $02 $02 $02 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00
//001AC000 FE 4B
// 01 00000000 		01 000000xx 00030000 0001 00000000

t_hfs_post_name=packed record
   tipo:byte;
   c1:cardinal;
   b1:byte;
   inode:cardinal;
   w1,w2,nlen,w3,w4:word;
   t5:array[0..10] of byte;
end;
p_hfs_post_name=^t_hfs_post_name;

t_hfs_post_name_27=packed record    // ver - cambalacho
   inode:cardinal;
end;
p_hfs_post_name_27=^t_hfs_post_name_27;

{

00E3C00E 00900100 000000
igw
 0 1 2 3 4  5 6 7 8  9 0 1 2  3 4 5 6  7 8 9 0  1 2 3 len      b1 t1                t2                t3                b2
C9C7E6D7C6 C1D94000 0000D801 00000000 00000000 000000 000008F0 00 E16D3AAA EFB12000 E16D3AA6 058EC000 E16D3AA6 058EC000 00 0008 00000001C9 C6E2D701 00004000 00000000 000A3306 04040000 00000002 02020000

}
t_igwpfar=packed record
 aa:array[0..23] of byte; // orig 0..51 = 52 bytes
 len:cardinal;
 b1:byte;
 time1,time2,laccess:int64;
 b2:byte;
 inode:word;
 tipo:cardinal;
end;
p_igwpfar=^t_igwpfar;



type t_ND_page_blank=packed record             // to find NDbbbbbb offset=3000/4000 etc
 version:word;
 tag:array[0..18] of byte;
 w4:array[0..4] of word;
 inode:cardinal;
 c1,c2:cardinal;
 qtd_dirs:word;
 qtd_groups:byte;
 b4:array[0..5] of byte;
 //m:cardinal;
 //b5:byte;
end;
p_page_ND_blank=^t_ND_page_blank;




type t_ND_page_zero=packed record             // to find NDbbbbbb offset=3000/4000 etc

 version:word;
 tag:array[0..10] of byte;
 dir_page:cardinal;
 bb:array[0..26] of byte;
 //b1:byte;
 //next_inode:cardinal;
 //b2:byte;
 //w4:array[0..4] of word;
 //c1,c2,c3:cardinal;
 qtd_dirs,
 qtd_groups:byte;
 wc0,
 flags:word;
end;

p_page_ND_zero=^t_ND_page_zero;

type t_AD_page=packed record
 //b1:byte;
 w1:word;
 filler:array[0..8] of byte;
 dir:array[0..1] of byte;
 inode:cardinal;
 b2,b3,b4:byte;
 f22:array[0..21] of byte;
 qtd_dirs:word;
 qtd_groups:byte;
 b5:byte;
 mtime:cardinal;
 b6:byte;
end;



type t_group_entry=packed record      //   BBBBLLLLqq  group entry
   blksize,recl:word;
   qtd:byte;
end;
p_group_entry=^t_group_entry;



//sizeof(t_ifsp)====63

t_IFSP=packed record             // macro IRRPIFSP
IFSP_ID:cardinal;                // DS CL4       LITERAL ID 'IFSP'                     03350000
IFSP_VERS:byte;
res1:byte;                       // DS CL1       Version Number for FSP                03400000
                                 // DS CL1       Reserved                              03450000
IFSP_LEN:word;                   // DS CL2       Length of the FSP                     03500000
IFSP_OWN_UID,                    // DS F         OWNING UID                            03550000
IFSP_OWN_GID:cardinal;           // DS F         OWNING GID                            03600000
//IFSP_PERMISSION                // DS 0CL4      Permission bits                       03650000
//IFSP_OWNER_8                      DS 0CL1      Owner permission bits                 03700000
IFSP_OWNER,                      // DS CL1       Owner permission bits                 03750000
//IFSP_GROUP_8                      DS 0CL1      Group permission bits                 03800000
IFSP_GROUP,                      // DS CL1       Group permission bits                 03850000
//IFSP_OTHER_8                      DS 0CL1      Other permission bits                 03900000
IFSP_OTHER,                      // DS CL1       Other permission bits                 03950000
IFSP_FLAG2:byte;                 // DS CL1       Additional FSP flags             @L1A 04000000

//*  Equates for IFSP_FLAG  SYS1.MACLIB(IRRISPF)
//IFSP_DIRECTORY EQU X'80000000' File is a directory                05600000
//IFSP_S_ISVTX   EQU X'00000004' S_ISVTX                            05650000
//IFSP_S_ISUID   EQU X'00000002' S_ISUID                            05700000
//IFSP_S_ISGID   EQU X'00000001' S_ISGID                            05750000


IFSP_FLAG:cardinal;              // DS CL4       File flags                            04050000
//IFSP_USER_AUDIT_OPTS DS 0CL4      User Audit Options                    04100000
IFSP_USER_AUDIT_READ,            // DS CL1       Read Access Options                   04150000
//IFSP_USER_AUDIT_WRITE DS CL1      Write Access Options                  04200000
IFSP_USER_AUDIT_EXEC_SCH,        // DS CL1   Execute/Search Access Options         04250000
res2,                            // DS CL1       Reserved                              04300000
//IFSP_ADTR_AUDIT_OPTS DS 0CL4      Auditor Audit Options                 04350000
IFSP_ADTR_AUDIT_READ,            // DS CL1       Read Access Options                   04400000
IFSP_ADTR_AUDIT_WRITE,           // DS CL1      Write Access Options                  04450000
IFSP_ADTR_AUDIT_EXEC_SCH,        // DS CL1   Execute/Search Access Options         04500000
res3:byte;                       // DS CL1       Reserved                              04550000
IFSP_SECLABEL:array[0..7] of char;//DS CL8       SECLABEL                         @L2C 04600000
res4:array[0..23] of byte;       // DS CL24      Reserved                              04650000
end;
p_IFSP_data=^t_IFSP;
{
parm len
1     27    001B C00E 0030 0200              no name
2     34    0022 C00F 0004 0000
      34    0022 C00E 0070 0300
3     55    0037 C00E 0040 0100

4     28    001C C00E 0070 0200              RES4
5     37    0025 C005 0003 0000              RES4
6     51    0033 C00F 0004 0000              RESERV6
7     78    004E C00B 0003 0000              VVVVVV...NDbbbbbbbb
      43    002B C005 0003 0000              RESERVED10
     227    00E3 C00E 0090 0100              IGWPFAR
     232    00E8 C009 0008 0000 0000  9001
     232    00E8 C009 000B 0000 0000  9001
     232    00E8 C009 000C 0000 0000  9001
      20    0014 C00F 0005                 Symbolic link
      27    0027 c005 0001                 dsname ex HPS.USERDIR.HFS


     }
type t_mount_point=record
   name,mounted_at:string;
end;
//if .w[0]=swap(c009) and w[4]=swap(9005) then lsym
//      len   0    1   2    3     4    5  6     7     8  lsym symb
//  31 001F C009 0017 0000 0000 9005 0000 0000 0100 0000 0009 4B4B614B4B618289950050
//     001A C009 000B 0000 0000 9005 0000 0000 0100 0000 0004 6196 97A3 = /opt

type t_symbolic1=packed record
   len:word;
   w: array[0..8] of word;
   lsym:word;
   symb:array[0..255] of char;
end;
p_symbolic1=^t_symbolic1;


// if (w[0]=swap($c009)) and (w[1]=swap($0005))
//      len   0    1   2    3     4    5  lsym
//     0018 C00F 0005 0000 0000 0100 0000 0008 61A28194 979385A2
type t_symbolic2=packed record
   len:word;
   w: array[0..5] of word;
   lsym:word;
   symb:array[0..255] of char;
end;
p_symbolic2=^t_symbolic2;



t_page_matrix=packed record
 page:cardinal;
 q:byte;
 b6:array[0..4] of byte;
end;
p_page_matrix=^t_page_matrix;

//0000021A 00 0000000000 0000021C00 0000000000 0000021E02 00


//0027C009     0020     0000 00007003 00000000 000001C6 D7D4C8C6 E2D7C5D9 C6000000 000001E5 01000000
type t_block_page=packed record
  len:word;
  c009:word;
  inode:word;
  ww: array[0..5] of word;
  b0:byte;
  FPMHFSPERF:array[0..9] of char;
  b1,b2,b3:byte;
  page:cardinal;
  q:byte;
end;

//0022C00E 00700300 00000000 0001C6D7 D4C8C6E2 D7C5D9C6 00000000 00010701 000000
type t_block_page22=packed record
  len:word;
  ww: array[0..5] of word;
  FPMHFSPERF:array[0..9] of char;
  b1,b2,b3:byte;
  page:cardinal;
  q:byte;
end;

//0031C009     0023     0000 00007003 00000000 000002C6 D7D4C8C6 E2D7C5D9 C6000000 00000128 20000000 00000000 01660D00 0000
type t_block_page31=packed record
  len:word;
  c009:word;
  inode:word;
  ww: array[0..5] of word;
  b0:byte;
  FPMHFSPERF:array[0..9] of char;
  b1,b2,b3:byte;
  pages:array[0..1] of t_page_matrix;
end;

type t_block_page3c=packed record // len 60  - tree pages...
  len:word;
  c009:word;
  ba:byte;
  inode:word;
  bb:byte;
  ww: array[0..5] of word;

  FPMHFSPERF:array[0..9] of char;
  b1,b2,b3:byte;
  pages:array[0..2] of t_page_matrix;
end;


type t_block_set=packed record   // array of blocks until 4 ??
   qt:word;
   name:array[0..9] of char; // or RESERVED10
   b1,b2,b3:byte;
   pages:array[0..16] of t_page_matrix;
end;
p_block_set=^t_block_set;

type t_page_with_inode=packed record // tip 9
  len:word;
  cxxx:word;
  inode:word;
end;
p_page_with_inode=^t_page_with_inode;


t_parm_80=packed record             //  to compute flag valid next inode
   a:array[0..47] of byte;
   flag:cardinal;
end;
p_parm_80=^t_parm_80;

type t_parm_type=packed record
  len:word;
  f1,f2,f3,g1:word;
  tip,ofs:byte;
end;

type t_blocks_type1=packed record    // ex 1529,39...
   len,f1,f2,f3,f4,f5,f6,f7:word;
   b1:byte;
   qtd:word;
   reserved:array[0..12] of byte;
   blocks:t_page_matrix;
end;
p_blocks_type1=^t_blocks_type1;
// len   f1   f2   f3              f4   f5   f6   f7 b1   qtd  0 1 2 3 4 5 6 7 8 9 0 1 2  1 2 3 4  q
//0027 C009 000B 0000            0000 7003 0000 0000 00  0001 C6D7D4C8C6E2D7C5D9C6000000 00000112 00 000000E3C00E0090010000

//0027 C009 0006 0000            0000 7003 0000 0000 00  0001 C6D7D4C8C6E2D7C5D9C6000000 00000109 02 000008



// ex                                0 1 2 3 4 5 6 7 8 9 0 1 2
// 1520 -> 05F0 C012 0002 8D00 0096 C6D7D4C8C6E2D7C5D9C6000000 0000F5D6 01 00000000 000000F5 DD010000 00000000 00F5E201 00000000 000000F5 E6010000 00000000 00F5FC01 00000000 000000F6 0A010000 00000000 00F61401 00000000 000000F6 1C000000 00000000 00F62101 00000000 000000F6 2B090000 00000000 00F63A
//          len   f1   f3   f3  qtd                            block set
type t_blocks_type2=packed record    // ex 1520
   len,f1,f2,f3:word;
   qtd:word;
   reserved:array[0..12] of byte;
   blocks:t_page_matrix;
end;
p_blocks_type2=^t_blocks_type2;

//                                              F P M H F S P E R F
//  ex:                                         0 1 2 3 4 5 6 7 8 9 0 1 2
//   44     002C C00E 0070 0300 0000 0000 0002 C6D7D4C8C6E2D7C5D9C6000000 000001F6 00 00000000 00000002 06000000 00
//          len    f1   f3   f3   f4   f5  qtd     0-12
//          0022 C00E 0070 0300 0000 0001 0001 D9C5E2C5D9E5C5C4F1F0000000 00000103 01 000000E3C00E0090
// HFSIN??  002C C00E 0070 0300 0000 0000 0002 C6D7D4C8C6E2D7C5D9C6000000 000001F6 00 00000000 000000020600000000E3C00E00900100000000C9C7E6D7C6

type t_blocks_type3=packed record
   len,f1,f2,f3,f4,f5:word;
   qtd:word;
   reserved:array[0..12] of byte;
   blocks:t_page_matrix;
end;
p_blocks_type3=^t_blocks_type3;


//   40     0028 C008 0001 0000 0000 0070 0300 0000 0000 0001C6D7D4C8C6E2D7C5D9C6000000 00000222 000000
//           len   f1  f2    f3  f4   f5   f6   f7   f8   qtd 0 1 2 3 4 5 6 7 8 9 0 1 2
type t_blocks_type4=packed record
   len,f1,f2,f3,f4,f5,f6,f7,f8:word;
   qtd:word;
   reserved:array[0..12] of byte;
   blocks:t_page_matrix;
end;
p_blocks_type4=^t_blocks_type4;



// PDSE name
//47 (  2F) 002F C00E 0060 0200 0000 00 C7 C4C5D2C5 E7D74000 00002401 000000FF FF000000 00000000 00000000 00000000 000000
type t_pdse_dir_entry=packed record
   len,f1,f2,f3:word;
   b1:byte;
   name:array[0..127] of byte;
end;
p_pdse_dir_entry=^t_pdse_dir_entry;



const
PARM_IGWPFAR=8;
PARM_IGWPFAR_SYM=9;

PARM_IGWPFAR_PAGE=13;
PARM_IGWPFAR_PAGE_TYPE2=11;
PARM_OFFSET_39=17;
PARM_OFFSET_34=26;




// tip 8 - no inode +blocks  tip 9 = inode num + blocks
parm_type:array[0..22] of t_parm_type =
(
 (len: 43;f1:$c005;f2:$0000;f3:$0000;tip: 8;ofs:12), //0 RESERVED10 no inode num 3 blocks
 (len: 27;f1:$c005;f2:$0001;f3:$0000;tip: 4;ofs: 0), //1 dsname
 (len: 34;f1:$c00f;f2:$0004;f3:$0000;tip: 1;ofs: 0), //2 no inode num - none
 (len: 55;f1:$c00e;f2:$0040;f3:$0100;tip: 1;ofs: 0), //3
 (len: 28;f1:$c00e;f2:$0070;f3:$0200;tip: 1;ofs: 0), //4 symbolic ??
 (len: 37;f1:$c005;f2:$0003;f3:$0000;tip: 1;ofs: 0), //5
 (len: 51;f1:$c00f;f2:$0004;f3:$0000;tip: 1;ofs: 0), //6
 (len: 78;f1:$c00b;f2:$0003;f3:$0000;tip: 1;ofs: 0), //7
 (len:227;f1:$c00e;f2:$0090;f3:$0100;tip: 2;ofs: 0), //8 inode
 (len:232;f1:$c009;f2:$0000;f3:$0000;tip: 1;ofs: 0), //9 maybe inode sym
 (len: 20;f1:$c00f;f2:$0005;f3:$0000;tip: 3;ofs: 0), //10 symbolic parm - var len from 11 to 255
 (len: 34;f1:$c00e;f2:$0070;f3:$0300;tip: 8;ofs:13), //11 offset to page matrix
 (len:233;f1:$c008;f2:$0001;f3:$0700;tip: 6;ofs: 0), //12
 (len:  0;f1:$09c0;f2:$0370;f3:$0000;tip: 9;ofs:18), //13 FPMHFSPERF inode num +blocknum type 13
 (len: 49;f1:$cccc;f2:$0000;f3:$0000;tip: 9;ofs:18), //14 FPMHFSPERF inode num +two blocknum+len
 (len: 60;f1:$c008;f2:$0000;f3:$0000;tip: 9;ofs:19), //15 FPMHFSPERF inode num + 3 blocks
 (len: 69;f1:$cccc;f2:$0000;f3:$0000;tip: 9;ofs:18), //16 FPMHFSPERF inode num + 4 blocks
 (len: 59;f1:$cccc;f2:$0000;f3:$0000;tip: 9;ofs:18), //17 FPMHFSPERF inode_num + 3 blocks
 (len: 44;f1:$c00e;f2:$0070;f3:$0300;tip: 8;ofs:13), //18 no inode num 2 blocks
 (len: 26;f1:$c009;f2:$000b;f3:$0000;tip: 3;ofs: 0), //19 symbolic link
 (len:134;f1:$c00e;f2:$0070;f3:$0300;tip: 8;ofs:13), //20 no inode num 11 blocks
 (len:  0;f1:$c009;f2:$0008;f3:$0000;tip: 3;ofs: 0), //21 symb link too var len
 (len:  0;f1:$c009;f2:$0000;f3:$7003;tip: 9;ofs:18)  //22xinode + 5 block
 );

 //11 inode > 255 ??

  {    26    001A C009 $00 $08 $0
  symb
           0 1 2 3  4 5  6 7  8 9 0 1  2 3 4 5  6 7 8 9  0 1
   26     001AC009 000B 0000 00009005 00000000 01000000 00046196 97A3 = /opt
   26     001AC009 0008 0000 00009005 00000000 01000000 00046182 8995
   one block
           0 1 2 3  4 5  6 7  8 9 0 1  2 3 4 5  6 7 8 9 0  1  2
          002BC005 0003 0000 00000003 00007003 00000000 0100 01D9C5E2C5D9E5C5C4F1F0 000000 00000103 01 000000 test RESERVED10
   43     002BC005 0003 0000 00000003 00007003 00000000 0100 01D9C5E2C5D9E5C5C4F1F0 000000 00000103 01 000000 work
          002BC005 0003 0000 00000003 00007003 00000000 0100 01D9C5E2C5D9E5C5C4F1F0 000000 00000103 01 000000  root
          002BC005 0003 0000 00000003 00007003 00000000 0100 01D9C5E2C5D9E5C5C4F1F0 000000 00000103 01 000000 web
           0 1 2 3  4 5  6 7                      8 9 0  1 2 3 4 5  6 7 8 9 0  1  2
   44     002CC00E 0070 0300                     000000 0000 02C6D7 D4C8C6E2 D7C5D9C6 00000000 0001F600 00000000 00000002 06000000 00

           0 1 2 3  4 5  6 7  8 9 0 1  2                      3 4 5  6 7 8 9 0  1  2
   34     0022C00E 0070 0300 00000000 00                     01C6D7D4C8C6E2D7C5D9C6 000000 000001F8 01 000000 user FPMHFSPERF

           0 1 2 3  4 5  6 7  8          9 0 1  2 3 4 5  6 7  8
   39     0027C009 0020 0000 00         007003 00000000 0000 01C6D7D4C8C6E2D7C5D9C6 000000 000001E5 01 000000
          0027C009 0022 0000 00         007003 00000000 0000 01C6D7D4C8C6E2D7C5D9C6 000000 000001ED 01 000000

3 blocks others
           0 1 2 3  4 5  6 7  8         9 0 1 2  3 4 5 6  7 8  9 0  1  2
   60     003CC008 0001 0500 00         00007003 00000000 0000 03C6D7D4C8C6E2D7C5D9C6 000000 00000142 00 0000000000 0000018200 0000000000 000001A2 00 000000
11 blocks
           0 1 2 3                       4 5 6 7 8 9 0   1 2  3
  134     0086C00E                      007003 00000000 0000 0BC6D7D4C8C6E2D7C5D9C6 00000000 00010D01 00000000 00000002 34030000 00000000 00028100 00000000 00000002 8C000000 00000000 00028F00 00000000 00000002 93000000 00000000 00029600 00000000 00000002 98000000 00000000 0002B900 00000000 00000002 CE000000 00000000 00035000 0000



1 block        f1   f2   f3   f4         f5
          0 1 2 3   4 5  6 7  8          9 0 1  2 3 4 5  6 7  8
   39     0027C009 0020 0000 0000       7003 00000000 0000 01C6D7D4C8C6E2D7C5D9C6 000000 000001E5 01 000000
2 block2
   49     0031C009 0023 0000 0000       7003 00000000 0000 02C6D7D4C8C6E2D7C5D9C6 000000 00000128 20 0000000000 000001660D 000000
3 blocks
           0 1 2 3  4 5  6 7  8         9 0 1  2 3 4 5  6 7  8 9 0  1  2
   59     003BC009 00DB 0000 0000       7003 00000000 0000 03C6D7D4C8C6E2D7C5D9C6 000000 0000014E 00 0000000000 0000016300 0000000000 00000179 02 000000


4 blocks
           0 1 2 3  4 5  6 7  8          9 0 1  2 3 4 5  6 7  8
   69     0045C009 00CB 0000 00         007003 00000000 0000 04C6D7D4C8C6E2D7C5D9C6 000000 00000141 00 0000000000 00000144 00 0000000000 00000146 00 0000000000 0000014A 03 000000

5 blocks
           0 1 2 3  4 5  6 7  8          9 0 1  2 3 4 5  6 7  8
   79     004FC009 003F 0000 00         007003 00000000 0000 05C6D7D4C8C6E2D7C5D9C600000000000175 00000000 00000000 02180400 00000000 0000021E 03000000 00000000 02250100 00000000 00000229 060000
6 blocks
   89     0059C009 00B2 0000 00         007003 00000000 0000 06C6D7D4C8C6E2D7C5D9C600 00000000 639E6100 00000000 00006400 87000000 00000000 648A7500 00000000 00006500 FF000000 00000000 6600FF00 00000000 00006700 2A0000
7 blocks
   99     0063C009 00A7 0000 00         007003 00000000 0000 07C6D7D4C8C6E2D7C5D9C6 000000 0000021B 00 0000000000 0000021D 0000 00000000 00000261 00000000 00000000 02630000 00000000 00000265 00000000 00000000 02210100 00000000 00000225 030000
8 blocks
  109     006DC009 00AA 0000 00         007003 00000000 0000 08C6D7D4C8C6 E2D7C5D9C6000000 00006308 7F000000 00000000 52690000 00000000 00005273 01000000 00000000 5DAF0900 00000000 00005DC1 00000000 00000000 5FF80700 00000000 00006000 05000000 00000000 60681D00 00037803 78060

9 blocks
  119     0077C009 001F 0000 00         007003 00000000 0000 09C6D7D4C8C6E2D7 C5D9C600 00000000 8A619E00 00000000 00008B00 FF000000 00000000 8C00FF00 00000000 00008D00 FF000000 00000000 8E00FF00 00000000 00008F00 FF000000 00000000 9000FF00 00000000 00009100 FF000000 00000000 9200F000 0000

                                                                                                                                       fill
10 blocks  len  f1   f2   f3              f4   f5    f6   f7 b1   qtd   reserved                                          blocks    q------ ----
  129     0081 C009 00BB 0000            0000 7003 0000 0000 00  000A C6D7D4C8C6E2D7C5D9C60000 00 000073   2C3F0000000000 00006158 05000000 0000 000061E80000 00000000
$         0027 C009 000B 0000            0000 7003 0000 0000 00  0001 C6D7D4C8C6E2D7C5D9C60000 00 00000112 00 000000E3C00E0090010000
1520
          05F0 C012 0002 8D00                                    0096 C6D7D4C8C6E2D7C5D9C60000 00 0000F5D6 01 00000000 000000F5 DD010000 00000000 00F5E201 00000000 000000F5 E6010000 00000000 00F5FC01 00000000 000000F6 0A010000 00000000 00F61401 00000000 000000F6 1C000000 00000000 00F62101 00000000 000000F6 2B090000 00000000 00F63A
          05F0 C012 0004 8B00                                    0096 C6D7D4C8C6E2D7C5D9C60000 00 0000FD9201 00000000 000000FD 99000000 00000000 00FD9E01 00000000 000000FD A6010000 00000000 00FDAC01 00000000 000000FD BC000000 00000000 00FDC700 00000000 000000FD D3000000 00000000 00FDE700 00000000 000000FD F6000000 00000000 00FE03


40 (  28) 0028 C008 0001 0000            0000 0070 0300 0000 000000 01C6D7D4C8C6E2D7C5D9C6000000000002 22000000

$0022C00E00700300000000010001D9C5E2C5D9E5C5C4F1F00000000000010301000000E3C00E0090
  if (pad^.f1=swap($c009)) and  (pad^.f5=swap($7003)) and qtd>0 then

  if (pad^.f1=swap($c00e)) and  (pad^.f2=swap($0070)) and (pad^.f3=swap($0300)) then
}








