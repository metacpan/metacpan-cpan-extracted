#!perl -w

use strict;
use FindBin;
use lib $FindBin::RealBin;
use Test::More;

use Getopt::Long;

use Tk;
use Tk::FreeDesktop::Wm;

use TestUtil; # imports tk_sleep

my $interactive;
GetOptions(
	   'interactive' => \$interactive,
	  )
    or die "usage: $0 [-interactive]\n";

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

# Without transparency
$fd->set_wm_icon("$FindBin::RealBin/srtbike16.gif");
$mw->update;
$mw->tk_sleep(0.2);
$mw->messageBox(-message => 'continue') if $interactive;

# With transparency, and setting multiple icons, and using a png image from file
my $p = $mw->Photo(-file => "$FindBin::RealBin/srtbike32.xpm");
$fd->set_wm_icon(["$FindBin::RealBin/srtbike16.gif", $p, "$FindBin::RealBin/srtbike48.png"]);
$mw->update;
$mw->tk_sleep(0.2);
$mw->messageBox(-message => 'continue') if $interactive;

# Alpha images - this would use Imager if installed
$fd->set_wm_icon(["$FindBin::RealBin/srtbike16a.png", "$FindBin::RealBin/srtbike32a.png"]);

pass 'set wm icon';

$mw->update;
MainLoop if $interactive;

