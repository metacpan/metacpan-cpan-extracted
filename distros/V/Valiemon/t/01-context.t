use strict;
use warnings;

use Test::More;
use Test::Deep qw(eq_deeply);

use Valiemon;

use_ok 'Valiemon::Context';

my $schema = {
    type => 'object',
    definitions => {
        person => {
            type => 'object',
            properties => {
                name => { type => 'string' },
                child => { '$ref' => '#/definitions/person' },
            },
            required => [qw(name)],
        },
    },
    properties => {
        user => { '$ref' => '#/definitions/person' },
    },
};

subtest 'new' => sub {
    my $v = Valiemon->new($schema);
    my $c = Valiemon::Context->new($v, $v->schema);
    is $c->root_validator, $v;
    is_deeply $c->root_schema, $v->schema;
};

subtest 'clone_from' => sub {
    my $v = Valiemon->new($schema);
    my $original_c = Valiemon::Context->new($v, $v->schema);

    my $c = Valiemon::Context->clone_from($original_c);
    is_deeply $c->root_validator, $original_c->root_validator;
    is_deeply $c->root_schema, $original_c->root_schema;

    subtest 'shallow copy' => sub {
        $original_c->push_error('heyhey');
        ok !eq_deeply $original_c->errors, $c->errors;

        $c->push_error('heyhey');
        ok eq_deeply $original_c->errors, $c->errors;

        $c->push_error('hoyhoy');
        ok !eq_deeply $original_c->errors, $c->errors;
    }
};

subtest 'sub_validator' => sub {
    my $opts = { use_json_boolean => 1 };
    my $v = Valiemon->new($schema, $opts);
    is_deeply $v->options, $opts;

    my $c = Valiemon::Context->new($v, $v->schema);
    my $sub_schema = $v->resolve_ref('#/definitions/person');
    my $sv = $c->sub_validator($sub_schema);
    is_deeply $sv->options, $opts, 'inherit options from root validator in context';
};

done_testing;
