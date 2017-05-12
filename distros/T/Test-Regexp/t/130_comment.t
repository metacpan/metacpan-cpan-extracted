#!/usr/bin/perl

use strict;
use warnings;
no  warnings 'syntax';

use 5.010;

use lib ".";

use Test::Tester;
use Test::Regexp;
use t::Common;

my $match_res;

foreach my $name (undef, "", "Hello", "Flip Flap") {
    foreach my $arg_name ("name", "comment") {
        foreach my $keep (0, 1) {
            my $p_arg_name = $keep ? "keep_pattern" : "pattern";
            my ($premature, @results) = run_tests sub {
                $match_res = match subject      => "Foo",
                                   $p_arg_name  => qr {Foo},
                                   $arg_name    => $name,
            };

            check results   => \@results,
                  premature => $premature,
                  expected  => 'PPPP',
                  match     => 1,
                  match_res => $match_res,
                  pattern   => 'Foo',
                  subject   => "Foo",
                  comment   => $name,
                  keep      => $keep,
            ;
        }
    }
}
