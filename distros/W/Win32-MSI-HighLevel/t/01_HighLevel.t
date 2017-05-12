use strict;
use warnings;
use Test::More;

=head1 NAME

HighLevel test suite

=head1 DESCRIPTION

Test Win32::MSI::HighLevel

=cut

BEGIN {
    use lib '../../..';    # For 'CPAN' folder layout
    use lib '../lib';    # For dev folder layout
    use Win32::API;

    if ($^O ne 'MSWin32') {
        plan (skip_all => "Windows only module. Tests irrelevant on $^O");
    } elsif (
        !Win32::API->new ("kernel32", 'LoadLibrary', "P", 'I')->Call ('msi'))
    {
        plan (skip_all =>
                "msi.dll required - Windows Installer must be installed");
    } else {
        plan (tests => 84);
    }

    use_ok ("Win32::MSI::HighLevel");
}

my $filename = 'delme.msi';

# Basic create and open database tests.
unlink $filename;
ok (
    my $msi = Win32::MSI::HighLevel->new (
        -file => $filename,
        -mode => Win32::MSI::HighLevel::Common::kMSIDBOPEN_CREATE ()
    ),
    'Create a new .msi file in transacted mode'
   );
$msi = 0;    # Destroy object

unlink $filename;
ok (
    $msi = Win32::MSI::HighLevel->new (
        -file => $filename,
        -mode => Win32::MSI::HighLevel::Common::kMSIDBOPEN_CREATEDIRECT ()
    ),
    'Create a new .msi file in direct mode'
   );
$msi = 0;    # Destroy object

ok (
    $msi = Win32::MSI::HighLevel->new (
        -file => $filename,
        -mode => Win32::MSI::HighLevel::Common::kMSIDBOPEN_DIRECT ()
    ),
    'Open existing .msi file in direct mode'
   );
$msi = 0;    # Destroy object

ok (
    $msi = Win32::MSI::HighLevel->new (
        -file => $filename,
        -mode => Win32::MSI::HighLevel::Common::kMSIDBOPEN_READONLY ()
    ),
    'Open existing .msi file in read only mode'
   );
$msi = 0;    # Destroy object

ok (
    $msi = Win32::MSI::HighLevel->new (
        -file => $filename,
        -mode => Win32::MSI::HighLevel::Common::kMSIDBOPEN_TRANSACT ()
    ),
    'Open existing .msi file in transacted mode'
   );

print "Create a Feature table, populate it, and check contents\n";
is ('Feature', $msi->createTable (-table => 'Feature'), 'Create Feature table');
is (
    'Complete',
    $msi->addFeature (-name => 'Complete', -Title => 'Full install'),
    'Add Complete feature to Feature table'
   );
mustDie (
    sub {$msi->addFeature ();},
    'Win32::MSI::HighLevel::addFeature requires a -name parameter',
    'Add empty feature fails'
);
ok ($msi->writeTables (), 'Write updated tables to disk');

is (0, $msi->exportTable ('Feature', 'Tables'), 'Export Feature table');

checkTableEntry (
    "Feature\tFeature_Parent\tTitle\tDescription\tDisplay\tLevel\tDirectory_\tAttributes",
    "s38\tS38\tL64\tL255\tI2\ti2\tS72\ti2",
    "Feature\tFeature",
    "Complete\t\tFull install\t\t1\t3\t\t0",
);

print "Create a Property table, populate it, and check contents\n";
is (
    'Property',
    $msi->createTable (-table => 'Property'),
    'Create Property table'
   );
is (
    'Wibble',
    $msi->addProperty (-Property => 'Wibble', -Value => 'wobble'),
    'Add Wibble property to Property table'
   );
mustDie (
    sub {$msi->addProperty ();},
    'Win32::MSI::HighLevel::addProperty requires a -Property parameter',
    'Add empty property fails'
);
ok ($msi->writeTables (), 'Write updated tables to disk');
is (0, $msi->exportTable ('Property', 'Tables'), 'Export Property table');

checkTableEntry ("Property\tValue", "s72\tl0", "Property\tProperty",
    "Wibble\twobble",);

print "Create a Directory table, populate it, and check contents\n";
is (
    'Directory',
    $msi->createTable (-table => 'Directory'),
    'Create Directory table'
   );
is (
    'TARGETDIR',
    $msi->addDirectory (
        -Directory        => 'TARGETDIR',
        -Directory_Parent => undef,
        -DefaultDir       => 'SrcDir|SourceDir'
    ),
    'Add root entry to Directory table'
   );
is (
    'Root',
    $msi->addDirectory (
        -Directory        => 'Root',
        -Directory_Parent => 'TARGETDIR',
    ),
    'Add root entry to Directory table'
   );
is (
    'Dobbie',
    $msi->addDirectory (
        -Directory_Parent => 'TARGETDIR',
        -Directory        => 'Dobbie',
        -source           => 'wibble~1|Wibble Plonk',
        -target           => 'target~1|Target Dir'
    ),
    'Add root entry to Directory table'
   );
mustDie (
    sub {$msi->addDirectory ();},
    'Win32::MSI::HighLevel::addDirectory requires a -Directory_Parent parameter',
    'Add empty dir fails'
);
mustDie (
    sub {
        $msi->addDirectory (
            -Directory_Parent => 'TARGETDIR',
            -Directory        => 'dir',
            -DefaultDir       => 'short~1|Short/One'
        );
    },
    'None of \?|><:/*" allowed: ',
    'Bad dir characters fail'
);
ok ($msi->writeTables (), 'Write updated tables to disk');
is (0, $msi->exportTable ('Directory', 'Tables'), 'Export Directory table');

checkTableEntry (
    "Directory\tDirectory_Parent\tDefaultDir",
    "s72\tS72\ts255",
    "Directory\tDirectory",
    "TARGETDIR\t\tSrcDir|SourceDir",
    "Root\tTARGETDIR\t.",
    "Dobbie\tTARGETDIR\ttarget~1|Target Dir:wibble~1|Wibble Plonk",
);

$msi = 0;    # Destroy object

unlink $filename;

print "Add a file to an empty database\n";
unlink $filename;
ok (
    $msi = Win32::MSI::HighLevel->new (
        -file => $filename,
        -mode => Win32::MSI::HighLevel::Common::kMSIDBOPEN_CREATE ()
    ),
    'Create a new .msi file in transacted mode'
   );

is (
    $msi->setProduct (
        -Language => 1033,
        -Name => 'Wibble',
        -Version => '1.0.0',
        -Manufacturer => 'Wibble Mfg. Co.'
        ),
    '{5C7C9ADE-0534-43B4-8C04-921F4A846CFA}',
    'Set product information'
   );

is (
    $msi->addFeature (-name => 'DefaultFeature', -Title => 'Default feature'),
    'DefaultFeature',
    'Add Default feature to Feature table'
   );

is (
    'TARGETDIR',
    $msi->addDirectory (
        -Directory        => 'TARGETDIR',
        -Directory_Parent => undef,
        -DefaultDir       => 'SrcDir|SourceDir'
    ),
    'Add root entry to Directory table'
   );

is (
    $msi->addFile (
        -sourceDir         => './Tables',
        -fileName          => 'Property.idt',
        -forceNewComponent => 'Property_idt',
        -featureId         => 'DefaultFeature'
    ),
    'Property.idt',
    'Add file entry to File table'
   );
ok ($msi->writeTables (), 'Write updated tables to disk');
is (0, $msi->exportTable ('Directory', 'Tables'), 'Export Directory table');

checkTableEntry (
"Directory\tDirectory_Parent\tDefaultDir",
"s72\tS72\ts255",
"Directory\tDirectory",
"Dir_.\tTARGETDIR\t.~1|.",
"Dir_Tables\tDir_.\tTables",
"TARGETDIR\t\tSrcDir|SourceDir",
);

is (0, $msi->exportTable ('File', 'Tables'), 'Export File table');

checkTableEntry (
    "File\tComponent_\tFileName\tFileSize\tVersion\tLanguage\tAttributes\tSequence",
    "s38\ts38\tl128\ti4\tS72\tS20\tI2\ti2",
    "File\tFile",
    "Property.idt\tProperty_idt\tProperty.idt\t58\t\t1033\t\t1",
);

$msi = 0;    # Destroy object

unlink $filename;
exit;


sub mustDie {
    my ($test, $errMsg, $name) = @_;

    eval {$test->();};

    my $isRightFail = defined ($@) && $@ =~ /\Q$errMsg\E/;

    print defined $@ ? "Error: $@\n" : "Unexpected success. Expected: $errMsg\n"
        if !$isRightFail;
    ok ($isRightFail, $name);
}


sub checkTableEntry {
    my ($columnNamesStr, $columnSpecsStr, $nameAndKeys, @testLines) = @_;
    my @colNames = split "\t", $columnNamesStr;
    my @colSpecs = split "\t", $columnSpecsStr;
    my ($tableName, @keyNames) = split "\t", $nameAndKeys;
    my $tablePath = File::Spec->rel2abs ("Tables\\$tableName.idt");
    my @keys;

    for my $colIndex (0 .. $#colNames) {
        my $colName = $colNames[$colIndex];

        push @keys, [$colName, $colIndex] if grep {$colName eq $_} @keyNames;
    }

    ok (
        (my $result = open (my $inFile, '<', $tablePath)),
        "Open $tableName table file for validation"
       );
    if (!$result) {
        print "Open $tablePath failed: $!\n";
        return;
    }

    matchTableLine ("column names for $tableName", scalar <$inFile>, @colNames);
    matchTableLine ("column specs for $tableName", scalar <$inFile>, @colSpecs);
    matchTableLine (
        "name and keys for $tableName",
        scalar <$inFile>,
        $tableName, @keyNames
    );

    my %tableEntries;

    while (my $line = <$inFile>) {
        addTableEntry ($line, \%tableEntries, @keys);
    }

    for my $testLine (@testLines) {
        my @colValues = split "\t", $testLine;
        my $keyStr = join " ", @colValues[map {$_->[1]} @keys];

        ok (exists $tableEntries{$keyStr}, "Check table row ($keyStr) exists");
        is ($testLine, $tableEntries{$keyStr}, "Check table line matches");
    }

    ok (close ($inFile), "Close $tableName table file\n");
}


sub matchTableLine {
    my ($comment, $line, @parts) = @_;
    my $refLine = join "\t", @parts;

    chomp $line;
    is ($line, $refLine, "Match $comment table");
}


sub addTableEntry {
    my ($line, $entries, @keys) = @_;

    chomp $line;
    my @colValues = split "\t", $line;
    my $keyStr = join " ", @colValues[map {$_->[1]} @keys];

    ok (!exists $entries->{$keyStr}, "Check table rows are unique");
    $entries->{$keyStr} = $line;
}
