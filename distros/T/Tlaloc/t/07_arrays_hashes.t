#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Tlaloc 'all';

# Tlaloc can attach wetness magic to arrays and hashes (not just scalars).
# Use wet(\@array) or wet(\%hash) to attach magic to the container.
#
# IMPORTANT: With PERL_MAGIC_ext, the mg_get callback does NOT automatically
# fire on normal array/hash operations (element access, keys, values, etc.).
# The wetness decrements only when wetness(), is_wet(), or is_dry() are called.
# These functions internally use tlaloc_read_wetness() which decrements wetness.

# ==================================================================
# ARRAY TESTS
# ==================================================================

subtest 'wet array basics' => sub {
    my @arr = (1, 2, 3);
    ok(is_dry(\@arr), 'array starts dry');
    
    wet(\@arr);
    ok(is_wet(\@arr), 'array is wet after wet()');
    is(evap_rate(\@arr), 10, 'default evap_rate is 10');
};

subtest 'drench array sets wetness to 100' => sub {
    my @arr = (1, 2);
    drench(\@arr, 5);  # evap=5
    
    # First wetness() call decrements: 100-5=95
    is(wetness(\@arr), 95, 'after drench, wetness = 100, first read = 95');
    # Second call: 95-5=90
    is(wetness(\@arr), 90, 'second wetness() call decrements again');
};

subtest 'array evap_rate can be configured' => sub {
    my @arr = (1);
    drench(\@arr, 20);  # evap=20
    is(evap_rate(\@arr), 20, 'evap_rate is 20');
    
    is(wetness(\@arr), 80, 'first read: 100-20=80');
    is(wetness(\@arr), 60, 'second read: 80-20=60');
};

subtest 'array evap_rate 0 means no evaporation' => sub {
    my @arr = (1);
    drench(\@arr, 0);  # evap=0, no evaporation
    
    is(wetness(\@arr), 100, 'no evaporation');
    is(wetness(\@arr), 100, 'still 100');
    is(wetness(\@arr), 100, 'still 100 after many reads');
};

subtest 'array operations do not fire mg_get' => sub {
    my @arr = (10, 20, 30);
    drench(\@arr, 10);

    # None of these fire mg_get on the container:
    my $first = $arr[0];           # element access
    my $count = @arr;              # scalar context
    for (@arr) { }                  # iteration
    push @arr, 40;                  # push
    my $p = pop @arr;               # pop
    my @slice = @arr[0,1];          # slice
    
    # Only the wetness() call below will decrement
    is(wetness(\@arr), 90, 'operations did not fire mg_get, only wetness() did');
    is($first, 10, 'element value correct');
    is($count, 3, 'scalar context correct');
    is($p, 40, 'popped value correct');
};

subtest 'array dries out after many wetness reads' => sub {
    my @arr = (1);
    wet(\@arr);  # default 50 wetness, evap=10
    
    # 50 -> 40 -> 30 -> 20 -> 10 -> 0
    is(wetness(\@arr), 40, 'first read: 50-10=40');
    is(wetness(\@arr), 30, 'second read: 40-10=30');
    is(wetness(\@arr), 20, 'third read');
    is(wetness(\@arr), 10, 'fourth read');
    is(wetness(\@arr), 0, 'fifth read - dry');
    ok(is_dry(\@arr), 'array is now dry');
};

subtest 'dry() removes array magic' => sub {
    my @arr = (1);
    wet(\@arr);
    ok(is_wet(\@arr), 'array is wet');
    
    dry(\@arr);
    ok(is_dry(\@arr), 'array is dry after dry()');
    is(wetness(\@arr), 0, 'wetness is 0');
};

# ==================================================================
# HASH TESTS
# ==================================================================

subtest 'wet hash basics' => sub {
    my %hash = (a => 1, b => 2);
    ok(is_dry(\%hash), 'hash starts dry');
    
    wet(\%hash);
    ok(is_wet(\%hash), 'hash is wet after wet()');
    is(evap_rate(\%hash), 10, 'default evap_rate is 10');
};

subtest 'drench hash sets wetness to 100' => sub {
    my %hash = (x => 1);
    drench(\%hash, 5);  # evap=5
    
    is(wetness(\%hash), 95, 'after drench, first read = 95');
    is(wetness(\%hash), 90, 'second read = 90');
};

subtest 'hash evap_rate can be configured' => sub {
    my %hash = (a => 1);
    drench(\%hash, 25);
    is(evap_rate(\%hash), 25, 'evap_rate is 25');
    
    is(wetness(\%hash), 75, 'first read: 100-25=75');
};

subtest 'hash operations do not fire mg_get' => sub {
    my %hash = (a => 1, b => 2, c => 3);
    drench(\%hash, 10);

    # None of these fire mg_get:
    my $val = $hash{a};            # key access
    my @k = keys %hash;            # keys()
    my @v = values %hash;          # values()
    my $e = exists $hash{a};       # exists()
    delete $hash{c};               # delete()
    while (my ($k,$v) = each %hash) { }  # each()
    
    # Only wetness() call decrements
    is(wetness(\%hash), 90, 'operations did not fire mg_get');
    is($val, 1, 'value correct');
};

subtest 'hash dries out after many wetness reads' => sub {
    my %hash = (a => 1);
    wet(\%hash);  # default 50 wetness, evap=10
    
    # 50 -> 40 -> 30 -> 20 -> 10 -> 0
    is(wetness(\%hash), 40, 'first read: 50-10=40');
    is(wetness(\%hash), 30, 'second read');
    is(wetness(\%hash), 20, 'third read');
    is(wetness(\%hash), 10, 'fourth read');
    is(wetness(\%hash), 0, 'fifth read - dry');
    ok(is_dry(\%hash), 'hash is now dry');
};

subtest 'dry() removes hash magic' => sub {
    my %hash = (k => 'v');
    wet(\%hash);
    ok(is_wet(\%hash), 'hash is wet');
    
    dry(\%hash);
    ok(is_dry(\%hash), 'hash is dry after dry()');
};

# ==================================================================
# NESTED STRUCTURES
# ==================================================================

subtest 'wet outer array, inner unaffected' => sub {
    my @outer = ([1,2], [3,4]);
    drench(\@outer, 10);
    
    # Check inner array is NOT wet
    ok(is_dry($outer[0]), 'inner arrayref is dry');
    
    # Outer is wet
    is(wetness(\@outer), 90, 'outer array is wet');
};

subtest 'wet inner hash, outer unaffected' => sub {
    my %outer = (inner => { a => 1 });
    my $inner = $outer{inner};
    
    drench($inner, 5);
    
    ok(is_dry(\%outer), 'outer hash is dry');
    is(wetness($inner), 95, 'inner hash is wet');
};

subtest 'wet both levels independently' => sub {
    my @outer = ({ a => 1 }, { b => 2 });
    drench(\@outer, 10);
    drench($outer[0], 5);
    
    is(wetness(\@outer), 90, 'outer wetness');
    is(wetness($outer[0]), 95, 'inner wetness');
};

# ==================================================================
# EVAP_RATE CHANGES
# ==================================================================

subtest 'change evap_rate mid-stream' => sub {
    my @arr = (1);
    drench(\@arr, 10);  # start at evap=10
    
    is(wetness(\@arr), 90, 'first read at evap=10');
    
    evap_rate(\@arr, 5);  # change to evap=5
    is(evap_rate(\@arr), 5, 'evap_rate changed to 5');
    
    is(wetness(\@arr), 85, 'next read at evap=5: 90-5=85');
};

done_testing;
