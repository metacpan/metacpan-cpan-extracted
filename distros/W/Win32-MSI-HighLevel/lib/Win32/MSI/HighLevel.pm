package Win32::MSI::HighLevel;

use strict;
use warnings;

require 5.007003;    # for Digest::MD5


BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}

$Win32::MSI::HighLevel::VERSION = '1.0008';

use Carp;
use Cwd;
use File::Spec;
use Win32;
use Win32::API;
use Win32::MSI::HighLevel::Common qw(
    kMSIDBOPEN_READONLY kMSIDBOPEN_TRANSACT kMSIDBOPEN_DIRECT kMSIDBOPEN_CREATE
    );
use Win32::MSI::HighLevel::Handle;
use Win32::MSI::HighLevel::View;
use Win32::MSI::HighLevel::Record;
use Win32::MSI::HighLevel::ErrorTable;
use base qw(Win32::MSI::HighLevel::Handle Exporter);

use constant kReportUpdates => 1;

our @EXPORT_OK = qw(
    kMSIDBOPEN_READONLY kMSIDBOPEN_TRANSACT kMSIDBOPEN_DIRECT kMSIDBOPEN_CREATE

    k_MSICOLINFO_INDEX

    kMSITR_IGNORE_ADDEXISTINGROW kMSITR_IGNORE_DELMISSINGROW
    kMSITR_IGNORE_ADDEXISTINGTABLE kMSITR_IGNORE_DELMISSINGTABLE
    kMSITR_IGNORE_UPDATEMISSINGROW kMSITR_IGNORE_CHANGECODEPAGE
    kMSITR_VIEWTRANSFORM

    kMSITR_IGNORE_ALL

    msidbRegistryRootClassesRoot msidbRegistryRootCurrentUser
    msidbRegistryRootLocalMachine msidbRegistryRootUsers

    msidbLocatorTypeDirectory msidbLocatorTypeFileName
    msidbLocatorTypeRawValue msidbLocatorType64bit

    msidbUpgradeAttributesMigrateFeatures
    msidbUpgradeAttributesOnlyDetect
    msidbUpgradeAttributesIgnoreRemoveFailure
    msidbUpgradeAttributesVersionMinInclusive
    msidbUpgradeAttributesVersionMaxInclusive
    msidbUpgradeAttributesLanguagesExclusive

    msidbComponentAttributesLocalOnly
    msidbComponentAttributesSourceOnly
    msidbComponentAttributesOptional
    msidbComponentAttributesRegistryKeyPath
    msidbComponentAttributesSharedDllRefCount
    msidbComponentAttributesPermanent
    msidbComponentAttributesODBCDataSource
    msidbComponentAttributesTransitive
    msidbComponentAttributesNeverOverwrite
    msidbComponentAttributes64bit

    SW_SHOWNORMAL
    SW_SHOWMAXIMIZED
    SW_SHOWMINNOACTIVE

    kReportUpdates
    );

=head1 NAME

Win32::MSI::HighLevel - Perl wrapper for Windows Installer API

=head1 VERSION

Version 1.0008

=head1 SYNOPSIS

    use Win32::MSI::HighLevel;

    my $filename = 'demo.msi';

    unlink $filename;
    my $msi = HighLevel->new (-file => $filename, -mode => Win32::MSI::HighLevel::Common::kMSIDBOPEN_CREATE);

    $msi->addFeature (
        -Feature => 'Complete',
        -Title => 'Full install', -Description => 'Install the whole ball of wax'
        );

    $msi->createTable (
        -table => 'Feature',
        -columnSpec => [
            Feature  => ['Key', 'Identifier'], Feature_Parent => 'Identifier',
            Title => 'Text(64)', Description => 'Text(255)',
            Display => 'Integer', Level => 'Integer',
            Directory_ => 'Directory',
            Attributes => 'Integer',
            ]
        );

    $msi->writeTables ();
    $msi->commit ();
    $msi = 0;

=head1 DESCRIPTION

Win32::MSI::HighLevel allows the creation (and editing) of Microsoft's Windows
Installer technology based installer files (.msi files).

The initial impetus to create this module came from trying to find an automated
build system friendly way of creating Windows installers. This has been very
nicely achieved, especially as the core table information can be provided in
text based table description files and thus managed with a revision control
system.

Windows Installer files are simply database files. Almost all the information
required for an installer is managed in tables in the database. This module
facilitates manipulating the information in the tables.

=head2 Obtaining a database object

C<MSI::HighLevel::new ($filename, $mode)> returns a new database object. C<$mode>
may be one of:

=over 4

=item $Win32::MSI::MSIDBOPEN_READONLY

This doesn't really open the file read-only, but changes will not be
written to disk.

=item $Win32::MSI::MSIDBOPEN_TRANSACT

Open in transactional mode so that changes are written only on commit.
This is the default.

=item $Win32::MSI::MSIDBOPEN_DIRECT

Opens read/write without transactional behavior.

=item $Win32::MSI::MSIDBOPEN_CREATE

This creates a new database in transactional mode.

=back

=head2 HighLevel Methods

Generally sample usage is provided for each method followed by a description of
the method, then followed by any named parameters recognized by the method.

Most methods require named parameters. Named parameters with an uppercase first
letter map directly on to table columns. Named parameters with a lower case
first letter generally use contextual information to simplify using the method.

Table column names with a trailing _ are key columns for their table.

=cut


# Constants and other definitions

use constant msidbRegistryRootClassesRoot  => 0;
use constant msidbRegistryRootCurrentUser  => 1;
use constant msidbRegistryRootLocalMachine => 2;
use constant msidbRegistryRootUsers        => 3;

use constant msidbLocatorTypeDirectory => 0;
use constant msidbLocatorTypeFileName  => 1;
use constant msidbLocatorTypeRawValue  => 2;
use constant msidbLocatorType64bit     => 16;

use constant msidbUpgradeAttributesMigrateFeatures     => 1;
use constant msidbUpgradeAttributesOnlyDetect          => 2;
use constant msidbUpgradeAttributesIgnoreRemoveFailure => 4;
use constant msidbUpgradeAttributesVersionMinInclusive => 256;
use constant msidbUpgradeAttributesVersionMaxInclusive => 512;
use constant msidbUpgradeAttributesLanguagesExclusive  => 1024;

use constant msidbComponentAttributesLocalOnly         => 0x0000;
use constant msidbComponentAttributesSourceOnly        => 0x0001;
use constant msidbComponentAttributesOptional          => 0x0002;
use constant msidbComponentAttributesRegistryKeyPath   => 0x0004;
use constant msidbComponentAttributesSharedDllRefCount => 0x0008;
use constant msidbComponentAttributesPermanent         => 0x0010;
use constant msidbComponentAttributesODBCDataSource    => 0x0020;
use constant msidbComponentAttributesTransitive        => 0x0040;
use constant msidbComponentAttributesNeverOverwrite    => 0x0080;
use constant msidbComponentAttributes64bit             => 0x0100;

use constant SW_SHOWNORMAL      => 1;
use constant SW_SHOWMAXIMIZED   => 3;
use constant SW_SHOWMINNOACTIVE => 7;

my $MsiOpenDatabase =
    Win32::MSI::HighLevel::Common::_def(MsiOpenDatabase => "PPP");
my $MsiOpenDatabasePIP =
    Win32::MSI::HighLevel::Common::_def(MsiOpenDatabase => "PIP");
my $MsiDataBaseCommit =
    Win32::MSI::HighLevel::Common::_def(MsiDatabaseCommit => "I");
my $MsiDatabaseApplyTransform =
    Win32::MSI::HighLevel::Common::_def(MsiDatabaseApplyTransform => "IPI");
my $MsiGetLastErrorRecord =
    Win32::MSI::HighLevel::Common::_def(MsiGetLastErrorRecord => "");
my $MsiFormatRecord =
    Win32::MSI::HighLevel::Common::_def(MsiFormatRecord => "IIPP");
my $MsiRecordSetString =
    Win32::MSI::HighLevel::Common::_def(MsiRecordSetString => "IIP");
my $MsiRecordGetInteger =
    Win32::MSI::HighLevel::Common::_def(MsiRecordGetInteger => "II");
my $MsiDatabaseExport =
    Win32::MSI::HighLevel::Common::_def(MsiDatabaseExport => 'IPPP');
my $MsiDatabaseImport =
    Win32::MSI::HighLevel::Common::_def(MsiDatabaseImport => 'IPP');

my %systemFolders = (
    AdminToolsFolder => {
        -Directory_Parent => 'TARGETDIR',
        -DefaultDir       => '.:ADMINT~1|Admin Tools'
        },
    AppDataFolder => {
        -Directory_Parent => 'TARGETDIR',
        -DefaultDir       => '.:Applic~1|Application Data'
        },
    CommonAppDataFolder => {
        -Directory_Parent => 'TARGETDIR',
        -DefaultDir       => '.:APPLIC~1|Application Data'
        },
    CommonFiles64Folder => {
        -Directory_Parent => 'TARGETDIR',
        -DefaultDir       => '.:Common~1|Common Files',
        },
    CommonFilesFolder => {
        -Directory_Parent => 'TARGETDIR',
        -DefaultDir       => '.:Common~1|Common Files'
        },
    DesktopFolder =>
        {-Directory_Parent => 'TARGETDIR', -DefaultDir => '.:Desktop'},
    FavoritesFolder => {
        -Directory_Parent => 'TARGETDIR',
        -DefaultDir       => '.:Favori~1|Favorites'
        },
    FontsFolder => {-Directory_Parent => 'TARGETDIR', -DefaultDir => '.:Fonts'},
    LocalAppDataFolder => {
        -Directory_Parent => 'TARGETDIR',
        -DefaultDir       => '.:APPLIC~1|Application Data'
        },
    MyPicturesFolder => {
        -Directory_Parent => 'TARGETDIR',
        -DefaultDir       => '.:MYPICT~1|My Pictures'
        },
    PersonalFolder =>
        {-Directory_Parent => 'TARGETDIR', -DefaultDir => '.:Personal'},
    ProgramFiles64Folder => {
        -Directory_Parent => 'TARGETDIR',
        -DefaultDir       => '.:Progra~1|Program Files'
        },
    ProgramFilesFolder => {
        -Directory_Parent => 'TARGETDIR',
        -DefaultDir       => '.:Progra~1|Program Files'
        },
    ProgramMenuFolder =>
        {-Directory_Parent => 'TARGETDIR', -DefaultDir => '.:Programs'},
    SendToFolder =>
        {-Directory_Parent => 'TARGETDIR', -DefaultDir => '.:SendTo'},
    StartMenuFolder => {
        -Directory_Parent => 'TARGETDIR',
        -DefaultDir       => '.:StartM~1|Start Menu'
        },
    StartupFolder =>
        {-Directory_Parent => 'TARGETDIR', -DefaultDir => '.:Startup'},
    System16Folder =>
        {-Directory_Parent => 'TARGETDIR', -DefaultDir => '.:System'},
    System64Folder => {-Directory_Parent => 'TARGETDIR', -DefaultDir => ''},
    SystemFolder =>
        {-Directory_Parent => 'TARGETDIR', -DefaultDir => '.:System32'},
    TempFolder => {-Directory_Parent => 'TARGETDIR', -DefaultDir => '.:Temp'},
    TemplateFolder =>
        {-Directory_Parent => 'TARGETDIR', -DefaultDir => '.:ShellNew'},
    WindowsFolder =>
        {-Directory_Parent => 'TARGETDIR', -DefaultDir => '.:Windows'},
    WindowsVolume => {-Directory_Parent => '', -DefaultDir => ''},
    );


=head3 new

Create a new C<HighLevel> instance given a file and open mode.

    my $msi = HighLevel->new (-file => $file, -mode => Win32::MSI::HighLevel::Common::kMSIDBOPEN_DIRECT);

=over 4

=item I<-file>: required

the .msi file to open/create

=item I<-mode>: optional

parameter - the open/create mode. Defaults to C<Common::kMSIDBOPEN_TRANSACT>

Must be one of:

=over 4

=item Win32::MSI::HighLevel::Common::kMSIDBOPEN_READONLY

open for read only assess only

=item Win32::MSI::HighLevel::Common::kMSIDBOPEN_TRANSACT

open existing file for transacted access

=item Win32::MSI::HighLevel::Common::kMSIDBOPEN_DIRECT

open existing file for direct (non-transacted) access

=item Win32::MSI::HighLevel::Common::kMSIDBOPEN_CREATE

create a new file for transacted access (see L</commit> below)

=item Win32::MSI::HighLevel::Common::kMSIDBOPEN_CREATEDIRECT

create a new file for direct (non-transacted) access

=back

=item I<-sourceRoot>: optional

Provide the (absolute) source directory that corresponds to the TARGETDIR
directory on the target system. Directories on the target system have the same
relative path from TARGETDIR as directories on the source system have to the
source folder.

C<-sourceRoot> defaults to the cwd.

=item I<-targetRoot>: optional

Provide the default (absolute) target directory for the install. Note that the
actual location can be set at install time by the user.

=item I<-workRoot>: optional

Provide the path to a scratch location that can be used to create intermediate
files and folders during the installer build process.

=back

=cut

sub new {
    my ($type, %params) = @_;
    my $class = ref $type || $type;
    my $hdl = Win32::MSI::HighLevel::Handle->null();

    Win32::MSI::HighLevel::Common::require(\%params, qw(-file));
    Win32::MSI::HighLevel::Common::allow(\%params,
        qw(-file -mode -noisy -workRoot -sourceRoot -targetRoot));
    $params{-mode} ||= Win32::MSI::HighLevel::Common::kMSIDBOPEN_TRANSACT;
    $params{-file} = File::Spec->canonpath(File::Spec->rel2abs($params{-file}));

    $params{-workRoot} = $params{-sourceRoot} unless exists $params{-workRoot};

    if ($params{-mode} =~ /^\d+$/) {
        $params{result} =
            $MsiOpenDatabasePIP->Call($params{-file}, $params{-mode}, $hdl);
    } else {
        $params{result} =
            $MsiOpenDatabase->Call($params{-file}, $params{-mode}, $hdl);
    }

    croak "Failed to open database $params{-file} in $class constructor\n"
        . _errorMsg()
        . "\nCould it be open already?"
        if $params{result};

    $params{nextSeqNum}    = 1;
    $params{usedSeqNum}    = {};
    $params{highestSeqNum} = $params{nextSeqNum};

    $params{knownTables} = {
        AppSearch              => \&_addAppSearchRow,
        Binary                 => \&_addBinaryRow,
        Component              => \&_addComponentRow,
        Condition              => \&_addConditionRow,
        Control                => \&_addControlRow,
        ControlCondition       => \&_addControlConditionRow,
        ControlEvent           => \&_addControlEventRow,
        CreateFolder           => \&_addCreateFolderRow,
        CustomAction           => \&_addCustomActionRow,
        Dialog                 => \&_addDialogRow,
        Directory              => \&_addDirectoryRow,
        Feature                => \&_addFeatureRow,
        FeatureComponents      => \&_addFeatureComponentsRow,
        File                   => \&_addFileRow,
        Icon                   => \&_addIconRow,
        InstallExecuteSequence => \&_addInstallExecuteSequenceRow,
        InstallUISequence      => \&_addInstallUISequenceRow,
        Media                  => \&_addMediaRow,
        Property               => \&_addPropertyRow,
        Registry               => \&_addRegistryRow,
        RegLocator             => \&_addRegLocatorRow,
        Shortcut               => \&_addShortcutRow,
        Upgrade                => \&_addUpgradeRow,
        };

    $params{-noisy} ||= 0;
    $params{extraSep} = '-';

    return $class->SUPER::new($hdl, %params);
}


sub DESTROY {
    my $self = shift;

    $self->commit() if $self->{handle};
    $self->SUPER::DESTROY();
}


sub _errorMsg {
    my ($host) = @_;
    my $dbHdl = 0;

    if (!ref $host) {
        $dbHdl = $host if defined $host and $host =~ /^\d+$/;
    } elsif ($host->isa('Win32::MSI::HighLevel::Record')) {
        $dbHdl = $host->{view}{highLevel}{handle};
    } elsif ($host->isa('Win32::MSI::HighLevel::View')) {
        $dbHdl = $host->{highLevel}{handle};
    } elsif ($host->isa('Win32::MSI::HighLevel')) {
        $dbHdl = $host->{handle};
    }

    my $errRec = Win32::MSI::HighLevel::Record->fromHandle(
        $MsiGetLastErrorRecord->Call());

    return '' unless $errRec;

    my $errCode = $MsiRecordGetInteger->Call($errRec->{handle}, 1);
    my $msg     = '';
    my $length  = pack("l", 0);

    $MsiFormatRecord->Call(0, $errRec->{handle}, $msg, $length);
    $length = unpack("l", $length);
    unless ($length++) {
        $errCode = 0;
        return '';
    }

    my $size = $length * 2;    # length to UTF-16 siez

    $msg = "\0" x $size;
    return '' if $MsiFormatRecord->Call(0, $errRec->{handle}, $msg, $length);

    # Now UTF-8 encoded, trim to $length
    $msg = substr $msg, 0, $length;
    $msg =~ s/\0/\n/g;

    my %params = map {chomp; s/\s+$//; defined $_ ? $_ : ''}
        $msg =~ /(\d+):\s+(.*?)(?=\d+:|$)/g;

    return
        "see Microsoft Windows SDK documentation for 'Windows Installer Error Messages'. Params are: $msg"
        unless exists $params{1}
            and exists $Win32::MSI::HighLevel::ErrorTable::ErrMsgs{$params{1}};

    my $str = $Win32::MSI::HighLevel::ErrorTable::ErrMsgs{$params{1}};

    while ($str =~ /(?<!\[)\[(\d+)\](?!\])/) {
        my $index = $1;

        $str =~ s/(?<!\[)\[$index\](?!\])/$params{$index}/g;
    }

    return $str;
}


=head3 autovivifyTables

    $msi->autovivifyTables (qw(Components Dialog Feature Properties));

Ensure that a list of tables exist. Create any tables in the list that do not
exist already.

This should be called after L</populateTables> has been called if you are not
dealing with a new .msi file.

=cut

sub autovivifyTables {
    my ($self, @tables) = @_;

    for my $table (@tables) {
        next if exists $self->{tables}{$table} or _readonlyTable($table);

        $self->createTable(-table => $table);
    }
}


=head3 close

Close the database. Generally L</close> is not required to be called explicitly
as the database should close cleanly when the C<HighLevel> object is destroyed.

    $msi->close ();

=cut

sub close {
    my $self = shift;

    $self->DESTROY();
}


=head3 commit

L</commit> is used to update the database in transacted mode. Although the .msi
database API provides a commit which B<must> be called in transacted mode, there
doesn't seem to be anything like an explicit rollback! An implicit rollback
happens when the database is closed without a commit however.

    $msi->commit ();

=cut

sub commit {
    my ($self) = @_;

    $self->{result} = $MsiDataBaseCommit->Call($self->{handle});
    croak "MsiDataBaseCommit failed with error code $self->{result}"
        if $self->{result};

    return undef;
}


=head3 addAppSearch

Add an entry to the AppSearch table.

=over 4

=item I<-Property>: required

Property that is set by the AppSearch action when it finds a match for the
signature.

=item I<-Signature_>: required

An entry into the Signature table (for a file) or a directory name.

=back

=cut


sub addAppSearch {
    my ($self, %params) = @_;

    Win32::MSI::HighLevel::Common::require(\%params, qw(-Property -Signature_));
    Win32::MSI::HighLevel::Common::allow(\%params, qw(-Property -Signature_));

    $self->_addAppSearchRow(\%params);
}


=head3 addBinaryFile

Add a binary file to the installation.

=over 4

=item I<-Name>: required

Id to be used as the key entry in the binary file table. This entry must be
unique.

=item I<-file>: required

Path to the file to be added on the source system.

=back

=cut


sub addBinaryFile {
    my ($self, %params) = @_;

    Win32::MSI::HighLevel::Common::require(\%params, qw(-Name -file));
    Win32::MSI::HighLevel::Common::allow(\%params, qw(-Name -file));

    croak "File $params{-file} must exist during installer generation"
        unless -e $params{-file};

    $params{-Data} = $params{-file};
    $self->_addBinaryRow(\%params);
}


=head3 addCab

Adds a cabinet file the the Cabs table and updates the media table to match.

This routine is primarily used by createCabs and should not generally be
required by users.

=over 4

=item I<-name>: required

=item I<-file>: required

=item I<-disk>: required

=item I<-lastSeq>: required

=back

=cut

sub addCab {
    my ($self, %params) = @_;

    Win32::MSI::HighLevel::Common::require(\%params,
        qw(-name -file -disk -lastSeq));
    Win32::MSI::HighLevel::Common::allow(\%params,
        qw(-name -file -disk -lastSeq));

    $self->_addRow('Cabs', 'Name',
        {-Name => $params{-name}, -Data => $params{-file}},
        );

    $self->addMedia(
        -Cabinet      => "#Cabs.$params{-name}",
        -DiskId       => $params{-disk},
        -LastSequence => $params{-lastSeq}
        );
}


=head3 addComponent

L</addComponent> adds a component associated with a specific Directory table
entry and a group of files.

    my $newId = $msi->addComponent (-Directory_ => 'wibble', -features => ['Complete']);

=over 4

=item I<-Attributes>: optional

Component attribute flags ored together. Default value is 0 (no flags set).

=item I<-Condition>: optional

A condition that is used at install time to determine if the component should
be installed.

=item I<-Directory_>: required

Identifier for the directory entry associated with the component.

=item I<-features>: required

Array of Feature table Feature identifiers that the component is referenced by.

This parameter is required to generate appropriate entries in the
FeatureComponents table.

=item I<-File>: optional

Optional file name for the key file associated with the component.

If the directory is to be used in the CreateFolder table then the file name
should be omitted and the directory name will be used as the key for the
component.

=item I<-guidSeed>: optional

Provide an UpgradeCode guid so that a component installer can provide an
upgraded component for an product installed using a different installer.

The UpgradeCode guid must be the UprgadeCode guid used by the main product
installer.

I<-guidSeed> would normally be used with I<-requestedId>.

=item I<-KeyPath>: optional

Primary key into either the File, ODBCDataSource or Registry table. This is only
required for generating a component that installs registry entries and doesn't
install any files or directories.

Do not use -File and -KeyPath together.

=item I<-requestedId>: optional

Desired id for component. If there exists a component with the same Id already
then the suggested Id will be used as a base to generate a new Id.

=back

=cut

sub addComponent {
    my ($self, %params) = @_;
    my %cParams;

    Win32::MSI::HighLevel::Common::require(\%params, qw(-Directory_ -features));
    Win32::MSI::HighLevel::Common::allow(
        \%params,
        qw(-Attributes -Condition -Directory_ -features -File -KeyPath
            -requestedId -guidSeed
            )
            );
    my $compName;

    croak "setProduct must be called before a component is added"
        unless exists $self->{prodNamespace} || $self->_genProductCode();

    croak "Only one of -File and -KeyPath may be used"
        if exists $params{-File} && exists $params{-KeyPath};

    if (exists $params{-requestedId}) {
        $compName = $self->_getUniqueID($params{-requestedId}, "Component", 72);
    } elsif (exists $params{-File}) {
        $compName = $self->_getUniqueID($params{-File}, "Component", 72);
    } elsif (exists $systemFolders{$params{-Directory_}}) {
        croak
            "The system folder $params{-Directory_} may not be used as a Component!";
    } else {
        $compName = $self->_getUniqueID($params{-Directory_}, "Component", 72);
    }

    return $self->{tables}{Component}{lc $compName}{-Component}
        if exists $self->{tables}{Component}{lc $compName};

    my $guidSeed =
        exists $params{-guidSeed}
        ? $params{-guidSeed}
        : $self->getProperty('UpgradeCode');

    $cParams{-Component} = $compName;
    $cParams{-ComponentId} =
        Win32::MSI::HighLevel::Common::genGUID("$guidSeed:$compName");
    $cParams{-Directory_} = $params{-Directory_};

    $cParams{-Attributes} = $params{-Attributes};
    $cParams{-Attributes} ||= 0;
    $cParams{-Condition} = $params{-Condition};
    $cParams{-KeyPath} = $params{-KeyPath} if exists $params{-KeyPath};
    $cParams{-KeyPath} ||= exists $params{-File} && $params{-File};

    $cParams{state} = Win32::MSI::HighLevel::Record::kNew;
    $self->_addComponentRow(\%cParams);

    $self->addFeatureComponents(
        -Component_ => $compName,
        -features   => $params{-features}
        );

    $self->{_flags}{addedCreateFolder} = undef;
    if (!defined $cParams{-KeyPath} or !length $cParams{-KeyPath}) {
        _genLu(\%cParams, 'CreateFolder');

        if (!exists $self->{tables}{CreateFolder}{$cParams{-lu}}) {
            # Need to add a CreateFolder table entry
            my %cfParams = (
                -Directory_ => $params{-Directory_},
                -Component_ => $compName,
                );

            $self->{_flags}{addedCreateFolder} =
                $self->_addCreateFolderRow(\%cfParams);
        }
    }

    return $cParams{-Component};
}


=head3 addControlCondition

L</addControlCondition> adds an entry to the control condition table.

    $msi->addControlCondition (
        -Dialog_   => 'LicenseAgreementDlg',
        -Control_  => 'Install',
        -Action    => Disable,
        -Condition => 'IAgree <> "Yes"'
        );

=over 4

=item I<-Dialog_>: required

Id of the dialog containing the control.

=item I<-Control_>: required

Id of the control affected by the entry.

=item I<-Action>: required

Action to be taken if the condition is met.

=item I<-Condition>: required

Condition to be met for the action to be performed.

=back

=cut

sub addControlCondition {
    my ($self, %params) = @_;

    Win32::MSI::HighLevel::Common::require(\%params,
        qw(-Dialog_ -Control_ -Action -Condition));
    Win32::MSI::HighLevel::Common::allow(\%params,
        qw(-Dialog_ -Control_ -Action -Condition));

    return $self->_addControlConditionRow(\%params);
}


=head3 addCreateFolder

L</addCreateFolder> adds an entry to the create folder table for the given
folder. Component and directory table entries will be generated as required.

    my $entry = $msi->addCreateFolder (-folderPath => $dirPath);

=over 4

=item I<-folderPath>: required

Path name of the folder to create on the target system.

=item I<-features>: required

I<-features> provides an array reference for the list of feature ids for
features that install the component that creates the folder.

=back

=cut

sub addCreateFolder {
    my ($self, %params) = @_;

    Win32::MSI::HighLevel::Common::require(\%params, qw(-folderPath -features));
    Win32::MSI::HighLevel::Common::allow(\%params, qw(-folderPath -features));
    $self->{_flags}{addedCreateFolder} = undef;

    my %cfParams;

    $cfParams{-Directory_} = $self->getTargetDirID($params{-folderPath});
    $cfParams{-Component_} = $self->getComponentIdForDirId(
        -Directory => $cfParams{-Directory_},
        -features  => $params{-features}
        );

    return $self->{_flags}{addedCreateFolder}
        if defined $self->{_flags}{addedCreateFolder};

    _genLu(\%cfParams, 'CreateFolder');

    my $luKey = lc $cfParams{-lu};

    if (exists $self->{tables}{CreateFolder}{$luKey}) {
        return $self->{tables}{CreateFolder}{$luKey};
    }

    return $self->_addCreateFolderRow(\%cfParams);
}


=head3 addCustomAction

Add an entry to the custom action table.

    $msi->addCustomAction (
        -Action => 'InstallDriver',
        -Type   => 3074,
        -Source => 'DriverInstaller',
        -Target => "[CommonFilesFolder]\\$Manufacturer\\driver.inf",
        );

This provides fairly raw access to the CustomAction table and is only part of
the work required to set up a custom action. See the CustomAction
Table section in the documentation referenced in the L<See Also|/"SEE ALSO"> section for
further information.

=over 4

=item I<-Action>: required

Id for the custom action.

=item I<-Type>: required

A number comprised of various bit flags ored together.

=item I<-Source>: optional

A property name or external key into another table. This depends on the Type.

=item I<-Target>: optional

Additional information depending on the Type.

=back

=cut

sub addCustomAction {
    my ($self, %params) = @_;

    Win32::MSI::HighLevel::Common::require(\%params, qw(-Action -Type));
    Win32::MSI::HighLevel::Common::allow(\%params,
        qw(-Action -Type -Source -Target));

    return $self->_addCustomActionRow(\%params);
}


=head3 addCustomActionJScriptFragment

Add an inline JScript entry to the custom action table.

    $msi->addCustomActionJScriptFragment (
        -Action => 'GetName',
        -script => '["TheName"] = ["Path"].match (/".*\\(.*)/)[1]'
    );

This adds a JScript custom action row.

=over 4

=item I<-Action>: required

Id for the custom action.

=item I<-script>: required

The JScript to execute.

["..."] is expanded to Session.Property ("...")

The expanded string must be 255 characters or fewer. It may be
multiple statements and may contain multiple lines. Line breaks will be removed
however.

=back

=cut

sub addCustomActionJScriptFragment {
    my ($self, %params) = @_;

    Win32::MSI::HighLevel::Common::require(\%params, qw(-Action -script));
    Win32::MSI::HighLevel::Common::allow(\%params, qw(-Action -script));

    $params{-script} =~ s/\[("\w+")\]/Session.Property ($1)/g;
    $params{-script} =~ s/[\n\r]\s*//g;

    croak "JScript must be 255 characters or fewer!"
        unless length($params{-script}) < 256;
    $params{-Target} = $params{-script};
    $params{-Type}   = 37;

    return $self->_addCustomActionRow(\%params);
}


=head3 addCustomActionJScriptFile

Add JScript entry to the custom action table.

    $msi->addCustomActionJScriptFile (
       -Action => 'GetRegString',
       -call => '["AppRelVers"] = CmpVersion ("foo.exe", "1.0.3");'
       -file => 'vercheck.js',
       );

This adds a JScript custom action row.

=over 4

=item I<-Action>: required

Id for the custom action.

=item I<-call>: optional

A fragment (255 characters or fewer) of JScript to be executed after the
script has been loaded.

Watch out for \ characters in file paths. You will need \\\\ to get a single
\ in a quoted string by the time Perl has changed \\\\ to \\ then JScript
changes \\ to \.

-item I<-file>: required

Name of the file containing the script to be processed.

=back

=cut

sub addCustomActionJScriptFile {
    my ($self, %params) = @_;

    Win32::MSI::HighLevel::Common::require(\%params, qw(-Action -file));
    Win32::MSI::HighLevel::Common::allow(\%params, qw(-Action -call -file));

    (my $cleanFile = $params{-file}) =~ s/\W//g;
    my $key;

    $self->_haveUniqueId($cleanFile, 'CustomAction', 'Script', $key);
    $self->addBinaryFile(-Name => $key, -file => $params{-file})
        unless exists $self->{tables}{Binary}{$key};

    if (exists $params{-call}) {
        $params{-call} =~ s/\[("\w+")\]/Session.Property ($1)/g;
        $params{-call} =~ s/[\n\r]\s*//g;

        croak "JScript must be 255 characters or fewer!"
            unless length($params{-call}) < 256;
        $params{-Target} = $params{-call};
    }

    $params{-Type}   = 5;
    $params{-Source} = $key;
    return $self->_addCustomActionRow(\%params);
}


=head3 addCustomActionVBScriptFragment

Add an inline VBScript entry to the custom action table.

    $msi->addCustomActionVBScriptFragment (
        -Action => 'GetName',
        -script => '["TheName"] = ["Path"].match (/".*\\(.*)/)[1]'
    );

This adds a VBScript custom action row.

=over 4

=item I<-Action>: required

Id for the custom action.

=item I<-script>: required

The VBScript to execute.

["..."] is expanded to Session.Property ("...")

The expanded string must be 255 characters or fewer. It may be
multiple statements and may contain multiple lines. Line breaks will be removed
however.

=back

=cut

sub addCustomActionVBScriptFragment {
    my ($self, %params) = @_;

    Win32::MSI::HighLevel::Common::require(\%params, qw(-Action -script));
    Win32::MSI::HighLevel::Common::allow(\%params, qw(-Action -script));

    $params{-script} =~ s/\[("\w+")\]/Session.Property ($1)/g;
    $params{-script} =~ s/[\n\r]\s*//g;

    croak "VBScript must be 255 characters or fewer!"
        unless length($params{-script}) < 256;
    $params{-Target} = $params{-script};
    $params{-Type}   = 38;

    return $self->_addCustomActionRow(\%params);
}


=head3 addCustomActionVBScriptFile

Add VBScript entry to the custom action table.

    $msi->addCustomActionVBScriptFile (
       -Action => 'GetRegString',
       -call => '["AppRelVers"] = CmpVersion ("foo.exe", "1.0.3");'
       -file => 'vercheck.vbs',
       );

This adds a VBScript custom action row.

=over 4

=item I<-Action>: required

Id for the custom action.

=item I<-call>: optional

A fragment (255 characters or fewer) of VBScript to be executed after the
script has been loaded.

Watch out for \ characters in file paths. You will need \\\\ to get a single
\ in a quoted string by the time Perl has changed \\\\ to \\ then VBScript
changes \\ to \.

-item I<-file>: required

Name of the file containing the script to be processed.

=back

=cut

sub addCustomActionVBScriptFile {
    my ($self, %params) = @_;

    Win32::MSI::HighLevel::Common::require(\%params, qw(-Action -file));
    Win32::MSI::HighLevel::Common::allow(\%params, qw(-Action -call -file));

    (my $cleanFile = $params{-file}) =~ s/\W//g;
    my $key;

    $self->_haveUniqueId($cleanFile, 'CustomAction', 'Script', $key);
    $self->addBinaryFile(-Name => $key, -file => $params{-file})
        unless exists $self->{tables}{Binary}{$key};

    if (exists $params{-call}) {
        $params{-call} =~ s/\[("\w+")\]/Session.Property ($1)/g;
        $params{-call} =~ s/[\n\r]\s*//g;

        croak "VBScript must be 255 characters or fewer!"
            unless length($params{-call}) < 256;
        $params{-Target} = $params{-call};
    }

    $params{-Type}   = 6;
    $params{-Source} = $key;
    return $self->_addCustomActionRow(\%params);
}


=head3 addDirectory

L</addDirectory> adds a directory with a specified parent directory to the
directory table.

    my $entry = $msi->addDirectory (-Directory => $dir, -DefaultDir => $def, -Diretory_Parent => $parent);

=over 4

=item I<-Directory>: optional

Identifier for the directory entry to create. This identifier may be the name
of a property set to the full path of the target directory.

=item I<-Directory_Parent>: required

This must be a Directory table -Directory column entry or undef. If
-Diretory_Parent is undef or has the same value as -Directory the added entry is
for a root directory and the root directory name is specified by -DefaultDir.
There must only be one root directory in the Directory table.

Except in the case of a root directory entry, the value given for
-Diretory_Parent must already exist as a -Directory entry in the Directory
table.

=item I<-DefaultDir>: optional

-DefaultDir provides directory names for the source and target directories for
this table entry. -target and -source may be used instead of -DefaultDir.

Different target and source directory names may be provided separated by a
colon:

    [targetname]:[sourcename]

Directory names may be given as [shortName]|[longName] pairs. [longName] may not
include any of: \ ? | > < : / * "

[shortName] additionally may not include spaces or any of: + , ; = [ ]

A . may be used in place of [targetname] to indicate that the parent directory
should be used rather than specifying a subdirectory.

If none of -DefaultDir, -target and -source are provided, -DefaultDir is set to
'.' (use parent directory).

=item I<-target>: optional

The [targetname] part of -DefaultDir.

=item I<-source>: optional

=back

=cut

sub addDirectory {
    my ($self, %params) = @_;
    my $table = $self->{tables}{Directory} ||= {};

    Win32::MSI::HighLevel::Common::require(\%params, qw(-Directory_Parent));
    Win32::MSI::HighLevel::Common::allow(\%params,
        qw(-DefaultDir -Directory -Directory_Parent -target -source));

    croak "Root directory already supplied (only one allowed): $table->{_root}"
        if defined $table->{_root}
            and (!defined $params{-Directory_Parent}
                || $params{-Directory_Parent} eq $params{-Directory});

    my $defaultDir;

    if (exists $params{-DefaultDir}) {
        $defaultDir = $params{-DefaultDir};
    } else {
        $params{-target} ||= '';
        $params{-source} ||= '';
        $params{-target} = '.' if $params{-source} eq $params{-target};
        $params{-source} = '' unless length $params{-source};
        $defaultDir = $params{-target};
        $defaultDir .= ":$params{-source}" if length $params{-source};
    }

    $params{-DefaultDir} = $defaultDir;

    # Root is required. writeTables checks that a valid root was provided
    $table->{_root} ||= undef;

    unless (defined $params{-Directory_Parent}
        && $params{-Directory_Parent} ne $params{-Directory})
    {
        $params{-Directory}        ||= 'TARGETDIR';
        $params{-DefaultDir}       ||= 'SOURCEDIR';
        $params{-Directory_Parent} ||= '';
        $table->{_root} = $params{-Directory};
    }

    croak
        "A -Directory parameter is required when not providing the root directory ($defaultDir)"
        unless exists $params{-Directory} and defined $params{-Directory};

    croak
        "Parent directory ($params{-Directory_Parent}) must be provided before children"
        if length $params{-Directory_Parent}
            and !exists $table->{lc $params{-Directory_Parent}}
            and !exists $systemFolders{$params{-Directory_Parent}};

    return $self->_addDirectoryRow(\%params);
}

=head3 addDirPath

L</addDirPath> is not fully implemented should not be used. Use multiple calls
to L</addDirectory> instead.

=cut

#    my $root = $msi->addDirPath (-source => $rootDir, -target => $installDir);
#
#L</addDirPath> adds a directory tree rooted at C<-source> on the generating
#machine. C<-source> must exist in the source machine when L</addDirPath> is
#called.
#
#L</addDirPath> calls L</addDirectory> for each directory entry in
#the tree rooted at C<-source>.
#
#A hash is returned where the keys are the identifiers generated to identify
#each directory entry added to the table and the values are a hash containing two
#entries C<< (-dirName => directory name, -subdirs => {subdirectory hash}) >>. The
#keys must be used when required to identify the directories from other tables or
#in subsequent calls to c<addDirPath> that add further directories from the same
#context.
#
#Note that should not be used to create directories outside the install context.
#Instead use L</addCreateDirectory>.
#
#The following parameters are recognized by L</addDirPath>:
#
#=over 4
#
#=item I<-source>
#
#Root of the directory tree to be added from the generating machine. If neither a
#C<-rootParent> nor a C<-target> parameter is provided then C<-source> is assumed to be
#the root directory for the install and C<TARGETDIR> is provided as the parent
#directory (see Directory Table in the SDK documentation).
#
#=item I<-rootParent>
#
#Identifier for the parent directory for C<-source>. This must be provided if
#C<-source> is not the root of the install tree. Typically
#
#=item I<-target>
#
#Default install directory on the target system. This value may be altered by the
#user at install time if it is for the root directory.
#
#Using a C<.> as the target for a non-root directory means that the target is the
#parent directory rather than a subdirectory.
#
#If a long file name (or a file name containing characters not allowed in a short
#filename) is given, a short file name will be generated.
#
#=back
#
#=cut

sub addDirPath {
    my ($self, %params) = @_;
    my $dirs = $self->{tables}{Directory} ||= {};

    Win32::MSI::HighLevel::Common::require(\%params, qw(-target -source));
    Win32::MSI::HighLevel::Common::allow(\%params, qw(-target -source));

    croak "Implementation incomplete.";
}


=head3 addDrLocator

L</addDrLocator> adds a DrLocator table row. It is used with L<addAppSearch> and
L<addSignature> to provide the information needed by the AppSearch action.

=cut

sub addDrLocator {
    my ($self, %params) = @_;
    my $dirs = $self->{tables}{Directory} ||= {};

    Win32::MSI::HighLevel::Common::require(\%params, qw(-Signature_));
    Win32::MSI::HighLevel::Common::allow(\%params,
        qw(-Signature_ -Parent -Path -Depth));

    return $self->_addDrLocator(\%params);
}


=head3 addMsiDriverPackages

Adds a device driver package to the installer.

    $msi->addMsiDriverPackages (-Component => 'InstallDriver', -Flags  => (2 | 4));

=over 4

=item I<-Component>: required

Id for the custom action.

=item I<-Flags>: optional

A number comprised of various bit flags ored together.

See the I<MsiDriverPackages Custom Table Schema> topic in the I<Windows Driver
Kit: Device Installation> documentation for the use of this parameter. the
default value is 0.

=item I<-Sequence>: optional

Determines driver installation order. Packages are installed in increasing order
of sequence number. Packages with the same sequence value are installed in
arbitrary order.

=back

=cut

sub addMsiDriverPackages {
    my ($self, %params) = @_;

    Win32::MSI::HighLevel::Common::require(\%params, qw(-Component));
    Win32::MSI::HighLevel::Common::allow(\%params,
        qw(-Component -Flags -Sequence));

    croak "A valid component Id is required for addMsiDriverPackages"
        unless defined $params{-Component}
            and exists $self->{tables}{Component}{lc $params{-Component}};

    $params{-Flags}    ||= 0;
    $params{-Sequence} ||= 0;

    return $self->_addMsiDriverPackagesRow(\%params);
}


=head3 addFeature

Add an installation feature. Parent features must be added before child features
are added. Multiple root features are allowed and provide different installation
configurations.

    my $root = $msi->addFeature (-name => 'Complete', -Title => 'Full install');

The following parameters are recognized by L</addFeature>

=over 4

=item I<-Attributes>: optional

C<-Attributes> is set to msidbFeatureAttributesFavorLocal by default. For a
discussion of the C<-Attributes> parameter see the Feature Table documentation
(see L<See Also|/"SEE ALSO"> below).

=item I<-Description>: optional

A textual description of the feature shown in the text control of the selection
dialog.

=item I<-Directory_>: optional

Directory associated with the feature that may be configured by the user at
install time. The directory must already have been added with L</addDirectory>,
L</addDirPath> or L</createDirectory>.

=item I<-Display>: optional

Determines the display state and order of this feature in the feature list.

If C<-Display> is not provided it will be set so that the new feature is shown
after any previous features and is shown collapsed.

If C<-Display> is set to 0 it is not shown.

If C<-Display> is odd is is shown expanded. If C<-Display> is even it is shown
collapsed.

Display values must be unique.

=item I<-Feature_Parent>: optional

Identifier for the parent feature. If this parameter is missing a root feature
is generated.

=item I<-Level>: optional, default = 3

Initial installation level for the feature. See the Feature Table documentation
for a discussion of installation level (see L<See Also|/"SEE ALSO"> below). For a single
feature install a value of 3 (the default) is often used. 0 may be used for a
feature that is not to be installed at all.

=item I<-name>: required

The name of the feature to add.

=item I<-Title>: optional

The name of the feature to add.

=back

=cut

sub addFeature {
    my ($self, %params) = @_;
    my $table = $self->{tables}{Feature} ||= {};

    Win32::MSI::HighLevel::Common::require(\%params, qw(-name));
    Win32::MSI::HighLevel::Common::allow(
        \%params, qw(
            -Attributes -Description -Directory_ -Display -Feature_Parent -Level
            -name -Title
            )
            );

    $params{-Feature} ||= $self->_getUniqueID($params{-name}, 'Feature', 38);
    $params{-Level} ||= 3;

    if (!exists $params{-Display}) {
        my $next = exists $self->{usedDisplay} ? undef : 1;

        $next ||= (sort @{$self->{usedDisplay}})[-1] + 1;
        $params{-Display} = $next;
    }

    croak "Feature level must be in the range 0 - 32767"
        unless $params{-Level} >= 0 and $params{-Level} <= 32767;
    croak
        "Display order value must be unique or 0. $params{-Display} has been used."
        if $params{-Display}
            and grep {$_ == $params{-Display}} @{$self->{usedDisplay}};
    croak "Feature must be unique - $params{-Feature} has already been used"
        if exists $table->{lc $params{-Feature}};

    push @{$self->{usedDisplay}}, $params{-Display};

    # Root is required. writeTables checks that a valid root was provided
    $table->{_root} ||= undef;

    unless (defined $params{-Feature_Parent}) {
        $table->{_root} = $params{-Feature};
    }

    my $hashKey = lc $params{-Feature};

    $params{-Attributes} ||= 0;
    $params{-Display} ||= 1 unless defined $params{-Feature_Parent};

    return $self->_addFeatureRow(\%params);
}


=head3 addFeatureComponents

Add FeatureComponent rows for a given Component and each of a list of
Features.

    $msi->addFeatureComponents (-Component_ => 'Wibble', -features => ['Complete']);

I<addFeatureComponents> returns the number of rows actually added to the
FeatureComponents table. Duplicate rows will not be added, but are not an error.

=over 4

=item I<-Component_>: required

The Component table key id.

=item I<-features>: required

A reference to an array of Feature table key ids.

=back

=cut

sub addFeatureComponents {
    my ($self, %params) = @_;
    my $added;

    Win32::MSI::HighLevel::Common::require(\%params, qw(-Component_ -features));
    Win32::MSI::HighLevel::Common::allow(\%params, qw(-Component_ -features));

    for my $featureId (@{$params{-features}}) {
        my %fcParams;

        $fcParams{-Feature_}   = $featureId;
        $fcParams{-Component_} = $params{-Component_};
        _genLu(\%fcParams, qw(Component_ Feature_));
        next if exists $self->{tables}{FeatureComponents}{lc $fcParams{-lu}};

        ++$added, $self->_addFeatureComponentsRow(\%fcParams)
            unless exists $self->{lookup}{FeatureComponents}
            {lc "$params{-Component_}/$featureId"};
    }

    return $added;
}


=head3 addFile

L</addFile> is used to add a file to be installed. Adding a file associated with
a feature (or features) updates the File and DiskId tables and may update the
Component, FeatureComponent and DuplicateFile tables.

    my $file = $msi->addFile (-source => $filepath, -featureId => 'Complete');

Default values are determined for C<-Sequence> and C<-Version> from the source
file which must be available when L</addFile> is called.

=over 4

=item I<-cabFile>: optional

Provide the name of a cab file the current file should be added to. By default
the file is added to an internally generated cab file.

If the file is to not to be compressed and stored internally in a cab file
C<-cabFile> should be set to C<undef>.

See also L</createCabs>.

=item I<-condition>: optional

If provided the I<-condition> is applied to the component the file is installed
by. A new component will be created if the condition does not match the
condition on an existing component that would otherwise have been used.

=item I<-featureId>: required

Id of the Feature that the file is to be installed for.

=item I<-fileId>: optional

Id to be used as the File column (and thus key) entry for the file being added.
By default I<-fileName> is used for this value.

I<-fileId> must be unique. I<-skipDupAdd> will be ignored if I<-fileId> is
provided.

=item I<-fileName>: required

Name of the file to be installed. Note that a long file name should be given:
L</addFile> generates the required short file name.

=item I<-forceNewComponent>: optional

If present this parameter forces a new component to be generated. If the value
is scalar it is used as a suggested component name otherwise an array ref
containing a list of parameters to be passed to addComponent is expected.

If a parameter list is provided it may be empty and required parameters for
addComponent will be generated.

=item I<-isKey>: optional

File is a key file for a component. Required to be set true if there is to be a
shortcut to the file. If the file is a PE format file (.exe, .dll, ...)
C<-isKey> is implied.

=item I<-Language>: optional

Specify the language ID or IDs for the file. If more than one ID is appropriate
use a comma separated list.

If this parameter is omitted the value '1033' (US English) is used. To specify
that no ID should be used (for font files for example) use an empty string.

=item I<-requestedId>: optional

A suggested component name. If the name has been used and the file being
inserted is not suitable for the existing component a new component name based
on the requested name will be used.

=item I<-Sequence>: optional

Determines the order in which files are installed. By default files are
installed in the order that they are added. Setting C<-Sequence> for a file sets
the install position for that file and any files added subsequently.

If setting the sequence number for a file causes a collision with any file
already added the previously added files are moved later in the install sequence
(their sequence number is increased). Note that any subsequently added files may
also cause previously added files to be installed later. In other words, setting
C<-Sequence> for a file allows a group of files to be inserted at a particular
place in the install order.

Use:

    -Sequence => undef

to reset to adding files at the end of the install order.

=item I<-sourceDir>: required

Path to the directory containing the file to be installed.

=item I<-skipDupAdd>: optional

Skip adding the file if an entry already exists for it. This option is ignored
if I<-fileId> is provided.

=item I<-targetDir>: optional

Path to the directory the file is to be installed to on the target system.

If C<-targetDir> is not provided the target directory will be set to be in the
same relative location as the source directory is to the source root directory.
C<-sourceDir> must be in the directory tree below the source root directory if
C<-targetDir> is not provided.

=item I<-Version>: optional

C<-Version> should only be set to specify a companion file (see "Companion
Files" in the SDK documentation). For a versioned file the version number is
obtained from the file's version resource.

=back

=cut

sub addFile {
    my ($self, %params) = @_;
    my $table = $self->{tables}{File} ||= {};

    Win32::MSI::HighLevel::Common::require(\%params,
        qw(-featureId -sourceDir -fileName));
    Win32::MSI::HighLevel::Common::allow(
        \%params, qw(
            -condition
            -featureId -fileId -fileName -forceNewComponent -isKey -Language
            -requestedId -Sequence -skipDupAdd -sourceDir -targetDir -Version )
            );

    croak
        "Feature $params{-featureId} must be provided before a file ($params{-fileName}) is added for it"
        unless exists $self->{tables}{Feature}{lc $params{-featureId}};

    $self->createTable(-table => 'File') unless exists $self->{tables}{File};

    $params{-sourceDir} =~ s|\\\\$||;
    $params{-path} = "$params{-sourceDir}\\$params{-fileName}";
    $params{-path} = File::Spec->canonpath($params{-path});
    Win32::MSI::HighLevel::Common::croak(
        "Required file ($params{-path}) does not exist")
        unless -f $params{-path};

    $params{-sourceDirRel} =
        File::Spec->abs2rel($params{-sourceDir}, $self->{-sourceRoot});
    $params{-Version} = Win32::GetFileVersion($params{-path});
    if ($params{-skipDupAdd} and !exists $params{-fileId}) {
        my $luKey = lc "$params{-sourceDirRel}\\$params{-fileName}";

        return $self->{lookup}{filePath}{$luKey}
            if exists $self->{lookup}{filePath}{$luKey};
    }

    open my $testFile, '<:raw', $params{-path}
        or croak("Unable to open file $params{-path}: $!");

    my $header = '';
    read $testFile, $header, 256, 0;    # No test - doesn't matter if read fails

    my $isPE = $header =~ /^MZ/;
    if ($isPE) {
        my $peOffset = substr($header, 0x3c, 4);
        $peOffset = unpack('V', $peOffset);
        seek $testFile, $peOffset, 0;

        my $ok = read $testFile, $header, 2;
        $isPE = $ok and $header =~ /^PE/;
    }

    CORE::close $testFile;

    $params{-targetDir} = $params{-sourceDir} if !defined $params{-targetDir};

    $params{-directory_} = $self->getTargetDirID($params{-targetDir})
        if not exists $params{-directory_};

    if (exists $params{-fileId}) {
        $params{-File} = $params{-fileId};
    } else {
        $params{-File} =
            $self->_getUniqueID("$params{-fileName}", 'File', 72,
            $params{-sourceDirRel});
    }

    my $compName;
    my $components = $self->{tables}{Component} ||= {};
    if (!$isPE and !exists $params{-forceNewComponent}) {
        # Look for suitable existing component
        my @comps = values %{$self->{tables}{Component}};

        for my $comp (@comps) {
            next if !ref $comp;
            next if $comp->{-Directory_} ne $params{-directory_};
            next
                if exists $params{-condition}
                    and $comp->{-Condition} ne $params{-condition};
            next
                if exists $params{-requestedId}
                    and $comp->{-Component} ne $params{-requestedId};

            # Ignore -isKey for component matching so all files that could be
            # included in a component are included in a single component keyed
            # by a specified file.

            $compName = $comp->{-Component};
            last;
        }
    }

    $params{-FileSize} = -s $params{-path};

    if (!defined $compName) {
        # Need to create a new Component table entry
        my %cParams;
        my @wanted = qw(-File );

        if (exists $params{-forceNewComponent}) {
            if (ref $params{-forceNewComponent}) {
                %cParams = @{$params{-forceNewComponent}};
            } else {
                $cParams{-requestedId} = $params{-forceNewComponent};
            }
        } elsif (exists $params{-requestedId}) {
            $cParams{-requestedId} = $params{-requestedId};
        }

        $cParams{-Condition} = $params{-condition}
            if exists $params{-condition};

        $cParams{$_} = $params{$_} for grep {exists $params{$_}} @wanted;

        $compName = $self->addComponent(
            %cParams,
            -Directory_ => $params{-directory_},
            -features   => [$params{-featureId}],
            );
    }

    my $compRef = $self->{tables}{Component}{lc $compName};

    if ($params{-isKey} && $compRef->{-KeyPath} ne $params{-File}) {
        my $compTable = $self->{tables}{Component};
        $compRef->{-KeyPath} = $params{-File};
    }

    $params{-Component_} = $compName;
    $params{-FileName}   = $self->_longAndShort($params{-fileName});
    $params{-Sequence}   = '';
    $params{-Language}   = '1033' unless exists $params{-Language};
    return $self->_addFileRow(\%params);
}


=head3 addIconFile

Add an icon file to the installation.

    my $iconId = $msi->addIconFile ('path/to/unique_file_name.ico');

Note that an internal ID is generated from the file name (excluding the path to
the file). The file name must thus only contain alphanumeric characters, periods
and the underscore character.

Two icon files that differ only in their path, but have the same name will cause
grief (only one of the files will be used). This condition is B<not> checked
for!

The generated internal Id is returned and may be used for the C<-Icon_>
parameter required in other tables.

The file must exist at the time that I<addIconFile> is called.

I<addIconFile> may be called multiple times with the same file

=cut


sub addIconFile {
    my ($self, $file) = @_;

    croak "File $file must exist during installer generation"
        unless -e $file;

    croak
        "Illegal characters in icon file name: $file. Alphanumeric, '.' and '_' only allowed."
        unless (my $name) = $file =~ /([\w.]*)$/;

    $name = lc $name;
    return $name if exists $self->{tables}{Icon}{$name};

    my %params = (-Data => $file, -Name => $name);

    $self->_addIconRow(\%params);
    return $name;
}


=head3 addInstallExecuteSequence

Add an entry to the custom action table.

    $msi->addInstallExecuteSequence (
        -Action    => 'InstallDriver',
        -Condition => 'NOT MYDRIVERINSTALLED AND NOT Installed',
        -Sequence  => 3959,
        );

This provides fairly raw access to the CustomAction table and is only part of
the work required to set up a custom action. See the CustomAction
Table section in the documentation referenced in the L<See Also|/"SEE ALSO"> section for
further information.

=over 4

=item I<-Action>: required

Id for the action. This must be either a built-in action or a custom action.

A matching entry must exist in the CustomAction table if this is a custom
action.

=item I<-Condition>: optional

A conditional expression that must evaluate true at run time for the step to be
executed.

=item I<-Sequence>: required

Sequence position for execution of this action.

=item I<-secureProperties>: optional

A public property or array ref containing a list of public properties used in
the I<-Condition> expression that need to be passed securely into the execute
context.

The property names will be added to the SecureCustomProperties property during
L</writeTables>.

=back

=cut

sub addInstallExecuteSequence {
    my ($self, %params) = @_;

    Win32::MSI::HighLevel::Common::require(\%params, qw(-Action -Sequence));
    Win32::MSI::HighLevel::Common::allow(\%params,
        qw(-Action -Condition -Sequence -secureProperties));

    return $self->_addInstallExecuteSequenceRow(\%params);
}


=head3 addInstallUISequence

Add an entry to the custom action table.

    $msi->addInstallUISequence (
        -Action    => 'SetDefTargetDir',
        -Condition => '',
        -Sequence  => 1100,
        );

=over 4

=item I<-Action>: required

Id for the action. This must be either a built-in action or a custom action.

A matching entry must exist in the CustomAction table if this is a custom
action.

=item I<-Condition>: optional

A conditional expression that must evaluate true at run time for the step to be
executed.

=item I<-Sequence>: required

Sequence position for execution of this action.

=back

=cut

sub addInstallUISequence {
    my ($self, %params) = @_;

    Win32::MSI::HighLevel::Common::require(\%params, qw(-Action -Sequence));
    Win32::MSI::HighLevel::Common::allow(\%params,
        qw(-Action -Condition -Sequence));

    return $self->_addInstallUISequenceRow(\%params);
}


=head3 addLaunchCondition

Add an entry to the custom action table.

    $msi->addLaunchCondition (
        -Condition => 'NOT Version9X',
        -Description  => 'Windows versions prior to XP are not supported.',
        );

This provides fairly raw access to the CustomAction table and is only part of
the work required to set up a custom action. See the CustomAction
Table section in the documentation referenced in the L<See Also|/"SEE ALSO"> section for
further information.

=over 4

=item I<-Condition>: required

A conditional expression that must evaluate true at run time for the install to
proceed.

=item I<-Description>: required

Error text shown if the launch condition evaluates false.

=item I<-secureProperties>: optional

A public property or array ref containing a list of public properties used in
the I<-Condition> expression that need to be passed securely into the execute
context.

The property names will be added to the SecureCustomProperties property during
L</writeTables>.

=back

=cut

sub addLaunchCondition {
    my ($self, %params) = @_;

    Win32::MSI::HighLevel::Common::require(\%params,
        qw(-Condition -Description));
    Win32::MSI::HighLevel::Common::allow(\%params,
        qw(-Condition -Description -secureProperties));

    if (exists $params{-secureProperties}) {
        my $param = $params{-secureProperties};

        $param = join ';', ref $param ? @$param : $param;
    }

    return $self->_addLaunchConditionRow(\%params);
}


=head3 addMedia (see also L</setProperty>)

Add a cabinet file to the Media table.

    $msi->addMedia (-Cabinet => '#cab1', -DiskId => 1, -LastSequence => 20);

If all the files required by the install are to be part of the .msi file then
addMedia can be ignored - L</createCabs> does all the work required.

=over 4

=item I<-Cabinet>: optional

Name of the cabinet file.

A # as the first character in the name indicates that the cabinet file will be
stored in a stream in the .msi file. In this case the name is case sensitive.

If the first character in the name is not a # then the name must be given as a
short file name (8.3 format) and the cabinet is stored in a separate file
located at the root of the source tree specified by the Directory Table.

=item I<-DiskId>: required

A number (1 or greater) that determines the sort order of the media table.

=item I<-LastSequence>: required

Sequence number of the last file in this media.

=item I<-DiskPrompt>: optional

Name (on the label for physical media) used to identify the physical media
associated with this media entry.

=item I<-Source>: optional

Source to be used for patching.

=item I<-VolumeLabel>: optional

Volume label to be used to identify physical media.

=back

=cut

sub addMedia {
    my ($self, %params) = @_;
    my $table = $self->{tables}{Media} ||= {};

    Win32::MSI::HighLevel::Common::require(\%params, qw(-DiskId -LastSequence));
    Win32::MSI::HighLevel::Common::allow(\%params,
        qw(-Cabinet -DiskId -DiskPrompt -LastSequence -Source -VolumeLabel));

    $params{-Cabinet} = '' if !defined $params{-Cabinet};
    return $self->_addMediaRow(\%params);
}


=head3 addProperty (see also L</setProperty>)

Add a property value to the Property table. A new property id is generated based
on the supplied id if a property of the same name exists already.

    $msi->addProperty (-Property => 'Manufacturer', -Value => 'Wibble Corp.');

The actual property id used is returned.

=over 4

=item I<-Property>: required

Suggested property name

=item I<-Value>: required

Property value

=back

=cut

sub addProperty {
    my ($self, %params) = @_;
    my $table = $self->{tables}{Property} ||= {};

    Win32::MSI::HighLevel::Common::require(\%params, qw(-Property -Value));
    Win32::MSI::HighLevel::Common::allow(\%params,
        qw(-Property -Value -context));

    $params{-Property} =
        $self->_getUniqueID($params{-Property}, 'Property', 72,
        $params{-context});

    return $self->_addPropertyRow(\%params);
}


=head3 addRegistry

Add a registry entry.

    $msi->addRegistry (
        -root => HighLevel::msidbRegistryRootClassesRoot,
        -Component_ => 'Application',
        -Key => '.app',
        -Name => undef,
        -Value => 'MyApp'
        );

=over 4

=item I<-Component_>: optional

Id of the component controlling installation of the registry value.

This parameter is required unless I<-genRegKey> is used.

=item I<-genRegKey>: optional

Generates the registry table key and returns it, but doesn't generate the table
entry.

This option is required to solve a chicken and egg problem with components that
use a Registry table key for their KeyPath.

=item I<-Key>: required

Key path which may include properties but must not start or end with a backslash
(\).

=item I<-Name>: optional

=item I<-Root>: required

=item I<-Value>: required

Registry value to add.

=back

=cut

sub addRegistry {
    my ($self, %params) = @_;
    my $table = $self->{tables}{Registry} ||= {};

    Win32::MSI::HighLevel::Common::require(\%params, qw(-Key -Root -Value));
    Win32::MSI::HighLevel::Common::allow(\%params,
        qw(-Component_ -genRegKey -Key -Name -Root -Value));

    Carp::croak "-Component_ is required unless -genRegKey is used"
        if !(exists $params{-Component_} || exists $params{-genRegKey});

    my $regId =
        $self->_getUniqueID("$params{-Root}/$params{-Key}/$params{-Name}",
        'Registry');

    return $regId if exists $params{-genRegKey};

    $params{-Name} ||= '';
    $params{-Registry} = $regId;

    return $self->_addRegistryRow(\%params);
}


=head3 addRegLocator

Add a RegLocator table entry.

    $msi->addRegLocator (
        -Signature_ => 'MyDriver',
        -Root       => HighLevel::msidbRegistryRootLocalMachine,
        -Key => 'SYSTEM\CurrentControlSet\Control\Class\{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}',
        -Name => 'Class',
        -Type => HighLevel::msidbLocatorTypeRawValue,
        );

=over 4

=item I<-64Bit>: optional

Set to search the 64-bit portion of the registry. The 32-bit portion of the
registry will not be searched if -64Bit is set.

=item I<-directory>: optional

A key into the Directory table to be set from the registry.

One of I<-directory>, I<-file> and I<-property> is required.

=item I<-file>: optional

A key into the File table to be set from the registry.

One of I<-directory>, I<-file> and I<-property> is required.

=item I<-Key>: required

Key path.

=item I<-Name>: optional

Registry value name. If omitted the default value is used.

=item I<-property>: optional

A key into the AppSearch table for the row that contains the property to be set
to the registry value.

One of I<-directory>, I<file> and I<-property> is required.

=item I<-Root>: required

One of:

=over 4

=item msidbRegistryRootClassesRoot: HKEY_CLASSES_ROOT

=item msidbRegistryRootCurrentUser: HKEY_CURRENT_USER

=item msidbRegistryRootLocalMachine: HKEY_LOCAL_MACHINE

=item msidbRegistryRootUsers: HKEY_USERS

=back

=back

=cut

sub addRegLocator {
    my ($self, %params) = @_;
    my $table = $self->{tables}{Registry} ||= {};

    Win32::MSI::HighLevel::Common::require(\%params, qw(-Key -Root));
    Win32::MSI::HighLevel::Common::allow(\%params,
        qw(-64Bit -directory -file -Key -Name -property -Root));
    $params{-Name} ||= '';

    my $type = 0;
    my $signature;

    if (exists $params{-directory}) {
        $signature = $params{-directory};
        $type      = msidbLocatorTypeDirectory;

    } elsif (exists $params{-file}) {
        $signature = $params{-file};
        $type      = msidbLocatorTypeFileName;

    } elsif (exists $params{-property}) {
        $signature = $params{-property};
        $type      = msidbLocatorTypeRawValue;
    }

    $type |= msidbLocatorType64bit
        if exists $params{'-64Bit'} && $params{'-64Bit'};
    $params{-Signature_} = $signature;
    $params{-Type}       = $type;

    croak "One of -directory, -file or -property required"
        unless defined $signature;

    return $self->_addRegLocatorRow(\%params);
}


=head3 addSelfReg

Add a SelfReg table entry.

    $msi->addSelfReg (
        -File_ => $fileTableKey,
        -Cost  => HighLevel::msidbRegistryRootLocalMachine
        );

=over 4

=item I<-Cost>: required

The cost in bytes due to self registering this .dll.

=item I<-File_>: required

The key in the File table for the .dll to self register.

=back

=cut

sub addSelfReg {
    my ($self, %params) = @_;
    my $table = $self->{tables}{Registry} ||= {};

    Win32::MSI::HighLevel::Common::require(\%params, qw(-File_ -Cost));
    Win32::MSI::HighLevel::Common::allow(\%params, qw(-File_ -Cost));

    return $self->_addSelfRegRow(\%params);
}


#=head3 addRemoveFile
#
#Add a RemoveFile table entry to remove files or an empty
#folder.
#
#=over 4
#
#=item I<-FileKey>: optional
#
#Unique id identifying this table entry
#
#=item I<-directory>: required
#
#Path to the directory to remove or remove files from.
#
#=item I<-directory>: required
#
#Path to the directory to remove or remove files from.
#
#=item I<-directory>: required
#
#Path to the directory to remove or remove files from.
#
#=item I<-InstallMode>: required
#
#One of:
#
#=over 4
#
#=item msidbRemoveFileInstallModeOnInstall: remove on install
#
#=item msidbRemoveFileInstallModeOnRemove: remove on uninstall
#
#=item msidbRemoveFileInstallModeOnBoth: always remove
#
#=back
#
#=back
#
#=cut
#
#sub addRemoveFile {
#    my ($self, %params) = @_;
#    my $table = $self->{tables}{RemoveFile} ||= {};
#
#    Win32::MSI::HighLevel::Common::require (\%params, qw(-Key -Root));
#    Win32::MSI::HighLevel::Common::allow (\%params,
#        qw(-64Bit -directory -file -Key -Name -property -Root));
#    $params{-Name} ||= '';
#
#    my $type = 0;
#    my $signature;
#
#    if (exists $params{-directory}) {
#        $signature = $params{-directory};
#        $type      = msidbLocatorTypeDirectory;
#
#    } elsif (exists $params{-file}) {
#        $signature = $params{-file};
#        $type      = msidbLocatorTypeFileName;
#
#    } elsif (exists $params{-property}) {
#        $signature = $params{-property};
#        $type      = msidbLocatorTypeRawValue;
#    }
#
#    $type |= msidbLocatorType64bit
#        if exists $params{'-64Bit'} && $params{'-64Bit'};
#    $params{-Signature_} = $signature;
#    $params{-Type}       = $type;
#
#    croak "One of -directory, -file or -property required"
#        unless defined $signature;
#
#    return $self->_addRegLocatorRow (\%params);
#}


=head3 addShortcut

The following parameters are recognized by L</addShortcut>:

=over 4

=item I<-Arguments>: optional

The command line arguments for the shortcut.

=item I<-Component_>: optional (see also C<-target> and C<-Target>)

The id for the Component table entry which determines whether the the shortcut
will be deleted or created. The shortcut is created if the component has been
installed and is deleted otherwise.

If C<-Component_> is not provided the component associated with C<-target> or
C<-Target> will be used.

=item I<-Description>

The localizable description of the shortcut.

=item I<-Directory_>: optional (see also C<-location>)

The id for the Directory table entry which specifies where the shortcut file
will be created. The Directory entry need not exist until L</writeTables> is
called and is not checked.

One only of C<-location> and C<-Directory_> must be provided.

=item I<-featureId>

The feature the shortcut is installed by.

=item I<-Hotkey>

The hotkey for the shortcut. The low-order byte contains the virtual-key code
for the key, and the high-order byte contains modifier flags.

=item I<-folderTarget>: optional (see also C<-target> and C<-Target>)

The folder pointed to by the shortcut. Note that this folder must already have
been provided using L</addDirectory>, L</addDirPath> or L</createDirectory>.

One only of C<-folderTarget>, C<-target> and C<-Target> must be provided.

=item I<-location>: optional (see also C<-Directory_>)

The directory where the shortcut file will be created. Note that the directory
must already have been added with L</addDirectory>, L</addDirPath> or
L</createDirectory>.

The directory provided will be searched for in the Directory table to find the
directory id to be used for C<-Directory_>.

One only of C<-location> and C<-Directory_> must be provided.

=item I<-name>: required

Name to be shown for the shortcut. Note that the name need not be unique.

=item I<-Shortcut>: optional

Suggested internal id to be used for the shortcut. Note that if there is another
shortcut with the same id already a new id will be generated by appending a
number to the given id. The id actually used is returned.

If C<-Shortcut> is omitted a suitable id will be generated from the C<-Name>
value.

=item I<-ShowCmd>: optional

The mode used to show the window used by the shortcut when run. May be one of
the following constants:

=over

=item SW_SHOWNORMAL - Show normalised

=item SW_SHOWMAXIMIZED - Show maximised

=item SW_SHOWMINNOACTIVE - Show iconised

=back

If C<-ShowCmd> is omitted default Windows behavior is used (SW_SHOWNORMAL).

=item I<-Target>: optional (see also C<-folderTarget> and C<-target>)

The Feature id or a Property id that specifies the target of the shortcut.

If a Feature id is provided the target is the key file of the Component_ table
entry associated with the Feature.

If a Property id is provided the target is the file or directory specified as
the value of the property.

One only of C<-folderTarget>, C<-target> and C<-Target> must be provided.

=item I<-target>: optional (see also C<-folderTarget> and C<-Target>)

The file pointed to by the shortcut. Note that this file must already have been
provided using L</addFile> or L</addFiles>.

One only of C<-folderTarget>, C<-target> and C<-Target> must be provided.

=item I<-WkDir>: optional (see also C<-wkdir>)

The Directory id that specifies the working directory for the shortcut.

One only of C<-wkdir> and C<-WkDir> may be provided.

=item I<-wkdir>: optional (see also C<-WkDir>)

The working directory for the shortcut.

A directory table will be created if required.

One only of C<-wkdir> and C<-WkDir> may be provided.

=back

=cut

sub addShortcut {
    my ($self, %params) = @_;
    my $table = $self->{tables}{Shortcut} ||= {};
    my $featureId = $params{-featureId};

    Win32::MSI::HighLevel::Common::require(\%params, qw(-name -featureId));
    Win32::MSI::HighLevel::Common::allow(
        \%params, qw(
            -Arguments -Component_ -Description -Directory_ -featureId
            -folderTarget -location -Hotkey -Icon_ -name -Shortcut -ShowCmd
            -Target -target -WkDir -wkdir
            )
            );

    croak "Only one of -WkDir and -wkDir allowed\n"
        if exists $params{-WkDir} and exists $params{-wkDir};

    my $count;
    ++$count for grep {exists $params{$_}} qw(-folderTarget -Target -target);
    croak "Only one of -folderTarget, -Target and -target allowed\n"
        if $count > 1;

    croak "One of -folderTarget, -Target and -target required\n"
        unless $count;

    croak "Only one of -Directory_ and -location allowed\n"
        if exists $params{-Directory_} and exists $params{-location};

    croak "One of -Directory_ and -location required\n"
        unless exists $params{-Directory_}
            or exists $params{-location};

    $params{-Directory_} = $self->getTargetDirID($params{-location})
        if not exists $params{-Directory_};
    $params{-location} ||= $params{-Directory_};

    if (exists $params{-folderTarget}) {
        my $target = $self->getTargetDirID($params{-folderTarget});
        $params{-Target} = "[$target]";
    } elsif (exists $params{-target}) {
        my $target = $params{-target};
        my ($path, $file) = $target =~ m!(.*)[\\/](.*)!;
        my $dirId = $self->getTargetDirID($path);

        $params{-Target} = defined $dirId ? "[$dirId]\\$file" : $target;
    }

    my $lookup = "$params{-Target}/$params{-Directory_}";
    $params{-Shortcut} =
        $self->_getUniqueID($params{-name}, 'Shortcut', undef, $lookup);

    # Note that a Directory table entry is required for the working directory
    # entry, not a property entry. The Shortcut table documentation is wrong!
    $params{-WkDir} = $self->getTargetDirID($params{-wkdir})
        if exists $params{-wkdir};

    $params{-Component_} ||= $self->addComponent(
        -Directory_ => $params{-Directory_},
        -features   => [$featureId]
        );
    $params{-Name} = $self->_longAndShort($params{-name});

    return $self->_addShortcutRow(\%params);
}


=head3 addSignature

Add an entry to the Signature table used by the AppSearch action to match
previously installed applications.

The following parameters are recognized by L</addSignature>:

=over 4

=item I<-FileName>: required

The name of the file to search for.

=item I<-Languages>: optional

Specify the language ID or IDs for the file. If more than one ID is specified
use a comma separated list. Multiple entries require a file supporting all
specified languages for a match.

=item I<-MaxDate>: optional

The maximum creation date of the file. If this parameter is specified, then the
file must have a creation date that is at most equal to MaxDate. This must be a
non-negative number. The format of this field is two packed 16-bit values of
type WORD. The high order WORD value specifies the date in MS-DOS date format.
The low order WORD value specifies the time in MS-DOS time format. A value of 0
for the time value represents midnight.

The formula for calculating the value is:

   (($Year - 1980) * 512 + $Month * 32 + $Day) * 65536 + $Hours * 2048 + $Minutes * 32 + $Seconds / 2

=item I<-MinDate>: optional

The minimum modification date and time of the file. If this field is specified,
then the file under inspection must have a modification date and time that is at
least equal to MinDate.

See I<-MaxSize> above.

=item I<-MinSize>: optional

The minimum size of the file. If this parameter is specified, then the file
under inspection must have a size that is at least equal to MinSize. This must
be a non-negative number.

=item I<-MaxVersion>: optional

The maximum version of the file. If this parameter is specified, then the file
must have a version that is at most equal to MaxVersion.

=item I<-MinVersion>: optional

The minimum version of the file, with a language comparison. If this field is
specified, then the file must have a version that is at least equal to
MinVersion. If the file has an equal version to the MinVersion field value but
the language specified in the Languages column differs, the file does not
satisfy the signature filter criteria.

Note The language specified in the Languages parameter is used in the comparison
and there is no way to ignore language. If you want a file to meet the
MinVersion field requirement regardless of language, you must enter a value in
the MinVersion field that is one less than the actual value. For example, if the
minimum version for the filter is 2.0.2600.1183, use 2.0.2600.1182 to find the
file without matching the language information.

=item I<-Signature>: required

This required parameter must be a unique id that is used as an external key by
various tables involved in searching for applications and related files,
directories and registry entries.

=back

=cut

sub addSignature {
    my ($self, %params) = @_;
    my $table = $self->{tables}{Signature} ||= {};
    my $featureId = $params{-featureId};

    Win32::MSI::HighLevel::Common::require(\%params, qw(-Signature -FileName));
    Win32::MSI::HighLevel::Common::allow(
        \%params, qw(
            -Signature -FileName -MinVersion -MaxVersion -MinSize -MaxSize
            -MinDate -MaxDate -Languages
            )
            );

    return $self->_addSignatureRow(\%params);
}


=head3 addStorage

Add a binary file to the installation as a storage.

=over 4

=item I<-Name>: required

Id to be used as the key entry in the storages table. This entry must be
unique.

=item I<-file>: required

Path to the file to be added on the source system.

=back

=cut


sub addStorage {
    my ($self, %params) = @_;

    Win32::MSI::HighLevel::Common::require(\%params, qw(-Name -file));
    Win32::MSI::HighLevel::Common::allow(\%params, qw(-Name -file));

    croak "File $params{-file} must exist during installer generation"
        unless -e $params{-file};

    $params{-Data} = $params{-file};
    $self->_addStorageRow(\%params);
}


=head3 addUpgrade

Add an upgrade table entry.

    $msi->addUpgrade (
        -UpgradeCode => $UpgradeGUID,
        -VersionMin  => 1.0,
        -VersionMax  => 2.0
        );

=over 4

=item I<-UpgradeCode>: optional

UpgradeCode GUID associated with the product detected by the Upgrade table entry
being added.

If this parameter is omitted the UpgradeCode Property table entry will be used.
Calling C<setProduct> sets the UpgradeCode Property table entry.

Version numbers (if provided) must be in the form C<x[.y[.z]]>. y and z will be
set to 0 if they are omitted. x, y, and z must be numeric. A fourth value is not
allowed.

=item I<-VersionMin>: optional

Minimum product version number that this table entry will detect.

If both C<-VersionMin> and C<-VersionMax> are omitted C<-VersionMin> will be set
to 0 to find all product versions.

=item I<-VersionMax>: optional

Maximum product version number that this table entry will detect.

If both C<-VersionMin> and C<-VersionMax> are omitted C<-VersionMax> will be set
to null to find all product versions.

=item I<-Language>: optional

Must be one of Microsoft's language codes. For example US English is 0x0409.

Language matching will be ignored if C<-Language> is omitted.

=item I<-Attributes>: optional

The following attributes may be ored together:

    msidbUpgradeAttributesMigrateFeatures     Copy selected features
    msidbUpgradeAttributesOnlyDetect          Detect only - don't uninstall
    msidbUpgradeAttributesIgnoreRemoveFailure Ignore uninstall failure
    msidbUpgradeAttributesVersionMinInclusive Include min version
    msidbUpgradeAttributesVersionMaxInclusive Include max version
    msidbUpgradeAttributesLanguagesExclusive  Include all langs except listed

See the MSDN documentation for further information about these attributes.

=item I<-Remove>: optional

List of features to be removed during the install. A single feature name or an
array reference containing feature names is expected.

=item I<-ActionProperty>: required

Public property name (must be upper case) of the property that will be set to
the list of product codes for installed products matching this upgrade entry.

This property name will be added to the SecureCustomProperties property during
L</writeTables>.

=back

=cut

sub addUpgrade {
    my ($self, %params) = @_;
    my $table = $self->{tables}{Registry} ||= {};

    Win32::MSI::HighLevel::Common::require(\%params, qw(-ActionProperty));
    Win32::MSI::HighLevel::Common::allow(
        \%params,
        qw(
            -UpgradeCode -VersionMin -VersionMax -Language -Attributes -Remove
            -ActionProperty
            )
            );

    if (!exists $params{-UpgradeCode}) {
        my $ucProp = $self->getProperty('UpgradeCode');

        croak
            "-UpgradeCode parameter or UpgradeCode property required for addUpgrade"
            unless defined $ucProp;

        $params{-UpgradeCode} = $ucProp;
    }

    $params{-Attributes} ||= 0;
    my $residuleFlags = $params{-Attributes} & ~0x707;
    croak "Bad -Attributes value used for addUpgrade: $residuleFlags"
        if $residuleFlags;

    $params{-Language} ||= '';

    croak "One of -VersionMin and -VersionMax required for addUpgrade"
        unless exists $params{-VersionMin}
            or exists $params{-VersionMax};
    for my $key (qw()) {
        next unless exists $params{$key};
        next if $params{$key} =~ /^\d+(\.\d+(\.\d+)?)?$/;

        croak "Version number must be of the form x[.y[.z]].\n"
            . "   $params{$key} is not valid for $key";
    }

    return $self->_addUpgradeRow(\%params);
}


=head3 createCabs

Creates the cab files as required from the files that have been added with
L</addFile> or L</addFiles>.

    $msi->createCabs ();

Note that L</createCabs> must be called after all files have been added and
before L</writeTables> is called.

Note too that makecab.exe must be available on the system being used. With
versions of Windows from Windows 2000 on makecab.exe seems to be provided with
the system so this should not generally be an issue. If L</createCabs> generates
a 'makecabs.exe not found' error copy makecabs.exe into the working directory or
add the path to makecabs.exe to the PATH environment variable.

L</createCabs> updates the C<Media> table as appropriate.

Note that L</createCabs> generates a C<cab.dff> file that may be used as a
manifest of the files added to the install (ignore lines starting with .).

=cut

sub createCabs {
    my $self = shift;

    unless (exists $self->{tables}{Cabs}) {
        $self->createTable(
            -table      => 'Cabs',
            -columnSpec => [
                Name => [qw(Identifier(32) Key Required)],
                Data => [qw(Binary Required)]
                ]
                );
    }

    my $fileTable = $self->{tables}{File};
    my @files = sort {$a->[0] cmp $b->[0]}
        map {[$fileTable->{$_}{-Component_}, $_]}
        grep {ref $fileTable->{$_}} keys %$fileTable;

    if (!@files) {
        # Add an empty media table entry
        $self->addMedia(-DiskId => 1, -LastSequence => 1);

        return;
    }

    my $lastComponent = $files[0][0];
    my $sequence      = 1;
    my $cabDFF        = "$self->{-workRoot}\\cab.dff";

    open CABDFF, '>', $cabDFF;
    print CABDFF <<HEADER;
.Set CabinetNameTemplate=cab*.cab
.Set Cabinet=on
.Set Compress=on
.Set CompressionType=LZX
.Set FolderFileCountThreshold=20
.Set GenerateInf=on
.Set MaxDiskSize=0
.Set UniqueFiles=off
HEADER

    for (@files) {
        my ($component, $key) = @$_;
        my $file    = $fileTable->{$key};
        my $absPath = File::Spec->rel2abs($file->{-path});

        if ($component ne $lastComponent) {
            print CABDFF ".New Folder\n";
            $lastComponent = $component;
        }

        $fileTable->{$key}{-Sequence} = $sequence++;
        print CABDFF "\"$absPath\" $file->{-File}\n";
    }

    print CABDFF <<TAIL;

TAIL
    CORE::close CABDFF;

    my $workDir = Cwd::getcwd();

    chdir $self->{-workRoot};
    mkdir "$self->{-workRoot}\\disk1" unless -d "$self->{-workRoot}\\disk1";
    `makecab /F $cabDFF /L "$self->{-workRoot}" /V1`;
    chdir $workDir;

    $self->addCab(
        -name    => 'cab1.cab',
        -file    => "$self->{-workRoot}\\disk1\\cab1.cab",
        -disk    => 1,
        -lastSeq => $sequence - 1
        );
}


=head3 createTable

Creates a new database table.

    my $table = $msi->createTable (-table => 'Feature');
    my $table = $msi->createTable (
        -table => 'Properties',
        -columnSpec => [
            Property => [qw(Key Identifier(72) Required)],
            Value => [qw(Text(0) Required)],
            ]
        );

C<createTable> knows the column specification for the following commonly used
tables: C<AppSearch, Binary, Component, CustomAction, Directory , Extension,
Feature, FeatureComponents, File, Icon, LaunchCondition, Media,
MsiDriverPackages, Property, ProgId, RegLocator, Shortcut, Verb>.

Any other tables must be created by providing a suitable I<-columnSpec>
parameter. If there are tables that you use regularly that are not included in
the list above contact the module maintainer with the column specification and
suggest that it be added.

=over 4

=item I<-columnSpec>: optional

Specification for the table's columns. This is required for tables that
Win32::MSI::HighLevel doesn't handle by default.

Note that custom tables may be added to the installer file.

The column specification comprises an array of column name => type pairs.
Most of the types mentioned in the MSDN documentation are recognized, including:

=over 4

=item AnyPath:

=item Cabinet: CHAR(255)

=item DefaultDir: CHAR(255)

=item Directory: CHAR(72)

=item Filename: CHAR(128) LOCALIZABLE

=item Formatted: CHAR(255)

=item Identifier: CHAR(38)

=item Integer: INT

=item Language: CHAR(20)

=item Long: LONG

=item Property: CHAR(32)

=item Required: NOT NULL

=item Shortcut: CHAR(255)

=item Text: CHAR(255) LOCALIZABLE

=item UpperCase: CHAR(255)

=item Version: CHAR(72)

=back

Where the default type includes a size (number in parenthesis) a different size
may be supplied by including it in parenthesis following the type:

    Text(0)

=item I<-table>: required

Name of the table to create.

=back

=cut

sub createTable {
    my ($self, %params) = @_;
    my %types = (
        AnyPath          => 'CHAR(255)',
        Binary           => 'OBJECT',
        Cabinet          => 'CHAR(255)',
        Condition        => 'CHAR(255)',
        CustomSource     => 'CHAR(255)',
        DefaultDir       => 'CHAR(255)',
        Directory        => 'CHAR(72)',
        DoubleInteger    => 'LONG',
        Filename         => 'CHAR(128) LOCALIZABLE',
        Formatted        => 'CHAR(255)',
        GUID             => 'CHAR(38)',
        Identifier       => 'CHAR(38)',
        Integer          => 'INT',
        KeyPath          => 'CHAR(255)',
        Language         => 'CHAR(20)',
        Long             => 'LONG',
        Property         => 'CHAR(32)',
        RegPath          => 'CHAR(255)',
        Required         => 'NOT NULL',
        Shortcut         => 'CHAR(255)',
        Text             => 'CHAR(255) LOCALIZABLE',
        UpperCase        => 'CHAR(255)',
        Version          => 'CHAR(72)',
        WildCardFilename => 'CHAR(128) LOCALIZABLE',
        );
    my %columnSpecs = (
        AppSearch => [
            Property   => [qw(Key Identifier(72) Required)],
            Signature_ => [qw(Key Identifier(72) Required)],
            ],
        Binary => [
            Name => [qw(Identifier(32) Key Required)],
            Data => [qw(Binary Required)]
            ],
        Component => [
            Component   => [qw(Key Identifier(72) Required)],
            ComponentId => 'GUID',
            Directory_  => [qw(Directory Required)],
            Attributes  => [qw(Integer Required)],
            Condition   => [qw(Condition)],
            KeyPath     => [qw(KeyPath(80))],
            ],
        ControlCondition => [
            Dialog_   => [qw(Key Identifier(72) Required)],
            Control_  => [qw(Key Identifier(50) Required)],
            Action    => [qw(Key Text(50) Required)],
            Condition => [qw(Key Condition Required)],
            ],
        CreateFolder => [
            Directory_ => [qw(Key Identifier(72) Required)],
            Component_ => [qw(Key Identifier(72) Required)],
            ],
        CustomAction => [
            Action => [qw(Key Identifier(72) Required)],
            Type   => [qw(Integer Required)],
            Source => [qw(CustomSource)],
            Target => [qw(Formatted)],
            ],
        Directory => [
            Directory        => [qw(Key Identifier(72) Required)],
            Directory_Parent => ['Identifier(72)'],
            DefaultDir       => [qw(DefaultDir Required)],
            ],
        DrLocator => [
            Signature_ => [qw(Key Text Required)],
            Parent     => [qw(Key Identifier(72))],
            Path       => [qw(Key Text)],
            Depth      => [qw(Integer)],
            ],
        Extension => [
            Extension  => [qw(Key Text Required)],
            Component_ => [qw(Key Identifier(72) Required)],
            ProgId_    => [qw(Text)],
            MIME_      => [qw(Text)],
            Feature_   => [qw(Identifier Required)],
            ],
        Feature => [
            Feature        => [qw(Key Identifier Required)],
            Feature_Parent => ['Identifier'],
            Title          => ['Text(64)'],
            Description    => ['Text(255)'],
            Display        => ['Integer'],
            Level          => [qw(Integer Required)],
            Directory_     => ['Directory'],
            Attributes     => [qw(Integer Required)],
            ],
        FeatureComponents => [
            Feature_   => [qw(Key Identifier Required)],
            Component_ => [qw(Key Identifier(72) Required)],
            ],
        File => [
            File       => [qw(Key Identifier Required)],
            Component_ => [qw(Identifier Required)],
            FileName   => [qw(Filename Required)],
            FileSize   => [qw(DoubleInteger Required)],
            Version    => [qw(Version)],
            Language   => [qw(Language)],
            Attributes => [qw(Integer)],
            Sequence   => [qw(Integer Required)],
            ],
        Icon => [
            Name => [qw(Identifier(32) Key Required)],
            Data => [qw(Binary Required)]
            ],
        InstallUISequence => [
            Action    => [qw(Identifier(72) Key Required)],
            Condition => [qw(Condition)],
            Sequence  => [qw(Integer Required)],
            ],
        LaunchCondition => [
            Condition   => [qw(Key Condition Required)],
            Description => [qw(Formatted Required)],
            ],
        Media => [
            DiskId       => [qw(Key Integer Required)],
            LastSequence => [qw(Long Required)],
            DiskPrompt   => [qw(Text(64))],
            Cabinet      => [qw(Cabinet)],
            VolumeLabel  => [qw(Text(32))],
            Source       => [qw(Property)],
            ],
        MsiDriverPackages => [
            Component => [qw(Key Text(255) Required)],
            Flags     => [qw(Long Required)],
            Sequence  => [qw(Long)],
            ],
        Property => [
            Property => [qw(Key Identifier(72) Required)],
            Value    => [qw(Text(0) Required)],
            ],
        ProgId => [
            ProgId        => [qw(Key Text Required)],
            ProgId_Parent => [qw(Text)],
            Class_        => [qw(GUID)],
            Description   => [qw(Text)],
            Icon_         => [qw(Identifier)],
            IconIndex     => [qw(Integer)],
            ],
        RegLocator => [
            Signature_ => [qw(Key Identifier(72) Required)],
            Root       => [qw(Integer Required)],
            Key        => [qw(RegPath Required)],
            Name       => [qw(Formatted)],
            Type       => [qw(Integer)],
            ],
        RemoveFile => [
            FileKey     => [qw(Key Identifier Required)],
            Directory_  => [qw(Identifier Required)],
            FileName    => [qw(WildCardFilename)],
            DirProperty => [qw(Identifier Required)],
            InstallMode => [qw(Identifier Required)],
            ],
        SelfReg => [
            File_ => [qw(Key Identifier(72) Required)],
            Cost  => [qw(Integer Required)]
            ],
        ServiceControl => [
            ServiceControl => [qw(Key Identifier(72) Required)],
            Name           => [qw(Formatted Required)],
            Event          => [qw(Integer Required)],
            Arguments      => [qw(Formatted)],
            Wait           => [qw(Integer)],
            Component_     => [qw(Identifier(72) Required)],
            ],
        ServiceInstall => [
            ServiceInstall => [qw(Key Identifier(72) Required)],
            Name           => [qw(Formatted Required)],
            DisplayName    => 'Formatted',
            ServiceType    => [qw(DoubleInteger Required)],
            StartType      => [qw(DoubleInteger Required)],
            ErrorControl   => [qw(DoubleInteger Required)],
            LoadOrderGroup => 'Formatted',
            Dependencies   => 'Formatted',
            StartName      => 'Formatted',
            Password       => 'Formatted',
            Arguments      => 'Formatted',
            Component_     => [qw(Identifier(72) Required)],
            Description    => 'Formatted',
            ],
        Shortcut => [
            Shortcut               => [qw(Key Identifier(72) Required)],
            Directory_             => [qw(Identifier(72) Required)],
            Name                   => [qw(Filename Required)],
            Component_             => [qw(Identifier(72) Required)],
            Target                 => [qw(Directory Required)],
            Arguments              => 'Formatted',
            Description            => 'Text',
            Hotkey                 => 'Integer',
            Icon_                  => 'Identifier(72)',
            IconIndex              => 'Integer',
            ShowCmd                => 'Integer',
            WkDir                  => 'Identifier(72)',
            DisplayResourceDLL     => 'Formatted',
            DisplayResourceId      => 'Integer',
            DescriptionResourceDLL => 'Formatted',
            DescriptionResourceId  => 'Integer',
            ],
        Signature => [
            Signature  => [qw(Key Identifier(72) Required)],
            FileName   => [qw(Text Required)],
            MinVersion => [qw(Version)],
            MaxVersion => [qw(Version)],
            MinSize    => [qw(DoubleInteger)],
            MaxSize    => [qw(DoubleInteger)],
            MinDate    => [qw(DoubleInteger)],
            MaxDate    => [qw(DoubleInteger)],
            Languages  => [qw(Text)],
            ],
        Upgrade => [
            UpgradeCode    => [qw(Key GUID Required)],
            VersionMin     => [qw(Key Version)],
            VersionMax     => [qw(Key Version)],
            Language       => [qw(Key Text)],
            Attributes     => [qw(Key Integer Required)],
            Remove         => 'Formatted',
            ActionProperty => [qw(Identifier Required)],
            ],
        Verb => [
            Extension_ => [qw(Key Text Required)],
            Verb       => [qw(Key Text Required)],
            Sequence   => [qw(Integer)],
            Command    => [qw(Formatted)],
            Argument   => [qw(Formatted)],
            ],
            );

    if (exists $params{_keys}) {
        # Return the keys for the given table
        my $tableSpec = $columnSpecs{$params{_keys}};

        croak
            "Internal error - no column specification for $params{_keys} table"
            unless defined $tableSpec;

        my %fields = @$tableSpec;
        my @keys   = grep {
            grep {$_ eq 'Key'}
                @{$fields{$_}}
        } keys %fields;

        return @keys;
    }

    Win32::MSI::HighLevel::Common::require(\%params, qw(-table));
    Win32::MSI::HighLevel::Common::allow(\%params, qw(-table -columnSpec));

    croak
        "$params{-table} is a temporary or read only table and can not be created."
        if _readonlyTable($params{-table});

    croak
        "A known table type ($params{-table} given) or a -columnSpec parameter is required"
        unless exists $params{-columnSpec}
            or exists $columnSpecs{$params{-table}};

    $params{-columnSpec} = $columnSpecs{$params{-table}}
        unless exists $params{-columnSpec};

    my @columnSpecs;
    my @keys;

    while (@{$params{-columnSpec}}) {
        my ($column, $spec) = splice @{$params{-columnSpec}}, 0, 2;

        croak "No type specification provided for column $columnSpecs[-1]"
            unless defined $spec and 'ARRAY' eq ref($spec) || !ref($spec);

        push @columnSpecs, "`$column`";

        my @specArray = 'ARRAY' eq ref $spec ? @$spec : $spec;
        for my $type (@specArray) {
            if ($type eq 'Key') {
                push @keys, $column;
                next;
            }

            my ($base, $size) = $type =~ /^(\w+) (?:\((\d+)+\))?/x;

            croak
                "Unknown column specification type ($type) for column $columnSpecs[-1]"
                unless exists $types{$base};

            my $specText = $types{$base};

            $specText .= "($size)"
                if defined $size and $specText !~ s/\(\d+\)/($size)/;
            $columnSpecs[-1] .= " $specText";
        }

        $columnSpecs[-1] =~ s/^(\S+\s\S+)(.*)(\sNOT NULL)/$1$3$2/;
        $columnSpecs[-1] =~
            s/^(\S+\s\S+(?:\sNOT NULL)?)(.*)(\sTEMPORARY)/$1$3$2/;
        $columnSpecs[-1] =~
            s/^(\S+\s\S+(?:\sNOT NULL)?(?:\sTEMPORARY)?)(.*)(\sLOCALIZABLE)/$1$3$2/;
        next;
    }

    croak "No key column provided for table $params{-table}"
        unless @keys;

    my $columnSpec = join ', ', @columnSpecs;
    my $sql = "CREATE TABLE `$params{-table}` ($columnSpec";

    $sql .= ' PRIMARY KEY ' . join(', ', map {"`$_`"} @keys) . ')';
    my $table = Win32::MSI::HighLevel::View->new($self, query => $sql, %params);

    $self->{tables}{$params{-table}}{_created} = 1;
    $self->commit();    # Ensure table is created in database
    return $table && $params{-table};
}


=head3 dropTable

Removes a database table.

    my $table = $msi->dropTable ('Feature');

=cut

sub dropTable {
    my ($self, $table) = @_;

    return Win32::MSI::HighLevel::View->new($self,
        query => "DROP TABLE `$table`");
}


=head3 expandPath

Expand a path including system folder properties to a path with the system
folders resolved by examining Directory table entries.

    my $path = expandPath ($filePath);

L</expandPath> returns a long path.

=cut

sub expandPath {
    my ($self, $path) = @_;

    return $path unless $path =~ s/^\[([^\]]+)\]//;

    my $dirId = lc $1;

    if (!exists $self->{tables}{Directory}{$dirId}) {
        return "$systemFolders{$1}$path"
            if exists $systemFolders{$1};

        warn "No Directory ID matching $1 found while expanding [$1]$path\n";
        return "$1$path";
    }

    my $prefix = '';

    while (defined $dirId and length $dirId) {
        last unless exists $self->{tables}{Directory}{$dirId};

        my $dir = $self->{tables}{Directory}{$dirId};
        my ($short, $long) = @{$self->_dirPair($dir->{-DefaultDir})};

        $long .= '\\' if length $prefix;
        $prefix = "$long$prefix";
        $dirId  = $dir->{-Directory_Parent};
    }

    return "$prefix$path";
}


=head3 exportTable

Saves a database table in a .csv file format.

    my $table = $msi->exportTable ('Directory', '.\Tables');

Important! You must L</writeTables> before calling L</exportTable> to ensure that
the database version of the table matches the internal cached version.

The sample code would export the Directory table as the file 'Directory.idt' to
the sub-directory Tables in the current working directory.

If the table includes streams a sub-directory to the directory containing the
exported file will be created with the same base name as the table. A file for
each stream will then be created in the sub-directory. The created files will
have the extension '.idb'.

Note that the table name _SummaryInformation may be used to write out the
Summary Information Stream.

Also note that the exported file format is ideal for management using a revision
control system.

See also L</importTable>.

=cut

sub exportTable {
    my ($self, $table, $path) = @_;

    $path = File::Spec->rel2abs($path);
    mkdir $path unless -d $path;

    my $result =
        $MsiDatabaseExport->Call($self->{handle}, $table, $path, "$table.idt");
    return $result;
}


=head3 getComponentIdFromFileId

Return the component Id for the given file Id.

    my %entry = getComponentIdFromFileId ('Wibble.txt');

This call does not create a component or file entry. It returns null if there is
not a matching file id.

=cut

sub getComponentIdFromFileId {
    my ($self, $fileId) = @_;

    return $self->{tables}{File}{lc $fileId}{-Component_}
        if exists $self->{tables}{File}{lc $fileId};

    return undef;
}


=head3 getComponentIdForDirId

Return the component Id for the component that has a null KeyPath and a
Directory_ value matching the directory id passed in.

    my %entry = getComponentIdForDirId (-Directory => 'Wibble', -features => ['Complete']);

A component is created if there is not an appropriate existing component.
FeatureComponent table entries will be generated if a Component table entry is
generated.

=over 4

=item I<-Directory>: required

Directory Id to find (or create) a matching component Id for.

=item I<-features>: required

The list of features that install the component associated with the directory.

=back

=cut

sub getComponentIdForDirId {
    my ($self, %params) = @_;

    Win32::MSI::HighLevel::Common::require(\%params, qw(-Directory -features));
    Win32::MSI::HighLevel::Common::allow(\%params, qw(-Directory -features));

    croak "Directory table doesn't exist."
        unless exists $self->{tables}{Directory};
    croak "$params{-Directory} is not a directory id"
        unless exists $self->{tables}{Directory}{lc $params{-Directory}};

    if (exists $self->{tables}{Component}{lc $params{-Directory}}) {
        my $component = $self->{tables}{Component}{lc $params{-Directory}};

        $component = $component->{-Component};
        $self->addFeatureComponents(
            -Component_ => $component,
            -features   => $params{-features}
            );
        return $component;
    }

    return $self->addComponent(
        -Directory_ => $params{-Directory},
        -features   => $params{-features}
        );
}


=head3 getId

Return the table key id generated for a given id. For example:

    my $dirId = $msi->getId ('MyDir', 'Directory', 'my\\path');

will return the unique id generated for the MyDir directory entry in the
Directory table with 'my\path' as the parent path.

=cut

sub getId {
    my ($self, $id, $context, $extra) = @_;
    $extra ||= '';

    my $key = lc "$id$self->{extraSep}$extra";

    $key =~ s/^[^|]*\|//;    # Retain only long file name portion
    $_[4] = $key if exists $_[4];    # 'Return' key
    if (exists $self->{id_keyToId}{$context}{$key}) {
        return $self->{id_keyToId}{$context}{$key};
    } else {
        return undef;
    }
}


=head3 getParentDirID dirId

Returns the parent Directory table id given an existing directory id.

    my $dirId = $msi->getParentDirID ('WibbleApp');

If the dirId passed in does not exist an undef will be returned, otherwise a
string (which may be empty for a root dir) will be returned.

=cut

sub getParentDirID {
    my ($self, $dirId) = @_;
    my $parentId;
    my $dirTable = $self->{tables}{Directory};

    $self->_buildDirLookup();

    return unless exists $dirTable->{$dirId};
    return $dirTable->{$dirId}{-Directory_Parent};
}


=head3 getProduct

Return a string containing product and major version information.

    my $productString = $msi->getProduct ();

=cut

sub getProduct {
    my ($self) = @_;
    my $name   = $self->getProperty('ProductName');
    my $vers   = $self->getProperty('ProductVersion');
    my $manf   = $self->getProperty('Manufacturer');

    return "$manf: $name - $vers";
}


=head3 getProductCode

Return a GUID as a string containing product code for the installer.

    my $productGUID = $msi->getProductCode ();

If a product code does not yet exist it will be generated as the MD5 sum of the
ProductName, ProductLanguage, ProductVersion and Manufacturer property values.

=cut

sub getProductCode {
    my ($self) = @_;

    return $self->{productCode} if exists $self->{productCode};
    return $self->_genProductCode();
}


=head3 getProperty

Return the Property value for the given property name. Returns undef of the
property entry doesn't exist.

    my %entry = $msi->getProperty ($propName);

=cut

sub getProperty {
    my ($self, $key) = @_;

    my $rec = $self->getTableEntry('Property', {'-Property' => $key});
    return undef if !defined $rec;
    return $rec->{-Value};
}


=head3 getTableEntry

Return a reference to the table column data for a given table entry.

    my $entry = $msi->getTableEntry ('File', {-File => 'wibble.exe'});

Returns undef if the table or key doesn't exist.

If fields within the $entry hash ref are edited L</updateTableEntry> must be called.

A degree of caution is advised in using this member. Very little checking can
be performed on the results of editing the hash returned. Generally errors will
result in failures at L</writeTables> time.

=cut

sub getTableEntry {
    my ($self, $name, $keys) = @_;
    my $key = lc join '/', map {$keys->{$_}} sort keys %$keys;

    return undef unless exists $self->{tables}{$name};
    return undef unless exists $self->{tables}{$name}{$key};

    my $entry = {%{$self->{tables}{$name}{$key}}};

    $entry->{'!key'}  = $key;
    $entry->{'!name'} = $name;
    $entry->{'!lu'}   = $entry->{-lu};
    return $entry;
}


=head3 getTargetDirID targetpath [public [wantedId]]

L</getTargetDirID> returns a Directory table id given an install time target file
path. Entries in the Directory table will be created as required to generate an
appropriate id.

    my $dirId = $msi->getTargetDirID ('[ProgramFilesFolder]\Wibbler\WibbleApp');

An existing Directory table entry may be used as the first element of a
directory path. If an existing Directory table entry is used it must be the
first element of the directory path. Relative paths are with respect to the
target install directory (TARGETDIR).

Where existing Directory table entries match a given path prefix the existing
entries are used to reduce proliferation of table entries.

L</getTargetDirID> generally takes a single unnamed parameter which is the
install time (target) path to match.

Note that the paths may use either \ or / delimiters. All path components are
assumed to be long (not short "filename"). Short "filenames" will be generated
as required.

An optional (second) boolean parameter may be provided to indicate that the
Directory is public. That is, that at install time the user may change the
install location for the directory. If a true value is provided as the second
parameter the directory Id is forced to upper case to make the entry a public
directory entry.

An optional third parameter may be provided to suggest an Id. If provided the
boolean 'public' parameter must be provided also.

The following system folder properties may be used directly as shown in the sample
code above:

=over 4

=item CommonAppDataFolder

Full path to the file directory containing application data for all users

=item CommonFilesFolder

Full path to the Common Files folder for the current user

=item StartMenuFolder

Full path to the Start Menu folder

=back

=cut

sub getTargetDirID {
    my ($self, $path, $public, $wantedId) = @_;
    my $id;
    my $dirTable = $self->{tables}{Directory};

    $self->_buildDirLookup();
    $path =~ s!\\!/!g;

    my @parts = split '/', $path;
    my $parent = 'TARGETDIR';

    while (@parts) {
        my ($part) = (shift @parts) =~ /\[?([^\]]*)\]?$/;
        my $lcPart = lc $part;
        my @entrys;
        my $entry;

        @entrys = keys %{$self->{DirLookup}{$lcPart}}
            if defined $self->{DirLookup}{$lcPart};

        for (@entrys) {
            next
                unless $self->{DirLookup}{$lcPart}{$_}{-Directory_Parent} eq
                    $parent;

            $entry = $self->{DirLookup}{$lcPart}{$_};
            last;
        }

        # See if it's a predefined directory
        if (!defined $entry and exists $systemFolders{$part}) {
            $entry = {%{$systemFolders{$part}}, -Directory => $part};
            $self->addDirectory(%$entry)
                if !defined $self->{tables}{Directory}{$lcPart};
        }

        if (!defined $entry) {

            # Create the Directory table entry and the lookup entry
            my $short  = $self->_longToShort($part);
            my $defDir = $short;
            my $dirId  = "Dir_$part";                # Avoid property id clashes

            # Dir id must be uc if it is public (eg, for a feature dir)
            $dirId = uc $dirId
                if !@parts
                    and $public
                    and uc($part) ne $part;

            $dirId = $wantedId if !@parts and defined $wantedId;

            $dirId = $self->_getUniqueID($dirId, "Directory", undef, $parent);
            if (!defined $dirId or !length $dirId) {
                croak "Failed to generate a directory id for $path";
            }

            $defDir .= "|$part" unless lc $short eq $lcPart;
            $self->addDirectory(
                -DefaultDir       => $defDir,
                -Directory        => $dirId,
                -Directory_Parent => $parent,
                );

            $entry = $dirTable->{lc $dirId};
            $self->{DirLookup}{lc $dirId}{$entry->{-Directory}} = $entry;
            $self->{DirLookup}{$lcPart}{$entry->{-Directory}} = $entry;
        }

        $id = $parent = $entry->{-Directory};
    }

    return $id;
}


=head3 haveDirId dirName

Returns a reference to the Directory table entry for given directory Id if it
exists or undef otherwise.

    my $dirEntry = $msi->haveDirId ('Wibble');

=cut

sub haveDirId {
    my ($self, $dirName) = @_;

    return unless exists $self->{tables}{Directory}{lc $dirName};
    return $self->{tables}{Directory}{lc $dirName};
}


=head3 importTable

Imports an exported database table in a .csv file format.

    my $table = $msi->importTable ('.\Tables', 'Directory');

    $msi->writeTables ();
    $msi->populateTables ();

Important! You should L</writeTables> and then L</populateTables> following
calling L</importTable> to ensure the cached table information matches the
database version.

The sample code would import the Directory table from the file 'Directory.idt'
in the Tables sub-directory of current working directory.

C<importTable> will create an absolute path from the folder path passed in as
the second parameter.

undef will be returned on success and an error string will be returned on
failure.

Note that the table name _SummaryInformation may be used to import the
Summary Information Stream.

=cut

sub importTable {
    my ($self, $table, $path) = @_;

    #define ERROR_FUNCTION_FAILED      1627L // Function failed during execution
    #define ERROR_BAD_PATHNAME               161L
    #define ERROR_INVALID_HANDLE_STATE  1609L
    #define ERROR_INVALID_PARAMETER          87L

    $path = File::Spec->rel2abs($path);

    my $result = $MsiDatabaseImport->Call($self->{handle}, $path, "$table.idt");

    return undef unless $result;
    return _errorMsg();
}


=head3 installService

Install a Win32 service that runs its own process.

    $msi->installService(-serviceName => 'MyService', -Component_ => $component);

At install time a previous instance of the service will be stopped and
uninstalled. The new instance will then be installed and optionally started.

=over

=item I<-serviceName>: required

Name used to identify the service. This must uniquely identify the service on
the target system or unhappy things will happen.

=item I<-Component_>: required

The component that the service file is installed by. This is used by the
installer to ensure the service is installed at the correct time.

=item I<-name>: optional

The name of the service to be installed. If a name is not provided -serviceName
is used.

=item I<-state>: optional

One of 'auto' or 'demand' with 'auto' used by default.

If the state is 'auto' the service will be started at install time and when the
system boots.

=item I<-type>: optional

If the type is supplied it must currently be 'interactive' to set
SERVICE_INTERACTIVE_PROCESS.

SERVICE_WIN32_OWN_PROCESS is assumed.

=item I<-Description>: optional

A brief (fewer than 256 characters) description of the service. -name will be
used by default.

=back

=cut

sub installService {
    my ($self, %params) = @_;
    my %states = (auto => 2, demand => 3, disabled => 4);

    Win32::MSI::HighLevel::Common::require(\%params,
        qw(-serviceName -Component_));
    Win32::MSI::HighLevel::Common::allow(\%params,
        qw(-serviceName -name -state -Component_ -Description));

    $params{-name}        ||= $params{-serviceName};
    $params{-Description} ||= $params{-name};
    $params{-state}       ||= 'auto';
    $params{-state} = $states{lc $params{-state}} || 2;

    my $type = 0x10;    # SERVICE_WIN32_OWN_PROCESS

    $type |= 0x100 if lc $params{-type} eq 'interactive';

    my %instParams = (
        -ServiceInstall => $params{-serviceName},
        -Component_     => $params{-Component_},
        -Name           => $params{-name},
        -ServiceType    => $type,
        -StartType      => $params{-state},
        -ErrorControl   => 1,
        -Description    => $params{-Description},
        );

    my $result = $self->_addServiceInstallRow(\%instParams);
    my $eventBits = 0xAA; # Full start/stop and delete/install processing

    $eventBits |= 0x01 if $params{-state} == 2; # Autostart

    my %ctrlParams = (
        -ServiceControl => $params{-serviceName},
        -Component_     => $params{-Component_},
        -Name           => $params{-name},
        -Event          => $eventBits,
        );

    $result = $self->_addServiceControlRow(\%ctrlParams);
    return;
}


=head3 option

Set various optional behavior.

=over

=item fixExtraSep

Fix the separator bug which can generates bogus identifiers for Component names
and in other situations. Note that this can lead to components with different
names in installers where this setting has changed state and lead to bad
behavior when updating installed components.

=back

=cut

sub option {
    my ($self, $option, $value) = @_;

    if ($option eq 'fixExtraSep') {
        $self->{extraSep} = '.';
        return;
    }

    die "Invalid option type passed to option: $option\n";
}


=head3 populateTables

Read the current .msi file and build an internal representation of it.

An optional boolean parameter may be passed. If set true C<populateTables> will
warn about any table files it finds that it doesn't know how to generate an
internal representation for. Such unknown tables can not be manipulated and will
be written to the output unchanged.

=cut

sub populateTables {
    my ($self, $warn) = @_;
    my $tables = $self->view(-table => '_Tables');

    while (my $tableName = $tables->fetch()) {
        my $name = $tableName->string('Name');

        $self->{tables}{$name} ||= {_created => 1};
        if (   !exists $self->{knownTables}{$name}
            or !defined $self->{knownTables}{$name})
        {
            warn "Don't know how to populate $name tables"
                if $warn and !exists $self->{knownTables}{$name};
            $self->{knownTables}{$name} = undef;    # Only warn about entry once
            next;
        }

        my $table = $self->view(-table => $name);

        while (my $rec = $table->fetch()) {
            $rec->populate();
            $rec->{state} = Win32::MSI::HighLevel::Record::kClean;
            $self->{knownTables}{$name}->($self, $rec);
        }
    } continue {
        $tableName = 0;
    }

    # Fix any missing File table information
    my $fileTable = $self->{tables}{File};
    for my $fileId (keys %{$fileTable}) {
        my $row = $fileTable->{$fileId};

        next unless ref $row;
        unless (defined $row->{-FileSize}) {
            my $fullPath = $self->_getFullFilePath($row);

            $row->{-FileSize} = -s $fullPath || undef;
        }

        $row->{-Attributes} ||= 0;
    }

    $tables = 0;
}


=head3 registerExtension

Add table entries to register a file extension and hook it up to an application.
Note that Extension, ProgId and Verb tables may be affected by this call
depending on the parameters supplied.

    $msi->registerExtension (
        -Extension => 'myext',
        -Component_ => $componentId,
        -ProgId => 'MyApp.Data.1',
        -Feature_ => $featureId,
        -Description => 'MyApp data file',
        -Verb => 'Open',
        -Argument => '%1',
        );

=over 4

=item I<-Argument>: optional

Command line argument to be used when launching the application. %1 may be used
to pass the file on the command line.

=item I<-Component_>: required

Id of the component that controls installation of the extension.

=item I<-Extension>: required

File extension (excluding the .) that is to be registered.

If multiple extensions need to be mapped to the same ProgId an array reference
may be used for the value of this parameter:

    $msi->registerExtension (..., -Extension => [qw(myext1 myext2)], ...);

=item I<-Description>: optional

Text that is shown in explorer for the file type.

=item I<-Feature_>: required

Feature that supplies the application associated with the extension.

=item I<-Icon_>: optional

Entry in the Icon table that supplies an icon used for files of this type.

=item I<-iconFile>: optional

Path to the file containing the icon referred to by I<-IconIndex>.

Note that the file name must be a unique icon file name independently of the
path and must only contain alphanumeric characters, periods and underscores.
This is because I<registerExtension> forms an ID that is used internally to
identify the specific icon file. Multiple extensions may use the same icon file
so it is important that I<registerExtension> can generate a one to one mapping
between the file name and the internally generated ID.

=item I<-IconIndex>: optional

Index to the icon resource in the file provided by the I<-Icon_> table entry
(which may be provided using I<-iconFile>).

=item I<-MIME_>: optional

MIME table Content Type entry specifying the MIME type of the contents of files
of this extension.

A C<-MIMECLSID> is required if this parameter is supplied.

=item I<-MIMECLSID>: optional

CLSID for the COM server that is associated with the MIME type for files of this
extension type.

This parameter is required only if a C<-MIME_> parameter is provided.

=item I<-ProgId_>: optional

ProgId table entry for the application associated with the file extension.

Note that several extensions may reference the same ProgId. However, if more
than one extension references the same ProgId the I<-Description> and I<-Icon*>
parameters for the first registered (or pre-existing) entry is used.

=item I<-ProgId_Parent>: optional

=item I<-Verb>: optional

Explorer's right click menu entry text for an action associated with files of
this type.

If a I<-Verb> parameter is supplied a I<-ProgId_> is required also.

=back

=cut

sub registerExtension {
    my ($self, %params) = @_;
    my $table = $self->{tables}{Registry} ||= {};
    my @return;

    Win32::MSI::HighLevel::Common::require(\%params,
        qw(-Component_ -Extension -Feature_));
    Win32::MSI::HighLevel::Common::allow(
        \%params,
        qw(-Argument -Component_ -Extension -Description -Feature_ -Icon_
            -iconFile -IconIndex -MIME_ -ProgId_ -ProgId_Parent -Verb)
            );

    $self->autovivifyTables(qw(Extension ProgId Verb));

    $params{-Extension} = [$params{-Extension}]
        unless 'ARRAY' eq ref $params{-Extension};

    croak
        "Component id must exist before a file extension is hooked up referencing is"
        unless exists $self->{tables}{Component}{lc $params{-Component_}};
    croak
        "Feature id must exist before a file extension is hooked up referencing is"
        unless exists $self->{tables}{Feature}{lc $params{-Feature_}};

    # Update the Extension table for each extension
    for my $extension (@{$params{-Extension}}) {
        my %rec = (
            -Extension  => $extension,
            -Component_ => $params{-Component_},
            -Feature_   => $params{-Feature_},
            );

        $rec{-ProgId_} = $params{-ProgId_} if exists $params{-ProgId_};
        $rec{-MIME_}   = $params{-MIME_}   if exists $params{-MIME_};

        $rec{-lu} = "$params{-Component_}/$extension";
        push @return, $self->_addRow('Extension', 'lu', \%rec);

        # Update the MIME table if required
        if (exists $params{-MIME_}) {
            my %rec = (
                -Extension_  => $extension,
                -ContentType => $params{-MIME_},
                -CLSID       => $params{-MIMECLSID},
                );

            $rec{-lu} = "$params{-ContentType}/$extension";
            $self->_addRow('MIME', 'lu', \%rec);
        }

        # Update the Verb table if required
        if (exists $params{-Verb}) {
            my %rec = (-Extension_ => $extension, -Verb => $params{-Verb});

            $rec{-Sequence} = $params{-Sequence}
                if exists $params{-Sequence};
            $rec{-Command}  = $params{-Command}  if exists $params{-Command};
            $rec{-Argument} = $params{-Argument}
                if exists $params{-Argument};

            $rec{-lu} = "$extension/$params{-Verb}";
            $self->_addRow('Verb', 'lu', \%rec);
        }
    }

    croak
        "An -IconIndex and either a -iconFile or -Icon_ parameter must be provided if any are provided"
        unless Win32::MSI::HighLevel::Common::noneOf(\%params,
        qw(-iconFile -IconIndex -Icon_))
        or exists $params{-IconIndex}
        && 1 ==
        Win32::MSI::HighLevel::Common::someOf(\%params, qw(-iconFile -Icon_));

    if (exists $params{-iconFile}) {
        # Create Icon table entry if required and generate icon Id
        $params{-Icon_} = $self->addIconFile($params{-iconFile});
    }

    if (exists $params{-ProgId_}) {
        # Update the ProgId table
        my %rec = (-ProgId => $params{-ProgId_});

        $rec{-ProgId_Parent} = $params{-ProgId_Parent}
            if exists $params{-ProgId_Parent};
        $rec{-Class_} = $params{-Class_} if exists $params{-Class_};
        $rec{-Description} = $params{-Description}
            if exists $params{-Description};
        $rec{-Icon_}     = $params{-Icon_}     if exists $params{-Icon_};
        $rec{-IconIndex} = $params{-IconIndex}
            if exists $params{-IconIndex};

        $self->_addRow('ProgId', 'ProgId', \%rec);
    }

    return @return;
}


=head3 setProduct

Set various product related information.

    $msi->setProduct (
        -Language => 1033,
        -Name => 'Wibble',
        -Version => '1.0.0',
        -Manufacturer => 'Wibble Mfg. Co.'
        );

For a new installer this should be called before any addComponent calls are made
as information from the product details is used to generate information required
to generate component table entries.

Property table entries are generated or updated by this call. In addition to the
properties discussed in conjunction with the parameters described below, a
ProductCode value is generated and added to the Property table.

The product code value is returned.

=over 4

=item I<-Name>: required

Product name.

=item I<-Manufacturer>: required

Manufacturer's name.

=item I<-Language>: required

Language code (LangId).

=item I<-Version>: required

Product version

=item I<-upgradeCode>: optional

A GUID that will be used as the UpgradeCode for Upgrade table entries and is
used as part of the string used to generate Component GUIDs.

If not provided C<setProduct> will generate an UpgradeCode GUID using the
-Name and -Manufacturer values. By default this will allow different language
version of a product to be upgraded interchangeably.

Do not include version information in -Name if you rely on the default
UpgradeCode GUID generation unless the version information is invariant across
all product versions you expect to be able to upgrade. For most upgrade purposes
this means that including a major version number in the name is OK, but
including a minor version number is not.

=back

=cut

sub setProduct {
    my ($self, %params) = @_;
    my $table = $self->{tables}{Property} ||= {};

    Win32::MSI::HighLevel::Common::require(\%params,
        qw(-Language -Manufacturer -Name -Version));
    Win32::MSI::HighLevel::Common::allow(\%params,
        qw(-Language -Manufacturer -Name -upgradeCode -Version));

    my $guid = $params{-upgradeCode};

    if (!$guid) {
        my $prodStr = "$params{-Manufacturer} $params{-Name}";

        $guid = Win32::MSI::HighLevel::Common::genGUID($prodStr);
    }

    $self->setProperty(-Property => 'UpgradeCode', -Value => $guid);
    $self->setProperty(
        -Property => 'ProductLanguage',
        -Value    => $params{-Language}
        );
    $self->setProperty(-Property => 'ProductName', -Value => $params{-Name});
    $self->setProperty(
        -Property => 'ProductVersion',
        -Value    => $params{-Version}
        );
    $self->setProperty(
        -Property => 'Manufacturer',
        -Value    => $params{-Manufacturer}
        );

    return $self->_genProductCode();
}


=head3 setProperty (see also L</addProperty>)

Set a property value in the Property table. The property is added if it didn't
exist already.

    $msi->setProperty (-Property => 'Manufacturer', -Value => 'Wibble Corp.');

The previous value is returned or C<undef> is returned if a new property is
added.

=over 4

=item I<-Property>: required

Property name

=item I<-Value>: required

Property value

=back

=cut

sub setProperty {
    my ($self, %params) = @_;
    my $table = $self->{tables}{Property} ||= {};

    Win32::MSI::HighLevel::Common::require(\%params, qw(-Property -Value));
    Win32::MSI::HighLevel::Common::allow(\%params, qw(-Property -Value));

    if (exists $table->{lc $params{-Property}}) {
        my $property = $table->{lc $params{-Property}};

        $property->{-Value} = $params{-Value};
        $property->{state} = Win32::MSI::HighLevel::Record::kDirty;
        return $property->{-Property};
    } else {
        return $self->addProperty(%params);
    }
}


=head3 setTableEntryField

Sets specified fields in an existing table entry.

    $msi->setTableEntryField (
        'Control',
        {-Dialog_ => 'Start_Installation_Dialog', -Control => InstallNow},
        {-Text => 'Install'}
        );

The first hash ref parameter must include entries for all the table's key
fields.

Note that this method provides fairly raw access to table entries and does not
perform very much validation. In particular fields that are linked to other
tables should not be altered using L</setTableEntryField>!

=cut

sub setTableEntryField {
    my ($self, $table, $keys, $values) = @_;
    my $key = join '/', map {$keys->{$_}} sort keys %$keys;

    croak "No table: $table" unless exists $self->{tables}{$table};
    croak "No entry $key for table $table"
        unless exists $self->{tables}{$table}{lc $key};

    my $entry = $self->{tables}{$table}{lc $key};

    exists $entry->{$_}
        or croak "Field $_ does not exist in $key entry for $table table"
        for keys %$values;

    $entry->{$_} = $values->{$_} for keys %$values;
    $entry->{state} = Win32::MSI::HighLevel::Record::kDirty;
    return $entry;
}


=head3 tableRows

Returns the count of the rows in a given table.

    my $count = $msi->tableRows ('File');

A single parameter giving the name of the table is required. C<undef> is
returned if the table does not exist.

=cut

sub tableRows {
    my ($self, $table) = @_;

    return undef unless exists $self->{tables}{$table};
    return scalar grep /^[^_]/, keys %{$self->{tables}{$table}};
}


=head3 updateTableEntry

Update the table column data for a table entry obtained using getTableEntry.

    my $entry = $msi->getTableEntry ('File', {-File => 'wibble.exe'});

    $entry->{-File} = 'Wibble.exe';
    $msi->updateTableEntry ($entry);

Use with caution. In particular, do not create new keys in the hash.

=cut

sub updateTableEntry {
    my ($self, $entry) = @_;

    croak "Invalid table entry"
        unless defined $entry
            and exists $entry->{state}
            and exists $entry->{'!name'};

    my $name = $entry->{'!name'};
    my $key  = $entry->{'!key'};
    my $lu   = $entry->{'!lu'};
    croak "Don't know how to update $name tables"
        unless exists $self->{knownTables}{$name};

    # Delete previous table entry
    $self->_deleteRow($name, $key, $lu);
    delete $entry->{'!lu'};
    delete $entry->{'!key'};
    delete $entry->{'!name'};

    # Add the updated table entry
    $entry->{state} = Win32::MSI::HighLevel::Record::kNew;
    $self->{knownTables}{$name}->($self, $entry);
}


=head3 view

Creates a Win32::MSI::HighLevel::View into the database.

    my $view = $msi->view (-table => 'Feature');

Generally other ways of manipulating the database are more useful than through a
view. However a Win32::MSI::HighLevel::View can be created to search tables for specific information
using the C<-columns>, C<-where>, C<-order> and C<-tables> parameters to return
selected records.

=cut

sub view {
    my ($self, %params) = @_;

    $params{-columns} ||= ['*'];
    Win32::MSI::HighLevel::Common::listize(\%params, qw(column table));
    Win32::MSI::HighLevel::Common::require(\%params, qw(-tables));
    Win32::MSI::HighLevel::Common::allow(\%params,
        qw(-columns -order -tables -table -where));

    my $query = "SELECT " . join(', ', @{$params{-columns}});

    $query .= " FROM " . join(', ', @{$params{-tables}});
    $query .= " WHERE $params{-where}" if exists $params{-where};
    $query .= " ORDER BY " . join(', ', @{$params{-order}})
        if exists $params{-order};

    return Win32::MSI::HighLevel::View->new($self, %params, query => $query);
}


=head3 writeTables

Write changes that have been made to the tables using the add* members. Until
writeTables is called the changes that have been made are cached in memory.
writeTables writes these changes through to the .msi database in preparation for
a L</commit>.

L</writeTables> also updates the SecureCustomProperties property with Upgrade
table L</-ActionProperty_> properties.

=cut

sub writeTables {
    my $self = shift;

    # First update SecureCustomProperties
    my $scp = $self->getProperty('SecureCustomProperties') || '';
    my %properties = map {$_ => 1} split ';', $scp;

    for my $tableColumn (
        [Upgrade                => '-ActionProperty'],
        [LaunchCondition        => '-secureProperties'],
        [InstallExecuteSequence => '-secureProperties'],
        )
    {
        my ($table, $column) = @$tableColumn;

        next unless exists $self->{tables}{$table};
        for my $entry (keys %{$self->{tables}{$table}}) {
            my $row = $self->{tables}{$table}{$entry};

            next if ! ref $row || ! exists $row->{$column};
            next if $entry =~ /^_/;    # Ignore flags

            $properties{$row->{$column}} = 1;
        }
    }

    $scp = join ';', sort keys %properties;
    $self->setProperty(-Property => 'SecureCustomProperties', -Value => $scp)
        if length $scp;

    for my $tableName (sort keys %{$self->{tables}}) {
        $self->createTable(-table => $tableName)
            unless _readonlyTable($tableName)
                or exists $self->{tables}{$tableName}{_created};

        my $table = $self->view(-table => $tableName);
        my $fieldHash = $self->{tables}{$tableName};

        croak "Table $tableName requires a root entry but none was provided"
            if exists $fieldHash->{_root} and !defined $fieldHash->{_root};

        print "Updating table $tableName\n"
            if $self->{-noisy} & kReportUpdates;

        my $rec = $table->createRecord();

        # Add/update/delete rows
        for my $key (sort keys %$fieldHash) {
            next if $key =~ /^(_|-[a-z])/;
            my $rowData = $fieldHash->{$key};

            next
                if defined $rowData->{state}
                    and $rowData->{state} ==
                    Win32::MSI::HighLevel::Record::kClean;

            my @columns = map {my $k = $_; $k =~ s/^-//; $k}
                grep {/^-[A-Z]/}
                keys %$rowData;

            defined $rowData->{"-$_"}
                and $rec->setValue($_, $rowData->{"-$_"})
                for @columns;
            $rec->{state} = $rowData->{state};

            $key ||= '<null>';

            if ($rowData->{state} == Win32::MSI::HighLevel::Record::kDelete) {
                (my $realKey = $key) =~ s/^\*//;
                print "Deleting: $tableName/$realKey\n"
                    if $self->{-noisy} & kReportUpdates;
            } else {
                print "Writing: $tableName/$key\n"
                    if $self->{-noisy} & kReportUpdates;
            }
            $rowData->{state} == Win32::MSI::HighLevel::Record::kNew
                ? $rec->insert()
                : $rec->update();

            if ($rec->getState() == Win32::MSI::HighLevel::Record::kDelete) {
                delete $fieldHash->{$key};
            } else {
                $rowData->{state} = $rec->getState();
            }

            $rec->clearFields();
            next;
        }
    }

    return 1;
}


# _addXxxRow routines handle adding table row information to the internal
# representation of the database. They call through to _addRow which expects a
# table name, row look up key name (excluding - prefix), the record and an
# optional auxiliary look up string. See _addRow for look up key details.

sub _addBinaryRow {
    my ($self, $rec) = @_;

    return $self->_addRow('Binary', 'Name', $rec, $rec->{-Name});
}


sub _addAppSearchRow {
    my ($self, $rec) = @_;

    _genLu($rec, qw(Property Signature_));
    return $self->_addRow('AppSearch', 'lu', $rec);
}


sub _addComponentRow {
    my ($self, $rec) = @_;

    return $self->_addRow('Component', 'Component', $rec,
        "$rec->{-Directory_}/$rec->{-KeyPath}");
}


sub _addConditionRow {
    my ($self, $rec) = @_;

    return $self->_addRow('Feature_', 'Feature_', $rec);
}


sub _addControlRow {
    my ($self, $rec) = @_;

    _genLu($rec, qw(Control Dialog_));
    return $self->_addRow('Control', 'lu', $rec);
}


sub _addControlConditionRow {
    my ($self, $rec) = @_;

    _genLu($rec, qw(Control_ Dialog_ Action Condition));
    return $self->_addRow('ControlCondition', 'lu', $rec);
}


sub _addControlEventRow {
    my ($self, $rec) = @_;

    _genLu($rec, qw(Argument Condition Control_ Dialog_ Event));
    return $self->_addRow('ControlEvent', 'lu', $rec);
}


sub _addCreateFolderRow {
    my ($self, $rec) = @_;

    _genLu($rec, qw(Component_ Directory_));
    return $self->_addRow('CreateFolder', 'lu', $rec);
}


sub _addCustomActionRow {
    my ($self, $rec) = @_;

    return $self->_addRow('CustomAction', 'Action', $rec);
}


sub _addDialogRow {
    my ($self, $rec) = @_;

    return $self->_addRow('Dialog', 'Dialog', $rec);
}


sub _addDirectoryRow {
    my ($self, $rec) = @_;

    _checkId($rec->{-Directory});
    _checkId($rec->{-Directory_Parent})
        if length $rec->{-Directory_Parent};

    if (   $rec->{-Directory} eq 'TARGETDIR'
        && $rec->{-DefaultDir} eq 'SourceDir'
        && !length $rec->{-Directory_Parent})
    {
        my $table = $self->{tables}{Directory};

        $table->{_root} = $rec->{-Directory};
        _checkId($rec->{-DefaultDir});
    } else {
        _checkDefaultDir($rec->{-DefaultDir});
    }

    my $lu = $rec->{-Directory};
    $lu ||= ":root:";
    $lu .= "/$rec->{-Directory_Parent}";

    return $self->_addRow('Directory', 'Directory', $rec, $lu);
}


sub _addDrLocator {
    my ($self, $rec) = @_;

    return $self->_addRow('DrLocator', 'Signature_', $rec);
}


sub _addMsiDriverPackagesRow {
    my ($self, $rec) = @_;

    return $self->_addRow('MsiDriverPackages', 'Component', $rec);
}


sub _addFeatureRow {
    my ($self, $rec) = @_;

    $self->{tables}{Feature} ||= {};

    unless (defined $rec->{-Feature_Parent}
        and length $rec->{-Feature_Parent})
    {
        my $table = $self->{tables}{Feature};

        $table->{_root} = $rec->{-Feature};
    }

    $rec->{-name} ||= $rec->{-Feature};
    return $self->_addRow('Feature', 'Feature', $rec, $rec->{-name});
}


sub _addFeatureComponentsRow {
    my ($self, $rec) = @_;

    _genLu($rec, qw(Component_ Feature_));
    return $self->_addRow('FeatureComponents', 'lu', $rec, $rec->{-lu});
}


sub _addFileRow {
    my ($self, $rec) = @_;
    my $files = $self->{tables}{File};

    $rec->{-Sequence} = $self->_nextSeqNum($rec->{-File}, $rec->{-Sequence});
    $self->_addRow('File', 'File', $rec,
        "$rec->{-Component_}/$rec->{-FileName}");
    return $rec->{-File};
}


sub _addIconRow {
    my ($self, $rec) = @_;

    return $self->_addRow('Icon', 'Name', $rec);
}


sub _addInstallExecuteSequenceRow {
    my ($self, $rec) = @_;

    return $self->_addRow('InstallExecuteSequence', 'Action', $rec,
        $rec->{-Sequence});
}


sub _addInstallUISequenceRow {
    my ($self, $rec) = @_;

    return $self->_addRow('InstallUISequence', 'Action', $rec,
        $rec->{-Sequence});
}


sub _addLaunchConditionRow {
    my ($self, $rec) = @_;

    return $self->_addRow('LaunchCondition', 'Condition', $rec,
        $rec->{-Sequence});
}


sub _addMediaRow {
    my ($self, $rec) = @_;

    return $self->_addRow('Media', 'DiskId', $rec, "$rec->{-Cabinet}");
}


sub _addPropertyRow {
    my ($self, $rec) = @_;

    $self->_addRow('Property', 'Property', $rec, $rec->{-Property});
    return $rec->{-Property};
}


sub _addRegistryRow {
    my ($self, $rec) = @_;

    _genLu($rec, qw(Key Name Root));
    $self->_addRow('Registry', 'lu', $rec, $rec->{-lu});
    return $rec->{-Registry};
}


sub _addRegLocatorRow {
    my ($self, $rec) = @_;

    $self->_addRow('RegLocator', 'Signature_', $rec);
    return $rec->{-Registry};
}


# $key must be a key into the hash referenced by $rec. Often it will be a table
# field. Where more than one field is a key field a synthetic key may be
# generated by:
#   _genLu ($rec, qw(Key1 Key2 ...));
# and 'lu' is passed in as the $key value.
# The key entries MUST be sorted by column name!

# Where a lookup by something other than the table key is required the $lu
# parameter may be provided. A {lookup}{tableName}{$lu} entry is then generated
# to provide a mapping from the lookup key to the actual table entry.

# Note that keys that match /^(_|-[a-z])/ are retained by _addRow but are
# ignored by table processing.

sub _addRow {
    my ($self, $tableName, $key, $rec, $lu) = @_;
    my $table = $self->{tables}{$tableName} ||= {};
    my $hashKey = lc $rec->{"-$key"};

    croak "-$key missing from $tableName table entry.\n"
        . "This may be a HighLevel bug where '-lu' should be used for the lookup key"
        unless exists $rec->{-$key};

    if (exists $table->{$hashKey}) {
        croak
            "Duplicate $key $rec->{-$key} entry not allowed in $tableName table"
            unless $rec->{skipDup};

        return $rec->{-$key};
    }

    my @keys = grep {/^-/} keys %$rec;

    @{$table->{$hashKey}}{@keys} = @{$rec}{@keys};

    if (defined $lu) {
        $lu                                          = lc $lu;
        $self->{lookup}{$tableName}{$lu}                  = $hashKey;
        $self->{id_idToKey}{$tableName}{lc $rec->{-$key}} = $lu;
    }

    if ($rec->{state}) {
        $table->{$hashKey}{state} = $rec->{state};
    } else {
        $table->{$hashKey}{state} = Win32::MSI::HighLevel::Record::kNew;
    }
    return $rec->{-$key};
}


sub _addSelfRegRow {
    my ($self, $rec) = @_;

    return $self->_addRow('SelfReg', 'File_', $rec);
}


sub _addServiceControlRow {
    my ($self, $rec) = @_;

    return $self->_addRow('ServiceControl', 'ServiceControl', $rec);
}


sub _addServiceInstallRow {
    my ($self, $rec) = @_;

    return $self->_addRow('ServiceInstall', 'ServiceInstall', $rec);
}


sub _addShortcutRow {
    my ($self, $rec) = @_;

    _genLu($rec, qw(Directory_ Target));
    return $self->_addRow('Shortcut', 'Shortcut', $rec, $rec->{-lu});
}


sub _addSignatureRow {
    my ($self, $rec) = @_;

    return $self->_addRow('Signature', 'Signature', $rec, $rec->{-Signature});
}


sub _addStorageRow {
    my ($self, $rec) = @_;

    return $self->_addRow('_Storages', 'Name', $rec, $rec->{-Name});
}


sub _addUpgradeRow {
    my ($self, $rec) = @_;

    _genLu($rec, qw(UpgradeCode VersionMin VersionMax Language Attributes));
    return $self->_addRow('Upgrade', 'lu', $rec, $rec->{-lu});
}


#sub _getFullSourceDirPath {
#    my ($self, $dir) = @_;
#    my $dirTable = $self->{tables}{Directory};
#    my @path;
#
#    $dir = $dir->{-Directory} if ref $dir;
#
#    while (defined $dir and exists $dirTable->{$dir}) {
#        my $entry = $dirTable->{$dir};
#        my $parent = $entry->{-Directory_Parent};
#        my $defDir = $entry->{-DefaultDir};
#        my ($sourceDir, $targetDir) = $entry->{-DefaultDir} =~ /^(\S+?)(?::(.*))?$/;
#
#        $sourceDir ||= $targetDir;
#        $dir = $parent;
#
#        next if $sourceDir eq '.';
#
#        my @pair = @{$self->_dirPair ($sourceDir)};
#
#        $sourceDir = $pair[1];
#        $sourceDir = $pair[0] unless length $sourceDir;
#        $sourceDir = $self->{-SourceRoot} if $sourceDir eq 'SOURCEDIR';
#
#        unshift @path, $sourceDir;
#    }
#
#    return join '\\', @path;
#}


sub _buildDirLookup {
    my $self = shift;

    return if exists $self->{tables}{Directory}{_byDir};

    # Build directory lookup hashes from existing table entries
    for my $Directory (keys %{$self->{tables}{Directory}}) {
        next if $Directory =~ /^_/;    # Skip special entries

        my $row = $self->{tables}{Directory}{$Directory};
        my ($targetDir, $sourceDir) =
            $row->{-DefaultDir} =~ /^([^:]+)(?::(.*))?$/;
        my $parent = $row->{-Directory_Parent};

        $sourceDir ||= $targetDir;
        if (!defined $sourceDir or !defined $targetDir) {
            croak("Directory information not available.");
        }
        $sourceDir = $self->_dirPair($sourceDir);
        $targetDir = $self->_dirPair($targetDir);

        $self->{DirLookup}{lc $sourceDir->[1]}{$row->{-Directory}} = $row;
        $self->{DirLookup}{lc $sourceDir->[0]}{$row->{-Directory}} = $row
            if lc $sourceDir->[1] ne lc $sourceDir->[0];

        my $id  = $row->{-Directory};
        my $key = $sourceDir->[1];

        $self->{id_idToKey}{$id}  = $key;
        $self->{id_keyToId}{$key} = $id;
    }

    $self->{tables}{Directory}{_byDir} = 1;
}


sub _checkId {
    my $id = shift;

    croak "Invalid Identifier: $id"
        unless $id =~ /^[_a-z][\w.]*$/i;
}


sub _checkDefaultDir {
    my ($dir) = @_;

    Carp::croak() unless defined $dir;

    my ($target, $source) = $dir =~ /(^[^:]+)(?::(.*))?$/;

    _checkFilename($target, 'Target directory') unless $target eq '.';
    _checkFilename($source, 'Source directory')
        if defined $source;
}


sub _checkFilename {
    my ($filename, $type) = @_;
    my $badLong  = '\?|><:/*"';
    my $badShort = "$badLong+,;=[] \t\n\r";
    my ($short, $long) = $filename =~ /(^[^|]+)(?:\|(.*))?$/;

    $short = '' unless defined $short;
    $type ||= 'Filename';
    croak "Invalid $type (bad short filename character): '$filename'."
        if $short =~ /[$badShort]/;
    croak "Invalid $type (bad short filename 8.3 format): '$filename'."
        if $short !~ /^[^.]{0,8}(?:\.[^.]{0,3})?$/;
    croak "Invalid $type (short filename must be provided): '$filename'."
        if !length $short;
    croak
        "Invalid $type (bad long filename character). None of $badLong allowed: '$filename'."
        if defined $long and $long =~ /[$badLong]/;
}


sub _deleteRow {
    my ($self, $name, $key, $lu) = @_;
    my $rec = $self->{tables}{$name}{$key};

    if ($self->{tables}{$name}{$key}{state} >
        Win32::MSI::HighLevel::Record::kNew)
    {
        # Schedule DB row for deletion
        $self->{tables}{$name}{$key}{state} =
            Win32::MSI::HighLevel::Record::kDelete;
        $self->{tables}{$name}{"*$key"} = {%{$self->{tables}{$name}{$key}}};
    }
    delete $self->{tables}{$name}{$key};

    if (defined $lu) {
        $lu = lc $lu;
        delete $self->{lookup}{$name}{$lu} if exists $self->{lookup}{$name};
        delete $self->{id_idToKey}{$name}{$rec->{-$key}}
            if exists $self->{id_idToKey}{$name};
    }
}


sub _dirPair {
    my ($self, $pairStr) = @_;
    my ($short, $long) = $pairStr =~ /([^|]+)\|?(.*)/;

    $long                             ||= $short;
    $short                            ||= $self->{dp_longToShort}{lc $long};
    $short                            ||= $self->_longToShort($long);
    $self->{dp_longToShort}{lc $long} ||= $short;

    return [$short, $long];
}

sub _findFileId {
    my ($self, $target) = @_;
    my ($path, $file) = $target =~ m!(.*)[\\/](.*)!;

    $file = lc $file;
    $path = lc $path;

    my @candidates =
        grep {lc($self->{tables}{File}{$_}{-FileName}) eq $file}
        grep {$_ !~ /^_/} keys %{$self->{tables}{File}};
    my $match;

    for my $fileId (@candidates) {
        next unless lc $self->{tables}{File}{$fileId}{-targetDir} eq $path;
        $match = $file;
        last;
    }

    return $match;
}


# _genLu generates a lookup string for the key fields in a table.
# If a single 'key' is passed in a table name is assumed and the key
# list is generated.
# If multiple keys are passed in they are used directly.
sub _genLu {
    my ($rec, @keys) = @_;

    @keys = createTable(0, _keys => $keys[0]) if @keys == 1;

    !defined $rec->{"-$_"} and $rec->{"-$_"} = '' for @keys;
    $rec->{-lu} = join '/', map $rec->{"-$_"}, sort @keys;
}


sub _genProductCode {
    my ($self)       = @_;
    my $manufacturer = $self->getProperty('Manufacturer');
    my $language     = $self->getProperty('ProductLanguage');
    my $name         = $self->getProperty('ProductName');
    my $version      = $self->getProperty('ProductVersion');

    return
        if grep {!defined} ($manufacturer, $language, $name, $version);

    $self->{prodNamespace} = "$manufacturer/$language/$name/$version";

    my $prodCode =
        Win32::MSI::HighLevel::Common::genGUID($self->{prodNamespace});

    $self->setProperty(-Property => 'ProductCode', -Value => $prodCode);
    $self->{productCode} = $prodCode;
    return $prodCode;
}


sub _getFullFilePath {
    my ($self, $file) = @_;

    return $file->{-path} if exists $file->{-path};
    return undef;
}


# Generate a unique Id to be used as a table key entry.
#
# $id is a source id - often a file name or user supplied id
# $context is generally a table name
# $length is the maximum generated id length
# $extra may be provided to disambiguate between id's - often a file path

sub _getUniqueID {
    # $context should be the bare table name if the id is a table key (eg
    # 'File')
    my ($self, $reqId, $context, $length, $extra) = @_;
    my $id = $reqId;
    my $key;

    return $self->{id_keyToId}{$context}{$key}
        if $self->_haveUniqueId($id, $context, $extra, $key);

    $length ||= 38;
    $id =~ tr/a-zA-Z0-9_.//cd;
    $id =~ s/^[\d.]+//;
    $id = substr $id, 0, $length;

    Carp::croak "'$reqId' can not be used as an id.\n"
        . "   An id must only contain letters, digits, _ and . characters and\n"
        . "   must start with a letter. Characters not allowed in an id have\n"
        . "   been removed from the requested id"
        if !length $id;

    my $lcId = lc $id;

    while (exists $self->{id_idToKey}{$context}{$lcId}) {
        if ($id =~ /(?<!\d)9+$/) {
            $id =~ s/(9+)$/"1" . ('0' x length $1)/e;
        } else {
            my ($digits) = $id =~ /(?<=_)(\d+)/;

            if (!defined $digits or !length $digits) {
                $id .= '_0';
                $digits = 0;
            }

            $id =~ s/(?<=_)(\d+)/$digits + 1/e;
        }

        $lcId = lc $id;
    }

    $self->{id_idToKey}{$context}{$lcId} = $key;
    $self->{id_keyToId}{$context}{$key}  = $id;
    return $id;
}


# Check to see if an id has been generated already for a given context.
# Sets $key
sub _haveUniqueId {
    $_[2] ||= 'global' unless defined $_[2];    # Init $context

    my ($self, $id, $context, $extra) = @_;
    $extra ||= '';

    my $key = lc "$id$self->{extraSep}$extra";

    $key =~ s/^[^|]*\|//;    # Retain only long file name portion
    $_[4] = $key if exists $_[4];    # 'Return' key
    if (exists $self->{id_keyToId}{$context}{$key}) {
        return $self->{id_keyToId}{$context}{$key};
    } else {
        return undef;
    }
}


sub _longAndShort {
    my ($self, $long) = @_;
    my $short = $self->_longToShort($long);

    return $short if $short eq $long;
    return "$short|$long";
}


sub _longToShort {
    my ($self, $long) = @_;

    return $self->{dp_longToShort}{lc $long}
        if exists $self->{dp_longToShort}{lc $long};

    my $short = $long;
    unless ($short =~
        /^([^\0-\037<>:;.,="\/\|[\] ]){1,8}(\.[^\0-\037<>:;.,="\/\|[\] ]{1,3})?$/
        )
    {
        $short = uc $short;

        # Remove bad characters
        $short =~ s/[\0-\037<>:;,="\/\|[\] ]//g;

        # Remove all except the last full stop
        $short =~ s/\.(?=.*\.)//g;

        # Truncate to 6.3 with ~1 appended to the name part
        $short =~
            s/^(.{1,6})(?:(?!(?=\.[^.]*$)).)*(\..{1,3}|)(?:[^.]*)$/$1~1$2/;

        while (exists $self->{dp_shortToLong}{$short}) {
            if ($short =~ /~9+(?=[^\d])/) {
                $short =~ s/(.*)\w~(\d+)/"$1~1" . ('0' x length $2)/e;
            } else {
                my ($digits) = $short =~ /(?<=~)(\d+)/;
                $short =~ s/(?<=~)(\d+)/$digits + 1/e;
            }
        }
    }

    $self->{dp_shortToLong}{$short} = $long;
    $self->{dp_longToShort}{lc $long} = $short;
    return $short;
}


sub _readonlyTable {
    my $table = shift;
    return $table =~ /^(_Storages|_Columns|_Streams|_Tables|_TransformView)$/;
}


sub _nextSeqNum {
    my ($self, $fileId, $seed) = @_;
    my $scan = $seed ||= $self->{nextSeqNum}++;
    my $files = $self->{tables}{File};

    while (exists $self->{usedSeqNum}{$scan}) {

        # Move present file up one slot and replace with new file
        my $mvFileId = $self->{usedSeqNum}{$scan};

        $files->{$fileId}{-Sequence}   = $scan;
        $self->{usedSeqNum}{$scan}     = $fileId;
        $files->{$mvFileId}{-Sequence} = ++$scan;
        $self->{usedSeqNum}{$scan}     = $mvFileId;
        $fileId                        = $mvFileId;
    }

    $self->{usedSeqNum}{$seed} = $fileId;
    $self->{highestSeqNum} = $scan
        if $self->{highestSeqNum} < $scan;
    $self->{highestSeqNum} = $self->{nextSeqNum}
        if $self->{highestSeqNum} < $self->{nextSeqNum};

    return $seed;
}

1;

=head1 REMARKS

This module depends on C<Win32::API>, which is used to import the
functions out of the F<msi.dll>. Microsoft's Windows Installer technology must
be installed on your system for this module to work.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-win32-msi-highlevel at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Win32-MSI-HighLevel>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

This module is supported by the author through CPAN. The following links may be
of assistance:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Win32-MSI-HighLevel>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Win32-MSI-HighLevel>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Win32-MSI-HighLevel>

=item * Search CPAN

L<http://search.cpan.org/dist/Win32-MSI-HighLevel>

=back

=head1 ACKNOWLEDGEMENTS

This module was inspired by, and is derived in part from Philipp Marek's
L<http://search.cpan.org/dist/Win32-MSI-DB>.

=head1 AUTHOR

    Peter Jaquiery
    CPAN ID: GRANDPA
    grandpa@cpan.org

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

Microsoft MSDN Installer Database documentation: L<http://msdn.microsoft.com/library/default.asp?url=/library/en-us/msi/setup/installer_database.asp>

=cut
