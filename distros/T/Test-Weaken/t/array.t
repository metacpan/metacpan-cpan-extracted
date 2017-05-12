#!perl

use strict;
use warnings;

use Test::More tests => 2;
use Scalar::Util qw(weaken);
use Data::Dumper;

use lib 't/lib';
use Test::Weaken::Test;

BEGIN {
    Test::More::use_ok('Test::Weaken');
}

my $test = Test::Weaken->new(
    sub {
        my $x;
        my $y = [ \$x, 42 ];
        $x = [ \$y, 711 ];
        weaken( my $w1 = \$x );
        weaken( my $w2 = \$y );
        $x->[2] = \$w1;
        $y->[2] = \$w2;
        $x;
    }
);

my $unfreed_count     = $test->test();
my $probe_count       = $test->probe_count();
my $unfreed_proberefs = $test->unfreed_proberefs();

my $text = "Checking $probe_count objects\n"
    . "$unfreed_count objects were not freed:\n";

# names for the references, so checking the dump does not depend
# on the specific hex value of locations

for my $ix ( 0 .. $#{$unfreed_proberefs} ) {
    $text .= Data::Dumper->Dump( [ $unfreed_proberefs->[$ix] ],
        ["unfreed_$ix"] );
}

Test::Weaken::Test::is( $text, <<'EOS', 'Dump of unfreed arrays' );
Checking 13 objects
12 objects were not freed:
$unfreed_0 = [
               \[
                   \$unfreed_0,
                   42,
                   \$unfreed_0->[0]
                 ],
               711,
               \${$unfreed_0->[0]}->[0]
             ];
$unfreed_1 = \\[
                   \[
                       ${$unfreed_1},
                       711,
                       \${${$unfreed_1}}->[0]
                     ],
                   42,
                   \${$unfreed_1}
                 ];
$unfreed_2 = \711;
$unfreed_3 = \\\[
                     \[
                         ${${$unfreed_3}},
                         42,
                         \${${${$unfreed_3}}}->[0]
                       ],
                     711,
                     ${$unfreed_3}
                   ];
$unfreed_4 = \\[
                   \[
                       ${$unfreed_4},
                       42,
                       \${${$unfreed_4}}->[0]
                     ],
                   711,
                   $unfreed_4
                 ];
$unfreed_5 = \[
                 \[
                     $unfreed_5,
                     42,
                     \${$unfreed_5}->[0]
                   ],
                 711,
                 \$unfreed_5
               ];
$unfreed_6 = \[
                 \[
                     $unfreed_6,
                     711,
                     \${$unfreed_6}->[0]
                   ],
                 42,
                 \$unfreed_6
               ];
$unfreed_7 = [
               \[
                   \$unfreed_7,
                   711,
                   \$unfreed_7->[0]
                 ],
               42,
               \${$unfreed_7->[0]}->[0]
             ];
$unfreed_8 = \\[
                   \[
                       ${$unfreed_8},
                       42,
                       \${${$unfreed_8}}->[0]
                     ],
                   711,
                   \${$unfreed_8}
                 ];
$unfreed_9 = \42;
$unfreed_10 = \\\[
                      \[
                          ${${$unfreed_10}},
                          711,
                          \${${${$unfreed_10}}}->[0]
                        ],
                      42,
                      ${$unfreed_10}
                    ];
$unfreed_11 = \\[
                    \[
                        ${$unfreed_11},
                        711,
                        \${${$unfreed_11}}->[0]
                      ],
                    42,
                    $unfreed_11
                  ];
EOS
