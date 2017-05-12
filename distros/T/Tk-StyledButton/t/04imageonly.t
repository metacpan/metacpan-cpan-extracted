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
my @cmpds = ('center', 'left', 'right', 'top', 'bottom');

my %activeimgs = ();
my %idleimgs = ();

my ($shape, $style) = (0,0);

my $count = 1;
my $mw = MainWindow->new();

my $img = $mw->Photo(-data => components_gif(), -format => 'gif');
#
#	if GD available, load image buttons
#
#$activeimgs{$_} = $mw->Photo(-file => "act$_.png"),
#$idleimgs{$_} = $mw->Photo(-file => "idle$_.png")
#	foreach ('square', 'oval', 'round');

	my $button = $mw->StyledButton(
		-shape => $shapes[$shape],
		-style => $styles[$style],
		-angle => 0.08,
		-dispersion => 0.61,
		-background => '#4D004D00B300',
		-foreground => 'yellow',
		-command => sub { $count++; },
		-image => $img,
		-padx => 10,
		-pady => 10)->pack();

my $evt = $mw->repeat(500, \&updateButton);
#$mw->after(5000, sub { $button->configure(-compound => 'center'); });
#$mw->after(7000, sub { $button1->flash(0); });

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
			-style => $styles[$style]);
}

sub components_gif {
	my $binary_data = <<EOD;
R0lGODlhGAAYAPcAAP8A/wAAAP///wD/AAD//wCZAMzMzAAA/wAAmZmZmf//AJmZAP8AAMwAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACwAAAAAGAAYAAAI/wABNAhA
sKDBgwgDAECwIIFDAQIMQHSYoACBiwQKaBygEIFDAwM0FjAg0UAAjBgJclxYkiREkQkQEMRYQGYC
hRQX6FyAAKKAmgcOBNCIQOhKAAkUKF3aM2LRoEIRyFy5QEHEpUoTCIgJNarQmw2SQjSwVCfJp0ED
SA3AMYACsksZNFBQIIHJrmoDVCSIVWkDBg0lClgQIG0Al3yrKqjaoPHIiYNlkiSpsKpiBXJN+hy6
1S7ihVb9am04sXGAsZ4VAggc0cBHynIbFPApUWHYmwTrtr4ZW7ZPAR0pCrcLnEHvBgs2L9Q6uXmC
v8Yby23aseRviAGMR2/sGDjL66W1HzRnoLe64N/ZxXMfONv8dZPQtzdOvbz5ZOAB4rOnqFqq///+
5UfeQv41AMCBCCaoIACqKRgQADs=
EOD
	return($binary_data);
	} # END components_gif...

