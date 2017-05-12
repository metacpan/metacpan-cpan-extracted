use strict;
use warnings;

use Test::More;

use Valiemon;

use_ok 'Valiemon::Attributes::Items';

subtest 'validate array (schema)' => sub {
    my ($res, $err);
    my $v = Valiemon->new({
        type => 'array',
        items => { type => 'integer' },
    });

    ($res, $err) = $v->validate([1, 2, 3]);
    ok $res;
    is $err, undef;

    ($res, $err) = $v->validate([1, 2, 3.5]);
    ok !$res;
    is $err->position, '/items/2/type';

    ($res, $err) = $v->validate([{ a => 'hoge' }]);
    ok !$res;
    is $err->position, '/items/0/type';
};

subtest 'validate array (index)' => sub {
    my ($res, $err);
    my $v = Valiemon->new({
        type => 'array',
        items => [{type => 'integer'}, {type => 'object'}, {type => 'array'}],
    });

    ($res, $err) = $v->validate([1, {}, []]);
    ok $res;
    is $err, undef;

    ($res, $err) = $v->validate([1, [], 3.5]);
    ok !$res;
    is $err->position, '/items/1/type';
};

subtest 'validate array with $ref' => sub {
    my ($res, $err) = @_;
    my $v = Valiemon->new({
        type => 'object',
        definitions => {
            array_item => {
                type => 'object',
                properties => { 'name' => { type => 'string' } },
                required => [qw(name)],
            },
        },
        properties => {
            users => {
                type => 'array',
                items => { '$ref' => '#/definitions/array_item' },
            },
        },
        required => [qw(users)]
    });

    ($res, $err) = $v->validate({ users => [ {name => 'hoge'}, {name => 'fuga'}] });
    ok $res;
    is $err, undef;

    ($res, $err) = $v->validate({ users => [] });
    ok $res;
    is $err, undef;

    ($res, $err) = $v->validate({ users => [ {name => 'hoge'}, {namae => 'tarou'} ] });
    ok !$res;
    is $err->position, '/properties/users/items/1/$ref/required';
};

done_testing;
