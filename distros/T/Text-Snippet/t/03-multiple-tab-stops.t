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
		shift(@ts)->replace($r);
	}
	is($s->to_string, $t->[2], $t->[3] || "parsed $t->[0] correctly");
}

__DATA__
Thing $1 and Thing $2
====
one|two
====
Thing one and Thing two
--------
Thing $2 and Thing $1
====
one|two
====
Thing two and Thing one
--------
Good $1, good $5, and good $149283
====
afternoon|evening|night
====
Good afternoon, good evening, and good night
--------
Good $1, good $50, and good $7
====
afternoon|evening|night
====
Good afternoon, good night, and good evening
