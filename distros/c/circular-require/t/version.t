#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

my %tests;
BEGIN {
    %tests = (
        '5.008001' => undef,
        'v5.8.1'   => undef,
        '5.8.1'    => undef,
        '6.008001' => qr/^Perl v6\.8\.1 required/,
        'v6.8.1'   => qr/^Perl v6\.8\.1 required/,
        '6.8.1'    => qr/^Perl v6\.8\.1 required/,
        'vFoo'     => qr/^Can't locate vFoo\.pm in \@INC/,
        'v101'     => qr/^Perl v101\.0\.0 required/,
        '"v101"'   => qr/^Can't locate v101 in \@INC/,
        '"5.8.1"'  => qr/^Can't locate 5\.8\.1 in \@INC/,
        '"5.008"'  => qr/^Can't locate 5\.008 in \@INC/,
    );
}

sub run_tests {
    my $when = shift;
    for my $test (keys %tests) {
        for my $require (qw(use require)) {
            # use STRING is not valid syntax
            next if $require eq 'use' && $test =~ /^"/;

            eval "$require $test";
            my $err = $@;
            if (defined($tests{$test})) {
                like($err, $tests{$test},
                     "$require $test threw the correct error $when");
            }
            else {
                is($err, '',
                   "$require $test succeeded $when");
            }
        }
    }
}

BEGIN { run_tests 'before load' }

no circular::require;

run_tests 'when enabled';

use circular::require;

run_tests 'when disabled';

done_testing;
