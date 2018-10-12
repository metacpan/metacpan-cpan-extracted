#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Versioning::Scheme::Perl;

subtest is_valid => sub {
    ok(!Versioning::Scheme::Perl->is_valid_version(''));
    ok( Versioning::Scheme::Perl->is_valid_version('1'));
    ok( Versioning::Scheme::Perl->is_valid_version('1.1'));
    ok( Versioning::Scheme::Perl->is_valid_version('1.01'));
    ok( Versioning::Scheme::Perl->is_valid_version('1.100'));
    ok( Versioning::Scheme::Perl->is_valid_version('1.2.3.4'));
    ok(!Versioning::Scheme::Perl->is_valid_version('1.1beta'));
};

subtest parse => sub {
    is_deeply(Versioning::Scheme::Perl->parse_version('1.0beta'), undef);
    is_deeply(Versioning::Scheme::Perl->parse_version('1.2.3'), {parts=>[1,2,3]});
};

subtest normalize => sub {
    dies_ok { Versioning::Scheme::Perl->normalize_version('1.1beta') } 'invalid -> dies';

    is(Versioning::Scheme::Perl->normalize_version('1'), "v1.0.0");
    is(Versioning::Scheme::Perl->normalize_version('1.2.3'), 'v1.2.3');
};

subtest cmp => sub {
    dies_ok { Versioning::Scheme::Perl->cmp_version('1.0beta', '1') };
    dies_ok { Versioning::Scheme::Perl->cmp_version('1', '1.0beta') };

    is(Versioning::Scheme::Perl->cmp_version('1', '1'), 0);
    is(Versioning::Scheme::Perl->cmp_version('1.0.0', '1'), 0);
    is(Versioning::Scheme::Perl->cmp_version('1.1.0', '1.001.000'), 0);
    is(Versioning::Scheme::Perl->cmp_version('1.1.20', '1.1.21'), -1);
    is(Versioning::Scheme::Perl->cmp_version('1.2.20', '1.1.21'), 1);
};

subtest bump => sub {
    dies_ok { Versioning::Scheme::Perl->bump_version('1.0beta') };

    is(Versioning::Scheme::Perl->bump_version('1.200.003'), 'v1.200.4');

    # opt: num
    dies_ok { Versioning::Scheme::Perl->bump_version('1.200.003', {num=>0}) };
    dies_ok { Versioning::Scheme::Perl->bump_version('1.200.003', {num=>-4}) };
    is(Versioning::Scheme::Perl->bump_version('1.200.003', {num=>2}), 'v1.200.5');
    is(Versioning::Scheme::Perl->bump_version('1.200.003', {num=>-1}), 'v1.200.2');
    is(Versioning::Scheme::Perl->bump_version('1.200.003', {num=>-3}), 'v1.200.0');
    is(Versioning::Scheme::Perl->bump_version('1.200.003', {num=>1200}), 'v1.201.203');
    is(Versioning::Scheme::Perl->bump_version('1.200.003', {num=>12000}), 'v1.212.3');
    is(Versioning::Scheme::Perl->bump_version('1.200.003', {num=>120000}), 'v1.320.3');
    is(Versioning::Scheme::Perl->bump_version('1.200.003', {num=>1200000}), 'v2.400.3');

    # opt: part
    dies_ok { Versioning::Scheme::Perl->bump_version('1.200.003', {part=>-4}) };
    is(Versioning::Scheme::Perl->bump_version('1.200.003', {part=>-2}), 'v1.201.0');
    is(Versioning::Scheme::Perl->bump_version('1.200.003', {part=>-2, num=>-1}), 'v1.199.3');
    is(Versioning::Scheme::Perl->bump_version('1.200.003', {part=>0}), 'v2.0.0');

    # opt: reset_smaller
    is(Versioning::Scheme::Perl->bump_version('1.200.003', {part=>-2, reset_smaller=>0}), 'v1.201.3');
};

DONE_TESTING:
done_testing;
