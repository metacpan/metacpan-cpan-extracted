package Win32::PEFile::PEConstants;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT = qw(
    %rsrcTypes @kCOFFKeys @kVersionStringKeys @kOptionalHeaderFields
    @kOptHeaderSectionCodes @kStdSectionCodes %kStdSectionCodeLu
    @kSectionHeaderFields $kCOFFHeaderSize $kSectionHeaderSize
    $kIMAGE_FILE_RELOCS_STRIPPED
    $kIMAGE_FILE_EXECUTABLE_IMAGE
    $kIMAGE_FILE_LINE_NUMS_STRIPPED
    $kIMAGE_FILE_LOCAL_SYMS_STRIPPED
    $kIMAGE_FILE_AGGRESSIVE_WS_TRIM
    $kIMAGE_FILE_LARGE_ADDRESS_AWARE
    $kIMAGE_FILE_RESERVED
    $kIMAGE_FILE_BYTES_REVERSED_LO
    $kIMAGE_FILE_32BIT_MACHINE
    $kIMAGE_FILE_DEBUG_STRIPPED
    );

#-- Constant data

our %rsrcTypes = (
    1  => 'CURSOR',
    2  => 'BITMAP',
    3  => 'ICON',
    4  => 'MENU',
    5  => 'DIALOG',
    6  => 'STRING',
    7  => 'FONTDIR',
    8  => 'FONT',
    9  => 'ACCELERATOR',
    10 => 'RCDATA',
    11 => 'MESSAGETABLE',
    12 => 'GROUP_CURSOR',
    13 => 'GROUP_ICON',
    16 => 'VERSION',
    17 => 'DLGINCLUDE',
    19 => 'PLUGPLAY',
    20 => 'VXD',
    21 => 'ANICURSOR',
    22 => 'ANIICON',
    23 => 'HTML',
    24 => 'MANIFEST',
    );

# COFF Characteristics flags
our $kIMAGE_FILE_RELOCS_STRIPPED = 0x0001;
    #Image only, Windows CE, and Windows NT® and later. This indicates that the
    #file does not contain base relocations and must therefore be loaded at its
    #preferred base address. If the base address is not available, the loader
    #reports an error. The default behavior of the linker is to strip base
    #relocations from executable (EXE) files.
our $kIMAGE_FILE_EXECUTABLE_IMAGE = 0x0002;
    #Image only. This indicates that the image file is valid and can be run. If
    #this flag is not set, it indicates a linker error.
our $kIMAGE_FILE_LINE_NUMS_STRIPPED = 0x0004;
    #COFF line numbers have been removed. This flag is deprecated and should be
    #zero.
our $kIMAGE_FILE_LOCAL_SYMS_STRIPPED = 0x0008;
    #COFF symbol table entries for local symbols have been removed. This flag is
    #deprecated and should be zero.
our $kIMAGE_FILE_AGGRESSIVE_WS_TRIM = 0x0010;
    #Obsolete. Aggressively trim working set. This flag is deprecated for
    #Windows 2000 and later and must be zero.
our $kIMAGE_FILE_LARGE_ADDRESS_AWARE = 0x0020;
    #Application can handle > 2 GB addresses.
our $kIMAGE_FILE_RESERVED = 0x0040;
    #This flag is reserved for future use.
our $kIMAGE_FILE_BYTES_REVERSED_LO = 0x0080;
    #Little endian: the least significant bit (LSB) precedes the most
    #significant bit (MSB) in memory. This flag is deprecated and should be
    #zero.
our $kIMAGE_FILE_32BIT_MACHINE = 0x0100;
    #Machine is based on a 32-bit-word architecture.
our $kIMAGE_FILE_DEBUG_STRIPPED = 0x0200;
    #Debugging information is removed from the image file.

our @kCOFFKeys = qw(
    Machine NumberOfSections TimeDateStamp PointerToSymbolTable
    NumberOfSymbols SizeOfOptionalHeader Characteristics
    );
our @kVersionStringKeys = qw(
    Comments FileDescription FileVersion InternalName LegalCopyright
    LegalTrademarks OriginalFilename PrivateBuild ProductName
    ProductVersion SpecialBuild
    );
our @kOptionalHeaderFields = qw (
    Magic MajorLinkerVersion MinorLinkerVersion SizeOfCode
    SizeOfInitializedData SizeOfUninitializedData
    AddressOfEntryPoint BaseOfCode
    );
our @kOptHeaderSectionCodes = qw(
    .edata .idata .rsrc .pdata certTable .reloc .debug Architecture GlobalPtr
    .tls LoadConfig BoundImport IAT DelayImportDescriptor .cormeta Reserved
    );
our @kStdSectionCodes = qw(
    .text .rdata .data .rsrc
    .bss .cormeta .debug$F .debug$P .debug$S .debug$T .drective .edata
    .idata .idlsym .pdata .reloc .sbss .sdata .srdata .sxdata
    .tls .tls$ .vsdata .xdata certTable Architecture GlobalPtr LoadConfig
    BoundImport IAT DelayImportDescriptor Reserved
    );
our %kStdSectionCodeLu =
    map {my $value = $_; $value =~ s/\W+//g; $_ => $value} @kStdSectionCodes;
our @kSectionHeaderFields = qw(
    Name VirtualSize VirtualAddress SizeOfRawData PointerToRawData
    PointerToRelocations PointerToLinenumbers NumberOfRelocations
    NumberOfLinenumbers Characteristics
    );

our $kCOFFHeaderSize    = 20;
our $kSectionHeaderSize = 40;

return 1;
