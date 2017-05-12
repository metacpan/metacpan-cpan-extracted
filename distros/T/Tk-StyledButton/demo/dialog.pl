use Tk;
use Tk::StyledDialog;

use strict;
use warnings;

my ($color, $shape, $style, $cmpd, $orient) = ('orange', 'rectangle', 'shiny', 'center', 'nw');

my $tip;
my ($w, $h);
my $useimg;
my $capture;

while (scalar @ARGV) {
	my $opt = shift @ARGV;

	$color = shift @ARGV,
	next
		if ($opt eq '-c');

	$shape = shift @ARGV,
	next
		if ($opt eq '-s');

	$style = shift @ARGV,
	next
		if ($opt eq '-f');

	$cmpd = shift @ARGV,
	next
		if ($opt eq '-a');

	$orient = shift @ARGV,
	next
		if ($opt eq '-o');

	$tip = shift @ARGV,
	next
		if ($opt eq '-t');

	$w = shift @ARGV,
	next
		if ($opt eq '-w');

	$h = shift @ARGV,
	next
		if ($opt eq '-h');

	$useimg = 'image',
	next
		if ($opt eq '-i');

	$useimg = 'bitmap',
	next
		if ($opt eq '-b');

	$capture = 1, next
		if ($opt eq '-g');
}

my @shapes = ('rectangle', 'oval', 'round', 'folio', 'bevel');
my @styles = ('flat', 'round', 'shiny', 'gel');
my @cmpds = ('top', 'bottom', 'center', 'left', 'right', 'none');
my @orients = ('n', 's', 'w', 'e', 'nw', 'ne', 'sw', 'se', 'en', 'es', 'wn', 'ws');

my $count = 1;
#my $btntext = join(',', $shapes[$shape], $styles[$style], $cmpds[$cmpd], $count);
my $btntext = join(',', $shape, $style, $cmpd, $count);
my $mw = MainWindow->new();

my $img = $mw->Photo(-data => components_gif(), -format => 'gif');
my $bitmap = 'question';
my $angle = (($style eq 'shiny') && ($shape eq 'round')) ? 0.04 : 0.08;
my $button;

my $dialog;

$button = $mw->StyledButton(
-text => 'Show it',
-shape => $shape,
-style => $style,
-angle => $angle,
-dispersion => 0.61,
-command => sub {
	$dialog->Show();
	},
-background => $color,
-foreground => 'black',
#-compound => $cmpd,
#-padx => 10,
#-pady => 10
)->pack();

my %args = (
-text => 'This is a sample StyledDialog',
-shape => $shape,
-style => $style,
-angle => $angle,
-dispersion => 0.61,
-buttons => [ 'OK', 'Cancel' ],
#-background => $color,
#-foreground => 'black',
#-compound => $cmpd,
#-padx => 10,
#-pady => 10
);

#$args{"-$useimg"} = (($useimg eq 'image') ? $img : $bitmap) if $useimg;
#$args{-tooltip} = [ $tip, 400 ] if $tip;

#$args{-width} = $w if $w;
#$args{-height} = $h if $h;
#$args{-orient} = $orient if $orient;

$dialog = $mw->StyledDialog(%args);

$dialog->Subwidget('B_OK')->configure(-background => $color, -width => 100);
$dialog->Subwidget('B_Cancel')->configure(-background => $color, -width => 100);

print $dialog->Subwidget('B_OK')->cget('-style'), "\n";

MainLoop();

sub capture {

	my ($activeimg, $activecoords, $idleimg, $idlecoords) =
		$button->capture(-omittext => 0, -omitimage => 0, -format => 'png');

	print STDERR $@ unless ($activeimg && $idleimg);
	open OUTFD, '>activeimg.gif';
	binmode OUTFD;
	print OUTFD $activeimg;
	close OUTFD;

	print "Active coords are: ", join(', ', @$activecoords), "\n";

	open OUTFD, '>idleimg.gif';
	binmode OUTFD;
	print OUTFD $idleimg;
	close OUTFD;
	print "Idle coords are: ", join(', ', @$idlecoords), "\n";
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

