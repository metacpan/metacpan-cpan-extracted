#!/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Data::Dumper;
use v5.14;

use Textoola::PatternStatParser;

BEGIN { use_ok( 'Textoola::PatternStatParser' ); }

subtest "parse_line" => sub {
    my $p=new Textoola::PatternStatParser();
    $p->parse_line("a b c");
    is_deeply(
	$p->patternstats(),{
	    'a b c' => 1,
	    'a' => 1,
	    'a b' => 1
        },
	"Divide the line and aggregate tokens 1. time"
	);

    $p->parse_line("a b d");
    is_deeply(
	$p->patternstats(),{
          'a b c' => 1,
          'a' => 2,
          'a b' => 2,
          'a b d' => 1
        },
	"Divide the line and aggregate tokens 2. time"
	);
    say Dumper($p->patternstats());
};

subtest "parse" => sub {
    my $t="a b c";
    my $p=new Textoola::PatternStatParser(path=>\$t);
    $p->parse();
    is_deeply(
	$p->patternstats(),{
	    'a b c' => 1,
	    'a' => 1,
	    'a b' => 1
        },
	"Divide the line and aggregate tokens 1. time"
	);
};

done_testing();
