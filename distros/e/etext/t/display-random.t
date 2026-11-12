#!/usr/bin/perl
# The display of the demo's OpLimits and SpanTable blocks
# (demo/etext.pl), at random: documents with several of each (and
# blocks nested in their cells and limits, tables with random spans),
# then random steps: typing, deleting ranges (across leaves, blocks and
# lines), block split, sprout (one index and two), flatten, trim and
# insert, spans set and cleared (setSpan), undo, redo, scrolling and
# resizing.  After each step the display is forced (update) with
# "debug" on (the demo sets it), and:
#  - no Perl or Tcl error (Tk::Error), no warning, no panic;
#  - every call of the two layout callbacks gave one entry for each leaf
#    of its arguments (then ornaments only);
#  - in every block of the two types fully in the window, the bounding
#    box of every position inside the block lies within the block's.
# At the end, the undo back to the start must give the document of the
# start back ("block list", the marks left out; in the seeds that set
# spans, the node values and instance data left out too: setting them is
# not undoable).
# ETEXT_DISPLAY_RANDOM="first last steps" runs other seeds (the default
# is "1 8 40"); so does ETEXT_RANDOM, as for t/valuecommand-random.t
# ("first last runs steps": runs is not used here).
use strict;
use warnings;
no warnings qw(once);		# The demo's globals.
use utf8;
use FindBin;
use Test::More;
use Data::Dumper ();

BEGIN {
  eval { require Tk; 1 } or plan skip_all => "Tk not available: $@";
}
use Tk::eText;

my $probe = eval { MainWindow->new };
plan skip_all => "no X display available ($@)" unless $probe;
$probe->withdraw;		# Destroyed last, see t/demo.t.

my ($first, $last, $nsteps);
if ($ENV{ETEXT_DISPLAY_RANDOM}) {
  ($first, $last, $nsteps) = split ' ', $ENV{ETEXT_DISPLAY_RANDOM};
} elsif ($ENV{ETEXT_RANDOM}) {
  my @f = split ' ', $ENV{ETEXT_RANDOM};
  ($first, $last, $nsteps) = @f[0, 1, -1];
} else {
  ($first, $last, $nsteps) = (1, 8, 40);
}
plan tests => ($last - $first + 1) + 4;

our ($text, $top);		# the demo's globals (package main)
my (@bgerrors, @warnings);
{
  no warnings 'redefine';
  *Tk::Error = sub { my ($w, $err, @loc) = @_; push @bgerrors, $err };
}
$SIG{__WARN__} = sub { push @warnings, $_[0] };
$SIG{ALRM} = sub { diag("timeout"); exit 1 };
alarm(120 + 4 * ($last - $first + 1) * $nsteps);
$0 = "$FindBin::Bin/../demo/etext.pl";

# The layout callbacks, wrapped: the number of leaves in the arguments
# and the result of each call.
my @calls;
sub nleaves { my $n = 0; for (@_) { $n += ref $_->[0] ? nleaves(@$_) : 1 } $n }
sub wrap {
  for my $type (qw(OpLimits SpanTable)) {
    my $orig = $type eq 'OpLimits' ? \&main::layoutOpLimits : \&main::layoutSpanTable;
    $text->block('configure', $type, -layoutcmd => sub {
      my @r = $orig->(@_);
      push @calls, { type => $type, n => nleaves(@_[2 .. $#_]), r => \@r };
      @r;
    });
  }
}
# An ornament returned by the callback (since 2.08 the strokes are
# ornaments, no longer stolen lines): a type name, then coordinates.
sub is_ornament { $_[0][0] =~ /^(?:line|polygon|rectangle|oval|arc|text)$/ }
sub bad_calls {			# The calls since the last check that are wrong.
  my %orn = map { $_ => 1 } $main::backgrId2;
  my @bad;
  for my $c (@calls) {
    my @r = @{$c->{r}};
    my $ok = @r >= $c->{n} + 1 && @{$r[0]} == 7;
    $ok &&= !grep { @$_ != 7 or $_->[0] != 1 } @r[1 .. $c->{n}];
    $ok &&= !grep { !is_ornament($_) and (@$_ != 7 or !$orn{$_->[0]}) } @r[$c->{n} + 1 .. $#r];
    push @bad, "$c->{type}: $c->{n} leaves, " . scalar(@r) . " entries" unless $ok;
  }
  @calls = ();
  @bad;
}

# The text as "block list", the marks left out, the strings next to each
# other joined (the undo may leave them in several segments), and the
# node values and instance data left out if asked (setSpan gives a
# table without instance data a key).
sub norm {
  my $novalues = shift;
  my @out;
  for (@_) {
    next if ref($_) =~ /Mark/;
    if (ref($_) eq 'Tk::Text::String' and @out and ref($out[-1]) eq 'Tk::Text::String') {
      my $s = ${$out[-1]} . $$_;
      $out[-1] = bless \$s, 'Tk::Text::String';
    } elsif (ref($_) eq 'Tk::Text::Block') {
      my $head = $novalues ? [@{$_->[0]}[0, 1]] : $_->[0];
      push @out, bless([$head, norm($novalues, @$_[1 .. $#$_])], ref $_);
    } else {
      push @out, $_;
    }
  }
  @out;
}
sub dump_text {
  local ($Data::Dumper::Indent, $Data::Dumper::Terse, $Data::Dumper::Sortkeys) = (0, 1, 1);
  my $d = Data::Dumper::Dumper([norm($_[0], $text->block('list', '1.0', 'end'))]);
  $d =~ s/bless\( do\{\\\(my \$o = ('[^']*'|\d+)\)\}, 'Tk::Text::(\w)\w+' \)/$2$1/g;
  $d =~ s/bless\( //g;
  $d =~ s/, 'Tk::Text::\w+' \)//g;
  $d =~ s/\n/\\n/g;
  $d;
}

# Random documents.
my @words = qw(a b x y n k p=17 i=1 sum f(p) 1000 * alpha beta 2 0 ∞ Name A B);
sub word { $words[rand @words] }
sub content {			# A leaf: a word, sometimes a nested block.
  my $depth = shift;
  my $r = rand;
  return '' if $r < 0.1;
  return word() if $r < 0.7 or $depth > 1;
  return [word(), main::mkBlock('Fraction', word(), word())] if $r < 0.8;
  return [main::mkBlock('SpanTable', main::mkNode(word(), word()))] if $r < 0.85;
  [opLimits($depth + 1)];
}
sub opLimits {
  my $depth = shift || 0;
  my $r = rand;
  return main::opLimitsPrimes() if $r < 0.3;
  my @kids = (main::mkTagged((qw(∑ ∏ ∫ ⋃))[rand 4], 'bigop'));
  push @kids, rand() < 0.6 ? main::mkNode(map content($depth), 1 .. 1 + int rand 3)
			   : content($depth) if rand() < 0.9;
  push @kids, content($depth) if rand() < 0.8;
  push @kids, content($depth) if rand() < 0.6;
  push @kids, content($depth) if rand() < 0.1;
  main::mkBlock('OpLimits', @kids);
}
sub spanTable {			# Rows of cells, as in HTML, random spans.
  my $depth = shift || 0;
  my ($nr, $nc) = (1 + int rand 4, 1 + int rand 4);
  my (@taken, @rows);
  for my $r (0 .. $nr - 1) {
    my ($c, @cells) = (0);
    while ($c < $nc) {
      $c++, next if $taken[$r][$c];
      my $cs = ($c + 1 < $nc and rand() < 0.2) ? 2 : 1;
      my $rs = ($r + 1 < $nr and rand() < 0.2) ? 1 + int rand 2 : 1;
      for my $rr ($r .. $r + $rs - 1) { $taken[$rr][$_] = 1 for $c .. $c + $cs - 1 }
      my $cell = content($depth);
      push @cells, ($cs > 1 || $rs > 1) ? main::mkValued($cell, { cols => $cs, rows => $rs }) : $cell;
      $c += $cs;
    }
    push @cells, word() unless @cells;
    push @rows, main::mkNode(@cells);
  }
  main::mkBlock(['SpanTable', main::newSpanTableKey()], @rows);
}
sub document {
  for my $line (1 .. 3 + int rand 3) {
    my @parts;
    for (1 .. 1 + int rand 3) {
      push @parts, word() . ' ';
      push @parts, rand() < 0.5 ? opLimits() : spanTable();
      push @parts, ' ' . word();
    }
    $text->blockInsert('end - 1 c', @parts);
    $text->insert('end - 1 c', "\n") if rand() < 0.8;
  }
}

sub lastline { (split /\./, $text->index('end - 1 c'))[0] }
sub randindex {
  my $l = 1 + int rand lastline();
  my $len = length($text->get("$l.0", "$l.end") // "");
  "$l." . int rand($len + 1);
}

# The steps, each [name, weight, code]; the code returns a description.
my $spans;			# Spans may be set in this seed.
my @kinds = (
  [type => 6, sub {
     my $i = randindex();
     my $s = join '', map { (('a' .. 'z', ' ', ' ', "\n"))[rand 29] } 1 .. 1 + int rand 5;
     $text->insert($i, $s);
     "insert $i '$s'";
   }],
  [delete => 5, sub {
     my $i = randindex();
     my $j = rand() < 0.2 ? randindex() : "$i + " . (1 + int rand 12) . " c";
     ($i, $j) = ($j, $i) if $text->compare($j, '<', $i);
     $j = $text->index($j);
     $text->delete($i, $j);
     "delete $i $j";
   }],
  [split => 3, sub {
     my ($i, $l) = (randindex(), int rand 4);
     $text->block('split', $i, $l);
     "split $i $l";
   }],
  [sprout => 2, sub { my $i = randindex(); $text->block('sprout', $i); "sprout $i" }],
  [sprout2 => 2, sub {
     my $i = randindex();
     my $j = $text->index("$i + " . int(rand 4) . " c");
     $text->block('sprout', $i, $j);
     "sprout $i $j";
   }],
  [flatten => 3, sub {
     my ($i, $l) = (randindex(), (1, 1, 2, -1, -2)[rand 5]);
     $text->block('flatten', $i, $l);
     "flatten $i $l";
   }],
  [trim => 1, sub { my $i = randindex(); $text->block('trim', $i); "trim $i" }],
  [blockinsert => 2, sub {
     my $i = randindex();
     my $b = (opLimits(1), spanTable(1), main::mkBlock('Fraction', 'u', 'v'))[rand 3];
     $text->blockInsert($i, $b);
     "blockInsert $i " . (ref $b->[0] ? $b->[0][0] : $b->[0]);
   }],
  [blockrange => 1, sub {
     my $i = randindex();
     my $j = $text->index("$i + " . int(rand 8) . " c");
     my $type = (qw(OpLimits SpanTable))[rand 2];
     $text->block('insert', $type, $i, $j);
     "block insert $type $i $j";
   }],
  [span => 4, sub {
     my $i = randindex();
     my ($c, $r) = rand() < 0.3 ? (1, 1) : (1 + int rand 3, 1 + int rand 3);
     $text->setSpan($i, $c, $r);
     "setSpan $i $c $r";
   }],
  [undo => 3, sub { $text->editUndo; 'undo' }],
  [redo => 2, sub { $text->editRedo; 'redo' }],
  [scroll => 2, sub {
     my $f = sprintf '%.2f', rand;
     $text->yview('moveto', $f);
     "yview moveto $f";
   }],
  [resize => 1, sub {
     my $g = (400 + int rand 500) . 'x' . (300 + int rand 400);
     $top->geometry($g);
     "geometry $g";
   }],
);
my $total = 0;
$total += $_->[1] for @kinds;
sub pick {			# No spans in the even seeds.
  while (1) {
    my $r = rand $total;
    for (@kinds) {
      next unless ($r -= $_->[1]) < 0;
      return $_ if $spans or $_->[0] ne 'span';
      last;
    }
  }
}

# Every position of every OpLimits and SpanTable block fully in the
# window: its bounding box inside the block's.  Returns the number of
# boxes compared and the faults.
sub check_boxes {
  my ($n, @bad) = (0);
  my ($ww, $wh) = ($text->width, $text->height);
  for my $l (1 .. lastline()) {
    my $s = $text->get("$l.0", "$l.end") // "";
    for my $p (0 .. length($s) - 1) {
      next unless substr($s, $p, 1) eq '{';
      my ($start, $len, $name) = $text->block('at', "$l.$p");
      next unless defined $name and $name =~ /^(OpLimits|SpanTable)$/;
      my ($bx, $by, $bw, $bh) = $text->bbox("$l.$p");
      next unless defined $bh and $bx >= 0 and $by >= 0
	and $bx + $bw < $ww - 4 and $by + $bh < $wh - 4;
      for my $q ($p + 1 .. $p + $len - 1) {
	my ($x, $y, $w, $h) = $text->bbox("$l.$q");
	next unless defined $h;
	$n++;
	push @bad, "$name at $l.$p ($bx,$by,$bw,$bh): $l.$q at ($x,$y,$w,$h)"
	  unless $x >= $bx and $y >= $by and $x + $w <= $bx + $bw and $y + $h <= $by + $bh;
      }
    }
  }
  ($n, @bad);
}

my (%done, %refused, $boxes, @seedfail);
sub run_seed {
  my $seed = shift;
  srand($seed);
  $spans = $seed % 2;
  $text->delete('1.0', 'end');
  $top->geometry('700x600');
  document();
  $text->editReset;
  $text->markSet('insert', '1.0');
  $top->update;
  my $start = dump_text($spans);
  @calls = ();
  my @log;
  my $fail;
  for my $k (1 .. $nsteps) {
    my $kind = pick();
    my ($bg, $warn) = (scalar(@bgerrors), scalar(@warnings));
    my $what = eval { $kind->[2]->() };
    if (defined $what) {
      $done{$kind->[0]}++;
    } else {
      $refused{$kind->[0]}++;
      ($what = "$kind->[0]: refused: $@") =~ s/ at \S+ line \d+.*//s;
    }
    push @log, $what;
    eval { $top->update; 1 } or $fail = "update: $@";
    my @badcalls = bad_calls();
    my ($n, @badboxes) = check_boxes();
    $boxes += $n;
    $fail ||= "background error: @bgerrors[$bg .. $#bgerrors]" if @bgerrors > $bg;
    $fail ||= "warning: @warnings[$warn .. $#warnings]" if @warnings > $warn;
    $fail ||= "layout callback: @badcalls" if @badcalls;
    $fail ||= "bbox: $badboxes[0] (and " . $#badboxes . " more)" if @badboxes;
    last if $fail;
  }
  unless ($fail) {
    my $u = 0;
    $u++ while $u < 10 * $nsteps and eval { $text->editUndo; 1 };
    $top->update;
    my $end = dump_text($spans);
    $fail = "undo to the start ($u steps): got\n$end\nexpected\n$start" if $end ne $start;
    my @bad = bad_calls();
    $fail ||= "layout callback after the undo: @bad" if @bad;
  }
  if ($fail) {
    push @seedfail, $seed;
    diag("seed $seed: $fail\nsteps:\n" . join("\n", @log));
  }
  ok(!$fail, "seed $seed: $nsteps steps" . ($spans ? ', spans' : ''));
}

my @steps = (
  sub {
    wrap();
    $text->configure(-wrap => 'word');
    run_seed($_) for $first .. $last;
  },
  sub {
    is_deeply(\@seedfail, [], 'seeds that failed');
    ok($done{span} || $last == $first, 'spans were set');
    my $n = 0;
    $n += $_ for values %done;
    cmp_ok($n, '>', 0, "steps done: " . join(', ', map "$_ $done{$_}", sort keys %done)
	   . "; refused: " . join(', ', map "$_ $refused{$_}", sort keys %refused));
    cmp_ok($boxes, '>', 0, "bounding boxes compared: $boxes");
    $top->destroy;
    $probe->destroy;
  },
);
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
