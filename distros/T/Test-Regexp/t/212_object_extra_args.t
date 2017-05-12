#!/usr/bin/perl

use strict;
use warnings;
no  warnings 'syntax';

use 5.010;

use lib ".";

use Test::Tester;
use Test::Regexp import => [];
use t::Common;

my $pattern = '\w+';

my $checker = Test::Regexp:: -> new -> init (
    pattern => $pattern,
    name    => "test",
);

my @fails = (["----"     => "dashes",],
             ["# foo"    => "comment"],
             ["foo\nbar" => "has a newline"]);

my $c = 0;
foreach my $fail (@fails) {
    my ($subject, $Reason) = @$fail;

    my $match_res;
    my ($premature, @results) = run_tests sub {
        $match_res = $checker -> no_match ($subject, reason => $Reason);
    };

    check results   => \@results,
          premature => $premature,
          expected  => 'P',
          match     =>  0,
          match_res => $match_res,
          pattern   => $pattern,
          subject   => $subject,
          reason    => $Reason,
          comment   => "test",
    ;
}

__END__
