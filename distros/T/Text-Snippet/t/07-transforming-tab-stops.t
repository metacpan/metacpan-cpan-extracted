use strict;
use warnings;
use Test::More;
use Data::Dumper;

my @tests = map {
	[ map { chomp; $_ } split( /\n====\n/, $_ ) ]
} split( /\n--------\n/, join( '', grep {!/^#/} <DATA> ) );

plan(tests => @tests + 2);
use_ok('Text::Snippet');

my $s = Text::Snippet->parse('${1/(.+)/\u$1/}');
isa_ok($s->tab_stops->[0], 'Text::Snippet::TabStop::WithTransformer');

foreach my $t(@tests){
	my $s = Text::Snippet->parse($t->[0]);
	my @ts = @{ $s->tab_stops };
	foreach my $r( split(/\|/, $t->[1]) ){
		shift(@ts)->replace($r) unless $r eq '-';
	}
	is($s, $t->[2], $t->[3] || "parsed $t->[0] correctly") or diag Dumper $s;
}

__DATA__
I $1 it, I ${1/(.+)/\U$1\E/} it!
====
love
====
I love it, I LOVE it!
====
mirrored uppercased
--------
I $1 it, I ${1/(.)(.)/\u$1$2/} it!
====
love
====
I love it, I LoVe it!
--------
I $1 it, I ${1/(.)/\{$1/} it!
====
love
====
I love it, I {l{o{v{e it!
====
bracketed
--------
Hello ${1/.+/\U$0/}
====
there
====
Hello THERE
--------
<${1:a}>Text</${1/\s.*//}>
====
a href="http://www.google.com"
====
<a href="http://www.google.com">Text</a>
====
wrap HTML tag
