use strict;
use warnings;
use Test::More tests => 27;

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

my $file = 'Makefile.PL';
my $dir = 'lib';
my $child = 'lib/Tk';
my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks);
($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($file);

my $fitem = new Tk::FileBrowser::Item( $file );

ok (defined $fitem, "File item created");
ok ($fitem->name eq "$cwd$sep$file", "Makefile.PL initialized");

ok ($fitem->isDir eq '', "Not a directory");
ok ($fitem->isFile eq 1, "A file");
ok ($fitem->isLink eq '', "Not a symbolic link");

ok ($fitem->size eq $size, "Size");

ok ($fitem->accessed eq $atime, "Accessed");
ok ($fitem->created eq $ctime, "Created");
ok ($fitem->modified eq $mtime, "Modified");

($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($dir);
my $ditem = new Tk::FileBrowser::Item( $dir );

ok (defined $ditem, "Directory item created");
ok ($ditem->name eq "$cwd$sep$dir", "lib initialized");

ok ($ditem->isDir eq 1, "A directory");
ok ($ditem->isFile eq '', "Not a file");
ok ($ditem->isLink eq '', "Not a symbolic link");

ok ($ditem->size eq 0, "Size");

ok ($ditem->accessed eq $atime, "Accessed");
ok ($ditem->created eq $ctime, "Created");
ok ($ditem->modified eq $mtime, "Modified");

ok ($ditem->isOpen eq 0, "Not Open");
$ditem->isOpen(1);
ok ($ditem->isOpen eq 1, "Open");

ok ($ditem->loaded eq 0, "Not Loaded");
$ditem->loaded(1);
ok ($ditem->loaded eq 1, "Loaded");

my $citem = new Tk::FileBrowser::Item( $child );
ok (defined $ditem, "Child item created");

$ditem->child($citem->name, $citem);
ok ($ditem->child($citem->name) eq $citem, "Child initialized");
ok ($ditem->size eq 1, "Size");
ok ($ditem->children eq 1, "children")


