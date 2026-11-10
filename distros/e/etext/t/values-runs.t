#!/usr/bin/perl
# Values of tag runs ("tag data"): which run a position names, what
# merges and cuts do with the values, and exactly when they are freed.
# The values are objects whose DESTROY method records that it ran (as
# in t/values.t).
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
plan tests => 187;
$mw->geometry('+10+10');

my @log;			# names of the objects destroyed, in order
{
  package V;
  sub new { my ($class, $name, $hook) = @_; bless { n => $name, hook => $hook }, $class }
  sub DESTROY { my $self = shift; $self->{hook}->($self) if $self->{hook};
		push @log, $self->{n} }
}

sub freed (&) { @log = (); $_[0]->(); my @r = @log; @log = (); return \@r }
sub sfreed (&) { my $r = &freed($_[0]); return [sort @$r] }
# The name of the value of the run of $tag at $index ('-' if no run).
sub rv { my ($t, $tag, $index) = @_;
	 my $v = eval { $t->tagData($tag, $index) };
	 return '-' if $@;
	 return defined $v ? (ref $v ? $v->{n} : $v) : undef }
sub ranges { my ($t, $tag) = @_; join ' ', $t->tagRanges($tag) }
sub dies_like { my ($code, $re, $name) = @_;
		my $ok = !eval { $code->(); 1 }; like($ok ? $@ : 'no error', $re, $name) }

# A text "abcdefghij" with runs of b on 1.0-1.3 and 1.6-1.9.
sub two_runs {
  my $t = $mw->eText(-width => 30, -height => 6, @_)->pack;
  $t->insert('end', "abcdefghij\nklmnop\n");
  $t->tagAdd('b', '1.0', '1.3');
  $t->tagAdd('b', '1.6', '1.9');
  $t->editReset;
  $t->debug(1);
  return $t;
}

# ---------------------------------------------------------------------
# T1: finding the run; reading and setting.
{
  my $t = two_runs();
  ok(!defined $t->tagData('b', '1.0'), 'no value at first');
  $t->tagData('b', '1.1', V->new('x'));
  $t->tagData('b', '1.8', V->new('y'));
  is(rv($t, 'b', '1.0'), 'x', 'the first character of the run');
  is(rv($t, 'b', '1.2'), 'x', 'its last character');
  is(rv($t, 'b', '1.6'), 'y', 'the second run');
  dies_like(sub { $t->tagData('b', '1.4') }, qr/^no run of tag "b" at 1\.4/,
	    'a character without the tag');
  dies_like(sub { $t->tagData('b', '1.3') }, qr/^no run of tag "b" at 1\.3/,
	    'the character just after a run');
  dies_like(sub { $t->tagData('nosuch', '1.0') }, qr/^tag "nosuch" isn't defined/,
	    'a tag that does not exist');
  dies_like(sub { $t->tag('data', 'b') }, qr/wrong # args/, 'wrong # args');
  dies_like(sub { $t->tag('nosuch') }, qr/must be add, bind, cget, configure, data, delete/,
	    'the bad option message names data');
  my $s = 'plain';
  is_deeply(freed { $t->tagData('b', '1.7', $s) }, ['y'], 'replacing frees the old value at once');
  $s .= ' changed';
  is($t->tagData('b', '1.6'), 'plain', 'a copy of the scalar is kept');
  my $obj = V->new('kept');
  $t->tagData('b', '1.6', $obj);
  undef $obj;
  is_deeply(\@log, [], 'the object lives on in the run');
  is_deeply(freed { $t->tagData('b', '1.8', undef) }, ['kept'], 'setting undef frees it');
  ok(!defined $t->tagData('b', '1.8'), 'no value any more');
  is_deeply(freed { $t->tagConfigure('b', -foreground => 'red'); $t->tagRaise('b');
		    $t->insert('2.2', 'xx'); $t->delete('2.0', '2.2');
		    $t->tagAdd('c', '1.0', '1.9'); $t->tagRemove('c', '1.0', 'end') }, [],
	    'unrelated changes free nothing');
  is(rv($t, 'b', '1.1'), 'x', 'and leave the value');

  # A run over a line end.
  $t->tagAdd('n', '1.8', '2.2');
  $t->tagData('n', '2.1', 'nl');
  is($t->tagData('n', '1.9'), 'nl', 'a run over a line end: one value');
  is($t->tagData('n', '1.10'), 'nl', 'the newline is in the run');
  is(ranges($t, 'n'), '1.8 2.2', 'one range');

  # The block list: the start element of a run with a value.
  my @l = $t->blockList('1.0', '1.4');
  is(ref $l[0], 'Tk::Text::TagOn', 'block list: the start of the run');
  is_deeply([@{$l[0]}], ['b', $t->tagData('b', '1.0')], 'is [name, value] when the run has a value');
  @l = $t->blockList('1.6', '1.9');
  is(${$l[0]}, 'b', 'and the name alone when it has none');
  @l = ();
  is_deeply(freed { $t->tagData('b', '1.0', undef) }, ['x'],
	    'the block list held a copy, not the value');

  # The widget destroyed: the values go after it.
  my $after;
  $t->tagData('b', '1.7', V->new('y2', sub { $after = eval { $t->index('end'); 'alive' } || 'gone' }));
  $t->tagData('b', '1.1', V->new('x2'));
  is_deeply(sfreed { $t->destroy; $mw->update }, ['x2', 'y2'],
	    'destroying the widget frees the values');
  is($after, 'gone', 'after the widget is gone');
}

# ---------------------------------------------------------------------
# T2: merges by tag add (not undoable: the loser is freed).
{
  my $t = two_runs();
  $t->tagData('b', '1.0', V->new('x'));
  $t->tagData('b', '1.6', V->new('y'));
  is_deeply(freed { $t->tagAdd('b', '1.3', '1.6') }, ['y'],
	    'tag add over the gap: the right value loses, freed then');
  is(ranges($t, 'b'), '1.0 1.9', 'one run');
  is(rv($t, 'b', '1.8'), 'x', 'with the left value');
  $t->tagRemove('b', '1.3', '1.6');
  is(rv($t, 'b', '1.0'), 'x', 'tag remove in the middle: the left part keeps it');
  ok(!defined $t->tagData('b', '1.7'), 'the right part starts without a value');
  $t->tagData('b', '1.7', V->new('y'));
  $t->tagData('b', '1.0', undef);
  is_deeply(freed { $t->tagAdd('b', '1.2', '1.7') }, [],
	    'the left run without a value: nothing freed');
  is(rv($t, 'b', '1.0'), 'y', 'the merged run takes the right value');

  # Three runs, the middle one without a value, joined by one tag add
  # that starts before them.
  $t->tagRemove('b', '1.0', 'end');
  $t->tagAdd('b', '1.1', '1.2');
  $t->tagAdd('b', '1.3', '1.4');
  $t->tagAdd('b', '1.5', '1.6');
  $t->tagData('b', '1.1', V->new('p'));
  $t->tagData('b', '1.5', V->new('r'));
  is_deeply(freed { $t->tagAdd('b', '1.0', '1.7') }, ['r'], 'three runs joined: the last value loses');
  is(rv($t, 'b', '1.0'), 'p', 'the first value present wins, the new start too');
  # Extending a run at either end.
  is_deeply(freed { $t->tagAdd('b', '1.7', '1.9'); $t->tagAdd('b', '1.8', '2.1') }, [],
	    'extending a run at its end');
  is(rv($t, 'b', '2.0'), 'p', 'the value covers the extension');
  is(ranges($t, 'b'), '1.0 2.1', 'one range');
  # A tag add inside a run, and the insert command with the tag.
  is_deeply(freed { $t->tagAdd('b', '1.2', '1.4'); $t->insert('1.3', 'X', 'b') }, [],
	    'adding the tag inside its run, inserting text with it');
  is(rv($t, 'b', '1.3'), 'p', 'the run is unchanged');
  $t->destroy;
}

# ---------------------------------------------------------------------
# T3, T4: cuts and shortened runs by tag remove; tag delete.
{
  my $t = two_runs();
  $t->tagAdd('b', '1.0', '1.10');
  $t->tagData('b', '1.5', V->new('x'));
  is_deeply(freed { $t->tagRemove('b', '1.0', '1.2') }, [], 'shortened at the start');
  is(ranges($t, 'b'), '1.2 1.10', 'the run');
  is(rv($t, 'b', '1.2'), 'x', 'keeps its value');
  is_deeply(freed { $t->tagRemove('b', '1.8', '1.10') }, [], 'shortened at the end');
  is(rv($t, 'b', '1.7'), 'x', 'keeps its value');
  is_deeply(freed { $t->tagRemove('b', '1.4', '1.6') }, [], 'cut in two');
  is(rv($t, 'b', '1.3'), 'x', 'the left part keeps it');
  ok(!defined $t->tagData('b', '1.6'), 'the right part has none');
  $t->tagData('b', '1.6', V->new('y'));
  is_deeply(freed { $t->tagRemove('b', '1.1', '1.6') }, ['x'],
	    'tag remove over a whole run frees its value then');
  is(rv($t, 'b', '1.6'), 'y', 'the next run keeps its own');
  is_deeply(freed { $t->tagRemove('b', '1.5', '1.7') }, [],
	    'shortening the run at its start from before it');
  is(rv($t, 'b', '1.7'), 'y', 'keeps the value');

  # Text inserted inside a run: without a tag list it is in the run;
  # with a tag list that lacks the tag it cuts the run.
  $t->tagRemove('b', '1.0', 'end');
  $t->tagAdd('b', '1.0', '1.6');
  $t->tagData('b', '1.0', V->new('x'));
  is_deeply(freed { $t->insert('1.3', 'NN'); $t->insert('1.4', "\n") }, [],
	    'plain text and a newline inserted inside the run');
  is(ranges($t, 'b'), '1.0 2.4', 'are in the run');
  is(rv($t, 'b', '2.3'), 'x', 'one value');
  is_deeply(freed { $t->insert('1.0', 'S'); $t->insert('2.4', 'E') }, [],
	    'text at the start or the end of the run');
  is(ranges($t, 'b'), '1.1 2.4', 'is not in it');
  is_deeply(freed { $t->insert('1.3', 'C', 'other') }, [],
	    'text with a tag list lacking the tag');
  is(ranges($t, 'b'), '1.1 1.3 1.4 2.4', 'cuts the run');
  is(rv($t, 'b', '1.1'), 'x', 'the left part keeps the value');
  ok(!defined $t->tagData('b', '1.4'), 'the right part has none');
  $t->tagData('b', '1.4', V->new('y'));
  $t->tagData('b', '1.1', 'string');
  $t->tagAdd('b', '2.6', '2.8');
  $t->tagData('b', '2.6', V->new('z'));
  is_deeply(sfreed { $t->tagDelete('b') }, ['y', 'z'], 'tag delete frees the values of all its runs');
  dies_like(sub { $t->tagData('b', '1.1') }, qr/isn't defined/, 'the tag is gone');
  $t->tagAdd('b', '1.0', '1.4');
  ok(!defined $t->tagData('b', '1.1'), 'the tag made again has no values');
  $t->destroy;
}

# ---------------------------------------------------------------------
# T4, F1: deletions with undo off.
{
  my $t = two_runs();
  $t->tagData('b', '1.0', V->new('x'));
  my $end;
  $t->tagData('b', '1.6', V->new('y', sub { $end = $t->index('end') }));
  is_deeply(freed { $t->delete('1.6', '1.9') }, ['y'], 'deleting all the text of a run frees its value');
  is($end, '4.0', 'once the deletion is done (the DESTROY method uses the widget)');
  $t->delete('1.0', 'end');
  $t->insert('end', "ab\ncd\n");
  $t->tagAdd('b', '2.0', '2.2');
  $t->tagData('b', '2.0', V->new('l2', sub { $end = $t->index('end') }));
  is_deeply(freed { $t->delete('2.0', '3.0') }, ['l2'], 'the example of the plan: line 2 deleted');
  is($end, '3.0', 'DESTROY sees the end as it is after the deletion');
  $t->delete('1.0', 'end');
  $t->insert('end', "abcdefghij\n");
  $t->tagAdd('b', '1.0', '1.3');
  $t->tagAdd('b', '1.6', '1.9');
  $t->tagData('b', '1.0', V->new('x'));
  $t->tagData('b', '1.6', V->new('y'));
  is_deeply(freed { $t->delete('1.2', '1.7') }, ['y'],
	    'deleting from inside one run to inside the next: the right value loses');
  is(ranges($t, 'b'), '1.0 1.4', 'one run');
  is(rv($t, 'b', '1.3'), 'x', 'with the left value');
  $t->tagRemove('b', '1.2', '1.3');
  $t->tagData('b', '1.3', V->new('y'));
  is_deeply(freed { $t->delete('1.2', '1.3') }, ['y'], 'deleting the gap: the right value loses');
  is(rv($t, 'b', '1.0'), 'x', 'the left one stays');
  # Exactly the gap, the runs touching it.
  $t->insert('1.2', 'GG');
  $t->tagRemove('b', '1.2', '1.4');
  $t->tagData('b', '1.4', V->new('y'));
  $t->tagData('b', '1.0', undef);
  is_deeply(freed { $t->delete('1.2', '1.4') }, [], 'deleting exactly the gap, the left run without a value');
  is(rv($t, 'b', '1.0'), 'y', 'the merged run takes the right value');
  # A run shortened by deletions at either end, and a whole run with
  # its neighbours.
  is_deeply(freed { $t->delete('1.0', '1.1'); $t->delete('1.2', '1.4') }, [], 'shortening by deletion');
  is(rv($t, 'b', '1.0'), 'y', 'keeps the value');
  $t->delete('1.0', 'end');
  $t->insert('end', "abcdefghij\n");
  $t->tagAdd('b', '1.1', '1.3');
  $t->tagAdd('b', '1.4', '1.5');
  $t->tagAdd('b', '1.6', '1.9');
  $t->tagData('b', '1.1', V->new('p'));
  $t->tagData('b', '1.4', V->new('q'));
  $t->tagData('b', '1.6', V->new('r'));
  is_deeply(freed { $t->delete('1.2', '1.7') }, ['q', 'r'],
	    'a whole run deleted and the next one cut: freed, and the loser');
  is(rv($t, 'b', '1.1'), 'p', 'the first run keeps its value');
  $t->delete('1.0', 'end');
  $t->insert('end', "abcdefghij\n");
  $t->tagAdd('b', '1.1', '1.3');
  $t->tagAdd('b', '1.4', '1.5');
  $t->tagAdd('b', '1.6', '1.9');
  $t->tagData('b', '1.4', V->new('q'));
  $t->tagData('b', '1.6', V->new('r'));
  is_deeply(freed { $t->delete('1.3', '1.7') }, ['q'],
	    'a whole run with a value between: it takes no part in the merge');
  is(rv($t, 'b', '1.1'), 'r', 'the merged run has the value of the run that is left');
  $t->delete('1.0', 'end');
  $t->insert('end', "abcdefghij\n");
  $t->tagAdd('b', '1.2', '1.4');
  $t->tagAdd('b', '1.5', '1.8');
  $t->tagData('b', '1.2', V->new('q'));
  $t->tagData('b', '1.5', V->new('r'));
  is_deeply(freed { $t->delete('1.1', '1.6') }, ['q'],
	    'a whole run and the start of the next');
  is(rv($t, 'b', '1.1'), 'r', 'the next run keeps its value');
  $t->destroy;
}

# ---------------------------------------------------------------------
# F3: deletions with undo on.
{
  my $t = two_runs(-undo => 1);
  $t->tagData('b', '1.0', V->new('x'));
  $t->tagData('b', '1.6', V->new('y'));
  is_deeply(freed { $t->delete('1.2', '1.7') }, [], 'undoable merge: the loser is kept');
  is(rv($t, 'b', '1.0'), 'x', 'the merged run has the left value');
  is_deeply(freed { $t->editUndo }, [], 'undo');
  is(ranges($t, 'b'), '1.0 1.3 1.6 1.9', 'the runs are back');
  is(rv($t, 'b', '1.0'), 'x', 'the left run has its value');
  is(rv($t, 'b', '1.6'), 'y', 'the right run has its value again');
  is_deeply(freed { $t->editRedo }, [], 'redo');
  is(rv($t, 'b', '1.0'), 'x', 'the merged run again');
  is_deeply(freed { $t->editUndo }, [], 'undo again');
  is(rv($t, 'b', '1.6'), 'y', 'the right value is back again');
  is_deeply(freed { $t->tagData('b', '1.6', undef) }, ['y'], 'the undo history holds no copy');

  # The merged run takes the right value (the left one has none).
  $t->tagData('b', '1.0', undef);
  $t->tagData('b', '1.6', V->new('y'));
  $t->editReset;
  @log = ();
  is_deeply(freed { $t->delete('1.2', '1.7') }, [], 'undoable merge, the left run without a value');
  is(rv($t, 'b', '1.0'), 'y', 'the merged run has the right value');
  is_deeply(freed { $t->editUndo }, [], 'undo');
  ok(!defined $t->tagData('b', '1.0'), 'the left run is without a value again');
  is(rv($t, 'b', '1.6'), 'y', 'the value is back on the right run');
  is_deeply(freed { $t->editRedo; $t->editUndo }, [], 'redo and undo');
  is(rv($t, 'b', '1.6'), 'y', 'still right');

  # A whole run deleted: kept until the undo step goes.
  is_deeply(freed { $t->delete('1.5', '1.10') }, [], 'deleting a whole run keeps its value');
  is_deeply(freed { $t->editUndo }, [], 'undo');
  is(rv($t, 'b', '1.7'), 'y', 'the run is back with its value');
  is_deeply(freed { $t->editRedo }, [], 'redo');
  is_deeply(freed { $t->editReset }, ['y'], 'edit reset frees it');

  # A run partly deleted: the part left keeps the value; undo restores
  # the whole.
  $t->delete('1.0', 'end');
  $t->insert('end', "abcdefghij\n");
  $t->tagAdd('b', '1.0', '1.10');
  $t->tagData('b', '1.0', V->new('w'));
  $t->editReset;
  is_deeply(freed { $t->delete('1.5', '1.10') }, [], 'deleting the end of a run');
  is(rv($t, 'b', '1.4'), 'w', 'the part left keeps the value');
  is_deeply(freed { $t->editUndo }, [], 'undo');
  is(ranges($t, 'b'), '1.0 1.10', 'the run is whole');
  is(rv($t, 'b', '1.9'), 'w', 'with its value');
  is_deeply(freed { $t->delete('1.0', '1.4') }, [], 'deleting the start of a run');
  is(rv($t, 'b', '1.0'), 'w', 'the part left keeps the value');
  is_deeply(freed { $t->editUndo }, [], 'undo');
  is(ranges($t, 'b'), '1.0 1.10', 'the run is whole');
  is(rv($t, 'b', '1.9'), 'w', 'with its value');

  # The undo of an insertion that holds a whole run.
  $t->editReset;
  $t->insert('2.0', 'NEW', 'b');
  is(ranges($t, 'b'), '1.0 1.10 2.0 2.3', 'a new run');
  $t->tagData('b', '2.0', V->new('n'));
  is_deeply(freed { $t->editUndo }, [], 'undoing its insertion keeps the value');
  is(ranges($t, 'b'), '1.0 1.10', 'the run is gone');
  # The redo of an insertion re-inserts it exactly (the undo recorded it
  # in block-list form): the run comes back, and its value with it.
  is_deeply(freed { $t->editRedo }, [], 'redo of the insertion frees nothing');
  is(ranges($t, 'b'), '1.0 1.10 2.0 2.3', 'the run is re-created');
  is(rv($t, 'b', '2.2'), 'n', 'with its value');
  is_deeply(freed { $t->editUndo; $t->editRedo }, [], 'undo and redo again');
  is(rv($t, 'b', '2.0'), 'n', 'the value is still there');
  is_deeply(freed { $t->delete('2.0', '2.end'); $t->editReset }, ['n'],
	    'deleting the run and edit reset free the value');
  $t->editReset;
  $t->insert('2.0', 'NEW', 'b');
  $t->tagData('b', '2.0', V->new('n2'));
  $t->editUndo;
  is_deeply(freed { $t->insert('3.0', 'q') }, ['n2'],
	    'an edit after an undo discards the redo step, and the value in it');

  # -maxundo discards the oldest step.
  $t->configure(-maxundo => 1);
  $t->tagAdd('b', '2.0', '2.3');
  $t->tagData('b', '2.0', V->new('m'));
  $t->editSeparator;
  $t->delete('2.0', '2.4');
  $t->editSeparator;
  is_deeply(freed { $t->insert('1.0', 'Z'); $t->editSeparator; $t->insert('1.0', 'Z') }, ['m'],
	    '-maxundo drops the step and frees the value');
  $t->configure(-maxundo => 0);

  # The widget destroyed with values in the history.
  $t->tagData('b', '1.3', V->new('h'));
  $t->delete('1.0', 'end');
  is_deeply(freed { $t->destroy; $mw->update }, ['h'], 'the widget frees the values of its history');
}

# ---------------------------------------------------------------------
# Undo restores the old state exactly: a value it finds on the run it
# gives a value back to (set there after the edit) is not freed but
# kept in the undo step, and comes back on redo.
{
  my $t = $mw->eText(-undo => 1)->pack;
  $t->debug(1);
  $t->insert('end', "abcdefghij\n");
  $t->tagAdd('b', '1.3', '1.6');
  $t->tagData('b', '1.3', V->new('y'));
  $t->editReset;
  is_deeply(freed { $t->delete('1.3', '1.6') }, [], 'a run deleted, its value kept for the undo');
  $t->configure(-undo => 0);		# (tag add is undoable: keep it out)
  $t->tagAdd('b', '1.3', '1.5');	# a new run where the old one was
  $t->configure(-undo => 1);
  $t->tagData('b', '1.3', V->new('z'));
  is_deeply(freed { $t->editUndo }, [], 'undo: the restored run joins the new one; nothing freed');
  is(ranges($t, 'b'), '1.3 1.8', 'one run');
  is(rv($t, 'b', '1.3'), 'y', 'with the value it had before the deletion (the leftmost)');
  is_deeply(freed { $t->editRedo }, [], 'redo frees nothing');
  is(ranges($t, 'b'), '1.3 1.5', 'the new run alone');
  is(rv($t, 'b', '1.3'), 'z', 'has its value back');
  is_deeply(freed { $t->editUndo }, [], 'undo again');
  is(rv($t, 'b', '1.3'), 'y', 'the old value again');
  is_deeply(freed { $t->editReset }, ['z'], 'edit reset frees the value kept in the step');
  is_deeply(freed { $t->destroy; $mw->update }, ['y'], 'the widget the other');
}

# ---------------------------------------------------------------------
# A run that starts where a deletion starts (its start was deleted, or
# it followed the deleted text): the undo re-inserts the text before
# it, and a piece of that text with the same tag must not take its
# value away.
{
  my $t = $mw->eText(-undo => 1)->pack;
  $t->debug(1);
  $t->insert('end', "jomgerq\nyseych\ngn\n");
  $t->tagAdd('b', '1.5', '1.6', '2.0', '3.0');
  $t->tagData('b', '2.0', V->new('r'));
  $t->editReset;
  is_deeply(freed { $t->delete('1.1', '2.0') }, [], 'a deletion holding a run without a value');
  is(ranges($t, 'b'), '1.1 2.0', 'the run after it starts at the deletion');
  is(rv($t, 'b', '1.1'), 'r', 'with its value');
  is_deeply(freed { $t->editUndo }, [], 'undo');
  is(ranges($t, 'b'), '1.5 1.6 2.0 3.0', 'both runs are back');
  ok(!defined $t->tagData('b', '1.5'), 'the deleted run has no value');
  is(rv($t, 'b', '2.0'), 'r', 'the run after it keeps its own');
  $t->editRedo;
  is(rv($t, 'b', '1.1'), 'r', 'redo: the value is still on it');
  $t->editUndo;
  is(rv($t, 'b', '2.0'), 'r', 'and after the undo again');
  is_deeply(freed { $t->destroy; $mw->update }, ['r'], 'freed once, with the widget');
}

# ---------------------------------------------------------------------
# A deletion that dissolves a block and joins a run with a value inside
# it to a later run: the undo takes the remains of the block out first,
# and the value stayed on the later run.
{
  my $t = $mw->eText(-undo => 1)->pack;
  $t->blockConfigure('F');
  $t->insert('end', "abcdefgh\n");
  $t->blockInsert('F', '1.2', '1.4');		# ab{cd}efgh
  $t->tagAdd('c', '1.3', '1.5', '1.7', '1.8');
  $t->tagData('c', '1.3', V->new('v'));
  $t->editReset;
  $t->delete('1.4', '1.7');
  is(rv($t, 'c', '1.2'), 'v', 'the joined run has the value');
  is_deeply(freed { $t->editUndo }, [], 'undo');
  is(ranges($t, 'c'), '1.3 1.5 1.7 1.8', 'the runs are back');
  is(rv($t, 'c', '1.3'), 'v', 'the value is on the first');
  ok(!defined $t->tagData('c', '1.7'), 'not on the second');
  $t->editRedo; $t->editUndo;
  is(rv($t, 'c', '1.3'), 'v', 'and again after redo and undo');
  is_deeply(freed { $t->destroy; $mw->update }, ['v'], 'freed once');
}

# ---------------------------------------------------------------------
# Runs and blocks: a run around a block, a run inside a block, blocks
# dissolved by a deletion.
{
  my $t = $mw->eText(-width => 30, -height => 6, -undo => 1)->pack;
  $t->blockConfigure('F');
  $t->insert('end', "ab\nnum\nden\ncd\n");
  $t->blockInsert('F', '2.0', '3.3');	# line 2: {num|den}
  $t->insert('2.0', 'xy');
  $t->insert('2.end', 'zw');		# xy{num|den}zw
  $t->editReset;
  $t->debug(1);
  is($t->get('2.0', '2.end'), 'xy{num|den}zw', 'a fraction in a line');
  $t->tagAdd('b', '2.1', '2.12');
  is(ranges($t, 'b'), '2.1 2.12', 'a run over the block');
  $t->tagData('b', '2.5', V->new('over'));
  is(rv($t, 'b', '2.1'), 'over', 'one value for the run, from inside the block');
  is(rv($t, 'b', '2.11'), 'over', 'and after it');
  is_deeply(freed { $t->tagRemove('b', '2.4', '2.5') }, [], 'a cut inside the block');
  is(rv($t, 'b', '2.3'), 'over', 'the left part keeps the value');
  ok(!defined $t->tagData('b', '2.6'), 'the right part, in the block, has none');
  $t->tagData('b', '2.6', V->new('in'));
  is_deeply(freed { $t->tagAdd('b', '2.4', '2.5') }, [],
	    'joined again inside the block: the loser is kept for the undo');
  is_deeply(freed { $t->editReset }, ['in'], 'and freed with the undo history');
  is(rv($t, 'b', '2.9'), 'over', 'the left value');

  # Block split and a newline in a leaf inside the run do not cut it.
  is_deeply(freed { $t->blockSplit('2.4', 0); $t->insert('2.10', "\n") }, [],
	    'block split and a typed newline inside the run');
  is(ranges($t, 'b'), '2.1 2.14', 'one range still') or diag ranges($t, 'b');
  is(rv($t, 'b', '2.13'), 'over', 'with its value');
  $t->editReset;

  # A run inside a leaf.
  $t->tagRemove('b', '1.0', 'end');
  is($t->get('2.0', '2.end'), "xy{n|um|de|n}zw", 'the block now');
  $t->tagAdd('i', '2.5', '2.7');
  $t->tagData('i', '2.6', V->new('leaf'));
  is_deeply(freed { $t->delete('2.4', '2.8') }, [], 'deleting a run inside a block (undo on)');
  is_deeply(freed { $t->editUndo }, [], 'undo');
  is(rv($t, 'i', '2.5'), 'leaf', 'the run in the block has its value');
  $t->configure(-undo => 0);
  is_deeply(freed { $t->delete('2.5', '2.7') }, ['leaf'], 'and without undo it is freed');

  # A deletion of a block head dissolves the block: runs on both sides
  # of the head merge.
  $t->delete('1.0', 'end');
  $t->insert('end', "ab\nnum\nden\ncd\n");
  $t->blockInsert('F', '2.0', '3.3');
  $t->insert('2.0', 'xy');		# xy{num|den}
  $t->tagAdd('b', '2.0', '2.2');
  $t->tagAdd('b', '2.3', '2.5');
  $t->tagData('b', '2.0', V->new('L'));
  $t->tagData('b', '2.3', V->new('R'));
  is_deeply(freed { $t->delete('2.2', '2.3') }, ['R'],
	    'deleting the head between two runs merges them');
  is($t->get('2.0', '2.end'), 'xynum', 'the block is dissolved');
  is(ranges($t, 'b'), '2.0 2.4', 'one run');
  is(rv($t, 'b', '2.3'), 'L', 'with the left value');
  $t->destroy;
}

{
  # Block insert inside a run keeps the run whole (the head and the
  # tail take the tag); at the start of a run, the run starts inside
  # the new block, with its value.
  my $t = $mw->eText->pack;
  $t->blockConfigure('F');
  $t->debug(1);
  $t->insert('end', "abcdefgh\n");
  $t->tagAdd('b', '1.1', '1.7');
  $t->tagData('b', '1.1', V->new('v'));
  is_deeply(freed { $t->blockInsert('F', '1.3', '1.5') }, [], 'block insert inside a run');
  is($t->get('1.0', '1.end'), 'abc{de}fgh', 'the block');
  is(ranges($t, 'b'), '1.1 1.9', 'the run is whole');
  is(rv($t, 'b', '1.8'), 'v', 'with its value');
  is_deeply(freed { $t->blockInsert('F', '1.1', '1.2') }, [], 'block insert at the start of the run');
  is(ranges($t, 'b'), '1.2 1.11', 'the run starts inside the new block');
  is(rv($t, 'b', '1.2'), 'v', 'with its value');
  $t->destroy;
}

# ---------------------------------------------------------------------
# Elided text: runs work the same.
{
  my $t = two_runs();
  $t->tagConfigure('b', -elide => 1);
  $t->tagData('b', '1.1', V->new('el'));
  is(rv($t, 'b', '1.2'), 'el', 'a run of elided text has its value');
  is_deeply(freed { $t->delete('1.0', '1.3') }, ['el'], 'deleting the elided run frees it');
  $t->destroy;
}

# ---------------------------------------------------------------------
# Leaks.
SKIP: {
  skip 'Test::LeakTrace not installed', 1 unless $have_lt;
  my $t = two_runs(-undo => 1);
  Test::LeakTrace::leaks_cmp_ok(sub {
    $t->tagData('b', '1.0', V->new('a'));
    $t->tagData('b', '1.6', { x => [1] });
    my @l = $t->blockList('1.0', '1.end');
    $t->delete('1.2', '1.7');
    $t->editUndo;
    $t->tagAdd('b', '1.3', '1.6');
    $t->tagRemove('b', '1.3', '1.6');
    $t->editReset;
  }, '<', 5, 'run values: no leaks');
  $t->destroy;
}

$mw->destroy;
