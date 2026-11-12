#!/usr/bin/perl
# block flatten (decisions F1-F4, O1, O2, U1-U3, O5) and blocks that are
# a single leaf: "block flatten index level" joins every separator
# inside the node "level" real levels above the leaf of index, pulls
# out the nodes where the depths differ (the recipe of RAGGED-ATOMIC.md
# 4.2), then pulls out the node itself; at the root the block becomes
# a single leaf.  The shape ("block at"), the values, the return value,
# the exact undo and redo, what -valuecommand is told, and every
# command on a block that is a single leaf.  All with "debug" on: the
# B-tree check (padding rules included) runs after every change and
# panics on an inconsistency.
#
# The tree of a block is written R( a | N( b | c ) ): the root R, a leaf
# a, a node N with the leaves b and c.  "block at" gives it as nested
# lists of leaf lengths: [1, [1, 1]]; a block that is a single leaf as
# one number.
use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require Tk; 1 } or plan skip_all => "Tk not available: $@";
}
use Tk::eText;

my $mw = eval { MainWindow->new };
plan skip_all => "no X display available ($@)" unless $mw;
plan tests => 165;
$mw->geometry('+10+10');

my @events;
my $t = $mw->eText(-undo => 1, -autoseparators => 1, -width => 40,
		   -height => 8)->pack;
$t->blockConfigure('F');
$t->blockConfigure('G');
$t->debug(1);
sub wh { '[' . join(' ', map { ref $_ ? wh($_) : $_ } @{$_[0]}) . ']' }
$t->configure(-valuecommand => sub {
  my ($w, $event, $kind, $where, $value, $cause) = @_;
  push @events, join ' ', $event, $kind, wh($where), $value // 'undef', $cause;
});

# The structure of the block whose head is at an index ("block at").
sub at { my @r = $t->blockAt($_[0] // '2.0'); $r[4] }
sub text { $t->get('2.0', '2.end') }
sub nd { my $v = eval { $t->blockNodedata(@_) }; $@ ? 'ERR' : $v }
sub fl { my $r = eval { $t->blockFlatten(@_) }; defined $r ? $r : "ERR $@" }

# The block on line 2 as "block list" gives it, marks left out and
# adjacent strings joined: separators with their depths ("|[d,e]" for
# the pair [depth, defect] before a padded leaf), the header with the
# node values.
sub blist {
  my $walk;
  $walk = sub {
    my @o;
    for my $e (@_) {
      next if ref($e) =~ /Mark/;
      if (ref($e) =~ /::String$/) {
	if (@o && !ref $o[-1]) { $o[-1] .= $$e } else { push @o, $$e }
      } elsif (ref($e) =~ /BlockSeparator/) {
	my ($d, $defect) = UNIVERSAL::isa($e, 'ARRAY') ? @$e : ($$e, 0);
	push @o, $defect ? \('|[' . ($d // 'u') . ",$defect]") : \"|$d";
      } elsif (ref($e) =~ /::Block$/) {
	push @o, [ $e->[0], $walk->(@$e[1 .. $#$e]) ];
      } else {
	push @o, $e;
      }
    }
    @o;
  };
  [ $walk->($t->blockList('2.0', '2.end')) ];
}
sub sep { @_ > 1 ? \('|[' . ($_[0] // 'u') . ",$_[1]]") : \"|$_[0]" }

sub setup {
  $t->delete('1.0', 'end');
  $t->insert('1.0', shift);
  $t->blockInsert('F', @_);
  $t->editReset;
  @events = ();
}
# Line 2 holds the fraction {num|den}: head 2.0, num 2.1-2.3, the
# separator 2.4, den 2.5-2.7, the tail 2.8.
sub fraction { setup("x\nnum\nden\ny\n", '2.0', '3.3') }

# The change, then its undo and its redo: the change's result, the shape
# and the block list (with the node values) after it, what -valuecommand
# is told, and the exactness of the undo and of the redo (5 tests).
sub exact {
  my ($name, $change, $result, $shape, $list, $told) = @_;
  $t->editSeparator;
  my $s0 = [blist(), at()];
  @events = ();
  my $r = $change->();
  my $s1 = [blist(), at()];
  is($r, $result, "$name: returns $result");
  is_deeply([$s1->[1], $s1->[0]], [$shape, [$list]], "$name: shape and list after");
  is_deeply([@events], $told, "$name: what -valuecommand is told") if defined $told;
  @events = ();
  $t->editUndo;
  is_deeply([blist(), at()], $s0, "$name: the undo is exact");
  $t->editRedo;
  is_deeply([blist(), at()], $s1, "$name: the redo is exact");
  @events = ();
}

# ---------------------------------------------------------------------
# The owner's examples (F1, O2): {num|den}, sprout 2.2 2.5 gives
# R( n | N( um ) | den ); flatten 2.3 1 gives R( n | um | den ) (N is
# pulled out: no separator removed); flatten 2.3 -1 makes the whole
# block the single leaf numden (two separators removed).

fraction();
$t->blockSprout('2.2', '2.5');
is_deeply(at(), [1, [2], 3], 'R( n | N( um ) | den )');
exact('flatten 2.3 1', sub { $t->blockFlatten('2.3', 1) }, 0,
      [1, 2, 3], [['F', 0], 'n', sep(0), 'um', sep(0), 'den'], []);
is(text(), '{n|um|den}', 'the text is unchanged');
$t->editUndo;
exact('flatten 2.3 -1', sub { $t->blockFlatten('2.3', -1) }, 2,
      6, [['F', -1], 'numden'], []);
is(text(), '{numden}', 'the separators are gone');

# Level 0 (the leaf itself): a no-op, not recorded for undo.
fraction();
$t->insert('2.1', 'q');
is(fl('2.2', 0), 0, 'level 0 returns 0');
is_deeply(at(), [4, 3], 'and changes nothing');
$t->editUndo;
is(text(), '{num|den}', 'the undo takes back the change before it');

# Levels beyond this leaf's root: an error worded as nodedata's (F2).
fraction();
$t->blockSprout('2.2', '2.5');
like(fl('2.1', 2), qr/^ERR bad level "2": the block containing 2\.1 has 1 level above this leaf/,
     'n has 1 level above it');
like(fl('2.3', 3), qr/^ERR bad level "3": the block containing 2\.3 has 2 levels above this leaf/,
     'um has 2');
like(fl('2.3', -4), qr/^ERR bad level "-4"/, 'negative levels are bounded too');
is(fl('2.3', -3), 0, '-3 is the leaf um itself: a no-op');
like(fl('1.0', 1), qr/^ERR bad index "1\.0": not inside a block/, 'outside blocks');
ok(!eval { $t->blockFlatten('2.1'); 1 }, 'the level is needed');
is_deeply(at(), [1, [2], 3], 'nothing changed');
# Negative levels: -2 is N for um.
is(fl('2.3', -2), 0, 'flatten 2.3 -2 is flatten 2.3 1');
is_deeply(at(), [1, 2, 3], 'R( n | um | den )');

# ---------------------------------------------------------------------
# The recipe on N( A( B( a ) ) | C( c ) | D( E( d ) ) ) (here N is the
# root R): repeat until the node's only child is a leaf: JOIN the
# rightmost separator whose two leaves are equally deep below their
# common ancestor; else PULL OUT the deepest node with a single child
# that is a leaf, the rightmost among equally deep ones; then PULL OUT
# the node itself.  So: PULL OUT E, JOIN c|d, PULL OUT B, JOIN a|cd,
# PULL OUT A, PULL OUT R.  The values (U1, U2) and the events show the
# order: a PULL OUT gives the node's value to the leaf (its own goes),
# a JOIN keeps the start side's.

sub recipe {
  setup("x\na\nc\nd\ny\n", '2.0', '4.1');	# {a|c|d}
  $t->blockSprout('2.0', '2.3');		# B( a )
  $t->blockSprout('2.0', '2.3');		# A( B( a ) )
  $t->blockSprout('2.2', '2.5');		# C( c )
  $t->blockSprout('2.4', '2.7');		# E( d )
  $t->blockSprout('2.4', '2.7');		# D( E( d ) )
  $t->editReset;
}
recipe();
is_deeply(at(), [[[1]], [1], [[1]]], 'R( A( B( a ) ) | C( c ) | D( E( d ) ) )');
my %place = (a => ['2.1', 0], B => ['2.1', 1], A => ['2.1', 2], c => ['2.3', 0],
	     C => ['2.3', 1], d => ['2.5', 0], E => ['2.5', 1], D => ['2.5', 2],
	     R => ['2.1', -1]);
$t->blockNodedata(@{$place{$_}}, $_) for sort keys %place;
@events = ();
exact('the recipe at the root', sub { $t->blockFlatten('2.1', -1) }, 2,
      3, [['F', -1, undef, ['R']], 'acd'],
      ['stash node [2.5 0] d block flatten',		# PULL OUT E
       'move node [2.5 1 [2.5 0]] E block flatten',
       'move node [2.5 2 [2.5 1]] D block flatten',
       'stash node [2.5 0] E block flatten',		# JOIN c|d
       'stash node [2.5 1] D block flatten',
       'stash node [2.1 0] a block flatten',		# PULL OUT B
       'move node [2.1 1 [2.1 0]] B block flatten',
       'move node [2.1 2 [2.1 1]] A block flatten',
       'move node [2.1 3 [2.1 2]] R block flatten',
       'stash node [2.3 0] c block flatten',		# JOIN a|cd
       'stash node [2.3 1] C block flatten',
       'stash node [2.1 0] B block flatten',		# PULL OUT A
       'move node [2.1 1 [2.1 0]] A block flatten',
       'move node [2.1 2 [2.1 1]] R block flatten',
       'stash node [2.1 0] A block flatten',		# PULL OUT R
       'move node [2.1 1 [2.1 0]] R block flatten']);

# With -undo off the values that go are told "drop".
recipe();
$t->blockNodedata(@{$place{$_}}, $_) for qw(c C d E);
$t->configure(-undo => 0);
@events = ();
is(fl('2.5', -1), 2, '-undo off: the root flattened');
is_deeply([@events], ['drop node [2.5 0] d block flatten',
		      'move node [2.5 1 [2.5 0]] E block flatten',
		      'drop node [2.5 0] E block flatten',
		      'move node [2.3 0 [2.1 0]] c block flatten',
		      'move node [2.3 1 [2.1 1]] C block flatten',
		      'drop node [2.1 0] c block flatten',
		      'move node [2.1 1 [2.1 0]] C block flatten'],
	  'what -valuecommand is told');
is_deeply([at(), nd('2.1', 0)], [3, 'C'], 'a single leaf with C\'s value');
$t->configure(-undo => 1);

# Without values on the nodes the leaves' values show the joins: the
# start side keeps its value; a PULL OUT of a node without a value lets
# the leaf keep its own.
recipe();
$t->blockNodedata('2.3', 0, 'c');
$t->blockNodedata('2.5', 0, 'd');
$t->blockNodedata('2.5', 1, 'E');
exact('leaf values', sub { $t->blockFlatten('2.1', -1) }, 2,
      3, [['F', -1, undef, ['c']], 'acd']);

# Lower levels: flatten D (2.5 2): PULL OUT E, then D itself.
recipe();
exact('flatten D', sub { $t->blockFlatten('2.5', 2) }, 0,
      [[[1]], [1], 1], [['F', 2], 'a', sep(2, 1), 'c', sep(2, 2), 'd']);
# A (2.1 -2): PULL OUT B, then A.
recipe();
exact('flatten A', sub { $t->blockFlatten('2.1', -2) }, 0,
      [1, [1], [[1]]], [['F', 2], sep(undef, 2), 'a', sep(2, 1), 'c', sep(2), 'd']);

# The same tree below a node N of the root: R( x | N( ... ) ).
setup("x\nx\nacd\ny\n", '2.0', '3.3');		# {x|acd}
$t->blockSprout('2.2', '2.7');		# R( x | N( acd ) )
$t->blockSplit('2.4', 0);
$t->blockSplit('2.6', 0);		# N( a | c | d )
$t->blockSprout('2.2', '2.5');
$t->blockSprout('2.2', '2.5');
$t->blockSprout('2.4', '2.7');
$t->blockSprout('2.6', '2.9');
$t->blockSprout('2.6', '2.9');
is_deeply(at(), [1, [[[1]], [1], [[1]]]], 'R( x | N( A( B( a ) ) | C( c ) | D( E( d ) ) ) )');
$t->blockNodedata('2.3', -2, 'N');
$t->blockNodedata('2.5', 0, 'c');
exact('flatten N below the root', sub { $t->blockFlatten('2.3', -2) }, 2,
      [1, 3], [['F', 0, undef, [undef, [undef], ['N']]], 'x', sep(0), 'acd']);

# Other shapes.  R( a | N( b | c ) ): JOIN b|c, PULL OUT N, JOIN a|bc.
setup("x\na\nbc\ny\n", '2.0', '3.2');	# {a|bc}
$t->blockSprout('2.2', '2.6');		# R( a | N( bc ) )
$t->blockSplit('2.4', 0);		# R( a | N( b | c ) )
is_deeply(at(), [1, [1, 1]], 'R( a | N( b | c ) )');
$t->blockNodedata('2.3', 1, 'N');
$t->blockNodedata('2.1', 0, 'A');
$t->blockNodedata('2.5', 0, 'C');
exact('R( a | N( b | c ) ) at the root', sub { $t->blockFlatten('2.1', 1) }, 2,
      3, [['F', -1, undef, ['A']], 'abc'],
      ['move node [2.5 0 [2.3 0]] C block flatten',	# JOIN b|c
       'stash node [2.3 0] C block flatten',		# PULL OUT N
       'move node [2.3 1 [2.3 0]] N block flatten',
       'stash node [2.3 0] N block flatten']);		# JOIN a|bc
# A uniform tree: R( A( a | b ) | B( c | d ) ) flattened at A: JOIN.
setup("x\nabcd\ny\n", '2.0', '2.4');	# {abcd}
$t->blockSplit('2.3', 1);			# R( A( ab ) | B( cd ) )
$t->blockSplit('2.2', 0);
$t->blockSplit('2.6', 0);			# {a|b|c|d}, R( A( a | b ) | B( c | d ) )
is_deeply(at(), [[1, 1], [1, 1]], 'R( A( a | b ) | B( c | d ) )');
exact('A( a | b ) flattened', sub { $t->blockFlatten('2.1', 1) }, 1,
      [2, [1, 1]], [['F', 1], sep(undef, 1), 'ab', sep(1), 'c', sep(0), 'd']);
exact('then the root', sub { $t->blockFlatten('2.1', -1) }, 2,
      4, [['F', -1], 'abcd']);

# Nested blocks inside the flattened text are kept (F3).
setup("x\nab\ncd\ny\n", '2.0', '3.2');	# {ab|cd}
$t->blockInsert('G', '2.2', '2.2');
$t->insert('2.3', 'uv');
$t->blockSplit('2.4', 0);			# {a{u|v}b|cd}
is(text(), '{a{u|v}b|cd}', 'a nested block in the first leaf');
my $nested = [['G', 0], 'u', sep(0), 'v'];
exact('flatten around a nested block', sub { $t->blockFlatten('2.1', -1) }, 1,
      9, [['F', -1], 'a', $nested, 'bcd']);
is_deeply(at('2.2'), [1, 1], 'the nested block is as it was');
# The innermost block: flatten inside the nested block.
exact('flatten the nested block', sub { $t->blockFlatten('2.3', -1) }, 1,
      8, [['F', -1], 'a', [['G', -1], 'uv'], 'bcd']);

# ---------------------------------------------------------------------
# Undo: one step, a kind of its own for -autoseparators (U3).

fraction();
$t->insert('2.1', 'q');
$t->blockFlatten('2.1', -1);
$t->editUndo;
is(text(), '{qnum|den}', 'the undo takes back the flatten only');
$t->editUndo;
is(text(), '{num|den}', 'then the insertion');
fraction();
$t->blockFlatten('2.1', -1);
$t->delete('2.1');
$t->editUndo;
is(text(), '{numden}', 'a deletion after it is a step of its own');
$t->editUndo;
is_deeply([text(), at()], ['{num|den}', [3, 3]], 'and the flatten one step');

# A value set on the single leaf after the flatten: the undo gives the
# leaf its own back, the redo the later one.
fraction();
$t->blockNodedata('2.1', 0, 'N');
$t->blockNodedata('2.1', 1, 'R');
$t->blockFlatten('2.1', -1);
is(nd('2.1', 0), 'R', 'the leaf took the root\'s value (U2)');
$t->blockNodedata('2.1', 0, 'L');
$t->editUndo;
is_deeply([nd('2.1', 0), nd('2.1', 1)], ['N', 'L'],
	  'the undo: the leaf\'s own value back, the one set after to the root (as a join)');
$t->editRedo;
is(nd('2.1', -1), 'L', 'the redo: the value set after');

# The callback cannot flatten.
fraction();
my $refused;
$t->configure(-valuecommand => sub {
  $refused = eval { $_[0]->blockFlatten('2.1', 1); 1 } ? 'no' : $@ unless defined $refused;
});
$t->blockNodedata('2.1', 0, 'v');
$t->blockNodedata('2.1', 0, undef);
like($refused, qr/^cannot modify \S+ while its -valuecommand runs/,
     'block flatten is refused while the callback runs');
$t->configure(-valuecommand => sub {
  my ($w, $event, $kind, $where, $value, $cause) = @_;
  push @events, join ' ', $event, $kind, wh($where), $value // 'undef', $cause;
});

# ---------------------------------------------------------------------
# A block that is a single leaf (O2): its root is that leaf.

sub single {
  fraction();
  $t->blockNodedata('2.1', 0, 'V');
  $t->blockFlatten('2.1', -1);		# {numden}
  $t->editReset;
  @events = ();
}
single();
is(at(), 6, 'block at: one number');
my @r = $t->blockAt('2.0');
is_deeply([@r[0 .. 2]], ['2.0', 8, 'F'], 'the rest of block at as before');
is_deeply(blist(), [[['F', -1, undef, ['V']], 'numden']], 'block list: depth -1');
is_deeply([nd('2.3', 0), nd('2.3', -1)], ['V', 'V'], 'nodedata 0 and -1 name the leaf');
like(fl('2.3', 1), qr/^ERR bad level "1": the block containing 2\.3 has 0 levels above this leaf/,
     'nodedata\'s levels: none above the leaf');
is(fl('2.3', -1), 0, 'flatten at -1 (the leaf) is a no-op');
ok(!eval { $t->blockTrim('2.1'); 1 }, 'block trim refuses it');
is(at(), 6, 'unchanged');

# The layout callback gets the leaf as its single argument.
my @args;
$t->blockConfigure('S', -layoutcmd => sub {
  my ($data, $x, @a) = @_;
  @args = @a;
  return ([-1, 0, 0, 20, 20, 10, 8], [scalar(@a), 0, 0, 20, 20, 10, 8]);
});
setup("x\nnum\nden\ny\n", '2.0', '3.3');
$t->delete('2.0', '2.end');
$t->insert('2.0', "ab\ncd");
$t->blockInsert('S', '2.0', '3.2');
$t->blockFlatten('2.1', -1);
$mw->update;
is(scalar(@args), 1, 'the layout callback gets one argument');
ok(!ref($args[0][0]), 'which is a leaf');
$t->blockConfigure('S', -layoutdepth => 2);
$mw->update;
is_deeply([scalar(@args), ref $args[0][0]], [1, 'ARRAY'],
	  '-layoutdepth 2: the leaf wrapped once');
$t->blockConfigure('S', -layoutdepth => 1);
$mw->update;
is_deeply([scalar(@args), ref $args[0][0]], [1, ''], '-layoutdepth 1: the leaf');

# A newline typed in it: the root becomes real, R( nu | mden ); the
# undo makes it a single leaf again (the root's value set meanwhile
# waits in the step).
single();
exact('a newline in a single leaf', sub { $t->insert('2.3', "\n"); 0 }, 0,
      [2, 4], [['F', 0, undef, [undef, ['V'], [undef]]], 'nu', sep(0), 'mden'],
      # (Provisional, O5) the root made real, the new leaf:
      ['new node [2.1 1] undef insert', 'new node [2.4 0] undef insert']);
$t->blockNodedata('2.1', 1, 'R');
$t->editUndo;
is_deeply([at(), nd('2.1', 0)], [6, 'V'], 'the undo: a single leaf');
$t->editRedo;
is(nd('2.1', 1), 'R', 'the redo: the root\'s value is back');

# block split: level 0 as a newline; level 1 adds a real root above
# the leaf (its pieces are sibling leaves); level 2 one more.
single();
exact('split level 0', sub { $t->blockSplit('2.3', 0) }, 0,
      [2, 4], [['F', 0, undef, [undef, ['V'], [undef]]], 'nu', sep(0), 'mden'],
      ['new node [2.1 1] undef block split', 'new node [2.4 0] undef block split']);
single();
exact('split level 1', sub { $t->blockSplit('2.3', 1) }, 1,
      [2, 4], [['F', 1, undef, [undef, ['V'], [undef]]], sep(undef, 1), 'nu', sep(1, 1), 'mden'],
      ['new node [2.1 1] undef block split', 'new node [2.4 0] undef block split']);
single();
exact('split level 2', sub { $t->blockSplit('2.3', 2) }, 2,
      [[2], [4]], [['F', 2, undef, [undef, [undef, ['V']], [undef, [undef]]]],
		   sep(undef, 1), 'nu', sep(2, 1), 'mden'],
      [map { "new node [$_] undef block split" } '2.1 1', '2.1 2', '2.4 1', '2.4 0']);
# A value set on the root the split added: the undo of the split.
single();
$t->blockSplit('2.3', 1);
$t->blockNodedata('2.1', -1, 'R');
$t->editUndo;
is_deeply([at(), nd('2.1', 0)], [6, 'R'], 'the undo of split 1: the leaf takes the root\'s value');
$t->editRedo;
is_deeply([at(), nd('2.1', 0)], [[2, 4], 'V'], 'the redo');

# block sprout first gives it a real root: R( start | N( middle ) | end ).
single();
exact('sprout in a single leaf', sub { $t->blockSprout('2.2', '2.4') }, 2,
      [1, [2], 3], [['F', 1, undef, [undef, ['V'], ['V', [undef]], ['V']]],
		    sep(undef, 1), 'n', sep(1), 'um', sep(1, 1), 'den']);
single();
exact('sprout of the whole text', sub { $t->blockSprout('2.1', '2.7') }, 2,
      [0, [6], 0], [['F', 1, undef, [undef, ['V'], ['V', [undef]], ['V']]],
		    sep(undef, 1), sep(1), 'numden', sep(1, 1)]);
single();
exact('sprout from the head', sub { $t->blockSprout('2.0', '2.3') }, 1,
      [[2], 4], [['F', 1, undef, [undef, ['V', [undef]], ['V']]],
		 'nu', sep(1, 1), 'mden']);
# A value set on the root sprout made: it waits in the undo step.
single();
$t->blockSprout('2.2', '2.4');
$t->blockNodedata('2.1', -1, 'R');
$t->editUndo;
is_deeply([at(), nd('2.1', 0)], [6, 'V'], 'the undo of sprout: a single leaf again');
$t->editRedo;
is(nd('2.1', -1), 'R', 'the redo: the root\'s value is back');

# Deletions and insertions inside it keep it a single leaf.
single();
exact('a deletion inside', sub { $t->delete('2.2', '2.5'); 0 }, 0,
      3, [['F', -1, undef, ['V']], 'nen'], []);
single();
exact('an insertion inside', sub { $t->insert('2.2', 'ab'); 0 }, 0,
      8, [['F', -1, undef, ['V']], 'nabumden'], []);
single();
exact('a nested block inside', sub { $t->blockInsert('G', '2.2', '2.4'); 0 }, 0,
      8, [['F', -1, undef, ['V']], 'n', [['G', 0], 'um'], 'den'],
      ['new node [2.3 1] undef block insert', 'new node [2.3 0] undef block insert']);
# A nested block of several leaves dissolved in it (its head deleted):
# the root becomes real; the undo makes it a single leaf again.
$t->blockSplit('2.4', 0);			# {n{u|m}den}
$t->editReset;
exact('a nested block dissolved in it', sub { $t->delete('2.2'); 0 }, 0,
      [2, 4], [['F', 0, undef, [undef, ['V'], [undef]]], 'nu', sep(0), 'mden'],
      ['new node [2.1 1] undef delete', 'new node [2.4 0] undef delete']);
# The whole block deleted and cut: the undo re-creates it from its list.
single();
$t->editSeparator;
my $l0 = blist();
$t->delete('1.1', '3.0');
is($t->get('1.0', 'end - 1c'), "xy\n", 'the whole block deleted');
$t->editUndo;
is_deeply([blist(), at()], [$l0, 6], 'the undo re-creates the single leaf');
single();
$t->editSeparator;
$l0 = blist();
$t->delete('2.3', '3.0');
$t->editUndo;
is_deeply([blist(), at()], [$l0, 6], 'the block cut: the undo re-creates the single leaf');

# block sprout, block split and block insert are undone in steps of their
# own on it: all of them in a row, undone one by one.
single();
my @states = ([blist(), at()]);
$t->blockSplit('2.3', 1);  push @states, [blist(), at()];
$t->insert('2.2', "\n");   push @states, [blist(), at()];
$t->blockFlatten('2.1', -1); push @states, [blist(), at()];
$t->blockSprout('2.1', '2.2'); push @states, [blist(), at()];
my $ok = 1;
for my $k (reverse 0 .. $#states - 1) {
  $t->editUndo;
  $ok &&= is_deeply([blist(), at()], $states[$k], "undo back to state $k");
}
for my $k (1 .. $#states) {
  $t->editRedo;
  is_deeply([blist(), at()], $states[$k], "redo to state $k");
}

$t->destroy;
$mw->destroy;
