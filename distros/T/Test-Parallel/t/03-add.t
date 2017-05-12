use strict;
use warnings;

use Test::Parallel;
use Test::More tests => 12;

test_with(1);
test_with(5);

exit;

sub test_with {

    my $n = shift || 1;

    my $p = Test::Parallel->new();
    for ( 1 .. $n ) {
        $p->add(
            sub {
                my $time = int( rand(2) );
                sleep($time);
                return { number => $n, time => $time };
            },
            sub {
                my $result = shift;
                is $result->{number} => $n;
                cmp_ok $result->{time}, '<=', 2;
            }
        );
    }
    note "running $n job(s) in parallel";
    $p->done();
}

