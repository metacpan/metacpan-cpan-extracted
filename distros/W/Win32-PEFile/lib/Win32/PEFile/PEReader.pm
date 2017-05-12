package Win32::PEFile::PEReader;

use strict;
use warnings;
use Encode;
use Carp;
use Win32::PEFile::PEBase;
use Win32::PEFile::PEConstants;

push @Win32::PEFile::PEReader::ISA, 'Win32::PEFile::PEBase';


sub new {
    my ($class, %params) = @_;
    my $self = bless \%params, $class;

    die "Parameter -file is required for $class->new ()\n"
        if !exists $params{'-file'};

    $self->{owner}{ok} = eval {$self->_parseFile()};
    $self->{owner}{err} = $@ || '';
    return $self;
}


sub getSection {
    my ($self, $sectionCode) = @_;

    return $self->_dispatch(_parseSectionData => $sectionCode);
}


sub getSectionNames {
    my ($self) = @_;
    my @names = keys %{$self->{owner}{DataDir}};
    my @sections = grep {$self->{owner}{DataDir}{$_}{size}} @names;

    return @sections;
}


sub _parseFile {
    my ($self) = @_;
    my $buffer = '';

    eval {
        open my $peFile, '<', $self->{owner}{'-file'}
            or die "unable to open '$self->{owner}{'-file'}' - $!\n";
        binmode $peFile;

        read $peFile, $buffer, 256, 0 or die "file read error: $!\n";

        die "No MZ header found\n" if $buffer !~ /^MZ/;

        $self->{peOffset} = substr($buffer, 0x3c, 4);
        $self->{peOffset} = unpack('V', $self->{peOffset});
        seek $peFile, 0x40, 0;

        if ($self->{peOffset} != 0x40) {
            read $peFile, $buffer, $self->{peOffset} - 0x40, 0;
            $self->{owner}{MSDOSStub} = $buffer;
        }

        seek $peFile, $self->{peOffset}, 0;

        (read $peFile, $buffer, 4 and $buffer =~ /^PE\0\0/)
            or die "corrupt or not a PE file \n";

        read $peFile, $buffer, 20, 0 or die "file read error: $!\n";
        @{$self->{owner}{COFFHeader}}{@kCOFFKeys} = unpack('vvVVVvv', $buffer);

        if ($self->{owner}{COFFHeader}{SizeOfOptionalHeader}) {
            my $opt = $self->{owner}{OptionalHeader} = {};

            read $peFile, $opt->{raw},
                $self->{owner}{COFFHeader}{SizeOfOptionalHeader}, 0;
            @{$opt}{@kOptionalHeaderFields} = unpack('vCCVVVVV', $opt->{raw});

            my $blk = substr $opt->{raw}, 24;

            $self->{is32Plus} = $opt->{Magic} == 0x20B;

            if ($self->{is32Plus}) {
                $self->_parsePE32PlusOpt($blk);
            } else {
                $self->_parsePE32Opt($blk);
            }

            $self->_parseSectionsTable($peFile);
            $self->_findDataDirData($peFile);
        }

        close $peFile;
    };

    die "Error in PE file $self->{'-file'}: $@\n" if $@;
    return 1;
}


sub _parsePE32Opt {
    my ($self, $blk) = @_;
    my $len    = length $blk;
    my @fields = (
        qw(
            ImageBase SectionAlignment FileAlignment MajorOperatingSystemVersion
            MinorOperatingSystemVersion MajorImageVersion MinorImageVersion
            MajorSubsystemVersion MinorSubsystemVersion Win32VersionValue
            SizeOfImage SizeOfHeaders CheckSum Subsystem DllCharacteristics
            SizeOfStackReserve SizeOfStackCommit SizeOfHeapReserve
            SizeOfHeapCommit LoaderFlags NumberOfRvaAndSizes )
            );

    $self->{owner}{OptionalHeader}{BaseOfData} =
        unpack('V', substr $blk, 0, 4, '');
    @{$self->{owner}{OptionalHeader}}{@fields} =
        unpack('VVVvvvvvvVVVVvvVVVVVV', $blk);

    # $blk passed in starts at offset 20 and 4 bytes are removed by substr above
    # so offset to data directory is 96 - (24 + 4) = 68
    $self->_parseDataDirectory(substr $blk, 68);
}


sub _parsePE32PlusOpt {
    my ($self, $blk) = @_;
    my $len    = length $blk;
    my @fields = (
        qw(
            ImageBaseL ImageBaseH SectionAlignment FileAlignment
            MajorOperatingSystemVersion MinorOperatingSystemVersion
            MajorImageVersion MinorImageVersion MajorSubsystemVersion
            MinorSubsystemVersion Win32VersionValue SizeOfImage SizeOfHeaders
            CheckSum Subsystem DllCharacteristics SizeOfStackReserveL
            SizeOfStackReserveH SizeOfStackCommitL SizeOfStackCommitH
            SizeOfHeapReserveL SizeOfHeapReserveH SizeOfHeapCommitL
            SizeOfHeapCommitH LoaderFlags NumberOfRvaAndSizes )
            );

    @{$self->{owner}{OptionalHeader}}{@fields} =
        unpack('VVVVvvvvvvVVVVvvVVVVVVVVVV', $blk);

    # $blk passed in starts at offset 20 so offset to data directory is 112 - 24
    $self->_parseDataDirectory(substr $blk, 88);
}


sub _parseDataDirectory {
    my ($self, $blk) = @_;
    my $len = length $blk;
    my @entries;

    for (1 .. $self->{owner}{OptionalHeader}{NumberOfRvaAndSizes}) {
        my $addr = unpack('V', substr $blk, 0, 4, '');
        my $size = unpack('V', substr $blk, 0, 4, '');

        push @entries, {imageRVA => $addr, size => $size};
        last if !length $blk;
    }

    @{$self->{owner}{DataDir}}{@kOptHeaderSectionCodes} = @entries;
    return;
}


sub _parseSectionsTable {
    my ($self, $peFile) = @_;
    my $sections = $self->{owner}{SecData} ||= {};

    for (1 .. $self->{owner}{COFFHeader}{NumberOfSections}) {
        my %section;
        my $raw;

        read $peFile, $raw, 40, 0;
        @section{@kSectionHeaderFields} = unpack('a8VVVVVVvvV', $raw);
        $section{Name} =~ s/\x00+$//;
        $self->{owner}{SecData}{$section{Name}}{header} = \%section;
    }
}


sub _findDataDirData {
    my ($self, $peFile) = @_;

    for my $entry (values %{$self->{owner}{DataDir}}) {
        next if !$entry->{size};    # size is zero

        for my $sectionName (keys %{$self->{owner}{SecData}}) {
            my $header = $self->{owner}{SecData}{$sectionName}{header};
            my $start = $header->{VirtualAddress};
            my $end = $header->{VirtualAddress} + $header->{VirtualSize};

            next if $start > $entry->{imageRVA} || $end < $entry->{imageRVA};

            # Found the section data
            $entry->{fileBias} =
                $header->{VirtualAddress} - $header->{PointerToRawData};
            $entry->{filePos}  = $entry->{imageRVA} - $entry->{fileBias};
            $header->{filePos} = $entry->{filePos};
            last;
        }
    }
}


1;


