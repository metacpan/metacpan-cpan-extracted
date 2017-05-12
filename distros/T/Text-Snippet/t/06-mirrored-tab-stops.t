use strict;
use warnings;
use Test::More;
use Data::Dumper;

my @tests = map {
	[ map { chomp; $_ } split( /\n====\n/, $_ ) ]
} split( /\n--------\n/, join( '', grep {!/^#/} <DATA> ) );

plan(tests => @tests + 1);
use_ok('Text::Snippet');

foreach my $t(@tests){
	my $s = Text::Snippet->parse($t->[0]);
	my @ts = @{ $s->tab_stops };
	foreach my $r( split(/\|/, $t->[1]) ){
		shift(@ts)->replace($r) unless $r eq '-';
	}
	is($s->to_string, $t->[2], $t->[3] || "parsed $t->[0] correctly");
}

__DATA__
I $1 it, I $1 it!
====
love
====
I love it, I love it!
====
mirrored simple tab stop
--------
I ${1:hate} it, I $1 it!
====
-
====
I hate it, I hate it!
====
mirrored tab stop with default carries over
--------
I $1 it, I ${1:love} it!
====
got
====
I got it, I got it!
====
mirrored tab stop with one default (secondary is ignored)
--------
I ${1:love} it, I ${1:hate} it!
====
-
====
I love it, I love it!
====
mirrored tab stop with two defaults (secondary is ignored)
