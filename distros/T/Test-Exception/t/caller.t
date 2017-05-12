#!/usr/bin/perl -Tw

# Make sure caller() is undisturbed.

use strict;
use warnings;

use Test::Exception;
use Test::More tests => 3;

eval { die caller() . "\n" };
is( $@, "main\n" );

throws_ok { die caller() . "\n" }  qr/^main$/;


# Make sure our override of caller() does not mess up @DB::args and thus Carp
# The test is rather strange, but there is no clearer way to trigger this
# error. For details see:
# http://rt.perl.org/rt3/Public/Bug/Display.html?id=52610#txn-713770

require Carp;
my $croaker = sub { Carp::croak ('No bizarre errors') };

for my $x (1..1) {
  eval { $croaker->($x) };
}

throws_ok (
  sub { $croaker->() },
  qr/No bizarre errors/,
  "Croak works properly (final)",
);
