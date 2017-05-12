#!perl

use strict;
use warnings;

use Test::More tests => 6;
use Scalar::Util qw(weaken isweak);

use lib 't/lib';
use Test::Weaken::Test;

BEGIN {
    Test::More::use_ok('Test::Weaken');
}

sub brief_result {
    my $test              = shift;
    my $unfreed_count     = $test->test();
    my $unfreed_proberefs = $test->unfreed_proberefs();

    my @unfreed_strong = ();
    my @unfreed_weak   = ();
    for my $proberef ( @{$unfreed_proberefs} ) {
        if ( ref $proberef eq 'REF' and isweak ${$proberef} ) {
            push @unfreed_weak, $proberef;
        }
        else {
            push @unfreed_strong, $proberef;
        }
    }

    return
          'total: weak='
        . $test->weak_probe_count() . q{; }
        . 'strong='
        . $test->strong_probe_count() . q{; }
        . 'unfreed: weak='
        . ( scalar @unfreed_weak ) . q{; }
        . 'strong='
        . ( scalar @unfreed_strong );
}

my $test = Test::Weaken::leaks(
    sub {
        my $x = [];
        my $y = \$x;
        weaken( my $z = \$x );
        $z;
    }
);
Test::More::ok( ( !$test ), 'Simple weak ref' );

Test::Weaken::Test::is(
    brief_result(
        Test::Weaken->new( sub { my $x = 42; my $y = \$x; $x = \$y; } )
    ),
    'total: weak=0; strong=3; unfreed: weak=0; strong=2',
    'Bad Less Simple Cycle'
);

Test::Weaken::Test::is(
    brief_result(
        Test::Weaken->new(
            sub { my $x; weaken( my $y = \$x ); $x = \$y; $y; }
        )
    ),
    'total: weak=1; strong=2; unfreed: weak=0; strong=0',
    'Fixed simple cycle'
);

Test::Weaken::Test::is(
    brief_result(
        Test::Weaken->new(
            sub {
                my $x;
                my $y = [ \$x ];
                my $z = { k1 => \$y };
                $x = \$z;
                my $result = [ $x, $y, $z ];
                $result;
            }
        )
    ),
    'total: weak=0; strong=12; unfreed: weak=0; strong=7',
    'Bad Complicated Cycle'
);

Test::Weaken::Test::is(
    brief_result(
        Test::Weaken->new(
            sub {
                my $x = 42;
                my $y = [ \$x ];
                my $z = { k1 => \$y };
                weaken( $x = \$z );
                my $result = [ $x, $y, $z ];
                $result;
            }
        )
    ),
    'total: weak=1; strong=11; unfreed: weak=0; strong=0',
    'Fixed Complicated Cycle'
);

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
