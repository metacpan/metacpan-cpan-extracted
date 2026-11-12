#!/usr/bin/perl
# Values of block nodes ("block nodedata"): where they are found, and
# exactly when they are freed.  The values are objects whose DESTROY
# method records that it ran; every test checks that an object is
# destroyed exactly once, by the command that drops it, and not before.
use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require Tk; 1 } or plan skip_all => "Tk not available: $@";
}
use Tk::eText;

my $mw = eval { MainWindow->new };
plan skip_all => "no X display available ($@)" unless $mw;
my $have_lt = eval { require Test::LeakTrace; 1 };
plan tests => 306;
$mw->geometry('+10+10');

my @log;			# names of the objects destroyed, in order
{
  package V;
  sub new { my ($class, $name, $hook) = @_; bless { n => $name, hook => $hook }, $class }
  sub DESTROY { my $self = shift; $self->{hook}->($self) if $self->{hook};
		push @log, $self->{n} }
}

# The names of the objects destroyed while the code runs.
sub freed (&) { @log = (); $_[0]->(); my @r = @log; @log = (); return \@r }
sub sfreed (&) { my $r = &freed($_[0]); return [sort @$r] }

# A text with a two-leaf block (a fraction) on line 2:
#   line 1 "ab", line 2 "{num|den}" (head 2.0, num 2.1-2.3 and its
#   separator 2.4, den 2.5-2.7 and the tail 2.8), line 3 "cd".
sub fraction {
  my $t = $mw->eText(-width => 30, -height => 6, @_)->pack;
  $t->blockConfigure('F');
  $t->insert('end', "ab\nnum\nden\ncd\n");
  $t->blockInsert('F', '2.0', '3.3');
  return $t;
}

sub nv { my ($t, $index, $level) = @_; my $v = $t->blockNodedata($index, $level);
	 return defined $v ? (ref $v ? $v->{n} : $v) : undef }

# Does the code die (in an eval), with a message matching the pattern?
sub dies_like { my ($code, $re, $name) = @_;
		my $ok = !eval { $code->(); 1 }; like($ok ? $@ : 'no error', $re, $name) }

# ---------------------------------------------------------------------
# N1, N2: finding the node; reading and setting.
{
  my $t = fraction();
  is($t->get('2.0', '2.end'), '{num|den}', 'the fraction');
  ok(!defined $t->blockNodedata('2.2', 0), 'no value at first');
  $t->blockNodedata('2.2', 0, V->new('num'));
  $t->blockNodedata('2.6', 0, V->new('den'));
  $t->blockNodedata('2.6', 1, V->new('root'));
  is(nv($t, '2.1', 0), 'num', 'level 0: the leaf of the position');
  is(nv($t, '2.4', 0), 'num', 'the separator after a leaf names that leaf');
  is(nv($t, '2.5', 0), 'den', 'the next leaf');
  is(nv($t, '2.8', 0), 'den', 'the tail names the last leaf');
  is(nv($t, '2.2', 1), 'root', 'level 1: the parent, here the root');
  is(nv($t, '2.2', -1), 'root', 'level -1: the root');
  is(nv($t, '2.2', -2), 'num', 'level -2: down from the root, the leaf');
  dies_like(sub { $t->blockNodedata('2.2', 2) },
	    qr/^bad level "2": the block containing 2\.2 has 1 level above this leaf/,
	    'a level beyond the root');
  dies_like(sub { $t->blockNodedata('2.2', -3) }, qr/^bad level "-3"/,
	    'a negative level below the leaf');
  dies_like(sub { $t->blockNodedata('2.0', 0) }, qr/^bad index "2\.0": not inside a block/,
	    'the head belongs to the enclosing text');
  dies_like(sub { $t->blockNodedata('1.0', 0) }, qr/not inside a block/,
	    'a position outside every block');
  dies_like(sub { $t->blockNodedata('2.2', 'x') }, qr/numeric|integer/i,
	    'a level that is not a number');
  dies_like(sub { $t->block('nodedata', '2.2') }, qr/wrong # args/, 'wrong # args');
  dies_like(sub { $t->block('nosuch') }, qr/nodedata/, 'the bad option message names nodedata');

  # N3: a copy of the scalar is kept.
  my $s = 'plain';
  $t->blockNodedata('2.2', 1, $s);
  $s .= ' changed';
  is($t->blockNodedata('2.2', 1), 'plain', 'a copy of a string is kept')
    or diag $t->blockNodedata('2.2', 1);
  is_deeply(\@log, ['root'], 'replacing a value frees the old one');
  @log = ();
  my $obj = V->new('kept');
  $t->blockNodedata('2.2', 1, $obj);
  undef $obj;
  is_deeply(\@log, [], 'the object lives on in the node');
  is(nv($t, '2.2', 1), 'kept', 'and is read back');
  is_deeply(freed { $t->blockNodedata('2.2', 1, undef) }, ['kept'],
	    'setting undef frees the value, then');
  ok(!defined $t->blockNodedata('2.2', 1), 'no value any more');
  is_deeply(freed { $t->blockNodedata('2.2', 0, V->new('num2')) }, ['num'],
	    'replacing frees the old value exactly once');

  # N7: the values in the block list.
  $t->blockNodedata('2.2', 1, 7);
  my ($block) = $t->blockList('2.0', '2.end');
  is(ref $block, 'Tk::Text::Block', 'block list: a block');
  is($block->[0][2], undef, 'the third element is undef without instance data');
  is(ref $block->[0][3], 'ARRAY', 'the fourth element: the node values');
  is($block->[0][3][0], 7, 'the root value first');
  is($block->[0][3][1][0]{n}, 'num2', 'then the leaves, each in a list');
  is($block->[0][3][2][0]{n}, 'den', 'the second leaf');
  is(scalar @{$block->[0][3]}, 3, 'the dummy line is not a leaf');
  undef $block;
  $t->blockData('2.2', 'inst');
  ($block) = $t->blockList('2.0', '2.end');
  is($block->[0][2], 'inst', 'with instance data, it stays third');
  undef $block;

  # Freeing by an unrelated edit: none.
  is_deeply(freed { $t->insert('1.1', "x\ny"); $t->delete('1.1', '2.1');
		    $t->insert('2.9', 'pq'); $t->delete('2.9', '2.11');
		    $t->insert('2.2', 'zz'); $t->delete('2.2', '2.4') }, [],
	    'unrelated edits free nothing');
  $t->insert('2.0', 'z');
  is($t->get('2.0', '2.end'), 'z{num|den}', 'the text then');
  is(nv($t, '2.2', 0), 'num2', 'the value stays with its leaf');

  # A leaf whose text becomes empty keeps its value.
  is_deeply(freed { $t->delete('2.2', '2.5') }, [], 'emptying a leaf frees nothing');
  is($t->get('2.0', '2.end'), 'z{|den}', 'the leaf is empty');
  is(nv($t, '2.2', 0), 'num2', 'and keeps its value');

  # The widget destroyed: all the values go, after the widget.
  my $after;
  $t->blockNodedata('2.4', -1,
		    V->new('root-hook', sub { $after = eval { $t->index('end'); 'alive' } || 'gone' }));
  is_deeply(sfreed { $t->destroy; $mw->update }, ['den', 'num2', 'root-hook'],
	    'destroying the widget frees the remaining values')
    or diag "@log";
  is($after, 'gone', 'after the widget is gone');
}

# ---------------------------------------------------------------------
# F1: freed when the command is finished, the text consistent again.
{
  my $t = fraction();
  my $end;
  $t->blockNodedata('2.2', 0, V->new('num', sub { $end = $t->index('end') }));
  is($t->index('end'), '5.0', 'end before the deletion');
  is_deeply(freed { $t->delete('2.0', '3.0') }, ['num'], 'deleting the block frees its value');
  is($end, '4.0', 'DESTROY saw the text after the deletion');

  # A DESTROY that edits the widget (allowed since 2.05, t/freeing.t):
  # the value its edit drops is freed in the same pass, after it.
  $t->insert('1.0', "num\nden\n");
  $t->blockInsert('F', '1.0', '2.3');
  is($t->get('1.0', '1.end'), '{num|den}', 'a new fraction');
  $t->blockNodedata('1.6', 0, V->new('inner'));
  $t->blockNodedata('1.2', 0, V->new('outer', sub {
    push @log, 'outer<'; eval { $t->blockNodedata('1.6', 0, undef) }; push @log, 'outer>' }));
  is_deeply(freed { $t->blockNodedata('1.2', 0, 'x') },
	    ['outer<', 'outer>', 'outer', 'inner'],
	    'an edit in DESTROY: the value it drops is freed in the same pass');
  ok(!defined $t->blockNodedata('1.6', 0), 'the value it removed is gone');
  $t->destroy;
}

# ---------------------------------------------------------------------
# N4, N5: deletions (undo off).
{
  # Three leaves in one node: deleting the middle one entirely.
  my $t = fraction();
  $t->insert('2.4', "\nmid");	# {num|mid|den}
  is($t->get('2.0', '2.end'), '{num|mid|den}', 'three leaves');
  $t->blockNodedata('2.1', 0, V->new('num'));
  $t->blockNodedata('2.5', 0, V->new('mid'));
  $t->blockNodedata('2.9', 0, V->new('den'));
  is_deeply(freed { $t->delete('2.4', '2.8') }, ['mid'],
	    'a leaf wholly inside the deletion, with the separator before it: its value is freed');
  is($t->get('2.0', '2.end'), '{num|den}', 'two leaves left');
  is(nv($t, '2.6', 0), 'den', 'the next leaf keeps its value');
  is(nv($t, '2.2', 0), 'num', 'the previous leaf keeps its value');

  # N5: a merge keeps the first value present.
  is_deeply(freed { $t->delete('2.2', '2.6') }, ['den'],
	    'merging two leaves frees the second value');
  is($t->get('2.0', '2.end'), '{nen}', 'one leaf');
  is(nv($t, '2.2', 0), 'num', 'the merged leaf keeps the first value');
  $t->destroy;

  $t = fraction();
  $t->blockNodedata('2.6', 0, V->new('den'));
  is_deeply(freed { $t->delete('2.2', '2.6') }, [], 'merging into a leaf without value');
  is(nv($t, '2.2', 0), 'den', 'the merged leaf takes the second value');
  $t->destroy;

  # Deleting the whole block, or its head, or its tail.
  for my $case (['2.0', '2.9', 'the whole block'],
		['1.1', '2.2', 'the head'],
		['2.6', '3.1', 'the tail']) {
    my ($i1, $i2, $what) = @$case;
    $t = fraction();
    $t->blockNodedata('2.2', 0, V->new('num'));
    $t->blockNodedata('2.6', 0, V->new('den'));
    $t->blockNodedata('2.6', -1, V->new('root'));
    is_deeply(sfreed { $t->delete($i1, $i2) }, [qw(den num root)],
	      "deleting $what frees every value of the block");
    is_deeply([$t->blockOf('2.1')], [], 'the block is gone');
    $t->destroy;
  }

  # Merging nodes: two subtrees (block split at level 1 in "den").
  $t = fraction();
  $t->blockSplit('2.6', 1);		# {num|d|en}: [[num, d], [en]]
  my @of = $t->blockOf('2.1');
  is_deeply($of[4], [[3, 1], [2]], 'two subtrees') or diag explain \@of;
  $t->blockNodedata('2.2', 0, V->new('num'));
  $t->blockNodedata('2.2', 1, V->new('node1'));
  $t->blockNodedata('2.8', 0, V->new('en'));
  $t->blockNodedata('2.8', 1, V->new('node2'));
  $t->blockNodedata('2.8', 2, V->new('root'));
  is_deeply(sfreed { $t->delete('2.3', '2.8') }, [qw(en node2)],
	    'merging two subtrees frees the second values on each level');
  @of = $t->blockOf('2.1');
  is_deeply($of[4], [[3]], 'one subtree') or diag explain \@of;
  is($t->get('2.0', '2.end'), '{nun}', 'the text');
  is(nv($t, '2.2', 0), 'num', 'merged leaf: its first value');
  is(nv($t, '2.2', 1), 'node1', 'merged node: its first value');
  is(nv($t, '2.2', 2), 'root', 'the root is untouched');
  $t->destroy;

  # The text of a leaf entirely in the range, but not the separator
  # before it: the leaf survives the join (as the first part of a leaf
  # split by an insertion keeps the value), and keeps its value.
  $t = fraction();
  $t->blockSplit('2.6', 1);		# {num|d|en}
  $t->blockNodedata('2.5', 0, V->new('d'));
  $t->blockNodedata('2.8', 0, V->new('en'));
  $t->blockNodedata('2.2', 1, V->new('node1'));
  $t->blockNodedata('2.8', 1, V->new('node2'));
  is_deeply(sfreed { $t->delete('2.5', '2.8') }, [qw(en node2)],
	    'the text of a leaf deleted, joined with the next one');
  is($t->get('2.0', '2.end'), '{num|n}', 'the text');
  is(nv($t, '2.6', 0), 'd', 'the joined leaf keeps the first value');
  is(nv($t, '2.6', 1), 'node1', 'the first node keeps its value');
  $t->destroy;

  # With the separator before it: that leaf is deleted as a whole.
  $t = fraction();
  $t->blockSplit('2.6', 1);		# {num|d|en}
  $t->blockNodedata('2.5', 0, V->new('d'));
  $t->blockNodedata('2.8', 0, V->new('en'));
  $t->blockNodedata('2.2', 1, V->new('node1'));
  $t->blockNodedata('2.8', 1, V->new('node2'));
  is_deeply(sfreed { $t->delete('2.4', '2.7') }, [qw(d node2)],
	    'a leaf deleted with the separator before it, the next joined');
  is($t->get('2.0', '2.end'), '{numen}', 'the text');
  is(nv($t, '2.2', 0), 'en', 'the joined leaf takes the value of the next one');
  is(nv($t, '2.2', 1), 'node1', 'the first node keeps its value');
  $t->destroy;

  # A whole subtree in the range.
  $t = fraction();
  $t->blockSplit('2.6', 1);
  $t->blockSplit('2.3', 1);		# {nu|m|d|en}: [[nu], [m, d], [en]]
  @of = $t->blockOf('2.1');
  is_deeply($of[4], [[2], [1, 1], [2]], 'three subtrees') or diag explain \@of;
  $t->blockNodedata('2.1', 1, V->new('first'));
  $t->blockNodedata('2.4', 1, V->new('middle'));
  $t->blockNodedata('2.4', 0, V->new('m'));
  $t->blockNodedata('2.9', 1, V->new('last'));
  is_deeply(sfreed { $t->delete('2.2', '2.9') }, [qw(last m middle)],
	    'a subtree wholly deleted, and the last one merged: their values are freed');
  @of = $t->blockOf('2.1');
  is_deeply($of[4], [[2]], 'what is left') or diag explain \@of;
  is(nv($t, '2.1', 1), 'first', 'the merged node keeps its first value');
  $t->destroy;

  # The last of the nodes directly above the leaves (and its ancestors
  # below the root) holds the tail of the block too: a deletion of all
  # its leaves does not delete it, it is joined to the node before it,
  # and its value moves there if that node has none (and is dropped
  # otherwise).  A node that is not the last is deleted with its value.
  for my $case ([0, undef, [qw(en)], 'node2'],
		[0, 'node1', [qw(en node2)], 'node1'],
		[1, undef, [qw(en node2)], undef],
		[1, 'node1', [qw(en node2)], 'node1']) {
    my ($more, $node1, $want, $left) = @$case;
    my $what = ($more ? 'a node that is not the last' : 'the last node')
      . ', the node before it ' . ($node1 ? 'with' : 'without') . ' a value';
    $t = fraction();
    $t->insert("2.8", "\nx") if $more;		# {num|den|x}
    $t->blockSplit('2.6', 1);			# {num|d|en}: [[num, d], [en]]
    $t->blockSplit('2.9', 1) if $more;		# [[num, d], [en], [(empty), x]]
    @of = $t->blockOf('2.1');
    is_deeply($of[4], $more ? [[3, 1], [2], [0, 1]] : [[3, 1], [2]], "$what: the nodes")
      or diag explain \@of;
    $t->blockNodedata('2.8', 0, V->new('en'));
    $t->blockNodedata('2.8', 1, V->new('node2'));
    $t->blockNodedata('2.2', 1, V->new($node1)) if $node1;
    is_deeply(sfreed { $t->delete('2.6', '2.9') }, $want,
	      "$what: deleting all its leaves frees " . join(' and ', @$want));
    @of = $t->blockOf('2.1');
    is_deeply($of[4], $more ? [[3, 1], [0, 1]] : [[3, 1]], "$what: the node is gone")
      or diag explain \@of;
    is(nv($t, '2.2', 1), $left, "$what: the node before it has " . ($left // 'no value'));
    $t->destroy;
  }

  # The same on each level: the last node of each level holds the tail.
  $t = fraction();
  $t->insert("2.8", "\nxyz");			# {num|den|xyz}
  $t->blockSplit('2.5', 2);			# {num||den|xyz}, empty leaf after num
  @of = $t->blockOf('2.1');
  is_deeply($of[4], [[[3, 0]], [[3, 3]]], 'three levels') or diag explain \@of;
  $t->blockNodedata('2.2', 2, V->new('a2'));
  $t->blockNodedata('2.10', 1, V->new('b1'));
  $t->blockNodedata('2.10', 2, V->new('b2'));
  is_deeply(sfreed { $t->delete('2.5', '2.13') }, ['b2'],
	    'all the leaves under the last node of level 2 deleted: the joined values');
  @of = $t->blockOf('2.1');
  is_deeply($of[4], [[[3, 0]]], 'one node on each level left') or diag explain \@of;
  is(nv($t, '2.2', 1) . ',' . nv($t, '2.2', 2), 'b1,a2',
     'level 1 took the value of the last node, level 2 kept its own');
  $t->destroy;
}

# ---------------------------------------------------------------------
# N4: trim; N6: split.
{
  my $t = fraction();
  $t->blockNodedata('2.2', -1, V->new('root'));
  is_deeply(freed { $t->blockSplit('2.2', 1) }, [], 'splitting frees nothing');
  is(nv($t, '2.2', -1), 'root', 'the root value moves to the new root');
  ok(!defined $t->blockNodedata('2.2', -2), 'the old root has none now');
  ok(!defined $t->blockNodedata('2.5', -2), 'nor the new node after the cut');
  $t->destroy;

  # A root with one child (two subtrees merged), trimmed.
  for my $rootValue (1, 0) {
    $t = fraction();
    $t->blockSplit('2.6', 1);		# {num|d|en}
    $t->delete('2.3', '2.8');		# {nun}: the root has one child
    $t->blockNodedata('2.2', -1, V->new('root')) if $rootValue;
    $t->blockNodedata('2.2', -2, V->new('child'));
    if ($rootValue) {
      is_deeply(freed { $t->blockTrim('2.2') }, ['child'],
		'trim: the child value is freed when the root has one');
      is(nv($t, '2.2', -1), 'root', 'the new root keeps the old root value');
    } else {
      is_deeply(freed { $t->blockTrim('2.2') }, [], 'trim: a root without value');
      is(nv($t, '2.2', -1), 'child', 'the new root keeps its own value');
    }
    is_deeply([($t->blockOf('2.1'))[4]], [[3]], 'one level less');
    $t->destroy;
  }

  $t = fraction();
  $t->blockNodedata('2.2', 0, V->new('num'));
  $t->blockSplit('2.2', 0);
  is($t->get('2.0', '2.end'), '{n|um|den}', 'split at level 0');
  is(nv($t, '2.1', 0), 'num', 'the first part keeps the value');
  ok(!defined $t->blockNodedata('2.3', 0), 'the second part has none');
  $t->insert('2.4', "\n");		# a typed newline: the same
  ok(!defined $t->blockNodedata('2.5', 0), 'nor a part made by a newline');
  $t->destroy;
}

# ---------------------------------------------------------------------
# N4: block insert inside a block.
{
  my $t = fraction();
  $t->insert('2.4', "\nmid");		# {num|mid|den}
  $t->blockNodedata('2.2', 0, V->new('num'));
  $t->blockNodedata('2.6', 0, V->new('mid'));
  $t->blockNodedata('2.10', 0, V->new('den'));
  $t->blockConfigure('G');
  is_deeply(freed { $t->blockInsert('G', '2.2', '2.10') }, ['den'],
	    'block insert: the cut last leaf joins the first, its value is freed');
  is($t->get('2.0', '2.end'), '{n{um|mid|d}en}', 'the new block');
  is(nv($t, '2.1', 0), 'num', 'the part left keeps the value of the first leaf');
  ok(!defined $t->blockNodedata('2.3', 0), 'the moved part of a cut leaf has none');
  is(nv($t, '2.6', 0), 'mid', 'a whole leaf moved keeps its value');
  is(nv($t, '2.12', 0), 'num', 'the part left after the new block is the same leaf');
  $t->destroy;

  # Whole leaves moved, the first included.
  $t = fraction();
  $t->insert('2.4', "\nmid");		# {num|mid|den}
  $t->blockNodedata('2.2', 0, V->new('num'));
  $t->blockNodedata('2.6', 0, V->new('mid'));
  $t->blockNodedata('2.10', 0, V->new('den'));
  $t->blockConfigure('G');
  is_deeply(freed { $t->blockInsert('G', '2.1', '2.9') }, [],
	    'block insert of whole leaves frees nothing');
  is($t->get('2.0', '2.end'), '{{num|mid|}den}', 'the new block');
  is(nv($t, '2.2', 0), 'num', 'the first leaf moved whole: its value moved with it');
  is(nv($t, '2.6', 0), 'mid', 'so did the second');
  is(nv($t, '2.12', 0), 'den', 'the leaf left whole keeps its value');
  is(nv($t, '2.1', 0), 'den', '(it starts with the new block)');
  $t->destroy;

  # Nodes left without children disappear.
  $t = fraction();
  $t->blockSplit('2.6', 1);
  $t->blockSplit('2.3', 1);		# {nu|m|d|en}: [[nu], [m, d], [en]]
  $t->blockNodedata('2.4', 1, V->new('middle'));
  $t->blockNodedata('2.9', 1, V->new('last'));
  $t->blockNodedata('2.9', 0, V->new('n'));
  $t->blockConfigure('G');
  is_deeply(sfreed { $t->blockInsert('G', '2.2', '2.10') }, [qw(last middle)],
	    'block insert across nodes (it used to crash): the emptied nodes go, with their values');
  my @of = $t->blockOf('2.1');
  is_deeply($of[4], [[11]], 'the enclosing block has one leaf and one node left')
    or diag explain \@of;
  is($t->get('2.0', '2.end'), '{n{u|m|d|en}}', 'the text');
  is(nv($t, '2.10', 0), 'n', 'the last leaf, moved whole, keeps its value in the new block');
  ok(!defined $t->blockNodedata('2.1', 0), 'the leaf holding the new block has none');
  $t->destroy;
}

# ---------------------------------------------------------------------
# F3: with undo, the values go to the undo step.
{
  my $t = fraction(-undo => 1);
  $t->editReset;
  $t->blockNodedata('2.2', 0, V->new('num'));
  $t->blockNodedata('2.6', 0, V->new('den'));
  $t->blockNodedata('2.6', -1, V->new('root'));
  is_deeply(freed { $t->delete('2.0', '2.9') }, [], 'deleting the block keeps its values');
  is_deeply(freed { $t->editUndo }, [], 'undo frees nothing');
  is(nv($t, '2.2', 0), 'num', 'undo gives the leaf its value back');
  is(nv($t, '2.6', 0), 'den', 'and the other leaf');
  is(nv($t, '2.6', -1), 'root', 'and the root');
  is_deeply(freed { $t->editRedo }, [], 'redo keeps them in the step again');
  is_deeply([$t->blockOf('2.1')], [], 'the block is gone again');
  is_deeply(sfreed { $t->editReset }, [qw(den num root)],
	    'edit reset frees them');
  $t->destroy;

  # A merge, undone: the loser comes back, and so does a moved value.
  $t = fraction(-undo => 1);
  $t->blockSplit('2.6', 1);		# {num|d|en}
  $t->editReset;
  $t->blockNodedata('2.2', 0, V->new('num'));
  $t->blockNodedata('2.8', 0, V->new('n'));
  $t->blockNodedata('2.8', 1, V->new('node2'));
  is_deeply(freed { $t->delete('2.2', '2.8') }, [], 'a merge with undo frees nothing');
  is(nv($t, '2.3', 1), 'node2', 'the first node had no value: it took the second one');
  is_deeply(freed { $t->editUndo }, [], 'undo');
  is($t->get('2.0', '2.end'), '{num|d|en}', 'the text is back');
  is(nv($t, '2.2', 0), 'num', 'the first leaf');
  is(nv($t, '2.8', 0), 'n', 'the merged-away leaf has its value back');
  is(nv($t, '2.8', 1), 'node2', 'the merged-away node has its value back');
  ok(!defined $t->blockNodedata('2.2', 1), 'the first node is without value again');

  # -maxundo: the oldest step goes, with its values.
  $t->configure(-maxundo => 1);
  $t->delete('2.2', '2.9');		# drops n (and node2 moves)
  $t->editSeparator;
  is_deeply(freed { $t->insert('1.0', 'x'); $t->editSeparator }, [qw(n)],
	    '-maxundo: the step pushed out frees its values')
    or diag "@log";
  is_deeply(sfreed { $t->destroy; $mw->update }, [qw(node2 num)],
	    'the widget destroyed frees the values of the nodes');
}

{
  # The undo of an insertion; the redo history dropped by a new edit.
  my $t = fraction(-undo => 1);
  $t->editReset;
  $t->insert('2.3', "\nnew");		# {nu|newm|den}
  is($t->get('2.0', '2.end'), '{nu|newm|den}', 'a new leaf');
  $t->blockNodedata('2.5', 0, V->new('new'));
  $t->blockNodedata('2.1', 0, V->new('nu'));
  is_deeply(freed { $t->editUndo }, [], 'undoing the insertion keeps the value');
  is($t->get('2.0', '2.end'), '{num|den}', 'the leaf is gone');
  is_deeply(freed { $t->editRedo }, [], 'redo');
  is(nv($t, '2.5', 0), 'new', 'the redone insertion gives the value back');
  is(nv($t, '2.1', 0), 'nu', 'the leaf before keeps its own');
  $t->editUndo;
  is_deeply(freed { $t->insert('1.0', 'q') }, ['new'],
	    'a new edit drops the redo history, and frees its values');
  is_deeply(freed { $t->destroy; $mw->update }, ['nu'], 'the rest goes with the widget');
}

{
  # Values in the undo history when the widget goes.
  my $t = fraction(-undo => 1);
  $t->blockNodedata('2.2', 0, V->new('num'));
  $t->delete('2.0', '2.9');
  is_deeply(freed { $t->destroy; $mw->update }, ['num'],
	    'destroying the widget frees the values in its undo history');
}

{
  # A deletion that cuts a block: the values of a block nested in what
  # is left of it survive, and the undo list holds no extra reference.
  my $t = $mw->eText(-undo => 1)->pack;
  $t->blockConfigure('F');
  $t->blockConfigure('G');
  $t->insert('end', "ab\nxyz\nuv\n");
  $t->blockInsert('G', '2.1', '2.2');	# x{y}z
  $t->blockInsert('F', '2.0', '3.2');	# {x{y}z|uv}
  is($t->get('2.0', '2.end'), '{x{y}z|uv}', 'a nested block');
  $t->editReset;
  $t->blockNodedata('2.3', 0, V->new('y'));
  $t->blockNodedata('2.8', 0, V->new('uv'));
  $t->blockNodedata('2.8', 1, V->new('Froot'));
  is_deeply(sfreed { $t->delete('1.1', '2.2') }, [],
	    'deleting the head of the outer block');
  is($t->get('1.0', '2.0'), "a{y}z\n", 'the nested block is left');
  is(nv($t, '1.2', 0), 'y', 'with its value');
  is_deeply(freed { $t->editUndo }, [], 'undo');
  is($t->get('1.0', '2.end'), "ab\n{x{y}z|uv}", 'the outer block is back');
  is(nv($t, '2.3', 0), 'y', 'the nested block value is in the restored nested block');
  is(nv($t, '2.8', 0), 'uv', 'the outer block leaf value is back');
  is(nv($t, '2.8', -1), 'Froot', 'the outer block root value is back');
  is_deeply(freed { $t->blockNodedata('2.3', 0, undef) }, ['y'],
	    'the undo history holds no copy of a value');
  $t->destroy;
}

{
  # The same, when what is left of the cut block spans lines (its
  # leaves become lines), the nested block on the second one.
  my $t = $mw->eText(-undo => 1)->pack;
  $t->blockConfigure('F');
  $t->blockConfigure('G');
  $t->insert('end', "ab\nxw\nuyv\n");
  $t->blockInsert('G', '3.1', '3.2');	# u{y}v
  $t->blockInsert('F', '2.0', '3.5');	# {xw|u{y}v}
  is($t->get('2.0', '2.end'), '{xw|u{y}v}', 'a nested block in the second leaf');
  $t->editReset;
  $t->blockNodedata('2.6', 0, V->new('y'));
  $t->blockNodedata('2.6', 1, V->new('Groot'));
  $t->blockNodedata('2.4', 0, V->new('uv'));
  is_deeply(freed { $t->delete('1.1', '2.2') }, [], 'deleting the head of the outer block');
  is($t->get('1.0', '3.0'), "aw\nu{y}v\n", 'its second leaf is a line now');
  is(nv($t, '2.2', 0), 'y', 'the nested block keeps its value');
  is_deeply(freed { $t->editUndo }, [], 'undo');
  is($t->get('1.0', '2.end'), "ab\n{xw|u{y}v}", 'the outer block is back');
  is(nv($t, '2.6', 0), 'y', 'the nested leaf value is back in place');
  is(nv($t, '2.6', 1), 'Groot', 'and the nested root value');
  is(nv($t, '2.4', 0), 'uv', 'and the outer leaf value');
  is_deeply(freed { $t->editRedo }, [], 'redo');
  is(nv($t, '2.2', 0), 'y', 'the nested block keeps its value again');
  is_deeply(freed { $t->editReset }, ['uv'], 'reset frees the value in the history');
  is_deeply(sfreed { $t->destroy; $mw->update }, [qw(Groot y)], 'the widget the others');
}

{
  # Cutting the tail of the outer block, the nested block before the
  # deletion.
  my $t = $mw->eText(-undo => 1)->pack;
  $t->blockConfigure('F');
  $t->blockConfigure('G');
  $t->insert('end', "ab\nxyz\nuv\n");
  $t->blockInsert('G', '2.1', '2.2');
  $t->blockInsert('F', '2.0', '3.2');	# {x{y}z|uv}
  $t->editReset;
  $t->blockNodedata('2.3', 0, V->new('y'));
  $t->blockNodedata('2.3', -1, V->new('Groot'));
  $t->blockNodedata('2.1', -1, V->new('Froot'));
  is_deeply(freed { $t->delete('2.8', '2.10') }, [], 'deleting the tail of the outer block');
  is($t->get('2.0', '4.0'), "x{y}z\nu\n", 'what is left');
  is(nv($t, '2.2', 0), 'y', 'the nested block keeps its value');
  is_deeply(freed { $t->editUndo }, [], 'undo');
  is($t->get('2.0', '2.end'), '{x{y}z|uv}', 'the outer block is back');
  is(nv($t, '2.3', 0), 'y', 'the nested leaf value is back in place');
  is(nv($t, '2.3', -1), 'Groot', 'and the nested root value');
  is(nv($t, '2.1', -1), 'Froot', 'and the outer root value');
  is_deeply(sfreed { $t->destroy; $mw->update }, [qw(Froot Groot y)], 'the widget frees them');
}

# ---------------------------------------------------------------------
# Round trips: an edit and its undo (and redo) give every node back its
# value, at leaf starts and ends and at node boundaries; Enter then
# Backspace without undo too.
{
  # The values of the whole tree, as the block list writes them.
  my $shape = sub {
    my ($t) = @_;
    my ($b) = $t->blockList('2.0', '2.end');
    my $walk; $walk = sub { my $n = shift;
			    '(' . join(' ', map { ref $_ eq 'ARRAY' ? $walk->($_)
						  : ref $_ ? $_->{n} : defined $_ ? $_ : '-' } @$n) . ')' };
    return $t->get('2.0', '2.end') . ' ' . $walk->($b->[0][3] || []);
  };
  # {num|d|en} with two subtrees, a value on every node.
  my $make = sub {
    my $t = fraction(@_);
    $t->debug(1);
    $t->blockSplit('2.6', 1);
    $t->blockNodedata('2.2', 0, V->new('num'));
    $t->blockNodedata('2.5', 0, V->new('d'));
    $t->blockNodedata('2.8', 0, V->new('en'));
    $t->blockNodedata('2.2', 1, V->new('N1'));
    $t->blockNodedata('2.8', 1, V->new('N2'));
    $t->blockNodedata('2.8', 2, V->new('R'));
    $t->editReset;
    return $t;
  };
  my @edits = (
    ['Enter at the start of a leaf', sub { $_[0]->insert('2.5', "\n") }],
    ['Enter at the end of a leaf', sub { $_[0]->insert('2.6', "\n") }],
    ['Enter at the start of a node', sub { $_[0]->insert('2.7', "\n") }],
    ['Enter at the start of the block', sub { $_[0]->insert('2.1', "\n") }],
    ['Enter at the end of the block', sub { $_[0]->insert('2.9', "\n") }],
    ['Backspace at the start of a leaf', sub { $_[0]->delete('2.4') }],
    ['Backspace at the start of a node', sub { $_[0]->delete('2.6') }],
    ['deleting the text of a leaf', sub { $_[0]->delete('2.5') }],
    ['deleting a leaf with its separator', sub { $_[0]->delete('2.4', '2.6') }],
    ['deleting a node with its separator', sub { $_[0]->delete('2.6', '2.9') }],
    ['deleting across a node boundary', sub { $_[0]->delete('2.3', '2.8') }],
    ['typing at a leaf start', sub { $_[0]->insert('2.5', "xy\nz") }],
  );
  for my $e (@edits) {
    my ($what, $code) = @$e;
    my $t = $make->(-undo => 1);
    my $before = $shape->($t);
    is_deeply(freed { $code->($t) }, [], "$what: frees nothing (undo on)");
    my $after = $shape->($t);
    is_deeply(freed { $t->editUndo }, [], "$what: undo");
    is($shape->($t), $before, "$what: undo gives every value back");
    $t->editRedo;
    is($shape->($t), $after, "$what: redo gives the state after the edit");
    $t->editUndo;
    is($shape->($t), $before, "$what: and undo again the state before");
    $t->destroy;
  }
  {
    # Several edits in one undo step.
    my $t = $make->(-undo => 1, -autoseparators => 0);
    my $before = $shape->($t);
    $t->insert('2.5', "\n");
    $t->insert('2.5', 'X');
    $t->delete('2.6');
    $t->insert('2.4', "\nY");
    $t->delete('2.2', '2.4');
    my $after = $shape->($t);
    is_deeply(freed { $t->editUndo }, [], 'a compound step: undo');
    is($shape->($t), $before, 'a compound step: every value back where it was');
    is_deeply(freed { $t->editRedo }, [], 'redo');
    is($shape->($t), $after, 'redo: the state after the step');
    $t->destroy;
  }
  my $t = $make->();
  my $before = $shape->($t);
  for my $i ('2.5', '2.6', '2.7', '2.2') {
    $t->insert($i, "\n");
    is_deeply(freed { $t->delete($i) }, [], "Enter then Backspace at $i frees nothing");
    is($shape->($t), $before, "and leaves every value where it was");
  }
  $t->destroy;
}

# ---------------------------------------------------------------------
# block insert of whole leaves: the last one moves with its value, as
# the first one does.
for my $case (['1.4', '1.12', [], '{aa|{bb|cc|dd}|ee}', undef],
	      ['1.3', '1.12', [], '{aa{|bb|cc|dd}|ee}', 'aa'],
	      ['1.5', '1.12', [], '{aa|b{b|cc|dd}|ee}', 'bb'],
	      ['1.4', '1.11', [], '{aa|{bb|cc|d}d|ee}', 'dd']) {
  my ($i1, $i2, $freed, $text, $outer) = @$case;
  my $t = $mw->eText->pack;
  $t->debug(1);
  $t->blockConfigure('F');
  $t->blockConfigure('G');
  $t->insert('end', "aa\nbb\ncc\ndd\nee\n");
  $t->blockInsert('F', '1.0', '5.2');	# {aa|bb|cc|dd|ee}
  my %pos = (aa => '1.1', bb => '1.4', cc => '1.7', dd => '1.10', ee => '1.13');
  $t->blockNodedata($pos{$_}, 0, V->new($_)) for keys %pos;
  is_deeply(freed { $t->blockInsert('G', $i1, $i2) }, $freed, "block insert $i1 $i2: frees nothing");
  is($t->get('1.0', '1.end'), $text, 'the text');
  is(nv($t, $t->index("1.0 + @{[index($text, 'cc')]} c"), 0), 'cc', 'the middle leaf in the new block');
  my $d = index($text, '{', 1);		# the head of G
  is(nv($t, "1.$d", 0), $outer, 'the leaf holding the new block');
  if ($i2 eq '1.12') {
    is(nv($t, '1.' . (index($text, 'dd') + 1), 0), 'dd', 'the whole last leaf moved with its value');
  } else {
    ok(!defined $t->blockNodedata('1.' . index($text, 'd}'), 0),
       'the moved part of the cut last leaf starts without a value');
  }
  $t->destroy;
}

# ---------------------------------------------------------------------
# Undo re-creates a block whose root has a single child that is not a
# leaf with its full depth (the separators alone give one level less).
{
  my $t = fraction(-undo => 1);
  $t->debug(1);
  $t->blockSplit('2.6', 1);		# {num|d|en}, the root two levels up
  $t->delete('2.4', '2.7');		# {numen}: root -> one node -> one leaf
  my ($block) = $t->blockList('2.0', '2.end');
  is($block->[0][1], 1, 'a block of depth 1 with a single leaf');
  undef $block;
  $t->blockNodedata('2.2', -1, V->new('R'));
  $t->blockNodedata('2.2', -2, V->new('C'));
  $t->editReset;
  is_deeply(freed { $t->delete('2.0', '2.end') }, [], 'deleting the block');
  is_deeply(freed { $t->editUndo }, [], 'undo');
  ($block) = $t->blockList('2.0', '2.end');
  is($block->[0][1], 1, 'the block is re-created with its depth');
  undef $block;
  is(nv($t, '2.2', -1), 'R', 'the root has its value');
  is(nv($t, '2.2', -2), 'C', 'its child has its own');
  is(nv($t, '2.2', 1), 'C', 'one level above the leaf');
  is_deeply(sfreed { $t->destroy; $mw->update }, ['C', 'R'], 'the widget frees them');
}

# ---------------------------------------------------------------------
# More than 64 blocks cut by one deletion: the values in what is left
# of them (a nested block) come back with the undo.
{
  my $t = $mw->eText(-undo => 1)->pack;
  $t->blockConfigure('F');
  $t->blockConfigure('G');
  $t->insert('end', "axc\n");
  $t->blockInsert('G', '1.1', '1.2');	# a{x}c
  $t->blockInsert('F', '1.1', '1.' . (5 + 2 * ($_ - 1))) for 1 .. 70;
  my $s = $t->get('1.0', '1.end');
  my ($x, $c) = (index($s, 'x'), index($s, 'c'));
  $t->blockNodedata("1.$x", 0, V->new('gx'));
  $t->blockNodedata("1.$x", -1, V->new('groot'));
  $t->editReset;
  is_deeply(freed { $t->delete("1.$c", '1.' . length($s)) }, [], '70 blocks cut');
  is($t->get('1.0', '1.end'), 'a{x}', 'dissolved, the nested block left');
  is_deeply(freed { $t->editUndo }, [], 'undo');
  is($t->get('1.0', '1.end'), $s, 'the 70 blocks are back');
  is(nv($t, "1.$x", 0), 'gx', 'the nested leaf has its value');
  is(nv($t, "1.$x", -1), 'groot', 'and the nested root');
  $t->destroy;
}

# ---------------------------------------------------------------------
# The block list of part of a block leaves the node values out (they
# follow the whole tree).
{
  my $t = fraction();
  $t->blockNodedata('2.2', 0, 'n');
  my ($b) = $t->blockList('2.0', '2.end');
  is($b->[0][3][1][0], 'n', 'the whole block: with the values');
  ($b) = $t->blockList('2.0', '2.6');
  is(scalar @{$b->[0]}, 2, 'part of it: the header has no values');
  ($b) = $t->blockList('2.2', '2.end');
  is(scalar @{$b->[0]}, 2, 'the other part neither');
  $t->destroy;
}

# ---------------------------------------------------------------------
# The instance data of a block the B-tree code deletes is freed when the
# command ends, too (its DESTROY may use the widget).
{
  my $t = fraction(-undo => 0);
  my $end;
  $t->blockData('2.2', V->new('inst', sub { $end = $t->index('end') }));
  is_deeply(freed { $t->delete('2.0', '3.0') }, ['inst'], 'deleting a block frees its instance data');
  is($end, '4.0', 'when the deletion is done');
  $t->insert('2.0', "num\nden\n");
  $t->blockInsert('F', '2.0', '3.3');
  $t->blockData('2.2', V->new('inst2', sub { $end = $t->get('2.0', '2.end') }));
  is_deeply(freed { $t->delete('2.0', '2.1') }, ['inst2'], 'dissolving a block (its head deleted)');
  is($end, 'num', 'when the dissolution is done');
  $t->insert('3.0', "x\n");
  $t->blockInsert('F', '3.0', '3.1');
  $t->blockData('3.1', V->new('inst3', sub { $end = eval { $t->index('end') } || 'gone' }));
  is_deeply(freed { $t->destroy; $mw->update }, ['inst3'], 'destroying the widget');
  is($end, 'gone', 'after it is gone');
}

# ---------------------------------------------------------------------
# Leaks.
SKIP: {
  skip 'Test::LeakTrace not installed', 1 unless $have_lt;
  my $t = fraction(-undo => 1);
  Test::LeakTrace::leaks_cmp_ok(sub {
    $t->blockNodedata('2.2', 0, V->new('a'));
    $t->blockNodedata('2.6', -1, { x => [1] });
    my @l = $t->blockList('2.0', '2.end');
    $t->delete('2.2', '2.6');
    $t->editUndo;
    $t->delete('2.0', '2.9');
    $t->editUndo;
    $t->editReset;
  }, '<', 5, 'node values: no leaks');
  $t->destroy;
}

$mw->destroy;
