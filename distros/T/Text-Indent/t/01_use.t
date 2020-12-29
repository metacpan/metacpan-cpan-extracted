#
# $Id$
#

use strict;
use warnings;

BEGIN {
    use Test::More;
    our $tests = 2;
    eval "use Test::NoWarnings";
    $tests++ unless( $@ );
    plan tests => $tests;
}

use_ok('Text::Indent');
is($Text::Indent::VERSION, '0.031', 'check module version');

#
# EOF
