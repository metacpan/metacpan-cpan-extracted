#!/usr/bin/perl

use strict;
use warnings;
no  warnings 'syntax';

use 5.010;

use lib ".";

use Test::Tester;
use Test::Regexp import => [];
use t::Common;

my $pattern2 = '(\w+)\s+(\w+)';
my $pattern3 = '(\w+)\s+(\w+)\s+(\w+)';

my $checker2 = Test::Regexp -> new -> init (
    keep_pattern => $pattern2,
);
my $checker3 = Test::Regexp -> new -> init (
    keep_pattern => $pattern3,
);

my @data = (
    ['PFSSSSS',  'PPPPPPP',  [qw [tripoline a punta]]],
    ['PPPPPP',   'FSSSSS',   [qw [cannarozzi rigati]]],
    ['PPPPPP',   'FSSSSS',   [qw [lumache grandi]]],
    ['PFSSSSSS', 'PFSSSSSS', [qw [lasagne festonate a nidi]]],
    ['PFSSSSS',  'PPPPPPP',  [qw [corni di bue]]],
);

foreach my $data (@data) {
    my $expected2 = shift @$data;
    my $expected3 = shift @$data;
    my $captures  = shift @$data;
    my $subject   = join ' ' => @$captures;

    my $match_res;
    my ($premature, @results) = run_tests sub {
        $match_res = $checker2 -> match ($subject, $captures)
    };

    check results   => \@results,
          premature => $premature,
          expected  => $expected2,
          match     =>  1,
          match_res => $match_res,
          pattern   => $pattern2,
          subject   => $subject,
          captures  => $captures,
          keep      =>  1,
    ;

   ($premature, @results) = run_tests sub {
        $match_res = $checker3 -> match ($subject, $captures)
    };

    check results   => \@results,
          premature => $premature,
          expected  => $expected3,
          match     =>  1,
          match_res => $match_res,
          pattern   => $pattern3,
          subject   => $subject,
          captures  => $captures,
          keep      =>  1,
    ;

}

__END__
