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
Thing ${1:one} and Thing ${2:two}
====
-|-
====
Thing one and Thing two
====
use defaults only
--------
Thing ${2:one} and Thing $1
====
A|B
====
Thing B and Thing A
====
override default
--------
Hey, Ho, the ${1:}
====
-
====
Hey, Ho, the 
====
missing default and no replacement yields zero-length replacement
--------
Hey, Ho, the [${1: }]
====
-
====
Hey, Ho, the [ ]
====
whitespace default
