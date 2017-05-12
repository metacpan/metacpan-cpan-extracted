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

foreach my $pattern (qr {Foo}, qr {Bar}) {
    foreach my $match (0, 1) {
        my ($premature, @results) = run_tests sub {
            $match_res = match subject => "Foo",
                               pattern => $pattern,
                               match   => $match,
                               todo    => "Todo test",
        };

        check results   => \@results,
              premature => $premature,
              expected  => $match ? 'PPPP' : 'P',
              match     => $match,
              match_res => $match_res,
              pattern   => $pattern,
              subject   => "Foo",
              todo      => "Todo test",
        ;
    }
}


__END__
