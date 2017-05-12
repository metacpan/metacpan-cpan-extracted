# A little program we can use to make sure we can control randomness.

package Flowers;

use Test::Sims;

make_rand "flower" => [qw(Rose Daisy Ed Bob)];

print rand_flower();
