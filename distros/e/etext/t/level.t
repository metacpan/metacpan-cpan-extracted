#!/usr/bin/perl
# "block level index ?level?": the depth of a separator that exists, and
# its change without moving text: the values of the leaves and nodes
# stay.
use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require Tk; 1 } or plan skip_all => "Tk not available: $@";
}
use Tk::eText;
use Data::Dumper;
$Data::Dumper::Indent = 0; $Data::Dumper::Terse = 1;

my $mw = eval { MainWindow->new };
plan skip_all => "no X display available ($@)" unless $mw;
plan tests => 60;
$mw->geometry('+10+10');

my $t;
sub widget {
  $t->destroy if $t;
  $t = $mw->eText(-width => 80, -height => 6, @_)->pack;
  $t->blockConfigure($_) for qw(F G T);
  $t->debug(1);
  $t;
}
sub show {
  my $out = '';
  for my $e (@_) {
    my $c = ref $e;
    if ($c eq 'Tk::Text::String') { (my $s = $$e) =~ s/\n//; $out .= $s }
    elsif ($c eq 'Tk::Text::NewLine') { $out .= '\n' }
    elsif ($c eq 'Tk::Text::BlockSeparator') {
      $out .= '|' . (UNIVERSAL::isa($e, 'ARRAY') ? Dumper([@$e]) : $$e) . ' ' }
    elsif ($c eq 'Tk::Text::Block') {
      $out .= "{$e->[0][0]:$e->[0][1]:" . Dumper($e->[0][3]) . ' ' . show(@$e[1 .. $#$e]) . '}' }
  }
  $out;
}
sub state { show($t->blockList('1.0', 'end - 1 c')) }
sub dies_like { my ($code, $re, $name) = @_;
		my $ok = !eval { $code->(); 1 }; like($ok ? $@ : 'no error', $re, $name) }

# {a|b||c|d} on line 1: two rows of two cells, values on the cells b, c,
# d, on both rows and on the root.  The separators are at 1.2, 1.4, 1.6.
sub table {
  widget(@_);
  $t->insert('1.0', 'abcd');
  $t->blockInsert('T', '1.0', '1.4');
  $t->blockSplit('1.4', 0);
  $t->blockSplit('1.3', 1);
  $t->blockSplit('1.2', 0);
  $t->blockNodedata('1.3', 0, 'B'); $t->blockNodedata('1.5', 0, 'C');
  $t->blockNodedata('1.7', 0, 'D');
  $t->blockNodedata('1.1', 1, 'ROW1'); $t->blockNodedata('1.5', 1, 'ROW2');
  $t->blockNodedata('1.1', 2, 'ROOT');
  $t->editReset;
}
my $table = q({T:1:['ROOT',['ROW1',[undef],['B']],['ROW2',['C'],['D']]] a|0 b|1 c|0 d});

# ---------------------------------------------------------------------
# 1. Reading.
{
  table(-undo => 1);
  is(state(), $table, 'a table: two rows of two cells');
  is($t->blockLevel('1.2'), 0, 'a cell separator: depth 0');
  is($t->blockLevel('1.4'), 1, 'the row separator: depth 1');
  is($t->blockLevel('1.6'), 0, 'the second cell separator');
  dies_like(sub { $t->blockLevel('1.1') }, qr/^bad index "1\.1": no separator of a block there/,
	    'a character of a leaf is not a separator');
  dies_like(sub { $t->blockLevel('1.0') }, qr/no separator of a block there/, 'nor is the head');
  dies_like(sub { $t->blockLevel('1.8') }, qr/no separator of a block there/, 'nor the tail');
  dies_like(sub { $t->blockLevel('1.9') }, qr/no separator of a block there/,
	    'nor a newline of the text');
  dies_like(sub { $t->block('level') }, qr/wrong # args.*block level index \?level\?/, 'wrong # args');
  dies_like(sub { $t->blockLevel('1.2', 'x') }, qr/numeric|integer/i, 'a level that is not a number');
  dies_like(sub { $t->blockLevel('1.2', -1) }, qr/^bad level "-1": must not be negative/,
	    'a negative level');
  dies_like(sub { $t->blockLevel('nowhere') }, qr/bad text index/, 'a bad index');
  is(state(), $table, 'nothing changed');
  ok(!eval { $t->editUndo; 1 }, 'and nothing recorded');
}

# ---------------------------------------------------------------------
# 2. Raising: the nodes that hold both leaves are cut; the first part
# keeps the value, the second starts without one.  No text moves.
{
  table(-undo => 1);
  $t->blockLevel('1.2', 1);
  is(state(), q({T:1:['ROOT',['ROW1',[undef]],[undef,['B']],['ROW2',['C'],['D']]] a|1 b|1 c|0 d}),
     'a cell separator made a row separator: three rows, every value where it was');
  is($t->get('1.0', '1.end'), '{a|b|c|d}', 'the text is the same');
  is($t->blockLevel('1.2'), 1, 'block level reads the new depth');
  $t->editUndo;
  is(state(), $table, 'undo');
  $t->editRedo;
  is(state(), q({T:1:['ROOT',['ROW1',[undef]],[undef,['B']],['ROW2',['C'],['D']]] a|1 b|1 c|0 d}),
     'redo');
  $t->editUndo;

  # Above the root: nodes are inserted below it, as for block split.
  $t->blockLevel('1.4', 2);
  is(state(), q({T:2:['ROOT',[undef,['ROW1',[undef],['B']]],[undef,['ROW2',['C'],['D']]]] a|0 b|2 c|0 d}),
     'raised above the root: a new level below the root, which keeps its value');
  $t->editUndo;
  is(state(), $table, 'undo takes the new level away');
  $t->editRedo;
  $t->editUndo;
  is(state(), $table, 'redo and undo again');

  # The same depth: nothing happens.
  $t->blockLevel('1.4', 1);
  is(state(), $table, 'the depth it has: no change');
  ok(!eval { $t->editUndo; 1 }, 'nothing recorded');
}

# ---------------------------------------------------------------------
# 3. Lowering: the nodes are joined as a deletion of the separator would
# join them; the start side's value stays, the end side's goes into the
# undo step (or moves, if the start side has none).
{
  table(-undo => 1);
  $t->blockLevel('1.4', 0);
  is(state(), q({T:1:['ROOT',['ROW1',[undef],['B'],['C'],['D']]] a|0 b|0 c|0 d}),
     'the row separator made a cell separator: one row of four cells; ROW2 is gone');
  is(nvl('1.5', 0), 'C', 'the cell after it keeps its value (the leaves are not joined)');
  $t->editUndo;
  is(state(), $table, 'undo: two rows, ROW2 is back');
  $t->editRedo;
  is(state(), q({T:1:['ROOT',['ROW1',[undef],['B'],['C'],['D']]] a|0 b|0 c|0 d}), 'redo');
  $t->editUndo;

  $t->blockNodedata('1.1', 1, undef);
  $t->blockLevel('1.4', 0);
  is(state(), q({T:1:['ROOT',['ROW2',[undef],['B'],['C'],['D']]] a|0 b|0 c|0 d}),
     'the first row had no value: the joined row takes that of the second');
  $t->editUndo;
  is(state(), q({T:1:['ROOT',[undef,[undef],['B']],['ROW2',['C'],['D']]] a|0 b|1 c|0 d}),
     'undo moves it back');
}
sub nvl { my $v = eval { $t->blockNodedata(@_) }; defined $v ? $v : '-' }

# Against the old way, the separator deleted and made again: that loses
# the value of the leaf after it.
{
  table(-undo => 1);
  $t->delete('1.4');
  $t->blockSplit('1.4', 0);
  is(state(), q({T:1:['ROOT',['ROW1',[undef],['B'],[undef],['D']]] a|0 b|0 c|0 d}),
     'delete and block split: the same tree, but C is gone with ROW2');
  $t->editUndo; $t->editUndo;
  $t->blockLevel('1.4', 0);
  is(state(), q({T:1:['ROOT',['ROW1',[undef],['B'],['C'],['D']]] a|0 b|0 c|0 d}),
     'block level: C stays');
}

# ---------------------------------------------------------------------
# 4. Undo steps: changes of level in a row are one step (a kind of edit
# of its own for -autoseparators).
{
  table(-undo => 1);
  $t->blockLevel('1.2', 1);
  $t->blockLevel('1.6', 1);
  is(state(), q({T:1:['ROOT',['ROW1',[undef]],[undef,['B']],['ROW2',['C']],[undef,['D']]] a|1 b|1 c|1 d}),
     'two cell separators raised: four rows');
  $t->editUndo;
  is(state(), $table, 'one undo step for both');
  $t->editRedo;
  $t->insert('1.1', 'x');
  $t->blockLevel('1.3', 0);
  $t->editUndo;
  is(state(), q({T:1:['ROOT',['ROW1',[undef]],[undef,['B']],['ROW2',['C']],[undef,['D']]] xa|1 b|1 c|1 d}),
     'after an insertion a change of level is a step of its own');
  ok($t->editModified, 'it counts for edit modified');
}

# ---------------------------------------------------------------------
# 5. A tree whose leaves are at different depths: a lowering never
# joins padding.
{
  widget(-undo => 1);
  $t->insert('1.0', 'x23');
  $t->blockInsert('F', '1.0', '1.3');
  $t->blockSplit('1.2', 0);			# {x|23}
  $t->blockSprout('1.3');			# R( x | S( 23 ) )
  $t->blockSplit('1.4', 0);			# R( x | S( 2 | 3 ) ): {x|2|3}
  $t->editReset;
  my $s0 = state();
  like($s0, qr/^\{F:1:.* \|\[undef,1\] x\|1 2\|0 3\}$/, "a ragged tree: $s0");
  is($t->blockLevel('1.2'), 1, 'the separator after the shallow leaf: depth 1');
  dies_like(sub { $t->blockLevel('1.2', 0) },
	    qr/^bad level "0": a leaf beside the separator at 1\.2 has no node of its own below level 1 \(block sprout gives it one\)/,
	    'lowering it to 0 is refused: the leaf x has no node of its own');
  is(state(), $s0, 'nothing changed');
  $t->blockSprout('1.1');			# R( X( x ) | S( 2 | 3 ) )
  $t->blockLevel('1.2', 0);
  is($t->get('1.0', '1.end'), '{x|2|3}', 'after block sprout of x it is done');
  is(Dumper(($t->blockAt('1.0'))[4]), '[[1,1,1]]', 'one node with three leaves');
  $t->editUndo; $t->editUndo;
  is(state(), $s0, 'both undone: the ragged tree');
  $t->blockLevel('1.4', 1);
  is(Dumper(($t->blockAt('1.0'))[4]), '[1,[1],[1]]', 'raising inside the deeper part: R( x | S( 2 ) | S( 3 ) )');
  $t->editUndo;
  is(state(), $s0, 'undone');
}

# ---------------------------------------------------------------------
# 6. -valuecommand.
{
  my @events;
  table(-undo => 1, -valuecommand => sub {
	  my ($w, $event, $kind, $where, $value, $cause) = @_;
	  push @events, "$cause: $event " . (defined $value ? $value : 'undef') . ' at '
	    . join(' ', map { ref $_ ? "[@$_]" : $_ } @$where) });
  @events = ();
  $t->blockLevel('1.2', 1);
  is("@events", 'block level: new undef at 1.3 1',
     'raising: the node made is told "new", with its place');
  @events = ();
  $t->blockLevel('1.4', 2);
  is(join('; ', @events),
     'block level: new undef at 1.1 2; block level: new undef at 1.5 2',
     'above the root: the node inserted below it, and its second half');
  @events = ();
  $t->editUndo;
  is("@events", '', 'the undo of a raise tells nothing');
  @events = ();
  $t->blockLevel('1.4', 0);
  is("@events", 'block level: stash ROW2 at 1.5 1', 'lowering: the value that loses the join is stashed');
  @events = ();
  $t->editUndo;
  is("@events", 'undo: restore ROW2 at 1.5 1', 'and restored by the undo');
  $t->blockNodedata('1.1', 1, undef);
  @events = ();
  $t->blockLevel('1.4', 0);
  is("@events", 'block level: move ROW2 at 1.5 1 [1.1 1]', 'or moved, when the start side has none');
  $t->configure(-undo => 0);
  $t->blockLevel('1.4', 1);
  $t->blockNodedata('1.5', 1, 'NEW');
  @events = ();
  $t->blockLevel('1.4', 0);
  is("@events", 'block level: drop NEW at 1.5 1', 'without -undo it is dropped');
}

# ---------------------------------------------------------------------
# 7. Random documents (all leaves of a block equally deep), a random
# separator, a random depth: only that separator changes, the text does
# not, no value is lost by a raise, and undo and redo are exact.
{
  widget(-undo => 1);
  srand(1113);
  my $val = 0;
  my $leaves = sub {
    my $head = shift;
    my @r = $t->blockAt("1.$head");
    my ($pos, @l) = ($head + 1);
    my $walk; $walk = sub { for my $c (@{$_[0]}) {
      if (ref $c) { $walk->($c) } else { push @l, [$pos, $c]; $pos += $c + 1 } } };
    $walk->(ref $r[4] ? $r[4] : [$r[4]]);
    @l;
  };
  my $seps = sub {			# [position, depth] of every separator on line 1.
    my (@s, $pos);
    my $walk; $walk = sub {
      for my $e (@_) {
	my $c = ref $e;
	if ($c eq 'Tk::Text::String') { $pos += length $$e }
	elsif ($c eq 'Tk::Text::BlockSeparator') {
	  push @s, [$pos, UNIVERSAL::isa($e, 'ARRAY') ? $e->[0] : $$e]; $pos++ }
	elsif ($c eq 'Tk::Text::Block') { $pos++; $walk->(@$e[1 .. $#$e]); $pos++ }
      }
    };
    $pos = 0;
    $walk->($t->blockList('1.0', '1.end'));
    @s;
  };
  my $vals = sub { my $s = state(); my @v = $s =~ /'(v\d+)'/g; join ' ', sort @v };
  my ($tried, $only, $text, $kept, $undo, $raise, $lower, @bad) = (0) x 7;
  for my $doc (1 .. 80) {
    $t->delete('1.0', 'end');
    my $n = 14 + int rand 8;
    $t->insert('1.0', join '', map chr(97 + int rand 26), 1 .. $n);
    my $a = 1 + int rand 3;
    $t->blockInsert('F', "1.$a", '1.' . ($n - 1 - int rand 3));
    for (1 .. 2 + int rand 6) {
      my $len = ($t->blockAt("1.$a"))[1];
      $t->blockSplit('1.' . ($a + 1 + int rand($len - 1)), int rand 3);
    }
    for my $l ($leaves->($a)) {
      for (my $level = 0; ; $level++) {
	last unless eval { $t->blockNodedata("1.$l->[0]", $level); 1 };
	next if rand() < 0.25;
	$t->blockNodedata("1.$l->[0]", $level, 'v' . $val++)
	  unless defined $t->blockNodedata("1.$l->[0]", $level);
      }
    }
    $t->editReset;
    for (1 .. 6) {
      my @s = $seps->();
      my $k = int rand @s;
      my ($pos, $old) = @{$s[$k]};
      my $new = int rand 4;
      my ($s0, $g0, $v0) = (state(), $t->get('1.0', '1.end'), $vals->());
      is($t->blockLevel("1.$pos"), $old, 'block level reads what block list shows') if $doc == 1 and $_ == 1;
      $t->blockLevel("1.$pos", $new);
      my ($s1, $v1) = (state(), $vals->());
      my @s1 = $seps->();
      $tried++;
      $new > $old ? $raise++ : $new < $old ? $lower++ : 0;
      my $same = @s1 == @s && !grep { $s1[$_][0] != $s[$_][0]
				      || $s1[$_][1] != ($_ == $k ? $new : $s[$_][1]) } 0 .. $#s;
      $only++ if $same;
      $text++ if $t->get('1.0', '1.end') eq $g0;
      $kept++ if $new < $old or $v1 eq $v0;
      my $ok = 1;
      if ($new != $old) {
	$t->editUndo; $ok &&= state() eq $s0;
	$t->editRedo; $ok &&= state() eq $s1;
	$t->editUndo; $ok &&= state() eq $s0;
	$t->editRedo;
      }
      $undo++ if $ok;
      push @bad, "document $doc, separator at $pos from $old to $new" unless $same and $ok;
      $t->editReset if rand() < 0.5;
    }
  }
  cmp_ok($raise, '>', 100, "$tried changes: $raise raise the depth");
  cmp_ok($lower, '>', 100, "$lower lower it");
  is($only, $tried, 'only that separator changes its depth');
  is($text, $tried, 'the text stays');
  is($kept, $tried, 'a raise loses no value');
  is($undo, $tried, 'undo and redo are exact');
  is("@bad[0 .. ($#bad > 4 ? 4 : $#bad)]", '', 'no failures');
}

$t->destroy;
