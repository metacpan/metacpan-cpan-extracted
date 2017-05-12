use strict;
use vars qw($loaded $hasgd);
BEGIN {
	$^W= 1;
	$| = 1;
	eval {
		require 'GD';
		require 'GD::Text::Wrapped';
	};

	$hasgd = $@ ? undef : 1;

#	if ($hasgd) {
#		print "1..16\n";
#	}
#	else {
		print "1..21\n";
#	}
}

END {
	print "not ok 1\n" unless $loaded;
}

use Tk;
use Tk::Photo;
use Tk::StyledButton;

use strict;
use warnings;

$loaded = 1;
my $testno = 2;

print "ok 1\n";

my @shapes = ('rectangle', 'oval', 'round', 'bevel', 'folio');
my @styles = ('flat', 'round', 'shiny', 'gel');
#push @styles, 'image' if $hasgd;

my %activeimgs = ();
my %idleimgs = ();

my ($shape, $style) = (0,0);

my $count = 0;
my $mw = MainWindow->new();
#
#	if GD available, load image buttons from DATA
#
if (1 == 0) {
$activeimgs{$_} = $mw->Photo(-file => "act$_.png"),
$idleimgs{$_} = $mw->Photo(-file => "idle$_.png")
	foreach ('square', 'oval', 'round');
}
	my $button = $mw->StyledButton(
		-shape => $shapes[$shape],
		-style => $styles[$style],
		-angle => 0.08,
		-dispersion => 0.61,
		-background => '#4D004D00B300',
		-command => sub { $count++; },
		-width => 100,
		-height => ($shape eq 'round') ? 100 : 40,
		-padx => 10,
		-pady => 10)->pack();

my $evt = $mw->repeat(500, \&updateButton);

MainLoop();

sub updateButton {
	print "ok $testno\n";
	$testno++;
	my $btntext = "Button $testno";

	$style++;
	return ($styles[$style] eq 'image') ?
		$button->configure(
			-activeimage => $activeimgs{$shapes[$shape]},
			-idleimage => $idleimgs{$shapes[$shape]},
			-style => $styles[$style]) :
		$button->configure(
			-style => $styles[$style])
		unless ($style >= scalar @styles);

	$style = 0;
	$shape++;
	if ($shape >= scalar @shapes) {
		$evt->cancel();
		exit(0);
	}

	return ($styles[$style] eq 'image') ?
		$button->configure(
			-activeimage => $activeimgs{$shapes[$shape]},
			-idleimage => $idleimgs{$shapes[$shape]},
			-shape => $shapes[$shape],
			-style => $styles[$style]) :
		$button->configure(
			-shape => $shapes[$shape],
			-style => $styles[$style],
			-width => 100,
			-height => ($shapes[$shape] eq 'round') ? 100 : 40,
			);
}
