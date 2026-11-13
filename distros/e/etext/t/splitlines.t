#!/usr/bin/perl
# Split lines and frames: where the core lays leaves of a block out one
# under another (a "stack": the default layout, or a group of leaves
# that a layout callback saw as one child with a repeat count), it draws
# the structure of the tree that is hidden there.  Between two leaves of
# a stack, lines show the depth of the separator in binary (bit 0 a
# dotted line, bit 1 a dashed one, bit 2 a solid one, bit 3 and above
# solid lines three pixels wide); around a stack, frames show the same
# way how many nodes with a single child there are from the node the
# stack is expected to be.
#
# What was generated is read with "ornament _splitlines index", a hook
# for this test (not an interface): for each stroke of the block that
# starts at the index, [kind, value, stroke, x0, y0, x1, y1], the pixels
# it covers counted from the top left corner of the block.  The pixels
# are read from a capture of the window (Tk::WinPhoto).
#
# The leaves are made of dots, which leave the rows next to the top and
# the bottom of a leaf free: a pixel of a letter may have any colour.
# The tree of a block is written R( a | N( b | c ) ), as in t/ragged.t.
use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require Tk; 1 } or plan skip_all => "Tk not available: $@";
}
use Tk::eText;

my $mw = eval { MainWindow->new };
plan skip_all => "no X display available ($@)" unless $mw;
$mw->geometry('+10+10');

my @bgerrors;
{
  no warnings 'redefine';
  *Tk::Error = sub { my ($w, $err, @loc) = @_; push @bgerrors, $err };
}

my $can_shoot = eval { require Tk::WinPhoto; 1 };
my $gray = join ',', map { $_ >> 8 } $mw->rgb('gray50');

# The space above and below the lines leaves room for the frames, which
# are drawn outside the boxes and are clipped to the display line.  The
# widget is high enough to show all the blocks of a section.
my $t;
sub widget {
  $t->destroy if $t;
  $t = $mw->eText(-width => 40, -height => 26, -font => 'Courier 12',
		  -highlightthickness => 0, -spacing1 => 10, -spacing3 => 10,
		  -undo => 1, @_)->pack;
  $mw->update;
  $t->debug(1);			# The B-tree is checked after every change.
  $t->blockConfigure('F');	# No layout callback: the default layout.
}

# A block of a type on a new line, "x   {leaf|leaf|...}   y": leaves of
# the given numbers of dots, with separators of the given depths between
# them (made from the right, with "block split" at that level).  Gives
# the indices of its head, of the first character of each leaf and of
# the delimiter after each leaf (whose bbox is that of the leaf).
sub block {
  my ($type, $lens, $levels) = @_;
  my ($l) = $t->index('end') =~ /^(\d+)/;
  $l--;
  my $total = 0;
  $total += $_ for @$lens;
  $t->insert('end', 'x   ' . ('.' x $total) . "   y\n");
  $t->blockInsert($type, "$l.4", "$l." . (4 + $total));
  my @cut;			# The first character of each leaf but the first.
  my $pos = 5;
  for my $k (0 .. $#$lens - 1) { $pos += $lens->[$k]; push @cut, $pos }
  $t->blockSplit("$l.$cut[$_]", $levels->[$_]) for reverse 0 .. $#cut;
  my (@leaf, @after);
  $pos = 5;
  for my $k (0 .. $#$lens) {
    push @leaf, "$l.$pos";
    $pos += $lens->[$k];
    push @after, "$l.$pos";
    $pos++;
  }
  return { line => $l, head => "$l.4", leaf => \@leaf, after => \@after };
}

sub splits { [ map { join ' ', @$_ } $t->ornament('_splitlines', $_[0]{head}) ] }
sub at { ($t->blockAt($_[0]{head}))[4] }
sub box { [ $t->bbox($_[0]) ] }

# What is expected, as "ornament _splitlines" gives it.  The strokes of
# a number, the lowest bit first; one row (one pixel around a frame) is
# left between two strokes.
my @stroke = (['dotted', 1], ['dashed', 1], ['solid', 1], ['thick', 3]);
sub strokes {
  my ($v) = @_;
  map { $stroke[$_ > 3 ? 3 : $_] } grep { ($v >> $_) & 1 } 0 .. 30;
}
# Lines for the number v from the row y down, over w columns from x.
sub want_lines {
  my ($v, $x, $y, $w) = @_;
  my @r;
  for my $s (strokes($v)) {
    push @r, join ' ', 'line', $v, $s->[0], $x, $y, $x + $w - 1, $y + $s->[1] - 1;
    $y += $s->[1] + 1;
  }
  @r;
}
# Frames for the number v around the box x, y, w, h.
sub want_frames {
  my ($v, $x, $y, $w, $h) = @_;
  my ($o, @r) = (1);		# How far outside the box.
  for my $s (strokes($v)) {
    my $out = $o + $s->[1] - 1;
    push @r, join ' ', 'frame', $v, $s->[0], $x - $out, $y - $out,
      $x + $w - 1 + $out, $y + $h - 1 + $out;
    $o += $s->[1] + 1;
  }
  @r;
}
# The box of a leaf (or of several consecutive leaves) of a block, from
# the top left corner of the block.
sub rel {
  my ($b, $first, $last) = @_;
  $last = $first unless defined $last;
  my @B = @{box($b->{head})};
  my @f = @{box($b->{after}[$first])};
  my @l = @{box($b->{after}[$last])};
  my $w = 0;
  for my $k ($first .. $last) {
    my @k = @{box($b->{after}[$k])};
    $w = $k[2] if $k[2] > $w;
  }
  ($f[0] - $B[0], $f[1] - $B[1], $w, $l[1] + $l[3] - $f[1]);
}

# Pixels.  '#' for a pixel of the colour of the strokes, '.' for others.
sub shot { $mw->update; $mw->Photo(-format => 'Window', -data => oct($t->id)) }
sub px { my ($ph, $x, $y) = @_; join(',', $ph->get($x, $y)) eq $gray ? '#' : '.' }
sub row { my ($ph, $x0, $x1, $y) = @_; join '', map { px($ph, $_, $y) } $x0 .. $x1 }
sub col { my ($ph, $x, $y0, $y1) = @_; join '', map { px($ph, $x, $_) } $y0 .. $y1 }
# The first n pixels of a stroke.
sub pattern {
  my ($name, $n) = @_;
  join '', map { $name eq 'dotted' ? ($_ % 3 ? '.' : '#')
		 : $name eq 'dashed' ? ($_ % 7 < 4 ? '#' : '.') : '#' } 0 .. $n - 1;
}
# A stroke of a line as it is listed is drawn so: its rows hold its
# pattern from its left end, and the rows above and below it are empty.
sub line_drawn {
  my ($ph, $b, $item) = @_;
  my ($kind, $v, $name, $x0, $y0, $x1, $y1) = split ' ', $item;
  my @B = @{box($b->{head})};
  my $n = $x1 - $x0 + 1;
  my @bad;
  for my $y ($y0 .. $y1) {
    my $got = row($ph, $B[0] + $x0, $B[0] + $x1, $B[1] + $y);
    push @bad, "row $y: $got" unless $got eq pattern($name, $n);
  }
  for my $y ($y0 - 1, $y1 + 1) {
    my $got = row($ph, $B[0] + $x0, $B[0] + $x1, $B[1] + $y);
    push @bad, "row $y not empty: $got" unless $got eq '.' x $n;
  }
  diag(join "\n", "$item:", @bad) if @bad;
  !@bad;
}
# A stroke of a frame: the top edge holds its pattern from the top left
# corner; the other edges are drawn in the same stroke (dots and dashes
# go on around the corners: each edge, its corners left out, is a piece
# of the pattern); the pixels next to it, inside and outside, are empty
# (but where the lines of the stack, whose rows are given, end).
sub frame_drawn {
  my ($ph, $b, $item, @line_rows) = @_;
  my ($kind, $v, $name, $x0, $y0, $x1, $y1) = split ' ', $item;
  my @B = @{box($b->{head})};
  my %line_row = map { $_ + $B[1] => 1 } @line_rows;
  ($x0, $x1) = map { $_ + $B[0] } $x0, $x1;
  ($y0, $y1) = map { $_ + $B[1] } $y0, $y1;
  my $th = $name eq 'thick' ? 3 : 1;
  my @bad;
  my $edges = sub {
    my ($i) = @_;		# How far inside the listed box.
    (row($ph, $x0 + $i, $x1 - $i, $y0 + $i), col($ph, $x1 - $i, $y0 + $i, $y1 - $i),
     row($ph, $x0 + $i, $x1 - $i, $y1 - $i), col($ph, $x0 + $i, $y0 + $i, $y1 - $i));
  };
  for my $i (0 .. $th - 1) {
    my @e = $edges->($i);
    push @bad, "top edge: $e[0]" unless $e[0] eq pattern($name, length $e[0]);
    for my $k (1 .. 3) {
      my $piece = substr($e[$k], 1, -1);
      push @bad, "edge $k: $e[$k]"
	if index(pattern($name, length($piece) + 14), $piece) < 0;
    }
  }
  for my $i (-1, $th) {
    my @e = $edges->($i);
    # The columns just inside the first frame are the sides of the box.
    for my $k (1, 3) {
      my @c = split //, $e[$k];
      for my $j (0 .. $#c) { $c[$j] = '.' if $line_row{$y0 + $i + $j} }
      $e[$k] = join '', @c;
    }
    for my $k (0 .. 3) {
      push @bad, "next to it ($i), edge $k: $e[$k]" if $e[$k] =~ /#/;
    }
  }
  diag(join "\n", "$item:", @bad) if @bad;
  !@bad;
}
sub drawn {
  my ($ph, $b) = @_;
  my @items = @{splits($b)};
  my @line_rows = map { my @i = split ' '; $i[4] .. $i[6] } grep { /^line/ } @items;
  my $ok = @items > 0;
  for my $item (@items) {
    $ok &&= $item =~ /^line/ ? line_drawn($ph, $b, $item)
      : frame_drawn($ph, $b, $item, @line_rows);
  }
  $ok;
}
# All the pixels of a block and of m pixels around it (the letters x
# and y next to it are left out).
sub region {
  my ($ph, $b, $m) = @_;
  my @B = @{box($b->{head})};
  join ';', map { my $y = $_;
		  map { join ',', $ph->get($_, $y) } $B[0] - $m .. $B[0] + $B[2] - 1 + $m }
    $B[1] - $m .. $B[1] + $B[3] - 1 + $m;
}

# ---------------------------------------------------------------------
# The default layout: all the leaves of a block are one stack.  Lines.

widget();
is($t->blockCget('F', '-splitlines'), 1, '-splitlines is on by default');

my $flat = block('F', [4, 6], [0]);
is_deeply(at($flat), [4, 6], 'R( a | b )');
is_deeply(splits($flat), [], 'a separator of depth 0, a root with two children: nothing');

my @one = map { block('F', [4, 6], [$_]) } 1 .. 4;
is_deeply(at($one[0]), [[4], [6]], 'R( N( a ) | M( b ) ): a separator of depth 1');
for my $s (1 .. 4) {
  my $b = $one[$s - 1];
  my @B = @{box($b->{head})};
  my ($x, $y, $w, $h) = rel($b, 1);
  is_deeply(splits($b), [want_lines($s, 0, $y, $B[2])],
	    "depth $s: across the block, at the top of the lower leaf");
}
is_deeply([map { (split ' ')[2] } map { @{splits($_)} } @one],
	  ['dotted', 'dashed', 'dotted', 'dashed', 'solid'],
	  '1 dotted, 2 dashed, 3 both, 4 solid');
is((split ' ', splits($one[2])->[1])[4] - (split ' ', splits($one[2])->[0])[4], 2,
   'depth 3: the dashed line 2 pixels under the dotted one');

my %with;			# The pixels of each block with its lines.
SKIP: {
  skip 'no Tk::WinPhoto to capture the window', 6 unless $can_shoot;
  my $ph = shot();
  $with{$_} = region($ph, $_, 6) for $flat, @one;
  ok(drawn($ph, $one[$_ - 1]), "depth $_: drawn as listed") for 1 .. 4;
  my @B = @{box($one[0]{head})};
  my ($x, $y) = rel($one[0], 1);
  is(row($ph, $B[0], $B[0] + 8, $B[1] + $y), '#..#..#..',
     'a dotted line: one pixel on, two off');
  @B = @{box($one[1]{head})};
  ($x, $y) = rel($one[1], 1);
  is(row($ph, $B[0], $B[0] + 13, $B[1] + $y), '####...####...',
     'a dashed line: four pixels on, three off');
}

# Editing lays the block out again: the lines follow.
$t->insert($one[0]{leaf}[1], '........');
$one[0]{after}[1] = "$one[0]{line}.24";
{
  my $b = $one[0];
  my @B = @{box($b->{head})};
  my @l1 = @{box("$b->{line}.10")};	# The first character of the lower leaf.
  is_deeply(splits($b), [want_lines(1, 0, $l1[1] - $B[1], $B[2])],
	    'after an insertion the line is as wide as the block is now');
}

# -splitlines 0: nothing is drawn, and nothing else changes.
{
  my @all = map { my $l = $_; map { "$l.$_" } 0 .. 20 } 1 .. 5;
  my @boxes = map { box($_) } @all;
  my @dlines = map { [$t->dlineinfo("$_.0")] } 1 .. 5;
  $t->blockConfigure('F', -splitlines => 0);
  is($t->blockCget('F', '-splitlines'), 0, '-splitlines 0');
  is_deeply([map { @{splits($_)} } $flat, @one], [], 'no lines are generated');
  is_deeply([map { box($_) } @all], \@boxes,
	    'the bbox of every position is the same without the lines');
  is_deeply([map { [$t->dlineinfo("$_.0")] } 1 .. 5], \@dlines,
	    'and so are the display lines');
 SKIP: {
    skip 'no Tk::WinPhoto to capture the window', 4 unless $can_shoot;
    my $ph = shot();
    ok(region($ph, $flat, 6) eq $with{$flat},
       'depth 0: the same pixels with the lines and without: nothing was drawn');
    is(scalar(grep { region($ph, $_, 6) eq $with{$_} } @one[1 .. 3]), 0,
       'changing the option redisplays: the pixels of the other blocks change');
    is(join('', map { my @B = @{box($_->{head})};
		      row($ph, $B[0], $B[0] + $B[2] - 1, $B[1] + (rel($_, 1))[1]) } @one) =~ tr/#//,
       0, 'the lines are gone');
    $t->blockConfigure('F', -splitlines => 1);
    $ph = shot();
    ok(region($ph, $one[3], 6) eq $with{$one[3]}, 'and back with -splitlines 1');
  }
  $t->blockConfigure('F', -splitlines => 1);
  $t->blockConfigure('F', -layoutdepth => -1);
  is($t->blockCget('F', '-splitlines'), 1, 'configuring another option leaves it');
}

# Deeper separators: bit 3 and each bit above it is a solid line three
# pixels wide; one row is left between two lines.
widget();
{
  my $b = block('F', [4, 4, 4], [8, 12]);
  my $c = block('F', [4, 4, 4], [16, 24]);
  my @B = @{box($b->{head})};
  my @C = @{box($c->{head})};
  is_deeply(splits($b), [want_lines(8, 0, (rel($b, 1))[1], $B[2]),
			 want_lines(12, 0, (rel($b, 2))[1], $B[2])],
	    'depths 8 and 12: a thick line; a solid and a thick one');
  my $y = (rel($b, 2))[1];
  is_deeply([map { join ' ', (split ' ')[2, 4, 6] } @{splits($b)}[1, 2]],
	    ["solid $y $y", 'thick ' . ($y + 2) . ' ' . ($y + 4)],
	    'the thick line takes three rows, one row under the solid one');
  is_deeply(splits($c), [want_lines(16, 0, (rel($c, 1))[1], $C[2]),
			 want_lines(24, 0, (rel($c, 2))[1], $C[2])],
	    'depths 16 and 24: one thick line; two thick lines');
 SKIP: {
    skip 'no Tk::WinPhoto to capture the window', 2 unless $can_shoot;
    my $ph = shot();
    ok(drawn($ph, $b), 'depths 8 and 12: drawn as listed');
    ok(drawn($ph, $c), 'depths 16 and 24: drawn as listed');
  }
}

# ---------------------------------------------------------------------
# Frames: the number of nodes with a single child from the root down.

widget();
{
  my @b = map { block('F', [4], []) } 1 .. 5;
  # A leaf gets a node of its own above it with "block sprout".
  my @n = (1, 2, 3, 4, 9);
  for my $i (0 .. 4) { $t->blockSprout($b[$i]{leaf}[0]) for 2 .. $n[$i] }
  is_deeply(at($b[0]), [4], 'R( a ): the root has one child');
  is_deeply(at($b[1]), [[4]], 'R( N( a ) ): the root and N have one child each');
  for my $i (0 .. 4) {
    my @B = @{box($b[$i]{head})};
    is_deeply(splits($b[$i]), [want_frames($n[$i], 0, 0, $B[2], $B[3])],
	      "a chain of $n[$i]: frames around the block");
  }
  is_deeply([map { join ' ', (split ' ')[2 .. 4] } map { @{splits($_)} } @b],
	    ['dotted -1 -1', 'dashed -1 -1', 'dotted -1 -1', 'dashed -3 -3',
	     'solid -1 -1', 'dotted -1 -1', 'thick -5 -5'],
	    '1 dotted, 2 dashed, 3 both, 4 solid, 9 dotted and thick: '
	    . 'the first one pixel outside the box, the next 2 pixels further');
 SKIP: {
    skip 'no Tk::WinPhoto to capture the window', 6 unless $can_shoot;
    my $ph = shot();
    ok(drawn($ph, $b[$_]), "a chain of $n[$_]: drawn as listed") for 0 .. 4;
    my @B = @{box($b[0]{head})};
    is(join('', map { px($ph, $B[0] + $_->[0], $B[1] + $_->[1]) }
	    [-1, -1], [-2, -1], [-1, -2], [0, 0]), '#...',
       'the corner of the frame is one pixel outside the corner of the box');
  }
  # The undo of a structural change lays the block out again.
  $t->editSeparator;
  $t->blockSprout($b[0]{leaf}[0]);
  is((split ' ', splits($b[0])->[0])[1], 2, 'a sprout: the chain is 2');
  $t->editUndo;
  is((split ' ', splits($b[0])->[0])[1], 1, 'undone: 1 again');
}

# Chains that end at a node with several children; no chain at all.
widget();
{
  # R( N( a | b ) ): sprout the only leaf, then split it.
  my $b = block('F', [8], []);
  $t->blockSprout($b->{leaf}[0]);
  $t->blockSplit("$b->{line}.9", 0);
  is_deeply(at($b), [[4, 4]], 'R( N( a | b ) )');
  my @B = @{box($b->{head})};
  is_deeply(splits($b), [want_frames(1, 0, 0, $B[2], $B[3])],
	    'a chain of 1 (the root), and no line between a and b');
  # R( N( a | b ) | M( c ) ).
  my $c = block('F', [4, 4, 4], [0, 1]);
  is_deeply(at($c), [[4, 4], [4]], 'R( N( a | b ) | M( c ) )');
  @B = @{box($c->{head})};
  is_deeply(splits($c), [want_lines(1, 0, (rel($c, 2))[1], $B[2])],
	    'no frame; a line between b and c only');
  # A block that is a single leaf has no nodes.
  my $d = block('F', [4], []);
  $t->blockFlatten($d->{leaf}[0], -1);
  is_deeply(at($d), 4, 'a block that is a single leaf');
  is_deeply(splits($d), [], 'no frame');
  # A block in a leaf of a block: each has its own.
  my $e = block('F', [4, 8], [0]);
  $t->blockInsert('F', "$e->{line}.12", "$e->{line}.14");
  my $in = { head => "$e->{line}.12" };
  my @I = @{box($in->{head})};
  is_deeply(splits($e), [], 'the outer block, R( a | b{c}d ): nothing');
  is_deeply(splits($in), [want_frames(1, 0, 0, $I[2], $I[3])],
	    'the block in its leaf, R( c ): a frame around its own box');
 SKIP: {
    skip 'no Tk::WinPhoto to capture the window', 3 unless $can_shoot;
    my $ph = shot();
    ok(drawn($ph, $b), 'R( N( a | b ) ): drawn as listed');
    ok(drawn($ph, $c), 'R( N( a | b ) | M( c ) ): drawn as listed');
    ok(drawn($ph, $in), 'the nested block: drawn at its own corner');
  }
}

# ---------------------------------------------------------------------
# Leaves of different depths: on each side of a separator, the depth is
# counted from the real parent of the leaf there (the depth less the
# defect of the leaf), the upper leaf's on the left half of the line,
# the lower leaf's on the right half.

widget();
{
  # R( x | S( 2 | 3 ) ): the leaf x has one padding node above it.
  my $b = block('F', [4, 8], [0]);
  $t->blockSprout($b->{leaf}[1]);
  $t->blockSplit("$b->{line}.14", 0);
  $b->{after} = [map { "$b->{line}.$_" } 9, 14, 19];
  is_deeply(at($b), [4, [4, 4]], 'R( x | S( 2 | 3 ) )');
  my @B = @{box($b->{head})};
  my $half = int($B[2] / 2);
  is_deeply(splits($b), [want_lines(1, $half, (rel($b, 1))[1], $B[2] - $half)],
	    'x | 2 (depth 1, defects 1 and 0): the right half only; 2 | 3: nothing');
  # R( S( 2 | 3 ) | x ).
  my $c = block('F', [8, 4], [0]);
  $t->blockSprout($c->{leaf}[0]);
  $t->blockSplit("$c->{line}.9", 0);
  $c->{after} = [map { "$c->{line}.$_" } 9, 14, 19];
  is_deeply(at($c), [[4, 4], 4], 'R( S( 2 | 3 ) | x )');
  my @C = @{box($c->{head})};
  $half = int($C[2] / 2);
  is_deeply(splits($c), [want_lines(1, 0, (rel($c, 2))[1], $half)],
	    '3 | x (defects 0 and 1): the left half only');
  # R( P( Q( a ) ) | T( b ) ): a separator of depth 2, b with defect 1.
  my $d = block('F', [4, 4], [2]);
  $t->blockFlatten($d->{leaf}[1], 1);
  is_deeply(at($d), [[[4]], [4]], 'R( P( Q( a ) ) | T( b ) )');
  my @D = @{box($d->{head})};
  $half = int($D[2] / 2);
  my $y = (rel($d, 1))[1];
  is_deeply(splits($d), [want_lines(2, 0, $y, $half),
			 want_lines(1, $half, $y, $D[2] - $half)],
	    'the two halves differ: 2 (dashed) on the left, 1 (dotted) on the right');
 SKIP: {
    skip 'no Tk::WinPhoto to capture the window', 5 unless $can_shoot;
    my $ph = shot();
    ok(drawn($ph, $b), 'R( x | S( 2 | 3 ) ): drawn as listed');
    ok(drawn($ph, $c), 'R( S( 2 | 3 ) | x ): drawn as listed');
    ok(drawn($ph, $d), 'two different halves: drawn as listed');
    is(row($ph, $B[0], $B[0] + $half - 1, $B[1] + (rel($b, 1))[1]), '.' x $half,
       'the half that shows 0 is empty');
    is(row($ph, $D[0] + $half - 7, $D[0] + $half + 6, $D[1] + $y),
       substr(pattern('dashed', $half), -7) . pattern('dotted', 7),
       'the dashes end and the dots start in the middle');
  }
}

# Random trees, laid out by default: what is generated is what "block
# list" (the depths of the separators, the defects of the leaves) and
# "block at" (the tree) say.
widget();
{
  srand(20261112);
  my (@bad, %kinds);
  for my $round (1 .. 60) {
    $t->delete('1.0', 'end');
    my $n = 1 + int rand 5;
    my $b = block('F', [(2) x $n], [map { int rand 4 } 2 .. $n]);
    $t->blockSprout($b->{leaf}[int rand $n]) for 1 .. int rand 4;
    # The separators: a depth, or [depth, defect of the leaf after it];
    # [undef, defect] before a first leaf that has one.
    my ($blk) = grep { ref($_) =~ /::Block$/ } $t->blockList("$b->{line}.0", "$b->{line}.end");
    my @sep = map { UNIVERSAL::isa($_, 'ARRAY') ? [@$_] : [$$_, 0] }
      grep { ref($_) =~ /BlockSeparator/ } @$blk;
    unshift @sep, [undef, 0] if !@sep || defined $sep[0][0];
    my @B = @{box($b->{head})};
    my $half = int($B[2] / 2);
    # The chain from the root: nested lists of one element.
    my ($chain, $tree) = (0, at($b));
    while (ref $tree && @$tree == 1) { $chain++; $tree = $tree->[0] }
    my @want = want_frames($chain, 0, 0, $B[2], $B[3]);
    for my $k (1 .. $n - 1) {
      my ($s, $da, $db) = ($sep[$k][0], $sep[$k - 1][1], $sep[$k][1]);
      my $y = (rel($b, $k))[1];
      if ($da == $db) {
	push @want, want_lines($s - $da, 0, $y, $B[2]);
	$kinds{whole}++ if $s > $da;
      } else {
	push @want, want_lines($s - $da, 0, $y, $half),
	  want_lines($s - $db, $half, $y, $B[2] - $half);
	$kinds{halves}++;
      }
    }
    $kinds{frames}++ if $chain;
    $kinds{ragged}++ if grep { $_->[1] } @sep;
    my $got = splits($b);
    push @bad, "round $round, " . $t->get("$b->{line}.4", "$b->{line}.end") . ":\n"
      . "  got:  @{[join '; ', @$got]}\n  want: @{[join '; ', @want]}"
      unless "@$got" eq "@want";
  }
  is(scalar(@bad), 0, '60 random trees: the lines and frames follow block list and block at')
    or diag(join "\n", @bad[0 .. ($#bad < 4 ? $#bad : 4)]);
  ok(!grep({ !$kinds{$_} } qw(whole halves frames ragged)),
     'among them trees with frames, with whole lines, with halves, with padding')
    or diag(join ' ', %kinds);
}

# A leaf of several display lines: the line is at the top of the first
# one, and the box of the stack holds them all.
widget(-width => 24);
{
  $t->insert('end', "x   .... " . ('.. ' x 40) . "  y\n");
  $t->blockInsert('F', '1.4', '1.129');
  $t->blockSplit('1.10', 1);
  my $b = { head => '1.4' };
  my @B = @{box('1.4')};
  my @first = @{box('1.11')};	# The first character of the lower leaf.
  my @last = @{box('1.128')};	# One of its last characters.
  cmp_ok($last[1], '>', $first[1], 'the lower leaf is wrapped');
  is_deeply(splits($b), [want_lines(1, 0, $first[1] - $B[1], $B[2])],
	    'the line is at the top of its first display line');
 SKIP: {
    skip 'no Tk::WinPhoto to capture the window', 1 unless $can_shoot;
    ok(drawn(shot(), $b), 'drawn as listed');
  }
}

# ---------------------------------------------------------------------
# A layout callback with -layoutdepth 1 -layoutwidths [2] sees the
# children of the root as two children with repeat counts; each one it
# gives a box is a stack.  The stacks are expected to be the children of
# the root.

widget();
my (@seen, $hide, $bad);
my $frac = sub {
  my ($data, $x, $num, $den) = @_;
  @seen = ($num->[0], $den->[0]);
  return 'no list' if $bad;
  my $w = $num->[2] > $den->[2] ? $num->[2] : $den->[2];
  my $h = 6 + $num->[4] + 12 + $den->[4] + 6;
  return ([-1, 0, 0, $w + 16, $w + 16, $h, 6 + $num->[4] + 6],
	  [$num->[0], 8, 6, $num->[2], $num->[2], $num->[4], $num->[5]],
	  $hide ? [$den->[0]] :
	  [$den->[0], 8, 6 + $num->[4] + 12, $den->[2], $den->[2], $den->[4], $den->[5]]);
};
$t->blockConfigure('Frac', -layoutdepth => 1, -layoutwidths => [2], -layoutcmd => $frac);
{
  # R( A( B( a ) | C( b ) ) | D( E( d ) ) ): the callback sees A (two
  # leaves) and D (one leaf).
  my $b = block('Frac', [4, 6, 4], [1, 2]);
  is_deeply(at($b), [[[4], [6]], [[4]]], 'R( A( B( a ) | C( b ) ) | D( E( d ) ) )');
  $mw->update;
  is_deeply(\@seen, [2, 1], 'the callback sees two groups, of 2 leaves and of 1');
  my @g1 = rel($b, 0, 1);
  my @g2 = rel($b, 2);
  is($g1[0], 8, 'the first group is where the callback put it');
  is_deeply(splits($b), [want_lines(1, $g1[0], (rel($b, 1))[1], $g1[2]),
			 want_frames(2, @g2)],
	    'a line inside the first group, across the group; '
	    . 'frames around the second, a chain of 2 (D and E); '
	    . 'nothing for the separator between the groups');
  # R( N( a ) | M( b ) | K( d ) ): the last two children are lumped.
  my $c = block('Frac', [4, 6, 4], [1, 1]);
  is_deeply(at($c), [[4], [6], [4]], 'R( N( a ) | M( b ) | K( d ) )');
  $mw->update;
  is_deeply(\@seen, [1, 2], 'the callback sees N, and M and K as one group');
  my @h1 = rel($c, 0);
  my @h2 = rel($c, 1, 2);
  is_deeply(splits($c), [want_frames(1, @h1), want_lines(1, $h2[0], (rel($c, 2))[1], $h2[2])],
	    'a frame around N (a chain of 1); a line between b and d; '
	    . 'no frame around two lumped children');
  # R( a | b ): the children of the root are leaves.
  my $d = block('Frac', [4, 6], [0]);
  $mw->update;
  is_deeply(\@seen, [1, 1], 'two leaves');
  is_deeply(splits($d), [], 'leaves that are not deeper than -layoutdepth: no frames');
  # R( x | S( 2 ) ): a leaf and a node with one leaf.
  my $r = block('Frac', [4, 6], [0]);
  $t->blockSprout($r->{leaf}[1]);
  is_deeply(at($r), [4, [6]], 'R( x | S( 2 ) )');
  is_deeply(splits($r), [want_frames(1, rel($r, 1))],
	    'a frame around the leaf of S (a chain of 1), none around the leaf x');
 SKIP: {
    skip 'no Tk::WinPhoto to capture the window', 5 unless $can_shoot;
    my $ph = shot();
    ok(drawn($ph, $b), 'groups: drawn as listed');
    ok(drawn($ph, $c), 'a single child and two lumped ones: drawn as listed');
    ok(drawn($ph, $r), 'a leaf and a node with one leaf: drawn as listed');
    my @B = @{box($b->{head})};
    # Between the box of the first group and the frame of the second.
    my $gap = join '', map { row($ph, $B[0], $B[0] + $B[2] - 1, $B[1] + $_) }
      $g1[1] + $g1[3] .. $g2[1] - 2;
    cmp_ok(length $gap, '>', 5 * $B[2], 'there is room between the groups');
    ok($gap !~ /#/, 'and nothing is drawn there');
  }

  # A child hidden with a list of one element is in no stack.
  my @boxes = map { box("$b->{line}.$_") } 0 .. 24;
  $hide = 1;
  $t->blockConfigure('Frac', -layoutdepth => 1);	# Lays the blocks out again.
  is_deeply(splits($b), [want_lines(1, $g1[0], (rel($b, 1))[1], $g1[2])],
	    'the second group hidden: no frame for it');
  $hide = 0;

  # Without the lines the callback lays the same boxes out.
  $t->blockConfigure('Frac', -splitlines => 0);
  is_deeply([map { @{splits($_)} } $b, $c, $d], [], '-splitlines 0: nothing generated');
  is_deeply([map { box("$b->{line}.$_") } 0 .. 24], \@boxes,
	    'the bbox of the block, of its leaves and of their characters is the same');
  $t->blockConfigure('Frac', -splitlines => 1);
  is(scalar(@bgerrors), 0, 'no background errors so far') or diag(join "\n", @bgerrors);
}

# -layoutdepth 0: the callback sees the root as one child with a repeat
# count, and the stack is expected to be the root.
widget();
$t->blockConfigure('Frac', -layoutdepth => 1, -layoutwidths => [2], -layoutcmd => $frac);
$t->blockConfigure('One', -layoutdepth => 0, -layoutcmd => sub {
  my ($data, $x, $all) = @_;
  @seen = ($all->[0]);
  return ([-1, 0, 0, $all->[2] + 16, $all->[2] + 16, $all->[4] + 12, $all->[5] + 6],
	  [$all->[0], 8, 6, @$all[2 .. 5]]);
});
# No -layoutdepth: the callback sees the whole tree, and may still give
# one box to several leaves; there is no node the stack is expected to
# be.
$t->blockConfigure('All', -layoutcmd => sub {
  my ($data, $x, @kids) = @_;
  my @leaves;
  my $walk; $walk = sub { ref $_[0][0] ? (map { $walk->($_) } @{$_[0]}) : push @leaves, $_[0] };
  $walk->($_) for @kids;
  @seen = (scalar @leaves);
  my ($w, $h) = (0, 0);
  for (@leaves) { $w = $_->[2] if $_->[2] > $w; $h += $_->[4] }
  return ([-1, 0, 0, $w + 16, $w + 16, $h + 12, $leaves[0][5] + 6],
	  [scalar(@leaves), 8, 6, $w, $w, $h, $leaves[0][5]]);
});
{
  # A leaf sprouted three times and then split at level 1.
  my $b = block('One', [8], []);
  $t->blockSprout($b->{leaf}[0]) for 1 .. 3;
  $t->blockSplit("$b->{line}.9", 1);
  is_deeply(at($b), [[[[4], [4]]]], 'R( M( N( P( a ) | Q( b ) ) ) )');
  $b->{after} = [map { "$b->{line}.$_" } 9, 14];
  $mw->update;
  is_deeply(\@seen, [2], '-layoutdepth 0: the callback sees one group of 2 leaves');
  my @g = rel($b, 0, 1);
  is_deeply(splits($b), [want_frames(2, @g), want_lines(1, $g[0], (rel($b, 1))[1], $g[2])],
	    'frames for the chain from the root (R and M), and the line');
  # The same tree for a callback without -layoutdepth.
  my $c = block('All', [8], []);
  $t->blockSprout($c->{leaf}[0]) for 1 .. 3;
  $t->blockSplit("$c->{line}.9", 1);
  $c->{after} = [map { "$c->{line}.$_" } 9, 14];
  $mw->update;
  is_deeply(\@seen, [2], 'no -layoutdepth: the callback sees the 2 leaves');
  @g = rel($c, 0, 1);
  is_deeply(splits($c), [want_lines(1, $g[0], (rel($c, 1))[1], $g[2])],
	    'it gives them one box: the line, and no frames');
  # A result that is refused: the default layout, all the leaves one
  # stack, expected to be the root.
  my $d = block('Frac', [4, 6, 4], [1, 2]);
  $mw->update;
  is(scalar(@bgerrors), 0, 'no background errors') or diag(join "\n", @bgerrors);
  $bad = 1;
  $t->blockConfigure('Frac', -layoutdepth => 1);
  $mw->update;
  cmp_ok(scalar(@bgerrors), '>', 0, 'a bad result of the callback is a background error');
  my @D = @{box($d->{head})};
  is_deeply(splits($d), [want_lines(1, 0, (rel($d, 1))[1], $D[2]),
			 want_lines(2, 0, (rel($d, 2))[1], $D[2])],
	    'and the block is laid out by default: lines between all its leaves');
  $bad = 0;
  @bgerrors = ();
 SKIP: {
    skip 'no Tk::WinPhoto to capture the window', 2 unless $can_shoot;
    my $ph = shot();
    ok(drawn($ph, $b), '-layoutdepth 0: drawn as listed');
    ok(drawn($ph, $c), 'no -layoutdepth: drawn as listed');
  }
}

# Destroying a widget whose blocks have split lines.
$t->destroy;
undef $t;
$mw->update;
pass('a widget with split lines is destroyed');
is(scalar(@bgerrors), 0, 'no background errors') or diag(join "\n", @bgerrors);

done_testing();
