#!perl -w

use strict;
use FindBin;
use lib $FindBin::RealBin;
use Test::More;

if (!defined &explain) {
    require Data::Dumper;
    *explain = sub {
	Data::Dumper::Dumper($_[0]);
    };
}

use Getopt::Long;

use Tk;
use Tk::FreeDesktop::Wm;

use TestUtil; # imports tk_sleep

my $v = 1;
my $interactive;
GetOptions(
	   'q|quiet'     => sub { $v = 0 },
	   'v|verbose'   => sub { $v = 2 },
	   'interactive' => \$interactive,
	  )
    or die "usage: $0 [-quiet|-verbose] [-interactive]\n";

my $mw = eval { tkinit };
if (!$mw) {
    plan skip_all => 'Cannot create MainWindow';
} else {
    plan 'no_plan';
}
$mw->geometry("+1+1"); # for twm
$mw->update;
my($wr) = $mw->wrapper;

{
    my $fd = Tk::FreeDesktop::Wm->new;
    is $fd->mw, $mw, 'mw is by default the first MainWindow';
}

{
    ok !eval { Tk::FreeDesktop::Wm->new(foo => "bar") }, 'unhandled arguments';
    like $@, qr{unhandled argument}i, 'expected error message';
}

my $fd = Tk::FreeDesktop::Wm->new(mw => $mw);
isa_ok $fd, "Tk::FreeDesktop::Wm";
is $fd->mw, $mw;

my @supported = $fd->supported;
if ($v) {
    my $msg = "Supported:\n@supported\n";
    if (eval { require Text::Wrap; 1 }) {
	$msg = Text::Wrap::wrap('', '  ', $msg);
    }
    diag "\n$msg";
}
my %supported = map {($_,1)} @supported;

if (!@supported) {
    diag 'Probably not a freedesktop compliant wm, skipping remaining tests';
    exit 0;
}

SKIP: {
    skip '_NET_SUPPORTING_WM_CHECK not supported', 2
	if !$supported{_NET_SUPPORTING_WM_CHECK};
    my $ret = $fd->supporting_wm;
    is ref($ret), 'HASH', 'Got a return value';
    my $wm_name = $ret->{name};
    ok defined $wm_name, 'wm name is defined';
    if ($v) {
	diag "You're running $wm_name";
    }
    if ($v >= 2) {
	diag explain $ret;
    }
}

SKIP: {
    skip '_NET_CLIENT_LIST not supported', 1
	if !$supported{_NET_CLIENT_LIST};

    my @windows = $fd->client_list;
    ok((grep { $wr eq $_ } @windows),
       "At least our window's wrapper should list in client_list")
	or diag "Found just @windows, but not $wr";
}

SKIP: {
    skip '_NET_CLIENT_LIST_STACKING not supported', 2
	if !$supported{_NET_CLIENT_LIST_STACKING};

    my @windows = $fd->client_list_stacking;
    ok((grep { $wr eq $_ } @windows),
       "At least our window's wrapper should list in client_list_stacking")
	or diag "Found just @windows, but not $wr";
}

my $nr_of_desktops;

SKIP: {
    skip '_NET_NUMBER_OF_DESKTOPS not supported', 2
	if !$supported{_NET_NUMBER_OF_DESKTOPS};

    $nr_of_desktops = $fd->number_of_desktops;
    cmp_ok $nr_of_desktops, '>=', 1, 'There should be at least one desktop';
    if ($v) {
	diag "Number of desktops: $nr_of_desktops";
    }

    # The wm may ignore this
    $fd->set_number_of_desktops($nr_of_desktops + 1);
    $mw->update;

    # Reset
    $fd->set_number_of_desktops($nr_of_desktops);
    $mw->update;

    # But now we should be at the old number again
    my $nr_of_desktops2 = $fd->number_of_desktops;
    is $nr_of_desktops, $nr_of_desktops2, "Same number of desktops again: $nr_of_desktops";
}

SKIP: {
    skip '_NET_DESKTOP_GEOMETRY not supported', 2
	if !$supported{_NET_DESKTOP_GEOMETRY};
    my($dw,$dh) = $fd->desktop_geometry;
    cmp_ok $dw, '>=', $mw->screenwidth, 'Desktop geometry width is at least screen width';
    cmp_ok $dh, '>=', $mw->screenheight, 'Desktop geometry height is at least screen height';
}

SKIP: {
    skip '_NET_DESKTOP_VIEWPORT not supported', 2
	if !$supported{_NET_DESKTOP_VIEWPORT};

    my($vx,$vy) = $fd->desktop_viewport;
    ok defined $vx, 'Viewport X';
    ok defined $vy, 'Viewport Y';

    $fd->set_desktop_viewport(10, 10);
    $fd->set_desktop_viewport($vx, $vy);
}

SKIP: {
    skip '_NET_ACTIVE_WINDOW not supported', 1
	if !$supported{_NET_ACTIVE_WINDOW};

    my($oldx,$oldy) = ($mw->rootx, $mw->rooty);
    # feels hacky...
    for (1..5) {
	my($px,$py) = $mw->pointerxy;
	$mw->geometry("+".($px-10)."+".($py-10));
	$mw->focus;
	$mw->update;
	last if $fd->active_window == $wr;
	diag "Maybe the WM is slow? Sleep for a second ($_/5)...";
	$mw->tk_sleep(1);
    }
    is $fd->active_window, $wr, 'This window is the active one';
    $mw->geometry("+$oldx+$oldy");
}

SKIP: {
    skip '_NET_CURRENT_DESKTOP not supported', 2
	if !$supported{_NET_CURRENT_DESKTOP};

    my $cd = $fd->current_desktop;
    cmp_ok $cd, '>=', 0, "Current desktop is $cd";

 SKIP: {
	skip 'No number of desktops', 1
	    if !defined $nr_of_desktops;
	cmp_ok $cd, '<', $nr_of_desktops, 'Current desktop is smaller than number of desktops';
    }
}

SKIP: {
    skip '_NET_WORKAREA not supported', 2
	if !$supported{_NET_WORKAREA};
    my($x,$y,$x2,$y2) = $fd->workarea;
    ok defined $x, 'workarea left top';
    ok defined $y2, 'workarea right bottom';
    if ($v >= 2) {
	diag "workarea: ";
	diag explain [$x, $y, $x2, $y2];
    }
}

SKIP: {
    skip '_NET_VIRTUAL_ROOTS not supported', 0
	if !$supported{_NET_VIRTUAL_ROOTS};
    my(@w) = $fd->virtual_roots;
    # no test here
}

{
    my $desktop_file = $fd->wm_desktop_file;
    is $desktop_file, undef, 'no desktop file by default';

    $fd->set_wm_desktop_file("$FindBin::RealBin/10basic.desktop");
    $desktop_file = $fd->wm_desktop_file;
    is $desktop_file, "$FindBin::RealBin/10basic.desktop", 'set desktop file';
}

$mw->update;
MainLoop if $interactive;
