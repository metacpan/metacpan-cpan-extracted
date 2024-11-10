
use strict;
use warnings;
use Test::More tests => 14;
use Test::Tk;
use MIME::Base64;
require Tk::LabFrame;
$mwclass = 'Tk::AppWindow';
my @iconpath = ('t/Themes');

use Config;
my $osname = $Config{'osname'};

BEGIN { use_ok('Tk::AppWindow::Ext::Art') };

createapp(
	-extensions => ['Art'],
	-iconpath => \@iconpath,
	-icontheme =>  'png_1',
);

my $art;
my $tiframe;
my $cpframe;
if (defined $app) {
	$app->geometry('640x400+100+100') if defined $app;
	$art = $app->extGet('Art');
	$tiframe = $app->LabFrame(
		-label => 'Text to Image',
		-labelside => 'acrosstop',
	)->pack(-fill => 'x');
	$cpframe = $app->LabFrame(
		-label => 'Compounds',
		-labelside => 'acrosstop',
	)->pack(-fill => 'x');
}

push @tests, 
	[sub { return $art->Name }, 'Art', 'extension Art loaded'],
	[sub {
		$tiframe->Label(
			-relief => 'groove',
			-borderwidth => 2,
			-image => $art->text2image('text2image'),
		)->pack(-side => 'left', -padx => 5);
		return 1
	}, 1, 'text2image'],
	[sub {
		$tiframe->Label(
			-relief => 'groove',
			-borderwidth => 2,
			-image => $art->text2image('text2image', 90),
		)->pack(-side => 'left', -padx => 5);
		return 1
	}, 1, 'text2image rotate'],
	[sub {
		$cpframe->Label(
			-relief => 'groove',
			-borderwidth => 2,
			-image => $art->createCompound(
				-image => $art->getIcon('document-save', 32),
				-text => 'Groovy',
				-textside => 'left',
			),
		)->pack(-side => 'left', -padx => 5);
		return 1
	}, 1, 'compound left'],
	[sub {
		$cpframe->Label(
			-relief => 'groove',
			-borderwidth => 2,
			-image => $art->createCompound(
				-image => $art->getIcon('document-save', 32),
				-text => 'Groovy',
				-textrotate => 90,
				-textside => 'left',
			),
		)->pack(-side => 'left', -padx => 5);
		return 1
	}, 1, 'compound left rotated'],
	[sub {
		$cpframe->Label(
			-relief => 'groove',
			-borderwidth => 2,
			-image => $art->createCompound(
				-image => $art->getIcon('document-save', 32),
				-text => 'Groovy',
				-textside => 'right',
			),
		)->pack(-side => 'left', -padx => 5);
		return 1
	}, 1, 'compound right'],
	[sub {
		$cpframe->Label(
			-relief => 'groove',
			-borderwidth => 2,
			-image => $art->createCompound(
				-image => $art->getIcon('document-save', 32),
				-text => 'Groovy',
				-textside => 'right',
				-textrotate => 270,
			),
		)->pack(-side => 'left', -padx => 5);
		return 1
	}, 1, 'compound right rotate'],
	[sub {
		$cpframe->Label(
			-relief => 'groove',
			-borderwidth => 2,
			-image => $art->createCompound(
				-image => $art->getIcon('document-save', 32),
				-text => 'Groovy',
				-textside => 'top',
			),
		)->pack(-side => 'left', -padx => 5);
		return 1
	}, 1, 'compound top'],
	[sub {
		$cpframe->Label(
			-relief => 'groove',
			-borderwidth => 2,
			-image => $art->createCompound(
				-image => $art->getIcon('document-save', 32),
				-text => 'Groovy',
				-textside => 'top',
				-textrotate => 270,
			),
		)->pack(-side => 'left', -padx => 5);
		return 1
	}, 1, 'compound top rotate'],
	[sub {
		$cpframe->Label(
			-relief => 'groove',
			-borderwidth => 2,
			-image => $art->createCompound(
				-image => $art->getIcon('document-save', 32),
				-text => 'Groovy',
				-textside => 'bottom',
			),
		)->pack(-side => 'left', -padx => 5);
		return 1
	}, 1, 'compound bottom'],
	[sub {
		$cpframe->Label(
			-relief => 'groove',
			-borderwidth => 2,
			-image => $art->createCompound(
				-image => $art->getIcon('document-save', 32),
				-text => 'Groovy',
				-textside => 'bottom',
				-textrotate => 90,
			),
		)->pack(-side => 'left', -padx => 5);
		return 1
	}, 1, 'compound bottom rotate'],
;


starttesting;

