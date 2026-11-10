#!/usr/bin/perl
# -valuecommand, at random: widgets with blocks, nested and -empty
# blocks, values on most nodes, runs, marks and blocks, then random
# commands (deletions, insertions, tag changes, block insert, split and
# trim, values set and unset, marks, undo, redo, separators, edit reset,
# -maxundo), with "debug 1" (a detach the look-ahead did not foresee,
# or one foreseen that did not happen as told, is then an error).
# After each command:
#  - every value it detached was told drop or stash before the change,
#    at a place that named the value during the call ("blockNodedata"
#    of [index, level], the run, the mark, the block), and a move named
#    an existing new place;
#  - every value freed was told drop or discard; every value told drop
#    is freed, one told stash is not;
#  - every value that came back (undo, redo) was told restore;
#  - no "late" event, and the widget refused changes during the calls.
# ETEXT_RANDOM="first last runs ops" runs other seeds (the defaults are
# "1 40 20 60").
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(reftype);

BEGIN {
  eval { require Tk; 1 } or plan skip_all => "Tk not available: $@";
}
use Tk::eText;

my $mw = eval { MainWindow->new };
plan skip_all => "no X display available ($@)" unless $mw;
my ($first, $last, $runs, $nops) = split ' ', ($ENV{ETEXT_RANDOM} || '1 40 20 60');
plan tests => ($last - $first + 1) + 3;
$mw->geometry('+10+10');

my (@destroyed, $serial, @events, $t, %count);
{
  package V;
  sub new { bless { n => $_[1] }, $_[0] }
  sub DESTROY { push @destroyed, $_[0]{n} }
}
sub nv { V->new('v' . ++$serial) }
sub lab { my $v = shift; ref $v eq 'V' ? $v->{n} : defined $v ? "<$v>" : 'undef' }

# The value at a place, as the callback gets it.
sub at_place {
  my ($w, $kind, $where) = @_;
  my $v;
  if ($kind eq 'node') { $v = eval { $w->blockNodedata($where->[0], $where->[1]) } }
  elsif ($kind eq 'run') { $v = eval { $w->tagData($where->[0], $where->[1]) } }
  elsif ($kind eq 'mark') {
    $v = eval { $w->markData($where->[0]) };
    return 'moved' unless eval { $w->index($where->[0]) eq $where->[1] };
  } elsif ($kind eq 'block') {
    # The head of an -empty block, else the block's tail.
    my $i = $where->[0];
    my $c = eval { $w->get($i) } // '';
    if ($c eq '{') {
      my ($l, $p) = split /\./, $i;
      my $s = $w->get("$l.0", "$l.end");
      my $d = 0;
      for my $k ($p .. length($s) - 1) {
	my $ch = substr $s, $k, 1;
	$d++ if $ch eq '{';
	$d-- if $ch eq '}';
	if ($d == 0) { $i = "$l.$k"; last }
      }
    } elsif ($c ne '.') {
      return "no block at $i";
    }
    $v = eval { $w->blockData($i) };
  }
  lab($v);
}

sub cb {
  my ($w, $event, $kind, $where, $value, $cause) = @_;
  my $l = lab($value);
  my %e = (event => $event, kind => $kind, where => $where, label => $l, cause => $cause);
  if ($event =~ /^(drop|stash|move|restore)$/) {
    my $now = at_place($w, $kind, $where);
    $e{bad} = "names $now" unless $now eq $l;
    if ($event eq 'move') {
      my $to = $where->[-1];
      if (ref $to ne 'ARRAY') {
	$e{bad} = 'no new place';
      } elsif ($kind eq 'node' ? !eval { $w->blockNodedata(@$to[0, 1]); 1 }
	       : !eval { $w->tagData(@$to[0, 1]); 1 }) {
	$e{bad} = "new place [@$to] does not exist";
      }
    }
  }
  $e{modified} = 1 if eval { $w->insert('1.0', 'Z'); 1 };
  push @events, \%e;
  $count{$event}++;
}

# The values attached now ("block list" holds them all).
sub attached {
  my %a;
  my @todo = ([ $t->blockList('1.0', 'end') ]);
  while (@todo) {
    my $x = shift @todo;
    if (ref $x eq 'V') { $a{$x->{n}} = 1 }
    elsif (ref $x && reftype($x) eq 'ARRAY') { push @todo, @$x }
  }
  \%a;
}

sub rnd_index {
  my $n = (split /\./, $t->index('end'))[0] - 1;
  my $l = 1 + int rand $n;
  my $len = (split /\./, $t->index("$l.end"))[1];
  "$l." . int rand($len + 1);
}
sub rnd_word { join '', map { chr(97 + int rand 26) } 1 .. 1 + int rand 4 }
sub ordered { my ($a, $b) = @_; return ($a, undef) unless defined $b;
	      $t->compare($a, '<=', $b) ? ($a, $b) : ($b, $a) }
sub near { my $i = shift; my $d = int rand 6; $t->index("$i +$d c") }

# Blocks, nested blocks, values everywhere (told as any command).
sub setup {
  my $u = $t->cget('-undo');
  $t->configure(-undo => 0);
  my $n = (split /\./, $t->index('end'))[0] - 1;
  for my $l (1 .. $n) {
    next if rand() < .2;
    my @leaves = map { rnd_word() } 1 .. 1 + int rand 4;
    my $at = (split /\./, $t->index("$l.end"))[1];
    $at = int rand($at + 1);
    $t->insert("$l.$at", join("\n", @leaves));
    my $end = $l + $#leaves;
    my $e = length($leaves[-1]) + ($#leaves ? 0 : $at);
    eval { $t->blockInsert('F', "$l.$at", "$end.$e") };
    for (1 .. int rand 5) {
      my $p = $at + 1 + int rand(3 + length "@leaves");
      eval { $t->blockSplit("$l.$p", int rand 3) };
    }
    my $len;
    for (1 .. int rand 3) {
      $len = (split /\./, $t->index("$l.end"))[1];
      my $a = int rand $len;
      my $b = $a + int rand 5;
      eval { $t->blockInsert(rand() < 1/3 ? ('E', "$l.$a") : ('G', "$l.$a", "$l.$b")) };
    }
    $len = (split /\./, $t->index("$l.end"))[1];
    for my $p (0 .. $len) {
      for my $lv (0 .. 6) {
	my $v = eval { $t->blockNodedata("$l.$p", $lv) };
	last if $@;
	$t->blockNodedata("$l.$p", $lv, nv()) if !defined $v && rand() < .7;
      }
      if (rand() < .3) {
	eval { $t->blockData("$l.$p", nv()) unless defined $t->blockData("$l.$p") };
      }
    }
    for my $g (qw(x y)) {
      next if rand() < .3;
      my $a = int rand $len;
      my $b = $a + 1 + int rand 6;
      $t->tagAdd($g, "$l.$a", "$l.$b");
      eval { $t->tagData($g, "$l.$a", nv()) } if rand() < .8;
    }
    if (rand() < .5) {
      my $m = 'm' . int rand 4;
      $t->markSet($m, "$l." . int rand $len);
      $t->markData($m, nv());
    }
  }
  $t->configure(-undo => $u);
  $t->editReset;
}

my @ops = (
  [10, sub { my ($a, $b) = ordered(rnd_index(), rand() < .7 ? undef : rnd_index());
	     $b //= near($a); ["delete $a $b", sub { $t->delete($a, $b) }] }],
  [3, sub { my $a = rnd_index(); ["delete $a", sub { $t->delete($a) }] }],
  [5, sub { my $i = rnd_index(); my $s = rnd_word(); $s .= "\n" . rnd_word() if rand() < .3;
	    my @tags = rand() < .3 ? ([qw(x)], [], [qw(y x)])[int rand 3] : ();
	    ["insert $i '$s' @{[map { qq([@$_]) } @tags]}", sub { $t->insert($i, $s, @tags) }] }],
  [5, sub { my ($a, $b) = ordered(rnd_index(), rnd_index()); my $g = (qw(x y))[int rand 2];
	    ["tag add $g $a $b", sub { $t->tagAdd($g, $a, $b) }] }],
  [4, sub { my ($a, $b) = ordered(rnd_index(), rnd_index()); my $g = (qw(x y))[int rand 2];
	    ["tag remove $g $a $b", sub { $t->tagRemove($g, $a, $b) }] }],
  [1, sub { my $g = (qw(x y))[int rand 2]; ["tag delete $g", sub { $t->tagDelete($g) }] }],
  [5, sub { my ($a, $b) = ordered(rnd_index(), rand() < .6 ? undef : rnd_index());
	    $b //= near($a); my $ty = (qw(F G F E))[int rand 4]; $b = $a if $ty eq 'E';
	    ["block insert $ty $a $b", sub { $t->blockInsert($ty, $a, $b) }] }],
  [4, sub { my $i = rnd_index(); my $lv = int rand 3;
	    ["block split $i $lv", sub { $t->blockSplit($i, $lv) }] }],
  [2, sub { my $i = rnd_index(); ["block trim $i", sub { $t->blockTrim($i) }] }],
  [8, sub { my $i = rnd_index(); my $lv = int(rand 4) - (rand() < .3 ? 2 : 0);
	    my $v = rand() < .85 ? nv() : undef;
	    ["nodedata $i $lv " . lab($v), sub { $t->blockNodedata($i, $lv, $v) }] }],
  [5, sub { my $i = rnd_index(); my $g = (qw(x y))[int rand 2]; my $v = rand() < .85 ? nv() : undef;
	    ["tag data $g $i " . lab($v), sub { $t->tagData($g, $i, $v) }] }],
  [3, sub { my $i = rnd_index(); my $v = rand() < .85 ? nv() : undef;
	    ["block data $i " . lab($v), sub { $t->blockData($i, $v) }] }],
  [3, sub { my $i = rnd_index(); my $m = 'm' . int rand 4; my $v = nv();
	    ["mark $m $i " . lab($v), sub { $t->markSet($m, $i); $t->markData($m, $v) }] }],
  [2, sub { my $m = 'm' . int rand 4; ["mark unset $m", sub { $t->markUnset($m) }] }],
  [6, sub { ['undo', sub { $t->editUndo }] }],
  [4, sub { ['redo', sub { $t->editRedo }] }],
  [2, sub { ['separator', sub { $t->editSeparator }] }],
  [1, sub { ['reset', sub { $t->editReset }] }],
  [1, sub { my $n = int rand 4; ["maxundo $n", sub { $t->configure(-maxundo => $n) }] }],
);
my $total = 0;
$total += $_->[0] for @ops;
sub pick { my $r = rand $total; for (@ops) { return $_->[1] if ($r -= $_->[0]) < 0 } $ops[-1][1] }

sub where { join ' ', map { ref $_ ? '[' . where(@$_) . ']' : $_ } @_ }

my $commands = 0;
$SIG{__WARN__} = sub { diag "warning: @_" };
for my $seed ($first .. $last) {
  srand $seed;
  my @failed;
  for my $run (1 .. $runs) {
    $t = $mw->eText(-width => 40, -height => 6, -undo => (rand() < .7 ? 1 : 0),
		    -autoseparators => (rand() < .5 ? 1 : 0), -valuecommand => \&cb);
    $t->debug(1);
    $t->blockConfigure('F');
    $t->blockConfigure('G');
    $t->blockConfigure('E', -empty => 1);
    $t->insert('end', join("\n", map { rnd_word() . rnd_word() } 1 .. 2 + int rand 3) . "\n");
    setup();
    my @log;
    for my $opn (1 .. $nops) {
      my $mark = $serial;
      my ($desc, $code) = @{pick()->()};
      my $before = attached();
      @events = ();
      @destroyed = ();
      my $ok = eval { $code->(); 1 };
      my $err = $@;
      $commands++;
      my $after = attached();
      my @p;
      push @p, "error: $err" if !$ok && $err =~ /-valuecommand/;
      my %told;
      for my $e (@events) {
	push @{$told{$e->{label}}}, $e->{event};
	push @p, "late $e->{kind} [" . where(@{$e->{where} || []}) . "] $e->{label}"
	    if $e->{event} eq 'late';
	push @p, "$e->{event} $e->{kind} $e->{label} at [" . where(@{$e->{where}}) . "]: $e->{bad}"
	    if $e->{bad};
	push @p, 'the widget changed during the call' if $e->{modified};
      }
      for my $l (keys %$before) {
	next if $after->{$l};
	push @p, "$l detached, not told" unless grep { /^(drop|stash)$/ } @{$told{$l} || []};
      }
      for my $l (keys %$after) {
	next if $before->{$l} || substr($l, 1) > $mark;	# set by the command
	push @p, "$l came back, not told" unless grep { $_ eq 'restore' } @{$told{$l} || []};
      }
      my %freed = map { $_ => 1 } @destroyed;
      for my $l (@destroyed) {
	push @p, "$l freed, not told" unless grep { /^(drop|discard)$/ } @{$told{$l} || []};
      }
      for my $e (@events) {
	push @p, "$e->{label} told drop, not freed" if $e->{event} eq 'drop' && !$freed{$e->{label}};
	push @p, "$e->{label} told stash, freed" if $e->{event} eq 'stash' && $freed{$e->{label}};
	push @p, "$e->{label} told move, not attached afterwards"
	  if $e->{event} eq 'move' && !$after->{$e->{label}}
	     && !grep { /^(drop|stash)$/ } @{$told{$e->{label}}};
      }
      push @log, "$desc" . join('', map { "\n    $_->{event} $_->{kind} [" . where(@{$_->{where} || []})
					  . "] $_->{label} ($_->{cause})" } @events);
      if (@p) {
	push @failed, "seed $seed run $run command $opn: $desc\n  " . join("\n  ", @p)
	  . "\n  commands:\n  " . join("\n  ", @log);
	last;
      }
    }
    @destroyed = ();
    @events = ();
    $t->destroy;
    push @failed, "seed $seed run $run: told at the widget's destruction" if @events;
  }
  ok(!@failed, "seed $seed: $runs widgets, $nops commands each") or diag $failed[0];
}
ok(!$count{late}, 'no late event');
ok($count{drop} && $count{stash} && $count{move} && $count{restore} && $count{discard},
   'every event happened');
note join ', ', map { "$_ $count{$_}" } sort keys %count;
ok($commands > 0, "$commands commands");
$mw->destroy;
