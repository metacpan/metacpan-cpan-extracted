use strict;
use warnings;
use Test::More;

use t::lib::Exceptions;

use Try::Lite;

subtest 'simple' => sub {
    my @exceptions;

    try {
        MyException->throw;
    } (
        'MyException' => sub {
            push @exceptions, ref($@);
        }
    );

    try {
        YourException->throw;
    } (
        'MyException' => sub {
            push @exceptions, ref($@);
        },
        'YourException' => sub {
            push @exceptions, ref($@);
        }
    );

    is_deeply \@exceptions, [qw/ MyException YourException /];
};

subtest 'nested_class' => sub {
    my $e;
    try {
        MyException->throw;
    } (
        'BaseException' => sub {
            $e = $@;
        }
    );
    isa_ok($e, 'BaseException');
    isa_ok($e, 'MyException');
};

subtest 'wildcard' => sub {
    my $e;
    try {
        die;
    } (
        'MyException' => sub {
        },
        '*' => sub {
            $e = $@;
        }
    );
    like $e, qr/^Died/;
};

subtest 'not catch' => sub {
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

done_testing;
