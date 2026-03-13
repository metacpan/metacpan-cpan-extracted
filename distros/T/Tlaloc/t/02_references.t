#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Tlaloc 'all';

# All six functions accept a reference and transparently operate on the
# referent (SvROK check + SvRV unwrap in every XSUB).

# ------------------------------------------------------------------
# 1. wet($ref) where $ref = \$x wets $x (the referent), not $ref
# ------------------------------------------------------------------
subtest 'wet($ref) wets the referent, not $ref itself' => sub {
    my $x   = "rain";
    my $ref = \$x;    # $ref holds a reference to $x

    wet($ref);        # SvROK($ref)=1 → unwrap → wets $x
    ok( is_wet($x),   '$x is wet after wet($ref)' );
    # $ref itself (as a ref-SV) has no magic — check via \$ref (unwraps to $ref)
    ok( is_dry(\$ref), '$ref SV itself is dry (magic is on $x, not $ref)' );
};

# ------------------------------------------------------------------
# 2. wetness(\$x) reads wetness of the referent
# ------------------------------------------------------------------
subtest 'wetness() via reference reads referent wetness' => sub {
    my $x = "cloud";
    wet($x);                        # 50
    is( wetness(\$x), 40, 'wetness(\$x) reads referent (50-10=40)' );
};

# ------------------------------------------------------------------
# 3. drench(\$x) drenches the referent
# ------------------------------------------------------------------
subtest 'drench() via reference' => sub {
    my $x = "storm";
    drench(\$x);
    is( wetness($x), 90, 'drench via ref: wetness 90 after one read' );
};

# ------------------------------------------------------------------
# 4. is_wet(\$x) and is_dry(\$x) inspect the referent
# ------------------------------------------------------------------
subtest 'is_wet() and is_dry() via reference' => sub {
    my $x = "puddle";

    ok( is_dry(\$x),  'is_dry(\$x) true before any wet()' );

    wet($x);
    ok( is_wet(\$x),  'is_wet(\$x) true after wet($x)' );
    ok( !is_dry(\$x), 'is_dry(\$x) false after wet($x)' );
};

# ------------------------------------------------------------------
# 5. dry(\$x) dries the referent
# ------------------------------------------------------------------
subtest 'dry() via reference' => sub {
    my $x = "flood";
    drench($x);
    dry(\$x);
    ok( is_dry($x), 'referent is dry after dry(\$x)' );
};

# ------------------------------------------------------------------
# 6. Magic on $x does not affect an independent $y
# ------------------------------------------------------------------
subtest 'magic is isolated to one scalar' => sub {
    my $x = "wet one";
    my $y = "dry one";
    wet($x);
    ok( is_wet($x),  '$x is wet'    );
    ok( is_dry($y),  '$y is still dry — magic is per-SV' );
};

# ------------------------------------------------------------------
# 7. Assignment copies value but NOT magic
# ------------------------------------------------------------------
subtest 'assignment does not copy magic' => sub {
    my $x = "source";
    drench($x);
    my $y = $x;              # copies the string "source", not the magic
    ok( is_wet($x),  '$x still wet after assignment' );
    ok( is_dry($y),  '$y is dry — assignment never copies MAGIC' );
    is( $y, "source", '$y has the correct value' );
};

# ------------------------------------------------------------------
# 8. Only one level of unwrap: wet(\$ref) wets $ref, not $$ref
# ------------------------------------------------------------------
subtest 'single level of ref unwrap' => sub {
    my $x   = "deep";
    my $ref = \$x;    # $ref is a ref to $x

    # wet(\$ref): sv = \$ref, SvROK=1, unwrap → sv = $ref
    # We wet $ref (the ref-SV), NOT $x
    wet(\$ref);

    # is_wet(\$ref): sv = \$ref, SvROK=1, unwrap → checks $ref → wet ✓
    ok( is_wet(\$ref), '$ref SV is wet after wet(\$ref)' );
    # is_dry($x): $x has no magic → dry ✓
    ok( is_dry($x),    '$x is dry — only one level unwrapped' );
};

done_testing();
