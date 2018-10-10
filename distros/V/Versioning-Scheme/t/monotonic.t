#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Versioning::Scheme::Monotonic;

subtest is_valid => sub {
    ok(!Versioning::Scheme::Monotonic->is_valid_version(''));
    ok(!Versioning::Scheme::Monotonic->is_valid_version('1'));
    ok( Versioning::Scheme::Monotonic->is_valid_version('1.1'));
    ok(!Versioning::Scheme::Monotonic->is_valid_version('1.01'));
    ok( Versioning::Scheme::Monotonic->is_valid_version('1.100'));
    ok( Versioning::Scheme::Monotonic->is_valid_version('1.100.0'));
    ok( Versioning::Scheme::Monotonic->is_valid_version('1.100+foo'));
    ok( Versioning::Scheme::Monotonic->is_valid_version('1.100.0+foo'));
    ok( Versioning::Scheme::Monotonic->is_valid_version('1.100+foo.bar-baz.123.000'));
    ok(!Versioning::Scheme::Monotonic->is_valid_version('1.100+foo.bar_baz.123.000'));
    ok(!Versioning::Scheme::Monotonic->is_valid_version('1.100.1'));
    ok(!Versioning::Scheme::Monotonic->is_valid_version('1.1.0.0'));
    ok(!Versioning::Scheme::Monotonic->is_valid_version('1.1beta'));
};

subtest normalize => sub {
    dies_ok { Versioning::Scheme::Monotonic->normalize_version('1.1.1') } 'invalid -> dies';

    is(Versioning::Scheme::Monotonic->normalize_version('1.2'), '1.2');
    is(Versioning::Scheme::Monotonic->normalize_version('1.2.0'), '1.2');
};

subtest cmp => sub {
    dies_ok { Versioning::Scheme::Monotonic->cmp_version('1.1.1', '1.1') };
    dies_ok { Versioning::Scheme::Monotonic->cmp_version('1.1', '1.1.1') };

    is(Versioning::Scheme::Monotonic->cmp_version('1.1', '1.1'), 0);
    is(Versioning::Scheme::Monotonic->cmp_version('1.1.0', '1.1'), 0);
    is(Versioning::Scheme::Monotonic->cmp_version('1.2', '1.13'), -1);
    is(Versioning::Scheme::Monotonic->cmp_version('2.2', '1.13'), 1);
    is(Versioning::Scheme::Monotonic->cmp_version('2.2+foo', '2.2.0+foo'), 0);
    is(Versioning::Scheme::Monotonic->cmp_version('2.2+alpha', '2.2.0+beta'), -1);
};

subtest bump => sub {
    dies_ok { Versioning::Scheme::Monotonic->bump_version('1.1.1') };

    is(Versioning::Scheme::Monotonic->bump_version('1.1'), '1.2');
    is(Versioning::Scheme::Monotonic->bump_version('1.1.0'), '1.2.0');

    # opt: num
    dies_ok { Versioning::Scheme::Monotonic->bump_version('1.1', {num=>-1}) };
    dies_ok { Versioning::Scheme::Monotonic->bump_version('1.1', {num=>-2}) };
    dies_ok { Versioning::Scheme::Monotonic->bump_version('1.2', {num=>-2}) };
    is(Versioning::Scheme::Monotonic->bump_version('1.1', {num=>2}), '1.3');
    is(Versioning::Scheme::Monotonic->bump_version('1.2', {num=>-1}), '1.1');
    is(Versioning::Scheme::Monotonic->bump_version('1.2', {num=>-1}), '1.1');

    # opt: part
    dies_ok { Versioning::Scheme::Monotonic->bump_version('1.1', {part=> 2}) };
    dies_ok { Versioning::Scheme::Monotonic->bump_version('1.1', {part=>-1}) };
    is(Versioning::Scheme::Monotonic->bump_version('1.2', {part=>1}), '1.3');
    is(Versioning::Scheme::Monotonic->bump_version('1.2', {part=>1, num=>-1}), '1.1');
    is(Versioning::Scheme::Monotonic->bump_version('1.2', {part=>0}), '2.3');
    is(Versioning::Scheme::Monotonic->bump_version('2.2', {part=>0, num=>-1}), '1.1');
};

DONE_TESTING:
done_testing;
