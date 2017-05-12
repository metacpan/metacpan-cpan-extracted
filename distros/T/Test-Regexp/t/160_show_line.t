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

foreach my $reason (undef, "", 0, "Bla bla bla") {
    foreach my $name ("", "Baz", "Qux Quux") {
        foreach my $match (0, 1) {
            my $pattern = $match ? qr {Foo} : qr {Bar};
            my ($premature, @results) = run_tests sub {
#line 999 160_show_line
                $match_res = match subject   => "Foo",
                                   pattern   => $pattern,
                                   match     => $match,
                                   reason    => $reason,
                                   test      => $reason,
                                   name      => $name,
                                   show_line => 1,
            };

            check results   => \@results,
                  premature => $premature,
                  expected  => $match ? 'PPPP' : 'P',
                  match     => $match,
                  match_res => $match_res,
                  pattern   => $pattern,
                  subject   => "Foo",
                  comment   => $name,
                  keep      => 0,
                  line      => [999 => '160_show_line'],
        $match ? (test      => $reason)
               : (reason    => $reason),
            ;
        }
    }
}


__END__
