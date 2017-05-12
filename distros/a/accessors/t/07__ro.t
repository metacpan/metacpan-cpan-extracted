#!/usr/bin/perl

##
## Tests for accessors::ro
##

use strict;
use warnings;

use Test::More tests => 13;
use Carp;

BEGIN { use_ok( "accessors::ro" ) };

my $time = shift || 0.5;

my $foo = bless { bar => 'read only' }, 'Foo';
can_ok( $foo, 'bar' );
can_ok( $foo, 'baz' );

is( $foo->bar( 'noop' ), 'read only', 'set foo->bar blocked' );
is( $foo->bar, 'read only', 'get foo->bar' );
is( $foo->baz, undef,       'get foo->baz' );
$foo->{baz} = 'set';
is( $foo->baz, 'set',       'get foo->baz' );

SKIP: {
    skip '$ENV{BENCHMARK_ACCESSORS} not set', 6 unless ($ENV{BENCHMARK_ACCESSORS});
    eval "use Benchmark qw( timestr countit )"; # ya never know...
    skip 'Benchmark.pm not installed!', 6 if ($@);
    eval "use t::Benchmark";
    die $@ if $@;

    test_generation_performance( 'accessors::ro' );

    test_set_get_performance( time      => $time,
			      generated => bless( {}, 'Generated' ),
			      hardcoded => bless( {}, 'HardCoded' ),
			      optimized => bless( {}, 'Optimized' ), );
}


package Foo;
use accessors::ro qw( bar baz );

# use different classes w/same accessor name + variable length
# for performance tests...
package Generated;
use accessors::ro qw( foo );
package HardCoded;
sub foo {
    my $self = shift;
    return $self->{foo};
}
package Optimized;
sub foo {
    return $_[0]->{'foo'};
}
