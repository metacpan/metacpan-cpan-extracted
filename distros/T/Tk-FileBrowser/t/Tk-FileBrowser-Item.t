use strict;
use warnings;
use Test::More tests => 28;

use Cwd;
my $cwd = getcwd;

use Config;
my $mswin = $Config{'osname'} eq 'MSWin32';

my $sep = '/';
$sep = '\\' if $mswin;
$cwd =~ s/\//\\/g if $mswin;

BEGIN {
	use_ok('Tk::FileBrowser::Item');
}

#require Tk::ListBrowser::Entry;
my $file = 'Makefile.PL';
$file = "$cwd$sep$file";
my $dir = 'lib';
$dir = "$cwd$sep$dir";
my $child = 'lib/Tk';
$child = "$cwd$sep$child";
my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks);
($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($file);

my $fitem = new Tk::FileBrowser::Item(-listbrowser => 1, -name => 'Makefile.PL', -fullname => $file);

ok (defined $fitem, "File item created");

ok ($fitem->name eq 'Makefile.PL', "Makefile.PL initialized");
ok ($fitem->fullname eq $file, "testing fullname method");

ok ($fitem->isDir eq '', "Not a directory");
ok ($fitem->isFile eq 1, "A file");
ok ($fitem->isLink eq '', "Not a symbolic link");

ok ($fitem->size eq $size, "Size");

ok ($fitem->accessed eq $atime, "Accessed");
ok ($fitem->created eq $ctime, "Created");
ok ($fitem->modified eq $mtime, "Modified");

($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($dir);
my $ditem = new Tk::FileBrowser::Item(-listbrowser => 1, -name => 'blob', -fullname => $dir);

ok (defined $ditem, "Directory item created");
ok ($ditem->name eq 'blob', "lib initialized");

ok ($ditem->isDir eq 1, "A directory");
ok ($ditem->isFile eq '', "Not a file");
ok ($ditem->isLink eq '', "Not a symbolic link");

ok ($ditem->size eq 0, "Size");

ok ($ditem->accessed eq $atime, "Accessed");
ok ($ditem->created eq $ctime, "Created");
ok ($ditem->modified eq $mtime, "Modified");

ok ($ditem->opened eq 0, "Not Open");
$ditem->opened(1);
ok ($ditem->opened eq 1, "Open");

ok ($ditem->loaded eq 0, "Not Loaded");
$ditem->loaded(1);
ok ($ditem->loaded eq 1, "Loaded");

my $citem = new Tk::FileBrowser::Item(-listbrowser => 1, -name => $child, -fullname => '');
ok (defined $citem, "Child item created");

$ditem->child($citem->name, $citem);
ok ($ditem->child($citem->name) eq $citem, "Child initialized");
ok ($ditem->size eq 1, "Size");
ok ($ditem->children eq 1, "children")


