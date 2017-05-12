#!perl

# This is the test case for Bug 56722.  This bug was found by Kevin Ryde.
# He also suggested the right fix and supplied the core of the test case.

use strict;
use warnings;

use Test::More tests => 3;
use Data::Dumper;

use lib 't/lib';
use Test::Weaken::Test;

BEGIN {
    Test::More::use_ok('Test::Weaken');
}

our $OVERLOAD_CALLS = 0;

package MyOverload;
use Carp;
use overload '+'    => \&add;
use overload 'bool' => \&bool;

sub new {
    my ( $class, $x ) = @_;
    return bless \$x, $class;
}

sub bool { $::OVERLOAD_CALLS++; return 1; }
sub add  { $::OVERLOAD_CALLS++; return 0; }

package main;

my $x = MyOverload->new('123');

my $leaks = Test::Weaken::leaks(
    sub {
        my $y = MyOverload->new('123');
        return [ $x, $y ];
    }
);

Test::More::ok( $leaks, 'CPAN Bug ID 56722 leaks' );
Test::Weaken::Test::is( $::OVERLOAD_CALLS, 0,
    'CPAN Bug ID 56722 no calls to overload functions' );
