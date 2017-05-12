#! perl

# tests from RT #49580, where calling ->isa() may recurse into ->can()
package Test::Overloaded::String;

use strict;
use warnings;
use overload '""' => sub { $_[0]->can('bar') };

sub new { bless {}, shift }

sub bar {1}

1;

package main;

use strict;
use warnings;
use Test::More tests => 1;
use UNIVERSAL::can;

my $foo = Test::Overloaded::String->new;

ok( "$foo",  "Didn't segfault" );
