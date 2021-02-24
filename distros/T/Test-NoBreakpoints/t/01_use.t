use strict;
use warnings;

BEGIN {
    use Test::More;
    our $tests = 1;
    eval "use Test::NoWarnings";
    $tests++ unless ($@);
    plan tests => $tests;
}

use_ok('Test::NoBreakpoints');
local $Test::NoBreakpoints::VERSION = $Test::NoBreakpoints::VERSION || 'from repo';
note("List::Uniq $Test::NoBreakpoints::VERSION, Perl $], $^X");
