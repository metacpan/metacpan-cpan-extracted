use strict;
use warnings;

use Test::More;

use Valiemon;

use_ok 'Valiemon::Attributes::Properties';

subtest 'validate properties' => sub {
    my $v = Valiemon->new({
        type => 'object',
        properties => {
            name  => { type => 'string'  },
            price => { type => 'integer' },
        },
    });
    my ($res, $err);
    ($res, $err) = $v->validate({ name => 'fish', price => 300 });
    ok $res;
    is $err, undef;

    ($res, $err) = $v->validate({ name => 'meat', price => [] });
    ok !$res;
    is $err->position, '/properties/price/type';
};

subtest 'validate nested properties' => sub {
    my ($res, $err);
    my $v = Valiemon->new({
        type => 'object',
        properties => {
            name  => {
                type => 'object',
                properties => {
                    first => { type => 'string' },
                    last  => { type => 'string' },
                    age   => { type => 'integer' },
                },
            },
        },
    });

    ($res, $err) = $v->validate({
        name => {
            first => 'ane',
            last  => 'hosii',
            age   => 14,
        }
    });
    ok $res;
    is $err, undef;

    ($res, $err) = $v->validate({ name => [] });
    ok !$res;
    is $err->position, '/properties/name/type';

    ($res, $err) = $v->validate({
        name => {
            # none `first`
            last => 'hoge',
            age  => '18',
        }
    });
    ok $res, 'first is not required';
    is $err, undef;

    ($res, $err) = $v->validate({
        name => {
            first => 'foo',
            last  => 'bar',
            age   => '1.5',
        }
    });
    ok !$res;
    is $err->position, '/properties/name/properties/age/type';
};

subtest 'validate properties with required' => sub {
    my ($res, $error);
    my $v = Valiemon->new({
        type => 'object',
        properties => {
            name => { type => 'string', required => 1 },
            cv   => { type => 'string' },
        },
    });

    ($res, $error) = $v->validate({ name => 'mio', cv => 'meshiya' });
    ok $res;
    is $error, undef;

    ($res, $error) = $v->validate({ name => 'eve' });
    ok $res;
    is $error, undef;

    ($res, $error) = $v->validate({ cv => 'me' });
    ok !$res;
    is $error->position, '/properties';
};

done_testing;
