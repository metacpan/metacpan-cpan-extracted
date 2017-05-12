use strict;
use warnings;
use Test::More;

use Try::Lite;

subtest 'propagated' => sub {
    eval {
        try {
            die "foo\n";
        } ( '*' => sub { die } );
    };
    like $@, qr/\Afoo\n\s+...propagated/;

    eval {
        try {
            die "foo\n";
        } ( '*' => sub { die "bar\n" } );
    };
    is $@, "bar\n";
};

done_testing;
