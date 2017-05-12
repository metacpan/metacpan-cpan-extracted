# A little program we can use to make sure we can control randomness.

package Flowers;

use Test::Random;

print int rand(100_000);
