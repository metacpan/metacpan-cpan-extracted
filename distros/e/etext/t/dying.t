#!/usr/bin/perl
# When Perl code that the widget calls dies (the manual, "When Perl code
# called by the widget dies"):
# - a DESTROY method that dies: Perl makes the error an "(in cleanup)"
#   warning if warnings are on where it is raised; the value is freed,
#   the other values waiting are freed, and the widget command that
#   dropped them returns normally;
# - a change refused inside a DESTROY method: the same (the refusal is
#   an error raised inside DESTROY, by a Perl/Tk method compiled without
#   "use warnings", so the warning needs perl -w), and an eval inside
#   DESTROY catches it;
# - the -valuecommand callback, or a DETACH method under the ready-made
#   'DETACH', that dies: a background error (Tk::Error), the command
#   goes on, nothing leaks;
# - DESTROYmult that dies: a background error, the answer counts as 0
#   (t/destroymult.t has the rest).
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(weaken);

BEGIN {
  eval { require Tk; 1 } or plan skip_all => "Tk not available: $@";
}
use Tk::eText;

my $mw = eval { MainWindow->new };
plan skip_all => "no X display available ($@)" unless $mw;
plan tests => 85;
$mw->geometry('+10+10');

my (@warnings, @bgerrors, %freed);
local $SIG{__WARN__} = sub { push @warnings, $_[0] };
local *Tk::Error = sub { push @bgerrors, $_[1] };
sub reset_logs { @warnings = @bgerrors = (); %freed = () }

{
  package V;			# a value; it dies in DESTROY if asked to
  sub new { my ($class, $n, %opt) = @_; bless { n => $n, %opt }, $class }
  sub DESTROY {
    my $self = shift;
    $freed{$self->{n}}++;
    $self->{hook}->($self) if $self->{hook};
    die "DESTROY $self->{n} died\n" if $self->{die};
  }
  package V::Quiet;		# the same, where warnings are off
  no warnings;
  our @ISA = ('V');
  sub DESTROY {
    my $self = shift;
    $freed{$self->{n}}++;
    die "DESTROY $self->{n} died\n";
  }
}

my $u = $mw->eText(-undo => 1)->pack;
my $path = $u->PathName;
$u->insert('1.0', "abcdef\nghijkl\n");
$u->markSet($_, '1.2') for qw(a b c p q1 q2);

# ---------------------------------------------------------------------
# A DESTROY method dies.
reset_logs();
my @weak;
$u->markData('a', V->new('a', die => 1));
$u->markData('b', V->new('b'));
$u->markData('c', V->new('c', die => 1));
for (qw(a b c)) { push @weak, $u->markData($_); weaken($weak[-1]) }
my $r = eval { $u->markUnset('a', 'b', 'c'); 'returned' } // "died: $@";
is($r, 'returned', 'DESTROY dies: the command returns normally');
is_deeply(\%freed, { a => 1, b => 1, c => 1 }, 'each value is freed once, the others too');
ok(!grep(defined, @weak), 'and is gone');
is(scalar @warnings, 2, 'two warnings');
like($warnings[0] // '', qr/^\t\(in cleanup\) DESTROY a died$/, 'the first "(in cleanup)"');
like($warnings[1] // '', qr/^\t\(in cleanup\) DESTROY c died$/, 'the second');
$mw->update;
is(scalar @bgerrors, 0, 'no background error');
ok(eval { $u->insert('1.0', 'X'); $u->delete('1.0'); 1 }, 'the widget works on');

# Where the DESTROY method has warnings off, Perl says nothing.
reset_logs();
$u->markSet('a', '1.2');
$u->markData('a', V::Quiet->new('quiet'));
$r = eval { $u->markData('a', undef); 'returned' } // "died: $@";
is($r, 'returned', 'DESTROY dies, warnings off: the command returns normally');
is_deeply(\%freed, { quiet => 1 }, 'the value is freed');
is(scalar @warnings, 0, 'and the error is lost');

# A DESTROY method that makes a change of its own and then dies: the
# change is made and is a step of its own; the values it dropped are
# freed in the same pass.
reset_logs();
$u->editReset;
$u->markData('q1', V->new('dropped'));
$u->markData('a', V->new('changes', die => 1, hook => sub {
  $u->insert('1.0', 'Y');
  $u->markData('q1', undef);
}));
$r = eval { $u->markUnset('a'); 'returned' } // "died: $@";
is($r, 'returned', 'a DESTROY that changes the widget, then dies: the command returns');
is($u->get('1.0'), 'Y', 'the change is made');
is_deeply(\%freed, { changes => 1, dropped => 1 }, 'the value it dropped is freed too, once');
is(scalar @warnings, 1, 'one warning');
$u->editUndo;
is($u->get('1.0', '1.end'), 'abcdef', 'the change is undone');
$u->editRedo;
is($u->get('1.0'), 'Y', 'and redone');
$u->delete('1.0');
$u->editReset;

# ---------------------------------------------------------------------
# A change refused inside a DESTROY method: the 10th round of a chain.
# Values 1 .. 8 each insert "n," and drop the next one (on the mark p);
# value 9 drops two (on the marks q1 and q2), freed in round 10, where
# their inserts are refused.
my $chain_hook;
sub link_value {
  my ($n) = @_;
  V->new($n, hook => $chain_hook);
}
#
# The refusal is an error raised by the widget method (a Perl/Tk method
# compiled in Tk.pm, where "use warnings" is not on): if it leaves
# DESTROY, Perl's "(in cleanup)" warning is given only under perl -w
# ($^W); the error rethrown by code under "use warnings" is warned.
for my $how ('caught', 'rethrown', 'direct, $^W', 'direct') {
  reset_logs();
  my @caught;
  local $^W = $how eq 'direct, $^W';
  $chain_hook = sub {
    my $self = shift;
    if ($how =~ /^direct/) {
      $u->insert('end -1c', "$self->{n},");
    } elsif (!eval { $u->insert('end -1c', "$self->{n},"); 1 }) {
      die $@ if $how eq 'rethrown';
      push @caught, $@;
      return;
    }
    if ($self->{n} eq '9') {
      $u->markData('q1', link_value('10a'));
      $u->markData('q2', link_value('10b'));
      $u->markData($_, undef) for qw(q1 q2);
    } else {
      $u->markData('p', link_value($self->{n} + 1));
      $u->markData('p', undef);
    }
  };
  my $what = "refused, $how";
  $u->markData('p', link_value(1));
  $r = eval { $u->markData('p', undef); 'returned' } // "died: $@";
  is($r, 'returned', "$what: the command returns normally");
  is($u->get('1.0', 'end -1c'), "abcdef\nghijkl\n1,2,3,4,5,6,7,8,9,",
     "$what: the changes up to round 9 are made");
  is_deeply([sort keys %freed], [sort(1 .. 9, '10a', '10b')],
	    "$what: every value is freed");
  ok(!grep({ $_ != 1 } values %freed), "$what: once");
  my $refusal = qr/cannot modify \Q$path\E while its values are being freed, 10 changes deep/;
  my @cleanup = grep /^\t\(in cleanup\)/, @warnings;
  if ($how eq 'caught') {
    is(scalar @warnings, 0, "$what: no warning");
    is(scalar @caught, 2, "$what: both refusals caught");
    like($caught[0] // '', qr/^$refusal/, "$what: \$@ is the refusal");
  } elsif ($how eq 'direct') {
    is(scalar @warnings, 0, "$what: without perl -w, no warning: the error is lost");
  } else {
    is(scalar @cleanup, 2, "$what: two warnings");
    like($cleanup[0] // '', qr/^\t\(in cleanup\) $refusal/,
	 "$what: \"(in cleanup)\" with the refusal");
    like($cleanup[1] // '', qr/^\t\(in cleanup\) $refusal/,
	 "$what: for the other value of the round too");
  }
  $u->delete('3.0', 'end -1c');
  $u->editReset;
}
undef $chain_hook;

# ---------------------------------------------------------------------
# DESTROYmult dies: a background error; the change is refused.
{
  package V::Mult; our @ISA = ('V');
  sub DESTROYmult { die "DESTROYmult died\n" }
}
reset_logs();
$chain_hook = sub {
  my $self = shift;
  $u->insert('end -1c', "$self->{n},");	# refused at the limit: dies
  $u->markData('p', V::Mult->new($self->{n} + 1, hook => $chain_hook));
  $u->markData('p', undef);
};
$u->markData('p', V::Mult->new(1, hook => $chain_hook));
{
  local $^W = 1;
  $r = eval { $u->markData('p', undef); 'returned' } // "died: $@";
}
$mw->update;
is($r, 'returned', 'DESTROYmult dies: the command returns normally');
is(scalar @bgerrors, 1, 'DESTROYmult dies: a background error');
like($bgerrors[0] // '', qr/^DESTROYmult died/, 'with its message');
my @cleanup = grep /^\t\(in cleanup\)/, @warnings;
is(scalar @cleanup, 1, 'and the refusal, not caught, is a warning (perl -w)');
like($cleanup[0] // '', qr/10 changes deep/, 'naming the limit 10');
is_deeply([sort { $a <=> $b } keys %freed], [1 .. 10], 'every value is freed');
ok(!grep({ $_ != 1 } values %freed), 'once');
undef $chain_hook;
$u->delete('3.0', 'end -1c');
$u->editReset;
$u->destroy;

# ---------------------------------------------------------------------
# The -valuecommand callback dies on every call: each call is a
# background error, the commands go on, the values are freed when they
# should be and once, and nothing the callback got is kept.
my (@events, @kept);
my $t = $mw->eText(-undo => 1, -valuecommand => sub {
  my ($w, $event, $kind, $where, $value, $cause) = @_;
  push @events, "$event $kind ($cause)";
  push @kept, $where, \$_[4];
  weaken($_) for @kept[-2, -1];
  die "callback died on $event\n";
})->pack;
$t->blockConfigure('F');
$t->insert('end', "abcdef\nnum\nden\n");
$t->blockInsert('F', '2.0', '3.3');	# Tells "new" (the callback dies).
$t->editReset;
$mw->update;
sub vc_check {
  my ($what, $command, $events, $freed) = @_;
  reset_logs();
  @events = ();
  my $r = eval { $command->(); 'returned' } // "died: $@";
  $mw->update;
  is($r, 'returned', "$what: the command returns normally");
  is_deeply(\@events, $events, "$what: the callback is called as usual");
  is(scalar @bgerrors, scalar @$events, "$what: each death is a background error");
  is_deeply(\%freed, $freed, "$what: the values freed");
}
$t->blockNodedata('2.1', 0, V->new('n1'));
vc_check('a node value replaced', sub { $t->blockNodedata('2.1', 0, V->new('n2')) },
	 ['drop node (set)'], { n1 => 1 });
is($t->blockNodedata('2.1', 0)->{n}, 'n2', 'the new value is set');
$t->tagAdd('x', '1.1', '1.3');
$t->tagData('x', '1.1', V->new('r1'));
$t->editReset;
vc_check('a run deleted', sub { $t->delete('1.0', '1.end') },
	 ['stash run (delete)'], {});
vc_check('undo', sub { $t->editUndo }, ['restore run (undo)'], {});
is($t->tagData('x', '1.1')->{n}, 'r1', 'the value is back');
vc_check('redo', sub { $t->editRedo }, ['stash run (redo)'], {});
vc_check('edit reset', sub { $t->editReset }, ['discard run (reset)'], { r1 => 1 });
$t->markSet('m', '1.0');
$t->markData('m', V->new('m1'));
vc_check('mark unset', sub { $t->markUnset('m') }, ['drop mark (unset)'], { m1 => 1 });
reset_logs();
$t->destroy;
is_deeply(\%freed, { n2 => 1 }, 'the widget destroyed: its last value is freed');
ok(!grep(defined, @kept), 'nothing the callback got is kept');

# ---------------------------------------------------------------------
# The ready-made 'DETACH': a DETACH method that dies.
{
  package V::Detach; our @ISA = ('V');
  our @calls;
  sub DETACH { push @calls, $_[2]; die "DETACH died\n" }
}
$t = $mw->eText(-undo => 1, -valuecommand => 'DETACH')->pack;
$t->insert('1.0', "abc\n");
$t->markSet('m', '1.1');
$t->markData('m', V::Detach->new('d1'));
reset_logs();
$r = eval { $t->markData('m', V::Detach->new('d2')); 'returned' } // "died: $@";
$mw->update;
is($r, 'returned', 'DETACH dies: the command returns normally');
is_deeply(\@V::Detach::calls, ['drop'], 'DETACH was called');
is(scalar @bgerrors, 1, 'its death is a background error');
like($bgerrors[0] // '', qr/^DETACH died/, 'with its message');
is_deeply(\%freed, { d1 => 1 }, 'the value is freed, once');
is($t->markData('m')->{n}, 'd2', 'the new value is set');
reset_logs();
$t->destroy;
is_deeply(\%freed, { d2 => 1 }, 'the last value is freed with the widget');
$mw->destroy;
