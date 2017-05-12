use strict;
use warnings;
use Test::More;

use t::lib::Exceptions;

use Try::Lite;

subtest 'object' => sub {
    eval {
        try {
            YourException->throw;
        } (
            'MyException' => sub {
            }
        );
        ok 0;
    };
    isa_ok $@, 'YourException';
};

subtest 'string' => sub {
    eval {
        try {
            die "foo\n";
        } (
            'MyException' => sub {
            }
        );
        ok 0;
    };
    is $@, "foo\n";
};

done_testing;
