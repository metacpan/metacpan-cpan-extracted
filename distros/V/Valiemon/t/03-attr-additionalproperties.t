use strict;
use warnings;

use Test::More;

use Valiemon;

use_ok 'Valiemon::Attributes::AdditionalProperties';

subtest 'additionalProperties=false' => sub {
    my $v = Valiemon->new({
        type => 'object',
        properties => {
            name  => { type => 'string'  },
            price => { type => 'integer' },
        },
        additionalProperties => 0,
    });

    subtest 'all properties are defined' => sub {
        my ($res, $err) = $v->validate({name => 'a', price => 1});
        ok $res, 'object is valid';
        is $err, undef;
    };

    subtest 'with additional property `tax`' => sub {
        my ($res, $err) = $v->validate({name => 'a', price => 1, tax => 'free'});
        ok !$res, 'object is invalid';
        is $err->position, '/additionalProperties';
    };
};

subtest 'additionalProperties=true or not specified' => sub {
    my $v = Valiemon->new({
        type => 'object',
        properties => {
            name  => { type => 'string'  },
            price => { type => 'integer' },
        },
        additionalProperties => 1,
    });
    my ($res, $err) = $v->validate({name => 'a', price => 1, tax => 'free'});
    ok $res, 'object is valid';
    is $err, undef;
};

subtest 'not specified' => sub {
    my $v = Valiemon->new({
        type => 'object',
        properties => {
            name  => { type => 'string'  },
            price => { type => 'integer' },
        },
    });
    my ($res, $err) = $v->validate({name => 'a', price => 1, tax => 'free'});
    ok $res, 'object is valid';
    is $err, undef;
};

done_testing;
