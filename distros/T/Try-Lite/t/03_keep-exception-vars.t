use strict;
use warnings;
use Test::More;

use Try::Lite;

subtest 'simple' => sub {
    $@ = "foo\n";
    try {
        die "bar\n";
    } (
        '*' => sub {}
    );
    is $@, "foo\n";
};

subtest 'nested' => sub {
    my $deep_exception;
    $@ = "foo\n";
    try {
        $@ = "bar\n";
        try {
            die "baz\n";
        } (
            '*' => sub {}
        );
        $deep_exception = $@;
    } (
        '*' => sub {}
    );
    is $@, "foo\n";
    is $deep_exception, "bar\n";
};

done_testing;
