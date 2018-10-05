#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Versioning::Scheme::Dotted;

subtest is_valid => sub {
    ok(!Versioning::Scheme::Dotted->is_valid_version(''));
    ok( Versioning::Scheme::Dotted->is_valid_version('1'));
    ok( Versioning::Scheme::Dotted->is_valid_version('1.1'));
    ok( Versioning::Scheme::Dotted->is_valid_version('1.01'));
    ok( Versioning::Scheme::Dotted->is_valid_version('1.100'));
    ok( Versioning::Scheme::Dotted->is_valid_version('1.2.3.4'));
    ok(!Versioning::Scheme::Dotted->is_valid_version('1.1beta'));
};

subtest normalize => sub {
    dies_ok { Versioning::Scheme::Dotted->normalize_version('1.1beta') } 'invalid -> dies';

    is(Versioning::Scheme::Dotted->normalize_version('1'), 1);
    is(Versioning::Scheme::Dotted->normalize_version('1.2.3'), '1.2.3');
    is(Versioning::Scheme::Dotted->normalize_version('1.2.3', {parts=>4}), '1.2.3.0');
    is(Versioning::Scheme::Dotted->normalize_version('1.2.3', {parts=>5}), '1.2.3.0.0');
    is(Versioning::Scheme::Dotted->normalize_version('1.2.3', {parts=>2}), '1.2');

    dies_ok { Versioning::Scheme::Dotted->normalize_version('1.1', {parts=>0}) } 'invalid parts-> dies';
};

subtest cmp => sub {
    dies_ok { Versioning::Scheme::Dotted->cmp_version('1.0beta', '1') };
    dies_ok { Versioning::Scheme::Dotted->cmp_version('1', '1.0beta') };

    is(Versioning::Scheme::Dotted->cmp_version('1', '1'), 0);
    is(Versioning::Scheme::Dotted->cmp_version('1.0.0', '1'), 0);
    is(Versioning::Scheme::Dotted->cmp_version('1.1.0', '1.001.000'), 0);
    is(Versioning::Scheme::Dotted->cmp_version('1.1.20', '1.1.21'), -1);
    is(Versioning::Scheme::Dotted->cmp_version('1.2.20', '1.1.21'), 1);
};

subtest bump => sub {
    dies_ok { Versioning::Scheme::Dotted->bump_version('1.0beta') };

    is(Versioning::Scheme::Dotted->bump_version('1.200.003'), '1.200.004');

    # opt: num
    dies_ok { Versioning::Scheme::Dotted->bump_version('1.200.003', {num=>0}) };
    dies_ok { Versioning::Scheme::Dotted->bump_version('1.200.003', {num=>-4}) };
    is(Versioning::Scheme::Dotted->bump_version('1.200.003', {num=>2}), '1.200.005');
    is(Versioning::Scheme::Dotted->bump_version('1.200.003', {num=>-1}), '1.200.002');
    is(Versioning::Scheme::Dotted->bump_version('1.200.003', {num=>-3}), '1.200.000');

    # opt: part
    dies_ok { Versioning::Scheme::Dotted->bump_version('1.200.003', {part=>-4}) };
    is(Versioning::Scheme::Dotted->bump_version('1.200.003', {part=>-2}), '1.201.000');
    is(Versioning::Scheme::Dotted->bump_version('1.200.003', {part=>-2, num=>-1}), '1.199.003');
    is(Versioning::Scheme::Dotted->bump_version('1.200.003', {part=>0}), '2.000.000');

    # opt: reset_smaller
    is(Versioning::Scheme::Dotted->bump_version('1.200.003', {part=>-2, reset_smaller=>0}), '1.201.003');
};

DONE_TESTING:
done_testing;
