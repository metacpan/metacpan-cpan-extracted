use strict;
use warnings;
use lib
    'C:\Documents and Settings\Peter\My Documents\Projects\grandfather\CPANDistro\Win32-PEFile\lib';
use Win32::PEFile;
use Win32::LangId;

my $base =
    'C:\Documents and Settings\Peter\My Documents\Projects\grandfather\CPANDistro\Win32-PEFile\t';

my $pe = Win32::PEFile->new (-file => "$base\\pefile.exe");
my @sectionNames = $pe->getSectionNames();
my $verStrs = $pe->getVersionStrings ();
my $verFixed = $pe->getFixedVersionValues();
my @exports = $pe->getExportNames();
my %imports = $pe->getImportNames();
my $newFilePath = "$base\\peFileNew.exe";

unlink $newFilePath;
$pe->writeFile (-file => $newFilePath);

my $stub = $pe->getMSDOSStub();

unlink $newFilePath;
my $langId  = $Win32::LangId::LangId{English}{UnitedStates};
my $peNew = Win32::PEFile->new (
    -create => 1,
    -file   => $newFilePath,
);

$peNew->addVersionResource (lang => $langId, %$verStrs, %$verFixed);
$peNew->addResource (
    lang => $langId,
    name => '101',
    type => 'Enabler',
    data => 'The quick brown fox and all that'
);
$peNew->addMSDOSStub ($stub);
$peNew->writeFile (-file => $newFilePath);
