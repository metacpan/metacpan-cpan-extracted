#
#===============================================================================
#         FILE:  random.t
#      CREATED:  07/05/2009 10:27:19 PM
#===============================================================================

use strict;
use warnings;

use Test::More;
use lib qw( ./lib ../lib  );
use Scalar::Util qw(looks_like_number);
require_ok('Tie::Hash::Random');

my %hash;
tie %hash, 'Tie::Hash::Random';

my $a_random_number           = $hash{foo};

ok (looks_like_number($a_random_number), "$a_random_number is a number");

my $an_other_random_number    = $hash{bar};
ok (looks_like_number($an_other_random_number), "$an_other_random_number is a number");

ok ( $a_random_number == $hash{foo}, "random numbers seems to be stored");

$hash{pepe} = 1234;
ok ( $hash{pepe} == 1234, "given numbers seems to be stored");


my %hash2;
tie %hash2, 'Tie::Hash::Random', {set => 'alpha'};

my $a_random_alpha = $hash2{foo};

ok(!looks_like_number($a_random_alpha), "$a_random_alpha is not a number");

my %hash3;
tie %hash3, 'Tie::Hash::Random', {set => 'alpha', min=>10, max=>20};

my $a_random_alpha2 = $hash3{foo};

ok(!looks_like_number($a_random_alpha2) && length($a_random_alpha2) >= 10,
                "$a_random_alpha2 is a big alpha");



done_testing;


