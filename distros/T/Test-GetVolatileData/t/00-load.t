#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 4;

BEGIN {
    use_ok('Carp');
    use_ok('LWP::UserAgent');
    use_ok('Exporter');
    use_ok( 'Test::GetVolatileData' ) || print "Bail out!\n";
}

diag( "Testing Test::GetVolatileData $Test::GetVolatileData::VERSION, Perl $], $^X" );

