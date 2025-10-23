
const

   PDSE_FIRST_OFFSET= 72;  // point to first group on parms
   PDSE_DIR_OFFSET=116;

   HFS_PAGELEN=4096;    // default hfs page len
   FORMAT1_LITERAL:array[0..3] of char =(chr($C6),chr($D4),chr($E3),chr($F1));
   PDSE_LINKED_TAG = 'IEWPLMH ';
   PDSE_TEXT_LITERAL:array[0..3] of char =(chr($C3),chr(0),chr(0),chr(0));

type


t_pdse_page0_sb=packed record // page zero superblock list
 sb,z:cardinal;
end;

t_pdse_page0=packed record
   igw:array[0..7] of char;  // IGWVDFbb
   w1,w2:word;
   c1,c2,c3,c4:cardinal;
   blocks:cardinal;
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
   superblocks:array[0..254] of t_pdse_page0_sb;
end;



t_pdse_page1=packed record
   blkcount:integer;
   c2:array[0..3] of Cardinal;
   TWO:array[0..3] of char;  // bTWO
   //naosei:array[0..7] of byte;
   t:int64;
   dsn:array[0..43] of char;   // optional - my be zero
   z1:byte;
   c5:array[0..4] of Cardinal;
end;

  {
   ver        volid z2   w2                 AD   w2   b1 b18   w4    5    6        0                d1 size
//3401D1C1 C4C9E2F2 00 0407 C1C44040404040404040 02A0 06  00 14F0 0000 0001 00000000 C41D74C8 30D09283 0027 07 F0C005D3 0FFE0000
    max        cc order
00000003 00000000 001B  00001001 00000001  0cf3   10d3
  }
t_pdse_AD_header=packed record                  // page AD
   version:word;
   volid:array[0..5] of char;
   z2:byte;
   w2:word;
   AD:array[0..9] of byte;
   w3:word;
   b1,b18:byte;
   w4,w5,w6:word;
   c1:cardinal;
   d1:int64;
   size:word;
   //z3,
   freelist:byte;
   f52:array[0..3] of cardinal;
   //min,max,
   order:word;
   //f53:array[0..52-9] of byte;
   //lhfsname:byte;
   //hfsname:array[0..44] of char;
end;
p_pdse_AD_header=^t_pdse_AD_header;



t_pdse_pad=packed record       // parms in AD page
   len:word;
   w1,w2,w3,w4,w5,w6:word;
   d:array[0..64] of byte;
end;
p_pdse_pad=^t_pdse_pad;



t_group=packed record
   g1,g2:word;
   gq:byte;
end;
p_group=^t_group;


t_page_matrix=packed record
 page:cardinal;
 q:byte;
 b6:array[0..4] of byte;
end;
p_page_matrix=^t_page_matrix;

//                                   G L D  A D D
// no repeat   33 (  21) 0021C000 38C7D3C4 C1C4C440 40010000 00020100 00000000 12000000 08000000 00
// wt repeat   27 (  1B) 001BC706 38E4E401 00000000 01000000 00006300 00000800 000000

type t_pdse_dir_entry=packed record
   len:word;
   const_c0,
   name_rep,
   const_38:byte;
   name:array[0..127] of byte;
end;
p_pdse_dir_entry=^t_pdse_dir_entry;


// 01 0000 0002 0100 00 00000012 00000008 00000000
type t_dir_part2=packed record
 b:array[0..7] of byte;
 i,n8,z:cardinal;
end;
p_dir_part2=^t_dir_part2;

type t_extra_dir=packed record
w1:word;
q,n,b:cardinal;
end;
p_extra_dir=^t_extra_dir;



// ex 26 (  1A) 001A C00B 0072 0000 1001 0000 0000 0100 00 08C7D3 C4E4E3D3 F3F1 GLDUTL31
//               len  1     2   3     4   5     6    7  b1 ln

t_pdse_pad_type1= packed record
  len,w1,w2,w3,w4,w5,w6,w7:word;
  b1,ln:byte;
name:array[0..127] of char;
end;
p_pdse_pad_type1=^t_pdse_pad_type1;
//                           l    1    2    3    4 b1 l8
//              47 (  2F) 002F C00E 0060 0200 0000 00 C7C4C5D2 C5E7D740 00 00002401 000000FF FF000000 00000000 00000000 00000000 000000
//166C9 parm    47 (  2F) 002F C00E 0060 0200 0000 00 C7 C4C5D2C5 E7D74000 00002401 000000FF FF000000 00000000 00000000 00000000 000000
// not name     47 (  2F) 002F C00B 0021 0000 7003 0000 00000100 02C6D7D4 D9C5E2C5 D9E5C500 00000000 11F90600 00000000 00001200 1F0000
//              47 (  2F) 002F C00E 0060 0200 0000 00 C7 C4C5D2C5 E7D74000 00002401 000000FF FF000000 00000000 00000000 00000000 000000
t_pdse_pad_type47= packed record
  len,w1,w2,w3,w4:word;
  b1:byte;
  name:array[0..7] of char;
end;
p_pdse_pad_type47=^t_pdse_pad_type47;


//              l    1    2    3 b1 ln name
// 18 (  12) 0012 C013 0002 0100 00 08 C7D3 C4C1C4C4 4040         alias.....
t_pdse_pad_type18= packed record // alias  12
  len,w1,w2,w3:word;
  b1,ln:byte;
  name:array[0..127] of char;
end;
p_pdse_pad_type18=^t_pdse_pad_type18;

//            l    0    1    2    3    4     5   6  b1  l
//26 (  1A) 001A C00B 000E 0000 1001 0000 0000 0100 00 08C7E2 D2E2D9C2 D9C4 name
//26 (  1A) 001A C00B 000E 0000 1001 0000 0002 0100 00 08C7E2 D2E2D9C2 E6E3 alias
t_pdse_pad_type26= packed record // alias   w6= flags (w6=0002)
  len:word;
  w:array[0..6] of word;
  b1,ln:byte;
  name:array[0..127] of char;
end;
p_pdse_pad_type26=^t_pdse_pad_type26;








//161 (  A1) 00A1 C00E 0050 0100 00000000 00020C00 00000008 00000000 80001E03 09C2C01C 12000000 003E6000 00040000 00040080
//92288100 00000000 62904000 00000000 1E00003C D7000010 0000011C 780000B7 E4000006 10000001 5C000000 28000001 34000000
//+29 +name   len 8
t_pdse_pad_type161= packed record // alias
  len,w1:word;
  b1:array[0..125] of byte;
  name:array[0..7] of char;
end;
p_pdse_pad_type161=^t_pdse_pad_type161;



type t_pdse_ND=packed record             // to find NDbbbbbb offset=3000/4000 etc
 version:word;
 tag:array[0..5] of byte;
 w1:word;
 b1:byte;
 ND_tag:array[0..1] of byte;
 fill1 :array[0..7] of byte;
 w4:array[0..4] of word;
 inode:cardinal;
 c1,c2:cardinal;
 qtd_dirs:word;
 qtd_groups:byte;
end;
p_pdse_ND=^t_pdse_ND;



{ with userdata
   l   w1   w2   w3  w4   w5   w6   w7   c2       c3      d1                 d2                 c7       c8       c9      c0       1         size
0060 C00E 0040 0400 0000 0001 0000 0000 00000000 000000   C20E8ED0 C2A54BE0 C1E6E5B6 B93B066B 00000000 0001EC30 C3D3C1D9 D2C70000 00000000 00000627 0000002100 00002200 000050 00000627 00 00000000 00000000 00000000
0060 C00E 0040 0400 0000 0001 0000 0000 00000000 000000   C2AD25DF 7ABEDFC9C2 AD258695 75BA9600 00000000 008F20C9 C2D4E4E2 C5D90000 00000000 0001CA00 00000900 00000A00 00005000 0001CA00 00000000 00000000 00000000 00000000 0038C00E
0063 C00B 0006 0000 4004 0000 0000 0100 00000000 000000   000000C2 425EA7D7 66 2B96C242 5E765730 18A20000 00000000 DED0C9C2 D4E4E2C5 D9000000 00000000 02C90000 000E0000 000F0000 00500000 02C90000 00000000 00000000 00000000 00000000
// userdata linked

      00A1 C00E 0050 0100 0000 0000 0002 0C00 00000004 00000000 80001E03 09C2C004 12000000 02018C00 0004C000 0004C000 00000000 00000000 62804000 00000000 6C0001F0 40000040 00000070 58000643 44000034 B8000001 80000000 64000001 1C000000 6C000036 38000100 00000200 00000000 00000000 00200716 5F0185
// 34 0022 C00E 0070 0300 0000 0001 0001C6D7 D4D9C5E2 C5D9E5C5 00000000 0014401B 0000

}
type t_AD_data=packed record
 len,w1,w2,w3,w4,w5,w6,w7:word;
 b2:array [0..6] of byte;
 d1,d2:int64;
 c4:array [0..19] of byte;
 size:cardinal;
end;
p_AD_data=^t_AD_data;

// len   0     1    2   3    4    5    6    7    8    9    0    1  d1                d2
//0063 C00B 0006 0000 4004 0000 0000 0100 0000 0000 0000 0000 0000 C2425EA7 D7662B96 C2425E765730 18A20000

type t_AD_type99=packed record
 len:word;
 w:array[0..11] of word;
 d1,d2:int64;
 c4:array [0..19] of byte;
 size:cardinal;
end;
p_AD_type99=^t_AD_type99;
//           len  w1                                                  d1                d2
//96 (  60) 0060 C00E 0040 0400 0000 0001 0000 0000 0000 0000 0000 00 C41D74C3 1B462007 C2853107
type t_AD_type96=packed record
 len,
 w1:word;
 w:array[0..8] of word;
 b1:byte;
 d1,d2:int64;
 c4:array [0..19] of byte;
 size:cardinal;
end;
p_AD_type96=^t_AD_type96;
//               l
// 105 (  69) 0069 C005 0003 0000 0000 0004 0000 4004 0000 0000 0100 0000 0000 0000 0000 0000 C41D74CD 2B07AD00 C285222F A1051709 00000000 00000000 00000000 00000000 00000000 00000000 00000001 00000002

type t_AD_type69=packed record
 w:array[0..15] of word;
 d1,d2:int64;
 c4:array [0..19] of byte;
 size:cardinal;
end;
p_AD_type69=^t_AD_type69;




//      0 1 2 3 4 5 6 7 8 9  1 2 3
//  01 D9C5E2C5D9E5C5C4F1F0 000000 00000103 01000000
type t_block_set=packed record   // array of blocks until 4 ??
   qt:word;
   name:array[0..9] of char; // or RESERVED10
   b1,b2,b3:byte;
   pages:array[0..16] of t_page_matrix;
end;
p_block_set=^t_block_set;



t_list_blocks=packed record
 bnum:array  of integer;
end;
p_list_blocks=^t_list_blocks;

t_file_pdse=record
   len,
   pages,
   off_page:integer;
   name,alias:string;
   dt:double;
end;
t_data_pdse=array of t_file_pdse;

t_linked_data=packed record
 tag:array[0..7] of char;           // const IEWPLMHb
 f1:array[0..131] of byte;
 name:array[0..7] of char;
 f2:array[0..9] of byte;
 size:cardinal;
end;
p_linked_data=^t_linked_data;






