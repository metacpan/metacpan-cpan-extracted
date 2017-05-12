#
# $Id: 01_use.t 4553 2010-09-23 10:52:20Z james $
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
is($Text::Indent::VERSION, '0.02', 'check module version');

#
# EOF
