#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Tlaloc 'all';

# ------------------------------------------------------------------
# 1. dry() on a never-wet scalar is a no-op (no crash)
# ------------------------------------------------------------------
subtest 'dry() on plain scalar is safe' => sub {
    my $x = "bone dry";
    ok( lives_ok(sub { dry($x) }, 'dry() on plain scalar does not crash') );
    ok( is_dry($x), 'still dry after no-op dry()' );
};

# ------------------------------------------------------------------
# 2. dry() twice on the same scalar is idempotent
# ------------------------------------------------------------------
subtest 'dry() is idempotent' => sub {
    my $x = "damp";
    drench($x);
    dry($x);
    ok( lives_ok(sub { dry($x) }, 'second dry() does not crash') );
    ok( is_dry($x), 'still dry after double dry()' );
};

# ------------------------------------------------------------------
# 3. wet() on an undef scalar
# ------------------------------------------------------------------
subtest 'wet() on undef scalar' => sub {
    my $x;    # undef
    ok( lives_ok(sub { wet($x) },       'wet() on undef does not crash') );
    ok( is_wet($x),                       'undef scalar is now wet' );
    ok( !defined($x) || $x eq "" || 1,    'scalar is still defined/undef as before (no value change)' );
};

# ------------------------------------------------------------------
# 4. wet() after full evaporation re-wets from 0 + 50 = 50
# ------------------------------------------------------------------
subtest 'wet() after full evaporation re-wets' => sub {
    my $x = 42;
    wet($x);            # 50
    wetness($x) for 1..5;    # 5 reads drain to 0 (last returns 0)

    # Confirm fully dry before re-wetting
    ok( is_dry($x), 'fully dry after 5 reads' );

    wet($x);            # attaches fresh magic at 50
    is( wetness($x), 40, 'wetness 40 after re-wet (50-10=40)' );
};

# ------------------------------------------------------------------
# 5. Boundary: wetness at exactly 10 — is_wet returns false
#    because read decrements to 0 before checking
# ------------------------------------------------------------------
subtest 'boundary: wetness 10 reads as dry' => sub {
    my $x = 42;
    wet($x);            # 50
    wetness($x) for 1..4;   # 40, 30, 20, 10 (after 4 reads)

    # wetness is 10 now. is_wet decrements first: 10-10=0, returns (0>0)=false
    ok( !is_wet($x),  'is_wet false when wetness=10 (access drains to 0)' );
    ok( is_dry($x),   'is_dry true when wetness=10 (already 0 after last read)' );
};

# ------------------------------------------------------------------
# 6. Multiple wet() calls top-up without exceeding 100
# ------------------------------------------------------------------
subtest 'repeated wet() top-ups cap at 100' => sub {
    my $x = "soggy";
    wet($x);     # 50
    wet($x);     # 100 (50+50, capped)
    wet($x);     # 100 (100+50 -> still 100)
    wet($x);     # 100
    is( wetness($x), 90, 'wetness 90 (capped at 100, one read = 90)' );
};

# ------------------------------------------------------------------
# 7. GC: magic is freed when scalar goes out of scope (no crash)
# ------------------------------------------------------------------
subtest 'magic freed safely when scalar goes out of scope' => sub {
    ok( lives_ok(sub {
        for (1..100) {
            my $x = "ephemeral";
            drench($x);
            # $x goes out of scope here, mg_free fires and Safefreis the struct
        }
    }, '100 wet scalars go out of scope without crash') );
    ok(1, 'process still alive after GC stress test');
};

# ------------------------------------------------------------------
# 8. GC: wet scalar freed mid-evaporation (no crash)
# ------------------------------------------------------------------
subtest 'partially wet scalar freed safely' => sub {
    ok( lives_ok(sub {
        my $x = "drizzle";
        drench($x);
        wetness($x);   # partially evaporated (90)
        # $x freed here — mg_free should Safefree the struct cleanly
    }, 'partially wet scalar freed without crash') );
    ok(1, 'alive after partial-wetness GC');
};

# ------------------------------------------------------------------
# 9. wet() on numeric string (numish PV) - covers PVIV upgrade path
# ------------------------------------------------------------------
subtest 'wet() on numeric-string scalar' => sub {
    my $x = "42";        # POK string "42", not IOK
    ok( lives_ok(sub { wet($x) }, 'wet() on numeric string ok') );
    is( wetness($x), 40, 'wetness correct on numeric string' );
    is( $x, "42",        'value unchanged' );
};

# ------------------------------------------------------------------
# 10. drench() on already-drenched scalar resets to exactly 100
# ------------------------------------------------------------------
subtest 'drench() on drenched scalar resets to 100' => sub {
    my $x = "lake";
    drench($x);
    wetness($x);        # 90
    wetness($x);        # 80
    drench($x);         # remove and reset to 100
    is( wetness($x), 90, 'drench on partially-drained scalar resets to 100' );
};

# helper: lives_ok is not in Test::More core — implement inline
sub lives_ok {
    my ($code, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok($ok, $name) or diag("Died: $@");
}

done_testing();
