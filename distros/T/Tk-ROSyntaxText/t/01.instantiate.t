#!perl -T

#   01.instantiate.t

use strict;
use warnings;
use English qw{-no_match_vars};
use Test::More 0.94;

use Tk;
use Tk::ROSyntaxText;

my $mw = eval { MainWindow->new(
    -title => q{Tk::ROSyntaxText: 01.instantiate.t},
); };

if ($mw) {
    plan tests => 3;
}
else {
    plan skip_all => q{No display detected.};
}

my $rosyn = eval { $mw->ROSyntaxText(); };

ok(! $EVAL_ERROR, q{Test widget instantiaton})
    or diag $EVAL_ERROR;

eval { $rosyn->pack(); };

ok(! $EVAL_ERROR, q{Test widget packing})
    or diag $EVAL_ERROR;

eval { $rosyn->destroy(); };

ok(! $EVAL_ERROR, q{Test widget destruction})
    or diag $EVAL_ERROR;

