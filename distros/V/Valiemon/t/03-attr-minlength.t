use strict;
use warnings;

use Test::More;

use Valiemon;

use_ok 'Valiemon::Attributes::MinLength';

subtest 'validate minLength' => sub {
    my ($res, $err);
    my $v = Valiemon->new({ minLength => 6 });

    ($res, $err) = $v->validate('unagi');
    ok !$res;
    is $err->position, '/minLength';

    ($res, $err) = $v->validate('kegani');
    ok $res, 'maxLength is inclusive';
    is $err, undef;

    ($res, $err) = $v->validate('hamachi');
    ok $res;
    is $err, undef;
};

subtest 'detect schema error' => sub {
    {
        eval {
            Valiemon->new({ minLength => -1 })->validate('a');
        };
        like $@, qr/`minLength` must be/;
    }
    {
        eval {
            Valiemon->new({ minLength => {} })->validate('b');
        };
        like $@, qr/`minLength` must be/;
    }
};

done_testing;
