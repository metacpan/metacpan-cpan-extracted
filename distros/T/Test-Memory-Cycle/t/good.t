#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::Builder::Tester tests => 2;
use Test::More;
use lib 't';
use Foo;

BEGIN {
    use_ok( 'Test::Memory::Cycle' );
}

GOOD: {
    my $cgi = new Foo;

    memory_cycle_ok( $cgi, "Foo doesn't leak" );
}
