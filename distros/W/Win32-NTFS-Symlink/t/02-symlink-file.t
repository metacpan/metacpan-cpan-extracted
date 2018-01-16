use strict;
use warnings;

use Test::More tests => 8;
BEGIN { use_ok('Win32::NTFS::Symlink') };

################################################################################

use Win32::NTFS::Symlink qw(:global);

use File::Spec;

my $root        = 'test_root.02-symlink-file';
my $target_file = 'foo';
my $link_file   = 'symlink_to_foo';

my $test_string = "Test 123";

mkdir $root or die "mkdir $root failed: $!";
chdir $root or die "chdir $root failed: $!";

ok(! -e $target_file, "$target_file does not already exist");
ok(! -e $link_file,   "$link_file does not already exist");

open my $ofh, '>', $target_file or
   die "open $target_file for writing failed: $!";

print $ofh $test_string;
close $ofh or die "close $target_file failed: $!";

ok(-f $target_file, "target file $target_file created");

ok(
   eval { symlink( $target_file => $link_file ) },
   "create junction $link_file => $target_file via symlink()"
);

my $readlink = readlink($link_file);

ok($readlink, "readlink(\$link_file) returns true");
ok($readlink eq $target_file, "$link_file points to $target_file");

open my $ifh, '<', $link_file or 
   die "open $link_file for writing failed: $!";;

ok(
   scalar( <$ifh> ) eq $test_string,
   "Contents of $target_file and $link_file are the same"
);

close $ifh or die "close $link_file failed: $!";

END {
   unlink $link_file;
   unlink $target_file;
   chdir '..' && rmdir $root;
}
