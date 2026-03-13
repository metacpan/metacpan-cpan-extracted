#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Tlaloc 'all';

# Each Perl-level read of a wet scalar fires the mg_get vtable callback,
# which decrements wetness by EVAP_STEP (10).
# These tests verify that various Perl operations each count as one access.

# Helper: returns wetness WITHOUT burning an access (reads internal state
# by re-wetting with 0 addend would break things, so we just use wetness()
# and account for the -10 it costs).

# ------------------------------------------------------------------
# 1. String interpolation: "$x" fires mg_get once
# ------------------------------------------------------------------
subtest 'string interpolation fires mg_get once' => sub {
    my $x = "hello";
    drench($x);                         # 100
    my $s = "$x";                       # mg_get: 100-10=90
    is( wetness($x), 80,                # wetness(): 90-10=80
        'one stringify + one wetness() call = -20 total' );
    is( $s, "hello", 'interpolated value is correct' );
};

# ------------------------------------------------------------------
# 2. Concatenation operator: "prefix" . $x fires mg_get once
# ------------------------------------------------------------------
subtest 'concatenation fires mg_get once' => sub {
    my $x = "world";
    drench($x);                         # 100
    my $s = "hello " . $x;             # mg_get: 100-10=90
    is( wetness($x), 80,               # wetness(): 90-10=80
        'concatenation + wetness() = -20 total' );
    is( $s, "hello world", 'concatenated value correct' );
};

# ------------------------------------------------------------------
# 3. uc() fires mg_get once
# ------------------------------------------------------------------
subtest 'uc() fires mg_get once' => sub {
    my $x = "rain";
    drench($x);                         # 100
    my $up = uc($x);                    # mg_get: 100-10=90
    is( wetness($x), 80,               # wetness(): 90-10=80
        'uc() + wetness() = -20 total' );
    is( $up, "RAIN", 'uc() result correct' );
};

# ------------------------------------------------------------------
# 4. lc() fires mg_get once
# ------------------------------------------------------------------
subtest 'lc() fires mg_get once' => sub {
    my $x = "STORM";
    drench($x);                         # 100
    my $lo = lc($x);                    # mg_get: 100-10=90
    is( wetness($x), 80,               # wetness(): 90-10=80
        'lc() + wetness() = -20 total' );
    is( $lo, "storm", 'lc() result correct' );
};

# ------------------------------------------------------------------
# 5. length() fires mg_get once
# ------------------------------------------------------------------
subtest 'length() fires mg_get once' => sub {
    my $x = "flood";
    drench($x);                         # 100
    my $len = length($x);               # mg_get: 100-10=90
    is( wetness($x), 80,               # wetness(): 90-10=80
        'length() + wetness() = -20 total' );
    is( $len, 5, 'length() result correct' );
};

# ------------------------------------------------------------------
# 6. Numeric addition: $x + 0 fires mg_get once
# ------------------------------------------------------------------
subtest 'numeric addition fires mg_get once' => sub {
    my $x = 42;
    drench($x);                         # 100
    my $n = $x + 0;                     # mg_get: 100-10=90
    is( wetness($x), 80,               # wetness(): 90-10=80
        '$x + 0 + wetness() = -20 total' );
    is( $n, 42, 'numeric value correct' );
};

# ------------------------------------------------------------------
# 7. Boolean context: if ($x) fires mg_get once
# ------------------------------------------------------------------
subtest 'boolean context fires mg_get once' => sub {
    my $x = "truthy";
    drench($x);                         # 100
    my $was_true = $x ? 1 : 0;         # mg_get: 100-10=90
    is( wetness($x), 80,               # wetness(): 90-10=80
        'boolean eval + wetness() = -20 total' );
    is( $was_true, 1, 'boolean result correct' );
};

# ------------------------------------------------------------------
# 8. Print fires mg_get once
# ------------------------------------------------------------------
subtest 'print fires mg_get once' => sub {
    my $x = "splash";
    drench($x);                         # 100
    {
        open my $fh, '>', \my $buf;
        print $fh $x;                   # mg_get: 100-10=90
    }
    is( wetness($x), 80,               # wetness(): 90-10=80
        'print + wetness() = -20 total' );
};

# ------------------------------------------------------------------
# 9. Passing to a sub fires mg_get once (on read of the argument)
# ------------------------------------------------------------------
subtest 'passing to a true no-op sub does not fire mg_get' => sub {
    my $x = "drizzle";
    drench($x);                         # 100
    sub _noop {}
    _noop($x);                          # @_ gets an alias to $x — no value read, no mg_get
    is( wetness($x), 90,               # wetness(): 100-10=90 (only this call fires mg_get)
        'pass-to-noop fires mg_get zero times; wetness() = -10 total' );
};

# ------------------------------------------------------------------
# 10. Multiple reads in one expression each fire mg_get separately
# ------------------------------------------------------------------
subtest 'multiple reads in one expression each fire mg_get' => sub {
    my $x = "torrent";
    drench($x);                         # 100
    # $x . $x reads $x twice: 100-10=90, 90-10=80
    my $doubled = $x . $x;             # two mg_get fires
    is( wetness($x), 70,               # wetness(): 80-10=70
        'two reads in one concat + wetness() = -30 total' );
    is( $doubled, "torrenttorrent", 'doubled string correct' );
};

# ------------------------------------------------------------------
# 11. Accumulated passive decay drains independently of explicit calls
# ------------------------------------------------------------------
subtest 'passive and explicit decay accumulate' => sub {
    my $x = "squall";
    wet($x);           # 50

    # 3 implicit reads (each -10):
    my $a = "$x";      # 50-10=40
    my $b = "$x";      # 40-10=30
    my $c = "$x";      # 30-10=20

    # 2 explicit reads:
    wetness($x);       # 20-10=10
    is( wetness($x), 0,   # 10-10=0
        '3 passive + 2 explicit = 5 total reads, wet(50) fully drained' );
    ok( is_dry($x),    'is_dry after 5 total accesses on wet(50) scalar' );
};

done_testing();
