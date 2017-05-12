use strict;
use warnings;

use Test::More;

use Valiemon;

use_ok 'Valiemon::Attributes::MaxItems';

subtest 'minItems' => sub {
    my ($res, $err);
    my $v = Valiemon->new({
        type => 'array',
        maxItems => 4,
    });

    ($res, $err) = $v->validate([1,2,3]);
    ok $res;
    is $err, undef;

    ($res, $err) = $v->validate([1,2,3,4]);
    ok $res, 'maxItem is inclusive';
    is $err, undef;

    ($res, $err) = $v->validate([1,2,3,4,5]);
    ok !$res;
    is $err->position, '/maxItems';
};

subtest 'detect schema error' => sub {
    {
        eval {
            Valiemon->new({ maxItems => 3.14 })->validate([]);
        };
        like $@, qr/`maxItems` must be/;
    }
    {
        eval {
            Valiemon->new({ maxItems => {} })->validate([]);
        };
        like $@, qr/`maxItems` must be/;
    }
};

done_testing;
