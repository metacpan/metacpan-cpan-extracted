#!/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Data::Dumper;
use v5.14;

use Textoola::PatternStatComparator;

BEGIN { use_ok( 'Textoola::PatternStatComparator' ); }

subtest "Compare" => sub {
    my $s1={
       "a" => 1,
       "b" => 2,
       "c" => 3,
       "d" => 4,
       "e" => 4,
    };
    my $s2={
       "a" => 0,
       "b" => 2,
       "c" => 6,
       "d" => 2,
       "e" => 5,
       "f" => 1,
    };

    my $p=new Textoola::PatternStatComparator(
	patternstats1 => $s1,
	patternstats2 => $s2,
	);
    my $r=$p->compare();
#    say Dumper($r);
    is_deeply(
	$r,{
          'e' => '0.25',
          'c' => '1',
          'a' => '-1',
          'd' => '-0.5',
	  'f' => '*',
        },
	"Compare and get various tendencies");
};

subtest "Compare" => sub {
    my $s1={
       "a" => 2,
       "a b" => 2,
       "a b c" => 2,
       "A" => 2,
       "A B" => 2,
       "A B C" => 1,
    };
    my $s2={
       "a" => 2,
       "a b" => 2,
       "a b c" => 1,
       "a b d" => 1,
       "A" => 2,
       "A B" => 2,
       "A B C" => 2,
    };

    my $p=new Textoola::PatternStatComparator(
	patternstats1 => $s1,
	patternstats2 => $s2,
	);
    my $r=$p->compare_reduce();
#    say Dumper($r);
    is_deeply(
	$r,{
          'a b c' => '-0.5',
          'A B C' => '1',
          'a b d' => '*',
        },
	"Compare and get various tendencies");
};

done_testing;
