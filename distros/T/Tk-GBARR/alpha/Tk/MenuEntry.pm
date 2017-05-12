

package Tk::MenuEntry;

use Tk qw(Ev);
use strict;
use vars qw(@ISA $VERSION);

@ISA = qw(Tk::Derived Tk::Frame);
$VERSION = "0.02";

Construct Tk::Widget 'MenuEntry';

my $BITMAP;

sub ClassInit {
    my($class,$mw) = @_;

    unless(defined($BITMAP)) {
	$BITMAP = __PACKAGE__ . "::downarrow";

	my $bits = pack("b12"x5,".1111111111.",
				"..11111111..",
				"...111111...",
				"....1111....",
				".....11.....");

	$mw->DefineBitmap($BITMAP => 12,5, $bits);
    }
}

sub Populate {
    my($me,$args) = @_;

    $me->SUPER::Populate($args);

    my $sf = $me->Frame;

    my $b = $sf->Button(
	-bitmap => $BITMAP,
	-anchor => 'center',
	-highlightthickness => 0,
    )->pack(-fill => 'both', -expand => 1);

    $me->Advertise(Button => $b);

    $sf->packPropagate(0);
    $sf->GeometryRequest($b->ReqWidth + 2,1);
    $sf->pack(-side => 'right', -fill => 'y');

    my $e = $me->Entry(
	-borderwidth => 0,
	-highlightthickness => 0,
    )->pack(
	-side => 'left',
	-fill => 'both',
	-expand => 1
    );

    # popup shell for listbox with values.
    my $c = $me->Toplevel(-bd => 2,-relief => "raised");
    $c->overrideredirect(1);
    $c->withdraw;
    my $sl = $c->ScrlListbox(
	-scrollbars => 'oe',
	-selectmode => "browse",
	-exportselection => 0,
	-bd => 0,
	-width => 0,
	-highlightthickness => 0,
	-relief => "raised"
    )->pack(
	-expand => 1,
	-fill => "both"
    );

    $me->Advertise(Popup => $c);
    $me->Advertise(Listbox => $sl);

    $b->bind('<1>', [ $me, 'ButtonDown']);

    $b->bind('<ButtonRelease-1>', [$me, 'ButtonUp', $b]);
    $me->bind('<ButtonRelease-1>', [$me, 'ButtonUp', $me]);

    $sl = $sl->Subwidget('scrolled');

    $sl->bind('<ButtonRelease-1>', [$me, 'ButtonUp', $sl, Ev('index',Ev('@'))]);

    $me->ConfigSpecs(
	-background  => [SELF => qw(background  Background),  "#d9d9d9"],
	-borderwidth => [SELF => qw(borderWidth BorderWidth), 2],
	-relief	     => [SELF => qw(relief      Relief),      'sunken'],
	-highlightthickness
		     => [SELF => qw(highlightThickness HighlightThickness),2],
	-maxlines    => [PASSIVE => qw(maxLines MaxLines), 10],
	-menucreate  => [CALLBACK => undef, undef, undef],
    );

    $me->Default(Entry => $e);

    $me;
}

sub ButtonDown {
    my ($me) = @_;

    return
	if ($me->cget(-state) =~ /disabled/);

    my $tl = $me->Subwidget('Popup');
    if ($tl->ismapped) {
	$me->Unpost;
    } else {
	$me->Post;
    }
}

sub ButtonUp {
    my ($me,$where,$index) = @_;

    return
	if ($me->cget(-state) =~ /disabled/);

    my $tl = $me->Subwidget('Popup');

    if ($tl->ismapped) {
	if($where->isa('Tk::Button')) {
	    my $lb = $me->Subwidget("Listbox");

	    $lb->selectionClear(0,'end');
	    $lb->selectionSet(0);
	}
	else {
	    if($where->isa('Tk::Listbox')) {
		my $sel = $where->get($index);
		my $e = $me->Subwidget('Entry');
		$e->delete(0,'end');
		$e->insert(0,$sel);
	    }
	    $me->Unpost;
	}
    }
}

sub listInsert	{ shift->Subwidget('Listbox')->insert(@_) }
sub listGet	{ shift->Subwidget('Listbox')->get(@_)	  }
sub listDelete	{ shift->Subwidget('Listbox')->delete(@_) }

sub Unpost {
    my ($me) = @_;
    my $tl = $me->Subwidget('Popup');

    if ($tl->ismapped) {
	$tl->withdraw;
	$me->grabRelease;
	$me->Subwidget('Button')->butUp;
    }
}

sub Post {
    my ($me) = @_;
    my $tl = $me->Subwidget('Popup');

    unless($tl->ismapped) {
	my $mc = $me->{Configure}{-menucreate};

	$mc->Call($me)
	    if defined $mc;

	my $lb = $me->Subwidget("Listbox");
	my $x = $me->rootx;
        my $y = $me->rooty + $me->height;
	my $size = $lb->size;
	my $msize = $me->{Configure}{-maxlines};

	$size = $msize
	    if $size > $msize;
	$size = 1
	    if(($size = int($size)) < 1);

	$lb->configure(-height => $size);
	# Scrolled turns propagate off, but I need it on
	$lb->Tk::pack('propagate',1);
	$lb->update;

	$x = 0
	    if $x < 0;
	$y = 0
	    if $y < 0;

	my $vw = $me->vrootwidth;
	my $rw = $tl->ReqWidth;
	my $w = $me->rootx + $me->width - $x;

	$w = $rw
	    if $rw > $w;
	$x =  $vw - $w
	    if(($x + $w) > $vw);

	my $vh = $me->vrootheight;
	my $h = $tl->ReqHeight;

	$y = $vh - $h
	    if(($y + $h) > $vh);

	$tl->geometry(
	    sprintf("%dx%d+%d+%d",$w, $h, $x, $y)
	);

	$tl->deiconify;
	$tl->raise;

	$me->Subwidget("Entry")->focus;

	$tl->configure(-cursor => "arrow");

	$lb->selectionClear(0);
	$lb->yview('moveto',0);
	$me->grabGlobal;
    }
}

1;
