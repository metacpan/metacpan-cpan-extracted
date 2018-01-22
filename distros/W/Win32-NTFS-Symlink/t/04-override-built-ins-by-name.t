use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('Win32::NTFS::Symlink') };

################################################################################

use Win32::NTFS::Symlink qw(global_readlink global_symlink);

sub do_test {
   \&CORE::GLOBAL::readlink == \&Win32::NTFS::Symlink::readlink &&
   \&CORE::GLOBAL::symlink  == \&Win32::NTFS::Symlink::symlink
}

ok(do_test, 'built-in readlink and symlink are overridden');
