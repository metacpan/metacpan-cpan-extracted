use strict;
use warnings;

use File::Copy;
use File::Spec;
use Win32::Guidgen;
use lib '../lib';   # For dev folder layout
use Win32::MSI::HighLevel;
use Win32::MSI::HighLevel::Summary;
use Carp qw(verbose);

use constant kManufacturer => 'Home installers inc.';
use constant kSourceFolder => '.\\';
use constant kDefVersion   => '1.0.0';
use constant kDefInFile    => 'InstallerTemplate.msi';
use constant kDefOutFile   => 'InstallMyself.msi';
use constant kDefProduct   => 'Self Installer';
use constant kDefTarget    => 'InstallMyself';
use constant kDefLanguage  => 0x0409;

my $gui = 0;

main ();
exit 0;


sub main {
    my $sourceFolder = kSourceFolder;
    my $version      = kDefVersion;

    for (1 .. $#ARGV) {
        ShowHelp () if $ARGV[$_] =~ /[\/-\\][hH?]/;

        if ($ARGV[$_] =~ m/\\$/) {
            my $sourceFolder = $ARGV[0] || kSourceFolder;

            ShowHelp (-3, "Error finding source folder $sourceFolder\n\n")
                if !-d $sourceFolder;

        } elsif ($ARGV[$_] =~ m/^\d+(\.\d+){1,3}$/) {
            $version = $ARGV[$_];

        } else {
            ShowHelp (-4, "Command line argument not recognised: $ARGV[$_]\n\n")
        }
    }

    $sourceFolder =~ s/\\$//;

    my $main = bless {
        languageCode => kDefLanguage,
        manufacturer => kManufacturer,
        noisy        => 2,
        outfile      => "$sourceFolder\\" . kDefOutFile,
        productName  => kDefProduct,
        productDir   => kDefProduct,
        sourceFolder => $sourceFolder,
        targetFolder => kDefTarget,
        templateFile => "$sourceFolder\\" . kDefInFile,
        version      => $version,
    };

    $main->createTemplate      ();
    $main->build               ();
    $main->updateSummaryStream ($main->{outfile});    # Update the package code GUID
    $main = 0;
}


sub createTemplate {
    # Build template file from exported tables
    my $self = shift;

    # First remove any previous version
    unlink $self->{templateFile} if -f $self->{templateFile};

    # Now generate a new installer database
    my $msi = Win32::MSI::HighLevel->new (
        -file => $self->{templateFile},
        -mode => Win32::MSI::HighLevel::Common::kMSIDBOPEN_CREATE,
    );

    # Fetch list of files from tables sub directory
    opendir my $dirScan, 'tables';
    my @tableFiles = sort tableSort readdir $dirScan;
    closedir $dirScan;

    # Scan the list for table (.idt) files
    for my $file (@tableFiles) {
        next unless -f "tables\\$file" and $file =~ /(.*)\.idt$/;

        my $table = $1;    # Get the table name
        my $result = $msi->importTable ($table, "$self->{sourceFolder}\\tables");

        print "Importing $table\n";
        print "   $result\n" if $result;
    }

    # Create missing standard tables
    $msi->createTable (-table => 'Component');
    $msi->createTable (-table => 'FeatureComponents');
    $msi->createTable (-table => 'Feature');
    $msi->createTable (-table => 'File');

    # Update the database then close it
    $msi->commit ();
    $msi = 0;

    # Copy template database as final database file ready to insert files into
    unlink $self->{outfile} if -f $self->{outfile};
    File::Copy::copy ($self->{templateFile}, $self->{outfile});
}


sub tableSort {
    my $haveA_ = $a =~ /^_/;
    my $haveB_ = $b =~ /^_/;

    # Sort special tables first.
    # In particular _ForceCodepage.idt needs to be before everything else so it
    # actually sets the code page correctly.
    return $a cmp $b if $haveA_ == $haveB_;
    return $haveA_ ? -1 : 1;
}


sub build {
    my $self = shift;

    # Open the installer database to be edited
    $self->{msi} = Win32::MSI::HighLevel->new (
        -file       => $self->{outfile},
        -mode       => Win32::MSI::HighLevel::Common::kMSIDBOPEN_DIRECT,
        -sourceRoot => $self->{sourceFolder},
        -targetRoot => $self->{targetPath},
    );

    $self->{msi}->populateTables ();
    $self->{msi}->setProduct (
        -Language     => $self->{languageCode},
        -Name         => $self->{productName},
        -Version      => $self->{version},
        -Manufacturer => $self->{manufacturer},
    );

    # Retreive various properties or set to defaults
    $self->{ProductName} = $self->{msi}->getProperty ('ProductName')
        unless exists $self->{ProductName}
            or not defined $self->{msi}->getProperty ('ProductName');
    $self->{ProductName} ||= $self->{productName};

    $self->{Manufacturer} = $self->{msi}->getProperty ('Manufacturer')
        unless exists $self->{Manufacturer}
            or not defined $self->{msi}->getProperty ('Manufacturer');
    $self->{Manufacturer} ||= $self->{manufacturer};

    # Add launch conditions
    $self->{msi}->addLaunchCondition (
        -Condition => 'VersionMsi >= "2.0"',
        -Description =>
            '[ProductName] requires Windows Installer 2.0 or later.',
    );

    # Set default target directory
    my $costInitializeStep =
        $self->{msi}
        ->getTableEntry ('InstallUISequence', {-Action => 'CostInitialize'});

    $self->{msi}->addInstallUISequence (
        -Action    => 'SetDefTargetDir',
        -Condition => 'TARGETDIR=""',
        -Sequence  => $costInitializeStep->{-Sequence} - 10,
    );
    $self->{msi}->addCustomAction (
        -Action => 'SetDefTargetDir',
        -Type   => 51,
        -Source => 'TARGETDIR',
        -Target => "[ProgramFilesFolder][Manufacturer]",
    );

    # Set the upgrade code
    $self->{msi}->addProperty (
        -Property => 'UpgradeCode',
        -Value =>
            Win32::MSI::HighLevel::Common::genGUID ($self->{msi}->getProduct ())
    );

    # Add directories
    $self->{msi}->addDirectory (
        -Directory        => 'TARGETDIR',
        -Directory_Parent => undef,
        -DefaultDir       => 'SourceDir'
    ) unless $self->{msi}->haveDirId ('TARGETDIR');

    # Add features
    my $featureDir = $self->{msi}->getTargetDirID ($self->{targetFolder}, 1);
    my $featureFull = $self->{msi}->addFeature (
        -name       => 'Complete',
        -Title      => 'Full install',
        -Directory_ => $featureDir
    );
    $self->{featureLU}{Complete} = $featureFull;

    # Add files
    $self->addFiles ();

    # Add licence file text
    @ARGV = "$self->{sourceFolder}\\LICENSE.rtf";
    my $text = do {local $/; join '', <>};

    $self->{msi}->setTableEntryField (
        'Control',
        {-Dialog_ => 'LicenseAgreementDlg', -Control => 'AgreementText'},
        {-Text    => $text}
    );

    # Add readme file text
    @ARGV = "$self->{sourceFolder}\\README.rtf";
    $text = do {local $\; join '', <>};
    $self->{msi}->setTableEntryField (
        'Control',
        {-Dialog_ => 'Readme_Dialog', -Control => 'ScrollableText'},
        {-Text    => $text}
    );

    # Add properties pertaining to Add/Remove programs entry
    $self->{msi}->addProperty (
        -Property => 'ARPHELPLINK',
        -Value    => "file:///C:/$self->{targetFolder}/readme.htm",
    );
    $self->{msi}->addProperty (-Property => 'ARPNOMODIFY', -Value => '1');
    $self->{msi}->addProperty (
        -Property => 'ARPURLINFOABOUT',
        -Value    => "file:///C:/$self->{targetFolder}/readme.htm",
    );
    $self->{msi}->addProperty (
        -Property => 'ARPURLUPDATEINFO',
        -Value    => "file:///C:/$self->{targetFolder}/readme.htm"
    );

    # Populate the .msi file
    $self->{msi}->createCabs  ();
    $self->{msi}->writeTables ();
    $self->{msi}->commit      ();
    $self->{msi}->close       ();
    $self->{msi} = 0;
}


sub updateSummaryStream {
    # Update the package code GUID for the Summary Stream
    # Note that the .msi file MUST be closed then re-opened for this to actually
    # do anything!

    my ($self, $file) = @_;
    my $msi = Win32::MSI::HighLevel->new (
        -file => $file,
        -mode => Win32::MSI::HighLevel::Common::kMSIDBOPEN_TRANSACT
    );
    my $summary = Win32::MSI::HighLevel::Summary->new ($msi);
    my $guid = uc Win32::Guidgen::create ();

    $summary->setProperty ('PID_REVNUMBER', $guid);
    $summary->setProperty ('PID_SUBJECT',   $self->{productName});
    $summary->setProperty ('PID_AUTHOR',    $self->{manufacturer});
    $summary->setProperty ('PID_KEYWORDS', "$self->{manufacturer},$self->{productName}");
    $summary->setProperty ('PID_COMMENTS', "This installer database installs $self->{productName}");
    $msi->commit ();
    $msi = 0;
    print "Set package code GUID to $guid\n";
}


sub addFiles {
    my $self = shift;

    $self->{fileMappings} = [
        # More specific matches first
        # Flags are: + - recursive,
        #            s - create file short cut
        #            f - create folder shortcut
        #            m - make folder structure
        {
            flags       => "+",
            source      => $self->{sourceFolder},
            target      => $self->{targetFolder},
            match       => "\.(rtf|pl)",
            exclude     => "(bin\\d+|\.(cab|dff|msi))",
            featureName => "Complete",
        },
        ]
        unless exists $self->{fileMappings};

    # Build hash of referenced features
    @{$self->{refFeatures}}{map { $_->{featureName} }
            @{$self->{fileMappings}}} = undef;

    $self->insertFiles ($_, '') || return 0 for @{$self->{fileMappings}};
    return 1;
}


sub insertFiles {
    my ($self, $mapping, $subpath) = @_;
    my $featureName = $mapping->{featureName};
    my $featureId   = $self->{featureLU}{$featureName};

    $mapping->{exclude} = "''.*" if !length $mapping->{exclude};
    $mapping->{destination} = [$mapping->{destination}]
        if exists $mapping->{destination}
            and 'ARRAY' ne ref $mapping->{destination};

    my $source = exists $mapping->{source} ? "$mapping->{source}$subpath" : undef;
    my $destFolder = fixPath ("$mapping->{target}$subpath");
    my $keyComponent;

    if (defined $source) {
        opendir SCANDIR, $source;
        my @files = readdir SCANDIR;
        closedir SCANDIR;

        for my $file (@files) {
            next if $file =~ /^\.\.?$/;

            if (-d "$source\\$file") {
                # Handle sub-directories
                next if $mapping->{flags} !~ '\+';
                return 0 if !$self->insertFiles ($mapping, "$subpath\\$file");
                next;
            }

            # Handle files
            next if $file !~ /$mapping->{match}$/i;
            next if $file =~ /$mapping->{exclude}$/i;

            my $sourcePath = fixPath ("$source\\$file");
            my $target     = fixPath ("$destFolder\\$file");
            my $lcTarget   = lc $target;
            my $lcDestFolder = lc $destFolder;

            if (exists $self->{installed}{$lcTarget}
                and lc ($self->{installed}{$lcTarget}) ne lc ($sourcePath))
            {
                print <<"WARN";
Target:
$target
installed from:
$self->{installed}{$lcTarget}
and from:
$sourcePath

Ignoring $sourcePath
WARN
                return 0;
            }

            next if exists $self->{installed}{$lcTarget};

            print "Processing: $sourcePath\n" if $self->{noisy} > 1;
            $self->{installed}{$lcTarget} = $sourcePath;

            my $newFile = $self->{msi}->addFile (
                -featureId  => $featureId,
                -fileName   => $file,
                -sourceDir  => $source,
                -targetDir  => $destFolder,
                -Language   => $self->{languageCode},
                -skipDupAdd => $mapping->{skipDupAdd},
            );

            $keyComponent ||= $self->{msi}->getComponentIdFromFileId ($newFile);

            $self->{"mc_$mapping->{key}"} =
                $self->{msi}->getTableEntry ('File', {-File => $newFile})
                if exists $mapping->{key};

            exists $mapping->{fixups}
                and $_->($self, $featureName, $file, $newFile)
                for @{$mapping->{fixups}};

            ## Hide file if hidden flag is set
            #$currFile->SetProperty ('Attributes' => 2)
            #    if defined $currFile and $flags =~ 'h';

            # Add shortcuts to the file
            if ($mapping->{flags} =~ 's') {
                for my $dest (@{$mapping->{destination}}) {
                    my $name   = $mapping->{name};
                    my %params = (
                        -Component_ =>
                            $self->{msi}->getComponentIdFromFileId ($newFile),
                        -name      => $name,
                        -target    => $target,
                        -location  => $dest,
                        -featureId => $featureId,
                    );

                    $params{-Description} = $mapping->{description}
                        if exists $mapping->{description};

                    $params{-Arguments} = $mapping->{arguments}
                        if exists $mapping->{arguments};

                    if ($mapping->{workdir} =~ /^\[(\w+)\]$/) {
                        $params{-WkDir} = $1;
                    } else {
                        $params{-wkdir} = $mapping->{workdir};
                    }

                    # Create a command line shortcut
                    $self->{msi}->addShortcut (%params);
                    print "Added shortcut to >$target< for '$name' at $dest\n";
                }
            }
        }
    }

    if ($mapping->{flags} =~ 'm' && length ($subpath) == 0) {
        # Create a folder on the target system
        my $newPath = $mapping->{target};

        $newPath .= "\\$subpath" if defined $subpath and length $subpath;
        $self->{msi}->addCreateFolder (-folderPath => $newPath,
            -features => ['Complete']);
    }

    if ($mapping->{flags} =~ 'f' && length ($subpath) == 0) {
        # Create shortcut to folder
        for my $dest (@{$mapping->{destination}}) {
            my $name   = $mapping->{name};
            my %params = (
                -name         => $featureName,
                -folderTarget => $destFolder,
                -location     => $dest,
                -featureId    => $featureId,
            );

            $params{-Description} = $mapping->{description}
                if exists $mapping->{description};

            # Create a folder shortcut
            $self->{msi}->addShortcut (%params);
            print "Added shortcut to >$destFolder< for '$name' at $dest\n";
        }
    }

    return 1;
}


sub fixPath {
    my $path = shift;

    # Normalise path
    1 while $path =~ s|\\ [^\\]+ \\ \.\.(?=\\) ||x;
    return $path;
}


sub ShowHelp {
    my $exitValue = 0;
    my $str       = '';

    $exitValue = shift if defined $_[0] and $_[0] =~ /^[-+]?\d+$/;

    $str .= $_ while $_ = shift;
    $str .= <<HELP;

MSIBuild takes a set of exported table definition files in the subdirectory
'tables' and generates an .msi installer containing the files in the
subdirectory 'source'. The root directory defaults to the current directory, but
may be specified as the first command line argument.

Usage:

MSIBuild [<source dir>] [<version>]

    <source dir> is the root folder for the subdirectories containing the table
    files and the files to be assembled into the installer.

    The current working directory is assumed if this argument is missing.

    A trailing '\' is required.

    <version> is the version number for the product. It is of the form: j.i.r
    where the release (r) should be omitted if 0. Major (j) and minor (i) values
    must be present.

    5.10 is assumed if this argument is missing.

HELP

    my $mode = $exitValue != 1 ? 'error' : 'help';

    ShowString ("MSIBuild $mode\n$str");

    exit ($exitValue || -1);
}


sub ShowString {
    my $str = shift;

    print $str;
    return;
}
