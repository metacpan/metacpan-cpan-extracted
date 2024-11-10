use strict;
use warnings;

use Test::Tk;
$mwclass = 'Tk::AppWindow';

use Test::More tests => 4;
BEGIN { 
	use_ok('Tk::AppWindow::Ext::Panels');
};


createapp(
	-extensions => [qw[Panels]],
	-panelgeometry => 'grid',
	-panellayout => [
		CENTER => {
			-in => 'MAIN',
			-weight => 1,
			-column => 0,
			-row => 1,
			-sticky => 'nsew',
		},
		WORK => {
			-in => 'CENTER',
			-column => 2,
			-row => 0,
			-sticky => 'nsew',
			-weight => 1,
		},
		TOP => {
#			-weight => 1,
			-in => 'MAIN',
			-column => 0,
			-row => 0,
			-sticky => 'ew',
		},
		BOTTOM => {
#			-weight => 1,
			-in => 'MAIN',
			-column => 0,
			-row => 2,
			-sticky => 'ew',
			-canhide => 1,
		},
		LEFT => {
#			-weight => 1,
			-in => 'CENTER',
			-column => 0,
			-row => 0,
			-sticky => 'ns',
			-canhide => 1,
			-adjuster => 'left',
		},
		RIGHT => {
#			-weight => 1,
			-in => 'CENTER',
			-column => 4,
			-row => 0,
			-sticky => 'ns',
			-canhide => 1,
			-paneloptions => [-width => 150],
			-adjuster => 'right',
		},
	
	],
# 	-barsizers => [qw[]],
# 	-fullsizebars => 'horizontal',
);

my $ext;
if (defined $app) {
	$ext = $app->extGet('Panels');

	my %visible = ();
	my $f = $app->Subwidget('WORK')->Frame(-relief => 'groove')->pack(-expand => 1, -fill => 'both');
	for (qw[LEFT RIGHT TOP BOTTOM]) {
		my $panel = $_;
		my $t = $app->Subwidget($panel)->Label(-relief => 'groove', -text => $panel)->pack(-expand => 1, -fill => 'both');
		$ext->panelShow($panel);
		my $var = 1;
		$visible{$_} = \$var;
		$f->Checkbutton(
			-text => $_,
			-variable => \$var,
			-command => sub {
				my $vis = $visible{$panel};
				if ($$vis) {
					$ext->panelShow($panel);
				} else {
					$ext->panelHide($panel);
				}
			}
		)->pack(-anchor => 'w');
	}
}

@tests = (
	[sub { return $ext->Name eq 'Panels' }, 1, 'extension Panels loaded']
);

starttesting;
