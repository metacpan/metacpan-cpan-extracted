#!perl

#   19.scrollshort.t

use strict;
use warnings;
use English qw{-no_match_vars};
use Test::More 0.94;

use Tk;
use Tk::ROSyntaxText;

my $mw = eval { MainWindow->new(
    -title => q{Tk::ROSyntaxText: 19.scrollshort.t},
); };

if ($mw) {
    plan tests => 3;
}
else {
    plan skip_all => q{No display detected.};
}

my $rosyn = eval { $mw->ScrlROSyntaxText(-dark_style => 1); };

ok(! $EVAL_ERROR, q{Test widget instantiaton})
    or diag $EVAL_ERROR;

eval { $rosyn->pack(-fill => q{both}, -expand => 1); };

ok(! $EVAL_ERROR, q{Test widget packing})
    or diag $EVAL_ERROR;

my $code_for_scrolling = <<'END_CODE';
package Tk::ROSyntaxText;

use strict;
use warnings;

our $VERSION = '1.000';

use Tk;
use base qw{Tk::Derived Tk::ROText};

use Syntax::Highlight::Engine::Kate::All;
use Syntax::Highlight::Engine::Kate 0.06;
use Carp;

Construct Tk::Widget q{ROSyntaxText};

# ...
END_CODE

eval { $rosyn->insert($code_for_scrolling); };

ok(! $EVAL_ERROR, q{Test text insertion})
    or diag $EVAL_ERROR;

my $exit_button
    = $mw->Button(-text => q{Exit}, -command => sub { exit; })->pack();

if (! $ENV{CPAN_TEST_AUTHOR}) {
    $exit_button->invoke();
}

MainLoop;

