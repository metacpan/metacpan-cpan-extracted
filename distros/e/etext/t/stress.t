#!/usr/bin/perl
# Crashes found by random sequences of block editing and undo, each
# reduced to a minimal script; then a bounded random run over a fixed
# list of seeds (among them the ones that crashed).  The B-tree is
# checked after every change (debug 1): an inconsistency panics, which
# ends this test file.
use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require Tk; 1 } or plan skip_all => "Tk not available: $@";
}
use Tk::eText;

my $mw = eval { MainWindow->new };
plan skip_all => "no X display available ($@)" unless $mw;
plan tests => 36;
$mw->geometry('+10+10');

my $t = $mw->eText(-undo => 1, -width => 40, -height => 10)->pack;
$t->blockConfigure('F');
$t->blockConfigure('G');
$t->blockConfigure('E', -empty => 1);
$t->debug(1);

# Start again from the given text, with empty undo stacks.
sub fresh {
  $t->delete('1.0', 'end');
  $t->editReset;
  $t->insert('1.0', $_[0]) if length $_[0];
}
sub text { my $s = $t->get('1.0', 'end'); $s =~ s/\n\n\z/\n/; $s }


# A. "block split" put its newline in without telling the display: the
# top index and the display lines kept byte offsets into the line it cut
# short, and the next redisplay (here the "see" of the undo) walked off
# the end of the line.  (The undo itself deletes the recorded range of
# the insertion, stale since the split was not recorded.)
fresh('');
$t->insert('1.0', 'ab');
$t->editUndo;
$t->editRedo;
$t->blockSplit('1.0', 0);
is(text(), "\nab\n", 'A: block split outside blocks inserts a newline');
ok(eval { $t->editUndo; 1 }, 'A: the redisplay after it survives');

# B. "block insert" of an empty range at the start of a line split the
# line there twice, each time putting a new empty segment in front of
# it, and took the first of them for the contents of the block: moved
# into the tree of an -empty block, which has none (a NULL dereference).
fresh("abc\ndef\n");
$t->blockInsert('E', '1.0');
is(text(), ".abc\ndef\n", 'B: empty block at the start of the first line');
$t->blockInsert('E', '2.0');
is(text(), ".abc\n.def\n", 'B: empty block at the start of another line');
$t->blockInsert('F', '1.0');
is(text(), "{}.abc\n.def\n", 'B: block with one empty leaf at the start of a line');
$t->blockInsert('E', '1.1');
is(text(), "{.}.abc\n.def\n", 'B: empty block at the start of a leaf');

# C. "block insert" with its second index before the first one cut the
# text apart ("Ran out of lines in TkBTreeMakeBlock").
fresh("abc\ndef\n");
ok(!eval { $t->blockInsert('F', '2.1', '1.1'); 1 },
   'C: block insert with the end before the start is an error');
like($@, qr/^block insert: index "1\.1" is before "2\.1"/, 'C: which says so');
is(text(), "abc\ndef\n", 'C: and changes nothing');

# D. A deletion from the tail of a nested block to beyond the tail of
# the block around it: the tail of the inner block is not deleted (the
# block is dissolved at the end of the deletion), but the split made to
# start the deletion there was left in its line meanwhile, and the
# checks of the deletions that followed found an empty segment
# ("CharCheckProc: segment has size <= 0") or two unmerged ones.
fresh("ab\ncd\n");
$t->blockInsert('F', '1.1');
$t->blockInsert('F', '1.0', '1.4');
is(text(), "{a{}b}\ncd\n", 'D: an empty leaf in a block');
$t->delete('1.3', '1.6');
is(text(), "a\ncd\n", 'D: deleting both tails dissolves both blocks');
$t->editUndo;
is(text(), "{a{}b}\ncd\n", 'D: and the undo brings them back');
fresh("abc\n");
$t->blockInsert('F', '1.1', '1.2');
$t->blockInsert('F', '1.0', '1.5');
$t->delete('1.4', '1.7');
is(text(), "ab\n", 'D: same with text in the inner block');
$t->editUndo;
is(text(), "{a{b}c}\n", 'D: and its undo');

# E. Deleting an -empty block inside another block took its index unit
# off the outer block's length twice: the outer block lost its last
# character, and deleting it later panicked ("IBTree length updated to
# negative value").
fresh("abc\ndef\n");
$t->blockInsert('F', '2.0', '2.3');
$t->blockInsert('E', '2.2');
$t->delete('2.2');
is(text(), "abc\n{def}\n", 'E: deleting an empty block inside a block');
$t->blockInsert('E', '2.2');
$t->blockInsert('E', '2.4');
is(text(), "abc\n{d.e.f}\n", 'E: two empty blocks inside a block');
$t->delete('2.2', '2.5');
is(text(), "abc\n{df}\n", 'E: deleting both with the text between');
$t->blockInsert('E', '2.2');
$t->delete('2.0', '2.end');
is(text(), "abc\n\n", 'E: deleting the block around one');

# F. An undefined index: the index parser wrote its null byte into the
# argument's string, the constant "" of undef (a segfault).
ok(!eval { $t->index(undef); 1 }, 'F: an undefined index is an error');
like($@, qr/^bad text index ""/, 'F: a bad index');
ok(!eval { $t->delete('1.0', undef); 1 }, 'F: for delete too');

# G. "block list" (and so the undo record of a deletion) from just
# after a block reported an empty piece of that block and its last
# newline: the undo of the deletion put a stray block in.
fresh("abcd\nxy\n");
$t->blockInsert('F', '1.1', '1.4');
is_deeply([map { ref } $t->blockList('1.6', '2.2')],
	  [qw(Tk::Text::String Tk::Text::NewLine Tk::Text::String)],
	  'G: block list from just after a block');
$t->delete('1.6', '2.end');
$t->editUndo;
is(text(), "a{bcd}\nxy\n", 'G: undo of a deletion starting just after a block');

# H. The undo of a deletion re-created a block of the deleted range at
# the recorded index even when that is "end" now (the change that made
# it so was not recorded): on the last, dummy, line ("TkBTreeCheck: last
# line has bogus segment type").
fresh("ab\ncd");
$t->blockInsert('E', '2.1');
$t->delete('2.1');
$t->configure(-undo => 0);
$t->delete('1.2', '2.end');
$t->configure(-undo => 1);
$t->editUndo;
is(text(), "ab.\n", 'H: an undo re-creating a block at the end');

# I. A deletion joining leaves of different nodes of a block glues the
# nodes, but the glued node kept only its own tag summary: the toggles
# of the lines it took in were no longer counted ("CheckNodeConsistency:
# mismatch in toggleCount", and crashes in later tag operations).
fresh('');
$t->blockInsert('F', '1.0');
$t->insert('1.1', 'ab', 'c');
$t->blockSplit('1.2', 2);
$t->blockSplit('1.1', 1);
$t->blockSplit('1.4', 1);
is(text(), "{|a||b}\n", 'I: a tagged block split at several levels');
$t->delete('1.2', '1.4');
is(text(), "{||b}\n", 'I: a deletion gluing its nodes');
is_deeply([$t->tagRanges('c')], ['1.2', '1.4'], 'I: the tag is still on the separator and b');

# J. A deletion joining the line of a block to the line before it
# takes the block's tag toggles off the counts (the block's line
# changes), rebalances, and only then cleans up the line and counts them
# again.  Meanwhile a node merge counted the block anyway, more toggles
# than the tag's total, so the tag's root was not moved to the merged
# node and stayed on the node the merge freed (a segfault at the next
# toggle count change).  Here the newline makes the 13th line, which
# splits the root node; deleting it merges the two nodes again.
fresh("z\n" x 10);
$t->tagAdd('b', '10.0', '10.1');
$t->blockInsert('F', '1.0');
$t->tagAdd('b', '1.1', '1.2');
$t->insert('1.0', "\n");
$t->delete('1.0', '2.0');
is_deeply([$t->tagRanges('b')], [qw(1.1 1.2 10.0 10.1)],
	  'J: a tag in a block, after a node split and merge');

# K. A deletion that dissolves a block (here: its head and a separator)
# first deletes the part inside, without rebalancing; it joined two
# leaves of different nodes without gluing the nodes (gluing was done
# only when rebalancing), and left a node without children in the tree:
# the dissolution walked into it (a segfault).
fresh("xy\n");
$t->blockInsert('F', '1.1');
$t->blockSplit('1.2', 1);
$t->blockSplit('1.2', 1);
is(text(), "x{||}y\n", 'K: three leaves in three nodes');
$t->delete('1.1', '1.3');
is(text(), "x\ny\n", 'K: deleting the head and a separator dissolves the block');
$t->editUndo;
is(text(), "x{||}y\n", 'K: and the undo brings it back');

# A bounded random run: the generators of the scripts that found the
# crashes, without the values (every crash happened without them too),
# and one that does everything; the seeds include the ones that crashed.
# Errors the commands may give for a random index are expected.
my $expected = qr/nothing to (un|re)do|Attempt|block|Cannot trim|IBTree/;
my @unexpected;

sub random_index { my ($lines, $cols) = @_; (1 + int rand $lines) . '.' . int rand $cols }

sub ordered {
  my ($a, $b) = @_;
  ($a, $b) = ($b, $a) if $t->compare($a, '>', $b);
  return ($a, $b);
}

sub run_op {
  my ($what, $code) = @_;
  eval { $code->(); 1 } or do {
    push @unexpected, "$what: $@" unless $@ =~ $expected;
  };
}

sub initial_text {
  my ($lines, $min, $more) = @_;
  join("\n", map { join '', map { chr(97 + int rand 26) } 1 .. ($min + int rand $more) } 1 .. $lines) . "\n";
}

# Block insert, split, deletion and insertion, undo and redo.
sub run_blocks {
  my $seed = shift;
  srand($seed);
  fresh(initial_text(6, 5, 10));
  for my $step (1 .. 300) {
    my $op = int rand 12;
    my ($a, $b) = ordered(random_index(6, 14), random_index(6, 14));
    my $lv = int(rand 3) - 1; my $r2 = int rand 4; my $r3 = int rand 2;
    run_op("blocks $seed step $step op $op", sub {
      if ($op <= 1) { $t->delete($a, $b) }
      elsif ($op == 2) { $t->insert($a, ('x', 'yy', 'z\nw', "\n")[$r2]) }
      elsif ($op == 3) { $t->editUndo }
      elsif ($op == 4) { $t->editRedo }
      elsif ($op == 7) { $t->editSeparator }
      elsif ($op == 8) {
	$t->blockInsert(('F', 'G')[$r3], $a, $b)
	  if $t->compare($b, '<=', $t->index("$a lineend"));
      }
      elsif ($op == 9) { $t->blockSplit($a, $r3) }
      elsif ($op == 10) { $t->delete($a) }
      elsif ($op == 11) { $t->insert($a, "\n") }
    });
  }
}

# Tags, deletion and insertion, undo and redo, now and then a block.
sub run_tags {
  my $seed = shift;
  srand($seed);
  fresh(initial_text(6, 5, 10));
  for my $step (1 .. 400) {
    my $op = int rand 11;
    my ($a, $b) = ordered(random_index(6, 12), random_index(6, 12));
    my $tag = ('b', 'c')[int rand 2];
    run_op("tags $seed step $step op $op", sub {
      if ($op == 0) { $t->tagAdd($tag, $a, $b) }
      elsif ($op == 1) { $t->tagRemove($tag, $a, $b) }
      elsif ($op == 2 || $op == 3) { $t->delete($a, $b) }
      elsif ($op == 4) { $t->insert($a, ('x', 'yy', 'z\nw')[int rand 3], (rand() > .5 ? $tag : ())) }
      elsif ($op == 5) { $t->editUndo }
      elsif ($op == 6) { $t->editRedo }
      elsif ($op == 7 || $op == 8) { my @r = $t->tagRanges($tag); rand(@r / 2) if @r }
      elsif ($op == 9) { $t->editSeparator }
      elsif ($op == 10) {
	if (rand() < .3) {
	  $t->blockInsert('F', $a, $b) if $t->compare($b, '<=', $t->index("$a lineend"));
	}
      }
    });
  }
}

# All of it, with -empty blocks, multi-level splits, trim and tags.
sub run_mixed {
  my $seed = shift;
  srand($seed);
  fresh(initial_text(5, 3, 8));
  for my $step (1 .. 300) {
    my $op = int rand 16;
    my ($a, $b) = ordered(random_index(5, 14), random_index(5, 14));
    my $r = int rand 4; my $tag = ('b', 'c')[int rand 2];
    run_op("mixed $seed step $step op $op", sub {
      if ($op <= 1) { $t->delete($a, $b) }
      elsif ($op == 2) { $t->insert($a, ('x', 'yy', "z\nw", "\n")[$r]) }
      elsif ($op == 3 || $op == 12) { $t->editUndo }
      elsif ($op == 4) { $t->editRedo }
      elsif ($op == 5) { $t->editSeparator }
      elsif ($op == 6) {
	$t->blockInsert(('F', 'G')[$r % 2], $a, $b)
	  if $t->compare($b, '<=', $t->index("$a lineend"));
      }
      elsif ($op == 7) { $t->blockInsert(('F', 'G', 'E', 'E')[$r], $a) }
      elsif ($op == 8) { $t->blockSplit($a, $r) }
      elsif ($op == 9) { $t->blockTrim($a) }
      elsif ($op == 10) { $t->delete($a) }
      elsif ($op == 11) { $t->tagAdd($tag, $a, $b) }
      elsif ($op == 13) { $t->tagRemove($tag, $a, $b) }
      elsif ($op == 14) { $t->insert($a, 'ab', $tag) }
      elsif ($op == 15) {
	$t->blockInsert('F', $a, $b)
	  if $t->compare($b, '<=', $t->index("$a lineend")) && $r == 0;
      }
    });
  }
}

# Since 2.04 block insert, split and trim, tag add and remove are
# undoable: all of them, with values on nodes, runs and marks, and
# many undos and redos; the B-tree check runs after every change, and
# no value is freed twice (its DESTROY method counts).
my (%alive, $twice);
{
  package StressValue;
  sub new { $alive{$_[1]} = 1; bless { n => $_[1] }, $_[0] }
  sub DESTROY { $twice++ unless delete $alive{$_[0]{n}} }
}
my $nvalue = 0;
sub run_undoable {
  my $seed = shift;
  srand($seed);
  fresh(initial_text(5, 3, 8));
  for my $step (1 .. 300) {
    my $op = int rand 17;
    my ($a, $b) = ordered(random_index(5, 14), random_index(5, 14));
    my $r = int rand 4; my $tag = ('b', 'c')[int rand 2];
    run_op("undoable $seed step $step op $op", sub {
      if ($op <= 1) { $t->delete($a, $b) }
      elsif ($op == 2) { $t->insert($a, ('x', 'yy', "z\nw", "\n")[$r], ($r % 2 ? $tag : ())) }
      elsif ($op == 3 || $op == 4) { $t->editUndo }
      elsif ($op == 5) { $t->editRedo }
      elsif ($op == 6) {
	$t->blockInsert(('F', 'G')[$r % 2], $a, $b)
	  if $t->compare($b, '<=', $t->index("$a lineend"));
      }
      elsif ($op == 7) { $t->blockInsert(('F', 'G', 'E', 'E')[$r], $a) }
      elsif ($op == 8) { $t->blockSplit($a, $r % 3) }
      elsif ($op == 9) { $t->blockTrim($a) }
      elsif ($op == 10) { $t->tagAdd($tag, $a, $b) }
      elsif ($op == 11) { $t->tagRemove($tag, $a, $b) }
      elsif ($op == 12) { $t->blockNodedata($a, $r % 3 - 1, StressValue->new('n' . ++$nvalue)) }
      elsif ($op == 13) {
	my @rr = $t->tagRanges($tag);
	$t->tagData($tag, $rr[2 * int rand(@rr / 2)], StressValue->new('r' . ++$nvalue)) if @rr;
      }
      elsif ($op == 14) { $t->markSet("m$r", $a); $t->markData("m$r", StressValue->new('m' . ++$nvalue)) }
      elsif ($op == 15) { $t->editSeparator }
      elsif ($op == 16) { $t->delete($a) }
    });
  }
  $t->editReset;
}
$expected = qr/$expected|no run of tag|not inside a block|bad level/;

# Ragged trees (2.06): block sprout and block flatten among the edits, with values on
# nodes, undo and redo; the B-tree check includes the rules of the
# padding nodes.
#
# Every structural change there is also checked for an exact undo and
# redo (2.06, step 2): the state before it (the block list of the text
# with the node values and marks, and the shape of every block, "block
# at", which together give the padding of the stored tree) comes back
# with its undo, the state after it with its redo, then again.
use Data::Dumper;
use Scalar::Util ();
my @inexact;
my $exact_checks = 0;
sub norm_list {
  my @o;
  for my $e (@_) {
    my $r = ref $e;
    if ($r =~ /Mark/) {
      my $n = Scalar::Util::reftype($e) eq 'ARRAY' ? $e->[0] : $$e;
      push @o, $e unless $n =~ /^(insert|current)$/;
    } elsif ($r =~ /::String$/) {
      if (@o && !ref $o[-1]) { $o[-1] .= $$e } else { push @o, $$e }
    } elsif ($r =~ /::NewLine$/) {
    } elsif ($r =~ /::Block$/) {
      push @o, [ 'B', $e->[0], norm_list(@$e[1 .. $#$e]) ];
    } else {
      push @o, $e;
    }
  }
  # Toggles and marks at one position: their order does not matter.
  my @r;
  while (@o) {
    my @run;
    push @run, shift @o while @o && ref $o[0] && ref($o[0]) =~ /Tag|Mark/;
    push @r, sort { Data::Dumper::Dumper($a) cmp Data::Dumper::Dumper($b) } @run;
    push @r, shift @o if @o && !@run;
  }
  @r;
}
sub exact_state {
  local $Data::Dumper::Indent = 0;
  local $Data::Dumper::Sortkeys = 1;
  my $s = Dumper([norm_list($t->blockList('1.0', 'end'))]);
  my $lines = (split /\./, $t->index('end'))[0];
  for my $l (1 .. $lines) {
    for my $c (0 .. (split /\./, $t->index("$l.end"))[1]) {
      my @r = $t->blockAt("$l.$c");
      $s .= " $l.$c:" . Dumper($r[4]) if @r;
    }
  }
  $s;
}
sub exact_op {
  my ($what, $code) = @_;
  $t->editSeparator;
  my $s0 = exact_state();
  $code->();
  my $s1 = exact_state();
  return if $s1 eq $s0;
  $exact_checks++;
  for my $round (1, 2) {
    $t->editUndo;
    return push @inexact, "$what: undo $round" if exact_state() ne $s0;
    $t->editRedo;
    return push @inexact, "$what: redo $round" if exact_state() ne $s1;
  }
}

sub run_ragged {
  my $seed = shift;
  srand($seed);
  fresh(initial_text(5, 3, 8));
  for my $step (1 .. 300) {
    my $op = int rand 18;
    my ($a, $b) = ordered(random_index(5, 14), random_index(5, 14));
    my $r = int rand 4;
    my $check = ($op <= 8 || $op == 13 || $op == 14 || $op >= 16) && rand() < .5;
    run_op("ragged $seed step $step op $op", $check ? sub {
      exact_op("ragged $seed step $step op $op", sub {
	if ($op <= 1) { $t->blockSprout($a, $t->index("$a + $r c")) }
	elsif ($op == 2) { $t->blockSprout($a) }
	elsif ($op == 3) { $t->blockSprout($t->index("$a - 1 c"), $t->index("$a + $r c")) }
	elsif ($op <= 5) { $t->delete($a, $b) }
	elsif ($op == 6) { $t->delete($a, $t->index("$a + $r c")) }
	elsif ($op == 7) { $t->insert($a, ('x', "\n", "y\nz", "\n\n")[$r]) }
	elsif ($op == 8) { $t->blockSplit($a, $r) }
	elsif ($op == 13) {
	  $t->blockInsert(('F', 'G')[$r % 2], $a, $b)
	    if $t->compare($b, '<=', $t->index("$a lineend"));
	}
	elsif ($op == 14) { $t->blockTrim($a) }
	else { $t->blockFlatten($a, $r - ($op - 16) * 4) }
      });
    } : sub {
      if ($op <= 1) { $t->blockSprout($a, $t->index("$a + $r c")) }
      elsif ($op == 2) { $t->blockSprout($a) }
      elsif ($op == 3) { $t->blockSprout($t->index("$a - 1 c"), $t->index("$a + $r c")) }
      elsif ($op <= 5) { $t->delete($a, $b) }
      elsif ($op == 6) { $t->delete($a, $t->index("$a + $r c")) }
      elsif ($op == 7) { $t->insert($a, ('x', "\n", "y\nz", "\n\n")[$r]) }
      elsif ($op == 8) { $t->blockSplit($a, $r) }
      elsif ($op == 9 || $op == 10) { $t->editUndo }
      elsif ($op == 11) { $t->editRedo }
      elsif ($op == 12) { $t->blockNodedata($a, $r - 1, StressValue->new('n' . ++$nvalue)) }
      elsif ($op == 13) {
	$t->blockInsert(('F', 'G')[$r % 2], $a, $b)
	  if $t->compare($b, '<=', $t->index("$a lineend"));
      }
      elsif ($op == 14) { $t->blockTrim($a) }
      elsif ($op >= 16) { $t->blockFlatten($a, $r - ($op - 16) * 4) }
      else { $t->editSeparator }
    });
  }
  $t->editReset;
}

my @block_seeds = (1 .. 12, 37, 63, 66, 86, 89, 113, 116, 130, 175, 306, 418, 447);
my @tag_seeds = (1 .. 6, 27, 297, 431);
my @mixed_seeds = (1 .. 10, 104, 146, 239, 291, 5087, 5218, 5466);
run_blocks($_) for @block_seeds;
run_tags($_) for @tag_seeds;
run_mixed($_) for @mixed_seeds;
is_deeply(\@unexpected, [], 'random runs: no unexpected error')
  or diag(join "\n", @unexpected[0 .. ($#unexpected > 9 ? 9 : $#unexpected)]);
@unexpected = ();
run_undoable($_) for 1 .. 12;
is_deeply(\@unexpected, [], 'random runs of the undoable block and tag changes: no unexpected error')
  or diag(join "\n", @unexpected[0 .. ($#unexpected > 9 ? 9 : $#unexpected)]);
@unexpected = ();
run_ragged($_) for 1 .. 12;
is_deeply(\@unexpected, [], 'random runs on ragged trees (block sprout, flatten): no unexpected error')
  or diag(join "\n", @unexpected[0 .. ($#unexpected > 9 ? 9 : $#unexpected)]);
is_deeply(\@inexact, [], "random runs on ragged trees: undo and redo exact ($exact_checks changes)")
  or diag(join "\n", @inexact[0 .. ($#inexact > 9 ? 9 : $#inexact)]);
ok(!$twice, "no value freed twice ($nvalue values made)");

$t->destroy;
$mw->destroy;
