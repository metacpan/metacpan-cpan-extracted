#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Tlaloc 'all';

# These tests verify that PASSIVE reads (Perl-level operations that read
# a scalar's value) trigger evaporation via the mg_get vtable callback.
# Each test uses custom evap_rate to make the math clearer.

# ------------------------------------------------------------------
# 1. String interpolation with custom evap_rate
# ------------------------------------------------------------------
subtest 'string interpolation respects evap_rate' => sub {
    my $x = "hello";
    drench($x, 1);                      # 100, evap=1
    my $s = "$x";                       # mg_get: 100-1=99
    is(evap_rate($x), 1, 'evap_rate is 1');
    is(wetness($x), 98, 'one interpolation + wetness() = -2');
};

# ------------------------------------------------------------------
# 2. Numeric context
# ------------------------------------------------------------------
subtest 'numeric context fires mg_get' => sub {
    my $x = 100;
    drench($x, 5);                      # 100, evap=5
    my $n = $x + 0;                     # mg_get: 100-5=95
    is(wetness($x), 90, 'numeric add + wetness() = -10');
};

# ------------------------------------------------------------------
# 3. Comparison operators
# ------------------------------------------------------------------
subtest 'comparison operators fire mg_get' => sub {
    my $x = 50;
    drench($x, 10);                     # 100

    my $r1 = ($x == 50);                # mg_get: 100-10=90
    is(wetness($x), 80, 'numeric eq + wetness() = -20');

    drench($x, 10);                     # 100
    my $r2 = ($x eq "50");              # mg_get: 100-10=90
    is(wetness($x), 80, 'string eq + wetness() = -20');
};

# ------------------------------------------------------------------
# 4. Regex matching
# ------------------------------------------------------------------
subtest 'regex match fires mg_get' => sub {
    my $x = "rainstorm";
    drench($x, 2);                      # 100, evap=2
    my $matched = ($x =~ /rain/);       # mg_get: 100-2=98
    is(wetness($x), 96, 'regex match + wetness() = -4');
    ok($matched, 'match succeeded');
};

# ------------------------------------------------------------------
# 5. substr() fires mg_get
# ------------------------------------------------------------------
subtest 'substr fires mg_get' => sub {
    my $x = "flooding"; # joke for the naive - not the entire planet!!!
    drench($x, 3);                      # 100, evap=3
    my $sub = substr($x, 0, 5);         # mg_get: 100-3=97
    is(wetness($x), 94, 'substr + wetness() = -6');
    is($sub, "flood", 'substr result correct');
};

# ------------------------------------------------------------------
# 6. split() fires mg_get
# ------------------------------------------------------------------
subtest 'split fires mg_get' => sub {
    my $x = "a,b,c";
    drench($x, 4);                      # 100, evap=4
    my @parts = split(/,/, $x);         # mg_get: 100-4=96
    is(wetness($x), 92, 'split + wetness() = -8');
    is_deeply(\@parts, ['a', 'b', 'c'], 'split result correct');
};

# ------------------------------------------------------------------  
# 7. join() with wet scalar fires mg_get
# ------------------------------------------------------------------
subtest 'join fires mg_get on joined scalar' => sub {
    my $x = "wet";
    drench($x, 5);                      # 100, evap=5
    my $joined = join(",", $x, "dry");  # mg_get: 100-5=95
    is(wetness($x), 90, 'join + wetness() = -10');
    is($joined, "wet,dry", 'join result correct');
};

# ------------------------------------------------------------------
# 8. Chained dereference doesn't add extra reads
# ------------------------------------------------------------------
subtest 'reference access pattern' => sub {
    my $x = "target";
    my $ref = \$x;
    drench($x, 10);                     # 100

    # $$ref reads the referent once
    my $val = $$ref;                    # mg_get on $x: 100-10=90
    is(wetness($x), 80, 'deref + wetness() = -20');
    is($val, "target", 'dereferenced value correct');
};

# ------------------------------------------------------------------
# 9. sprintf fires mg_get
# ------------------------------------------------------------------
subtest 'sprintf fires mg_get' => sub {
    my $x = "drizzle";
    drench($x, 7);                      # 100, evap=7
    my $s = sprintf("It's %s outside", $x);  # mg_get: 100-7=93
    is(wetness($x), 86, 'sprintf + wetness() = -14');
    is($s, "It's drizzle outside", 'sprintf result correct');
};

# ------------------------------------------------------------------
# 10. Assignment to another variable fires mg_get
# ------------------------------------------------------------------
subtest 'assignment fires mg_get' => sub {
    my $x = "source";
    drench($x, 8);                      # 100, evap=8
    my $y = $x;                         # mg_get on $x: 100-8=92
    is(wetness($x), 84, 'assignment + wetness() = -16');
    is($y, "source", 'copied value correct');
    ok(is_dry($y), 'magic NOT copied - $y is dry');
};

# ------------------------------------------------------------------
# 11. Gradual evaporation to complete dryness
# ------------------------------------------------------------------
subtest 'gradual evaporation to dryness' => sub {
    my $x = "ephemeral";
    wet($x, 10);                        # 50, evap=10

    # 5 passive reads should drain it
    my @reads;
    push @reads, "$x" for 1..5;         # 50-10-10-10-10-10 = 0

    ok(is_dry($x), 'scalar is dry after 5 passive reads');
    is(wetness($x), 0, 'wetness is 0');
};

# ------------------------------------------------------------------
# 12. Zero evap_rate prevents passive decay
# ------------------------------------------------------------------
subtest 'zero evap_rate prevents passive decay' => sub {
    my $x = "permanent";
    drench($x, 0);                      # 100, evap=0

    # Multiple passive reads should not decrease wetness
    my $a = "$x";
    my $b = "$x";
    my $c = length($x);
    my $d = uc($x);

    # wetness() also uses evap=0, so no decrement
    is(wetness($x), 100, 'wetness unchanged with evap_rate 0');
    ok(is_wet($x), 'still wet');
};

# ------------------------------------------------------------------
# 13. Changing evap_rate mid-stream
# ------------------------------------------------------------------
subtest 'changing evap_rate mid-stream' => sub {
    my $x = "changeable";
    drench($x, 20);                     # 100, evap=20

    my $a = "$x";                       # 100-20=80
    is(wetness($x), 60, 'after 2 reads at evap=20: 60');

    evap_rate($x, 5);                   # change to 5
    my $b = "$x";                       # 60-5=55
    is(wetness($x), 50, 'after 2 more reads at evap=5: 50');
};

done_testing;
