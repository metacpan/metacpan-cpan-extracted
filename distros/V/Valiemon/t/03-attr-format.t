use strict;
use warnings;

use Test::More;

use Valiemon;

use_ok 'Valiemon::Attributes::Format';

subtest 'date-time' => sub {
    my ($res, $error);
    my $v = Valiemon->new({ format => 'date-time' });

    subtest 'UTC' => sub {
        ($res, $error) = $v->validate('2014-01-01T00:00:00Z');
        ok $res;
        is $error, undef;
    };

    subtest '+09:00' => sub {
        ($res, $error) = $v->validate('2014-01-01T00:00:00+09:00');
        ok $res;
        is $error, undef;
    };

    subtest 'not a String' => sub {
        ($res, $error) = $v->validate(undef);
        ok $res;
        is $error, undef;
    };

    subtest 'invalid' => sub {
        ($res, $error) = $v->validate('2014-01-01 00:00:00');
        ok !$res;
        is $error->position, '/format';
    };

    subtest 'invalid(range)' => sub {
        TODO : {
            local $TODO = 'RFC3339 range of value';
            ($res, $error) = $v->validate('2014-13-61T00:00:00Z');
            ok !$res;

            todo_skip 'it dies', 1;
            is $error->position, '/format';
        };
    }
};

subtest 'uri' => sub {
    my ($res, $error);
    my $v = Valiemon->new({ format => 'uri' });

    subtest 'valid' => sub {
        for my $input (qw(
                           ftp://example.com/
                           http://example.com/
                           https://example.com/
                           https://example.com/%E5%B0%8F%E9%A3%BC%E5%BC%BE
                     )) {
            subtest $input => sub {
                ($res, $error) = $v->validate($input);
                ok $res;
                is $error, undef;
            };
        }
    };

    subtest 'invalid' => sub {
        for my $input (qw(
                           example
                           小飼弾
                           https://example.com/小飼弾
                           https://小飼弾.example.com/
                     )) {
            subtest $input => sub {
                ($res, $error) = $v->validate($input);
                ok !$res;
                is $error->position, '/format';
            };
        }
    };
};

subtest 'invalid format' => sub {
    my ($res, $error);

    my $v = Valiemon->new({ format => 'the-invalid-format' });
    eval {
        $v->validate('a');
    };
    like $@, qr/invalid format: `the-invalid-format`/;
};

done_testing;
