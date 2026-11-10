#!/usr/bin/perl
# Values of marks ("mark data"): kept through moves, edits and undo,
# freed exactly when they are replaced, the mark is unset or the widget
# is destroyed.  The values are objects whose DESTROY method records
# that it ran (as in t/values.t).
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
plan tests => 58;
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
sub mv { my ($t, $m) = @_; my $v = $t->markData($m);
	 return defined $v ? (ref $v ? $v->{n} : $v) : undef }
sub dies_like { my ($code, $re, $name) = @_;
		my $ok = !eval { $code->(); 1 }; like($ok ? $@ : 'no error', $re, $name) }

{
  my $t = $mw->eText(-width => 30, -height => 6, -undo => 1)->pack;
  $t->insert('end', "abcdef\nghijkl\nmnop\n");
  $t->editReset;
  $t->markSet('m', '1.3');

  # Reading, setting, errors.
  ok(!defined $t->markData('m'), 'a mark starts without a value');
  dies_like(sub { $t->markData('nosuch') }, qr/^there is no mark named "nosuch"/,
	    'a mark that does not exist');
  dies_like(sub { $t->markData('nosuch', 1) }, qr/^there is no mark named "nosuch"/,
	    'setting it neither');
  dies_like(sub { $t->mark('data') }, qr/wrong # args/, 'wrong # args');
  dies_like(sub { $t->mark('data', 'm', 1, 2) }, qr/wrong # args/, 'too many');
  dies_like(sub { $t->mark('nosuch') }, qr/must be data, gravity/,
	    'the bad option message names data');
  my $s = 'plain';
  $t->markData('m', $s);
  $s .= ' changed';
  is($t->markData('m'), 'plain', 'a copy of the scalar is kept');
  my $obj = V->new('m1');
  is_deeply(freed { $t->markData('m', $obj) }, [], 'replacing a string frees no object');
  undef $obj;
  is_deeply(\@log, [], 'the object lives on in the mark');
  is(mv($t, 'm'), 'm1', 'and is read back');

  # Kept: moves, gravity, edits, undo and redo, edit reset.
  is_deeply(freed { $t->markSet('m', '2.2') }, [], 'mark set on the existing mark keeps it');
  is($t->index('m'), '2.2', 'the mark moved');
  is(mv($t, 'm'), 'm1', 'with its value');
  is_deeply(freed { $t->markGravity('m', 'left'); $t->markGravity('m', 'right') }, [],
	    'changing the gravity keeps it');
  is_deeply(freed { $t->insert('2.1', 'XY'); $t->insert('2.4', "Z\n") }, [],
	    'insertions around the mark keep it');
  is_deeply(freed { $t->delete('2.0', '3.3') }, [], 'deleting the text around the mark keeps it');
  is($t->index('m'), '2.0', 'the mark is at the place of the deletion');
  is(mv($t, 'm'), 'm1', 'still with its value');
  is_deeply(freed { $t->editUndo }, [], 'undo puts the mark back');
  is($t->index('m'), '3.0', 'where it was');
  is(mv($t, 'm'), 'm1', 'with its value');
  is_deeply(freed { $t->editRedo; $t->editUndo; $t->editReset }, [],
	    'redo, undo and edit reset keep it');
  is(mv($t, 'm'), 'm1', 'the value is still there');

  # Freed: replaced, set to undef, mark unset; the widget is consistent
  # when the object is destroyed.
  my $seen;
  $t->markData('m', V->new('m2', sub { $seen = join ',', grep { $_ eq 'm' } $t->markNames }));
  is_deeply(\@log, ['m1'], 'replacing frees the old value, at once');
  @log = ();
  is_deeply(freed { $t->markData('m', undef) }, ['m2'], 'setting undef frees the value');
  ok(!defined $t->markData('m'), 'no value any more');
  is($seen, 'm', 'the mark still exists when its old value is destroyed');
  $t->markData('m', V->new('m3', sub { $seen = join ',', grep { $_ eq 'm' } $t->markNames }));
  $seen = 'not run';
  is_deeply(freed { $t->markUnset('m') }, ['m3'], 'mark unset frees the value');
  is($seen, '', 'once the mark is gone');
  $t->markSet('m', '1.1');
  ok(!defined $t->markData('m'), 'a mark set anew after unset starts without a value');

  # Several marks in one unset, in order; unset of a mark without a value.
  $t->markSet('p', '1.1');
  $t->markSet('q', '1.2');
  $t->markData('p', V->new('p'));
  $t->markData('q', V->new('q'));
  is_deeply(sfreed { $t->markUnset('p', 'm', 'q') }, ['p', 'q'],
	    'unsetting several marks frees each value once');

  # A mark recorded by an undoable deletion, unset, then the deletion
  # undone: the mark is re-created, without a value.
  $t->markSet('r', '1.2');
  $t->markData('r', V->new('r'));
  $t->delete('1.1', '1.4');
  is_deeply(freed { $t->markUnset('r') }, ['r'], 'unset after the deletion frees the value');
  is_deeply(freed { $t->editUndo }, [], 'undo');
  is($t->index('r'), '1.2', 'the mark is re-created by the undo');
  ok(!defined $t->markData('r'), 'without a value');

  # insert and current.
  $t->markData('insert', V->new('ins'));
  $t->markData('current', 'cur');
  is_deeply(freed { $t->markSet('insert', '2.3'); $t->markUnset('insert', 'current') }, [],
	    'insert and current keep their values (unset ignores them)');
  is(mv($t, 'insert'), 'ins', 'the insert mark has a value');
  is($t->markData('current'), 'cur', 'and current');

  # A DESTROY method that edits the widget: allowed since 2.05 (see
  # t/freeing.t), reading works.
  $t->markSet('e', '1.0');
  my ($err, $read);
  $t->markData('e', V->new('e', sub { $read = $t->get('1.0');
	$err = eval { $t->insert('1.0', 'E'); 1 } ? 'ok' : $@ }));
  is_deeply(freed { $t->markData('e', undef) }, ['e'], 'a value whose DESTROY tries to edit the widget');
  is($err, 'ok', 'the edit works');
  is($t->get('1.0'), 'E', 'and is made; reading worked: '.$read);

  # The widget destroyed: all the values go, after the widget.
  my $after;
  $t->markSet('z', '2.0');
  $t->markData('z', V->new('z', sub { $after = eval { $t->index('end'); 'alive' } || 'gone' }));
  is_deeply(sfreed { $t->destroy; $mw->update }, ['ins', 'z'],
	    'destroying the widget frees the remaining values');
  is($after, 'gone', 'after the widget is gone');
}

{
  # The Tk-level command.
  my $t = $mw->eText->pack;
  $t->insert('end', "abc");
  $t->markSet('m', '1.1');
  $t->mark('data', 'm', [1, 2]);
  is_deeply(scalar $t->mark('data', 'm'), [1, 2], 'mark data through the widget command');
  is_deeply(freed { $t->markSet('m', '1.2') }, [], 'moving');
  is_deeply(scalar $t->markData('m'), [1, 2], 'the value is a reference, kept as one');
  $t->destroy;
}

{
  # block list: a mark with a value is MarkLeft/MarkRight [name, value];
  # without one, a reference to its name, as before.
  my $t = $mw->eText(-undo => 1)->pack;
  $t->insert('end', "abcdef\n");
  $t->editReset;
  $t->markSet('r', '1.2');
  $t->markSet('l', '1.3');
  $t->markGravity('l', 'left');
  $t->markSet('n', '1.4');
  $t->markData('r', V->new('r'));
  $t->markData('l', 'lv');
  my @l = grep { ref($_) =~ /^Tk::Text::Mark/ } $t->blockList('1.1', '1.5');
  my %m = map { (UNIVERSAL::isa($_, 'ARRAY') ? $_->[0] : $$_) => $_ } @l;
  is(ref $m{r}, 'Tk::Text::MarkRight', 'a right-gravity mark with a value');
  ok(UNIVERSAL::isa($m{r}, 'ARRAY') && $m{r}[1]{n} eq 'r', 'is [name, value]');
  is(ref $m{l}, 'Tk::Text::MarkLeft', 'a left-gravity mark with a value');
  is_deeply([@{$m{l}}], ['l', 'lv'], 'is [name, value] too');
  is(ref $m{n}, 'Tk::Text::MarkRight', 'a mark without a value');
  ok(!UNIVERSAL::isa($m{n}, 'ARRAY') && ${$m{n}} eq 'n', 'is a reference to its name, as before');
  @l = (); %m = ();
  is_deeply(freed { $t->markData('r', undef) }, ['r'],
	    'the copy in the list does not keep the object alive');

  # The undo's own list leaves mark values out: a deletion over the mark
  # and its undo keep the value as it is, and hold no copy of it.
  $t->markData('r', V->new('r2'));
  my $obj = $t->markData('r');
  is_deeply(freed { $t->delete('1.0', '1.end'); $t->editUndo }, [], 'delete over the mark, undo');
  is($t->index('r'), '1.2', 'the mark is back');
  ok($t->markData('r') == $obj, 'with the same value, not a copy from the list');
  undef $obj;
  is_deeply(freed { $t->markData('r', undef) }, ['r2'],
	    'freed at once when replaced: the undo step holds no copy');
  $t->destroy;
}

SKIP: {
  skip 'Test::LeakTrace not installed', 1 unless $have_lt;
  my $t = $mw->eText(-undo => 1)->pack;
  $t->insert('end', "abcdef\n");
  Test::LeakTrace::leaks_cmp_ok(sub {
    $t->markSet('m', '1.2');
    $t->markData('m', { x => [1] });
    $t->markData('m', V->new('a'));
    $t->delete('1.0', '1.4');
    $t->editUndo;
    $t->markUnset('m');
    $t->editReset;
  }, '<', 5, 'mark values: no leaks');
  $t->destroy;
}

$mw->destroy;
