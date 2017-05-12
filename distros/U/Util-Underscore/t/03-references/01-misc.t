#!perl

use strict;
use warnings;

use Test::More tests => 3;

use Util::Underscore;

BEGIN {

    package Local::Numy;

    use overload
        fallback => 1,
        '0+'     => sub {
        return 0;
        };
}

subtest '_::ref_addr' => sub {
    plan tests => 7;
    my $ref  = [];
    my $addr = 0 + $ref;

    is _::ref_addr $ref, $addr, "positive simple ref";

    my $object = bless $ref, 'Local::Numy';
    isnt 0 + $object, $addr, "fixture";
    is _::ref_addr $object, $addr, "positive overloaded object";

    ok !defined _::ref_addr undef, "negative undef";
    ok !defined _::ref_addr "foo", "negative string";

    is _::ref_addr, $addr, "positive default argument" for $ref;
    ok !defined _::ref_addr, "negative default argument" for undef;
};

subtest '_::ref_type' => sub {
    plan tests => 8;
    is _::ref_type [], 'ARRAY', "positive simple ref";

    my $object = bless [], "Foo";
    isnt ref $object, 'ARRAY', "fixture";
    is _::ref_type $object, 'ARRAY', "positive object";

    ok !defined _::ref_type undef, "negative undef";
    ok !defined _::ref_type "foo", "negative string";

    is _::ref_type, 'ARRAY', "positive default argument" for [];
    ok !defined _::ref_type, "negative default argument" for undef;

    subtest "positive return values" => sub {
        plan tests => 7;

        is _::ref_type \1, 'SCALAR', 'SCALAR';
        is _::ref_type \\1, 'REF', 'REF';
        is _::ref_type [], 'ARRAY', 'ARRAY';
        is _::ref_type {}, 'HASH', 'HASH';
        is _::ref_type sub { }, 'CODE', 'CODE';
        is _::ref_type \*::, 'GLOB', 'GLOB';
        is _::ref_type qr//, 'REGEXP', 'REGEXP';
    };
};

subtest 'weak refs' => sub {
    plan tests => 9;
    my $ref = \do { my $o };

    subtest 'sanity check' => sub {
        plan tests => 3;
        ok !_::ref_is_weak $ref, "negative fixture";
        _::ref_weaken $ref;
        ok _::ref_is_weak $ref, "positive after weakening";
        _::ref_unweaken $ref;
        ok !_::ref_is_weak $ref, "negative after unweakening";
    };

    # now, for checking that this is actually dealing with weak refs
    my ($weak_ref, $strong_ref);
    ok !defined $weak_ref,   "fixture weak ref";
    ok !defined $strong_ref, "fixture strong ref";
    {
        my $value;
        $strong_ref = $weak_ref = \$value;
        _::ref_weaken $weak_ref;
        ok !_::ref_is_weak $strong_ref, "strong ref is strong";
        ok _::ref_is_weak $weak_ref,    "weak ref is weak";

        # at this point, $value has a refcount of 2 – itself and $strong_ref
    }

    # $value is now out of scope, refcount is 1.

    is _::ref_addr $strong_ref, _::ref_addr $weak_ref, "refs in sync";

    {
        my $copy = $weak_ref;
        ok !_::ref_is_weak $copy, "copies of weak refs are strong refs";
    }

    undef $strong_ref;

    # $value dropped to refcount 0, is reclaimed
    ok !defined $weak_ref, "stale weak ref is undef";

    subtest 'default argument' => sub {
        plan tests => 3;
        my $ref      = [];     # needed to avoid garbage collection
        my $weak_ref = $ref;
        for ($weak_ref) {
            ok !_::ref_is_weak, "negative _::ref_is_weak";
            _::ref_weaken;
            ok _::ref_is_weak, "positive _::ref_is_weak";
            _::ref_unweaken;
            ok !_::ref_is_weak, "negative _::ref_is_weak";
        }
    };
};
