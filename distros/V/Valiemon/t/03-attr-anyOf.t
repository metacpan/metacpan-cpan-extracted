use strict;
use warnings;

use Test::More;

use Valiemon;

use_ok 'Valiemon::Attributes::AnyOf';

subtest 'anyOf' => sub {
    my ($res, $err);
    my $v = Valiemon->new({
        anyOf => [
            { properties => { name => { type => "string" } }, required => ['name'] },
            { properties => { age => { type => "integer" } } },
        ],
    });

    ($res, $err) = $v->validate({ name => 'rei', age => 14 });
    ok $res, 'both satisfied';
    is $err, undef;

    ($res, $err) = $v->validate({ name => 'mari', age => 'secret' });
    ok $res, 'first schema satisfied';
    is $err, undef;

    ($res, $err) = $v->validate({ age => 14 });
    ok $res, 'second schema satisfied';
    is $err, undef;

    ($res, $err) = $v->validate({ age => 'secret' });
    ok !$res, 'failed both schema validation';
    is $err->position, '/anyOf';
};

subtest 'single element in anyOf' => sub {
    my ($res, $err);
    my $v = Valiemon->new({
        anyOf => [
            { properties => { age => { type => "integer" } } },
        ],
    });

    ($res, $err) = $v->validate({ name => 'rei', age => 14 });
    ok $res;
    is $err, undef;

    ($res, $err) = $v->validate({ name => 'mari', age => 'secret' });
    ok !$res;
    is $err->position, '/anyOf';
};

subtest 'detect schema error' => sub {
    {
        eval {
            Valiemon->new({
                anyOf => {},
            })->validate([]);
        };
        like $@, qr/`anyOf` must be/;
    }
    {
        eval {
            Valiemon->new({
                anyOf => 'heyhey',
            })->validate([]);
        };
        like $@, qr/`anyOf` must be/;
    }
};

done_testing;
