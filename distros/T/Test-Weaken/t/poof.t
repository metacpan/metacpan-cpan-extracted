#!perl

# Test of deprecated, legacy interface.
# I may remove this interface, but until I do, I guess I should test it.

use strict;
use warnings;

use Test::More tests => 2;
use Scalar::Util qw(isweak weaken reftype);
use Data::Dumper;

use lib 't/lib';
use Test::Weaken::Test;

BEGIN {
    Test::More::use_ok('Test::Weaken');
}

my ( $weak_count, $strong_count, $weak_unfreed_array, $strong_unfreed_array )
    = Test::Weaken::poof(
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

my $text =
      "Starting counts: w=$weak_count  s=$strong_count\n"
    . 'Unfreed counts: w='
    . scalar @{$weak_unfreed_array} . '  s='
    . scalar @{$strong_unfreed_array} . "\n";

# names for the references, so checking the dump does not depend
# on the specific hex value of locations

for my $strong_unfreed ( @{$strong_unfreed_array} ) {
    $text .= Data::Dumper->Dump( [$strong_unfreed], [qw(strong)] );
}
for my $weak_unfreed ( @{$weak_unfreed_array} ) {
    $text .= Data::Dumper->Dump( [$weak_unfreed], [qw(weak)] );
}

Test::Weaken::Test::is( $text, <<'EOS', 'Dump of unfreed arrays' );
Starting counts: w=2  s=11
Unfreed counts: w=2  s=10
$strong = [
            \[
                \$strong,
                42,
                \$strong->[0]
              ],
            711,
            \${$strong->[0]}->[0]
          ];
$strong = \\[
                \[
                    ${$strong},
                    711,
                    \${${$strong}}->[0]
                  ],
                42,
                \${$strong}
              ];
$strong = \711;
$strong = \\\[
                  \[
                      ${${$strong}},
                      42,
                      \${${${$strong}}}->[0]
                    ],
                  711,
                  ${$strong}
                ];
$strong = \[
              \[
                  $strong,
                  42,
                  \${$strong}->[0]
                ],
              711,
              \$strong
            ];
$strong = \[
              \[
                  $strong,
                  711,
                  \${$strong}->[0]
                ],
              42,
              \$strong
            ];
$strong = [
            \[
                \$strong,
                711,
                \$strong->[0]
              ],
            42,
            \${$strong->[0]}->[0]
          ];
$strong = \\[
                \[
                    ${$strong},
                    42,
                    \${${$strong}}->[0]
                  ],
                711,
                \${$strong}
              ];
$strong = \42;
$strong = \\\[
                  \[
                      ${${$strong}},
                      711,
                      \${${${$strong}}}->[0]
                    ],
                  42,
                  ${$strong}
                ];
$weak = \\[
              \[
                  ${$weak},
                  42,
                  \${${$weak}}->[0]
                ],
              711,
              $weak
            ];
$weak = \\[
              \[
                  ${$weak},
                  711,
                  \${${$weak}}->[0]
                ],
              42,
              $weak
            ];
EOS
