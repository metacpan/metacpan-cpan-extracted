#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Versioning::Scheme::Python;

subtest is_valid => sub {
    ok(!Versioning::Scheme::Python->is_valid_version(''));
    ok( Versioning::Scheme::Python->is_valid_version('1'));
    ok( Versioning::Scheme::Python->is_valid_version('1!1.2.3post1.dev2+local'));
    # XXX more tests
};

subtest parse => sub {
    is_deeply(Versioning::Scheme::Python->parse_version(''), undef);
    is_deeply(Versioning::Scheme::Python->parse_version('1.2.3'), {base=>[1,2,3]});
    # XXX more tests
};

subtest normalize => sub {
    dies_ok { Versioning::Scheme::Python->normalize_version('') } 'invalid -> dies';

    is(Versioning::Scheme::Python->normalize_version('1.01'), "1.1");
    # XXX more tests
};

subtest cmp => sub {
    dies_ok { Versioning::Scheme::Python->cmp_version('', '1') };
    dies_ok { Versioning::Scheme::Python->cmp_version('1', '') };

    is(Versioning::Scheme::Python->cmp_version('1', '1'), 0);
    is(Versioning::Scheme::Python->cmp_version('1.1', '1.1a1'), 1);
    # XXX more tests
};

subtest bump => sub {
    dies_ok { Versioning::Scheme::Python->bump_version('') };

    is(Versioning::Scheme::Python->bump_version('1.2.003'), '1.2.4');

    # opt: num
    dies_ok { Versioning::Scheme::Python->bump_version('1.2.003', {num=>0}) };
    dies_ok { Versioning::Scheme::Python->bump_version('1.2.003', {num=>-4}) };
    is(Versioning::Scheme::Python->bump_version('1.2.003', {num=>2}), '1.2.5');
    is(Versioning::Scheme::Python->bump_version('1.2.003', {num=>-1}), '1.2.2');
    is(Versioning::Scheme::Python->bump_version('1.2.003', {num=>-3}), '1.2.0');

    # opt: part num
    dies_ok { Versioning::Scheme::Python->bump_version('1.2.003', {part=>-4}) };
    is(Versioning::Scheme::Python->bump_version('1.2.003', {part=>-2}), '1.3.0');
    is(Versioning::Scheme::Python->bump_version('1.2.003', {part=>-2, num=>-1}), '1.1.3');
    is(Versioning::Scheme::Python->bump_version('1.2.003', {part=>0}), '2.0.0');

    # opt: reset_smaller
    is(Versioning::Scheme::Python->bump_version('1.2.003', {part=>-2, reset_smaller=>0}), '1.3.3');

    # opt: part a
    dies_ok { Versioning::Scheme::Python->bump_version('1.2.003', {part=>'a'}) };
    is(Versioning::Scheme::Python->bump_version('1.2.003a1', {part=>'a'}), '1.2.3a2');

    # XXX more tests
};

DONE_TESTING:
done_testing;
