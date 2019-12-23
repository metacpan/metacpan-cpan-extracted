#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Throttle::Adaptive;

{
    my $throttle = Throttle::Adaptive->new(ratio => 2, time => 120);
    $throttle->count(0) for 1..200;
    ok !$throttle->should_fail for 1..200;
    $throttle->count(1) for 1..400;
    # We now have 400 failed requests and 200 successful requests. With a ratio of 2, this
    # should give us a nearly 50% failure rate. To accommodate for statistical probability,
    # check that the actual failed rate is between 10% and 90%. :-)
    my $sum; $sum += $throttle->should_fail for 1..200;
    ok($sum >= 20 && $sum <= 180) or diag $sum;
}

done_testing;
