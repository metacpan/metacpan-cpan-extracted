#!perl -T

#   00.load.t

use strict;
use warnings;
use Test::More 0.94 tests => 1;

BEGIN {
    use_ok(q{Tk::ROSyntaxText});
}

diag qq{Testing Tk::ROSyntaxText $Tk::ROSyntaxText::VERSION};

