use strict;
use warnings;

use Test::More;

use Valiemon;

use_ok 'Valiemon::Attributes::OneOf';

subtest 'oneOf' => sub {
    my ($res, $err);
    my $v = Valiemon->new({
        oneOf => [
            { required => ['codeName'] },
            { required => ['realName'] },
        ],
    });

    ($res, $err) = $v->validate({ codeName => 'V' });
    ok $res, 'first schema satisfied';
    is $err, undef;

    ($res, $err) = $v->validate({ realName => 'Venus' });
    ok $res, 'second schema satisfied';
    is $err, undef;

    ($res, $err) = $v->validate({ codeName => 'V', realName => 'Venus' });
    ok !$res, 'only one schema should be satisfied';
    is $err->position, '/oneOf';

    ($res, $err) = $v->validate({ });
    ok !$res, 'failed both schema validation';
    is $err->position, '/oneOf';
};

subtest 'single element in oneOf' => sub {
    my ($res, $err);
    my $v = Valiemon->new({
        oneOf => [
            { properties => { age => { type => "integer" } } },
        ],
    });

    ($res, $err) = $v->validate({ name => 'rei', age => 14 });
    ok $res;
    is $err, undef;

    ($res, $err) = $v->validate({ name => 'mari', age => 'secret' });
    ok !$res;
    is $err->position, '/oneOf';
};

subtest 'detect schema error' => sub {
    {
        eval {
            Valiemon->new({
                oneOf => {},
            })->validate([]);
        };
        like $@, qr/`oneOf` must be/;
    }
    {
        eval {
            Valiemon->new({
                oneOf => 'heyhey',
            })->validate([]);
        };
        like $@, qr/`oneOf` must be/;
    }
};

done_testing;
