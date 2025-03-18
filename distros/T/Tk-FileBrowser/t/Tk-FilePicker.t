use strict;
use warnings;
use Test::More tests => 5;
use Test::Tk;
use Tk;
require Tk::LabFrame;
require Tk::ROText;

BEGIN {
	use_ok('Tk::FilePicker');
};

createapp;

my @padding = (-padx => 2, -pady => 2);
my $fp;
if (defined $app) {
#	$app->geometry('640x400+100+100');
	$fp = $app->FilePicker(
	);
	my $singlef = $app->LabFrame(
		-label => 'Single selection',
		-labelside => 'acrosstop',
	)->pack(@padding, -fill => 'x');
	my $singlev = '';
	$singlef->Button(
		-text => 'Pick save',
		-command => sub {
			($singlev) = $fp->pickFileSave(
#				-initialfile => 'woobadooba',
#				-initialdir => $ENV{HOME},
			);
		},
	)->pack(@padding, -fill => 'x');
	my $se = $singlef->Entry(
		-textvariable => \$singlev,
		-width => 80
	)->pack(@padding, -fill => 'x');

	my $multif = $app->LabFrame(
		-label => 'Multi selection',
		-labelside => 'acrosstop',
	)->pack(@padding, -fill => 'x');
	my $mt;
	$multif->Button(
		-text => 'Pick open',
		-command => sub {
			my @sel = $fp->pickFileOpenMulti(
				-initialdir => 't',
			);
			$mt->delete('0.0', 'end');
			for (@sel) {
				$mt->insert('end', "$_\n")
			}
		},
	)->pack(@padding, -fill => 'x');
	$mt = $multif->Scrolled('ROText',
		-scrollbars => 'osoe',
		-width => 80,
		-height => 6,
	)->pack(@padding, -expand => 1, -fill => 'both');

	my $folderf = $app->LabFrame(
		-label => 'Folder selection',
		-labelside => 'acrosstop',
	)->pack(@padding, -fill => 'x');
	my $folderv = '';
	$folderf->Button(
		-text => 'Pick folder',
		-command => sub {
			($folderv) = $fp->pickFolderSelect(
			);
		},
	)->pack(@padding, -fill => 'x');
	my $fe = $folderf->Entry(
		-textvariable => \$folderv,
		-width => 80
	)->pack(@padding, -fill => 'x');
}

testaccessors($fp, 'lastfolder');

push @tests, (
	[ sub { return defined $fp }, 1, 'Tk::FilePicker created' ],
);


starttesting;



