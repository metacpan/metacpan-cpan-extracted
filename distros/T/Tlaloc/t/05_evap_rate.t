#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Tlaloc 'all';

# Test default evap_rate
subtest 'default evap_rate' => sub {
    my $x = "test";
    drench($x);
    is(evap_rate($x), 10, 'default evap_rate is 10');
    is(wetness($x), 90, 'wetness decrements by 10');
    is(wetness($x), 80, 'wetness decrements by 10 again');
};

# Test custom evap_rate via wet()
subtest 'wet() with custom evap_rate' => sub {
    my $x = "test";
    wet($x, 5);
    is(evap_rate($x), 5, 'evap_rate set to 5 via wet()');
    is(wetness($x), 45, 'wetness decrements by 5');
    is(wetness($x), 40, 'wetness decrements by 5 again');
};

# Test custom evap_rate via drench()
subtest 'drench() with custom evap_rate' => sub {
    my $x = "test";
    drench($x, 20);
    is(evap_rate($x), 20, 'evap_rate set to 20 via drench()');
    is(wetness($x), 80, 'wetness decrements by 20');
    is(wetness($x), 60, 'wetness decrements by 20 again');
};

# Test evap_rate() setter
subtest 'evap_rate() setter' => sub {
    my $x = "test";
    drench($x);
    is(evap_rate($x), 10, 'default evap_rate');
    evap_rate($x, 1);
    is(evap_rate($x), 1, 'evap_rate changed to 1');
    is(wetness($x), 99, 'wetness decrements by 1');
    is(wetness($x), 98, 'wetness decrements by 1 again');
};

# Test evap_rate on non-wet scalar
subtest 'evap_rate on dry scalar' => sub {
    my $x = "test";
    is(evap_rate($x), 0, 'evap_rate returns 0 for dry scalar');
};

# Test large evap_rate (drains quickly)
subtest 'large evap_rate' => sub {
    my $x = "test";
    drench($x, 50);
    is(wetness($x), 50, 'first access -50');
    is(wetness($x), 0, 'second access drains to 0');
    ok(is_dry($x), 'scalar is now dry');
};

# Test evap_rate of 0 (never evaporates via explicit calls)
subtest 'evap_rate of 0' => sub {
    my $x = "test";
    drench($x, 0);
    # Note: evap_rate of 0 means no evaporation
    is(wetness($x), 100, 'wetness unchanged with evap_rate 0');
    is(wetness($x), 100, 'still 100');
    evap_rate($x, 10);  # restore normal
    is(wetness($x), 90, 'now evaporates');
};

done_testing;
