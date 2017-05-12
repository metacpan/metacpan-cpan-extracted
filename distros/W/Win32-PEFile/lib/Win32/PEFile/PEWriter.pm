package Win32::PEFile::PEWriter;
use strict;
use warnings;
use Encode;
use Carp;
use Win32::PEFile::PEConstants;
use Win32::PEFile::SectionHandlers;

push @Win32::PEFile::PEWriter::ISA, 'Win32::PEFile::PEBase';


sub new {
    my ($class, %params) = @_;
    my $self = bless \%params, $class;

    die "Parameter -file is required for $class->new ()\n"
        if !exists $params{'-file'};

    $self->_clearCaches();
    $self->{owner}{err} = $@ || '';
    return $self;
}


sub getSectionNames {
    my ($self) = @_;

    if (! $self->{sectionNames}) {
        @{$self->{sectionNames}} =
            grep {exists $self->{owner}{SecData}{$_}} @kStdSectionCodes;
    }

    return @{$self->{sectionNames}};
}


sub writeFile {
    my ($self) = @_;
    my $buffer = '';

    $self->_clearCaches();

    $self->{fileAlignment} = $self->{owner}{OptionalHeader}{FileAlignment};
    $self->{faMasked}      = $self->{fileAlignment} - 1;
    $self->{faMask}        = ~$self->{faMasked};

    $self->_measureSections();
    $self->{coffHeader}{SizeOfOptionalHeader} = 0;
    $self->{optionalHeaderBin} = undef;

    my $headerSize = length $self->_getOptionalHeaderBin();
    $headerSize += length $self->_getDataDirectoryBin();

    open my $peFile, '>', $self->{-file} or die "unable to create file - $!\n";
    binmode $peFile;

    print $peFile 'MZ', ("\0") x 58;    # Add sig and pad to PE header index
    $self->{peOffset} ||= 0x40;         # Default location of the PE header

    my $stubEnd = $self->{peOffset};

    if (exists $self->{owner}{MSDOSStub}) {
        # Adjust PE header location to accomodate MS-DOS stub
        $self->{peOffset} = $stubEnd += length $self->{owner}{MSDOSStub};
        $self->{peOffset} = ($self->{peOffset} + 7) & ~7;
    }

    # Write the file address of the PE header start
    print $peFile pack('V', $self->{peOffset});

    if ($self->{owner}{MSDOSStub}) {
        # Write the MS-DOS stub
        print $peFile $self->{owner}{MSDOSStub};
        print $peFile "\0" x ($self->{peOffset} - $stubEnd)
            if $self->{peOffset} != $stubEnd;
    }

    my $peStart = tell $peFile;

    print $peFile "PE\0\0";

    $self->_resetCoff();

    $self->_calcSectionsData();
    $self->_layoutSections($peStart + $self->_getOptionalHeaderSize());
    
    # Update COFF header and write it
    $self->{coffHeader}{TimeDateStamp} ||= time;
    $self->{coffHeader}{SizeOfOptionalHeader} ||=
        $self->_getOptionalheaderSize();

    my @coffValues = @{$self->{coffHeader}}{@kCOFFKeys};

    print $peFile pack('vvVVVvv', @coffValues);

    $self->_writeOptionalHeader($peFile);
    $self->_writeSectionsTable($peFile);

    my $headerEnd = tell $peFile;

    $self->_writeSections($peFile);
    close $peFile;
    return 1;
}


sub _clearCaches {
    my ($self) = @_;
    my $buffer = '';

    $self->{peOffset}          = 64;
    $self->{optionalHeaderBin} = undef;
    $self->{sectionNames} = undef;
    return 1;
}


sub _resetCoff {
    my ($self) = @_;

    $self->{coffHeader}{Machine}              ||= 0x14c; # Intel 386 or later machine
    $self->{coffHeader}{NumberOfSections}     ||= 0;
    $self->{coffHeader}{TimeDateStamp}        ||= 0;
    $self->{coffHeader}{PointerToSymbolTable} ||= 0;
    $self->{coffHeader}{NumberOfSymbols}      ||= 0;
    $self->{coffHeader}{SizeOfOptionalHeader} ||= 0;
    $self->{coffHeader}{Characteristics} ||=
        $kIMAGE_FILE_EXECUTABLE_IMAGE | $kIMAGE_FILE_32BIT_MACHINE;
}


sub _getOptionalheaderSize {
    my ($self) = @_;

    $self->_genOptionalHeader() if !defined $self->{optionalHeader};
    return length $self->{optionalHeader}{end};
}


sub _measureSections {
    my ($self) = @_;
    my $sectionStart = 0;

    for my $secName ($self->getSectionNames()) {
        my $blob;
        my $section = $self->{owner}{SecData}{$secName};

        if (exists $kStdSectionCodeLu{$secName}) {
            $self->_dispatch(_assemble => $secName);
            $blob = $self->_dispatch(_getSecData => $section->{header}{Name})
                if $section->{header};
        } else {
            # Default handling - just treat the data as a blob and create a data
            # directory entry in the OptionalHeader table for the section
            die "Need to impliment default section handling in _measureSections\n";
        }

        next if !$section->{header};
        
        if (!defined $blob || !length $blob) {
            if (exists $section->{rawData}) {
                $blob = $section->{rawData};
            } else {
                open my $blobIn, '<', $self->{owner}{reader}{-file};
                binmode $blobIn;
                seek $blobIn, $section->{header}{PointerToRawData}, 0;
                read $blobIn, $blob, $section->{header}{SizeOfRawData};
            }
        }

        $self->{SecData}{$secName} = {} if ! defined $self->{SecData}{$secName};
        my $wSec = $self->{SecData}{$secName};

        @{$wSec->{header}}{@kSectionHeaderFields} =
            @{$section->{header}}{@kSectionHeaderFields};
        $wSec->{header}{PointerToRawData} = $sectionStart;
        $wSec->{header}{SizeOfRawData}    = length $blob;
        $wSec->{blob}                     = $blob;
        $sectionStart =
            ($self->{faMasked} + $sectionStart + length $blob) &
            $self->{faMask};
    }
}


sub _layoutSections {
    my ($self, $sectionStart) = @_;

    for my $secName ($self->getSectionNames()) {
        next if !exists $self->{SecData}{$secName};
        my $wSec = $self->{SecData}{$secName};
        my $blobLen = length $wSec->{blob} || next;

        $sectionStart = ($self->{faMasked} + $sectionStart) & $self->{faMask};
        $wSec->{header}{PointerToRawData} = $sectionStart;
        $wSec->{header}{SizeOfRawData}    = $blobLen;
        $sectionStart += $blobLen;
    }
}


sub _getOptionalHeaderBin {
    my ($self) = @_;

    return $self->{optionalHeaderBin} if $self->{optionalHeaderBin};

    my $opt = $self->{owner}{OptionalHeader} ||= {};

    $self->{is32Plus} = $opt->{Magic} == 0x20B if $opt->{Magic};
    $opt->{Magic} ||= 0x20B if $self->{is32Plus};
    $opt->{Magic} ||= 0x10b;

    my $bin = pack('v', $opt->{Magic});
    $bin .= pack('C', $opt->{MajorLinkerVersion}      ||= 0);
    $bin .= pack('C', $opt->{MinorLinkerVersion}      ||= 0);
    $bin .= pack('V', $opt->{SizeOfCode}              ||= 0);
    $bin .= pack('V', $opt->{SizeOfInitializedData}   ||= 0);
    $bin .= pack('V', $opt->{SizeOfUninitializedData} ||= 0);
    $bin .= pack('V', $opt->{AddressOfEntryPoint}     ||= 0);
    $bin .= pack('V', $opt->{BaseOfCode}              ||= 0);

    if ($self->{is32Plus}) {
        $bin .= pack('V', $opt->{ImageBaseL} || 0);
        $bin .= pack('V', $opt->{ImageBaseH} || 0);
    } else {
        $bin .= pack('V', $opt->{BaseOfData} ||= 0);
        $bin .= pack('V', $opt->{ImageBase} || 0x400000);
    }

    $bin .= pack('V', $opt->{SectionAlignment}            ||= 32);
    $bin .= pack('V', $opt->{FileAlignment}               ||= 32);
    $bin .= pack('v', $opt->{MajorOperatingSystemVersion} ||= 4);
    $bin .= pack('v', $opt->{MinorOperatingSystemVersion} ||= 0);
    $bin .= pack('v', $opt->{MajorImageVersion}           ||= 0);
    $bin .= pack('v', $opt->{MinorImageVersion}           ||= 0);
    $bin .= pack('v', $opt->{MajorSubsystemVersion}       ||= 0);
    $bin .= pack('v', $opt->{MinorSubsystemVersion}       ||= 0);
    $bin .= pack('V', $opt->{Win32VersionValue}           ||= 0);
    $bin .= pack('V', $opt->{SizeOfImage}                 ||= 0);
    $bin .= pack('V', $opt->{SizeOfHeaders}               ||= 0);
    $bin .= pack('V', $opt->{CheckSum}                    ||= 0);
    $bin .= pack('v', $opt->{Subsystem}                   ||= 0);
    $bin .= pack('v', $opt->{DllCharacteristics}          ||= 0x400 | 0x800);

    if ($self->{is32Plus}) {
        $bin .= pack('V', $opt->{SizeOfStackReserveL} ||= 0);
        $bin .= pack('V', $opt->{SizeOfStackReserveH} ||= 0);
        $bin .= pack('V', $opt->{SizeOfStackCommitL}  ||= 0);
        $bin .= pack('V', $opt->{SizeOfStackCommitH}  ||= 0);
        $bin .= pack('V', $opt->{SizeOfHeapReserveL}  ||= 0);
        $bin .= pack('V', $opt->{SizeOfHeapReserveH}  ||= 0);
        $bin .= pack('V', $opt->{SizeOfHeapCommitL}   ||= 0);
        $bin .= pack('V', $opt->{SizeOfHeapCommitH}   ||= 0);
    } else {
        $bin .= pack('V', $opt->{SizeOfStackReserve} ||= 0);
        $bin .= pack('V', $opt->{SizeOfStackCommit}  ||= 0);
        $bin .= pack('V', $opt->{SizeOfHeapReserve}  ||= 0);
        $bin .= pack('V', $opt->{SizeOfHeapCommit}   ||= 0);
    }

    $bin .= pack('V', $opt->{LoaderFlags}         ||= 0);
    $bin .= pack('V', $opt->{NumberOfRvaAndSizes} ||= 0);

    return $self->{optionalHeaderBin} = $bin;
}


sub _getDataDirectoryBin {
    my ($self) = @_;

    return $self->{dataDirectoryBin} if $self->{dataDirectoryBin};

    my $opt     = $self->{owner}{OptionalHeader};
    my $bin     = '';
    my @rFields = qw(imageRVA size);

    for my $field (@kOptHeaderSectionCodes) {
        my $record = $self->{owner}{DataDir}{$field};

        $record->{$_} ||= 0 for @rFields;
        $bin .= pack('VV', @{$record}{@rFields});
    }

    return $self->{dataDirectoryBin} = $bin;
}


sub _calcSectionsData {
    my ($self) = @_;

    $self->{coffHeader}{NumberOfSections} = @{$self->{sectionNames}};

    my $alignmentMask = $self->{owner}{OptionalHeader}{FileAlignment} - 1;
    my $headersEnd =
        $self->{peOffset} +
        $kCOFFHeaderSize +
        $self->{coffHeader}{SizeOfOptionalHeader} +
        @{$self->{sectionNames}} * $kSectionHeaderSize;
    my $nextSectionStart = ($headersEnd + $alignmentMask) & ~$alignmentMask;

    $self->{owner}{OptionalHeader}{BaseOfData} = $nextSectionStart;

    for my $sectionName (@{$self->{sectionNames}}) {
        my $secBin       = $self->{secDataBin}{$sectionName};
        my $dirDataEntry = $self->{owner}{DataDir}{$sectionName};

        $dirDataEntry->{size} =
            $self->_dispatch(_calcSize => $sectionName, $nextSectionStart);

        if (!$dirDataEntry->{size}) {
            $dirDataEntry->{size}     = 0;
            $dirDataEntry->{imageRVA} = 0;
            next;
        }

        my $blockSize =
            ($dirDataEntry->{size} + $alignmentMask) & ~$alignmentMask;
        my $header = $self->{owner}{SecData}{$sectionName}{header} ||= {};

        $dirDataEntry->{filePos} = $nextSectionStart;
        $dirDataEntry->{fileBiss} =
            $dirDataEntry->{imageRVA} - $nextSectionStart;
        $header->{Name}                 = $sectionName;
        $header->{VirtualSize}          = $dirDataEntry->{size};
        $header->{VirtualAddress}       = $dirDataEntry->{imageRVA};
        $header->{SizeOfRawData}        = $blockSize;
        $header->{PointerToRawData}     = $nextSectionStart;
        $header->{PointerToRelocations} = 0;
        $header->{PointerToLinenumbers} = 0;
        $header->{NumberOfRelocations}  = 0;
        $header->{NumberOfLinenumbers}  = 0;
        $header->{Characteristics} ||= 0;

        $nextSectionStart += $blockSize;
    }
}


sub _getOptionalHeaderSize {
    my ($self) = @_;

    $self->{coffHeader}{SizeOfOptionalHeader} = $self->{is32Plus} ? 240 : 224;
    return $self->{coffHeader}{SizeOfOptionalHeader};
}


sub _writeOptionalHeader {
    my ($self, $peFile) = @_;
    my $opt = $self->{owner}{OptionalHeader};

    $self->{is32Plus} ||= $opt->{Magic} == 0x20B;
    $opt->{Magic} = 0x20B if $self->{is32Plus};
    print $peFile pack('vCCVVVVV', @{$opt}{@kOptionalHeaderFields});

    if ($self->{is32Plus}) {
        $self->_writePE32PlusOpt($peFile);
    } else {
        $self->_writePE32Opt($peFile);
    }

    $self->_writeDataDirectory($peFile);
}


sub _writePE32Opt {
    my ($self, $peFile) = @_;
    my $opt    = $self->{owner}{OptionalHeader};
    my @fields = (
        qw(
            ImageBase SectionAlignment FileAlignment MajorOperatingSystemVersion
            MinorOperatingSystemVersion MajorImageVersion MinorImageVersion
            MajorSubsystemVersion MinorSubsystemVersion Win32VersionValue
            SizeOfImage SizeOfHeaders CheckSum Subsystem DllCharacteristics
            SizeOfStackReserve SizeOfStackCommit SizeOfHeapReserve
            SizeOfHeapCommit LoaderFlags NumberOfRvaAndSizes
            )
            );

    print $peFile pack('V', $opt->{BaseOfData} ||= 0);
    my $start = tell $peFile;
    print $peFile pack('VVVvvvvvvVVVVvvVVVVVV', map {$_ || 0} @{$opt}{@fields});

    my $pos = tell $peFile;
    return;
    # $blk passed in starts at offset 20 and 4 bytes are removed by substr above
    # so offset to data directory is 96 - (24 + 4) = 68
}


sub _writePE32PlusOpt {
    my ($self, $peFile) = @_;
    my $opt    = $self->{owner}{OptionalHeader};
    my @fields = (
        qw(
            ImageBaseL ImageBaseH SectionAlignment FileAlignment
            MajorOperatingSystemVersion MinorOperatingSystemVersion
            MajorImageVersion MinorImageVersion MajorSubsystemVersion
            MinorSubsystemVersion Win32VersionValue SizeOfImage SizeOfHeaders
            CheckSum Subsystem DllCharacteristics SizeOfStackReserveL
            SizeOfStackReserveH SizeOfStackCommitL SizeOfStackCommitH
            SizeOfHeapReserveL SizeOfHeapReserveH SizeOfHeapCommitL
            SizeOfHeapCommitH LoaderFlags NumberOfRvaAndSizes
            )
            );

    my $start = tell $peFile;
    print $peFile
        pack('VVVVvvvvvvVVVVvvVVVVVVVVVV', map {$_ || 0} @{$opt}{@fields});

    my $pos = tell $peFile;
    return;
    # $blk passed in starts at offset 20 so offset to data directory is 112 - 24
}


sub _writeDataDirectory {
    my ($self, $peFile) = @_;

    for my $field (@kOptHeaderSectionCodes) {
        if (exists $self->{owner}{DataDir}{$field}) {
            my $record = $self->{owner}{DataDir}{$field};
            print $peFile pack('VV', @{$record}{'imageRVA', 'size'});
        } else {
            print $peFile pack('VV', 0, 0);
        }
    }
}


sub _writeSectionsTable {
    my ($self, $peFile) = @_;

    for my $secName (@{$self->{sectionNames}}) {
        my $section = $self->{owner}{SecData}{$secName};

        next if !exists $section->{header};
        print $peFile
            pack('a8VVVVVVvvV', @{$section->{header}}{@kSectionHeaderFields});
    }
}


sub _writeSections {
    my ($self, $peFile) = @_;

    for my $secName (@{$self->{sectionNames}}) {
        my $blob   = $self->{SecData}{$secName}{blob};
        my $pos    = tell $peFile;
        my $target = ($self->{faMasked} + $pos) & $self->{faMask};

        $blob = '' if ! defined $blob;

        if ($pos < $target) {
            my $padding = "\0" x ($target - $pos);

            print $peFile $padding;
        }

        print $peFile $blob;
    }
}


1;


