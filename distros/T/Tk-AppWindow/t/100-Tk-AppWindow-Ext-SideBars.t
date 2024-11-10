use strict;
use warnings;

use Test::Tk;
$mwclass = 'Tk::AppWindow';
$delay = 2000;

use Test::More tests => 5;
BEGIN { 
	use_ok('Tk::AppWindow::Ext::SideBars');
};


createapp(
	-extensions => [qw[Art MenuBar SideBars]],
	-panellayout => [
		CENTER => {
			-in => 'MAIN',
			-side => 'top',
			-fill => 'both',
			-expand => 1,
		},
		SUBCENTER => {
			-in => 'CENTER',
			-side => 'left',
			-fill => 'both',
			-expand => 1,
		},
		WORK => {
			-in => 'SUBCENTER',
			-side => 'top',
			-fill => 'both',
			-expand => 1,
		},
		TOOL => {
			-in => 'SUBCENTER',
			-after => 'WORK',
			-side => 'top',
			-fill => 'x',
#				-expand => 1,
			-canhide => 1,
			-paneloptions => [-borderwidth  => 3, -relief => 'raised'],
			-adjuster => 'bottom',
		},
		TOP => {
			-in => 'MAIN',
			-side => 'top',
			-before => 'CENTER',
			-fill => 'x',
			-canhide => 1,
			-paneloptions => [-borderwidth  => 3, -relief => 'raised'],
		},
		BOTTOM => {
			-in => 'MAIN',
			-after => 'CENTER',
			-side => 'top',
			-fill => 'x',
			-canhide => 1,
			-paneloptions => [-borderwidth  => 3, -relief => 'raised'],
		},
		LEFT => {
			-in => 'CENTER',
			-before => 'SUBCENTER',
			-side => 'left',
			-fill => 'y',
			-canhide => 1,
#			-paneloptions => [-width => 150],
			-adjuster => 'left',
		},
		RIGHT => {
			-in => 'CENTER',
			-after => 'SUBCENTER',
			-side => 'left',
			-fill => 'y',
			-canhide => 1,
#			-paneloptions => [-width => 150],
			-paneloptions => [-borderwidth  => 3, -relief => 'raised'],
			-adjuster => 'right',
		},
	],
);

my $ext;
if (defined $app) {
	my $panels = $app->extGet('Panels');
#	my $art = $app->extGet('Art');
#	my @themes = $art->AvailableThemes;
#	for (@themes) { print "$_\n" };
#	$app->configPut(-icontheme => 'Oxygen');
#	my $editcut = $app->getArt('edit-cut', 32);
#	print "icon found\n" if defined $editcut;
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
				my $page = $ext->pageAdd('BOTTOM', 'BOTTOM', 'edit-cut', 'BOTTOM');
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
#		-width => 20,
#		-height => 10,
		-borderwidth => 2,
	)->pack(-expand => 1, -fill => 'both');
	$ext = $app->extGet('SideBars');
	$app->geometry('640x400+100+100');
	for (qw[LEFT RIGHT TOP TOOL BOTTOM]) {
		my $panel = $_;
		my $tabside = lc($panel);
		$tabside = 'bottom' if $panel eq 'TOOL';
		$ext->nbAdd($panel, $panel, $tabside);
		my $img;
		$img = 'edit-cut' unless $panel eq 'TOP';
		$ext->nbTextSide($panel, 'right') if $panel eq 'BOTTOM';
		my $page = $ext->pageAdd($panel, $panel, $img, $panel);
		$page->Label(-width => 12, -height => 8, -text => $panel)->pack(-expand => 1, -fill, 'both');
	}
#	$app->after(100, sub {
#		$app->geoAddCall('WORK', sub {
#			my $w = $app->Subwidget('WORK');
#			my $c = $app->Subwidget('SUBCENTER');
#			my $t = $app->Subwidget('TOOL');
#			$w->pack(
#				-in => $c,
##				-before => $t,
#				-expand => 1,
#				-fill => 'both',
#			);
#		});
#	});
}
testaccessors($ext, qw/IconSize/);
push @tests, 
	[sub { return $ext->Name eq 'SideBars' }, 1, 'extension SideBars loaded']
;

starttesting;
