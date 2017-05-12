#!/usr/bin/env perl

use 5.008;
use strict;
use warnings;
use Test::More 0.94;
use Fcntl ':seek';
use Tie::Handle::Filter;

my %test_operation = (
    'print' => sub { print {shift} qw(hello world) },
    'printf' => sub { printf {shift} '%s and %s', qw(hello world) },
    'syswrite' => sub { my $foo = 'hello world'; syswrite shift, $foo },
);

my %filter_output = (
    filter_first => [
        sub { "first $_[0] ", @_[ 1 .. $#_ ] },
        'print'    => 'first hello world',
        'printf'   => 'first hello  and world',
        'syswrite' => substr 'first hello world',
        0, length 'hello world',
    ],
    filter_all => [
        sub {
            map {"all $_"} @_;
        },
        'print'    => 'all helloall world',
        'printf'   => 'all hello and all world',
        'syswrite' => substr 'all hello world',
        0,
        length 'hello world',
    ],
);
plan tests => scalar keys %filter_output;

while ( my ( $filter_name, $filter_ref ) = each %filter_output ) {
    subtest $filter_name => sub {
        my $function_ref = shift @{$filter_ref};
        my %output       = @{$filter_ref};
        plan tests => scalar keys %output;

        while ( my ( $operation, $expected ) = each %output ) {
            subtest $operation => sub {
                plan tests => 3;

                open my $fh, '+>', undef
                    or die "can't create anonymous storage: $!";

                ok eval {
                    tie *$fh, 'Tie::Handle::Filter', *$fh, $function_ref;
                    1;
                } => 'tie';

                ok eval { $test_operation{$operation}->($fh); 1 } =>
                    $operation;

                untie *$fh;
                seek $fh, 0, SEEK_SET
                    or die "can't seek to start of anonymous storage: $!";
                my $written;
                if ( $operation eq 'syswrite' ) {
                    sysread $fh, $written, length $expected;
                }
                else {
                    $written = join '', <$fh>;
                }

                is $written, $expected, 'read back' or show $written;
            };
        }
    };
}
