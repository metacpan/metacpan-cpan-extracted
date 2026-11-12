#!/usr/bin/perl
# Ragged trees: blocks whose leaves are at different depths, made with
# "block sprout" (and "block split"), and what the widget does with
# them: the shape ("block at") after every structural change, the levels
# of "block nodedata", newlines and "block split" in leaves that hang
# from their parent through padding, the layout callback's arguments
# (with -layoutdepth), the values sprout copies, the exact undo and redo
# of sprout, what -valuecommand is told, and deletions that join leaves
# of different depths, with the exact undo and redo of those and of
# block insert, whole ragged blocks deleted and newlines typed in a
# padded leaf.  All with "debug" on: the B-tree check (padding
# rules included) runs after every change and panics on an
# inconsistency.
#
# The tree of a block is written R( a | N( b | c ) ): the root R, a leaf
# a, a node N with the leaves b and c.  "block at" gives it as nested
# lists of leaf lengths: [1, [1, 1]].
use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require Tk; 1 } or plan skip_all => "Tk not available: $@";
}
use Tk::eText;

my $mw = eval { MainWindow->new };
plan skip_all => "no X display available ($@)" unless $mw;
plan tests => 234;
$mw->geometry('+10+10');

my @events;
my $t = $mw->eText(-undo => 1, -autoseparators => 1, -width => 40,
		   -height => 8)->pack;
$t->blockConfigure('F');
$t->blockConfigure('G');
$t->debug(1);

# The structure of the block whose head is at an index ("block at").
sub at { my @r = $t->blockAt($_[0] // '2.0'); $r[4] }
sub text { $t->get('2.0', '2.end') }
sub nd { my $v = eval { $t->blockNodedata(@_) }; $@ ? 'ERR' : $v }

# The block on line 2 as "block list" gives it, marks left out and
# adjacent strings joined: separators with their (stored) depths, and
# the header with the node values over the real tree.
sub blist {
  my @out;
  my $walk;
  $walk = sub {
    my @o;
    for my $e (@_) {
      next if ref($e) =~ /Mark/;
      if (ref($e) =~ /::String$/) {
	if (@o && !ref $o[-1]) { $o[-1] .= $$e } else { push @o, $$e }
      } elsif (ref($e) =~ /BlockSeparator/) {
	# The pair [stored depth, defect] before a padded leaf.
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

# Line 2 holds the fraction {num|den}: head 2.0, num 2.1-2.3, the
# separator 2.4, den 2.5-2.7, the tail 2.8.
sub fraction {
  $t->delete('1.0', 'end');
  $t->insert('1.0', "x\nnum\nden\ny\n");
  $t->blockInsert('F', '2.0', '3.3');
  $t->editReset;
  @events = ();
}

# ---------------------------------------------------------------------
# block sprout: the owner's examples.

fraction();
is($t->blockSprout('2.2', '2.3'), 2, 'sprout 2.2 2.3 puts in two separators');
is(text(), '{n|u|m|den}', 'the u of num is a leaf of its own');
is_deeply(at(), [1, [1], 1, 3], 'R( n | N( u ) | m | den )');

fraction();
is($t->blockSprout('2.1', '2.4'), 2, 'sprout 2.1 2.4: two separators');
is_deeply(at(), [0, [3], 0, 3], 'R( | N( num ) | | den ): two empty leaves');

fraction();
is($t->blockSprout('2.0', '2.5'), 0, 'sprout 2.0 2.5, both delimiters: none');
is(text(), '{num|den}', 'the text does not change');
is_deeply(at(), [[3], 3], 'R( N( num ) | den ): the WRAP of num');

fraction();
is($t->blockSprout('2.0', '2.3'), 1, 'sprout 2.0 2.3: one separator');
is_deeply(at(), [[2], 1, 3], 'R( N( nu ) | m | den )');

fraction();
is($t->blockSprout('2.2', '2.2'), 2, 'an empty range');
is_deeply(at(), [1, [0], 2, 3], 'R( n | N( ) | um | den ): an empty middle leaf');

fraction();
is($t->blockSprout('2.4', '2.9'), 0, 'from the separator before den to past the tail');
is_deeply(at(), [3, [3]], 'R( num | N( den ) )');

fraction();
is($t->blockSprout('2.4', '2.5'), 1, 'just the separator: the leaf before it is taken');
is_deeply(at(), [3, [0], 3], 'R( num | N( ) | den )');

# Errors.
fraction();
ok(!eval { $t->blockSprout('2.2', '2.6'); 1 }, 'a range over a separator is an error');
like($@, qr/^block sprout: the range is not inside one leaf/, 'which says so');
ok(!eval { $t->blockSprout('2.3', '2.2'); 1 }, 'a reversed range is an error');
like($@, qr/^block sprout: the end of the range is before its start/, 'which says so');
ok(!eval { $t->blockSprout('1.0', '1.1'); 1 }, 'outside blocks is an error');
like($@, qr/^block sprout: not inside a block/, 'which says so');
$t->blockInsert('G', '2.2', '2.3');		# {n{u}m|den}
ok(!eval { $t->blockSprout('2.1', '2.3'); 1 }, 'ends in different blocks are an error');
like($@, qr/^block sprout: the ends of the range are in different blocks/, 'which says so');
is_deeply(at(), [5, 3], 'and nothing changed');

# A nested block wholly inside the range moves into the middle leaf.
is($t->blockSprout('2.1', '2.6'), 2, 'sprout over a nested block');
is(text(), '{|n{u}m||den}', 'the nested block is in the middle leaf');
is_deeply(at(), [0, [5], 0, 3], 'R( | N( n{u}m ) | | den )');
is_deeply(at('2.3'), [1], 'the nested block is unchanged');

# ---------------------------------------------------------------------
# block nodedata on a ragged tree: levels count real ancestors from the
# leaf (0 the leaf), negative ones real nodes from the root (-1 the
# root, down to the leaf itself); the bound is per leaf.

fraction();
$t->blockNodedata('2.1', 0, 'L');
$t->blockNodedata('2.1', 1, 'R');
$t->blockSprout('2.2', '2.3');		# R( n | N( u ) | m | den )
is(nd('2.3', 0), undef, 'u: level 0 is the leaf (no value)');
is(nd('2.3', 1), 'L', 'u: level 1 is N');
is(nd('2.3', 2), 'R', 'u: level 2 is the root');
is(nd('2.3', -1), 'R', 'u: level -1 is the root');
is(nd('2.3', -2), 'L', 'u: level -2 is N');
is(nd('2.3', -3), undef, 'u: level -3 is the leaf itself');
is(nd('2.1', 1), 'R', 'n: level 1 is the root');
is(nd('2.1', -2), 'L', 'n: level -2 is the leaf itself');
ok(!eval { $t->blockNodedata('2.1', 2); 1 }, 'n: level 2 is an error');
like($@, qr/^bad level "2": the block containing 2\.1 has 1 level above this leaf/,
     'which counts the levels above this leaf');
ok(!eval { $t->blockNodedata('2.3', 3); 1 }, 'u: level 3 is an error');
like($@, qr/^bad level "3": the block containing 2\.3 has 2 levels above this leaf/,
     'which counts the levels above this leaf');
ok(!eval { $t->blockNodedata('2.1', -3); 1 }, 'n: level -3 is an error');

# ---------------------------------------------------------------------
# Newlines and block split in a leaf that hangs through padding: up to
# its defect a split makes a sibling leaf (a padding chain of its own);
# beyond, it cuts real nodes as before.

fraction();
$t->blockSprout('2.4', '2.9');		# R( num | N( den ) ): num padded
is_deeply(at(), [3, [3]], 'R( num | N( den ) )');
$t->insert('2.2', "\n");
is(text(), '{n|um|den}', 'a newline in the padded leaf num');
is_deeply(at(), [1, 2, [3]], 'R( n | um | N( den ) ): siblings under the root');
$t->blockSplit('2.1', 1);
is_deeply(at(), [0, 1, 2, [3]], 'split level 1 = the defect of n: a sibling again');
$t->blockSplit('2.4', 2);
is(text(), '{|n||um|den}', 'split level 2 at the start of um');
is_deeply(at(), [[0, 1, 0], [2, [3]]],
	  'beyond the defect: the root is cut, a level added above it');
$t->blockSplit('2.9', 1);			# in den, below N
is_deeply(at(), [[0, 1, 0], [2, [1], [2]]], 'split level 1 in den cuts N');

fraction();
$t->blockSprout('2.2', '2.3');		# R( n | N( u ) | m | den )
$t->insert('2.3', "a\nb");
is(text(), '{n|a|bu|m|den}', 'a newline typed in u');
is_deeply(at(), [1, [1, 2], 1, 3], 'below N: siblings in N');
$t->insert('2.9', "c\nd");
is_deeply(at(), [1, [1, 2], 2, 1, 3], 'in the padded leaf m: siblings under R');

# The last leaf holds the dummy line in its lowest node.
fraction();
$t->blockSprout('2.6', '2.7');		# R( num | d | N( e ) | n )
is_deeply(at(), [3, 1, [1], 1], 'sprout in the last leaf');
$t->insert('2.10', "\nz");
is_deeply(at(), [3, 1, [1], 1, 1], 'a newline at the end of the last leaf');
$t->delete('2.9', '2.end - 1c');
is_deeply(at(), [3, 1, [1], 0], 'deleting most of the last two leaves');

# block trim on a ragged tree: R( N( num ) ) loses its root.
fraction();
$t->blockSprout('2.0', '2.5');		# R( N( num ) | den )
$t->delete('2.4', '2.8');		# the separator and den
is_deeply(at(), [[3]], 'R( N( num ) )');
ok(eval { $t->blockTrim('2.1'); 1 }, 'trim removes the root');
is_deeply(at(), [3], 'N( num )');

# ---------------------------------------------------------------------
# The layout callback's arguments follow the real tree; -layoutdepth D
# extends at the root side by D minus the greatest depth, then wraps
# each shallower leaf in lists of one element down to D, then cuts at
# D as before.

my @shape;
sub shape {
  my $a = shift;
  return 'L' . ($a->[0] == 1 ? '' : $a->[0]) unless ref $a->[0];
  [ map { shape($_) } @$a ];
}
sub leaves { my $s = shift; ref $s ? (map { leaves($_) } @$s) : ($s =~ /L(\d*)/ ? ($1 eq '' ? 1 : $1) : 0) }
$t->blockConfigure('S', -layoutcmd => sub {
  my ($data, $x, @args) = @_;
  @shape = map { shape($_) } @args;
  my $n = 0; $n += $_ for map { leaves($_) } @shape;
  return ([-1, 0, 0, 20, 20, 10, 8], [$n, 0, 0, 20, 20, 10, 8]);
});
sub layout {
  $t->blockConfigure('S', -layoutdepth => shift);
  @shape = ();
  $t->delete('1.0', 'end');
  $t->insert('1.0', "x\nnum\nden\ny\n");
  $t->blockInsert('S', '2.0', '3.3');
  $t->blockSprout('2.2', '2.3');	# R( n | N( u ) | m | den )
  $mw->update;
  [@shape];
}
is_deeply(layout(-1), ['L', ['L'], 'L', 'L'], 'callback: the real tree');
is_deeply(layout(1), ['L', 'L', 'L', 'L'], '-layoutdepth 1: N mocked as a leaf');
is_deeply(layout(2), [['L'], ['L'], ['L'], ['L']], '-layoutdepth 2: the leaves wrapped down to 2');
is_deeply(layout(3), [[['L'], ['L'], ['L'], ['L']]],
	  '-layoutdepth 3: the root side extended by 1, then the leaves wrapped');

# ---------------------------------------------------------------------
# Values: the former leaf's value goes to the start piece, the new node
# and the end piece, as the same value (shared); the middle leaf gets
# none.  Without a start piece the middle leaf is the former leaf: its
# value moves to the new node.

fraction();
my $obj = bless { n => 'obj' }, 'Obj';
$t->blockNodedata('2.1', 0, $obj);
$t->blockSprout('2.2', '2.3');
is(nd('2.1', 0), $obj, 'the start piece keeps the value');
is(nd('2.3', 1), $obj, 'the new node has it, the same object');
is(nd('2.5', 0), $obj, 'the end piece has it');
is(nd('2.3', 0), undef, 'the middle leaf has none');
$t->blockNodedata('2.3', 1, 'other');
is(nd('2.1', 0), $obj, 'setting one owner leaves the others');

fraction();
$t->blockNodedata('2.1', 0, 'V');
$t->blockSprout('2.0', '2.3');		# R( N( nu ) | m | den )
is(nd('2.1', 1), 'V', 'no start piece: the value moved to the new node');
is(nd('2.1', 0), undef, 'and the middle leaf has none');
is(nd('2.4', 0), 'V', 'the end piece has it');

# ---------------------------------------------------------------------
# Undo and redo of sprout: exact (the block list with node values, and
# the shape), one step of a kind of its own.

for my $case (['2.2', '2.3'], ['2.1', '2.4'], ['2.0', '2.5'], ['2.0', '2.3'],
	      ['2.2', '2.2'], ['2.4', '2.9'], ['2.6', '2.7']) {
  fraction();
  $t->blockNodedata('2.1', 0, 'A');
  $t->blockNodedata('2.5', 0, 'B');
  $t->blockNodedata('2.5', 1, 'R');
  $t->blockSprout('2.2', '2.2') if $case->[0] eq '2.6';	# a ragged tree first
  $t->editSeparator;
  my ($l0, $a0) = (blist(), at());
  $t->blockSprout(@$case);
  my ($l1, $a1) = (blist(), at());
  $t->editUndo;
  is_deeply([blist(), at()], [$l0, $a0], "sprout @$case: the undo is exact");
  $t->editRedo;
  is_deeply([blist(), at()], [$l1, $a1], "sprout @$case: the redo is exact");
}

# A value set on the new node after the sprout comes back with the redo.
fraction();
$t->blockNodedata('2.1', 0, 'A');
$t->blockSprout('2.2', '2.3');
$t->blockNodedata('2.3', 1, 'N');
$t->blockNodedata('2.3', 0, 'M');
my $l1 = blist();
$t->editUndo;
is(nd('2.1', 0), 'A', 'undo: the leaf keeps its value');
$t->editRedo;
is_deeply(blist(), $l1, 'redo: the values set after the sprout are back');

# Sprout is an edit of its own kind: with -autoseparators, one step.
fraction();
$t->insert('2.1', 'a');
$t->blockSprout('2.2', '2.3');
$t->editUndo;
is(text(), '{anum|den}', 'one undo takes back the sprout only');

# ---------------------------------------------------------------------
# -valuecommand: the copies are told "copy", with the receiving place
# as after the change; a WRAP tells each node above the leaf whose first
# leaf it is ("move", the new place as after the change); the undo
# tells the pull out and the stashes, the redo the restores.

my $vt = $mw->eText(-undo => 1, -valuecommand => sub {
  my ($w, $event, $kind, $where, $value, $cause) = @_;
  push @events, join ' ', $event, $kind, wh($where), $value // 'undef', $cause;
})->pack;
sub wh { '[' . join(' ', map { ref $_ ? wh($_) : $_ } @{$_[0]}) . ']' }
$vt->blockConfigure('F');
$vt->debug(1);
$vt->insert('1.0', "x\nnum\nden\ny\n");
$vt->blockInsert('F', '2.0', '3.3');
$vt->blockNodedata('2.1', 0, 'L');
$vt->blockNodedata('2.1', 1, 'R');
@events = ();
$vt->blockSprout('2.2', '2.3');
is_deeply(\@events, ['new node [2.3 0] undef block sprout',
		     'copy node [2.1 0 [2.3 1]] L block sprout',
		     'copy node [2.1 0 [2.5 0]] L block sprout'],
	  'sprout tells the middle leaf new (provisional) and the copies');
@events = ();
$vt->editUndo;
is_deeply(\@events, ['move node [2.3 1 [2.3 0]] L undo',
		     'stash node [2.5 0] L undo',
		     'stash node [2.3 0] L undo'],
	  'the undo tells the pull out and the joins');
@events = ();
$vt->editRedo;
is_deeply([sort @events], ['restore node [2.3 0] L redo', 'restore node [2.3 1] L redo',
			   'restore node [2.5 0] L redo'],
	  'the redo tells what comes back');
$vt->editUndo;
@events = ();
$vt->blockSprout('2.0', '2.5');
@events = grep { !/^discard/ } @events;	# The redo stack goes.
is_deeply(\@events, ['new node [2.1 0] undef block sprout',
		     'move node [2.1 1 [2.1 2]] R block sprout',
		     'move node [2.1 0 [2.1 1]] L block sprout'],
	  'a WRAP: the root and the value moving to the new node');
is(scalar($vt->blockNodedata('2.1', 2)), 'R', 'the root is at its new place');
@events = ();
$vt->editUndo;
is_deeply(\@events, ['move node [2.1 1 [2.1 0]] L undo',
		     'move node [2.1 2 [2.1 1]] R undo'],
	  'the pull out tells both moves back');

# The callback cannot sprout.
my $refused;
$vt->configure(-valuecommand => sub {
  $refused = eval { $_[0]->blockSprout('2.1', '2.2'); 1 } ? 'no' : $@ unless defined $refused;
});
$vt->blockNodedata('2.1', 0, undef);
like($refused, qr/^cannot modify \S+ while its -valuecommand runs/,
     'block sprout is refused while the callback runs');
$vt->destroy;

# ---------------------------------------------------------------------
# Deletions that join leaves of different depths: the shallower leaf is
# wrapped until both are equally deep, then joined as before (the
# start side keeps its value, else takes the end side's).  The undo is
# the inverse sequence in reverse order: the text comes back with its
# structure (the leaves it re-creates with their own padding), the
# values come back, then each WRAP is pulled out again.  Exact: the
# block list with the node values and the shape are those before the
# change; the redo gives those after it.  -valuecommand is told every
# step (a WRAP or a PULL OUT as "move" of the nodes renumbered).

$t->configure(-valuecommand => sub {
  my ($w, $event, $kind, $where, $value, $cause) = @_;
  push @events, join ' ', $event, $kind, wh($where), $value // 'undef', $cause;
});
sub sep { @_ > 1 ? \('|[' . ($_[0] // 'u') . ",$_[1]]") : \"|$_[0]" }

# The change, then its undo and its redo: the shape and the block list
# (with the node values) after the change (the block's header and
# contents; if no block is left, what line 2 has), the events of each,
# and the exactness of the undo and of the redo (6 tests).
sub exact {
  my ($name, $change, $shape, $list, $told, $undone, $redone) = @_;
  $list = [$list] if defined $shape;
  $t->editSeparator;
  my $s0 = [blist(), at()];
  @events = ();
  $change->();
  my $s1 = [blist(), at()];
  is_deeply([$s1->[1], $s1->[0]], [$shape, $list], "$name: shape and values after");
  is_deeply([@events], $told, "$name: what -valuecommand is told");
  @events = ();
  $t->editUndo;
  is_deeply([blist(), at()], $s0, "$name: the undo is exact");
  is_deeply([@events], $undone, "$name: what the undo tells");
  @events = ();
  $t->editRedo;
  is_deeply([blist(), at()], $s1, "$name: the redo is exact");
  is_deeply([@events], $redone, "$name: what the redo tells");
  @events = ();
}
sub setup {
  $t->delete('1.0', 'end');
  $t->insert('1.0', shift);
  $t->blockInsert('F', @_);
  $t->editReset;
}

# C( ab | B( xy | z ) ), from inside ab to inside xy: WRAP ab, JOIN.
# BUGS 28: the undo gave C( W( ab ) | B( xy | z ) ).
setup("x\nab\nxyz\ny\n", '2.0', '3.3');
$t->blockSprout('2.3', '2.8');		# C( ab | B( xyz ) )
$t->blockSplit('2.6', 0);		# C( ab | B( xy | z ) )
is_deeply(at(), [2, [2, 1]], 'C( ab | B( xy | z ) )');
$t->blockNodedata('2.4', 1, 'B');
$t->blockNodedata('2.1', 0, 'A');
$t->blockNodedata('2.4', 0, 'X');
$t->blockNodedata('2.1', -1, 'C');
exact('C( ab | B( xy | z ) ), b|x', sub { $t->delete('2.2', '2.5') },
      [[2, 1]], [['F', 1, undef, ['C', ['B', ['A'], [undef]]]], 'ay', sep(0), 'z'],
      ['new node [2.1 1] undef delete',
       'move node [2.1 1 [2.1 2]] C delete', 'stash node [2.4 0] X delete',
       'move node [2.4 1 [2.1 1]] B delete'],
      ['restore node [2.4 1] B undo', 'restore node [2.4 0] X undo',
       'move node [2.1 2 [2.1 1]] C undo'],
      ['move node [2.1 1 [2.1 2]] C redo', 'stash node [2.4 0] X redo',
       'move node [2.4 1 [2.1 1]] B redo']);
is(text(), '{ay|z}', 'deleted b|x');

# A value set on the wrapped node after the deletion (B had none): it
# waits in the undo step and comes back with the redo.
$t->editUndo;
$t->blockNodedata('2.4', 1, undef);
$t->editReset;
$t->delete('2.2', '2.5');
$t->blockNodedata('2.1', 1, 'W');
@events = ();
$t->editUndo;
is_deeply([at(), @events], [[2, [2, 1]], 'restore node [2.4 0] X undo',
			    'stash node [2.1 1] W undo',
			    'move node [2.1 2 [2.1 1]] C undo'],
	  'the undo: the value of the wrapped node waits in the step');
is(nd('2.1', 1), 'C', 'and the node above ab is the root again');
@events = ();
$t->editRedo;
is_deeply([nd('2.1', 1), @events], ['W', 'move node [2.1 1 [2.1 2]] C redo',
				    'stash node [2.4 0] X redo',
				    'restore node [2.1 1] W redo'],
	  'the redo gives it back');

# C( A( x | aa ) | B2( B1( yy | w ) | b ) ), from inside aa to inside
# yy: WRAP aa, JOIN at depth 2 (B1 joins the new node, B2 joins A).
setup("x\nx\naa\ny\n", '2.0', '3.2');
$t->blockSplit('2.5', 1);		# R( A( x | aa ) | B2( ) )
$t->insert('2.6', "yyw\nb");		# R( A( x | aa ) | B2( yyw | b ) )
$t->blockSprout('2.5', '2.10');		# wrap yyw
$t->blockSplit('2.8', 0);		# B1( yy | w )
is_deeply(at(), [[1, 2], [[2, 1], 1]], 'C( A( x | aa ) | B2( B1( yy | w ) | b ) )');
$t->blockNodedata('2.6', 1, 'B1');
$t->blockNodedata('2.6', 2, 'B2');
$t->blockNodedata('2.3', 1, 'A');
$t->blockNodedata('2.3', 0, 'a');
$t->blockNodedata('2.6', 0, 'y');
exact('two levels, a|y', sub { $t->delete('2.4', '2.7') },
      [[1, [2, 1], 1]],
      [['F', 2, undef, [undef, ['A', [undef], ['B1', ['a'], [undef]], [undef]]]],
       sep(undef, 1), 'x', sep(1), 'ay', sep(0), 'w', sep(1, 1), 'b'],
      ['new node [2.3 1] undef delete',
       'stash node [2.6 0] y delete', 'move node [2.6 1 [2.3 1]] B1 delete',
       'stash node [2.6 2] B2 delete'],
      ['restore node [2.6 2] B2 undo', 'restore node [2.6 1] B1 undo',
       'restore node [2.6 0] y undo'],
      ['stash node [2.6 0] y redo', 'move node [2.6 1 [2.3 1]] B1 redo',
       'stash node [2.6 2] B2 redo']);
is(text(), '{x|ay|w|b}', 'deleted a|y');

# Whole padded leaves go: R( aa | bb | N( cc | dd ) ), from inside aa
# to inside cc (bb goes with its padding): WRAP aa, JOIN.
setup("x\naa\nbb\nccdd\ny\n", '2.0', '4.4');
$t->blockSprout('2.6', '2.12');		# R( aa | bb | N( ccdd ) )
$t->blockSplit('2.9', 0);		# N( cc | dd )
is_deeply(at(), [2, 2, [2, 2]], 'R( aa | bb | N( cc | dd ) )');
$t->blockNodedata('2.7', 1, 'N');
$t->blockNodedata('2.4', 0, 'BB');
$t->blockNodedata('2.1', -1, 'R');
$t->blockNodedata('2.7', 0, 'CC');
exact('a padded leaf deleted whole', sub { $t->delete('2.2', '2.8') },
      [[2, 2]], [['F', 1, undef, ['R', ['N', ['CC'], [undef]]]], 'ac', sep(0), 'dd'],
      ['new node [2.1 1] undef delete',
       'move node [2.1 1 [2.1 2]] R delete', 'stash node [2.4 0] BB delete',
       'move node [2.7 0 [2.1 0]] CC delete', 'move node [2.7 1 [2.1 1]] N delete'],
      ['restore node [2.7 1] N undo', 'restore node [2.7 0] CC undo',
       'restore node [2.4 0] BB undo', 'move node [2.1 2 [2.1 1]] R undo'],
      ['move node [2.1 1 [2.1 2]] R redo', 'stash node [2.4 0] BB redo',
       'move node [2.7 0 [2.1 0]] CC redo', 'move node [2.7 1 [2.1 1]] N redo']);

# The end leaf deeper, whole (with its separator): it goes; but N
# holds the tail: joined, never deleted (F8), so num is wrapped.
setup("x\nnum\nden\ny\n", '2.0', '3.3');
$t->blockSprout('2.4', '2.9');		# R( num | N( den ) )
$t->blockNodedata('2.5', 1, 'N');
$t->blockNodedata('2.5', 0, 'D');
$t->blockNodedata('2.1', 0, 'M');
exact('F8: m|den', sub { $t->delete('2.3', '2.8') },
      [[2]], [['F', 1, undef, [undef, ['N', ['M']]]], 'nu'],
      ['new node [2.1 1] undef delete',
       'stash node [2.5 0] D delete', 'move node [2.5 1 [2.1 1]] N delete'],
      ['restore node [2.5 1] N undo', 'restore node [2.5 0] D undo'],
      ['stash node [2.5 0] D redo', 'move node [2.5 1 [2.1 1]] N redo']);

# A leaf and its node go whole: no WRAP.
setup("x\nnum\nden\ny\n", '2.0', '3.3');
$t->blockSprout('2.5', '2.6');		# R( num | | N( d ) | en )
$t->blockNodedata('2.6', 1, 'N');
exact('m| |d: no WRAP', sub { $t->delete('2.3', '2.7') },
      [2, 2], [['F', 1], sep(undef, 1), 'nu', sep(1, 1), 'en'],
      ['stash node [2.6 1] N delete'], ['restore node [2.6 1] N undo'],
      ['stash node [2.6 1] N redo']);

# A whole ragged block deleted, and one cut by the deletion (the
# widget dissolves it): the undo re-creates it from its list, the
# leaves with their padding.
setup("x\nab\ncd\nef\ny\n", '2.0', '4.2');
$t->blockSprout('2.4', '2.5');		# R( ab | | N( c ) | d | ef )
$t->blockNodedata('2.5', 1, 'N');
$t->blockNodedata('2.1', -1, 'R');
$t->blockNodedata('2.1', 0, 'A');
$t->blockNodedata('2.7', 0, 'E');
is_deeply(at(), [2, 0, [1], 1, 2], 'R( ab | | N( c ) | d | ef )');
exact('a whole ragged block', sub { $t->delete('1.1', '3.0') },
      undef, [],
      ['stash node [2.1 0] A delete', 'stash node [2.5 1] N delete',
       'stash node [2.7 0] E delete', 'stash node [2.1 1] R delete'],
      ['restore node [2.7 0] E undo', 'restore node [2.5 1] N undo',
       'restore node [2.1 0] A undo', 'restore node [2.1 1] R undo'],
      ['stash node [2.1 0] A redo', 'stash node [2.5 1] N redo',
       'stash node [2.7 0] E redo', 'stash node [2.1 1] R redo']);
$t->editUndo;
exact('a ragged block cut', sub { $t->delete('1.1', '2.6') },
      undef, ['d'],
      ['stash node [2.1 0] A delete', 'stash node [2.5 1] N delete',
       'stash node [2.7 0] E delete', 'stash node [2.1 1] R delete'],
      ['restore node [2.7 0] E undo', 'restore node [2.1 0] A undo',
       'restore node [2.1 1] R undo', 'restore node [2.5 1] N undo'],
      ['stash node [2.1 0] A redo', 'stash node [2.5 1] N redo',
       'stash node [2.7 0] E redo', 'stash node [2.1 1] R redo']);

# Newlines typed in a padded leaf: the redo of the insertion gives the
# new leaves their own padding again.
setup("x\nnum\nden\ny\n", '2.0', '3.3');
$t->blockSprout('2.4', '2.9');		# R( num | N( den ) )
exact('newlines in a padded leaf', sub { $t->insert('2.2', "a\nb\nc") },
      [2, 1, 3, [3]], [['F', 1], sep(undef, 1), 'na', sep(1, 1), 'b', sep(1, 1), 'cum',
		       sep(1), 'den'],
      ['new node [2.4 0] undef insert', 'new node [2.6 0] undef insert'], [], []);

# block insert across leaves of different depths: its undo sets the
# levels of the separators back, and the leaves' defects.
setup("x\nnum\nden\ny\n", '2.0', '3.3');
$t->blockSprout('2.0', '2.5');		# R( N( num ) | den )
$t->blockNodedata('2.1', 1, 'N');
$t->blockNodedata('2.5', 0, 'D');
$t->blockNodedata('2.1', -1, 'R');
exact('block insert from N( num ) into den', sub { $t->blockInsert('G', '2.2', '2.6') },
      [[9]], [['F', 1, undef, ['R', ['N', ['D']]]], 'n', [['G', 0], 'um', sep(0), 'd'], 'en'],
      ['move node [2.5 0 [2.1 0]] D block insert',
       map({ "new node [$_] undef block insert" } '2.3 1', '2.3 0', '2.6 0')],
      ['restore node [2.5 0] D undo'],
      ['move node [2.5 0 [2.1 0]] D redo']);
setup("x\nnum\nden\ny\n", '2.0', '3.3');
$t->blockSprout('2.4', '2.9');		# R( num | N( den ) )
$t->blockNodedata('2.5', 1, 'N');
$t->blockNodedata('2.5', 0, 'D');
exact('block insert from num into N( den )', sub { $t->blockInsert('G', '2.2', '2.6') },
      [9], [['F', 1, undef, [undef, ['D']]], sep(undef, 1), 'n', [['G', 0], 'um', sep(0), 'd'],
	    'en'],
      ['move node [2.5 0 [2.1 0]] D block insert', 'stash node [2.5 1] N block insert',
       map({ "new node [$_] undef block insert" } '2.3 1', '2.3 0', '2.6 0')],
      ['restore node [2.5 1] N undo', 'restore node [2.5 0] D undo'],
      ['move node [2.5 0 [2.1 0]] D redo', 'stash node [2.5 1] N redo']);
# R( dsj | N( | M( ) | x ) | ceno ): leaves at three depths, separators
# of levels 2, 1, 1, 2 (found by the random exactness check).
setup("x\ndsjxceno\ny\n", '2.0', '2.8');
$t->blockSprout('2.4', '2.5');
$t->blockSprout('2.5', '2.5');
is_deeply(blist(), [[['F', 2], sep(undef, 2), 'dsj', sep(2, 1), sep(1), sep(1, 1), 'x',
		     sep(2, 2), 'ceno']],
	  'R( dsj | N( | M( ) | x ) | ceno )');
exact('block insert over three depths', sub { $t->blockInsert('G', '2.3', '2.9') },
      [14], [['F', 2], sep(undef, 2), 'ds', [['G', 0], 'j', sep(0), sep(0), sep(0), 'x', sep(0)],
	     'ceno'],
      [map { "new node [$_] undef block insert" } '2.4 1', '2.4 0', '2.6 0', '2.7 0', '2.8 0',
	 '2.10 0'], [], []);
# block sprout with one index (decision O8): the WRAP of the leaf the
# index names (as "block nodedata index 0" does), returns 0; also the
# only leaf of a block, and a block that is a single leaf (which first
# gets a real root).  The leaf's value moves to the new node (as for
# the two-index form from delimiter to delimiter), the leaf is told
# "new".
setup("x\nnum\ny\n", '2.0', '2.3');	# {num}
$t->blockNodedata('2.1', 0, 'L');
exact('sprout 2.1 in {num}', sub { is($t->blockSprout('2.1'), 0, 'sprout 2.1 returns 0') },
      [[3]], [['F', 1, undef, [undef, ['L', [undef]]]], 'num'],
      ['new node [2.1 0] undef block sprout', 'move node [2.1 0 [2.1 1]] L block sprout'],
      ['move node [2.1 1 [2.1 0]] L undo'], ['restore node [2.1 1] L redo']);
setup("x\nnum\nden\ny\n", '2.0', '3.3');	# {num|den}
exact('sprout 2.4 (the separator names num)', sub { $t->blockSprout('2.4') },
      [[3], 3], [['F', 1], 'num', sep(1, 1), 'den'],
      ['new node [2.1 0] undef block sprout', 'new node [2.1 1] undef block sprout'],
      [], []);
exact('sprout 2.8 (the tail names den)', sub { $t->blockSprout('2.8') },
      [[3], [3]], [['F', 1], 'num', sep(1), 'den'],
      ['new node [2.5 0] undef block sprout', 'new node [2.5 1] undef block sprout'],
      [], []);
$t->blockFlatten('2.1', -1);		# {numden}: a single leaf
$t->blockNodedata('2.1', 0, 'S');
$t->editReset;
exact('sprout in a single leaf', sub { $t->blockSprout('2.3') },
      [[6]], [['F', 1, undef, [undef, ['S', [undef]]]], 'numden'],
      ['new node [2.1 2] undef block sprout', 'new node [2.1 0] undef block sprout',
       'move node [2.1 0 [2.1 1]] S block sprout'],
      ['move node [2.1 1 [2.1 0]] S undo'], ['restore node [2.1 1] S redo']);
setup("x\naxb\ny\n", '2.0', '2.3');	# {axb}
$t->blockConfigure('G');
$t->blockInsert('G', '2.2', '2.3');	# {a{x}b}
$t->blockSplit('2.3', 0);		# {a{|x}b}
$t->editReset;
exact('sprout in a nested block', sub { $t->blockSprout('2.4') },
      [6], [['F', 0], 'a', [['G', 1], sep(undef, 1), sep(1), 'x'], 'b'],
      ['new node [2.4 0] undef block sprout', 'new node [2.4 1] undef block sprout'],
      [], []);
is_deeply([$t->blockAt('2.2')]->[4], [0, [1]], 'the nested block: G( | N( x ) )');
for my $bad (['1.0', qr/^block sprout: not inside a block/], ['2.0', qr/^block sprout: not inside a block/]) {
  setup("x\nnum\ny\n", '2.0', '2.3');
  ok(!eval { $t->blockSprout($bad->[0]); 1 } && $@ =~ $bad->[1], "sprout $bad->[0]: an error");
}
ok(!eval { $t->blockSprout(); 1 } && $@ =~ /wrong # args/, 'sprout without an index: an error');

# "new" (provisional, decision O5): told before the change, once for
# each node or leaf it creates without a value, with its place after
# the change.  The manual's example: {num|den}, R on the root, N on
# num; "block split 2.2 1" gives R( X( n ) | Y( um | den ) ) (the
# root's value moves up with the root, so that level -1 keeps naming
# it: X, the first half of the old root, is new).
setup("x\nnum\nden\ny\n", '2.0', '3.3');
$t->blockNodedata('2.1', -1, 'R');
$t->blockNodedata('2.1', 0, 'N');
exact('split 2.2 1: new', sub { $t->blockSplit('2.2', 1) },
      [[1], [2, 3]], [['F', 1, undef, ['R', [undef, ['N']], [undef, [undef], [undef]]]],
		      'n', sep(1), 'um', sep(0), 'den'],
      ['new node [2.1 1] undef block split', 'new node [2.3 1] undef block split',
       'new node [2.3 0] undef block split', 'move node [2.1 1 [2.1 2]] R block split'],
      [], ['move node [2.1 1 [2.1 2]] R redo']);
# A newline typed in a leaf; block insert; a nested block dissolved.
setup("x\nnum\nden\ny\n", '2.0', '3.3');
exact('newlines: new leaves', sub { $t->insert('2.2', "a\nbc\nd") },
      [2, 2, 3, 3], [['F', 0], 'na', sep(0), 'bc', sep(0), 'dum', sep(0), 'den'],
      ['new node [2.4 0] undef insert', 'new node [2.7 0] undef insert'], [], []);
$t->blockConfigure('G');
setup("x\nnum\nden\ny\n", '2.0', '3.3');
$t->blockNodedata('2.1', 0, 'N');
# The whole of num moves into the new block with its value (the
# enclosing leaf left is new), and the part of den before 2.5 (nothing).
exact('block insert G over num|: new', sub { $t->blockInsert('G', '2.1', '2.5') },
      [9], [['F', 0], [['G', 0, undef, [undef, ['N'], [undef]]], 'num', sep(0)], 'den'],
      ['new node [2.2 1] undef block insert', 'new node [2.1 0] undef block insert',
       'new node [2.6 0] undef block insert'], [], []);
setup("x\nnum\nden\ny\n", '2.0', '3.3');
$t->blockInsert('G', '2.2', '2.6');	# {n{um|d}en}
$t->editReset;
exact('a nested block dissolved: new leaves', sub { $t->delete('2.1', '2.3') },
      [2, 3], [['F', 0], 'um', sep(0), 'den'],
      ['new node [2.4 0] undef delete'], [], []);

# The public list (decision L1): the separator before a padded leaf is
# the pair [stored depth, defect], a padded first leaf gets [undef,
# defect]; a uniform tree's list is as before.
setup("x\nx\n23\ny\n", '2.0', '3.2');	# {x|23}
$t->blockSprout('2.2', '2.6');		# R( x | S( 23 ) )
$t->blockSplit('2.4', 0);		# R( x | S( 2 | 3 ) )
is_deeply(blist(), [[['F', 1], sep(undef, 1), 'x', sep(1), '2', sep(0), '3']],
	  'R( x | S( 2 | 3 ) ): [undef, 1] before x');
my ($pair) = grep { ref($_) =~ /BlockSeparator/ } map { ref($_) =~ /::Block$/ ? @$_ : () }
  $t->blockList('2.0', '2.end');
is_deeply([ref $pair, [@$pair]], ['Tk::Text::BlockSeparator', [undef, 1]],
	  'a blessed array of the same class');
setup("x\n23\nx\ny\n", '2.0', '3.1');	# {23|x}
$t->blockSprout('2.0', '2.4');		# R( S( 23 ) | x )
$t->blockSplit('2.2', 0);
is_deeply(blist(), [[['F', 1], '2', sep(0), '3', sep(1, 1), 'x']],
	  'R( S( 2 | 3 ) | x ): [1, 1] before x');
fraction();
is_deeply(blist(), [[['F', 0], 'num', sep(0), 'den']], 'a uniform tree: as before');

# Random edits and undo on ragged trees, checked by the B-tree check.
srand(7);
fraction();
for my $step (1 .. 300) {
  my $n = (split /\./, $t->index('2.end'))[1];
  my $a = '2.' . int rand($n + 1);
  my $b = '2.' . int rand($n + 1);
  ($a, $b) = ($b, $a) if $t->compare($a, '>', $b);
  my $op = int rand 8;
  eval {
    if ($op == 0) { $t->blockSprout($a, $t->index("$a + " . int(rand 3) . 'c')) }
    elsif ($op == 1) { $t->blockSprout($a) }
    elsif ($op == 2) { $t->delete($a, $b) }
    elsif ($op == 3) { $t->insert($a, ("\n", 'q')[rand 2]) }
    elsif ($op == 4) { $t->blockSplit($a, int rand 3) }
    elsif ($op == 5) { $t->editUndo }
    elsif ($op == 6) { $t->editRedo }
    else { $t->blockNodedata($a, int(rand 3) - 1, "v$step") }
  };
  last if $t->compare('2.0', '>=', 'end - 1c');
}
pass('random edits of ragged trees: no panic');

$t->destroy;
$mw->destroy;
