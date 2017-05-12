# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Win32-StreamNames.t'

#########################
use warnings;
use strict;

use Test::More tests => 29;
use Win32API::File qw (:Func);
use Cwd;

# Version 1.04
# Check module is there (1)
BEGIN { use_ok('Win32::StreamNames') };

#########################
# Create the file and streams
# Cannot distribute streams with files - they do not survive the zip process
sub create_file ($)
{
   my ($file) = @_;
   open (FILE, '>', $file) or die "Unable to open $file: $!";
   print FILE "This is $file\n";
   close FILE;

}  # create_file

sub create_empty_file ($)
{
   my ($file) = @_;
   open (FILE, '>', $file) or die "Unable to open $file: $!";
   close FILE;

}  # create_file

#########################

# Sanity check (2)
is($^O, 'MSWin32', 'OS is Windows');

# Construct the test directory (used later) & file name
my $dir = $0;
$dir =~ s/([\/\\]).*$/$1/;

# NTFS ??
my $sRootPath = (split /[\\\/]/, getcwd())[0].'\\';
my $osVolName = ' ' x 260;
my $osFsType  = ' ' x 260;

# File system type (3)
GetVolumeInformation( $sRootPath, $osVolName, 260, [], [], [], $osFsType, 260 );
is($osFsType, "NTFS") or diag "File system $osFsType unsupported";

# Prepare for testing
$^E = 0;

my $file = $dir.'test.txt';
my @list;

create_file ($file);
create_file ($file.':stream1');
create_file ($file.':stream2');
create_file ($file.':stream3');
create_file ($file.':stream4');

# Is the test file ok? (4 & 5)
ok(-f $file, "$file exists ok");
ok(-r $file, "$file exists ok");

# Open the test file (6)
@list = StreamNames($file);
is(0+$^E, 0, 'os error ok') or diag ("$^E: Value of \$file is: $file<<\n");

# Stream names (7..10)
for my $stream (@list)
{
   ok(open (HANDLE, $file.$stream), "Stream $file$stream ok") or diag ("$file$stream: $!");
   close HANDLE;
}

# 4 streams in this file (11)
is(@list, 4, 'Number of streams') or diag ("@list");
unlink $file;

# Directory? (12, 13)
# Test changed with directory support v1.01
@list = StreamNames('.');
ok(@list == 0, 'Empty directory list') or diag ("@list");
is (0+$^E, 0, 'Attempt to open a directory');

# No such file (14, 15)
@list = StreamNames('gash.zzz');
ok (!@list, 'Empty list on ENOENT') or diag ("@list");
is (0+$^E, 2, 'ENOENT');

# Long file name (16, 17)
$file = $dir.'ThisIsAveryLongFileNameWhichGoesOnAndOn';
create_file ($file);
create_file ($file.':AndThisIsAlsoAVeryLongStreamNameAsWell');

@list = StreamNames($file);
is ("@list", ':AndThisIsAlsoAVeryLongStreamNameAsWell:$DATA') or diag ("@list");
is (0+$^E, 0, 'Long one');
unlink $file;

# Embeded spaces (18, 19, 20)
$file = $dir.'Embedded space in filename';
create_file ($file);
create_file ($file.':Embedded space in stream name');

@list = StreamNames($file);
is (@list, 1, 'Embedded space in filename, list') or diag ("File: $file, List: @list\n");
is (0+$^E, 0, 'Embedded space in filename, oserr') or diag ("@list\n$file");
is ("@list", ':Embedded space in stream name:$DATA', 'Embedded space in filename, list');
unlink $file;

# No streams in file (21, 22);
$file = $dir.'NoStreams.txt';
create_file ($file);

@list = StreamNames($file);
ok (!@list, 'Empty list on no streams') or diag ("@list");
is (0+$^E, 0, 'No streams, oserr') or diag ("@list\n$file");
unlink $file;

# Test for directory support (23, 24, 25)
my $testdir = $dir.'TestDir';
mkdir $testdir || die "Unable to create $testdir: $!";
$file = "$testdir:dirADStest";
create_file ($file);

@list = StreamNames($testdir);
is (@list, 1, 'dirADStest, list') or diag ("File: $file, List: @list\n");
is (0+$^E, 0, 'dir ADS test, oserr') or diag ("@list\n$file");
is ("@list", ':dirADStest:$DATA', 'dir ADS test, list');

unlink $file;

# Empty stream file? (26,27)
$file = $dir.'test.txt';
create_empty_file ($file.':streamE');
@list = StreamNames($file);
is(0+$^E, 0, 'os error ok') or diag ("$^E: Value of \$file is: $file<<\n");
ok(@list == 1, 'Empty stream list') or diag ("list:<@list>");
unlink $file;

# Empty stream file within a list of data files (28,29)
my $file1 = "$testdir:dirADStest.name1";
create_file ($file1);
my $file2 = "$testdir:dirADStest1.name2";
create_empty_file ($file2);
my $file3 = "$testdir:dirADStest2.name3";
create_file ($file3);
my $file4 = "$testdir:dirADStest3.name4";
create_file ($file4);
@list = StreamNames($testdir);
is(0+$^E, 0, 'os error ok') or diag ("$^E: Value of \$file is: $file<<\n");
ok(@list == 5, 'Mixed stream list') or diag ("list:<@list>");

unlink ($file1, $file2, $file2, $file4);
rmdir $testdir;
# End of file