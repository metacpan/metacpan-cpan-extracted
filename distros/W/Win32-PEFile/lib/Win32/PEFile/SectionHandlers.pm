package Win32::PEFile::SectionHandlers;

use strict;
use warnings;
use Carp qw();
use Win32::PEFile::PEConstants;

our %_EntryPoints;
our %_SectionNames;


sub parseSection {
    my ($section) = @_;
}


sub register {
    my ($class, $sectionCode, @methods) = @_;

    $_SectionNames{$sectionCode} = $class;
    $_EntryPoints{$_} = $class for @methods;

    my $doUIName = $class->can('uiName');

    $doUIName or die "'$class' requires a uiName method\n";

    my $uiName = $doUIName->();
    (my $type = $class) =~ s/.*:(\w+)Handler$/$1/;

    $class->can("${_}_$type")
        or die "'$class' requires a ${_}_$type method\n"
        for '_calcSize', "_parse", "_assemble";
}


sub _readSectionDataEntry {
    my ($self, $fh, $offset, $sectionOffset) = @_;
    my $oldPos = tell $fh;
    my %sect;

    seek $fh, $offset + $sectionOffset, 0;
    read $fh, my $rData, 16 or die "file read error: $!\n";
    my ($dataRVA, $size, $codePage) = unpack ('VVVV', $rData);
    my $imageRVA      = $self->{DataDir}{'.rsrc'}{imageRVA};
    my $resDataOffset = $dataRVA - $imageRVA;

    $sect{sectCodepage} = $codePage;
    $sect{sectOffset}   = $offset;
    seek $fh, $resDataOffset + $sectionOffset, 0;
    read $fh, $sect{sectData}, $size or die "file read error: $!\n";

    seek $fh, $oldPos, 0;
    return \%sect;
}


sub _readSzStr {
    my ($self, $fh, $offset) = @_;
    my $oldPos = tell $fh;
    my $str    = '';

    seek $fh, $offset, 0 if defined $offset;
    read $fh, my $strBytes, 2 or die "file read error: $!\n";
    $strBytes = 2 * unpack ('v', $strBytes);

    if ($strBytes) {
        read $fh, $str, $strBytes or die "file read error: $!\n";
        $str = Encode::decode('UTF-16LE', $str);
    }

    seek $fh, $oldPos, 0 if defined $offset;
    return $str;
}


package Win32::PEFile::rsrcHandler;

use Win32::PEFile::PEConstants;

my @kDirTableFields = qw(
    Characteristics TimeDate MajorVersion MinorVersion
    NumNameEntries NumIDEntries
    );


push @Win32::PEFile::rsrcHandler::ISA, 'Win32::PEFile::SectionHandlers';
Win32::PEFile::rsrcHandler->register(
    '.rsrc',
    qw'addResource addVersionResource
        getVersionStrings getFixedVersionValues getResourceData
        getVersionCount'
);


sub uiName {
    return 'Resources';
}


sub addResource {
    my ($self, %params) = @_;
    my @requiredFields = qw{data lang name type};
    my @missing = grep {!exists $params{$_}} @requiredFields;

    Carp::croak "The following fields are required by addResource: @missing"
        if @missing;

    $self->{SecData}{'.rsrc'}{Entries} ||= {};

    my $rsrc = $self->_buildResourceEntry(
        -path => [$params{type}, $params{name}, $params{lang}],
        -root => $self->{SecData}{'.rsrc'},
        %params
    );

    my $header = $self->{SecData}{'.rsrc'}{header} ||= {};
    my $dDir   = $self->{DataDir}{'.rsrc'}         ||= {};

    $header->{VirtualSize} += length $rsrc->{sectData};
    $dDir->{size}     ||= undef;
    $dDir->{filePos}  ||= undef;
    $dDir->{fileBias} ||= undef;
    $dDir->{imageRVA} ||= 16384;
}


sub addVersionResource {
    my ($self, %params) = @_;
    my %verStringKeys = map {$_ => undef} @kVersionStringKeys;
    my @strings = grep {exists $verStringKeys{$_}} keys %params;

    $params{lang} = 0x0409 if ! defined $params{lang};
    $params{strings}{$_} = $params{$_} for @strings;

    $params{name} = 1 if ! defined $params{name};
    $self->addResource(
        data => $self->_buildVersionInfo(%params),
        lang => $params{lang},
        type => 'VERSION',
        name => $params{name},
    );
}


sub getVersionStrings {
    my ($self, $lang) = @_;
    my $verResource;

    ($verResource, $lang) = $self->getResourceData('VERSION', 1, $lang);

    my $entries = $self->{SecData}{'.rsrc'}{Entries} ||= {};

    return if !$verResource || !exists $entries->{VERSION}{1}{$lang};

    $self->_parseVersionInfo($lang);

    my $strings = $entries->{VERSION}{1}{$lang}{StringFileInfo};
    return wantarray ? ($strings, $lang) : $strings;
}


sub getVersionCount {
    my ($self, $lang) = @_;
    my $count = 0;

    my ($verResource, $langDef) = $self->getResourceData('VERSION', 1, $lang);
    my $entries = $self->{SecData}{'.rsrc'}{Entries}{VERSION};

    for my $version (keys %$entries) {
        $count +=
            grep {!defined $lang or $_ == $lang} keys %{$entries->{$version}};
    }

    return $count;
}


sub getFixedVersionValues {
    my ($self, $lang) = @_;
    my $verResource;

    ($verResource, $lang) = $self->getResourceData('VERSION', 1, $lang);

    my $entries = $self->{SecData}{'.rsrc'}{Entries};

    return if !$verResource || !exists $entries->{VERSION}{1}{$lang};

    $self->_parseVersionInfo($lang);
    my $info = $entries->{VERSION}{1}{$lang}{FixedFileInfo};
    return wantarray ? ($info, $lang) : $info;
}


sub getResourceData {
    my ($self, $type, $name, $lang) = @_;

    return
        if !$self->_parse_rsrc(
        'rsrc',
        type => $type,
        name => $name,
        lang => $lang
        );

    my $entries = $self->{SecData}{'.rsrc'}{Entries};

    return if !exists $entries->{$type};

    if (   !defined $lang
        || !exists $entries->{$type}{$name}{$lang})
    {
        my %langs = map {$_ => 1} keys %{$entries->{$type}{$name}};

        $lang ||= 0x0409;    # Default to US English
        $lang = (keys %langs)[0] if !exists $langs{$lang};
    }

    return $entries->{$type}{$name}{$lang}{sectData}, $lang;
}


sub _parse_rsrc {
    my ($self) = @_;
    my $fName = $self->{'-file'};

    return if !-f $fName;

    my $rsrcHdr = $self->{DataDir}{'.rsrc'};

    open my $peFile, '<', $fName or die "unable to open '$fName' - $!\n";
    binmode ($peFile);

    $self->{SecData}{'.rsrc'}{Entries} = {};
    $self->_parseRsrcTable($self->{SecData}{'.rsrc'}{Entries},
        $peFile, 0, $rsrcHdr->{filePos});
    close $peFile;
    return 1;
}


sub _parseRsrcTable {
    my ($self, $rsrc, $fh, $filePos, $sectionOffset, $level) = @_;
    my $oldPos = tell $fh;

    ++$level;
    seek $fh, $filePos + $sectionOffset, 0;
    read $fh, (my $rData), 16;

    my %dirTable;
    my $entries = $self->{SecData}{'.rsrc'}{Entries};

    @dirTable{@kDirTableFields} = unpack ('VVvvvv', $rData);
    $self->{SecData}{'.rsrc'}{dirTable} = \%dirTable;

    my ($numNames, $numIDs) = @dirTable{qw(NumNameEntries NumIDEntries)};

    # Handle IMAGE_RESOURCE_DIRECTORY_ENTRY DirectoryEntries[]
    while ($numNames || $numIDs) {
        read $fh, $rData, 8;

        my ($RVAOrID, $RVA) = unpack ('VV', $rData);
        my $addr = ($RVA & ~0x80000000);
        my $rsrcId;

        if ($numNames) {
            # Fetch the entry name. $RVAOrID is the RVA
            --$numNames;
            $rsrcId =
                $self->_readSzStr($fh,
                ($RVAOrID & ~0x80000000) + $sectionOffset);

        } elsif ($numIDs) {
            # Resource ID. $RVAOrID is the ID
            --$numIDs;
            $rsrcId = $RVAOrID;
            $rsrcId = $rsrcTypes{$rsrcId}
                if $level == 1 && exists $rsrcTypes{$rsrcId};
        }

        if (0 != ($RVA & 0x80000000)) {
            # It's a sub table entry
            $rsrc->{$rsrcId} = {};
            $self->_parseRsrcTable($rsrc->{$rsrcId}, $fh, $addr, $sectionOffset,
                $level);
        } else {
            # It's a data entry
            $rsrc->{$rsrcId} =
                $self->_readSectionDataEntry($fh, $RVA, $sectionOffset);
            next;
        }
    }

    seek $fh, $oldPos, 0;
}


sub _parseVersionInfo {
    my ($self, $lang) = @_;
    my $entries = $self->{SecData}{'.rsrc'}{Entries} ||= {};

    return $lang
        if defined $lang
        && exists $entries->{VERSION}{1}{$lang}{FixedFileInfo};
    return if !exists $entries->{VERSION}{1};

    #struct VS_VERSIONINFO {
    #  WORD  wLength;
    #  WORD  wValueLength;
    #  WORD  wType;
    #  WCHAR szKey[]; // "VS_VERSION_INFO".
    #  WORD  Padding1[];
    #  VS_FIXEDFILEINFO Value;
    #  WORD  Padding2[];
    #  WORD  Children[];
    #};

    if (!defined $lang) {
        # Default to US-en if available, otherwise pick any
        my @langs = grep {exists $entries->{VERSION}{1}{$_}} 0x0409,
            keys %{$entries->{VERSION}{1}};
        $lang = $langs[0];
    }

    my $rsrcEntry = $entries->{VERSION}{1}{$lang};
    open my $resIn, '<', \$rsrcEntry->{sectData};
    binmode $resIn;

    while (read $resIn, (my $data), 6) {
        my %header = (sectOffset => $rsrcEntry->{sectOffset});

        @header{qw(length valueLength isText)} = unpack ('vvv', $data);
        read $resIn, $header{type}, 4;
        $header{type} = Encode::decode('UTF-16LE', $header{type});

        if ($header{type} eq 'VS') {
            $self->_parseFixedFileInfo($rsrcEntry, $resIn, \%header);
        } elsif ($header{type} eq 'Va') {
            $self->_parseVarFileInfo($rsrcEntry, $resIn, \%header);
        } elsif ($header{type} eq 'St') {
            $self->_parseStringFileInfo($rsrcEntry, $resIn, \%header);
        } else {
            die "Unknown version resource info prefix: $header{type}\n";
        }
    }

    close $resIn;
    return $lang;
}


sub _parseFixedFileInfo {
    my ($self, $rsrcEntry, $resIn, $header) = @_;

    read $resIn, (my $key),  26;    # remainder of key
    read $resIn, (my $data), 4;     # null terminator and padding
    $header->{type} = $header->{type} . Encode::decode('UTF-16LE', $key);

    #struct VS_FIXEDFILEINFO {
    #  DWORD dwSignature;
    #  DWORD dwStrucVersion;
    #  DWORD dwFileVersionMS;
    #  DWORD dwFileVersionLS;
    #  DWORD dwProductVersionMS;
    #  DWORD dwProductVersionLS;
    #  DWORD dwFileFlagsMask;
    #  DWORD dwFileFlags;
    #  DWORD dwFileOS;
    #  DWORD dwFileType;
    #  DWORD dwFileSubtype;
    #  DWORD dwFileDateMS;
    #  DWORD dwFileDateLS;
    #};
    my %fixedFileInfo;

    read $resIn, $data, 52;
    @fixedFileInfo{
        qw(
            dwSignature dwStrucVersion dwFileVersionMS dwFileVersionLS
            dwProductVersionMS dwProductVersionLS dwFileFlagsMask dwFileFlags
            dwFileOS dwFileType dwFileSubtype dwFileDateMS dwFileDateLS
            )
        }
        = unpack ('V13', $data);
    die "Beyond eof in _parseFixedFileInfo\n" if eof $resIn;
    seek $resIn, (tell $resIn) % 4, 1;    # Skip padding bytes

    $rsrcEntry->{FixedFileInfo} = \%fixedFileInfo;
}


sub _parseStringFileInfo {
    my ($self, $rsrcEntry, $resIn, $header) = @_;

    read $resIn, (my $key), 24;           # remainder of key
    $header->{type} = $header->{type} . Encode::decode('UTF-16LE', $key);

    my %stringFileInfo;

    #struct StringFileInfo {
    #  WORD        wLength;
    #  WORD        wValueLength;
    #  WORD        wType;
    #  WCHAR       szKey[]; // "StringFileInfo"
    #  WORD        Padding[];
    #  StringTable Children[];
    #};

    my $padding = (tell $resIn) % 4;
    die "Beyond eof in _parseStringFileInfo\n" if eof $resIn;
    seek $resIn, $padding, 1;    # Skip padding bytes following key

    # Read the entire string file info record
    my $pos = tell $resIn;
    read $resIn, (my $strTables), $header->{length} - 34 - $padding;
    die "Beyond eof in _parseStringFileInfo\n" if eof $resIn;
    seek $resIn, (tell $resIn) % 4, 1;    # Skip record end padding bytes
    open my $strTblIn, '<', \$strTables;
    binmode $strTblIn;

    while (read $strTblIn, (my $hdrData), 6) {

        #struct StringTable {
        #  WORD   wLength;
        #  WORD   wValueLength;
        #  WORD   wType;
        #  WCHAR  szKey[]; // 8 character Unicode string
        #  WORD   Padding[];
        #  String Children[];
        #};

        my %strTblHdr;

        @strTblHdr{qw(length valueLength isText)} = unpack ('vvv', $hdrData);
        read $strTblIn, $strTblHdr{langCP}, 16;
        $strTblHdr{langCP} = Encode::decode('UTF-16LE', $strTblHdr{langCP});
        die "Beyond eof in _parseStringFileInfo\n" if eof $strTblIn;
        seek $strTblIn, (tell $strTblIn) % 4, 1;    # Skip padding bytes
        read $strTblIn, (my $stringsData), $strTblHdr{length} - tell $strTblIn;
        open my $stringsIn, '<', \$stringsData;
        binmode $stringsIn;

        while (read $stringsIn, (my $strData), 6) {

            #struct String {
            #  WORD   wLength;
            #  WORD   wValueLength;
            #  WORD   wType;
            #  WCHAR  szKey[];
            #  WORD   Padding[];
            #  WORD   Value[];
            #};

            my %strHdr;

            @strHdr{qw(length valueLength isText)} = unpack ('vvv', $strData);
            read $stringsIn, $strData, $strHdr{length} - 6;
            $strData = Encode::decode('UTF-16LE', $strData);
            $strData =~ s/\x00\x00+/\x00/g;
            my ($name, $str) = split "\x00", $strData;
            $stringFileInfo{$name} = $str;
            # Skip padding bytes
            seek $stringsIn, (tell $stringsIn) % 4, 1 if !eof $stringsIn;
        }
    }

    $rsrcEntry->{StringFileInfo} = \%stringFileInfo;
}


sub _parseVarFileInfo {
    my ($self, $rsrcEntry, $resIn, $header) = @_;

    read $resIn, (my $key), 20;    # remainder of key
    $header->{type} = $header->{type} . Encode::decode('UTF-16LE', $key);

    my %varFileInfo;

    #struct VarFileInfo {
    #  WORD  wLength;
    #  WORD  wValueLength;
    #  WORD  wType;
    #  WCHAR szKey[]; // "VarFileInfo"
    #  WORD  Padding[];
    #  Var   Children[];
    #};

    my $padding = (tell $resIn) % 4;
    die "Beyond eof in _parseVarFileInfo\n" if eof $resIn;
    seek $resIn, $padding, 1;    # Skip padding bytes following key

    # Read the entire var file info record
    my $pos = tell $resIn;
    read $resIn, (my $varData), $header->{length} - 28 - $padding;
    # Skip record end padding bytes
    seek $resIn, (tell $resIn) % 4, 1 if !eof $resIn;
    open my $varIn, '<', \$varData;
    binmode $varIn;

    while (read $varIn, (my $hdrData), 6) {

        my %varHdr;

        #struct Var {
        #  WORD  wLength;
        #  WORD  wValueLength;
        #  WORD  wType;
        #  WCHAR szKey[];
        #  WORD  Padding[];
        #  DWORD Value[];
        #};

        @varHdr{qw(length valueLength isText)} = unpack ('vvv', $hdrData);
        read $varIn, $varHdr{key}, 22;
        $varHdr{key} = Encode::decode('UTF-16LE', $varHdr{key});
        my $hPadding = (tell $varIn) % 4;
        # Skip padding bytes following key
        seek $varIn, $hPadding, 1 if !eof $varIn;
        read $varIn, (my $value), $varHdr{length} - 28 - $hPadding;
        @{$varFileInfo{langCPIds}} = unpack ('V*', $value);
    }

    $rsrcEntry->{VarFileInfo} = \%varFileInfo;
}


sub _assemble_rsrc {
    my ($self) = @_;

    return 1 if !exists $self->{SecData}{'.rsrc'}{added};
    die "'" . ref ($self) . "'->_assemble not implemented\n";
}


sub _buildResourceEntry {
    my ($self, %params) = @_;
    my $root  = $params{-root};
    my $path  = $params{-path};
    my $entry = $root;

    Carp::croak "-root and -path parameters required in _buildResourceEntry"
        if !ref $root || !ref $path;

    $entry = $entry->{$_} ||= {} for grep {defined} @$path;
    $entry->{sectData}     = $params{data};
    $entry->{sectCodepage} = $params{codepage} || 0;
    $entry->{sectOffset}   = undef;
    return $entry;
}


sub _buildVersionInfo {
    my ($self, %params) = @_;
    my $fixed  = $self->_buildVS_FIXEDFILEINFO(%params);
    my $string = $self->_buildStringFileInfo(%params);
    my $var    = $self->_buildVarFileInfo(%params);
    my $tail   = Encode::encode('UTF-16LE', 'StringFileInfo');

    $tail .= "\0\0" if 3 & length $tail;

    for my $entry ($fixed, $var, $string) {
        next if !defined $entry;

        $tail .= $entry;
    }

    return pack ('vvv', 6 + length $tail, length $fixed, 1) . $tail;
}


sub _buildVS_FIXEDFILEINFO {
    my ($self, %params) = @_;
    my $vData = Encode::encode('UTF-16LE', 'VS_VERSION_INFO');
    my @items;

    push @items, 0xFEEF04BD;                            # Signature
    push @items, $params{StrucVersion} ||= 65536;       # 1.0
    push @items, $params{FileVersionMS} ||= 65536;      # 1.0
    push @items, $params{FileVersionLS} ||= 0;
    push @items, $params{ProductVersionMS} ||= 65536;
    push @items, $params{ProductVersionLS} ||= 0;
    push @items, $params{FileFlagsMask} ||= 0;
    push @items, $params{FileFlags} ||= 0;
    push @items, $params{FileOS} ||= 4;
    push @items, $params{FileType} ||= 2;
    push @items, $params{FileSubtype} ||= 0;
    push @items, $params{FileDateMS} ||= 0;
    push @items, $params{FileDateLS} ||= 0;

    $_ ||= 0 for @items;

    $vData .= ("\0") x 4;             # null terminator and padding
    $vData .= pack ('V13', @items);

    return {size => length $vData, data => $vData};
}


sub _buildStringFileInfo {
    my ($self, %params) = @_;
    my $tail = Encode::encode('UTF-16LE', 'StringFileInfo');

    $tail .= "\0\0" if 3 & length $tail;
    $tail .= $self->_buildStringTable(%params);

    return pack ('vvv', 6 + length $tail, 0, 1) . $tail;
}


sub _buildStringTable {
    my ($self, %params) = @_;

    Carp::confess "lang parameter required in _buildStringTable"
        if !exists $params{lang};

    my $vData = Encode::encode('UTF-16LE', sprintf '%4x%4x',
        $params{lang}, ($params{codePage} ||= 1200));
    my @strings;

    $params{strings}{ProductVersion}   ||= '1.0';
    $params{strings}{FileVersion}      ||= '1.0';
    $params{strings}{OriginalFilename} ||= $self->{-file};
    $params{strings}{InternalName}     ||= $self->{-file};

    while (my @keyValue = each %{$params{strings}}) {
        push @strings, $self->_buildString(@keyValue);
    }

    $vData .= "\0\0" if 3 & (6 + length $vData);
    $vData .= join '', @strings;
    return pack ('vvv', 6 + length $vData, 0, 1) . $vData;
}


sub _buildString {
    my ($self, $key, $value) = @_;

    $value = '' if !defined $value;
    # Calculate length
    my $len = 6 + 2 * length ($key) + 2;    # header + len + null
    my $padding1 = $len & 3 ? 2 : 0;

    $len += 2 if $len & 3;
    $len += 2 * length ($value) + 2;

    my $padding2 = $len & 3 ? 2 : 0;

    # Generate record
    my $tail = pack ('vvv', $len + $padding2, $len, 1);

    $tail .= Encode::encode('UTF-16LE', $key) . "\0\0";
    $tail .= "\0\0" if $padding1;
    $tail .= Encode::encode('UTF-16LE', $value) . "\0\0";
    $tail .= "\0\0" if $padding2;

    return $tail;
}


sub _buildVarFileInfo {
    my ($self, %params) = @_;

    return if !exists $params{langCPIds};

    Carp::croak "VarFileInfo not currently supported for VERSION resources";

    my $vData = Encode::encode('UTF-16LE', 'VarFileInfo');
    my @items;

    $vData .= ("\0") x 4;    # null terminator and padding

    return {size => length $vData, data => $vData};
}


sub _calcSize_rsrc {
    my ($self, $sectionStart) = @_;

    return if !exists $self->{SecData}{'.edata'};

    if (exists $self->{SecData}{'.edata'}{added}) {
        die "'" . ref ($self) . "'->_calcSize_edata not implemented\n";
    }

    return $self->{DataDir}{'.edata'}{size};
    #my $rsrcData = __PACKAGE__->__new();
    #
    #$self->_getResourceData($self->{SecData}{'.rsrc'}{Entries}, $rsrcData);
    #$self->{DataDir}{'.rsrc'}{rawData} = $rsrcData->__rawData($sectionStart);
    #$self->{DataDir}{'.rsrc'}{size}    = $rsrcData->__length();
    #return $self->{DataDir}{'.rsrc'}{size};
}


sub _getResourceData {
    my ($self, $root, $rsrcData, $level) = @_;
    my @nameEntries = grep {/\D/} sort keys %$root;
    my @iDEntries   = grep {!/\D/} sort keys %$root;

    $rsrcData->__addTable(time, 0 + @nameEntries, 0 + @iDEntries);

    for my $nameEntry (@nameEntries) {
        $rsrcData->__addResDirNameEntry($nameEntry);
    }

    for my $idEntry (@iDEntries) {
        $rsrcData->__addResDirIdEntry($idEntry);
    }

    return $self->{SecData}{'.rsrc'}{secData};
}


sub _getData {
    my ($self) = @_;

    return $self->_getRsrcData();
}


sub __new {
    my ($class, %params) = @_;

    return bless \%params, $class;
}


sub __rawData {
    my ($self, $sectionStart) = @_;

    return $self->{rawData};
}


sub __addTable {
    my ($self, $timeDate, $numNameEntries, $numIdEntries) = @_;

    $self->{tableData} .=
        pack ('VVvvvv', 0, $timeDate, 0, 0, $numNameEntries, $numIdEntries);
    push @{$self->{tablesEntries}}, [$numNameEntries, $numIdEntries];
}


sub __addResDirNameEntry {
    my ($self, $nameOrID) = @_;
    my $isName = $nameOrID =~ /\D/;

}


sub __length {
    my ($self) = @_;

    return length $self->{rawData};
}


package Win32::PEFile::edataHandler;

use Win32::PEFile::PEConstants;

push @Win32::PEFile::edataHandler::ISA, 'Win32::PEFile::SectionHandlers';
Win32::PEFile::edataHandler->register('.edata',
    qw'getEntryPoint getExportNames getExportOrdinalsCount haveExportEntry');


sub uiName {
    return 'Exports';
}


sub getExportNames {
    my ($self) = @_;

    return if !exists $self->{DataDir}{'.edata'};

    $self->_parse_edata() if !exists $self->{SecData}{'.edata'}{Entries};
    return keys %{$self->{SecData}{'.edata'}{Entries}};
}


sub getExportOrdinalsCount {
    my ($self) = @_;

    return if !exists $self->{DataDir}{'.edata'};

    $self->_parse_edata() if !exists $self->{SecData}{'.edata'}{Entries};
    return keys %{$self->{SecData}{'.edata'}{Entries}};
}


sub getEntryPoint {
    my ($self, $entryPointName) = @_;

    return $self->haveExportEntry($entryPointName);
}


sub haveExportEntry {
    my ($self, $entryPointName) = @_;

    return if !exists $self->{DataDir}{'.edata'};
    return exists $self->{SecData}{'.edata'}{Entries}{$entryPointName}
        if exists $self->{SecData}{'.edata'}{Entries};

    $self->_parse_edata();
    return exists $self->{SecData}{'.edata'}{Entries}{$entryPointName};
}


sub _parse_edata {
    my ($self) = @_;
    my $edataHdr = $self->{DataDir}{'.edata'};

    open my $peFile, '<', $self->{'-file'}
        or die "unable to open file - $!\n";
    binmode $peFile;
    seek $peFile, $edataHdr->{filePos}, 0;
    read $peFile, (my $eData), $edataHdr->{size};

    my %dirTable;

    @dirTable{
        qw(
            Flags Timestamp VerMaj VerMin NameRVA Base ATEntries Names
            ExportTabRVA NameTabRVA OrdTabRVA
            )
        }
        = unpack ('VVvvVVVVVVV', $eData);
    $self->{SecData}{'.edata'}{dirTable} = \%dirTable;

    my $nameTableFileAddr = $dirTable{NameTabRVA} - $edataHdr->{fileBias};

    seek $peFile, $nameTableFileAddr, 0;
    read $peFile, (my $nameData), $dirTable{Names} * 4;

    for my $index (0 .. $dirTable{Names} - 1) {
        my $addr = unpack ('V', substr $nameData, $index * 4, 4);

        next if !$addr;

        my $epName =
            $self->_readNameStr($peFile, $addr - $edataHdr->{fileBias});

        $self->{SecData}{'.edata'}{Entries}{$epName} = $index;
    }

    close $peFile;
}


sub _assemble_edata {
    my ($self) = @_;

    return 1 if !exists $self->{SecData}{'.edata'}{added};
    die "'" . ref ($self) . "'->_assemble_edata not implemented\n";
}


sub _calcSize_edata {
    my ($self, $sectionStart) = @_;

    return if !exists $self->{SecData}{'.edata'};

    if (exists $self->{SecData}{'.edata'}{added}) {
        die "'" . ref ($self) . "'->_calcSize_edata not implemented\n";
    }

    return $self->{DataDir}{'.edata'}{size};
}


package Win32::PEFile::idataHandler;

use Win32::PEFile::PEConstants;

push @Win32::PEFile::idataHandler::ISA, 'Win32::PEFile::SectionHandlers';
Win32::PEFile::idataHandler->register('.idata',
    qw'getImportNames getImportNamesArray haveImportEntry');


sub uiName {
    return 'Imports';
}


sub getImportNames {
    my ($self) = @_;
    my %dlls;

    return if !exists $self->{DataDir}{'.idata'};

    $self->_parse_idata() if !exists $self->{SecData}{'.idata'};

    my $entries = $self->{SecData}{'.idata'}{Entries};

    for my $dllName (keys %$entries) {
        my $entry = $entries->{$dllName};
        $dlls{$dllName} = [@{$entry->{_entries}}];
    }

    return %dlls;
}


sub getImportNamesArray {
    my ($self) = @_;
    my %dlls;

    return if !exists $self->{DataDir}{'.idata'};

    $self->_parse_idata() if !exists $self->{SecData}{'.idata'};

    my $entries = $self->{SecData}{'.idata'}{Entries};

    for my $dllName (keys %$entries) {
        my $entry = $entries->{$dllName};
        $dlls{$dllName} = [@{$entry->{_entries}}];
    }

    return @{$self->{SecData}{'.idata'}{ByName}};
}


sub haveImportEntry {
    my ($self, $entryPath) = @_;

    return if !exists $self->{DataDir}{'.idata'};

    $self->_parse_idata() if !exists $self->{SecData}{'.idata'};
    return if !exists $self->{SecData}{'.idata'};

    my ($dll, $routine) = split '/', $entryPath;

    return if !exists $self->{SecData}{'.idata'}{Entries}{$dll};
    return !!grep {$routine eq $_}
        @{$self->{SecData}{'.idata'}{Entries}{$dll}{_entries}};
}


sub _parse_idata {
    my ($self) = @_;
    my $idataHdr = $self->{DataDir}{'.idata'};
    
    return if ! exists $idataHdr->{filePos};

    open my $peFile, '<', $self->{'-file'}
        or die "unable to open file - $!\n";
    binmode $peFile;
    seek $peFile, $idataHdr->{filePos}, 0;
    read $peFile, (my $idata), $idataHdr->{size};

    my @dirTable;
    my @nameArray;

    $self->{SecData}{'.idata'}{dirTable} = \@dirTable;
    open my $dirFile, '<', \$idata;
    binmode $dirFile;

    while (1) {
        my %dirEntry;

        read $dirFile, (my $entryData), 20 or last;
        @dirEntry{
            qw(ImportLUTableRVA TimeDate ForwarderChain dllNameRVA ThunkTableRVA)
        } = unpack ('VVVVV', $entryData);

        last if !$dirEntry{dllNameRVA};

        my $dllNameFileAddr = $dirEntry{dllNameRVA} - $idataHdr->{fileBias};
        my $dllName         = $self->_readNameStr($peFile, $dllNameFileAddr);
        my $entries         = $self->{SecData}{'.idata'}{Entries} ||= {};

        push @nameArray, $dllName;
        $entries->{$dllName} = \%dirEntry;
        $entries->{$dllName}{_entries} =
            $self->_parseImportLUTable($peFile, $dllName);
    }

    $self->{SecData}{'.idata'}{ByName} = \@nameArray;
    close $peFile;
}


sub _parseImportLUTable {
    my ($self, $peFile, $dllName) = @_;
    my $oldPos   = tell $peFile;
    my $dirEntry = $self->{SecData}{'.idata'}{Entries}{$dllName} ||= {};
    my $idataHdr = $self->{DataDir}{'.idata'};
    my $luAddr   = $dirEntry->{ImportLUTableRVA} - $idataHdr->{fileBias};
    my $isPEPlus = $self->{is32Plus};
    my @entries;

    seek $peFile, $luAddr, 0;

    while (1) {
        read $peFile, my $lutEntry, ($isPEPlus ? 8 : 4);

        my $index;
        my $isOrdinal;

        if ($isPEPlus) {
            ($index, $isOrdinal) = unpack ('VV', $lutEntry);
        } else {
            $index = unpack ('V', $lutEntry);
            $isOrdinal = $index & 0x80000000;
            $index &= ~0x80000000;
        }

        last if !$index && !$isOrdinal;

        if ($isOrdinal) {
            push @entries, $index;
            next;
        }

        my $hintAddr = $index - $idataHdr->{fileBias};
        my $oldPos   = tell $peFile;

        seek $peFile, $hintAddr, 0;
        read $peFile, my $hint, 2;
        $hint = unpack ('v', $hint);

        my $entryName = $self->_readNameStr($peFile);

        push @entries, $entryName;
        seek $peFile, $oldPos, 0;
    }

    seek $peFile, $oldPos, 0;
    return \@entries;
}


sub _assemble_idata {
    my ($self) = @_;

    return 1 if !exists $self->{SecData}{'.idata'}{added};
    die "'" . ref ($self) . "'->_assemble_idata not implemented\n";
}


sub _calcSize_idata {
    my ($self, $sectionStart) = @_;

    return if !exists $self->{SecData}{'.idata'};

    if (exists $self->{SecData}{'.idata'}{added}) {
        die "'" . ref ($self) . "'->_calcSize_idata not implemented\n";
    }

    return $self->{DataDir}{'.idata'}{size};
}


package Win32::PEFile::certHandler;

use Win32::PEFile::PEConstants;

push @Win32::PEFile::certHandler::ISA, 'Win32::PEFile::SectionHandlers';
Win32::PEFile::certHandler->register('certTable',
    qw'addCertificate getCertificate');


sub uiName {
    return 'Certificate';
}


sub addCertificate {
    my ($self) = @_;

}


sub getCertificate {
    my ($self) = @_;

}


sub _parse_cert {
    my ($self, $sectionStart) = @_;

    die "'" . ref ($self) . "'->_parse_cert not implemented\n";
}


sub _assemble_cert {
    my ($self) = @_;

    return 1 if !exists $self->{SecData}{certTable}{added};
    die "'" . ref ($self) . "'->_assemble_cert not implemented\n";
}


sub _calcSize_cert {
    my ($self, $sectionStart) = @_;

    return if !exists $self->{SecData}{certTable};

    if (exists $self->{SecData}{certTable}{added}) {
        die "'" . ref ($self) . "'->_calcSize_cert not implemented\n";
    }

    return $self->{DataDir}{certTable}{size};
}


1;

=head1 NAME

Win32::PEFile::SectionHandlers - PEFile section handlers

=head1 OVERVIEW

A PEFile contains a number of sections that provide the "interesting"
information and data in the file. This module provides code to handle various
section types. C<Win32::PEFile::SectionHandlers> is a base class that provides
common construction code and hooks the derived section handler classes into the
PEFile parser. This allows entry points provided by section handlers to be made
available from PEFile objects as object methods.

Section handlers call Win32::PEFile::SectionHandlers::register() passing their
class, section tag ('.rsrc' for example) and the list of public methods
provided by the section handler.

Win32::PEFile uses AUTOLOAD to hook up section handlers to the Win32::PEFile
class on demand.

=cut
