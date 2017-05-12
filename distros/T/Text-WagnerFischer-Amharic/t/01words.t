# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

binmode(STDOUT, ":utf8");  # but we still get wide char errors
binmode(STDERR, ":utf8");  # but we still get wide char errors
use Test::More qw(no_plan);
use utf8;
use strict;

use Text::WagnerFischer::Amharic qw( distance );

is ( 1, 1, "loaded." );

#
# these tests are a bit week..
#

my $d = distance ( "ሠላም", "ሰላም" );
is ( $d, 1, "ሠላም vs ሰላም" );


$d = distance ( "ሀለሐ", "ሰረሠ" );
is ( $d, 6, "ሀለሐ vs ሰረሠ" );


$d = distance ( "ሀለሐ", "ሳራሳ" );
is ( $d, 9, "ሀለሐ vs ሳራሳ" );


$d = distance ( "ሀለሐ", "ሀለሐ" );
is ( $d, 0, "ሀለሐ vs ሀለሐ" );


$d = distance ( "ሀለሐ", "ሐለሀ" );
is ( $d, 2, "ሀለሐ vs ሐለሀ" );
