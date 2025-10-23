
//      all about vsam structure files (big mess!!!)


type

t_vsam_idx = packed record    // index record   dfsms using datasets pag 306...

IXHLL: word; 	//Index record length. The length of the index record is equal to the
//length of the control interval minus 7.

IXHFLPLN:byte;	//Index entry control information length. This is the
//length of the last three of the four fields in an index entry.
//(The length of the first field is variable.)
//The length of the control information is 3, 4, or 5 bytes.

IXHPTLS:byte;	//Vertical-pointer-length indicator.
//The fourth field in an index entry is a vertical pointer to a control interval.
//In an index-set record, the pointer is a binary number that designates a control
//interval in the index. The number is calculated by dividing the RBA of the control
//interval by the length of the control interval.

//To permit for a possibly large index, the pointer is always 3 bytes.
//In a sequence-set record, the pointer is a binary number, beginning at 0,
//and calculated the same as for index-set record, that designates a control
//interval in the data control area governed by the sequence-set record.

//A free-control-interval entry is nothing more than a vertical pointer.
//There are as many index entries and free-control-interval entries in a
//sequence-set record as there are control intervals in a control area.

//Depending on the number of control intervals in a control area, the pointer is 1, 2,
//or 3 bytes.

//An IXHPTLS value of X'01' indicates a 1-byte pointer; X'03' indicates a 2-byte pointer;
//X'07' indicates a 3-byte pointer.

IXHBRBA: cardinal;// ofs 4 -  Base RBA. In an index-set record, this is the beginning RBA of the index.
// Its value is 0. The RBA of a control interval in the index is calculated by multiplying index
//control interval length times the vertical pointer and adding the result to the base RBA.

// In a sequence-set record, this is the RBA of the control area governed by the record.

//The RBA of a control interval in the control area is calculated by multiplying data control
//interval length times the vertical pointer and adding the result to the base RBA.

//Thus, the first control interval in a control area has the same RBA as the control area
//(length times 0, plus base RBA, equals base RBA).

// Exception: For an extended-addressable KSDS, this field is a relative control interval
//number instead of a RBA.

//IXHBCI:cardinal;
//IXHFINXT:cardinal; //	Doubly defined with IXHBRBA. Set only in an index-set record.
//It is the CI# of the next index-set record in the free index-set record LIFO chain.
//This field in the first 2nd-level index record (CI #2) has the CI# of the most recently
//freed index-set record or, if Flag byte = X'80', the index-set record that was
//interrupted during CA reclaim.

IXHHP:cardinal;	 //  ofs 8 Horizontal-pointer RBA. This is the RBA of the next index record
// in the same level as this record. The next index record contains keys next in
//ascending sequence after the keys in this record.

// Exception: For an extended-addressable KSDS, this field is a relative control
//interval number instead of a RBA.


IXHFSNXT:cardinal; // ofs 12 	Set in the first 2nd-level index record (CI #2) and the free
//sequence-set records. It is the CI# of the next sequence-set record in the
//free sequence-set record LIFO chain. This field in the first 2nd-level index record
//has the CI# of the most recently freed sequence-set record or, if Flag byte = X’80’,
//the sequence-set record that was interrupted during CA reclaim.

IXHLV: byte;       //	ofs 16	Level number. The sequence set is the first level of an index, and
//each of its records has an IXHLV of 1. Records in the next higher level have a 2, and so on.



IXHFLAG:byte;  // ofs 17
//X'80' -- CA reclaim is in progress. Set only in index CI #2.

//X'40' -- CA reclaim is committed. Set only in the index record one level above the
// vertical chain of index records to be reclaimed.

//X'20' -- CA reclaim is pending. Set in all index reccords that will be reclaimed.
//This flag stays ON until this index record is reused.

//X'10' -- Index record removed from horizontal chain for CA Reclaim. This flag stays
//ON until this index record is reused.

//X'08' -- Index CI #2 itself is logically in the IXHFINXT chain. This flag is
//set only in index CI #2.

//X'04' -- IXHHBACK is valid and can be referenced.

IXHFSO:word;	// ofs 18  Displacement to the unused space in the record. In an index-set record,
//this is the length of the header (24). There are no free control interval entries.

//In a sequence-set record, the displacement is equal to 24, plus the length of
//    free control interval entries, if any.

IXHLEO:word;	//ofs 20 Displacement to the control information in the last index entry.
//The last (leftmost) index entry contains the highest key in the index record.

//In a search, if the search-argument key is greater than the highest key in the
//preceding index record but less than or equal to the highest key in this index record,
//then this index record governs either the index records in the next lower level
//that have the range of the search-argument key or the control area in which a
//data record having the search-argument key is stored.

IXHSEO:word;	// ofs 22Displacement to the control information in the last (leftmost) index
//entry in the first (rightmost) section. Index entries are divided into sections to
//simplify a quick search. Individual entries are not examined until the right section is located.

IXHHBACK:cardinal;// ofs 24 Point to the preceding index CI in the horizontal chain. Only set in the reclaimed index CI.
end;




t_idx_entry =packed record
ix_F,ix_L,ix_P:integer;
end;

t_idx_key =packed record
ix_P:integer;
key: array[0..60] of byte;
end;

t_vdr_valid = packed record
  blklen,rlen:word;
  name:array[0..3] of char;
end;



vvdr_name = packed record
  len:byte;
  name:array[0..44] of char;
end;



vvdr_header = packed record
VVRLEN   :word;                     //LENGTH OF ENTIRE VVR
//VVRHDR   DS    0CL9                    VVR HEADER
VVRHDLEN :word;                     //   LENGTH OF HEADER CELL
VVRTYPE :char;                      //  TYPE 'Z' OR 'Q'
VVRFLAG:byte;                       //  HEADER FLAG
//VVRRESV1 EQU   X'80'                   RESERVED
//VVRSELFD EQU   X'40'                   SELV DESCRIBING VVR FOR VVDS
//VVRCATSD EQU   X'20'                   CATALOG SELFDESCRIBING VVR
//VVRRESV2 EQU   X'10'                   RESERVED
//VVRCOMPT EQU   X'08'                   COMP-TYPE 0 => 'D', 1 => 'I'
//VVRRESV3 EQU   X'07'                   RESERVED
VVRKRQ:array[0..3] of byte;         //  KEY RANGE QUALIFIER
//VVRV1    DS    0C                      RESERVED
VVRCMPNL :byte;                     //  COMPONENT NAME LENGTH
VVRCMPNM :array[0..44] of char;     //  COMPONENT NAME
end;


// cbtape 172 -->  vvr block - ver old,but....

//   *        V V R   A M D S B   C E L L                                  *

vvdr_h60 = packed record
blen :word;                               //  LENGTH OF ENTIRE VVR AMDSB CELL
//VVRAMCAT DS    0CL96
//VVRAMSB1 DS    0CL6
tipo  :byte;                              //  TYPE X'60' FOR VVR AMDSB CELL
atrib :byte;                              //  ATTRIBUTES
//VVRAMDST EQU   X'80'                    //  1 => KSDS, 0 => ESDS
//VVRAMWCK EQU   X'40'                    //  WRITE CHECK
//VVRAMSDT EQU   X'20'                    //  SEQUENCE SET WITH DATA
//VVRAMREP EQU   X'10'                    //  REPLICATION
//VVRAMORD EQU   X'08'                    //  USE VOLUMES IN LIST ORDER
//VVRAMRGE EQU   X'04'                    //  KEY RANGE DATA SET
//VVRAMRDS EQU   X'02'                    //  RRDS
//VVRAMSPN EQU   X'01'                    //  SPANNED RECORDS ARE ALLOWED
rlen:word;                                //  LENGTH OF AMDSB
//r0:word;
//VVRAMNST DS    0CL2                     //  NUMBER OF ENTRIES IN IDX SECTION
aixrpk :word;                             //  ALTERNATE KEY RKP
//VVRAMKEY DS    0CL4                     //  KEY DESCRIBTION
irpk :word;                               //  RELATIVE KEY POSITION
ilen :word;                               //  KEY LENGTH
//VVRAMSB2 DS    0CL10
p_freeci :byte;                           //  % FREE CI IN CA
p_freeb :byte;                            //  % FREE BYTES IN CI
ci_ca :word;                              //  NUMBER OF CI'S PER CA
free_ci_ca :word;                         //  FREE CI'S  IN CA
free_b_ci :cardinal;                      //  FREE BYTES PER CI
//VVRAMCIR DS    0CL8
ci_size :cardinal;                        //  CONTROL INTERVAL SIZE
max_recs :cardinal;                       //  MAXIMUM RECORD SIZE
//VVRAMSB3 DS    0CL68
//VVRAMHLR DS    0CL4                     //   RBA OF HIGH LEVEL INDEX RECORD
ix_seq  :cardinal;                        //  RECORD SLOTS PER CI
//VVRAMSSR DS    0CL4                     //   RBA OF FIRST SEQ.SET RECORD
max_rrn :cardinal;                        //  MAX. RELATIVE RECORD NUMBER
p_ardb :cardinal;                         //  PONTER TO FIRST ARDB
f_atrib :byte;                            //  ATTRIBUTES
//VVRAMUNQ EQU   X'80'                    //  NON-UNIQUE OR UNIQUE KEYS
//VVRAMFLT EQU   X'40'                    //  CYLINDER FAULT ON MSS OR STAGE
//VVRAMBND EQU   X'20'                    //  BIND OR DO NOT BIND ON MSS
//VVRAMWAT EQU   X'10'                    //  WAIT OR NOR-WAIT ON RELINQUISH
//VVRAMLM  EQU   X'08'                    //  LOAD MODE OR DATASET LOADED
//VVRAMRS1 EQU   X'07'                    //  RESERVED
n_c_req :byte;                            //  NUMBER OF CONCURRENT REQUESTS
r1 :cardinal;                             //  RESERVED
//VVRAMBFI DS    0CL2                     //  NUMBER OF INDEX BUFFERS
datab :word;                              //  NUMBER OF DATA BUFFERS
times :array[0..7] of byte;               //  SYSTEM TIME STAMP
index_level :word;                        //  NUMBER OF INDEX LEVELS
extents :word;                            //  NUMBER OF EXTENTS
n_rec :cardinal;                          //  NUMBER OF LOGICAL RECORDS
n_del :cardinal;                          //  NUMBER OF DELETED RECORDS
n_ins :cardinal;                          //  NUMBER OF INSERTED RECORDS
n_upd :cardinal;                          //  NUMBER OF UPDATED RECORDS
n_retr :cardinal;                         //  NUMBER OF RETRIEVED RECORDS
free_sp:cardinal;                         //  BYTES OF FREE SPACE IN DATASET
ci_split :cardinal;                       //  NUMBER OF CI SPLITS
ca_split :cardinal;                       //  NUMBER OF CA SPLITS
excps :cardinal;                          //  NUMBER OF EXCP'S
end;






//  *        V V R   D A T A S E T   I N F O R M A T I O N   C E L L      *

vvr_h21 = packed record                // VVR DS INFO CELL
VVRDSLEN :word;                        // LENGTH OF DS INFO CELL
VVRDSTYP :byte;                        //   TYPE X'21' FOR VVR DS INFO CELL
VVRATTR1 :byte;                        //   DATA SET ATRIBUTES
//VVRA1SPD EQU   X'80'                 SPEED
//VVRA1UNQ EQU   X'40'                 UNIQUE
//VVRA1REU EQU   X'20'                 REUSE
//VVRA1ERS EQU   X'10'                 ERASE
//VVRA1RSV EQU   X'08'                 RESERVED
//VVRA1IUP EQU   X'04'                 INHIBIT UPDATE
//VVRA1TEX EQU   X'02'                 TEMPORARY EXPORT
//VVRA1TRO EQU   X'01'                 TRACK OVERFLOW
VVRATTR2 :byte;                           //SHARE ATTRIBUTES
//VVRA2REG EQU   X'C0'                 REGIONAL SHARING ATTRIBUTES
//VVRA2SYS EQU   X'30'                 SYSTEM SHARING ATTRIBUTES
//VVRA2RSV EQU   X'0C'                 RESERVED
//VVRA2INT EQU   X'02'                 INTERNAL SYSTEM DATA SET
//VVRA2NUS EQU   X'01'                 COMPONENT IS NOT USABLE
VVROPIND :byte;                        //OPEN INDICATOR
VVRBUFSZ :cardinal;                    //  MINIMUM BUFFER SIZE
//VVRSPACE DS    0CL7                  SPACE
VVRPRISP :array[0..2] of byte;         // PRIMARY SPACE ALLOCATION
VVRSECSP :array[0..2] of byte;         // SECONDARY SPACE ALLOCATION
VVRSPCFG :byte;                        //SPACE FLAGS
//VVRSPCOP EQU   X'C0'                 SPACE OPTIONS
//VVRSPTRK EQU   X'80'                 TRACK ALLOCATION
//VVRSPCYL EQU   X'C0'                 CYLINDER ALLOCATION
//VVRSPCRS EQU   X'3F'                 RESERVED
VVRDSHU  :cardinal;                    //  DATASET HI USED RBA
VVRDSHA  :cardinal;                    //  DATASET HI ALLOC RBA
VVRLRECL :cardinal;                    //  AVG LOGICAL RECORD LENGTH
VVRDSRSV :word;                        //RESERVED
VVREXCPX :array[0..7] of byte;         // //  EXCEPTION EXIT
VVRDSHK  :cardinal;                    //  DATASET HI KEY RBA
VVRCLSFG :byte;                        //CLUSTER ATTRIBUTE FLAG
//VVRCLRSV EQU   X'FC'                 RESERVED
//VVRCFSWS EQU   X'02'                 CLUSTER DESCRIBES SWAPSPACE
//VVRCFPGS EQU   X'01'                 CLUSTER DESCIBES PAGESPACE
VVRAIXFG :byte;                        // AIX ATTRIBUTE FLAG
//VVRAIUPG EQU   X'80'                 UPGRADE AIX
//VVRAIRSV EQU   X'7F'                 RESERVED
VVRTMSTP :array[0..7] of byte;         //         TIMESTAMP
un01: array[0..7] of cardinal;         //DS    8XL4                  UNKNOWN
b01:array[0..4] of byte;
b02:array[0..7] of byte;
VVR21SCL :word;                        // LENGTH OF STORAGE CLASS
VVR21SCN :array[0..7] of char;         // NAME OF STORAGE CLASS
VVR21DCL :word;                        // LENGTH OF DATA CLASS
VVR21DCN :array[0..7] of char;         // NAME OF DATA CLASS
VVR21MCL :word;                        // LENGTH OF MANAGEMENT CLASS
VVR21MCN :array[0..7] of char;         // NAME OF MANAGEMENT CLASS
end;



//***********************************************************************
//                                                                    *
//       V V R   V O L U M E   I N F O R M A T I O N   C E L L        *
//*                                                                     *
//***********************************************************************
vvr_h23 = packed record
VVRVOLLN :word;                        // LENGTH OF VOL INFO CELL
VVRVOLTP,                              // TYPE X'23' FOR VOL INFO CELL
VVRVOLFG:byte;                         // VOLUME FLAGS
//VVRPRIME EQU   X'80'                   PRIME VOLUME
//VVRVRSV1 EQU   X'40'                   RESERVED
//VVROVFLW EQU   X'20'                   OVERFLOW VOLUME
//VVRVRSV2 EQU   X'1F'                   RESERVED
VVRNOEXT :byte;                        // EXT-NO. FOR DSET ON VOLUME
VVRHKRBA :cardinal;                    // HIGH KEY RBA
VVRHURBA :cardinal;                    // HIGH USED RBA
VVRHARBA :cardinal;                    // HIGH ALLOCATED RBA
VVRBLKSZ :cardinal;                    // BLOCKSIZE
VVRBLKTK : word;                       // NUMBER OF BLOCKS PER TRACK
VVRTRKAU : word;                       // TRACKS PER ALLOCATION UNIT
VVRTPEXT :byte;                        // EXTENT TYPE FLAG
//VVRSSDAT EQU   X'80'                   SEQUENCE SET WITH DATA
//VVRNOPFM EQU   X'40'                   EXTENTS NOT PREFORMATTED
//VVRCONV  EQU   X'20'                   CONVERTED VSAM DATASET VOLUME
//VVRTPRSV EQU   X'1F'                   RESERVED
VVRTKCYL : word;                       // TRACKS PER CYLINDER
VVRBYTTK :cardinal;                    // BYTES PER TRACK
VVRBYTAU :cardinal;                    // BYTES PER ALLOCATION UNIT
VVRLOKYL : word;                       // LOW KEY LENGTH
VVRLOKYV :array[0..44] of char;        // LOW KEY ON VOLUME
//VVRXTENT DS    0CL2                    EXTENT DESCRIBTION
VVRXTNTL : word;                       //LENGTH OF EXTENT SECTION
//VVRXTNT  DS    0CL20                   EXTENTS (ONE OR MORE SETS)
//VVRX     DS    0CL20                   INDIVIDUAL EXTENT
VVRXSEQN : word;                       // SEQUENCE NUMBER
//VVRXSCH  DS    0CL4                    STARTING CCHH
VVRXSC   : word;                       // STARTING CC
VVRXSH   : word;                       // STARTING HH
//VVRXECH  DS    0CL4                    ENDING CCHH
VVRXEC   : word;                       // ENDING CC
VVRXEH   : word;                       // ENDING HH
VVRXNTRK : word;                       // NUMBER OF TRACKS
VVRXSRBA :cardinal;                    //  STARTING RBA
VVRXERBA :cardinal;                    //  ENDING RBA
end;


t_CIDF = packed record            //* CIDF
    ofs,                          //* Offset to CI free space
    len: word;                    //* len CI free space
end;

T_RDF = packed record
 Control_Field   :byte;
 Binary_Number   :word;
end;
t_rdf_qrec_len=packed record
   qrec,
   recl:word;
end;

t_rdf_list = array of t_rdf_qrec_len;

p_rdf_list = ^t_rdf_list;


const
CIDF_BUSY = $8000;

vvdr_name_offset = 10;        // init name position om vvr_header
VVRAMDST=$80;                 // EQU   X'80'   1 => KSDS, 0 => ESDS
VVRAMRDS=2;                   //  RRDS
VVRAMSPN=1;                   //  SPANNED RECORDS ARE ALLOWED
// vsam allocation
VVRSPCOP=$C0;                 // SPACE OPTIONS
VVRSPTRK=$80;                 //TRACK ALLOCATION
VVRSPCYL=$C0;                 //CYLINDER ALLOCATION



// DFSMS using datasets pag 186
vsam_addicional    = $400000; // next rdf  lrecl or spanned
vsam_spanned_first = $100000;
vsam_spanned       = $300000; // first,last or both
vsam_spanned_last  = $200000;
vsam_deleted       = $040000; // only for fixed len RRDS
vsam_lrecl         = $080000; // next = lrecl



{
A control interval consists of:
. Logical records
. Free space
. Control information fields

CIDFs are 4 bytes long, and contain the amount and location of free space. RDFs
are 3 bytes long, and describe the length of records and how many adjacent
records are of the same length.

An RDF is a 3-byte field that contains a 1-byte control field and a 2-byte binary
number, as the following table shows.

}
