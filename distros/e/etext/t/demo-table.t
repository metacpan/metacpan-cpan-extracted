#!/usr/bin/perl
# The demo's SpanTable block (demo/etext.pl): a table R( Row( c | c ...)
# | ... ) whose cells may span columns and rows, the spans being the
# values of the cells ({ cols => 2, rows => 3 } or "2x3"), and a cell
# spanned over is absent from the later rows (as in HTML).  The two
# tables of the demo are laid out and checked with bbox: the cells in
# their columns and rows, "Name" over two header rows, "Results" over
# the columns of "A" and "B", rules that do not cross a spanning cell,
# a note spanning two short rows and taller than both making them
# grow.  Then spans set and cleared (setSpan, growSpan), a table in a
# cell, the shapes editing makes (a cell that is a node, a row that is a
# leaf, a table that is a leaf), and undo.
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
plan tests => 61;

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
  my $orig = \&main::layoutSpanTable;
  $text->block('configure', 'SpanTable', -layoutcmd => sub {
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

# A block's node values left out (setting them is not undoable).
sub novalues {
  map { ref($_) eq 'Tk::Text::Block'
	  ? bless([[@{$_->[0]}[0 .. 2]], novalues(@$_[1 .. $#$_])], ref $_) : $_ } @_;
}
sub cells { map ext(@$_), leaves(shift) }
sub near { my ($a, $b, $d) = @_; abs($a - $b) <= ($d || 1) }
# The rules of the last layout (block coordinates): horizontal and
# vertical ones, [x, y, w, h] each (black rectangles, ornaments).
sub call_for {			# The last call for the table at $head.
  my $key = $text->block('data', "$_[0] + 1 c");
  (grep { ref $_->{key} and $_->{key} == $key } @calls)[-1];
}
sub rules {
  my $c = call_for(shift);
  my @r = @{$c->{r}};
  map { [@$_[1, 2], $_->[3] - $_->[1], $_->[4] - $_->[2]] }
    grep { $_->[0] eq 'rectangle' and {@$_[5 .. $#$_]}->{-fill} eq 'black' }
    @r[$c->{n} + 1 .. $#r];
}
# The leaves of the last layout (block coordinates): [x, y, w, h] each.
sub laidout {
  my $c = call_for(shift);
  map { [@$_[1, 2, 3, 5]] } @{$c->{r}}[1 .. $c->{n}];
}
my ($t1, $t2);			# The heads of the tables.

my @steps = (
  sub {
    wrap();
    $text->delete('1.0', 'end');
    $text->editReset;
    $text->exampleSpanTables('1.0');
    $top->update;
    $t1 = '1.0';
    my @a = $text->block('at', $t1);
    $t2 = "1." . ($a[1] + 2);
    is($a[2], 'SpanTable', 'the first table');
    is_deeply($a[4], [[4, 7], [1, 1], [5, 1, 1], [4, 1, 5]],
	      'its rows: "A | B" without the slot "Name" covers');
    is_deeply(structure($t2), [[4, 4], [1, [9, 13, 14, 13]], [1], [1, 5]],
	      'the second: the note a node of four lines, the row of "y" one cell');
    is_deeply($text->block('nodedata', '1.2', 0), { rows => 2 }, 'the span of "Name" is its value');
    my ($name, $res, $A, $B, $alpha, $one, $two, $beta, $three, $frac) = cells($t1);
    ok($name->[2] <= $res->[0] && $name->[2] <= $A->[0], '"Name" is in the first column');
    cmp_ok(abs(cy($name) - ($res->[1] + $A->[3])/2), '<=', 3, '"Name" is centered on the two header rows');
    ok($res->[3] <= $A->[1], '"Results" above "A"');
    ok(cx($A) < cx($res) && cx($res) < cx($B), '"Results" over "A" and "B"');
    ok(near(cx($A), cx($one)) && near(cx($one), cx($three)), '"A", "1" and "3" in one column');
    ok(near(cx($B), cx($two)) && near(cx($two), cx($frac)), '"B", "2" and the fraction in one column');
    ok(near(cx($name), cx($alpha)) && near(cx($alpha), cx($beta)), '"Name", "alpha" and "beta" in one column');
    ok(near($alpha->[1], $one->[1]) && near($one->[1], $two->[1]), 'a row shares its baseline');
    ok($alpha->[1] >= $A->[3] && $beta->[1] >= $alpha->[3], 'the rows in order');
    ok($frac->[1] < $beta->[1] && $frac->[3] > $beta->[3] && $frac->[1] >= $two->[3],
       'the fraction, taller than the text of its row, makes the row taller');
    ok(one_per_leaf(), 'the callback gave one entry for each leaf');
    # The rules (block coordinates) do not cross the spanning cells.
    my @leaf = laidout($t1);
    my ($n, $r) = @leaf[0, 1];		# Name, Results
    my @rules = rules($t1);
    my @hcross = grep { $_->[3] == 1 && $_->[1] > $n->[1] && $_->[1] < $n->[1] + $n->[3]
			  && $_->[0] < $n->[0] + $n->[2] } @rules;
    my @vcross = grep { $_->[2] == 1 && $_->[0] > $r->[0] && $_->[0] < $r->[0] + $r->[2]
			  && $_->[1] < $r->[1] + $r->[3] } @rules;
    my @under = grep { $_->[3] == 1 && $_->[1] > $n->[1] && $_->[1] < $n->[1] + $n->[3] } @rules;
    is(scalar(@hcross), 0, 'no rule across "Name"');
    is(scalar(@vcross), 0, 'no rule across "Results"');
    is(scalar(@under), 1, 'the rule under "Results" ends at "Name"');
    # The second table: the note spans the rows of "x" and "y".
    my ($item, $note, $x, $n1, $n2, $n3, $n4, $y, $z, $short) = cells($t2);
    my $N = [$n1->[0] < $n4->[0] ? $n1->[0] : $n4->[0], $n1->[1], $n3->[2], $n4->[3]];
    $N->[2] = $_->[2] for grep { $_->[2] > $N->[2] } $n1, $n2, $n4;
    ok($n1->[3] <= $n2->[1] && $n2->[3] <= $n3->[1] && $n3->[3] <= $n4->[1], 'the note: four lines');
    ok($N->[1] >= $x->[1] - 3 && $N->[3] <= $z->[1], 'the note between the top of "x" and the row of "z"');
    cmp_ok($z->[1] - $x->[1], '>=', $N->[3] - $N->[1], 'the two rows are as tall as the note');
    cmp_ok($y->[1] - $x->[1], '>=', ($N->[3] - $N->[1])/2 - 3, 'they grew equally');
    ok(near(cx($short), cx($N)) && near(cx($note), cx($N)), '"Note", the note and "short" in one column');
    ok(near(cx($item), cx($x)) && near(cx($x), cx($y)) && near(cx($y), cx($z)), 'and "Item", "x", "y", "z" in the other');
    is_deeply(\@bgerrors, [], 'no errors') or diag(@bgerrors);
    $main::start = [ novalues(@{block_list()}) ];
  },
  sub {
    # Spans set and cleared.
    $text->setSpan('1.2', 1, 1);	# "Name"
    $top->update;
    ok(!defined $text->block('nodedata', '1.2', 0), 'setSpan 1 1 clears the value');
    my ($name, $res, $A, $B, $alpha, $one, $two) = cells($t1);
    ok(near(cx($A), cx($alpha)) && near(cx($B), cx($one)), 'without the span "A" and "B" move left');
    ok($A->[1] >= $name->[3], 'into the row below "Name"');
    $text->growSpan('1.2', 0, 1);
    $top->update;
    is_deeply($text->block('nodedata', '1.2', 0), { cols => 1, rows => 2 }, 'growSpan sets it again');
    ($name, $res, $A, $B, $alpha, $one, $two) = cells($t1);
    ok(near(cx($A), cx($one)) && near(cx($B), cx($two)), 'and "A" and "B" go back');
    my @c2 = leaves($t2);
    my $l3 = $c2[5][0];		# The third line of the note.
    $text->growSpan($l3, 0, 1);
    $top->update;
    is_deeply($text->block('nodedata', $c2[3][0], 1), { cols => 1, rows => 3 },
	      'growSpan on the note: its node spans three rows');
    my ($item, $note, $x, $n1, $n2, $n3, $n4, $y, $z, $short) = cells($t2);
    ok($short->[0] > $n2->[2], '"short" goes to a third column');
    ok(near($short->[1], $z->[1]), 'in the row of "z"');
    $text->setSpan($l3, 1, 1);
    $top->update;
    ($item, $note, $x, $n1, $n2, $n3, $n4, $y, $z, $short) = cells($t2);
    ok($y->[1] >= $n4->[3], 'without a span, the note is in the row of "x" only');
    ok(near(cx($short), cx($n1)), '"short" below it');
    $text->growSpan($l3, 0, 1);
    # A string as the value.
    $text->block('nodedata', $c2[0][0], 0, '2x1');	# "Item"
    $text->setSpan($c2[3][0], 1, 2);	# Redisplays.
    $top->update;
    ($item, $note, $x, $n1) = cells($t2);
    ok($note->[0] > $n1->[2] && cx($item) > $x->[2],
       '"2x1": "Item" spans two columns, "Note" goes to the third');
    $text->block('nodedata', $c2[0][0], 0, undef);
    $text->setSpan($c2[3][0], 1, 2);
    ok(one_per_leaf(), 'one entry for each leaf');
    is_deeply(\@bgerrors, [], 'no errors') or diag(@bgerrors);
  },
  sub {
    # A table in a cell: "2".
    my @c = leaves($t1);
    $text->insertSpanTable($c[6][0], 2, 2);
    my ($h) = $c[6][0];
    is_deeply(structure($h), [[0, 0], [0, 0]], 'an empty 2x2 table in the cell');
    my ($hl, $hc) = split /\./, $h;
    $text->insert("$hl." . ($hc + $_), chr(ord('p') + $_ - 1)) for reverse 1 .. 4;
    $text->setSpan("$hl." . ($hc + 1), 2, 1);	# "p"
    $top->update;
    is_deeply(structure($h), [[1, 1], [1, 1]], 'p q / r s');
    my ($p, $q, $r, $s) = cells($h);
    ok($q->[0] > $s->[2] && $p->[2] <= $s->[2] + 1, 'p spans two columns, q is in the third');
    ok(scalar(grep { !is_ornament($_) and $_->[0] == $main::backgrId2 } map @{$_->{r}}, @calls) == 0, 'no squares in tables');
    my @outer = cells($t1);
    my @b = $text->bbox($t1);
    my $bb = [$b[0], $b[1], $b[0] + $b[2], $b[1] + $b[3]];
    ok(!grep(!inside($_, $bb), @outer, $p, $q, $r, $s), 'all inside the outer table');
    is_deeply(\@bgerrors, [], 'no errors') or diag(@bgerrors);
  },
  sub {
    # Degenerate shapes.
    my @c = leaves($t1);
    is($text->block('sprout', $c[4][0]), 0, 'sprout "alpha": a cell that is a node');
    $top->update;
    my ($name, $res, $A, $B, $alpha, $one) = cells($t1);
    ok(near(cx($alpha), cx($name)) && near($alpha->[1], $one->[1]), 'it stays in its column and row');
    ok(one_per_leaf(), 'one entry for each leaf');
    is($text->block('flatten', $c[2][0], 1), 1, 'flatten the row of "A" and "B"');
    $top->update;
    my @l = cells($t1);
    ok(near(cx($l[2]), cx($l[4])), 'a row that is a leaf: one cell, "AB", in the first free column');
    ok(one_per_leaf(), 'one entry for each leaf');
    my $e = $text->block('flatten', $c[0][0], -1);
    $top->update;
    is(ref structure($t1), '', 'flattened at the root: the table is one leaf');
    ok(one_per_leaf(), 'one entry');
    is_deeply(\@bgerrors, [], 'no errors') or diag(@bgerrors);
    is_deeply(\@warnings, [], 'no warnings') or diag(@warnings);
    # Undo it all.
    my $n = 0;
    $n++ while $n < 50 and !is_deeply_quiet([novalues(@{block_list()})], $main::start)
      and eval { $text->editUndo; 1 };
    $top->update;
    is_deeply([novalues(@{block_list()})], $main::start, "undo brings the tables back ($n steps)")
      or diag(compact([novalues(@{block_list()})]), "\n", compact($main::start));
    my ($name2, $res2, $A2, $B2, $alpha2, $one2) = cells($t1);
    ok(near(cx($A2), cx($one2)) && near(cx($name2), cx($alpha2)), 'with their spans');
    is_deeply(\@bgerrors, [], 'no errors') or diag(@bgerrors);
  },
  sub {
    # A table copied as the demo copies blocks (Int Copy and Int Paste;
    # File/Save and Open go through the same insertSelf): the spans (node
    # values) and the instance data come back.
    $text->delete('1.0', 'end');
    $text->editReset;
    $text->exampleSpanTables('1.0');
    $top->update;
    my @a = $text->block('at', '1.0');
    my $orig = $text->block('list', '1.0', "1.$a[1]");
    $text->insert('end', "\n");
    my ($line) = $text->index('end - 1c') =~ /^(\d+)/;
    $_->insertSelf($text, "$line.0") for @$orig;
    $top->update;
    my @b = $text->block('at', "$line.0");
    my $copy = $text->block('list', "$line.0", "$line.$b[1]");
    my ($ob) = grep { ref($_) =~ /::Block$/ } @$orig;
    my ($cb) = grep { ref($_) =~ /::Block$/ } @$copy;
    ok($ob && $cb && is_deeply_quiet($cb->[0][3], $ob->[0][3]), 'Int Paste: the node values (spans) come back');
    ok($cb && defined $cb->[0][2], 'Int Paste: the instance data comes back');
    is_deeply($text->block('nodedata', "$line.2", 0), { rows => 2 }, 'Int Paste: "Name" spans two rows');
    my $file = "/tmp/etext-demo-table-$$.tsf";
    $text->Save($file);
    $text->delete('1.0', 'end');
    $text->mark('set', 'insert', '1.0');
    $text->Load($file);
    unlink $file;
    $top->update;
    is_deeply($text->block('nodedata', '1.2', 0), { rows => 2 }, 'Save and Open: "Name" spans two rows');
    $top->destroy;
    $probe->destroy;
  },
);
sub compact {
  require Data::Dumper;
  local ($Data::Dumper::Indent, $Data::Dumper::Terse, $Data::Dumper::Sortkeys) = (0, 1, 1);
  my $d = Data::Dumper::Dumper($_[0]);
  $d =~ s/bless\( do\{\\\(my \$o = ('[^']*'|\d+)\)\}, 'Tk::Text::(\w)\w+' \)/$2$1/g;
  $d =~ s/bless\( //g;
  $d =~ s/, 'Tk::Text::\w+' \)//g;
  $d;
}
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
