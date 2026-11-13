#!/usr/bin/perl
# "edit step begin|end" and the method editStep: several commands as one
# undo step, the values set inside it included.
use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require Tk; 1 } or plan skip_all => "Tk not available: $@";
}
use Tk::eText;

my $mw = eval { MainWindow->new };
plan skip_all => "no X display available ($@)" unless $mw;
plan tests => 76;
$mw->geometry('+10+10');

my (@ev, @log);
{
  package SV;
  sub new { my ($class, $name) = @_; bless { n => $name }, $class }
  sub DESTROY { push @log, $_[0]{n} }
}
sub lab { my $v = shift; ref $v ? $v->{n} : defined $v ? $v : '-' }
sub ev { my @r = @ev; @ev = (); join('; ', @r) }
sub dies_like { my ($code, $re, $name) = @_;
		my $ok = !eval { $code->(); 1 }; like($ok ? $@ : 'no error', $re, $name) }

my $t;
# x{num|den}y on line 1: head 1.1, num 1.2-1.4, the separator 1.5, den
# 1.6-1.8, the tail 1.9; the tag u on "nu", the mark m before "u".
sub widget {
  $t->destroy if $t;
  $t = $mw->eText(-width => 60, -height => 5, -undo => 1, @_)->pack;
  $t->blockConfigure('F');
  $t->debug(1);
  $t->insert('1.0', 'xnumdeny');
  $t->blockInsert('F', '1.1', '1.7');
  $t->blockSplit('1.5', 0);
  $t->tagAdd('u', '1.2', '1.4');
  $t->markSet('m', '1.3');
  $t->editReset;
  @ev = (); @log = ();
  $t;
}
sub with_events {
  widget(-valuecommand => sub {
	   my ($w, $event, $kind, $where, $value, $cause) = @_;
	   push @ev, "$cause: $event $kind " . lab($value) . ' at '
	     . join(' ', map { ref $_ ? "[@$_]" : $_ } @$where) }, @_);
}
# The text and the six values.
sub st {
  my $text = $t->get('1.0', 'end - 1 c'); $text =~ s/\n/\\n/g;
  join ' ', $text,
    map(lab(scalar eval { $t->blockNodedata(@$_) }), ['1.2', 0], ['1.8', 0], ['1.2', 1]),
    'data=' . lab(scalar eval { $t->blockData('1.2') }),
    'tag=' . lab(scalar eval { $t->tagData('u', '1.2') }),
    'mark=' . lab(scalar eval { $t->markData('m') });
}
my $start = 'x{num|den}y - - - data=- tag=- mark=-';
my $set = 'x{num|den}y NUM DEN ROOT data=DATA tag=TAG mark=MARK';
sub set_all {
  $t->blockNodedata('1.2', 0, 'NUM'); $t->blockNodedata('1.8', 0, 'DEN');
  $t->blockNodedata('1.2', 1, 'ROOT'); $t->blockData('1.2', 'DATA');
  $t->tagData('u', '1.2', 'TAG'); $t->markData('m', 'MARK');
}

# ---------------------------------------------------------------------
# 1. The subcommand.
{
  widget();
  is(st(), $start, 'the text, no values');
  is($t->editStep, 0, 'no step is open');
  is($t->editStep('begin'), 1, 'edit step begin: one open');
  is($t->editStep('begin'), 2, 'again: two');
  is($t->editStep, 2, 'edit step tells how many');
  is($t->editStep('end'), 1, 'edit step end');
  is($t->editStep('end'), 0, 'and the outermost');
  dies_like(sub { $t->editStep('end') }, qr/^no edit step is open/, 'an end without a begin');
  dies_like(sub { $t->editStep('middle') }, qr/^bad edit step option "middle": must be begin or end/,
	    'a bad option');
  dies_like(sub { $t->edit('step', 'begin', 'x') }, qr/wrong # args.*edit step \?begin\|end\?/,
	    'wrong # args');
  dies_like(sub { $t->edit('nosuch') }, qr/must be modified, redo, reset, separator, step or undo/,
	    'the bad option message of edit names step');
  ok(!eval { $t->editUndo; 1 }, 'empty steps record nothing');
}

# ---------------------------------------------------------------------
# 2. Changes of different kinds are one undo step inside a step, several
# outside.
{
  widget();
  my $changes = sub {
    $t->insert('1.3', 'Z');
    $t->delete('1.9');
    $t->blockSplit('1.8', 0);
    $t->tagAdd('b', '1.6', '1.9');
    $t->blockLevel('1.8', 1);
  };
  $changes->();
  my $after = $t->get('1.0', '1.end') . ' ' . join(' ', $t->tagRanges('b'));
  is($after, 'x{nZum|d|e}y 1.6 1.9', 'five changes of five kinds');
  my $n = 0;
  $n++ while eval { $t->editUndo; 1 };
  is($n, 5, 'outside a step: five undo steps');
  is($t->get('1.0', '1.end'), 'x{num|den}y', 'all undone');

  $t->editStep('begin');
  $changes->();
  $t->editSeparator;			# Ignored inside a step.
  $t->insert('1.0', 'A');
  $t->editStep('end');
  is($t->get('1.0', '1.end'), 'Ax{nZum|d|e}y', 'the same inside a step, a separator and one more');
  $t->editUndo;
  is($t->get('1.0', '1.end') . ' ' . join(' ', $t->tagRanges('b')), 'x{num|den}y ',
     'one undo takes all of it back (edit separator inside a step does nothing)');
  ok(!eval { $t->editUndo; 1 }, 'it was one step');
  $t->editRedo;
  is($t->get('1.0', '1.end') . ' ' . join(' ', $t->tagRanges('b')), 'Ax{nZum|d|e}y 1.7 1.10',
     'one redo does all of it again');
  ok(!eval { $t->editRedo; 1 }, 'one step');

  # After the step the history goes on as before.
  $t->insert('1.0', 'B'); $t->insert('1.0', 'C');
  $t->delete('1.0');
  $t->editUndo;
  is($t->get('1.0', '1.2'), 'CB', 'after the step: a deletion is a step of its own');
  $t->editUndo;
  is($t->get('1.0', '1.end'), 'Ax{nZum|d|e}y', 'and insertions in a row are one, apart from the step before');
  $t->editUndo;
  is($t->get('1.0', '1.end'), 'x{num|den}y', 'the step itself');
}

# ---------------------------------------------------------------------
# 3. Values set inside a step are recorded; outside they are not.
{
  widget();
  set_all();
  is(st(), $set, 'six values set outside a step');
  ok(!eval { $t->editUndo; 1 }, 'nothing to undo: setting a value is not recorded');

  widget();
  $t->editStep('begin');
  set_all();
  $t->editStep('end');
  is(st(), $set, 'six values set inside a step');
  $t->editUndo;
  is(st(), $start, 'undo: none of them is left');
  $t->editRedo;
  is(st(), $set, 'redo: all six are back');
  $t->editUndo;

  # A value replaced, and a value removed.
  set_all();
  $t->editStep(sub {
    $t->blockNodedata('1.2', 0, 'NUM2'); $t->blockNodedata('1.8', 0, undef);
    $t->blockData('1.2', 'DATA2'); $t->tagData('u', '1.2', undef);
    $t->markData('m', 'MARK2');
  });
  is(st(), 'x{num|den}y NUM2 - ROOT data=DATA2 tag=- mark=MARK2', 'replaced and removed inside a step');
  $t->editUndo;
  is(st(), $set, 'undo: the old values');
  $t->editRedo;
  is(st(), 'x{num|den}y NUM2 - ROOT data=DATA2 tag=- mark=MARK2', 'redo');
  $t->editUndo;

  # A set that changes nothing is not recorded.
  $t->editReset;
  $t->editStep(sub { $t->blockNodedata('1.8', 1, 'ROOT2'); $t->blockNodedata('1.8', 1, 'ROOT') });
  $t->editStep(sub { $t->markData('nomark', undef) if 0; $t->blockNodedata('1.6', 0, 'DEN') });
  $t->editUndo;
  is(st(), $set, 'a value set twice in a step: the undo gives the first one back');
  widget();
  $t->editStep(sub { $t->blockNodedata('1.2', 0, undef) });
  ok(!eval { $t->editUndo; 1 }, 'undef set where there is no value: nothing recorded');
}

# ---------------------------------------------------------------------
# 4. With the text: a block made and given its data and node values is
# one step (the demo's blockInsert is such a sequence).
{
  widget();
  $t->insert('1.end', "\nabcd");
  $t->editReset;
  my @r = $t->editStep(sub {
    $t->blockInsert('F', '2.1', '2.3');
    $t->blockSplit('2.3', 0);
    $t->blockData('2.2', 'INST');
    $t->blockNodedata('2.2', 0, 'B'); $t->blockNodedata('2.4', 0, 'C');
    $t->blockNodedata('2.2', 1, 'R');
    ('a', 'list');
  });
  is("@r", 'a list', 'editStep returns what the code returns');
  my $made = sub { join ' ', $t->get('2.0', '2.end'), map(lab(scalar eval { $t->blockNodedata(@$_) }),
						      ['2.2', 0], ['2.4', 0], ['2.2', 1]),
		     lab(scalar eval { $t->blockData('2.2') }) };
  is($made->(), 'a{b|c}d B C R INST', 'a block made with its data and its values');
  $t->editUndo;
  is($t->get('2.0', '2.end'), 'abcd', 'one undo: the text as before');
  ok(!eval { $t->editUndo; 1 }, 'one step');
  $t->editRedo;
  is($made->(), 'a{b|c}d B C R INST', 'one redo: the block, its data and its values');
  is(scalar $t->editStep(sub { 7 }), 7, 'scalar context');
}

# ---------------------------------------------------------------------
# 5. The method closes the step when the code dies; steps nest.
{
  widget();
  dies_like(sub { $t->editStep(sub { $t->insert('1.0', 'Q'); $t->delete('1.3'); die "oops\n" }) },
	    qr/^oops$/, 'the error of the code comes through');
  is($t->editStep, 0, 'the step is closed');
  is($t->get('1.0', '1.end'), 'Qx{um|den}y', 'what it did before dying stays');
  $t->editUndo;
  is($t->get('1.0', '1.end'), 'x{num|den}y', 'as one undo step');

  my $depth;
  $t->editStep(sub {
    $t->insert('1.0', 'A');
    $t->editStep(sub { $depth = $t->editStep; $t->delete('1.3'); $t->blockNodedata('1.4', 0, 'V') });
    $t->insert('1.0', 'B');
  });
  is($depth, 2, 'a step inside a step');
  is($t->get('1.0', '1.end') . ' ' . lab($t->blockNodedata('1.4', 0)), 'BAx{um|den}y V', 'both ran');
  $t->editUndo;
  is($t->get('1.0', '1.end') . ' ' . lab($t->blockNodedata('1.4', 0)), 'x{num|den}y -',
     'the outer one is the undo step');
  ok(!eval { $t->editUndo; 1 }, 'one step');

  # Without -undo nothing is recorded, and nothing breaks.
  $t->configure(-undo => 0);
  $t->editStep(sub { $t->insert('1.0', 'N'); $t->blockNodedata('1.4', 0, 'W') });
  is($t->get('1.0', '1.end') . ' ' . lab($t->blockNodedata('1.4', 0)), 'Nx{num|den}y W', 'with -undo off');
  $t->configure(-undo => 1);
  ok(!eval { $t->editUndo; 1 }, 'nothing recorded');
}

# ---------------------------------------------------------------------
# 6. -valuecommand: a recorded set stashes the old value (an unrecorded
# one drops it); undo and redo stash and restore.
{
  with_events();
  $t->blockNodedata('1.2', 0, 'OLD');
  $t->blockNodedata('1.2', 0, 'OUT');
  is(ev(), 'set: drop node OLD at 1.2 0', 'outside a step the old value is dropped');
  $t->editStep(sub { set_all() });
  is(ev(), 'set: stash node OUT at 1.2 0', 'inside a step it is stashed; values set where none was tell nothing');
  $t->editUndo;
  is(ev(), 'undo: stash mark MARK at m 1.3; undo: stash run TAG at u 1.2 1.4; '
     . 'undo: stash block DATA at 1.1; undo: stash node ROOT at 1.2 1; '
     . 'undo: stash node DEN at 1.6 0; undo: stash node NUM at 1.2 0; '
     . 'undo: restore node OUT at 1.2 0',
     'undo: the values set go into the step, last first; the old one comes back');
  $t->editRedo;
  is(ev(), 'redo: stash node OUT at 1.2 0; redo: restore node NUM at 1.2 0; '
     . 'redo: restore node DEN at 1.6 0; redo: restore node ROOT at 1.2 1; '
     . 'redo: restore block DATA at 1.1; redo: restore run TAG at u 1.2 1.4; '
     . 'redo: restore mark MARK at m 1.3', 'redo: the other way');
  $t->editReset;
  is(ev(), 'reset: discard node OUT at 1.2 0', 'the step discarded: the old value it held is told');
  $t->editStep(sub { $t->blockNodedata('1.2', 0, 'NEWER') });
  ev();
  $t->editUndo; ev();
  $t->insert('1.0', 'x');
  is(ev(), 'insert: discard node NEWER at 1.2 0',
     'a new edit drops the step that could be redone, with the value it held');
}

# ---------------------------------------------------------------------
# 7. Values that are objects are freed once, when the step that holds
# them goes.
{
  widget();
  $t->blockNodedata('1.2', 0, SV->new('old'));
  @log = ();
  $t->editStep(sub { $t->blockNodedata('1.2', 0, SV->new('new')) });
  is("@log", '', 'replaced inside a step: the old object lives in the step');
  $t->editUndo;
  is(lab($t->blockNodedata('1.2', 0)) . " @log", 'old ', 'undone: it is back, the new one waits');
  $t->editRedo;
  is(lab($t->blockNodedata('1.2', 0)) . " @log", 'new ', 'redone');
  $t->editReset;
  is("@log", 'old', 'the step discarded: the old object is destroyed, once');
  @log = ();
  $t->editStep(sub { $t->blockNodedata('1.2', 0, undef) });
  is("@log", '', 'removed inside a step: alive');
  $t->editUndo;
  $t->editReset;
  is(lab($t->blockNodedata('1.2', 0)) . " @log", 'new ', 'undone and the step discarded: the leaf holds it');
  $t->destroy; undef $t;
  is("@log", 'new', 'destroyed with the widget, once');
}

# ---------------------------------------------------------------------
# 8. With cut and paste: two pieces exchanged as one step; the paste of
# the clipboard over a selection is one step.
{
  widget();
  $t->blockNodedata('1.2', 0, 'NUM'); $t->blockNodedata('1.8', 0, 'DEN');
  $t->insert('1.end', "\nabcdef");
  $t->blockInsert('F', '2.1', '2.5');
  $t->blockSplit('2.4', 0);
  $t->blockNodedata('2.5', 0, 'D');
  $t->editReset;
  my $both = sub { join ' ', $t->get('1.0', '1.end'), $t->get('2.0', '2.end'),
		     map lab(scalar eval { $t->blockNodedata(@$_) }), ['1.2', 0], ['1.8', 0], ['2.2', 0], ['2.6', 0] };
  my $s0 = $both->();
  is($s0, 'x{num|den}y a{bc|de}f NUM DEN - D', 'two blocks');
  $t->editStep(sub {
    my @one = $t->blockCut('1.4', '1.7');	# m|d
    my @two = $t->blockCut('2.3', '2.6');	# c|d
    $t->blockPaste('1.4', \@two);
    $t->blockPaste('2.3', \@one);
  });
  is($both->(), 'x{nuc|den}y a{bm|de}f NUM D - DEN', 'two pieces exchanged, the values with them');
  $t->editUndo;
  is($both->(), $s0, 'one undo for the two cuts and the two pastes');
  ok(!eval { $t->editUndo; 1 }, 'one step');
  $t->editRedo;
  is($both->(), 'x{nuc|den}y a{bm|de}f NUM D - DEN', 'one redo');
  $t->editUndo;

 SKIP: {
    $t->tagAdd('sel', '1.4', '1.7');
    $t->clipboardCopy;
    skip 'the clipboard is not available here', 4 unless defined eval { $t->clipboardGet };
    $t->tagRemove('sel', '1.0', 'end');
    $t->tagAdd('sel', '2.3', '2.6');
    $t->markSet('insert', '2.4');
    $t->clipboardPaste;
    is($both->(), 'x{num|den}y a{bm|de}f NUM DEN - DEN', 'the clipboard pasted over a selection');
    $t->editUndo;
    is($both->(), $s0, 'one undo: the selection is back');
    ok(!eval { $t->editUndo; 1 }, 'the deletion and the paste were one step');
    is($t->editStep, 0, 'no step left open');
  }
}

# ---------------------------------------------------------------------
# 9. Random: steps of random commands and value settings; one undo gives
# the state before the step, one redo the state after.
{
  widget();
  srand(1114);
  my $val = 0;
  my $state = sub {
    my @v;
    my $len = length $t->get('1.0', '1.end');
    for my $p (0 .. $len) {
      for my $level (0 .. 2) {
	my $v = eval { $t->blockNodedata("1.$p", $level) };
	push @v, "$p/$level=$v" if defined $v;
      }
    }
    join ' ', $t->get('1.0', 'end - 1 c'), @v, 'data=' . lab(scalar eval { $t->blockData('1.2') }),
      'mark=' . lab(scalar eval { $t->markData('m') }), 'tags=' . join(',', $t->tagRanges('u')),
      map { 'tag=' . lab(scalar eval { $t->tagData('u', $_) }) } $t->tagRanges('u');
  };
  my ($tried, $undo, $redo, $one, @bad) = (0, 0, 0, 0);
  for my $round (1 .. 150) {
    if ($round % 25 == 1) {
      widget();
      $t->blockSplit('1.3', 1);
    }
    $t->editReset;
    my $s0 = $state->();
    $t->editStep(sub {
      for (1 .. 1 + int rand 5) {
	my $len = length $t->get('1.0', '1.end');
	my $inside = sub { my @r = $t->blockAt('1.1'); 2 + int rand($r[1] - 2) };
	my $k = int rand 8;
	eval {
	  if ($k == 0) { $t->insert('1.' . $inside->(), chr(97 + int rand 26)) }
	  elsif ($k == 1) { $t->blockSplit('1.' . $inside->(), int rand 2) }
	  elsif ($k == 2) { $t->blockNodedata('1.' . $inside->(), int rand 3, rand() < 0.2 ? undef : 'v' . $val++) }
	  elsif ($k == 3) { $t->blockData('1.2', rand() < 0.2 ? undef : 'd' . $val++) }
	  elsif ($k == 4) { $t->markData('m', rand() < 0.2 ? undef : 'm' . $val++) }
	  elsif ($k == 5) { my @r = $t->tagRanges('u'); $t->tagData('u', $r[0], rand() < 0.2 ? undef : 't' . $val++) if @r }
	  elsif ($k == 6) { my $p = $inside->(); $t->delete("1.$p") if $t->get("1.$p") =~ /[a-z|]/ and $len > 8 }
	  else { my $p = $inside->(); $t->tagAdd('u', "1.$p", '1.' . ($p + 1)) }
	  1;
	};
      }
    });
    my $s1 = $state->();
    next if $s1 eq $s0;
    $tried++;
    my $u = eval { $t->editUndo; 1 } && $state->() eq $s0;
    $one++ if $u && !eval { $t->editUndo; 1 };
    my $r = $u && eval { $t->editRedo; 1 } && $state->() eq $s1;
    $undo++ if $u; $redo++ if $r;
    push @bad, $round unless $u and $r;
  }
  cmp_ok($tried, '>', 100, "$tried steps that changed something");
  is($undo, $tried, 'one undo gives the text and the values before the step');
  is($one, $tried, 'and is the whole step');
  is($redo, $tried, 'one redo gives those after it');
  is("@bad[0 .. ($#bad > 4 ? 4 : $#bad)]", '', 'no failures');
}

$t->destroy if $t;
