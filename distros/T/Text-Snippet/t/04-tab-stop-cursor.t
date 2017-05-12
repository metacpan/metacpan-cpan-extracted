use strict;
use warnings;
use Test::More;
use Data::Dumper;

my @tests = map {
	[ map { chomp; $_ } split( /\n====\n/, $_ ) ]
} split( /\n--------\n/, join( '', grep {!/^#/} <DATA> ) );

plan(tests => (@tests * 2) + 18);
use_ok('Text::Snippet::TabStop::Cursor');
use_ok('Text::Snippet');

foreach my $t(@tests){
	my $s = Text::Snippet->parse($t->[0]);
	my $c = $s->cursor;
	my @values = split(/\|/, $t->[1]);
	while($c->has_next){
		my $ts = $c->next;
		$ts->replace(shift(@values)) if(@values);
	}
	is($c->is_terminal, 1, 'is_terminal == true on last tab stop');
	is($s->to_string, $t->[2], "parsed $t->[0] correctly");
}

my $s = Text::Snippet->parse("1. \$1\n2. \$1\$2\n3. \$1\$2\$3");
my $c = $s->cursor;

is_deeply($c->current_position, [0,0], 'starts at 0,0');
is($c->current_char_position, 0, 'char starts at 0');

$c->next;
is_deeply($c->current_position, [0,3], 'first tab-stop at 0,3');
is($c->current_char_position, 3, 'first char tab-stop at 3');

$c->next;
is_deeply($c->current_position, [1,3], 'second tab-stop at 1,3');
is($c->current_char_position, 7, 'second char tab-stop at 7');

$c->next;
is_deeply($c->current_position, [2,3], 'third tab-stop at 2,3');
is($c->current_char_position, 11, 'third char tab-stop at 11') or diag Dumper $c;

$c->prev->replace('Foo');
$c->next;
is_deeply($c->current_position, [2,6], 'after modifying $2, third tab-stop at 2,6');
is($c->current_char_position, 17, '11 + (3 * 2) == 17') or diag Dumper $c;

$c->prev; $c->prev->replace('Blah');
$c->next; $c->next;
is_deeply($c->current_position, [2,10], 'after modifying $1 and $2, third tab-stop at 2,10');
is($c->current_char_position, 29, '11 + (3 * 2) + (4 * 3) == 29') or diag Dumper $c;

$c->prev;
is_deeply($c->current_position, [1,7], 'after modifying $1 and $2, second tab-stop at 1,7');
is($c->current_char_position, 15, '7 + (4 * 2) == 15') or diag Dumper $c;

$c->prev;
is_deeply($c->current_position, [0,3], 'after modifying $1, first tab-stop at 0,3');
is($c->current_char_position, 3, 'original tab-stop unmoved') or diag Dumper $c;


__DATA__
Thing ${1} and Thing $2
====
one|two
====
Thing one and Thing two
--------
Thing ${2} and Thing $1
====
one|two
====
Thing two and Thing one
