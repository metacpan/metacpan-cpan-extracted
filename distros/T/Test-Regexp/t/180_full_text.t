#!/usr/bin/perl

use strict;
use warnings;
no  warnings 'syntax';

use 5.010;

use Test::Tester;
use Test::Regexp;
use Test::More 0.88;

my $subject        = "0123456789" x 10;
my $trunc_subject  = "0123456789" x 5;
   $trunc_subject .= "...56789";

my $pat = qr /.+/;

foreach my $full_text (0, 1) {
    my ($premature, @results) = run_tests sub {
        match subject   => "$subject",
              pattern   => $pat,
              full_text => $full_text,
        ;
    };
    my $exp_subject = $full_text ? $subject : $trunc_subject;
    my $not         = $full_text ? "not "   : "";

    is $results [0] {name}, qq {qq {$exp_subject} matched by /$pat/},
                           "Subject is ${not}truncated";
}


done_testing;
