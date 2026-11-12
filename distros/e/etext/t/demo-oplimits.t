#!/usr/bin/perl
# The demo's OpLimits block (demo/etext.pl): a big operator with limits,
# R( op | Lower( l1 | l2 ) | upper | index ), a ragged tree.  The
# owner's example OpLimits{sum|(p=17|p is prime)|1000|*} is laid out and
# the places of its leaves are checked with bbox and dlineinfo: the
# upper limit above the operator, the lower lines below it in order,
# all three centered on it, the index to its right at superscript
# height, the operator on the axis of the line.  Then the shapes that
# editing makes: a flattened lower limit, an empty upper limit, fewer
# children, more lower lines, extra children, a single leaf; each laid
# out without errors, the callback giving one entry per leaf.
use strict;
use warnings;
no warnings qw(once);		# The demo's globals.
use utf8;
use FindBin;
use Test::More;

BEGIN {
  eval { require Tk; 1 } or plan skip_all => "Tk not available: $@";
}
use Tk::eText;

my $probe = eval { MainWindow->new };
plan skip_all => "no X display available ($@)" unless $probe;
$probe->withdraw;		# Destroyed last, see t/demo.t.
plan tests => 63;

our ($text, $top);		# the demo's globals (package main)
my (@bgerrors, @warnings);
{
  no warnings 'redefine';
  *Tk::Error = sub { my ($w, $err, @loc) = @_; push @bgerrors, $err };
}
$SIG{__WARN__} = sub { push @warnings, $_[0] };
$SIG{ALRM} = sub { diag("timeout"); exit 1 }; alarm 120;
$0 = "$FindBin::Bin/../demo/etext.pl";

# The layout callback, wrapped: each call's number of leaves (from the
# arguments) and the result.
my @calls;
sub nleaves { my $n = 0; for (@_) { $n += ref $_->[0] ? nleaves(@$_) : 1 } $n }
sub wrap {
  my $orig = \&main::layoutOpLimits;
  $text->block('configure', 'OpLimits', -layoutcmd => sub {
    my @r = $orig->(@_);
    push @calls, { n => nleaves(@_[2 .. $#_]), r => \@r, key => $_[0][2] };
    @r;
  });
}
# The entries for the leaves are one each, the rest are ornaments: in
# every call since the last check (there must be one at least).
my $checked = 0;
# An ornament returned by the callback (since 2.08 the strokes are
# ornaments, no longer stolen lines): a type name, then coordinates.
sub is_ornament { $_[0][0] =~ /^(?:line|polygon|rectangle|oval|arc|text)$/ }
sub one_per_leaf {
  my @new = @calls[$checked .. $#calls];
  $checked = @calls;
  return 0 unless @new;
  my %orn = map { $_ => 1 } $main::backgrId2;
  for my $c (@new) {
    my @r = @{$c->{r}};
    return 0 unless @r >= $c->{n} + 1 and @{$r[0]} == 7;
    for (@r[1 .. $c->{n}]) { return 0 unless @$_ == 7 and $_->[0] == 1 }
    for (@r[$c->{n} + 1 .. $#r]) { return 0 unless is_ornament($_) or @$_ == 7 and $orn{$_->[0]} }
  }
  1;
}

# The extent of $n characters from $from: [left, top, right, bottom].
sub ext {
  my ($from, $n) = @_;
  my @e;
  for my $k (0 .. ($n || 1) - 1) {
    my ($x, $y, $w, $h) = $text->bbox("$from + $k c");
    next unless defined $h;
    @e = ($x, $y, $x + $w, $y + $h) unless @e;
    $e[0] = $x if $e[0] > $x;
    $e[1] = $y if $e[1] > $y;
    $e[2] = $x + $w if $e[2] < $x + $w;
    $e[3] = $y + $h if $e[3] < $y + $h;
  }
  \@e;
}
sub cx { ($_[0][0] + $_[0][2]) / 2 }
sub cy { ($_[0][1] + $_[0][3]) / 2 }
sub inside {
  my ($e, $b) = @_;
  $e->[0] >= $b->[0] and $e->[1] >= $b->[1] and $e->[2] <= $b->[2] and $e->[3] <= $b->[3];
}
# The leaves of the block at $head: [start index, length] each.
sub leaves {
  my $head = shift;
  my (undef, undef, undef, undef, $tree) = $text->block('at', $head);
  my ($l, $c) = split /\./, $text->index($head);
  my @out;
  my $pos = $c + 1;
  my $walk;
  $walk = sub {
    for (@_) {
      if (ref $_) { $walk->(@$_) }
      else { push @out, ["$l.$pos", $_]; $pos += $_ + 1 }
    }
  };
  $walk->(ref $tree ? @$tree : $tree);
  @out;
}
sub structure { my @a = $text->block('at', shift); $a[4] }
# "block list" of the text without the marks (the undo puts them back
# where it can), and with the strings next to each other joined (the
# undo may leave them in several segments).
sub nomarks {
  my @out;
  for (@_) {
    next if ref($_) =~ /Mark/;
    if (ref($_) eq 'Tk::Text::String' and @out and ref($out[-1]) eq 'Tk::Text::String') {
      my $s = ${$out[-1]} . $$_;
      $out[-1] = bless \$s, 'Tk::Text::String';
    } elsif (ref($_) eq 'Tk::Text::Block') {
      push @out, bless([$_->[0], nomarks(@$_[1 .. $#$_])], ref $_);
    } else {
      push @out, $_;
    }
  }
  @out;
}
sub block_list { [ nomarks($text->block('list', '1.0', 'end')) ] }

my @steps = (
  sub {
    wrap();
    $text->delete('1.0', 'end');
    $text->editReset;
    $text->insert('1.0', "x = ");
    $text->blockInsert('1.4', main::opLimitsPrimes());
    $text->insert('1.end', " y");
    $top->update;
    is_deeply(structure('1.4'), [1, [4, 10], 4, 1],
	      'the tree R( op | Lower( l1 | l2 ) | upper | index ), ragged');
    is($text->get('1.5'), "\x{2211}", 'the operator is a sum');
    my ($op, $l1, $l2, $up, $ix) = map ext(@$_), leaves('1.4');
    my $b = [ $text->bbox('1.4') ];
    $b = [ $b->[0], $b->[1], $b->[0] + $b->[2], $b->[1] + $b->[3] ];
    ok($up->[3] <= $op->[1], 'the upper limit is above the operator');
    ok($l1->[1] >= $op->[3], 'the first lower line is below it');
    ok($l2->[1] >= $l1->[3], 'the second lower line below the first');
    cmp_ok(abs(cx($up) - cx($op)), '<=', 2, 'the upper limit is centered on the operator');
    cmp_ok(abs(cx($l1) - cx($op)), '<=', 2, 'so is the first lower line');
    cmp_ok(abs(cx($l2) - cx($op)), '<=', 2, 'and the second');
    ok($ix->[0] >= $op->[2], 'the index is to the right of the operator');
    ok($ix->[1] < cy($op) && $ix->[3] > $op->[1],
       'at superscript height: it starts above the middle of the operator, and does not end above it');
    ok($ix->[3] <= cy($op) + 4, 'and ends near the middle');
    ok(!grep(!inside($_, $b), $op, $l1, $l2, $up, $ix), 'all leaves are inside the block');
    my ($x, $y, $w, $h, $base) = $text->dlineinfo('1.0');
    cmp_ok(abs(cy($op) - ($y + $base - $main::stdAscentHalf)), '<=', 3,
	   "the operator's middle is on the axis of the line");
    my $xe = ext('1.0', 1);
    ok($xe->[2] <= $b->[0] && ext('1.end - 1 c', 1)->[0] >= $b->[2],
       'the text around the block is outside it');
    ok(one_per_leaf(), 'the callback gave one entry for each leaf');
    is_deeply(\@bgerrors, [], 'no errors') or diag(@bgerrors);
    $main::start = block_list();
  },
  sub {
    # A flattened lower limit: a leaf instead of a node.
    my ($op, $l1) = leaves('1.4');
    is($text->block('flatten', $l1->[0], 1), 1, 'flatten the lower limit');
    $top->update;
    is_deeply(structure('1.4'), [1, 14, 4, 1], 'the lower limit is one leaf');
    my ($o, $lo, $up, $ix) = map ext(@$_), leaves('1.4');
    ok($lo->[1] >= $o->[3] && $up->[3] <= $o->[1], 'still below the operator, the upper limit above');
    cmp_ok(abs(cx($lo) - cx($o)), '<=', 2, 'centered');
    ok($ix->[0] >= $o->[2], 'the index to the right');
    ok(one_per_leaf(), 'one entry for each leaf');
    # An empty upper limit: a small square above the operator.
    my $u = (leaves('1.4'))[2];
    $text->delete($u->[0], "$u->[0] + $u->[1] c");
    $top->update;
    is_deeply(structure('1.4'), [1, 14, 0, 1], 'the upper limit is empty');
    ($op, my $lo2, $u, $ix) = leaves('1.4');
    my $ue = ext($u->[0], 1);	# The separator after it: the empty leaf.
    my $oe = ext(@$op);
    ok(@$ue && $ue->[3] <= $oe->[1], 'the empty upper limit is still above the operator');
    my ($sq) = grep { $_->[0] == $main::backgrId2 } @{$calls[-1]{r}};
    ok($sq, 'with a square to show it');
    ok(one_per_leaf(), 'one entry for each leaf');
    is_deeply(\@bgerrors, [], 'no errors') or diag(@bgerrors);
  },
  sub {
    # Fewer children: no upper limit, no index.
    my ($op, $lo, $u, $ix) = leaves('1.4');
    my $tail = "$ix->[0] + $ix->[1] c";
    $text->delete("$u->[0] - 1 c", $tail);
    $top->update;
    is_deeply(structure('1.4'), [1, 14], 'two children left');
    my ($o, $l) = map ext(@$_), leaves('1.4');
    ok($l->[1] >= $o->[3], 'the lower limit below the operator');
    my @b = $text->bbox('1.4');
    cmp_ok(abs($b[2] - ($l->[2] - $l->[0])), '<=', 1, 'the block is as wide as its widest part');
    ok(one_per_leaf(), 'one entry for each leaf');
    # The operator alone.
    ($op, $lo) = leaves('1.4');
    $text->delete("$lo->[0] - 1 c", "$lo->[0] + $lo->[1] c");
    $top->update;
    is_deeply(structure('1.4'), [1], 'the operator alone');
    ok(one_per_leaf(), 'one entry');
    # A single leaf: no root.
    $text->insert("1.6", "\nk");
    is($text->block('flatten', '1.5', -1), 1, 'flatten at the root');
    $top->update;
    is(structure('1.4'), 2, 'the block is a single leaf');
    ok(one_per_leaf(), 'laid out as an operator');
    is_deeply(\@bgerrors, [], 'no errors') or diag(@bgerrors);
    # Undo it all: the example comes back.
    1 while eval { $text->editUndo; 1 } and structure('1.4') and !eq_list();
    $top->update;
    is_deeply(block_list(), $main::start, 'undo brings the example back');
    is_deeply(structure('1.4'), [1, [4, 10], 4, 1], 'with its ragged tree');
    ok(one_per_leaf(), 'one entry for each leaf');
  },
  sub {
    # More lower lines, and children after the index.
    my ($op, $l1, $l2, $up, $ix) = leaves('1.4');
    $text->insert("$l2->[0] + $l2->[1] c", "\nq<N");
    ($op, $l1, $l2, my $l3, $up, $ix) = leaves('1.4');
    $text->insert("$ix->[0] + $ix->[1] c", "\nextra\nmore");
    $top->update;
    is_deeply(structure('1.4'), [1, [4, 10, 3], 4, 1, 5, 4], 'three lower lines, two extra children');
    my @e = map ext(@$_), leaves('1.4');
    my ($o, $a1, $a2, $a3, $u, $i, $x1, $x2) = @e;
    ok($a1->[1] >= $o->[3] && $a2->[1] >= $a1->[3] && $a3->[1] >= $a2->[3],
       'the lower lines below the operator, in order');
    cmp_ok(abs(cx($a3) - cx($o)), '<=', 2, 'centered');
    ok($i->[0] >= $o->[2], 'the index to the right of the operator');
    ok($x1->[0] >= $i->[2] && $x2->[0] >= $x1->[2], 'the extra children after it, in order');
    my ($x, $y, $w, $h, $base) = $text->dlineinfo('1.0');
    my $xb = ext('1.0', 1);	# "x" of the text before: on the baseline
    cmp_ok(abs($x1->[3] - $xb->[3]), '<=', 1, 'the extra children on the baseline of the line');
    my @b = $text->bbox('1.4');
    my $bb = [$b[0], $b[1], $b[0] + $b[2], $b[1] + $b[3]];
    ok(!grep(!inside($_, $bb), @e), 'all leaves inside the block');
    ok(one_per_leaf(), 'one entry for each leaf');
    is_deeply(\@bgerrors, [], 'no errors') or diag(@bgerrors);
  },
  sub {
    # Empty leaves everywhere: the operator, the lower limit.
    $text->delete('1.0', 'end');
    $text->blockInsert('1.0', main::mkBlock('OpLimits', '', main::mkNode('', ''), '', ''));
    $top->update;
    is_deeply(structure('1.0'), [0, [0, 0], 0, 0], 'all leaves empty');
    my @sq = grep { $_->[0] == $main::backgrId2 } @{$calls[-1]{r}};
    is(scalar(@sq), 5, 'a square for each');
    ok(one_per_leaf(), 'one entry for each leaf');
    # The insertion of the menu: the sum and empty limits, the cursor
    # in the lower limit.
    $text->delete('1.0', 'end');
    $text->insert('1.0', 'ab');
    $text->markSet('insert', '1.1');
    $text->insertOpLimits('insert');
    $top->update;
    is_deeply(structure('1.1'), [1, [0], 0, 0], 'Insert/Big operator gives a template');
    is($text->get('1.2'), "\x{2211}", 'with a sum');
    ok(grep($_ eq 'bigop', $text->tagNames('1.2')), 'in the big font');
    is($text->index('insert'), '1.4', 'the cursor in the lower limit');
    $text->insert('insert', 'n=1');
    $top->update;
    is_deeply(structure('1.1'), [1, [3], 0, 0], 'typing goes there');
    is($text->get('1.0', '1.end'), "a{\x{2211}|n=1||}b", 'the text');
    # A nested block in a limit.
    $text->delete('1.0', 'end');
    $text->exampleOpLimits('1.0');
    $top->update;
    my @heads = grep { my @a = $text->block('at', $_); @a && $a[2] eq 'OpLimits' }
		map "1.$_", 0 .. length($text->get('1.0', '1.end'));
    is(scalar(@heads), 3, 'Examples/Big operators gives three');
    my ($op, $lo, $up) = leaves($heads[1]);
    my $f = ext(@$up);
    ok($f->[3] <= ext(@$op)->[1], 'the fraction in the upper limit of the integral is above it');
    is_deeply(\@bgerrors, [], 'no errors') or diag(@bgerrors);
    is_deeply(\@warnings, [], 'no warnings') or diag(@warnings);
    ok(scalar(@calls) > 10, 'the callback was called (' . scalar(@calls) . ' times)');
    $top->destroy;
    $probe->destroy;
  },
);
sub eq_list { is_deeply_quiet(block_list(), $main::start) }
sub is_deeply_quiet {
  require Data::Dumper;
  local $Data::Dumper::Sortkeys = 1;
  Data::Dumper::Dumper($_[0]) eq Data::Dumper::Dumper($_[1]);
}
my $i = 0;
sub step {
  my $s = $steps[$i++];
  eval { $s->(); 1 } or diag("step $i failed: $@");
  $top->after(50, \&step) if $i < @steps;
}
BEGIN {
  require Tk;
  my $orig = \&Tk::MainLoop;
  no warnings 'redefine';
  *Tk::MainLoop = sub { $top->after(100, \&step); $orig->() };
}
do $0;
diag("demo died: $@") if $@;
