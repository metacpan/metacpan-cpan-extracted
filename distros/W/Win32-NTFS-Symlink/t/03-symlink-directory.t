use strict;
use warnings;

use Test::More tests => 12;
BEGIN { use_ok('Win32::NTFS::Symlink') };

################################################################################

use Win32::NTFS::Symlink qw(:global :is_ ntfs_reparse_tag :const);

use File::Spec;

my $root       = 'test_root.03-symlink-directory';
my $target_dir = 'foo';
my $link_dir   = 'symlink_to_foo';

my $target_test_file = File::Spec->catfile($target_dir, 'bar.txt');
my $link_test_file   = File::Spec->catfile($link_dir,   'bar.txt');

my $test_string = "Test 123";

mkdir $root or die "mkdir $root failed: $!";
chdir $root or die "chdir $root failed: $!";

ok(! -e $target_dir, '$target_dir does not already exist');
ok(! -e $link_dir,   '$link_dir does not already exist');

mkdir $target_dir or die "mkdir $target_dir failed: $!";

open my $ofh, '>', $target_test_file or
   die "open $target_test_file for writing failed: $!";

print $ofh $test_string;
close $ofh or die "close $target_test_file failed: $!";

ok(-f $target_test_file, 'Test file created in $target_dir');

ok(
   eval { symlink( $target_dir => $link_dir ) },
   'symlink($target_dir, $link_dir)'
);

my $readlink = readlink($link_dir);

ok($readlink, 'readlink($link_dir) returns true');

ok(is_ntfs_symlink($link_dir),   'is_ntfs_symlink($link_dir) is true');
ok(!is_ntfs_junction($link_dir), 'is_ntfs_junction($link_dir) is false');

ok(
   ntfs_reparse_tag($link_dir) == IO_REPARSE_TAG_SYMLINK,
   'ntfs_reparse_tag($link_dir) == IO_REPARSE_TAG_SYMLINK'
);
ok(
   ntfs_reparse_tag($link_dir) != IO_REPARSE_TAG_MOUNT_POINT,
   'ntfs_reparse_tag($link_dir) != IO_REPARSE_TAG_MOUNT_POINT'
);

ok($readlink eq $target_dir, '$link_dir points to $target_dir');

open my $ifh, '<', $link_test_file or
   die "open $link_test_file for writing failed: $!";

ok(
   scalar( <$ifh> ) eq $test_string,
   'file in $link_dir is the same as file in $target_dir'
);

close $ifh or die "close $link_test_file failed: $!";

END {
   unlink $target_test_file;
   rmdir $link_dir;
   rmdir $target_dir;
   chdir '..' && rmdir $root;
}
