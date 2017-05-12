use strict;
use warnings;

use Test;

BEGIN { plan tests => 4 };

use Tk::HideCursor;
use Tk;

ok(1); # If we made it this far, we're ok.

my $mw = MainWindow->new();
ok(2);

$mw->hideCursor();
ok(3);

$mw->showCursor();
ok(4);

