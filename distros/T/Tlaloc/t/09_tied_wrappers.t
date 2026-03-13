#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Tlaloc 'all';

# Tied wrappers provide passive evaporation for arrays and hashes.
# Unlike magic-based wetness (where only explicit wetness()/is_wet()/is_dry()
# calls cause evaporation), tied wrappers evaporate on element access.

# ==================================================================
# TIED ARRAY TESTS
# ==================================================================

subtest 'wet_tie array basics' => sub {
    my @arr = (1, 2, 3);
    my $tied = wet_tie(\@arr, 10);
    
    ok(defined $tied, 'wet_tie returns tied object');
    isa_ok($tied, 'Tlaloc::Tied::Array');
    is($tied->evap_rate, 10, 'evap_rate is 10');
};

subtest 'array element access evaporates' => sub {
    my @arr = (10, 20, 30);
    my $tied = wet_tie(\@arr, 5);  # 100, evap=5
    
    # wetness() call evaporates: 100-5=95
    is($tied->wetness, 95, 'initial wetness check');
    
    my $x = $arr[0];  # FETCH evaporates: 95-5=90
    is($x, 10, 'element value correct');
    
    # wetness() evaporates again: 90-5=85
    is($tied->wetness, 85, 'element access evaporated');
};

subtest 'array scalar context evaporates' => sub {
    my @arr = (1, 2, 3, 4);
    my $tied = wet_tie(\@arr, 10);
    
    my $count = scalar @arr;  # FETCHSIZE evaporates
    is($count, 4, 'scalar context gives count');
    ok($tied->wetness < 90, 'scalar context evaporated');
};

subtest 'array iteration evaporates' => sub {
    my @arr = (1, 2, 3);
    my $tied = wet_tie(\@arr, 10);  # 100, evap=10
    
    # wetness() evaporates: 100-10=90
    is($tied->wetness, 90, 'initial check');
    
    # for loop: FETCHSIZE + 3 FETCH calls = 4 evaporations (90-40=50)
    for my $x (@arr) { }
    
    # wetness() evaporates: 50-10=40
    is($tied->wetness, 40, 'iteration evaporated (fetchsize + 3 elements)');
};

subtest 'array push/pop evaporation' => sub {
    my @arr = (1, 2);
    my $tied = wet_tie(\@arr, 10);
    
    push @arr, 3;  # PUSH does not evaporate
    is(scalar(@arr), 3, 'push worked');
    
    my $p = pop @arr;  # POP evaporates
    is($p, 3, 'popped value correct');
    
    my $s = shift @arr;  # SHIFT evaporates
    is($s, 1, 'shifted value correct');
    
    ok($tied->wetness < 80, 'pop/shift evaporated');
};

subtest 'array slice evaporates' => sub {
    my @arr = (1, 2, 3, 4, 5);
    my $tied = wet_tie(\@arr, 5);
    
    my @slice = @arr[1, 3];  # 2 FETCH calls
    is_deeply(\@slice, [2, 4], 'slice values correct');
    ok($tied->wetness < 95, 'slice evaporated');
};

subtest 'array exists evaporates' => sub {
    my @arr = (1, 2, 3);
    my $tied = wet_tie(\@arr, 10);
    
    my $e = exists $arr[1];  # EXISTS evaporates
    ok($e, 'element exists');
    ok($tied->wetness < 90, 'exists evaporated');
};

subtest 'array store does not evaporate' => sub {
    my @arr = (1, 2, 3);
    my $tied = wet_tie(\@arr, 10);
    
    is($tied->wetness, 90, 'initial check');  # evaporates 100->90
    
    $arr[0] = 99;  # STORE - no evaporation (still 90)
    is($arr[0], 99, 'store worked');  # FETCH evaporates 90->80
    
    # wetness check evaporates 80->70
    is($tied->wetness, 70, 'store did not evaporate, only fetch and wetness()');
};

subtest 'array drench and wet methods' => sub {
    my @arr = (1, 2);
    my $tied = wet_tie(\@arr, 10);
    
    # Use up wetness
    for (1..5) { my $x = $arr[0]; }  # 5 FETCHes
    ok($tied->wetness < 50, 'wetness decreased');
    
    $tied->drench;
    is($tied->wetness, 90, 'drench restored to 100 (minus wetness() call)');
    
    $tied->drench(5);
    is($tied->evap_rate, 5, 'drench set evap_rate');
};

subtest 'array dries out' => sub {
    my @arr = (1);
    my $tied = wet_tie(\@arr, 20);
    
    # Consume wetness
    for (1..10) {
        last if $tied->is_dry;
        my $x = $arr[0];
    }
    
    ok($tied->is_dry, 'array dried out');
    is($tied->wetness, 0, 'wetness is 0');
};

subtest 'untie_wet array' => sub {
    my @arr = (1, 2, 3);
    my $tied = wet_tie(\@arr, 10);
    
    $arr[1] = 99;  # modify via tied interface
    
    untie_wet(\@arr);
    
    ok(!tied(@arr), 'array is untied');
    is_deeply(\@arr, [1, 99, 3], 'data preserved after untie');
};

# ==================================================================
# TIED HASH TESTS
# ==================================================================

subtest 'wet_tie hash basics' => sub {
    my %hash = (a => 1, b => 2);
    my $tied = wet_tie(\%hash, 10);
    
    ok(defined $tied, 'wet_tie returns tied object');
    isa_ok($tied, 'Tlaloc::Tied::Hash');
    is($tied->evap_rate, 10, 'evap_rate is 10');
};

subtest 'hash key access evaporates' => sub {
    my %hash = (x => 10, y => 20);
    my $tied = wet_tie(\%hash, 5);  # 100, evap=5
    
    is($tied->wetness, 95, 'initial wetness');
    
    my $v = $hash{x};  # FETCH evaporates
    is($v, 10, 'value correct');
    
    is($tied->wetness, 85, 'key access evaporated');
};

subtest 'hash keys/values evaporates' => sub {
    my %hash = (a => 1, b => 2, c => 3);
    my $tied = wet_tie(\%hash, 10);
    
    my @k = keys %hash;  # FIRSTKEY evaporates
    is(scalar @k, 3, 'got 3 keys');
    ok($tied->wetness < 90, 'keys() evaporated');
};

subtest 'hash exists evaporates' => sub {
    my %hash = (key => 'value');
    my $tied = wet_tie(\%hash, 10);
    
    my $e = exists $hash{key};  # EXISTS evaporates
    ok($e, 'key exists');
    ok($tied->wetness < 90, 'exists evaporated');
};

subtest 'hash store does not evaporate' => sub {
    my %hash = (a => 1);
    my $tied = wet_tie(\%hash, 10);
    
    is($tied->wetness, 90, 'initial check');
    
    $hash{b} = 2;  # STORE - no evaporation
    is($hash{b}, 2, 'store worked');  # FETCH evaporates
    
    ok($tied->wetness < 80, 'only fetch evaporated');
};

subtest 'hash iteration evaporates' => sub {
    my %hash = (a => 1, b => 2);
    my $tied = wet_tie(\%hash, 10);
    
    while (my ($k, $v) = each %hash) { }  # iteration evaporates
    
    ok($tied->wetness < 80, 'iteration evaporated');
};

subtest 'hash drench and wet methods' => sub {
    my %hash = (a => 1);
    my $tied = wet_tie(\%hash, 10);
    
    # Use up wetness
    for (1..5) { my $x = $hash{a}; }
    
    $tied->drench(5);
    is($tied->wetness, 95, 'drench restored (100-5 from wetness())');
    is($tied->evap_rate, 5, 'evap_rate changed');
    
    $tied->wet;  # already at 95, +50 capped at 100
    is($tied->wetness, 95, 'wet() capped at 100 (minus wetness())');
};

subtest 'hash dries out' => sub {
    my %hash = (k => 'v');
    my $tied = wet_tie(\%hash, 25);
    
    for (1..10) {
        last if $tied->is_dry;
        my $x = $hash{k};
    }
    
    ok($tied->is_dry, 'hash dried out');
};

subtest 'untie_wet hash' => sub {
    my %hash = (a => 1, b => 2);
    my $tied = wet_tie(\%hash, 10);
    
    $hash{c} = 3;  # modify via tied interface
    
    untie_wet(\%hash);
    
    ok(!tied(%hash), 'hash is untied');
    is_deeply(\%hash, {a => 1, b => 2, c => 3}, 'data preserved');
};

# ==================================================================
# EDGE CASES
# ==================================================================

subtest 'evap_rate 0 prevents evaporation' => sub {
    my @arr = (1, 2, 3);
    my $tied = wet_tie(\@arr, 0);
    
    for (1..10) { my $x = $arr[0]; }
    
    is($tied->wetness, 100, 'no evaporation with evap_rate 0');
};

subtest 'change evap_rate mid-stream' => sub {
    my @arr = (1);
    my $tied = wet_tie(\@arr, 20);
    
    my $x = $arr[0];  # evaporates 20
    is($tied->wetness, 60, 'after fetch at evap=20');  # 100-20-20=60
    
    $tied->evap_rate(5);
    my $y = $arr[0];  # evaporates 5
    is($tied->wetness, 50, 'after fetch at evap=5');  # 60-5-5=50
};

subtest 'wet_tie on invalid ref croaks' => sub {
    my $scalar = "hello";
    eval { wet_tie(\$scalar) };
    like($@, qr/requires an array or hash reference/, 'croaks on scalar ref');
    
    my $code = sub { };
    eval { wet_tie($code) };
    like($@, qr/requires an array or hash reference/, 'croaks on code ref');
};

subtest 'default evap_rate' => sub {
    my @arr = (1);
    my $tied = wet_tie(\@arr);  # no evap_rate specified
    
    is($tied->evap_rate, 10, 'default evap_rate is 10');
};

done_testing;
