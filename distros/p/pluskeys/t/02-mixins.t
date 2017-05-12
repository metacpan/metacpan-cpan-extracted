#!perl -T
use 5.008;
use strict;
use warnings;

# These tests are awkward because of needing to 
# test for compilation effects and failures.

package Test::pluskeys;

our @ISA = qw(
    Test::pluskeys::Test1
    Test::pluskeys::Test2
);

use Test::More;
use Test::Exception;

my $AVOID_522_BUG = sub {
    my $danger_zone = $] >= 5.021007 && $] < 5.023010;
    skip "bareword detection bug in perl $]", 1 if $danger_zone;
};

my $obj = bless { };
my $want;

{
    package Test::pluskeys::Test1;
    use Test::More;
    use Test::Exception;

    BEGIN { use_ok pluskeys => qw(ALPHA BETA GAMMA) }

    $want = "first beta";
       $obj->{ +BETA } =  $want;
    is $obj->{ +BETA } => $want,  "direct +BETA store of $want";

    isnt $obj->{ +BETA }, $obj->{ BETA },  "first +BETA pluskey version distinct from BETA unpluskey";

    sub inner {
        my $self = shift;
        return $self->{ +ALPHA } = shift if @_;
        return $self->{ +ALPHA };
    }

    $want = "first alpha";
    $obj->inner($want);
    is $obj->inner => $want,  "method store of $want";

    lives_ok(
        sub { eval q( my $x = $obj->{ +ALPHA }; 1 ) || die; },
        "in-scope +ALPHA pluskey lives",
    );

    my $gamma;
    lives_ok(
        sub { eval q( $gamma = $obj->{ +GAMMA }; 1 ) || die; },
        "in-scope +GAMMA pluskey lives",
    );
    ok !defined($gamma), "+GAMMA is undef";

SKIP: { 
        &$AVOID_522_BUG();
        throws_ok(
            sub { eval q( my $x = $obj->{ +ALHPA }; 1 ) || die; },
            qr/Bareword "ALHPA" not allowed while "strict subs" in use/,
            "typo'd +ALHPA pluskey dies",
        );
    }

}

{
    package Test::pluskeys::Test2;
    use Test::More;
    use Test::Exception;

    # make sure these are additive
    BEGIN { use_ok pluskeys => qw(ALPHA) }
    BEGIN { use_ok pluskeys => qw(BETA) }

    $want = "second beta";
       $obj->{ +BETA } =  $want;
    is $obj->{ +BETA } => $want,  "direct +BETA store of $want"; 

    isnt $obj->{ +BETA }, $obj->{ BETA },  "second +BETA pluskey version distinct from unpluskey BETA";

    sub outer {
        my $self = shift;
        return $self->{ +ALPHA } = shift if @_;
        return $self->{ +ALPHA };
    }

    $want = "second alpha";
    $obj->outer($want);
    is $obj->outer => $want,  "method store of $want";

SKIP: { 
        &$AVOID_522_BUG();
        throws_ok(
            sub { eval q( my $x = $obj->{ +GAMMA }; 1 ) || die; },
            qr/Bareword "GAMMA" not allowed while "strict subs" in use/,
            "missing +GAMMA pluskey dies",
        );

    }

} ## package Test::pluskeys::Test2

SKIP: { 
        &$AVOID_522_BUG();
        throws_ok(
            sub { eval q( my $x = $obj->{ +ALPHA }; 1 ) || die; },
            qr/Bareword "ALPHA" not allowed while "strict subs" in use/,
            "out-of-scope bareword dies",
        );
}

isnt $obj->inner, $obj->outer,  "distinct inner/outer +ALPHAs";

cmp_ok 4, "==", scalar(keys %$obj), "four keys in object";

for my $key (keys %$obj) {
    like $key, qr/\w::\w/,      "key $key looks like a pluskey";
}


done_testing();
