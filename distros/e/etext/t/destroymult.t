#!/usr/bin/perl
# DESTROY methods run while the values a widget command dropped are
# freed may change the widget; the values such a change drops are freed
# in the next round of the same pass.  At the limit of the pass (10 to
# begin with) the widget asks the object whose DESTROY method makes the
# change, $object->DESTROYmult($n, $limit): a positive integer $more
# raises the limit by $more, anything else (no such method, 0, undef, a
# negative number, not a number, a non-object, a method that dies) and
# the change is refused.
use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require Tk; 1 } or plan skip_all => "Tk not available: $@";
}
use Tk::eText;

my $mw = eval { MainWindow->new };
plan skip_all => "no X display available ($@)" unless $mw;
plan tests => 246;
$mw->geometry('+10+10');

my @bgerrors;
local *Tk::Error = sub { push @bgerrors, $_[1] };

my $u = $mw->eText(-undo => 1)->pack;
my $path = $u->PathName;
sub refused { qr/^cannot modify \Q$path\E while its values are being freed, $_[0] changes deep/ }
sub text { $u->get('1.0', 'end -1c') // '' }

# A chain: the value numbered $k, freed in round $k, inserts "$k," at
# the end of the text and drops a new value $k+1 (set on the mark p,
# then unset) as long as $k <= $N.  So $N changes are wanted, the k-th
# in round k.  The package of the values decides what DESTROYmult does.
our ($N, @chain, @asks, @errors, %freed);
{
  package Chain;
  sub new { my ($class, $n) = @_; bless { n => $n }, $class }
  sub DESTROY {
    my $self = shift;
    $freed{$self->{n}}++;
    return if !$self->{n} || $self->{n} > $N;
    my $next = (ref $self)->new($self->{n} + 1);
    if (eval {
      $u->insert('end -1c', "$self->{n},");
      $u->markData('p', $next);
      $u->markData('p', undef);
      1 }) {
      push @chain, $self->{n};
    } else {
      push @errors, $@;
      $next->{n} = 0;			# inert, freed when this returns
    }
  }
  package Chain::None;   our @ISA = ('Chain');
  package Chain::Zero;   our @ISA = ('Chain');
  sub DESTROYmult { push @asks, [$_[0]{n}, @_[1, 2]]; 0 }
  package Chain::Five;   our @ISA = ('Chain');
  sub DESTROYmult { push @asks, [$_[0]{n}, @_[1, 2]]; 5 }
  package Chain::Dies;   our @ISA = ('Chain');
  sub DESTROYmult { push @asks, [$_[0]{n}, @_[1, 2]]; die "no more\n" }
  package Chain::Undef;  our @ISA = ('Chain');
  sub DESTROYmult { push @asks, [$_[0]{n}, @_[1, 2]]; undef }
  package Chain::Neg;    our @ISA = ('Chain');
  sub DESTROYmult { push @asks, [$_[0]{n}, @_[1, 2]]; -5 }
  package Chain::NaN;    our @ISA = ('Chain');
  sub DESTROYmult { push @asks, [$_[0]{n}, @_[1, 2]]; 'many' }
  package Chain::Frac;   our @ISA = ('Chain');
  sub DESTROYmult { push @asks, [$_[0]{n}, @_[1, 2]]; 2.5 }
}

sub run_chain {
  my ($class, $n) = @_;
  local $N = $n;
  @chain = @asks = @errors = @bgerrors = ();
  %freed = ();
  $u->delete('1.0', 'end');
  $u->markSet('p', '1.0');
  $u->editReset;
  $u->markData('p', $class->new(1));
  $u->markData('p', undef);		# the pass starts here
  $mw->update;				# the background errors
}

# Every value freed exactly once: those of the chain (1 .. last), and
# the one the last DESTROY made and could not drop, if any (n = 0).
sub freed_once {
  my ($last, $what) = @_;
  my @want = (1 .. $last);
  my @got = sort { $a <=> $b } grep { $_ } keys %freed;
  is_deeply(\@got, \@want, "$what: the values freed are 1 .. $last");
  ok(!grep({ $_ != 1 } values %freed), "$what: each once");
}

# Without DESTROYmult, and with one answering 5, for 9, 10, 25 and 100
# rounds.
for my $n (9, 10, 25, 100) {
  run_chain('Chain::None', $n);
  my $made = $n < 10 ? $n : 9;
  is_deeply(\@chain, [1 .. $made], "no DESTROYmult, $n rounds: $made changes made");
  if ($n < 10) {
    is(scalar @errors, 0, "no DESTROYmult, $n rounds: nothing refused");
  } else {
    is(scalar @errors, 1, "no DESTROYmult, $n rounds: refused once");
    like($errors[0], refused(10), "no DESTROYmult, $n rounds: at the limit 10");
  }
  freed_once($made + 1, "no DESTROYmult, $n rounds");
  is(text(), join('', map "$_,", 1 .. $made),
     "no DESTROYmult, $n rounds: the text");

  run_chain('Chain::Five', $n);
  is_deeply(\@chain, [1 .. $n], "DESTROYmult 5, $n rounds: all $n changes made");
  is(scalar @errors, 0, "DESTROYmult 5, $n rounds: nothing refused");
  # Asked in rounds 10, 15, 20, ... up to $n, by the value freed there.
  my @want;
  for (my ($k, $limit) = (1, 10); $limit <= $n; $k++, $limit += 5) {
    push @want, [$limit, $k, $limit];
  }
  is_deeply(\@asks, \@want, "DESTROYmult 5, $n rounds: asked with \$n and \$limit as specified")
    or diag(join ' ', map "[@$_]", @asks);
  freed_once($n + 1, "DESTROYmult 5, $n rounds");
  is(text(), join('', map "$_,", 1 .. $n),
     "DESTROYmult 5, $n rounds: the text");
}

# The changes made from DESTROY methods are undo steps of their own,
# beyond the limit too.
{
  run_chain('Chain::Five', 25);
  my $ok = 1;
  for my $k (reverse 1 .. 25) {
    $u->editUndo;
    $ok &&= text() eq join('', map "$_,", 1 .. $k - 1);
  }
  ok($ok, 'each undo takes back one change made from a DESTROY method');
  for my $k (1 .. 25) {
    $u->editRedo;
    $ok &&= text() eq join('', map "$_,", 1 .. $k);
  }
  ok($ok, 'each redo makes one again');
  is(text(), join('', map "$_,", 1 .. 25), 'all 25 are back');
  is(scalar keys %freed, 26, 'undo and redo freed nothing more');
}

# Answers that refuse: 0, undef, a negative number, not a number, not an
# integer; a method that dies (a background error); and a DESTROY method
# that has replaced its arguments, so that there is no object to ask
# (Chain::Lost).
{
  package Chain::Lost; our @ISA = ('Chain::Five');
  sub DESTROY { my $self = $_[0]; @_ = ('plain'); Chain::DESTROY($self) }
}
for my $case (['Chain::Zero', '0'], ['Chain::Undef', 'undef'],
	      ['Chain::Neg', 'a negative number'], ['Chain::NaN', 'not a number'],
	      ['Chain::Frac', '2.5'], ['Chain::Dies', 'a method that dies'],
	      ['Chain::Lost', 'no object']) {
  my ($class, $what) = @$case;
  for my $n (9, 10, 25, 100) {
    my $w = "$what, $n rounds";
    run_chain($class, $n);
    my $made = $n < 10 ? $n : 9;
    is_deeply(\@chain, [1 .. $made], "$w: $made changes made");
    freed_once($made + 1, $w);
    if ($n < 10) {
      ok(!@asks && !@errors && !@bgerrors, "$w: nothing asked or refused");
      next;
    }
    is_deeply(\@asks, $class eq 'Chain::Lost' ? [] : [[10, 1, 10]],
	      $class eq 'Chain::Lost' ? "$w: nobody asked" : "$w: asked once, (1, 10)");
    is(scalar @errors, 1, "$w: one refusal");
    like($errors[0], refused(10), "$w: at the limit 10");
    if ($class eq 'Chain::Dies') {
      is(scalar @bgerrors, 1, "$w: a background error");
      like($bgerrors[0] // '', qr/^no more/, "$w: with its message");
    } else {
      is(scalar @bgerrors, 0, "$w: no background error");
    }
  }
}

# The limit and the count of requests belong to one pass: the next
# command starts again at 10 with request 1.
{
  run_chain('Chain::Five', 12);
  run_chain('Chain::Five', 12);
  is_deeply(\@asks, [[10, 1, 10]], 'the next pass starts again: (1, 10)');
}

# Several changes in the round at the limit: the first asks, the limit
# is raised, the others are made without asking.  An answer of 1 makes
# the widget ask again in the next round, with the next $n.
{
  package Chain::One; our @ISA = ('Chain');
  sub DESTROYmult { push @asks, [$_[0]{n}, @_[1, 2]]; 1 }
}
run_chain('Chain::One', 13);
is_deeply(\@chain, [1 .. 13], 'DESTROYmult 1: all 13 changes made');
is_deeply(\@asks, [[10, 1, 10], [11, 2, 11], [12, 3, 12], [13, 4, 13]],
	  'asked once per round from round 10 on, with $limit + 1');

# A DESTROYmult that tries to change the widget: refused without asking
# again; its answer still counts.
{
  package Chain::Meddles; our @ISA = ('Chain');
  our @tried;
  sub DESTROYmult {
    push @asks, [$_[0]{n}, @_[1, 2]];
    push @tried, eval { $u->insert('1.0', 'X'); 1 } ? 'ok' : $@;
    5;
  }
}
@Chain::Meddles::tried = ();
run_chain('Chain::Meddles', 12);
is_deeply(\@chain, [1 .. 12], 'a DESTROYmult that meddles: its answer counts');
is(scalar @asks, 1, 'and it is not asked again');
like($Chain::Meddles::tried[0] // '', refused(10), 'its own change is refused');
unlike($u->get('1.0'), qr/X/, 'and not made');

# A value nested in another: the object whose DESTROY method makes the
# change is asked, here one held by a plain array that is the value.
{
  package Inner; our @ISA = ('Chain');
  sub DESTROYmult { push @asks, ['inner', @_[1, 2]]; 5 }
  package Outer;
  sub new { my ($class, $n) = @_; bless { n => $n, inner => Inner->new($n) }, $class }
  sub DESTROYmult { push @asks, ['outer', @_[1, 2]]; 0 }
  sub DESTROY { delete $_[0]{inner} }	# the Inner's DESTROY runs inside
}
{
  local $N = 12;
  @chain = @asks = @errors = ();
  %freed = ();
  $u->delete('1.0', 'end');
  $u->editReset;
  # Rounds 1 to 9: a chain of plain Chain::None values; the 9th drops a
  # value that is an unblessed array holding an Inner, whose DESTROY
  # makes the change of round 10.
  no warnings 'redefine';
  local *Chain::None::new = sub {
    my ($class, $n) = @_;
    $n == 10 ? [Inner->new(10)] : bless { n => $n }, $class;
  };
  $u->markData('p', Chain::None->new(1));
  $u->markData('p', undef);
  is_deeply(\@chain, [1 .. 12], 'a value held by an unblessed array: the chain goes on');
  is_deeply(\@asks, [['inner', 1, 10]], 'the object whose DESTROY changes the widget is asked');
  freed_once(13, 'a value held by an unblessed array');

  # An Outer value: its DESTROY method has returned when the Inner it
  # holds is freed, and the Inner's DESTROY makes the change.
  @chain = @asks = @errors = ();
  %freed = ();
  local *Chain::None::new = sub {
    my ($class, $n) = @_;
    $n == 10 ? Outer->new(10) : bless { n => $n }, $class;
  };
  $u->markData('p', Chain::None->new(1));
  $u->markData('p', undef);
  is_deeply(\@asks, [['inner', 1, 10]],
	    'an object freed by the DESTROY of the value: the innermost is asked');
  is_deeply(\@chain, [1 .. 12], 'and its answer counts');
  freed_once(13, 'a value nested in an object');
}

# DESTROYmult is a method: an inherited one is found.
{
  package Chain::Parent; our @ISA = ('Chain::Five');
}
run_chain('Chain::Parent', 12);
is_deeply(\@asks, [[10, 1, 10]], 'an inherited DESTROYmult is asked');
is_deeply(\@chain, [1 .. 12], 'and its answer counts');
$u->destroy;
$mw->destroy;
