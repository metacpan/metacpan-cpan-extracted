use strict;
use warnings;
use Test::More;

use t::lib::Exceptions;

use Try::Lite;

subtest 'nexted try catch' => sub {
    my $caught_exception;
    try {
        try {
            MyException->throw;
        } (
            '*' => sub {
                die;
            }
        );
    } (
        '*' => sub {
            $caught_exception = $@;
        }
    );
    isa_ok $caught_exception, 'MyException';
};

done_testing;
