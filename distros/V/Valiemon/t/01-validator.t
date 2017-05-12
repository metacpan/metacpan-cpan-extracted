use strict;
use warnings;

use Test::More;
use Test::Deep;

use_ok 'Valiemon';

subtest 'validate' => sub {
    my $v = Valiemon->new({
        type => 'array',
        items => { type => 'integer' },
    });

    subtest 'pass' => sub {
        my ($result, $error) = $v->validate([1,2,3]);
        ok $result;
        ok ! $error;
    };

    subtest 'ValidationError has position, attribute, expected, actual' => sub {
        my ($result, $error) = $v->validate([1,2,'a']);
        ok !$result;
        cmp_deeply $error, isa('Valiemon::ValidationError') & methods(
            position => '/items/2/type',
            attribute => 'Valiemon::Attributes::Type',
            expected => {
                type => 'integer'
            },
            actual => 'a',
        );
    };
};

done_testing;
