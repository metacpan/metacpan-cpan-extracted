#!/usr/bin/perl

use strict;
use warnings;
no  warnings 'syntax';

use 5.010;

use lib ".";

use Test::Tester;
use Test::Regexp import => [];
use t::Common;

my $pattern = '(\w+)\s+(\w+)';

my @checkers = (
    Test::Regexp:: -> new -> init (
        keep_pattern => $pattern,
        pattern      => '\w+\s+\w+',
        name         => 'US president',
    ),
    Test::Regexp:: -> new -> init (
        keep_pattern => $pattern,
        pattern      => '\w+\s+\w+',
        comment      => 'US president',
    ),
);

my @data = (
    ['PPPPPPPPPP',   [qw [Gerald Ford]]],
    ['PPPPPPPPPP',   [qw [Jimmy Carter]]],
);

foreach my $data (@data) {
    my $expected = shift @$data;
    my $captures = shift @$data;
    my $subject  = join ' ' => @$captures;

    foreach my $checker (@checkers) {
        my $match_res;
        my ($premature, @results) = run_tests sub {
            $match_res = $checker -> match ($subject, $captures);
        };

        check results   => \@results,
              premature => $premature,
              expected  => $expected,
              match     =>  1,
              match_res => $match_res,
              pattern   => $pattern,
              subject   => $subject,
              comment   => 'US president'
        ;
    }
}

__END__
