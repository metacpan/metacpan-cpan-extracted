# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

use Test::More qw(no_plan);
use strict;
use utf8;

require Text::Metaphone::Amharic;

is ( 1, 1, "loaded." );

my $mphone = new Text::Metaphone::Amharic;

is ( 1, 1, "new." );

my @keys = $mphone->metaphone ( "ወምበር" );
is ( $keys[1], "ውንብር", "ውምብር/ውንብር match." );


my $key1  = $mphone->metaphone ( "ፀሐይ" );
my $key2  = $mphone->metaphone ( "ጸሃይ" );
is ( $key1, $key2, "ፀሐይ/ጸሃይ match." );


$key1  = $mphone->metaphone ( "ዓለም" );
$key2  = $mphone->metaphone ( "አለም" );
is ( $key1, $key2, "ዓለም/አለም match." );

$key2  = $mphone->metaphone ( "ዐለም" );
is ( $key1, $key2, "ዓለም/ዐለም match." );

$key2  = $mphone->metaphone ( "ኣለም" );
is ( $key1, $key2, "ዓለም/ኣለም match." );


@keys  = $mphone->metaphone ( "ጤና" );
$key2  = $mphone->metaphone ( "ቴና" );
is ( $keys[1], $key2, "ጤና/ቴና match." );
