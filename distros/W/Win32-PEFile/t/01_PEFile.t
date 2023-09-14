#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 17;

my $kTestFile;
my $kTestNRFile;
my $kBadFile;

BEGIN {
    if (-d 'Win32-PEFile/t') {
        use lib 'Win32-PEFile/lib'; # For release build test run
        print "Running from Win32-PEFile parent folder\n";
        $kTestFile   = 'Win32-PEFile/t/PEFile.exe';
        $kTestNRFile = 'Win32-PEFile/t/PEFileNR.exe';
        $kBadFile    = 'Win32-PEFile/t/01_PEFile.t';
    } elsif (-d 't') {
        use lib 'lib'; # For development testing from t's parent
        print "Running from Win32-PEFile folder\n";
        $kTestFile   = 't/PEFile.exe';
        $kTestNRFile = 't/PEFileNR.exe';
        $kBadFile    = 't/01_PEFile.t';
    } elsif (-d '../t') {
        use lib '../lib'; # For development testing from t
        print "Running from Win32-PEFile/t folder\n";
        $kTestFile   = 'PEFile.exe';
        $kTestNRFile = 'PEFileNR.exe';
        $kBadFile    = '01_PEFile.t';
    } else {
        die "Can't firgure out run context!\n";
    }
}

use Win32::PEFile;

=head1 NAME

Win32::PEFile test suite

=head1 DESCRIPTION

This file contains an install time test suite to be run on a target system as a
check that the Win32::PEFile module works correctly with the target system.

See tests in the ../xt folder for more comprehensive release and development
tests.

=cut

local $SIG{__WARN__} =
    sub {$|++; print ""; die $_[0]};    # Really make warnings fatal

my $pe;

print "Testing Win32::PEFile version $Win32::PEFile::VERSION\n";

ok($pe = Win32::PEFile->new(-file => $kTestFile),
    'Create Win32::PEFile instance');
ok($pe->isOk(), "Ok set for PE file");

is($pe->haveExportEntry('EntryPoint1'),        '1', 'Find EntryPoint1');
is($pe->haveExportEntry('EntryPoint2'),        '',  "Don't find EntryPoint2");
is($pe->haveImportEntry('MSVCR90.dll/printf'), '1', 'Find import printf');
is($pe->haveImportEntry('MSVCR90.dll/sprintf'), '', "Don't find import sprint");

my $count = $pe->getVersionCount();
is($count, 1, "Version count - any");
$count = $pe->getVersionCount(0x409);
is($count, 0, "Version count - no US-en");
$count = $pe->getVersionCount(0x1409);
is($count, 1, "Version count - NZ-en");

my $strs = $pe->getVersionStrings();
is($strs->{'ProductName'},    'PEFile Application', "Get Product name");
is($strs->{'ProductVersion'}, '1, 0, 0, 1',         "Get Product version");

my @exports = $pe->getExportNames();
is(scalar @exports, 1, "List all exports");

my %imports = $pe->getImportNames();
is(keys %imports, 2, "List all imports");

# PE file without a version resource tests
$pe = Win32::PEFile->new(-file => $kTestNRFile);
ok($pe->isOk(), "Ok for non-resource PE file");

$strs = $pe->getVersionStrings();
ok(!defined $strs, "No bogus version strings");

# Non-PE file tests
$pe = Win32::PEFile->new(-file => $kBadFile);
ok(!$pe->isOk(), "Not ok for non-PE file");
is($pe->lastError(), <<ERROR, "lastError set for non-PE file");
Error in PE file $kBadFile: No MZ header found

ERROR


sub mustDie {
    my ($test, $errMsg, $name) = @_;

    eval {$test->();};
    my $err = $@;
    my $isRightFail = defined ($err) && $err =~ /\Q$errMsg\E/;

    print defined $err
        ? "Error: $err\n"
        : "Unexpected success. Expected: $errMsg\n"
        if !$isRightFail;
    ok($isRightFail, $name);
}
