use strict;
use warnings;

use Test::More tests => 20;
use File::Copy;
sub compare_files;

BEGIN { use_ok('Tk::GtkSettings') };

use Tk::GtkSettings qw(
	$delete_output
	$gtkpath
	$verbose
	$out_file
	alterColor
	appName
	convertColorCode
	export2file
	export2Xdefaults
	export2Xresources
	export2xrdb
	groupAdd
	groupAll
	groupDelete
	groupExists
	groupMembers
	groupMembersAdd
	groupMembersReplace
	groupOption
	groupOptionAll
	groupOptionDelete
	gtkKey
	gtkKeyAll
	gtkKeyDelete
	hex2rgb
	hexstring
	initDefaults
	loadGtkInfo
	platformPermitted
	removeFromXdefaults
	removeFromXresources
	resetAll
	rgb2hex
);

my $outdir = './t/output/';
mkdir $outdir unless -e $outdir;

$verbose = 0;
$gtkpath = './t/Gtk/';

initDefaults;
my @groups = groupAll;
@groups = sort @groups;
# my $size = gtkKeyAll;
# ok (($size eq 83), "Gtk info loaded");

my $color1 = alterColor('#000000', 1);
ok (($color1 eq '#010101'), 'Alter color');

my $color2 = convertColorCode('rgb(255,255,255)');
ok (($color2 eq '#FFFFFF'), 'Convert color Code');

groupAdd('NewGroup', [], {});
ok ((groupExists('NewGroup')), 'Adding group');

groupDelete('NewGroup');
ok ((not groupExists('NewGroup')), 'Deleting group');

groupDelete('main');
ok ((groupExists('main')), 'Cannot delete main group');

gtkKey('blobber', 'blubber');
ok ((gtkKey('blobber') eq 'blubber'), 'Setting gtk key');

gtkKeyDelete('blobber');
ok ((not defined gtkKey('blobber')), 'Deleting gtk key');

my @rgb = hex2rgb('#FF0000');
ok ((($rgb[0] eq 255) and ($rgb[1] eq 0) and ($rgb[2] eq 0)), 'hex2rgb');

my $hs = hexstring(255);
ok (($hs eq 'FF'), 'hexstring');

my $hex = rgb2hex(255, 0, 0);
ok (($hex eq '#FF0000'), 'rgb2hex');

initDefaults;

SKIP: {
	skip 'Unsupported platform', 9 unless platformPermitted;

	ok ((($groups[0] eq 'content') and ($groups[1] eq 'list') and ($groups[2] eq 'main')), "Groups set");

	groupMembersAdd(qw[content Member1 Member2]);
	my $groupsize1 = groupMembers('content');
	ok (($groupsize1 eq 11), 'Adding members');

	groupMembersReplace(qw[content Member1 Member2]);
	my $groupsize2 = groupMembers('content');
	ok (($groupsize2 eq 2), 'Replacing members');

	my $optionsize1 = groupOptionAll('content');
	ok (($optionsize1 eq 2), 'Groupt content options 1');

	groupOption('content', 'blobber', 'blubber');
	ok ((groupOption('content', 'blobber') eq 'blubber'), 'Setting option');

	my $optionsize2 = groupOptionAll('content');
	ok (($optionsize2 eq 3), 'Group content options 2');

	groupOptionDelete('content', 'blobber');
	ok ((not defined groupOption('content', 'blobber')), 'Deleting option');

	copy './t/original/export.dump', './t/output/export.dump';
	export2file($outdir . 'export.dump');
	ok(compare_files('./t/output/export.dump', './t/reference/export.dump'), 'Exporting to file');

	copy './t/original/remove.dump', './t/output/remove.dump';
	export2file($outdir . 'remove.dump', 1);
	ok(compare_files('./t/output/remove.dump', './t/reference/remove.dump'), 'Removing from file');
};

sub compare_files {
	my ($fa, $fb) = @_;
	unless (open(FILEA, "<$fa")) {
		warn "cannot open $fa";
		return 0;
	}
	my $a = '';
	while (my $la = <FILEA>) { $a = "$a$la" }
	close FILEA;
	unless (open(FILEB, "<$fb")) {
		warn "cannot open $fb";
		return 0;
	}
	my $b = '';
	while (my $lb = <FILEB>) { $b = "$b$lb" }
	close FILEB;
	return $a eq $b
}
