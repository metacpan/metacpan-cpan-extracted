use strict;
use warnings;

use Test::More;

use Valiemon;

use_ok 'Valiemon::Attributes::MaxLength';

subtest 'validate maxLength' => sub {
    my ($res, $err);
    my $v = Valiemon->new({ maxLength => 6 });

    ($res, $err) = $v->validate('unagi');
    ok $res;
    is $err, undef;

    ($res, $err) = $v->validate('kegani');
    ok $res, 'maxLength is inclusive';
    is $err, undef;

    ($res, $err) = $v->validate('hamachi');
    ok !$res;
    is $err->position, '/maxLength';
};

subtest 'detect schema error' => sub {
    {
        eval {
            Valiemon->new({ maxLength => -1 })->validate('a');
        };
        like $@, qr/`maxLength` must be/;
    }
    {
        eval {
            Valiemon->new({ maxLength => {} })->validate('b');
        };
        like $@, qr/`maxLength` must be/;
    }
};

done_testing;
