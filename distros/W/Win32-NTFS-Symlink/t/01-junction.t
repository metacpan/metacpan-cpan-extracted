use strict;
use warnings;

use Test::More tests => 9;
BEGIN { use_ok('Win32::NTFS::Symlink') };

################################################################################

use Win32::NTFS::Symlink qw(:global junction);

use File::Spec;

my $root       = 'test_root.01-junction';
my $target_dir = 'foo';
my $link_dir   = 'junction_to_foo';

my $target_test_file = File::Spec->catfile($target_dir, 'bar.txt');
my $link_test_file   = File::Spec->catfile($link_dir,   'bar.txt');

my $test_string = "Test 123";

mkdir $root or die "mkdir $root failed: $!";
chdir $root or die "chdir $root failed: $!";

ok(! -e $target_dir, "$target_dir does not already exist");
ok(! -e $link_dir,   "$link_dir does not already exist");

mkdir $target_dir or die "mkdir $target_dir failed: $!";
ok(-d $target_dir, "target directory $target_dir created");

open my $ofh, '>', $target_test_file or
   die "open $target_test_file for writing failed: $!";

print $ofh $test_string;
close $ofh or die "close $target_test_file failed: $!";

ok(-f $target_test_file, "file $target_test_file created in target directory");

ok(
   eval { Win32::NTFS::Symlink::junction( $target_dir => $link_dir ) },
   "create junction $link_dir => $target_dir via junction()"
);

my $readlink = readlink($link_dir);
my $readlink_rel = (File::Spec->splitdir($readlink))[-1] || '';

ok($readlink, "readlink(\$link_dir) returns true");
ok($readlink_rel eq $target_dir, "$link_dir points to $target_dir");

open my $ifh, '<', $link_test_file or 
   die "open $link_test_file for writing failed: $!";;

ok(
   scalar( <$ifh> ) eq $test_string,
   "Contents of $target_test_file and $link_test_file are the same"
);

close $ifh or die "close $link_test_file failed: $!";;;

END {
   unlink $target_test_file;
   rmdir $link_dir;
   rmdir $target_dir;
   chdir '..' && rmdir $root;
}
