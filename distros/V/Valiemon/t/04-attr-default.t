use strict;
use warnings;

use Test::More;

use Valiemon;

subtest 'fillin default' => sub {
    my ($res, $error);
    my $v = Valiemon->new({
        type => 'object',
        properties => {
            id => { type => 'integer' },
            name => { type => 'string', default => 'anonymous' },
        },
        required => [qw(id name)],
    });

    my $d1 = { id => 10 };
    ($res, $error) = $v->validate($d1);
    ok $res;
    is $error, undef;
    is_deeply $d1, { id => 10, name => 'anonymous' }, 'fillin name property';


    my $d2 = { id => 927, name => 'pokupoku' };
    ($res, $error) = $v->validate($d2);
    ok $res;
    is $error, undef;
    is_deeply $d2, { id => 927, name => 'pokupoku' }, 'keep name property';
};

subtest 'fillin default with $ref' => sub {
    my ($res, $error);
    my $v = Valiemon->new({
        type => 'object',
        definitions => {
            name => { type => 'string', default => 'anonymous' },
        },
        properties => {
            id => { type => 'integer' },
            name => { '$ref' => '#/definitions/name' },
        },
        required => [qw(id name)],
    });

    my $d1 = { id => 10 };
    ($res, $error) = $v->validate($d1);
    ok $res;
    is $error, undef;
    is_deeply $d1, { id => 10, name => 'anonymous' }, 'fillin name property';


    my $d2 = { id => 927, name => 'pokupoku' };
    ($res, $error) = $v->validate($d2);
    ok $res;
    is $error, undef;
    is_deeply $d2, { id => 927, name => 'pokupoku' }, 'keep name property';
};

subtest 'fillin default at toplevel' => sub {
    TODO : {
        # > This keyword MAY be used in root schemas, and in any subschemas.
        # http://json-schema.org/latest/json-schema-validation.html#anchor103
        local $TODO = 'currently default keyword not support not object value at top level';
        my $v = Valiemon->new({ type => 'integer', default => 1 });
        my $d = undef;
        $v->validate($d);
        is $d, 1;
    }
};

done_testing;
