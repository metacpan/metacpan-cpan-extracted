use strict;
use warnings;

BEGIN {
    use Test::More;
    our $tests = 1;
    eval "use Test::NoWarnings";
    $tests++ unless( $@ );
    plan tests => $tests;
}

use_ok('Text::Indent');
local $Text::Indent::VERSION = $Text::Indent::VERSION || 'from repo';
note("Text::Indent $Text::Indent::VERSION, Perl $], $^X");
