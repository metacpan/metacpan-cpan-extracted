#
#===============================================================================
#         FILE:  random.t
#      CREATED:  07/05/2009 10:27:19 PM
#===============================================================================

use strict;
use warnings;

use Test::More;
use lib qw( ./lib ../lib  );
use Tie::Array::Random;
use Scalar::Util qw(looks_like_number);

my @array;
tie @array, 'Tie::Array::Random';

my $a_random_number           = $array[1];

ok (looks_like_number($a_random_number), "$a_random_number is a number");

my $an_other_random_number    = $array[2];
ok (looks_like_number($an_other_random_number), "$an_other_random_number is a number");

ok ( $a_random_number == $array[1], "random numbers seems to be stored");

$array[3] = 1234;
ok ( $array[3] == 1234, "given numbers seems to be stored");


my @array2;
tie @array2, 'Tie::Array::Random', {set => 'alpha'};

my $a_random_alpha = $array2[1];

ok(!looks_like_number($a_random_alpha), "$a_random_alpha is not a number");

my @array3;
tie @array3, 'Tie::Array::Random', {set => 'alpha', min=>10, max=>20};

my $a_random_alpha2 = $array3[2];

ok(!looks_like_number($a_random_alpha2) && length($a_random_alpha2) >= 10,
                "$a_random_alpha2 is a big alpha");


ok( $#array3 > 0, "fetch size : $#array3");


done_testing;


