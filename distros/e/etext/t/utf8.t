#!/usr/bin/perl
# Character (UTF-8) indices: the widget must count characters, not bytes,
# exactly like Tk::Text does; and it must keep doing so inside blocks.
use strict;
use warnings;
use utf8;
use Test::More;

BEGIN {
  eval { require Tk; 1 } or plan skip_all => "Tk not available: $@";
}
use Tk::eText;

my $mw = eval { MainWindow->new };
plan skip_all => "no X display available ($@)" unless $mw;
plan tests => 35;
$mw->geometry('+10+10');

binmode(Test::More->builder->$_, ':utf8') for qw(output failure_output);

# Text with 2-, 3- and 4-byte characters.
my @lines = ("abc d\x{e9}f gh\x{20ac}i\n",
	     "\x{65e5}\x{672c}\x{8a9e} text \x{1F600} end\n",
	     "plain ascii line\n",
	     "\x{c9}cole \x{e9}t\x{e9} \x{c9}T\x{c9}\n");

sub make {
  my ($class) = @_;
  my $w = $mw->$class(-width => 30, -height => 8, -wrap => 'none')->pack;
  $w->tagConfigure('t', -foreground => 'blue');
  $w->insert('end', $lines[0]);
  $w->insert('end', $lines[1], 't');
  $w->insert('end', $lines[2] . $lines[3]);
  $w->tagAdd('u', '1.5', '2.3');
  $w->markSet('m', '2.4');
  $w->markSet('insert', '4.2');
  $mw->update;
  return $w;
}
my $ref = make('Text');		# the reference: Tk's own text widget
my $w   = make('eText');

# 1. The same things, asked of both widgets at every position.
my (%bad, $queries);
sub cmp_both {
  my ($what, $method, @args) = @_;
  my @r = eval { $ref->$method(@args) };
  my @e = eval { $w->$method(@args) };
  $queries++;
  no warnings 'uninitialized';
  if ("@r" ne "@e") {
    $bad{$what}++;
    diag("$what: $method(@args): Text says [@r], eText says [@e]")
      if $bad{$what} <= 3;
  }
}
for my $l (1 .. 4) {
  (my $n = $ref->index("$l.0 lineend")) =~ s/.*\.//;
  for my $c (0 .. $n + 2) {
    my $i = "$l.$c";
    cmp_both('index', 'index', $i);
    cmp_both('modifiers', 'index', "$i $_")
      for ('+1c', '+2c', '+5c', '-1c', '-3c', '+12c', '-12c', 'lineend',
	   'linestart', 'wordstart', 'wordend', '+1c wordend', '-1c wordstart');
    cmp_both('get', 'get', $i);
    cmp_both('get range', 'get', $i, "$i +3c");
    cmp_both('compare', 'compare', $i, '<', '2.4');
    cmp_both('tag names', 'tagNames', $i);
    cmp_both('bbox', 'bbox', $i) if $l <= 2;
  }
}
is($bad{index} || 0, 0, 'index: "line.char" parses and prints like Tk::Text');
is($bad{modifiers} || 0, 0, '+Nc, -Nc, line/word start/end like Tk::Text');
# "+N lines" keeps the character position; Tk keeps the byte offset
# (TK_BUGS.md A5), so this is not compared with Tk::Text.
is($w->index('1.5 +1 lines'), '2.5', '+1 lines keeps the character position (Tk::Text: ' . $ref->index('1.5 +1 lines') . ')');
is($w->index('2.5 -1 lines'), '1.5', '-1 lines keeps the character position');
is($bad{get} || 0, 0, 'get of single characters like Tk::Text');
is($bad{'get range'} || 0, 0, 'get of ranges like Tk::Text');
is($bad{compare} || 0, 0, 'compare like Tk::Text');
is($bad{'tag names'} || 0, 0, 'tag names at character positions like Tk::Text');
is($bad{bbox} || 0, 0, 'bbox of characters like Tk::Text');
cmp_both('ranges', 'tagRanges', 'u');
cmp_both('ranges', 'tagRanges', 't');
cmp_both('ranges', 'index', 'm');
cmp_both('ranges', 'index', 'insert');
cmp_both('ranges', 'index', 'end');
is($bad{ranges} || 0, 0, 'tag ranges and marks like Tk::Text');

# Searches: exact and regexp, both directions, with -nocase, with -count.
for my $pat ("\x{e9}", "\x{c9}", "\x{c9}T", 'text', 'e.d', "\x{20ac}i",
	     "[\x{65e5}\x{672c}]+", "\x{c9}COLE", 'ab', 'line$', "\x{1F600} e") {
  for my $dir ('-forwards', '-backwards') {
    for my $kind ('-exact', '-regexp') {
      for my $case ((), '-nocase') {
	for my $from ('1.0', 'end', '2.5') {
	  my ($cr, $ce) = (-1, -1);
	  my @r = $ref->search($dir, $kind, $case, -count => \$cr, '--', $pat, $from);
	  my @e = $w->search($dir, $kind, $case, -count => \$ce, '--', $pat, $from);
	  $queries++;
	  no warnings 'uninitialized';
	  if ("@r/$cr" ne "@e/$ce") {
	    $bad{search}++;
	    diag("search $dir $kind $case '$pat' $from: Text [@r/$cr], eText [@e/$ce]")
	      if $bad{search} <= 5;
	  }
	}
      }
    }
  }
}
is($bad{search} || 0, 0, 'search results and -count like Tk::Text');

# @x,y never lands inside a character, and agrees with Tk::Text.
{
  my @b = $ref->bbox('1.0');
  for my $y ($b[1] + 2, $b[1] + $b[3] + 2) {
    for (my $x = 0; $x < 220; $x += 3) {
      cmp_both('pixel', 'index', "\@$x,$y");
    }
  }
  is($bad{pixel} || 0, 0, '@x,y like Tk::Text');
}

# dump reports character positions.
{
  my @r = $ref->dump('-all', '1.0', 'end');
  my @e = $w->dump('-all', '1.0', 'end');
  is_deeply(\@e, \@r, 'dump like Tk::Text');
}
cmp_ok($queries, '>', 1000, "that was $queries comparisons");
$ref->destroy;
$w->destroy;

# 2. Characters inside blocks.
$w = $mw->eText(-width => 30, -height => 8)->pack;
$w->blockConfigure('Std');
$w->insert('end', "abc d\x{e9}fg hij\n");
$w->blockInsert('Std', '1.4', '1.8');
$mw->update;
# Positions: 1.4 is the start of the block (its dummy position), 1.5 'd',
# 1.6 'é', 1.7 'f', 1.8 'g', 1.9 the newline of the internal line, then
# 1.10 ' ', 1.11 'h' ...
is($w->get('1.0', 'end'), "abc {d\x{e9}fg} hij\n\n", 'block with a multi-byte character inside');
is($w->get('1.6'), "\x{e9}", 'get of the character inside the block');
is($w->get('1.5', '1.8'), "d\x{e9}f", 'get of a range inside the block');
is($w->index('1.6'), '1.6', 'index inside the block round-trips');
is($w->index('1.6 +1c'), '1.7', '+1c after a multi-byte character in a block');
is($w->index('1.7 -1c'), '1.6', '-1c onto a multi-byte character in a block');
is($w->index('1.3 +3c'), '1.6', '+3c across the block start');
is($w->index('1.11 -5c'), '1.6', '-5c across the block end');
is($w->index('1.0 lineend'), '1.14', 'lineend counts the block in characters');
my @of = $w->blockOf('1.6');
is("$of[0] $of[1]", '1.4 6', 'block of: start and length in characters');
is_deeply($of[4], [4], 'block of: leaf length in characters');
my @walk;
my $i = '1.0';
for (1 .. 16) { push @walk, $i; $i = $w->index("$i +1c") }
is(join(' ', @walk), join(' ', map { "1.$_" } 0 .. 14) . ' 2.0',
   '+1c walks every character position once');
my @back;
$i = '2.0';
for (1 .. 16) { push @back, $i; $i = $w->index("$i -1c") }
is(join(' ', reverse @back), join(' ', map { "1.$_" } 0 .. 14) . ' 2.0',
   '-1c walks back over every character position');
$w->markSet('insert', '1.6');
is($w->index('insert'), '1.6', 'mark inside a block at a character position');
my $cnt = 0;
is($w->search(-count => \$cnt, "\x{e9}f", '1.0'), '1.6', 'search finds a match inside the block');
is($cnt, 2, 'search -count inside the block counts characters');
my @dump = $w->dump('-all', '1.0', 'end');
my $roundtrip = 0;
while (@dump) {
  my ($key, $value, $index) = splice @dump, 0, 3;
  $roundtrip++ if $w->index($index) ne $index;
}
is($roundtrip, 0, 'dump indices round-trip');

# Nested blocks and 4-byte characters.
$w->blockInsert('Std', '1.6', '1.8');
$w->insert('1.1', "\x{1F600}");
$mw->update;
is($w->get('1.0', 'end'), "a\x{1F600}bc {d{\x{e9}f}g} hij\n\n", 'nested block, 4-byte character');
my $monotonic = 1;
my $prev = '1.0';
for my $c (1 .. 20) {
  my $cur = $w->index("1.$c");
  $monotonic = 0 unless $w->compare($cur, '>=', $prev);
  $monotonic = 0 if $c <= 17 && $cur ne "1.$c";
  $prev = $cur;
}
ok($monotonic, 'every character position of a line with nested blocks is addressable');
$w->destroy;

# A block with two leaves: the leaf separator takes one position too.
$w = $mw->eText(-width => 30, -height => 8)->pack;
$w->blockConfigure('Std');
$w->insert('end', "abc d\x{e9}fg hij\n");
$w->blockInsert('Std', '1.4', '1.8');
$w->blockSplit('1.7', 0);
$mw->update;
is($w->get('1.0', 'end'), "abc {d\x{e9}|fg} hij\n\n", 'block split after a multi-byte character');
is($w->search(-count => \$cnt, 'fg', '1.0') . " $cnt", '1.8 2', 'search finds a match in the second leaf');
$w->destroy;
$mw->destroy;
