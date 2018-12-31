#
# $Id$
#

use strict;
use warnings;

BEGIN {
    use Test::More;
    our $tests = 3;
    eval "use Test::NoWarnings";
    $tests++ unless( $@ );
    plan tests => $tests;
}

use_ok('Text::Indent');

eval { Text::Indent->new };
ok( ! $@, "can create an object");
eval {  Text::Indent->new( Foo => 'Bar' ) };
ok( $@, "constructor dies on invalid args");

#
# EOF
