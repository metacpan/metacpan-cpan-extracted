use strict;
use FindBin;
use Test::More;

use Getopt::Long;
use Tk;
use Tk::FreeDesktop::Wm;

my $doit;
GetOptions('doit' => \$doit)
    or die "usage: $0 [-doit]\n";

if (!$doit) {
    plan skip_all => 'experiments not activated (try -doit switch)';
}

my $mw = eval { tkinit };
if (!$mw) {
    plan skip_all => 'Cannot create MainWindow';
} else {
    plan 'no_plan';
}
$mw->geometry("+1+1"); # for twm

$mw->update;
my($wr) = $mw->wrapper;

my $fd = Tk::FreeDesktop::Wm->new;
ok $fd;

my %supported = map {($_,1)} $fd->supported;

{ # XXX no effect on metacity or fvwm:
    my $t = $mw->Toplevel;
    $t->geometry("+1+1"); # for twm
    for my $type (qw(_NET_WM_WINDOW_TYPE_DESKTOP
		     _NET_WM_WINDOW_TYPE_DIALOG
		     _NET_WM_WINDOW_TYPE_DOCK
		     _NET_WM_WINDOW_TYPE_MENU
		     _NET_WM_WINDOW_TYPE_NORMAL
		     _NET_WM_WINDOW_TYPE_TOOLBAR
		   )) {
	diag "Try $type...";
	$fd->set_window_type($type, $t);
	$t->update;
	system('xprop', '-id', $t->id);
	$t->after(100);
    }
}

SKIP: {
    skip '_NET_CLIENT_LIST_STACKING not supported', 2
	if !$supported{_NET_CLIENT_LIST_STACKING};

    $mw->raise;
    $mw->update;
    my @windows = $fd->client_list_stacking;

    local $TODO = "Usually fails if there are other stay-on-top windows";
    is($windows[-1], $wr,
       "Our window's wrapper should be on top (last in list)")
	or diag "@windows";
}

SKIP: {
    skip '_NET_DESKTOP_NAMES not supported', 1
	if !$supported{_NET_DESKTOP_NAMES};

    local $TODO = "fvwm 2.5.16 claims to support it, but fails!";
    my @names = $fd->desktop_names;
    diag "desktop names: " . explain(@names);
}


# XXX SKIP?
{
    diag 'wm_desktop';
    diag explain [$fd->wm_desktop];
    # XXX equals current desktop?
}

# XXX SKIP?
{
    diag 'wm_state';
    diag explain [$fd->wm_state];
}

# XXX SKIP?
{
    diag 'wm_visible_name';
    diag explain [$fd->wm_visible_name]; # XXX???
}

# XXX SKIP?
{
    diag 'wm_window_type';
    diag explain [$fd->wm_window_type]; # XXX???
}

if (0) {
    eval {
	my($wrapper)=$mw->wrapper;
	$mw->property('set','_NET_WM_STATE','ATOM',32,["_NET_WM_STATE_STICKY"],$wrapper); # sticky
	$mw->property('set','_NET_WM_LAYER','ATOM',32,["_NET_WM_STATE_STAYS_ON_TOP"],$wrapper); # ontop
    };
    warn $@ if $@;
}

eval {
    warn $mw->property('get','_NET_WM_PID',"root");
};
warn $@ if $@;

