use strict;
use warnings;

use Test::More;

use Valiemon;

use_ok 'Valiemon::Attributes::Not';

subtest 'validate not' => sub {
    my ($res, $error);
    my $v = Valiemon->new({
        not => {
            properties => { age => { type => 'number' } }
        },
    });

    ($res, $error) = $v->validate({ name => 'usamin', age => 'himitsu' });
    ok $res, 'ok when invalidate data for subschema ';
    is $error, undef;

    ($res, $error) = $v->validate({ name => 'usamin', age => 17 });
    ok !$res, 'ng when data is valid for subschema';
    is $error->position, '/not';
};

subtest 'detect schema error' => sub {
    {
        eval {
            Valiemon->new({
                type => 'object',
                properties => { name => { type => 'string' } },
                not => [], # Not object
            })->validate({ name => 'pom' });
        };
        like $@, qr/be an object/;
    }
};

done_testing;
