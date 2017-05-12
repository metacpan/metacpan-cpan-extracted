# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

use Test::More qw(no_plan);
use strict;
use utf8;

use Text::TransMetaphone ( 'trans_metaphone', 'reverse_key' );

is ( 1, 1, "loaded." );

my @keys = trans_metaphone ( "ዩኒኮድ" );
is ( $keys[0], "jnkd", "Key Create Test" );

is ( reverse_key ( $keys[0], "am" ), "[#የ#][#ነ#][#ከ#][#ደ#]", "Key Reverse Test" );

