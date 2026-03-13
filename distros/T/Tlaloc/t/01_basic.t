#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Tlaloc 'all';

# NOTE: tlaloc_read_wetness() DECREMENTS wetness by 10 BEFORE returning.
# So wetness($x), is_wet($x), and is_dry($x) each cost 10 wetness per call.
# mg_get also fires (-10) on every Perl-level read of a wet scalar.

# ------------------------------------------------------------------
# 1. Plain scalar has no magic — always dry
# ------------------------------------------------------------------
subtest 'plain scalar is dry' => sub {
    my $x = "hello";
    is( wetness($x), 0,  'wetness 0 on plain scalar'   );
    ok( is_dry($x),      'is_dry true on plain scalar'  );
    ok( !is_wet($x),     'is_wet false on plain scalar' );
};

# ------------------------------------------------------------------
# 2. wet() attaches magic at level 50
# ------------------------------------------------------------------
subtest 'wet() attaches magic at 50' => sub {
    my $x = "hello";
    wet($x);
    # tlaloc_read_wetness: 50-10=40
    is( wetness($x), 40, 'wetness 40 after wet() and one call' );
};

# ------------------------------------------------------------------
# 3. wet() makes scalar is_wet
# ------------------------------------------------------------------
subtest 'wet() makes is_wet true' => sub {
    my $x = "hello";
    wet($x);                         # 50
    ok( is_wet($x), 'is_wet true after wet()' );  # 50-10=40, 40>0
};

# ------------------------------------------------------------------
# 4. is_dry false after wet()
# ------------------------------------------------------------------
subtest 'is_dry false after wet()' => sub {
    my $x = "hello";
    wet($x);                          # 50
    ok( !is_dry($x), 'is_dry false after wet()' );  # 50-10=40, 40!=0
};

# ------------------------------------------------------------------
# 5. drench() sets wetness to 100
# ------------------------------------------------------------------
subtest 'drench() sets to 100' => sub {
    my $x = "hello";
    drench($x);
    # tlaloc_read_wetness: 100-10=90
    is( wetness($x), 90, 'wetness 90 after drench() and one call' );
};

# ------------------------------------------------------------------
# 6. dry() removes magic
# ------------------------------------------------------------------
subtest 'dry() removes magic' => sub {
    my $x = "hello";
    drench($x);
    dry($x);
    is( wetness($x), 0,  'wetness 0 after dry()'   );
    ok( is_dry($x),      'is_dry true after dry()' );
    ok( !is_wet($x),     'is_wet false after dry()' );
};

# ------------------------------------------------------------------
# 7. wet() on already-wet scalar tops up (no decrement on top-up)
# ------------------------------------------------------------------
subtest 'wet() tops up without decrementing' => sub {
    my $x = "hello";
    wet($x);            # 50
    wet($x);            # 50 + 50 = 100  (top-up, no decrement side effect)
    is( wetness($x), 90, 'wetness 90 after two wet() calls + one read' );
};

# ------------------------------------------------------------------
# 8. wet() top-up capped at 100
# ------------------------------------------------------------------
subtest 'wet() top-up capped at 100' => sub {
    my $x = "hello";
    drench($x);         # 100
    wet($x);            # 100 + 50 = 150 -> capped at 100
    is( wetness($x), 90, 'wetness capped at 100 (90 after one read)' );
};

# ------------------------------------------------------------------
# 9. drench() always resets to 100 regardless of current level
# ------------------------------------------------------------------
subtest 'drench() resets to exactly 100' => sub {
    my $x = "hello";
    wet($x);            # 50
    wetness($x);        # 50-10=40 (drains to 40)
    drench($x);         # removes old magic, attaches fresh 100
    is( wetness($x), 90, 'drench always gives 100 (90 after one read)' );
};

# ------------------------------------------------------------------
# 10. Access-based evaporation: 10 reads drain drench from 100 to 0
# ------------------------------------------------------------------
subtest 'evaporation: 10 reads drain drench to 0' => sub {
    my $x = 42;         # use integer to avoid any implicit string reads
    drench($x);         # 100
    my $w;
    for (1..10) {
        $w = wetness($x);   # each call: -10
    }
    # Call 1: 90, Call 2: 80, ..., Call 10: 0
    is( $w, 0, 'wetness 0 after 10 wetness() calls on drenched scalar' );
    ok( is_dry($x),   'is_dry after 10 reads' );
    ok( !is_wet($x),  'is_wet false after 10 reads' );
};

# ------------------------------------------------------------------
# 11. wet() drains to 0 in 5 reads
# ------------------------------------------------------------------
subtest 'evaporation: 5 reads drain wet() to 0' => sub {
    my $x = 42;
    wet($x);            # 50
    my $w;
    for (1..5) {
        $w = wetness($x);   # 40, 30, 20, 10, 0
    }
    is( $w, 0, 'wetness 0 after 5 reads on wet() scalar' );
    ok( is_dry($x), 'is_dry after 5 reads' );
};

# ------------------------------------------------------------------
# 12. mg_get passive decay fires on Perl-level reads
# ------------------------------------------------------------------
subtest 'mg_get passive decay on stringify' => sub {
    my $x = "hello";
    drench($x);                  # 100
    wetness($x);                 # 100-10=90 (explicit call)
    my $copy = "$x";             # mg_get fires: 90-10=80 (passive)
    is( wetness($x), 70,         # 80-10=70
        'wetness 70 after explicit + stringify + explicit' );
};

# ------------------------------------------------------------------
# 13. Scalar value is unaffected by magic operations
# ------------------------------------------------------------------
subtest 'scalar value unchanged by magic' => sub {
    my $x = "hello";
    wet($x);
    is( $x, "hello", 'value unchanged after wet()' );
    drench($x);
    is( $x, "hello", 'value unchanged after drench()' );
    dry($x);
    is( $x, "hello", 'value unchanged after dry()' );
};

done_testing();
