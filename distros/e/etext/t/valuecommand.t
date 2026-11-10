#!/usr/bin/perl
# -valuecommand: the program is told, before a command changes anything,
# which values the change detaches and where they are (drop, stash,
# move), and afterwards which come back (restore), which a discarded
# undo step frees (discard).  During the call the place names the value
# and the widget refuses changes.
use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require Tk; 1 } or plan skip_all => "Tk not available: $@";
}
use Tk::eText;

my $mw = eval { MainWindow->new };
plan skip_all => "no X display available ($@)" unless $mw;
plan tests => 67;
$mw->geometry('+10+10');

my (@log, @ev, @bad);
{
  package V;
  sub new { my ($class, $name) = @_; bless { n => $name }, $class }
  sub DESTROY { push @log, $_[0]{n} }
}

sub lab { my $v = shift; ref $v ? $v->{n} : defined $v ? $v : 'undef' }
sub place { join ' ', map { ref $_ ? '[' . place(@$_) . ']' : $_ } @_ }
# The value at a place, as the callback gets it.
sub at {
  my ($w, $kind, $where) = @_;
  my $v;
  if ($kind eq 'node') { $v = eval { $w->blockNodedata(@$where[0, 1]) } }
  elsif ($kind eq 'run') { $v = eval { $w->tagData(@$where[0, 1]) } }
  elsif ($kind eq 'mark') { $v = eval { $w->markData($where->[0]) } }
  elsif ($kind eq 'block') {
    my $i = $where->[0];
    $i = "$i +1c" if $w->get($i) eq '{';
    $v = eval { $w->blockData($i) };
  }
  lab($v);
}
sub cb {
  my ($w, $event, $kind, $where, $value, $cause) = @_;
  push @ev, "$event $kind [" . place(@$where) . '] ' . lab($value) . " ($cause)";
  if ($event =~ /^(drop|stash|move|restore)$/ && at($w, $kind, $where) ne lab($value)) {
    push @bad, "$ev[-1]: the place names " . at($w, $kind, $where);
  }
}
sub events (&) { @ev = (); @bad = (); $_[0]->(); my @r = @ev; @ev = (); \@r }

sub widget {
  my $t = $mw->eText(-width => 30, -height => 6, -valuecommand => \&cb, @_)->pack;
  $t->blockConfigure('F');
  $t->debug(1);
  $t;
}
# Line 2 holds {num|mid|den}: head 2.0, num 2.1, mid 2.5, den 2.9, tail 2.12.
sub fraction {
  my $t = widget(@_);
  $t->insert('end', "abcdef\nnum\nmid\nden\ncd\n");
  $t->blockInsert('F', '2.0', '4.3');
  $t->editReset;
  $t;
}

# ---------------------------------------------------------------------
# Setting and unsetting.
{
  my $t = fraction();
  is($t->cget('-valuecommand') && 1, 1, 'the option is set');
  is_deeply(events { $t->blockNodedata('2.2', 0, V->new('num')) }, [],
	    'setting a value where there is none: nothing to tell');
  is_deeply(events { $t->blockNodedata('2.3', 0, V->new('num2')) },
	    ['drop node [2.1 0] num (set)'], 'a node value replaced');
  is_deeply(events { $t->blockNodedata('2.6', -1, V->new('root')) }, [], 'the root');
  is_deeply(events { $t->blockNodedata('2.10', 1, undef) },
	    ['drop node [2.1 1] root (set)'],
	    'a value removed: the node is named by its first leaf');
  $t->tagAdd('x', '1.1', '1.3');
  $t->tagData('x', '1.1', V->new('run'));
  is_deeply(events { $t->tagData('x', '1.2', V->new('run2')) },
	    ['drop run [x 1.1 1.3] run (set)'], 'a run value replaced');
  $t->markSet('m', '1.4');
  $t->markData('m', V->new('mark'));
  is_deeply(events { $t->markData('m', undef) },
	    ['drop mark [m 1.4] mark (set)'], 'a mark value removed');
  $t->markData('m', V->new('mark2'));
  is_deeply(events { $t->markUnset('m') },
	    ['drop mark [m 1.4] mark2 (unset)'], 'mark unset');
  $t->blockData('2.1', V->new('data'));
  is_deeply(events { $t->blockData('2.5', V->new('data2')) },
	    ['drop block [2.0] data (set)'], 'block data replaced');
  is_deeply(\@bad, [], 'each place named its value during the call');
  $t->destroy;
}

# During the call: the widget can be read, not changed; an error in the
# callback is a background error and the command goes on.
{
  my @errors;
  local *Tk::Error = sub { push @errors, $_[1] };
  my %seen;
  my $t;
  $t = fraction(-valuecommand => sub {
    my ($w, $event, $kind, $where, $value, $cause) = @_;
    $seen{read} = $w->get('2.1', '2.4');
    $seen{nodedata} = lab($w->blockNodedata(@$where));
    $seen{insert} = eval { $w->insert('1.0', 'X'); 1 } ? 'ok' : $@;
    $seen{same} = ($w == $t);
    die "oops\n" if $value->{n} eq 'die';
  });
  $t->blockNodedata('2.1', 0, V->new('a'));
  $t->blockNodedata('2.1', 0, V->new('b'));
  is($seen{read}, 'num', 'the callback reads the text');
  is($seen{nodedata}, 'a', 'and finds the value at its place');
  my $path = $t->PathName;
  like($seen{insert}, qr/^cannot modify \Q$path\E while its -valuecommand runs/,
       'a change is refused');
  is($t->get('1.0', '1.end'), 'abcdef', 'and nothing changed');
  ok($seen{same}, 'the first argument is the widget');
  $t->blockNodedata('2.1', 0, V->new('die'));
  @log = ();
  $t->blockNodedata('2.1', 0, undef);
  $mw->update;
  is(scalar(@errors), 1, 'an error in the callback is a background error');
  is_deeply(\@log, ['die'], 'the command went on: the value is freed');
  $t->destroy;
}

# ---------------------------------------------------------------------
# Tag changes: runs that become one keep the first value present; a run
# whose text all loses the tag is gone.
sub runs {
  my $t = widget(@_);
  $t->insert('end', "abcdefghij\nklmnop\n");
  $t->tagAdd('x', '1.0', '1.3');
  $t->tagAdd('x', '1.6', '1.9');
  $t->tagData('x', '1.0', V->new('r1'));
  $t->tagData('x', '1.6', V->new('r2'));
  $t->editReset;
  $t;
}
{
  my $t = runs();
  is_deeply(events { $t->tagAdd('x', '1.3', '1.6') },
	    ['drop run [x 1.6 1.9] r2 (tag add)'], 'tag add joins two runs');
  is_deeply([ $t->tagRanges('x') ], [qw(1.0 1.9)], 'they are one');
  $t->destroy;

  $t = runs();
  $t->tagData('x', '1.0', undef);
  is_deeply(events { $t->tagAdd('x', '1.2', '1.7') },
	    ['move run [x 1.6 1.9 [x 1.0 1.3]] r2 (tag add)'],
	    'the first has no value: the second moves to it');
  is(lab($t->tagData('x', '1.0')), 'r2', 'and is there');
  is_deeply(events { $t->tagRemove('x', '1.0', '1.9') },
	    ['drop run [x 1.0 1.9] r2 (tag remove)'], 'tag remove over a whole run');
  $t->destroy;

  $t = runs();
  is_deeply(events { $t->tagRemove('x', '1.1', '1.8') }, [],
	    'runs shortened keep their values');
  is_deeply(events { $t->tagDelete('x') },
	    ['drop run [x 1.0 1.1] r1 (tag delete)', 'drop run [x 1.8 1.9] r2 (tag delete)'],
	    'tag delete');
  is_deeply(\@bad, [], 'each place named its value during the call');
  $t->destroy;

  # With -undo: into the step, and back.
  $t = runs(-undo => 1);
  is_deeply(events { $t->tagRemove('x', '1.5', '1.9') },
	    ['stash run [x 1.6 1.9] r2 (tag remove)'], 'with -undo, into the step');
  is_deeply(events { $t->editUndo }, ['restore run [x 1.6 1.9] r2 (undo)'],
	    'the undo gives it back');
  is_deeply(events { $t->editRedo }, ['stash run [x 1.6 1.9] r2 (redo)'],
	    'the redo takes it again');
  is_deeply(\@bad, [], 'each place named its value during the call');
  $t->destroy;
}

# ---------------------------------------------------------------------
# Deletion.
{
  my $t = fraction();
  $t->blockNodedata('2.1', 0, V->new('num'));
  $t->blockNodedata('2.5', 0, V->new('mid'));
  $t->blockNodedata('2.9', 0, V->new('den'));
  is_deeply(events { $t->delete('2.4', '2.8') },
	    ['drop node [2.5 0] mid (delete)'], 'deleting |mid deletes the leaf mid');
  $t->blockNodedata('2.1', 0, undef);
  @log = ();
  is_deeply(events { $t->delete('2.2', '2.6') },
	    ['move node [2.5 0 [2.1 0]] den (delete)'],
	    'a join: the end leaf\'s value moves to the start leaf without one');
  is(lab($t->blockNodedata('2.1', 0)), 'den', 'and is there');
  is_deeply(\@log, [], 'nothing was freed');
  is_deeply(\@bad, [], 'each place named its value during the call');
  $t->destroy;

  # A block deleted, a block dissolved: all their values.
  $t = fraction(-undo => 1);
  $t->blockNodedata('2.1', 0, V->new('num'));
  $t->blockNodedata('2.9', -1, V->new('root'));
  $t->blockData('2.1', V->new('data'));
  is_deeply(events { $t->delete('2.0', '2.13') },
	    ['stash block [2.0] data (delete)', 'stash node [2.1 0] num (delete)',
	     'stash node [2.1 1] root (delete)'], 'a block deleted, with -undo');
  my $undone = events { $t->editUndo };
  is_deeply([ sort @$undone ],
	    ['restore block [2.0] data (undo)', 'restore node [2.1 0] num (undo)',
	     'restore node [2.1 1] root (undo)'], 'the undo gives them back');
  is_deeply(events { $t->configure(-undo => 0); $t->delete('1.2', '2.3') },
	    ['drop block [2.0] data (delete)', 'drop node [2.1 0] num (delete)',
	     'drop node [2.1 1] root (delete)'], 'a block dissolved (its head deleted)');
  is_deeply(\@bad, [], 'each place named its value during the call');
  $t->destroy;

  # Runs: the gap between two runs deleted.
  $t = runs();
  is_deeply(events { $t->delete('1.3', '1.6') },
	    ['drop run [x 1.6 1.9] r2 (delete)'], 'a deletion joins two runs');
  is_deeply(events { $t->delete('1.0', '1.end') },
	    ['drop run [x 1.0 1.6] r1 (delete)'], 'a run deleted');
  $t->destroy;
}

# ---------------------------------------------------------------------
# Block insert and block trim.
{
  my $t = fraction();
  $t->blockNodedata('2.5', 0, V->new('mid'));
  $t->blockNodedata('2.9', 0, V->new('den'));
  $t->blockConfigure('G');
  is_deeply(events { $t->blockInsert('G', '2.6', '2.10') },
	    ['drop node [2.9 0] den (block insert)'],
	    'block insert: the two parts left of the leaves join');
  $t->destroy;

  $t = fraction();
  $t->blockNodedata('2.9', 0, V->new('den'));
  $t->blockConfigure('G');
  is_deeply(events { $t->blockInsert('G', '2.6', '2.10') },
	    ['move node [2.9 0 [2.5 0]] den (block insert)'],
	    'the first part has no value: the second\'s moves');
  $t->destroy;

  $t = fraction();
  $t->blockSplit('2.4', 1);		# {num||mid|den}: num, (mid den)
  $t->blockNodedata('2.6', -1, V->new('root'));
  $t->blockNodedata('2.6', 1, V->new('node'));
  $t->blockConfigure('G');
  is_deeply(events { $t->blockInsert('G', '2.2', '2.12') },
	    ['drop node [2.5 1] node (block insert)'],
	    'a node all of whose leaves move into the new block goes');
  $t->destroy;

  $t = widget();
  $t->insert('end', "num\nden\n");
  $t->blockInsert('F', '1.0', '2.3');
  $t->blockSplit('1.6', 2);		# a root above, two nodes below it
  $t->delete('1.6');			# root - node - leaves
  $t->blockNodedata('1.2', -1, V->new('root'));
  $t->blockNodedata('1.2', -2, V->new('child'));
  is_deeply(events { $t->blockTrim('1.2') },
	    ['drop node [1.1 2] child (block trim)'],
	    'block trim: the root keeps its value, the child\'s goes');
  is(lab($t->blockNodedata('1.2', -1)), 'root', 'the new root has the old root\'s');
  is_deeply(\@bad, [], 'each place named its value during the call');
  $t->destroy;
}

# ---------------------------------------------------------------------
# Undo steps thrown away: discard, at the end of the command, with the
# place the step recorded.
{
  for my $how (['edit reset', [], sub { $_[0]->editReset }, 'reset'],
	       ['-maxundo', [-maxundo => 1, -autoseparators => 0], sub {
		  my $u = shift;
		  $u->editSeparator; $u->insert('1.0', 'q'); $u->editSeparator;
		  $u->insert('1.0', 'r'); $u->editSeparator }, 'separator'],
	       ['a new change after an undo', [], sub {
		  my $u = shift; $u->editUndo; $u->insert('1.0', 'q') }, 'insert']) {
    my ($what, $options, $discard, $cause) = @$how;
    my $t = runs(-undo => 1, @$options);
    if ($what =~ /after an undo/) {
      # The undo of an insertion keeps a run made in it, for the redo.
      $t->insert('2.0', 'zzz');
      $t->configure(-undo => 0);
      $t->tagData('x', '1.6', undef);
      $t->tagAdd('x', '2.0', '2.2');
      $t->tagData('x', '2.0', V->new('r2'));
      $t->configure(-undo => 1);
    } else {
      $t->tagRemove('x', '1.5', '1.9');
    }
    $t->editSeparator;
    @log = ();
    my $e = events { $discard->($t) };
    my @d = grep { /^discard/ } @$e;
    my $at = ($what =~ /after an undo/) ? '2.0' : '1.6';
    is_deeply(\@d, ["discard run [x $at] r2 ($cause)"], "$what: discard");
    is_deeply(\@log, ['r2'], "$what: and the value is freed");
    $t->destroy;
  }
}

# ---------------------------------------------------------------------
# What is not told: the widget's destruction; nothing without the option.
{
  my $t = fraction();
  $t->blockNodedata('2.1', 0, V->new('num'));
  @log = ();
  is_deeply(events { $t->destroy }, [], 'destroying the widget tells nothing');
  is_deeply(\@log, ['num'], 'and frees the values');

  $t = fraction(-valuecommand => undef);
  ok(!defined $t->cget('-valuecommand'), 'no -valuecommand');
  $t->blockNodedata('2.1', 0, V->new('num'));
  $t->blockNodedata('2.9', 0, V->new('den'));
  is_deeply(events { $t->delete('2.2', '2.10') }, [], 'nothing is told');
  $t->configure(-valuecommand => \&cb);
  $t->blockNodedata('2.1', 0, V->new('num2'));
  is_deeply(events { $t->blockNodedata('2.1', 0, undef) },
	    ['drop node [2.1 0] num2 (set)'], 'the option set later works');
  $t->configure(-valuecommand => undef);
  $t->blockNodedata('2.1', 0, V->new('num3'));
  is_deeply(events { $t->blockNodedata('2.1', 0, undef) }, [],
	    'and unset, stops');
  $t->destroy;
}
# ---------------------------------------------------------------------
# The ready-made callback: -valuecommand => 'DETACH' calls the method
# DETACH of a value that is an object having one, and skips the others.
{
  my @calls;
  {
    package D;
    sub new { my ($class, $name) = @_; bless { n => $name }, $class }
    sub DETACH { my ($self, @args) = @_; push @calls, [$self->{n}, @args] }
  }
  my $t = fraction(-valuecommand => 'DETACH', -undo => 1);
  $t->blockNodedata('2.1', 0, D->new('num'));
  $t->blockNodedata('2.5', 0, V->new('mid'));	# no DETACH method
  $t->blockNodedata('2.9', 0, 'den');		# not an object
  $t->editReset;
  $t->delete('2.0', '2.13');
  is(scalar(@calls), 1, 'only the value that can DETACH is called');
  my ($n, $w, $event, $kind, $where, $cause) = @{$calls[0] || []};
  is($n, 'num', 'its method');
  ok(ref $w && $w == $t, 'gets the widget');
  is("$event $kind [@$where] $cause", 'stash node [2.1 0] delete',
     'the event, kind, place and cause');
  @calls = ();
  $t->editUndo;
  is(join(' ', map { "$_->[0] $_->[2] [@{$_->[4]}] $_->[5]" } @calls),
     'num restore [2.1 0] undo', 'and is told when the undo gives it back');
  @calls = ();
  $t->blockNodedata('2.1', 0, undef);
  is(join(' ', map { "$_->[0] $_->[2] $_->[5]" } @calls), 'num drop set',
     'and when it is dropped');
  @calls = ();
  $t->blockNodedata('2.1', 0, D->new('again'));
  $t->destroy;
  is(scalar(@calls), 0, 'nothing when the widget is destroyed');

  # A subclass may have a DETACH method of its own: 'DETACH' names it.
  our @mine;
  {
    package Tk::eTextSub;
    our @ISA = ('Tk::eText');
    Construct Tk::Widget 'eTextSub';
    sub DETACH { push @main::mine, $_[1]; shift->SUPER::DETACH(@_) }
  }
  $t = $mw->eTextSub(-valuecommand => 'DETACH');
  $t->blockConfigure('F');
  $t->insert('end', "num\nden\n");
  $t->blockInsert('F', '1.0', '2.3');
  $t->blockNodedata('1.1', 0, D->new('x'));
  @calls = ();
  $t->blockNodedata('1.1', 0, undef);
  is_deeply(\@mine, ['drop'], 'a subclass\'s DETACH is called');
  is(scalar(@calls), 1, 'and may pass it on');
  $t->destroy;
}
$mw->destroy;
