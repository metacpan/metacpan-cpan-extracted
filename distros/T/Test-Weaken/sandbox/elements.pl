#!perl

# This is a sandbox for experiments with referencing and dereferencing.
# It is not part of a test suite, not even an "author" test suite.

use strict;
use warnings;

use Scalar::Util qw(reftype weaken);
use Devel::Peek qw();
use Carp;
use English qw( -no_match_vars );
use Fatal qw(open);

my $scalar = 42;
my @data;
weaken( $data[0] = \$scalar );

print {*STDERR} "Dumping data array\n"
    or Carp::croak('Cannot print to STDERR');
Devel::Peek::Dump \@data;
print {*STDERR} "\n"
    or Carp::croak('Cannot print to STDERR');

my ($probe_ref) = map { \$_ } @data;
Devel::Peek::Dump $probe_ref;
