use strict;
use warnings;

use Test::Tk;
$mwclass = 'Tk::AppWindow';

use Test::More tests => 4;
BEGIN { 
	use_ok('Tk::AppWindow::Ext::SideBars');
};


createapp(
	-extensions => [qw[Art MenuBar SideBars]],
);

my $ext;
if (defined $app) {

#	my $art = $app->extGet('Art');
#	my @themes = $art->AvailableThemes;
#	for (@themes) { print "$_\n" };
#	$app->configPut(-icontheme => 'Oxygen');
#	my $editcut = $app->getArt('edit-cut', 32);
#	print "icon found\n" if defined $editcut;
	my $panels = $app->extGet('Panels');
	my $bframe= $app->Frame->pack;
	$bframe->Button(
		-text => '22',
		-command => sub {
			$ext->configPut(-sidebariconsize => 22);
			$ext->ReConfigure;
		}
	)->pack(-side => 'left');
	$bframe->Button(
		-text => '32',
		-command => sub {
			$ext->configPut(-sidebariconsize => 32);
			$ext->ReConfigure;
		}
	)->pack(-side => 'left');
	$bframe->Button(
		-text => 'Add page',
		-command => sub {
			unless ($ext->pageExists('BOTTOM', 'BOTTOM')) {
				my $page = $ext->pageAdd('BOTTOM', 'BOTTOM', 'edit-paste', 'BOTTOM');
				$page->Label(-width => 12, -height => 8, -text => 'bottom')->pack(-expand => 1, -fill, 'both');
				if ($ext->pageCount('BOTTOM')) {				
					$panels->panelShow('BOTTOM');
				} else {
					$panels->panelHide('BOTTOM');
				}
			}
		}
	)->pack(-side => 'left');
	$bframe->Button(
		-text => 'Remove page',
		-command => sub {
			if ($ext->pageExists('BOTTOM', 'BOTTOM')) {
				$ext->pageDelete('BOTTOM', 'BOTTOM') if $ext->pageExists('BOTTOM', 'BOTTOM');
				if ($ext->pageCount('BOTTOM')) {				
					$panels->panelShow('BOTTOM');
				} else {
					$panels->panelHide('BOTTOM');
				}
			}
		}
	)->pack(-side => 'left');

	$app->Subwidget('WORK')->Label(
		-relief => 'raised',
		-text => 'WORK',
		-width => 20,
		-height => 10,
		-borderwidth => 2,
	)->pack(-expand => 1, -fill => 'both');
	$ext = $app->extGet('SideBars');
	$app->geometry('640x400+100+100');
	for (qw[LEFT RIGHT TOP BOTTOM]) {
		my $panel = $_;
		$ext->nbAdd($panel, $panel, lc($panel));
		my $img;
		$img = 'edit-cut' unless $panel eq 'TOP';
		$ext->nbTextSide($panel, 'right') if $panel eq 'BOTTOM';
		my $page = $ext->pageAdd($panel, $panel, $img, $panel);
		$page->Label(-width => 12, -height => 8, -text => $panel)->pack(-expand => 1, -fill, 'both');
	}
}

@tests = (
	[sub { return $ext->Name eq 'SideBars' }, 1, 'extension SideBars loaded']
);

starttesting;
