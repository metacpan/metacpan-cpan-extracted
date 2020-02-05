use strict;
use warnings;

use Test::More;

use Valiemon;

use_ok 'Valiemon::Attributes::Required';

subtest 'validate required' => sub {
    my ($res, $error);
    my $v = Valiemon->new({ required => [qw(key)] });

    ($res, $error) = $v->validate({ key => 'hoge' });
    ok $res, 'required constraint satisifed';
    is $error, undef;

    ($res, $error) = $v->validate({ key => {} });
    ok $res, 'any type ok';
    is $error, undef;

    ($res, $error) = $v->validate({ ke => {} });
    ok !$res;
    is $error->position, '/required';
};

subtest 'validate required with object' => sub {
    my ($res, $error);
    my $v = Valiemon->new({
        type => 'object',
        properties => {
            name => { type => 'string' },
            age  => { type => 'integer' },
        },
        required => [qw(name age)]
    });

    ($res, $error) = $v->validate({ name => 'oneetyan', age => 17 });
    ok $res;
    is $error, undef;

    ($res, $error) = $v->validate({ name => 'oneetyan', age => 17, is_kawaii => 1 });
    ok $res;
    is $error, undef;

    ($res, $error) = $v->validate({ name => 'oneetyan' });
    ok !$res;
    is $error->position, '/required';
};

subtest 'nothing required with object' => sub {
    my ($res, $error);
    my $v = Valiemon->new({
        type => 'object',
        properties => {
            name => { type => 'string' },
            age  => { type => 'integer' },
        },
    });

    ($res, $error) = $v->validate({});
    ok $res;
    is $error, undef;
};

subtest 'required with optional object' => sub {
    my ($res, $error);
    my $v = Valiemon->new({
        type => 'object',
        properties => {
            opt => {
                type => 'object',
                required => [qw(req)],
                properties => {
                    req => {
                        type => 'string'
                    }
                }
            }
        },
    });

    ($res, $error) = $v->validate({});
    ok $res;
    is $error, undef;
    ($res, $error) = $v->validate({ opt => {} });
    ok ! $res;
    ok $error;
    ($res, $error) = $v->validate({ opt => { req => "foo" } });
    ok $res;
    is $error, undef;
};

subtest 'detect schema error' => sub {
    {
        eval {
            Valiemon->new({
                type => 'object',
                properties => { name => { type => 'string' } },
                required => [], # empty
            })->validate({ name => 'pom' });
        };
        like $@, qr/must be an array and have at leas one element/;
    }
    {
        eval {
            Valiemon->new({
                type => 'object',
                properties => { name => { type => 'string' } },
                required => { name => 1 }, # not array
            })->validate({ name => 'pom' });
        };
        like $@, qr/must be an array and have at leas one element/;
    }
};

done_testing;
