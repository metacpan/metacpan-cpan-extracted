#!/usr/bin/perl
# Representation B of the containers of values (tkTextData.h, built
# with ETEXT_DATA_ARRAYS=1 perl Makefile.PL): a slot other than the
# Perl value (a TK_TEXT_DATA_INT, set through the test hook
# "_dataslot", which only B has) travels with the container: it
# survives drop -> undo -> redo and the merges (N5 keeps the first
# container present, whole), it stays when only the Perl value is set
# to undef, and every container is freed exactly once.  Skipped with
# representation A (the default), which has no such slots.
use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require Tk; 1 } or plan skip_all => "Tk not available: $@";
}
use Tk::eText;

my $mw = eval { MainWindow->new };
plan skip_all => "no X display available ($@)" unless $mw;
$mw->geometry('+10+10');

# A widget that never has data: it reads the number of data blocks
# alive in the process.
my $probe = $mw->eText;
unless (eval { $probe->WidgetMethod('_dataslot', 'live'); 1 }) {
  $probe->destroy;
  $mw->destroy;
  plan skip_all => 'representation A (the default build): no slots but the Perl value';
}
plan tests => 140;

sub live { $probe->WidgetMethod('_dataslot', 'live') }
sub ds { my $t = shift; $t->WidgetMethod('_dataslot', @_) }

my %destroyed;			# DESTROY count per name
{
  package V;
  sub new { my ($class, $name) = @_; bless { n => $name }, $class }
  sub DESTROY { $destroyed{$_[0]{n}}++ }
}
sub nv { my $v = shift; defined $v ? (ref $v ? $v->{n} : $v) : undef }

# A text with a two-leaf block (a fraction) on line 2:
#   line 1 "ab", line 2 "{num|den}" (head 2.0, num 2.1-2.3 and its
#   separator 2.4, den 2.5-2.7 and the tail 2.8), line 3 "cd".
sub fraction {
  my $t = $mw->eText(-width => 30, -height => 6, -autoseparators => 0, @_)->pack;
  $t->blockConfigure('F');
  $t->insert('end', "ab\nnum\nden\ncd\n");
  $t->blockInsert('F', '2.0', '3.3');
  $t->editReset;
  return $t;
}

my $base = live();
is($base, 0, 'no data block alive at first');

# ---------------------------------------------------------------------
# The hook itself, and the Perl value as one part of the container.
{
  my $t = fraction();
  is(ds($t, 'node', '2.2', 0), undef, 'no slot at first');
  ds($t, 'node', '2.2', 0, 11);
  is(ds($t, 'node', '2.2', 0), 11, 'an INT slot on a leaf');
  is(live(), $base + 1, 'one data block');
  ok(!defined $t->blockNodedata('2.2', 0), 'the Perl value is still undef');
  $t->blockNodedata('2.2', 0, V->new('a'));
  is(nv($t->blockNodedata('2.2', 0)), 'a', 'the Perl value set beside it');
  is(ds($t, 'node', '2.2', 0), 11, 'the slot is still there');
  is(live(), $base + 1, 'in the same block');
  $t->blockNodedata('2.2', 0, undef);
  is($destroyed{a}, 1, 'setting undef frees the Perl value, once');
  is(ds($t, 'node', '2.2', 0), 11, 'and leaves the slot');
  is(live(), $base + 1, 'and the block');
  my ($block) = $t->blockList('2.0', '2.end');
  is(scalar @{$block->[0]}, 2, 'a node with only a slot has no value in block list');
  ds($t, 'node', '2.2', 0, undef);
  is(ds($t, 'node', '2.2', 0), undef, 'the slot removed');
  is(live(), $base, 'the block goes with its last slot');

  # Marks.
  $t->markSet('m', '1.1');
  $t->markData('m', V->new('m1'));
  ds($t, 'mark', 'm', 5);
  $t->markData('m', undef);
  is($destroyed{m1}, 1, 'mark data undef frees the Perl value once');
  is(ds($t, 'mark', 'm'), 5, 'and leaves the slot of the mark');
  $t->markSet('m', '3.1');
  is(ds($t, 'mark', 'm'), 5, 'the slot moves with the mark');
  ok(!defined $t->markData('m'), 'no Perl value');
  my @dump = $t->dump('-mark', '-values', '3.1');
  is_deeply([@dump[0 .. 3]], ['mark', 'm', '3.1', undef], 'dump -values shows no value');

  # Runs.
  $t->tagAdd('b', '1.0', '1.2');
  $t->tagData('b', '1.0', V->new('r1'));
  ds($t, 'run', 'b', '1.1', 6);
  $t->tagData('b', '1.1', undef);
  is($destroyed{r1}, 1, 'tag data undef frees the Perl value once');
  is(ds($t, 'run', 'b', '1.0'), 6, 'and leaves the slot of the run');

  # Blocks.
  $t->blockData('2.2', V->new('i1'));
  ds($t, 'block', '2.2', 7);
  $t->blockData('2.2', undef);
  is($destroyed{i1}, 1, 'block data undef frees the Perl value once');
  is(ds($t, 'block', '2.2'), 7, 'and leaves the slot of the block');
  ($block) = $t->blockList('2.0', '2.end');
  is(scalar @{$block->[0]}, 2, 'instance data with only a slot is not in block list');
  is(live(), $base + 3, 'three blocks: mark, run, block');
  $t->destroy;
  $mw->update;
  is(live(), $base, 'all freed with the widget');
}

# ---------------------------------------------------------------------
# A node's container survives drop -> undo -> redo.
{
  my $t = fraction(-undo => 1);
  ds($t, 'node', '2.2', 0, 11);			# num: a slot only
  ds($t, 'node', '2.6', 0, 22);			# den: a slot and a value
  $t->blockNodedata('2.6', 0, V->new('den'));
  ds($t, 'node', '2.2', 1, 33);			# the root: a slot only
  is(live(), $base + 3, 'three containers');
  $t->delete('2.4', '2.8');			# "|den": the leaf den goes
  $t->editSeparator;
  is($t->get('2.0', '2.end'), '{num}', 'the leaf den deleted');
  is(ds($t, 'node', '2.2', 0), 11, 'num keeps its slot');
  is(ds($t, 'node', '2.2', 1), 33, 'and the root its slot');
  ok(!$destroyed{den}, 'the dropped container is kept by the undo');
  is(live(), $base + 3, 'and stays alive');
  $t->editUndo;
  is($t->get('2.0', '2.end'), '{num|den}', 'undo: den is back');
  is(ds($t, 'node', '2.6', 0), 22, 'with its slot');
  is(nv($t->blockNodedata('2.6', 0)), 'den', 'and its Perl value');
  is(ds($t, 'node', '2.2', 0), 11, 'num as it was');
  $t->editRedo;
  is($t->get('2.0', '2.end'), '{num}', 'redo: den deleted again');
  ok(!$destroyed{den}, 'its container is kept again');
  $t->editUndo;
  is(ds($t, 'node', '2.6', 0), 22, 'undo again: the slot is back');
  is(nv($t->blockNodedata('2.6', 0)), 'den', 'with the value');
  is(live(), $base + 3, 'no container made or lost on the way');

  # A container with only a slot is dropped and given back whole too.
  $t->blockNodedata('2.6', 0, undef);
  is($destroyed{den}, 1, 'the value freed once');
  $t->delete('2.4', '2.8');
  $t->editSeparator;
  $t->editUndo;
  is(ds($t, 'node', '2.6', 0), 22, 'a slot-only container comes back with undo');
  $t->editReset;
  $t->destroy;
  $mw->update;
  is(live(), $base, 'all freed with the widget');
}

# ---------------------------------------------------------------------
# Merges of nodes: N5 keeps the first container present, whole.
{
  my $t = fraction(-undo => 1);
  ds($t, 'node', '2.2', 0, 11);			# num: a slot only
  ds($t, 'node', '2.6', 0, 22);			# den: a slot and a value
  $t->blockNodedata('2.6', 0, V->new('d2'));
  $t->delete('2.4', '2.5');			# the separator: one leaf
  $t->editSeparator;
  is($t->get('2.0', '2.end'), '{numden}', 'the leaves joined');
  is(ds($t, 'node', '2.2', 0), 11, 'the joined leaf keeps the first container');
  ok(!defined $t->blockNodedata('2.2', 0), 'whole: no Perl value from the second');
  ok(!$destroyed{d2}, 'the second, dropped, is kept by the undo');
  $t->editUndo;
  is(ds($t, 'node', '2.2', 0), 11, 'undo: num as it was');
  is(ds($t, 'node', '2.6', 0), 22, 'den has its slot back');
  is(nv($t->blockNodedata('2.6', 0)), 'd2', 'and its value');
  $t->editRedo;
  is(ds($t, 'node', '2.2', 0), 11, 'redo: the first container again');

  # The first empty: the second moves to the joined leaf.  (An undo
  # takes the separator below the step it undoes, as in Tk: a new
  # step needs one of its own.)
  $t->editUndo;
  $t->editSeparator;
  ds($t, 'node', '2.2', 0, undef);
  $t->delete('2.4', '2.5');
  $t->editSeparator;
  is(ds($t, 'node', '2.2', 0), 22, 'the first empty: the joined leaf takes the second');
  is(nv($t->blockNodedata('2.2', 0)), 'd2', 'whole, with its value');
  $t->editUndo;
  is(ds($t, 'node', '2.2', 0), undef, 'undo moves it back: num has none');
  is(ds($t, 'node', '2.6', 0), 22, 'den has it');
  is(nv($t->blockNodedata('2.6', 0)), 'd2', 'with its value');
  $t->editReset;
  $t->destroy;
  $mw->update;
  is($destroyed{d2}, 1, 'the value freed once, with the widget');
  is(live(), $base, 'all containers freed');
}

# ---------------------------------------------------------------------
# Runs: dropped with the run and given back; merged by N5.
{
  my $t = fraction(-undo => 1);
  $t->tagAdd('b', '1.0', '1.1');
  $t->tagAdd('b', '3.0', '3.1');
  $t->editSeparator;
  ds($t, 'run', 'b', '1.0', 1);			# a slot only
  ds($t, 'run', 'b', '3.0', 2);			# a slot and a value
  $t->tagData('b', '3.0', V->new('r2'));
  $t->tagRemove('b', '1.0', '1.1');		# the whole first run
  $t->editSeparator;
  is_deeply([$t->tagRanges('b')], ['3.0', '3.1'], 'the first run removed');
  $t->editUndo;
  is(ds($t, 'run', 'b', '1.0'), 1, 'undo: its slot is back');
  $t->editRedo;
  $t->editUndo;
  is(ds($t, 'run', 'b', '1.0'), 1, 'after redo and undo again');
  $t->editSeparator;
  $t->tagAdd('b', '1.0', '3.1');		# one run from 1.0 to 3.1
  $t->editSeparator;
  is_deeply([$t->tagRanges('b')], ['1.0', '3.1'], 'the runs merged');
  is(ds($t, 'run', 'b', '3.0'), 1, 'the merged run keeps the first container');
  ok(!defined $t->tagData('b', '3.0'), 'whole: no value from the second');
  ok(!$destroyed{r2}, 'the second is kept by the undo');
  $t->editUndo;
  is(ds($t, 'run', 'b', '1.0'), 1, 'undo: the first run as it was');
  is(ds($t, 'run', 'b', '3.0'), 2, 'the second has its slot back');
  is(nv($t->tagData('b', '3.0')), 'r2', 'and its value');
  $t->editReset;
  $t->destroy;
  $mw->update;
  is($destroyed{r2}, 1, 'the run value freed once');
  is(live(), $base, 'all containers freed');
}

# ---------------------------------------------------------------------
# The instance data of a block: block insert keeps it in its undo atom.
{
  my $t = fraction(-undo => 1);
  $t->blockInsert('F', '1.0', '1.2');
  $t->editSeparator;
  ds($t, 'block', '1.1', 9);
  $t->blockData('1.1', V->new('i9'));
  $t->editUndo;					# dissolves the new block
  is($t->get('1.0', '1.end'), 'ab', 'undo: the block is dissolved');
  ok(!$destroyed{i9}, 'its instance data is kept by the undo atom');
  is(live(), $base + 1, 'the container is alive');
  $t->editRedo;
  is(ds($t, 'block', '1.1'), 9, 'redo: the block has its slot back');
  is(nv($t->blockData('1.1')), 'i9', 'and its instance data');

  # The undo of a deletion re-creates the block from its block list,
  # which leaves the instance data out: the step keeps the container,
  # and gives it back whole.
  $t->delete('1.0', '1.end');
  $t->editSeparator;
  ok(!$destroyed{i9}, 'deleting the block: the step keeps its data');
  is(live(), $base + 1, 'the container is alive');
  $t->editUndo;
  is(nv($t->blockData('1.1')), 'i9', 'undo of a deletion: the Perl value comes back');
  is(ds($t, 'block', '1.1'), 9, 'and the other slots');
  $t->editRedo;
  is(live(), $base + 1, 'redo: the step keeps the container again');
  $t->editUndo;
  is(ds($t, 'block', '1.1'), 9, 'undo again: the slot is back');
  is(nv($t->blockData('1.1')), 'i9', 'with the Perl value');
  $t->editReset;
  $t->destroy;
  $mw->update;
  is($destroyed{i9}, 1, 'the instance data freed once');
  is(live(), $base, 'all containers freed');
}

# ---------------------------------------------------------------------
# The same for blocks a deletion deletes inside another one, dissolves
# (cuts), leaves in the remains of a cut block, and for -empty blocks;
# and for the redo of an insertion, which re-inserts a block list too.
{
  my $t = fraction(-undo => 1);		# {num|den} on line 2
  $t->blockConfigure('G');
  $t->blockConfigure('E', -empty => 1);
  $t->blockInsert('G', '2.2', '2.3');		# {n{u}m|den}
  $t->blockInsert('E', '1.1');			# a.b
  $t->editReset;
  is($t->get('1.0', '3.end'), "a.b\n{n{u}m|den}\ncd", 'blocks in blocks');
  my %at = (E => '1.1', F => '2.1', G => '2.3');
  my %slot = (E => 1, F => 2, G => 3);
  for my $b (sort keys %at) {
    ds($t, 'block', $at{$b}, $slot{$b});
    $t->blockData($at{$b}, V->new("b$b")) unless $b eq 'G';	# G: a slot only
  }
  is(live(), $base + 3, 'three containers');
  my $slots = sub { join ',', map { ds($t, 'block', $at{$_}) // '-' } sort keys %at };
  is($slots->(), '1,2,3', 'their slots');
  for my $case (['1.0', '1.3', 'an -empty block'],
		['2.2', '2.5', 'a block nested in another'],
		['2.4', '3.1', 'a block cut, a nested one cut out of it'],
		['2.6', '3.1', 'a block cut, a nested one in its remains'],
		['1.2', '2.2', 'a block cut at its head'],
		['1.0', '3.1', 'all of them']) {
    my ($i1, $i2, $what) = @$case;
    $t->delete($i1, $i2);
    $t->editSeparator;
    is(live(), $base + 3, "deleting $what: no container freed");
    $t->editUndo;
    $t->editSeparator;
    is($slots->(), '1,2,3', "deleting $what: undo gives the slots back");
    $t->editRedo;
    $t->editSeparator;
    $t->editUndo;
    $t->editSeparator;
    is($slots->(), '1,2,3', "deleting $what: after redo and undo again");
    is(nv($t->blockData('2.1')), 'bF', "deleting $what: the Perl value too");
  }
  ok(!grep({ $destroyed{"b$_"} } qw(E F)), 'no value freed');
  $t->editReset;

  # An insertion holding a block (made with -undo off): its undo keeps
  # the block's container for the redo.
  $t->insert('3.1', 'XY');
  $t->configure(-undo => 0);
  $t->blockInsert('E', '3.2');			# cX.Yd
  ds($t, 'block', '3.2', 4);
  $t->configure(-undo => 1);
  is(live(), $base + 4, 'a block in the inserted text');
  $t->editUndo;
  is($t->get('3.0', '3.end'), 'cYd', 'undo of the insertion');
  is(live(), $base + 4, 'the step keeps the container');
  $t->editRedo;
  is($t->get('3.0', '3.end'), 'cX.Yd', 'redo re-inserts the block');
  is(ds($t, 'block', '3.2'), 4, 'with its slot');
  $t->editReset;
  $t->destroy;
  $mw->update;
  is($destroyed{bE} . $destroyed{bF}, '11', 'the values freed once, with the widget');
  is(live(), $base, 'all containers freed');
}

# ---------------------------------------------------------------------
# block sprout puts the former leaf's container on the start piece, the
# new node and the end piece: every slot, the Perl value shared (one
# object for the three).  Undo and redo give each container back; each
# is freed once.
{
  my $t = fraction(-undo => 1);
  my $v = V->new('sprouted');
  ds($t, 'node', '2.2', 0, 44);
  $t->blockNodedata('2.2', 0, $v);
  undef $v;
  $t->blockSprout('2.2', '2.3');			# R( n | N( u ) | m | den )
  is(ds($t, 'node', '2.1', 0), 44, 'sprout: the start piece keeps the slot');
  is(ds($t, 'node', '2.3', 1), 44, 'the new node has it');
  is(ds($t, 'node', '2.5', 0), 44, 'the end piece has it');
  is(ds($t, 'node', '2.3', 0), undef, 'the middle leaf has none');
  is(nv($t->blockNodedata('2.3', 1)), 'sprouted', 'and the Perl value');
  ok($t->blockNodedata('2.3', 1) == $t->blockNodedata('2.5', 0),
     'one object for the owners');
  is(live(), $base + 3, 'three containers');
  $t->editUndo;
  is(ds($t, 'node', '2.2', 0), 44, 'undo: the leaf has its slot');
  is($t->get('2.0', '2.end'), '{num|den}', 'and its text');
  $t->editRedo;
  is(ds($t, 'node', '2.3', 1), 44, 'redo: the new node has the slot again');
  is(ds($t, 'node', '2.5', 0), 44, 'and the end piece');
  ok(!$destroyed{sprouted}, 'the value is alive');
  $t->destroy;
  $mw->update;
  is($destroyed{sprouted}, 1, 'freed once, with the widget');
  is(live(), $base, 'all containers freed');
}

# ---------------------------------------------------------------------
# Without undo: a dropped container is freed when the command ends.
{
  my $t = fraction(-undo => 0);
  ds($t, 'node', '2.6', 0, 22);
  $t->blockNodedata('2.6', 0, V->new('x'));
  ds($t, 'node', '2.2', 1, 33);
  is(live(), $base + 2, 'two containers');
  $t->delete('2.4', '2.8');
  is($destroyed{x}, 1, 'the deletion frees the value once');
  is(live(), $base + 1, 'and its container');
  $t->delete('2.0', '3.0');			# the whole block
  is(live(), $base, 'deleting the block frees the root\'s container');
  $t->destroy;
  $mw->update;
}

is(live(), $base, 'nothing left alive');
is_deeply([grep { $destroyed{$_} != 1 } sort keys %destroyed], [],
	  'every value freed exactly once');
$probe->destroy;
$mw->destroy;
