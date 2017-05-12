#!/usr/bin/perl

use strict;
use warnings;
no  warnings 'syntax';

use 5.010;

use lib ".";

use Test::Tester;
use Test::Regexp import => [];
use t::Common;


while (<DATA>) {
    state $c = 0;
    $c ++;
    chomp;
    m {^\h* (?|"(?<subject>[^"]*)"|(?<subject>\S+))
        \h+ (?|/(?<pattern>[^/]*)/|(?<pattern>\S+))
        \h+ (?<match>(?i:[ymn01]))
        \h+ (?<result>[PFS]+)
        \h* (?:$|\#)}x or next;
    my ($subject, $pattern, $match, $expected) =
        @+ {qw [subject pattern match result]};

    my $match_val = $match =~ /[ym1]/i;

    my $checker = Test::Regexp:: -> new -> init (
        pattern =>  $pattern,
        name    => "Name: $c",
    );

    Test::More::is $checker -> name, "Name: $c", "Object has a name";

    my $match_res;
    my $method = $match_val ? "match" : "no_match";
    my ($premature, @results) = run_tests sub {
        $match_res = $checker -> $method ($subject)
    };

    check results   => \@results,
          premature =>  $premature,
          expected  =>  $expected,
          match     =>  $match_val,
          match_res =>  $match_res,
          pattern   =>  $pattern,
          subject   =>  $subject,
          comment   => "Name: $c",
    ;

}


#
# Names in the __DATA__ section come from 'meta norse_mythology'.
#

__DATA__
Dagr          ....       y   PPPP
Kvasir        Kvasir     y   PPPP
Snotra        \w+        y   PPPP
Sjofn         \w+        n   F     # It matches, so a no_match should fail
Borr          Bo         y   PFSS  # Match is only partial
Magni         Sigyn      y   FSSS  # Fail, then a skip
Andhrimnir    Delling    n   P     # Doesn't match, so a pass
Hlin          .(.)..     y   PPFP  # Sets a capture, so should fail
Od            (?<l>.*)   y   PPFF  # Sets a capture, so should fail
