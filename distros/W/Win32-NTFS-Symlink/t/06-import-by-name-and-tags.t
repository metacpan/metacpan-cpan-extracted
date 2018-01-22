use strict;
use warnings;

use Test::More tests => 5;
BEGIN { use_ok('Win32::NTFS::Symlink') };

################################################################################

{
   package Import_by_name;
   
   use Win32::NTFS::Symlink qw(readlink symlink junction);
   
   sub do_test {
      \&readlink == \&Win32::NTFS::Symlink::readlink &&
      \&symlink  == \&Win32::NTFS::Symlink::symlink &&
      \&junction == \&Win32::NTFS::Symlink::junction;
   }
}

{
   package Import_by_tag;
   
   use Win32::NTFS::Symlink qw(:package);
   
   sub do_test {
      \&readlink == \&Win32::NTFS::Symlink::readlink &&
      \&symlink  == \&Win32::NTFS::Symlink::symlink &&
      \&junction == \&Win32::NTFS::Symlink::junction;
   }
}

{
   package Import_by_name_ntfs_;
   
   use Win32::NTFS::Symlink qw(ntfs_readlink ntfs_symlink ntfs_junction);
   
   sub do_test {
      \&ntfs_readlink == \&Win32::NTFS::Symlink::ntfs_readlink &&
      \&ntfs_symlink  == \&Win32::NTFS::Symlink::ntfs_symlink &&
      \&ntfs_junction == \&Win32::NTFS::Symlink::ntfs_junction;
   }
}

{
   package Import_by_tag_ntfs_;
   
   use Win32::NTFS::Symlink qw(:ntfs_);
   
   sub do_test {
      \&ntfs_readlink == \&Win32::NTFS::Symlink::ntfs_readlink &&
      \&ntfs_symlink  == \&Win32::NTFS::Symlink::ntfs_symlink &&
      \&ntfs_junction == \&Win32::NTFS::Symlink::ntfs_junction;
   }
}

ok(
   Import_by_name::do_test,
   'import readlink, symlink, and junction by name'
);

ok(
   Import_by_tag::do_test,
   'import readlink, symlink, and junction via :package tag'
);

ok(
   Import_by_name_ntfs_::do_test,
   'import ntfs_readlink, ntfs_symlink, and ntfs_junction by name'
);

ok(
   Import_by_tag_ntfs_::do_test,
   'import ntfs_readlink, ntfs_symlink, and ntfs_junction via :ntfs_ tag'
);
