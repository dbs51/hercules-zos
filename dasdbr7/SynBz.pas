unit SynBz;

interface
uses
  SysUtils,  Classes,  Windows;

type
{$DEFINE USEBZAASM}

  TBZAlloc = function(AppData: Pointer; Items, Size: Cardinal): Pointer; stdcall;
  TBZFree = procedure(AppData, Block: Pointer); stdcall;
  TBZStreamRec = record
    next_in: PChar;
    avail_in: Integer;
    total_in: Integer;
    total_in_hi: Integer;

    next_out: PChar;
    avail_out: Integer;
    total_out: Integer;
    total_out_hi: Integer;

    State: Pointer;

    zalloc: TBZAlloc;
    zfree: TBZFree;
    AppData: Pointer;
  end;

  TBZBuffer = array[word] of byte;
  TBZCompressor = class(TStream)  private
    FInitialized: Boolean;
    FStrm: TBZStreamRec;
    FDestStream: TStream;
    SrcLen: Cardinal;
    FBufferIn: TBZBuffer;
    BufferOut: ^TBZBuffer; // via Getmem() for AES 16-bytes alignment
    procedure FlushBufferOut;
  public
    constructor Create(outStream: TStream; CompressionLevel: Integer=6);
    destructor Destroy; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Seek(Offset: Longint; Origin: Word): Longint; override;
    procedure Finish;
    property FullSize: cardinal read SrcLen;
  end;

  TBZDecompressor = class(TStream)
  private
    FReachedEnd,
    FInitialized: Boolean;
    FStrm: TBZStreamRec;
    FSrcStream: TStream;
    DestLen: Cardinal;
    FBufferIn: array[word] of byte; // one 64kb buffers
  public
    constructor Create(inStream: TStream);
    destructor Destroy; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Seek(Offset: Longint; Origin: Word): Longint; override;
    property FullSize: cardinal read DestLen;
  end;

function UnCompressBzDll(Source: pChar; SourceSize, DestSize: integer): TMemoryStream; overload; 
// result=nil if error decompressing
implementation
{$ifdef Win32}
var BZCompressModule:   HMODULE = 0;
    BZDecompressModule: HMODULE = 0;

  BZ2_bzCompressInit: function(var strm: TBZStreamRec;
    blockSize100k, verbosity, workFactor: Integer): Integer; stdcall = nil;
  BZ2_bzCompress: function(var strm: TBZStreamRec;
    action: Integer): Integer; stdcall = nil;
  BZ2_bzCompressEnd: function(var strm: TBZStreamRec): Integer; stdcall = nil;

{$ifdef USEBZAASM}
{$I bunzipasm.inc} // all asm code extracted from bunzip.dll :)
{$else}
  BZ2_bzDecompressInit: function(var strm: TBZStreamRec;
    verbosity, small: Integer): Integer; stdcall = nil;
  BZ2_bzDecompress: function(var strm: TBZStreamRec): Integer; stdcall = nil;
  BZ2_bzDecompressEnd: function(var strm: TBZStreamRec): Integer; stdcall = nil;
{$endif}

{$else}
const
  bzlib='libbz2.so';

function BZ2_bzCompressInit(var strm: TBZStreamRec;
    blockSize100k, verbosity, workFactor: Integer): Integer; cdecl;
    external bzlib name 'BZ2_bzCompressInit';
function BZ2_bzCompress(var strm: TBZStreamRec;
    action: Integer): Integer; cdecl;
    external bzlib name 'BZ2_bzCompress';
function BZ2_bzCompressEnd(var strm: TBZStreamRec): Integer; cdecl;
    external bzlib name 'BZ2_bzCompressEnd';

{$ifdef USEBZAASM}
{$I bunzipasm.inc} // all asm code extracted from bunzip.dll :)
{$else}
function BZ2_bzDecompressInit(var strm: TBZStreamRec;
    verbosity, small: Integer): Integer; cdecl;
    external bzlib name 'BZ2_bzDecompressInit';
function BZ2_bzDecompress(var strm: TBZStreamRec): Integer; cdecl;
    external bzlib name 'BZ2_bzDecompress';
function BZ2_bzDecompressEnd(var strm: TBZStreamRec): Integer; cdecl;
    external bzlib name 'BZ2_bzDecompressEnd';
{$endif}
{$endif}

const
  BZ_RUN              = 0;
  BZ_FLUSH            = 1;
  BZ_FINISH           = 2;

  BZ_OK               = 0;
  BZ_RUN_OK           = 1;
  BZ_FLUSH_OK         = 2;
  BZ_FINISH_OK        = 3;
  BZ_STREAM_END       = 4;
  BZ_SEQUENCE_ERROR   = (-1);
  BZ_PARAM_ERROR      = (-2);
  BZ_MEM_ERROR        = (-3);
  BZ_DATA_ERROR       = (-4);
  BZ_DATA_ERROR_MAGIC = (-5);
  BZ_IO_ERROR         = (-6);
  BZ_UNEXPECTED_EOF   = (-7);
  BZ_OUTBUFF_FULL     = (-8);
  BZ_CONFIG_ERROR     = (-9);

  SBzlibDataError = 'bzlib: Compressed data is corrupted';
  SBzlibInternalError = 'bzlib: Internal error. Code %d';
  SBzlibAllocError = 'bzlib: Too much memory requested';

{$ifdef Win32}
function GetLastErrorText(aerror: integer): string;
begin
 setlength(result,1024);
 setlength(result,FormatMessage(format_message_from_system,
   nil,aerror,0,pchar(result),1024,nil));
end;

procedure ShowLastError;
begin
  MessageBox(0,pChar(GetLastErrorText(getLastError)),nil,MB_OK or MB_ICONERROR);
end;

function BZInitCompressFunctions(Module: HMODULE): Boolean;
begin
  BZCompressModule := Module;
  if Module=0 then begin
    ShowLastError;
    Result := false;
  end else begin
    BZ2_bzCompressInit := GetProcAddress(Module, 'BZ2_bzCompressInit');
    BZ2_bzCompress := GetProcAddress(Module, 'BZ2_bzCompress');
    BZ2_bzCompressEnd := GetProcAddress(Module, 'BZ2_bzCompressEnd');
    Result := Assigned(BZ2_bzCompressInit) and Assigned(BZ2_bzCompress) and
      Assigned(BZ2_bzCompressEnd);
  end;
  if not Result then begin
    BZ2_bzCompressInit := nil;
    BZ2_bzCompress := nil;
    BZ2_bzCompressEnd := nil;
  end;
end;

{$ifndef USEBZAASM}






function BZInitDecompressFunctions: Boolean;
var F: string;
begin

  result := false;
  F := extractfilepath(paramstr(0))+'bunzip.dll';
  if FileExists(F) then
     BZDeCompressModule:= LoadLibrary(pChar(F)) else
     exit;
  if BZDeCompressModule=0 then
    ShowLastError else begin
    BZ2_bzDecompressInit := GetProcAddress(BZDeCompressModule, 'BZ2_bzDecompressInit');
    BZ2_bzDecompress := GetProcAddress(BZDeCompressModule, 'BZ2_bzDecompress');
    BZ2_bzDecompressEnd := GetProcAddress(BZDeCompressModule, 'BZ2_bzDecompressEnd');
    Result := Assigned(BZ2_bzDecompressInit) and Assigned(BZ2_bzDecompress) and
      Assigned(BZ2_bzDecompressEnd);
  end;

  if not Result then begin
    BZ2_bzDecompressInit := nil;
    BZ2_bzDecompress := nil;
    BZ2_bzDecompressEnd := nil;
  end;
end;

{$endif}
{$endif}



function BZAllocMem(AppData: Pointer; Items, Size: Cardinal): Pointer; stdcall;
begin
  GetMem(Result, Items * Size);
end;


procedure BZFreeMem(AppData, Block: Pointer); stdcall;
begin
  FreeMem(Block);
end;


function Check(const Code: Integer; const ValidCodes: array of Integer): integer;
var I: Integer;
begin

  if Code = BZ_MEM_ERROR then
    OutOfMemoryError;
  Result := Code;
  for I := Low(ValidCodes) to High(ValidCodes) do
    if ValidCodes[I] = Code then
      Exit;
  raise Exception.CreateFmt(SBzlibInternalError, [Code]);
end;

procedure InitStream(var strm: TBZStreamRec);
begin



  FillChar(strm, SizeOf(strm), 0);
{$ifdef Win32}  // use LibC Alloc/Free on Linux
  with strm do begin
    zalloc := BZAllocMem;
    zfree := BZFreeMem;
  end;
{$endif} 
end;

{ TBZCompressor }

constructor TBZCompressor.Create(outStream: TStream; CompressionLevel: Integer);
{$ifdef Win32}
var F: string;
begin
  if @BZ2_bzCompressInit=nil then begin
    F := extractfilepath(paramstr(0))+'bzip.dll';
    if FileExists(F) then
      BZInitCompressFunctions(LoadLibrary(pChar(F)));
  end;
  if @BZ2_bzCompressInit=nil then
    CompressionLevel := -1; // <0 -> direct copy (no compression)
{$else}
begin
{$endif}
  FDestStream := outStream;
  InitStream(FStrm);
  New(BufferOut);
  with FStrm do begin
    next_out := PChar(BufferOut);
    avail_out := SizeOf(BufferOut^);
    next_in := @FBufferIn;
  end;
  if CompressionLevel>=0 then // FInitialized=false -> direct copy
    FInitialized := Check(BZ2_bzCompressInit(FStrm, CompressionLevel, 0, 0),
      [BZ_OK])=BZ_OK;
end;

destructor TBZCompressor.Destroy;
begin
  if FInitialized then begin
    FStrm.next_out := nil;
    FStrm.avail_out := 0;
    BZ2_bzCompressEnd(FStrm);
    FreeMem(BufferOut);
  end;
  inherited;
end;

procedure TBZCompressor.Finish;
begin

  if self=nil then
    exit;
  if FInitialized then begin
    while FStrm.avail_in > 0 do begin
      Check(BZ2_bzCompress(FStrm, BZ_RUN), [BZ_RUN_OK]);
      if FStrm.avail_out = 0 then FlushBufferOut;
    end;
    FStrm.next_in := nil;
    FStrm.avail_in := 0;
    while Check(BZ2_bzCompress(FStrm, BZ_FINISH), [BZ_FINISH_OK, BZ_STREAM_END])<>BZ_STREAM_END do
      FlushBufferOut;
  end;
  FlushBufferOut;
end;

procedure TBZCompressor.FlushBufferOut;
var Count: integer;
begin
//  if not FInitialized then exit;
  Count := SizeOf(BufferOut^) - FStrm.avail_out;
  if Count=0 then exit;
  FDestStream.Write(BufferOut^, Count);
  FStrm.next_out := PChar(BufferOut);
  FStrm.avail_out := SizeOf(BufferOut^);
end;

function TBZCompressor.Read(var Buffer; Count: Integer): Longint;
begin
  assert(false);
  result := 0;
end;

function TBZCompressor.Seek(Offset: Integer; Origin: Word): Longint;
begin
  if not FInitialized then // CompressionLevel<0: direct copy to
    result := 0 else
  if (Offset = 0) and (Origin = soFromCurrent) then // for TStream.Position
    Result := FStrm.total_out else begin
    Result := 0;
    assert((Offset = 0) and (Origin = soFromBeginning) and (FStrm.total_out = 0));
  end;
end;

function TBZCompressor.Write(const Buffer; Count: Integer): Longint;
var i: integer;
    p: pChar;
begin

  if (self<>nil) and (Count>0) then begin
    result := Count;
    inc(SrcLen,Count);
    if FInitialized then begin
      if Count+FStrm.avail_in>sizeof(fBufferIn)-1 then begin
        while FStrm.avail_in > 0 do begin
          Check(BZ2_bzCompress(FStrm, BZ_RUN), [BZ_RUN_OK]);
          if FStrm.avail_out = 0 then
            FlushBufferOut;
        end;
        FStrm.avail_in := 0;
        FStrm.next_in := @fBufferIn;
      end;
      if Count<sizeof(fBufferIn) then begin
        move(Buffer,fBufferIn[FStrm.avail_in],Count);
        inc(FStrm.avail_in,Count);
      end else begin
        FStrm.avail_in := Count;
        FStrm.next_in := @Buffer;
        while FStrm.avail_in > 0 do begin
          Check(BZ2_bzCompress(FStrm, BZ_RUN), [BZ_RUN_OK]);
          if FStrm.avail_out = 0 then
            FlushBufferOut;
        end;
        FStrm.avail_in := 0;
        FStrm.next_in := @fBufferIn;
      end;
    end else begin // if not FIinitialized: CompressionLevel<0: direct copy to
      p := @Buffer;
      while Count>=FStrm.avail_out do begin
        FlushBufferOut;
        if Count<sizeof(BufferOut^) then
          i := Count else
          i := sizeof(BufferOut^);
        move(p^,BufferOut^,i);
        inc(p,i);
        dec(Count,i);
        dec(FStrm.avail_out,i);
      end;
      if Count>0 then begin
        move(p^,BufferOut^[sizeof(BufferOut^)-FStrm.avail_out],Count);
        dec(FStrm.avail_out,Count);
      end;
    end;
  end else
    result := 0; // self=nil
end;

{ TBZDecompressor }
constructor TBZDecompressor.Create(inStream: TStream);
begin
  FSrcStream := inStream;
{$ifndef USEBZAASM}
  if (@BZ2_bzDecompressInit=nil) and not BZInitDecompressFunctions then exit;
{$endif}
  InitStream(FStrm);
  FStrm.next_in := @FBufferIn;
  FInitialized := Check(BZ2_bzDecompressInit(FStrm, 0, 0), [BZ_OK])=BZ_OK;
end;

destructor TBZDecompressor.Destroy;
begin
  if FInitialized then begin
    FStrm.next_out := nil;
    FStrm.avail_out := 0;
    BZ2_bzDecompressEnd(FStrm);
  end;
  inherited;
end;

function TBZDecompressor.Read(var Buffer; Count: Integer): Longint;
begin
  if not FInitialized then begin
    Result := FSrcStream.Read(Buffer,Count);
    inc(DestLen,Result);
    exit;
  end;
  FStrm.next_out := @Buffer;
  FStrm.avail_out := Count;
  while FStrm.avail_out > 0 do begin
    if FReachedEnd then begin { unexpected EOF }
      Result := 0;
      exit;
    end;
    if FStrm.avail_in = 0 then begin
      FStrm.next_in := @FBufferIn;
      FStrm.avail_in := FSrcStream.Read(FBufferIn, SizeOf(FBufferIn));
      { Unlike zlib, bzlib does not return an error when avail_in is zero and
        it still needs input. To avoid an infinite loop, check for this. }
      if FStrm.avail_in=0 then begin
        Result := 0;
        exit;
      end;
    end;
    case Check(BZ2_bzDecompress(FStrm), [BZ_OK, BZ_STREAM_END, BZ_DATA_ERROR, BZ_DATA_ERROR_MAGIC]) of
      BZ_STREAM_END: FReachedEnd := True;
      BZ_DATA_ERROR, BZ_DATA_ERROR_MAGIC: raise Exception.Create(SBzlibDataError);
    end;
  end;
  Result := Count;
  inc(DestLen,Result);
end;








function TBZDecompressor.Seek(Offset: Integer; Origin: Word): Longint;
begin
  if not FInitialized then // CompressionLevel<0: direct copy to
    result := DestLen else
    result := FStrm.total_out;
  if (Offset<>0) or (Origin<>soFromCurrent) then begin // for TStream.Position
    assert((Offset = 0) and (Origin = soFromBeginning) and (result = 0));
    Result := 0;
  end;
end;

function TBZDecompressor.Write(const Buffer; Count: Integer): Longint;
begin
  assert(false);
  result := 0;
end;

function UnCompressBzDll(Source: pChar; SourceSize, DestSize: integer): TMemoryStream; overload;
// result=nil if error decompressing

var strm: TBZStreamRec;
    res: integer;
begin
  result := nil;
{$ifndef USEBZAASM}
  if (@BZ2_bzDecompressInit=nil) and not BZInitDecompressFunctions then exit;
{$endif}
  InitStream(strm);
  if BZ2_bzDecompressInit(strm, 0,0)<>BZ_OK then
  begin
     strm.next_in:=nil;
     exit;
  end;
  strm.next_in := Source;
  strm.avail_in := SourceSize;
  result := TMemoryStream.Create;
  result.Size := DestSize;
  strm.next_out := result.Memory;
  strm.avail_out := DestSize;
{$ifdef USEBZAASM}
  try
    res := BZ2_bzDecompress(strm);
  except
    on E: Exception do
      res := BZ_DATA_ERROR;
  end;
{$else}
  res := BZ2_bzDecompress(strm);
{$endif}
  if res<>BZ_STREAM_END then
    FreeAndNil(result);
  BZ2_bzDecompressEnd(strm);
  Result.SetSize(strm.total_out);
end;


{$ifdef Win32}
initialization
finalization
  if BZCompressModule<>0 then
    FreeLibrary(BZCompressModule);


 if BZDeCompressModule<>0 then
    FreeLibrary(BZDeCompressModule);


{$endif}
end.

