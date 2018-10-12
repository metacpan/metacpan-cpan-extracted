#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Versioning::Scheme::Semantic;

subtest is_valid => sub {
    ok(!Versioning::Scheme::Semantic->is_valid_version(''));
    ok(!Versioning::Scheme::Semantic->is_valid_version('1'));
    ok(!Versioning::Scheme::Semantic->is_valid_version('1.1'));
    ok(!Versioning::Scheme::Semantic->is_valid_version('1.01'));
    ok(!Versioning::Scheme::Semantic->is_valid_version('1.100'));
    ok( Versioning::Scheme::Semantic->is_valid_version('1.100.0'));

    ok(!Versioning::Scheme::Semantic->is_valid_version('1.2.3.4'), 'too many parts');

    # pre-release identifier
    ok( Versioning::Scheme::Semantic->is_valid_version('1.2.3-beta1'));
    ok( Versioning::Scheme::Semantic->is_valid_version('1.2.3-beta-one'));
    ok( Versioning::Scheme::Semantic->is_valid_version('1.2.3-123'));
    ok(!Versioning::Scheme::Semantic->is_valid_version('1.2.3-0123'));

    # metadata
    ok( Versioning::Scheme::Semantic->is_valid_version('1.2.3+000'));
    ok( Versioning::Scheme::Semantic->is_valid_version('1.2.3-beta1+000'));
    ok(!Versioning::Scheme::Semantic->is_valid_version('1.2.3+foo_bar'));

    # invalid
    ok(!Versioning::Scheme::Semantic->is_valid_version('1.1beta'));
};

subtest parse => sub {
    is_deeply(
        Versioning::Scheme::Semantic->parse_version('1.2.3-beta1+000'),
        {major=>1, minor=>2, patch=>3, prerelease=>'beta1', metadata=>'000'},
    );
};

subtest normalize => sub {
    dies_ok { Versioning::Scheme::Semantic->normalize_version('1.1') } 'invalid -> dies';

    is(Versioning::Scheme::Semantic->normalize_version('1.2.3'), '1.2.3');
};

subtest cmp => sub {
    dies_ok { Versioning::Scheme::Semantic->cmp_version('1.1', '1.1.1') };
    dies_ok { Versioning::Scheme::Semantic->cmp_version('1.1.1', '1.1') };

    is(Versioning::Scheme::Semantic->cmp_version('1.0.0', '1.0.0'), 0);
    is(Versioning::Scheme::Semantic->cmp_version('1.3.0', '1.12.0'), -1);
    is(Versioning::Scheme::Semantic->cmp_version('2.3.0', '1.12.0'), 1);

    # with pre-release
    is(Versioning::Scheme::Semantic->cmp_version('2.3.0', '2.3.0-beta'), 1);
    is(Versioning::Scheme::Semantic->cmp_version('2.3.0-beta', '2.3.0-beta'), 0);
    is(Versioning::Scheme::Semantic->cmp_version('2.3.0-beta1', '2.3.0-beta2'), -1);

    # with metadata
    is(Versioning::Scheme::Semantic->cmp_version('2.3.0+meta1', '2.3.0+meta2'), 0);

    # with pre-release & metadata
    is(Versioning::Scheme::Semantic->cmp_version('2.3.0+meta1', '2.3.0-beta1+meta2'), 1);
};

subtest bump => sub {
    dies_ok { Versioning::Scheme::Semantic->bump_version('1.1') };

    is(Versioning::Scheme::Semantic->bump_version('1.2.3'), '1.2.4');

    is(Versioning::Scheme::Semantic->bump_version('1.2.3-beta+foo'), '1.2.4-beta+foo');

    # opt: num
    dies_ok { Versioning::Scheme::Semantic->bump_version('1.2.3', {num=>0}) };
    dies_ok { Versioning::Scheme::Semantic->bump_version('1.2.3', {num=>-4}) };
    is(Versioning::Scheme::Semantic->bump_version('1.2.3', {num=>2}), '1.2.5');
    is(Versioning::Scheme::Semantic->bump_version('1.2.3', {num=>-1}), '1.2.2');
    is(Versioning::Scheme::Semantic->bump_version('1.2.3', {num=>-3}), '1.2.0');

    # opt: part
    dies_ok { Versioning::Scheme::Semantic->bump_version('1.2.3', {part=> 3}) };
    dies_ok { Versioning::Scheme::Semantic->bump_version('1.2.3', {part=>-4}) };
    is(Versioning::Scheme::Semantic->bump_version('1.2.3', {part=>-2}), '1.3.0');
    is(Versioning::Scheme::Semantic->bump_version('1.2.3', {part=>-2, num=>-1}), '1.1.3');
    is(Versioning::Scheme::Semantic->bump_version('1.2.3', {part=>0}), '2.0.0');

    # opt: reset_smaller
    is(Versioning::Scheme::Semantic->bump_version('1.2.3', {part=>-2, reset_smaller=>0}), '1.3.3');
};

DONE_TESTING:
done_testing;
