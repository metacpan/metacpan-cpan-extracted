#!/usr/bin/perl
# Ornaments: canvas-like primitives whose coordinates are reference
# points computed from the places where the text is drawn.
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

my $t = $mw->eText(-width => 40, -height => 6, -font => 'Courier 12',
		   -highlightthickness => 0)->pack;
$t->insert('end', join '', map { "line $_ with some words\n" } 1..30);
$mw->update;

sub pt { my @r = $t->ornamentPoint(@_); return @r }

# Anchors on the box of a character, as bbox gives it.
my ($bx, $by, $bw, $bh) = $t->bbox('2.5');
is_deeply([pt([at => '2.5', 'nw'])], [$bx, $by, 1], 'nw is the corner of bbox');
is_deeply([pt([at => '2.5', 'se'])], [$bx + $bw, $by + $bh, 1], 'se');
is_deeply([pt([at => '2.5', 'center'])], [$bx + $bw/2, $by + $bh/2, 1], 'center');
is_deeply([pt([at => '2.5', 'c'])], [pt([at => '2.5', 'center'])], 'c is center');
is_deeply([pt([at => '2.5', 'e'])], [$bx + $bw, $by + $bh/2, 1], 'e');
my @base = pt([at => '2.5']);
ok($base[1] > $by && $base[1] < $by + $bh, 'the default anchor bw is on the baseline');
is($base[0], $bx, 'bw is at the left');
is_deeply([pt([at => '2.5', 'be'])], [$bx + $bw, $base[1], 1], 'be');

# A range: the union of the boxes of its characters.
my @b0 = $t->bbox('2.0');
my @b9 = $t->bbox('2.8');
is_deeply([pt([range => '2.0', '2.9', 'nw'])], [$b0[0], $b0[1], 1], 'range nw');
is_deeply([pt([range => '2.0', '2.9', 'se'])],
	  [$b9[0] + $b9[2], $b9[1] + $b9[3], 1], 'range se');
my @two = pt([range => '2.3', '3.2', 'se']);
is($two[1], ($t->bbox('3.0'))[1] + ($t->bbox('3.0'))[3],
   'a range over two lines reaches the second one');
is_deeply([pt([range => '2.4', '2.4', 'n'])], [pt([at => '2.4', 'nw'])],
	  'an empty range is the place of its start, with no width');

# Combinations.
my @p = pt([at => '2.0', 'nw']);
my @q = pt([at => '3.6', 'se']);
is_deeply([pt([mix => 1, [at => '2.0', 'nw'], 1, [at => '3.6', 'se']])],
	  [($p[0] + $q[0])/2, ($p[1] + $q[1])/2, 1], 'mix: the mean');
is_deeply([pt([mix => 3, [at => '2.0', 'nw'], 1, [at => '3.6', 'se']])],
	  [(3*$p[0] + $q[0])/4, (3*$p[1] + $q[1])/4, 1], 'mix: weighted');
is_deeply([pt([offset => [at => '2.0', 'nw'], 5, -3])],
	  [$p[0] + 5, $p[1] - 3, 1], 'offset');
is_deeply([pt([xy => [at => '2.0', 'nw'], [at => '3.6', 'se']])],
	  [$p[0], $q[1], 1], 'xy: the x of one point, the y of another');
is_deeply([pt([min => [at => '2.6', 'nw'], [at => '3.2', 'se']])],
	  [(pt([at => '3.2', 'se']))[0], (pt([at => '2.6', 'nw']))[1], 1], 'min');
is_deeply([pt([max => [at => '2.6', 'nw'], [at => '3.2', 'se']])],
	  [(pt([at => '2.6', 'nw']))[0], (pt([at => '3.2', 'se']))[1], 1], 'max');

# Positions that are not displayed: stand-ins outside the window.
my @below = pt([at => '25.3', 'nw']);
is($below[2], 0, 'a position below the window is not displayed');
ok($below[1] > $t->height, 'its stand-in is below the window');
is($below[0], $t->width / 2,
   'its x, never displayed: the middle of the text area');
$t->yview(10);
$mw->update;
my @above = pt([at => '2.3', 'nw']);
is($above[2], 0, 'a position above the window is not displayed');
ok($above[1] < 0, 'its stand-in is above the window');
my @a1 = pt([at => '1.0', 'nw']);
ok($a1[1] < $above[1], 'further up for a line further up');
$t->yview(0);
$mw->update;

# Anchors on the mid line, fractions.
{
  my ($bx, $by, $bw, $bh) = $t->bbox('2.5');
  my $base = (pt([at => '2.5']))[1];
  my $ex = $t->fontMetrics($t->cget('-font'), '-ascent') / 2;
  is_deeply([pt([at => '2.5', 'mw'])], [$bx, $base - $ex/2, 1],
	    'mw: half an x-height above the baseline, at the left');
  is_deeply([pt([at => '2.5', 'm'])], [$bx + $bw/2, $base - $ex/2, 1], 'm');
  is_deeply([pt([at => '2.5', 'me'])], [$bx + $bw, $base - $ex/2, 1], 'me');
  is_deeply([pt([at => '2.5', [0.25, 0.75]])], [$bx + $bw/4, $by + 3*$bh/4, 1],
	    'an anchor of fractions');
  is_deeply([pt([range => '2.5', '2.7', [1, 0]])], [$bx + 2*$bw, $by, 1],
	    'fractions of a range');
  my $o = $t->ornamentCreate('line', [at => '2.5', [0.5, 0]], [range => '2.0', '2.2', 'me']);
  is_deeply([$t->ornamentPoints($o)], [['at', '2.5', [0.5, 0]], ['range', '2.0', '2.2', 'me']],
	    'points: anchors');
  $t->ornamentDelete($o);
  eval { pt([at => '2.5', [1]]) };
  like($@, qr/bad anchor/, 'a list of one fraction is not an anchor');
}

# A display line of a range, and its outline.
{
  my $union = sub {
    my ($from, $to) = @_;
    my ($x0, $y0, $x1, $y1);
    for (my $i = $t->index($from); $t->compare($i, '<', $to); $i = $t->index("$i + 1c")) {
      my ($x, $y) = pt([at => $i, 'nw']);
      my ($w, $h) = map { $_ } (pt([at => $i, 'se']))[0, 1];
      ($w, $h) = ($w - $x, $h - $y);
      $x0 = $x if !defined $x0 || $x < $x0;
      $y0 = $y if !defined $y0 || $y < $y0;
      $x1 = $x + $w if !defined $x1 || $x + $w > $x1;
      $y1 = $y + $h if !defined $y1 || $y + $h > $y1;
    }
    return ($x0, $y0, $x1, $y1);
  };
  my @l2 = $union->('2.3', '3.0');
  my @l3 = $union->('3.0', '4.0');
  my @l4 = $union->('4.0', '4.5');
  is_deeply([pt([line => '2.3', '4.5', 0, 'nw'])], [@l2[0, 1], 1], 'line 0: the first piece');
  is_deeply([pt([line => '2.3', '4.5', 0, 'se'])], [@l2[2, 3], 1], 'line 0: to its right end');
  is_deeply([pt([line => '2.3', '4.5', 1, 'nw'])], [@l3[0, 1], 1], 'line 1: a whole line');
  is_deeply([pt([line => '2.3', '4.5', -1, 'se'])], [@l4[2, 3], 1], 'line -1: the last piece');
  is_deeply([pt([line => '2.3', '4.5', -2, 'se'])], [@l3[2, 3], 1], 'line -2');
  is_deeply([pt([line => '2.3', '4.5', 7, 'se'])], [@l4[2, 3], 1], 'out of range: the nearest');
  is_deeply([pt([line => '2.3', '4.5', -7, 'nw'])], [@l2[0, 1], 1], 'out of range at the top');
  is_deeply([pt([line => '2.3', '4.5', 0])], [$l2[0], (pt([at => '2.3']))[1], 1],
	    'line: the anchor bw by default');
  is($l2[2], $l3[2], 'lines 2 and 3 end at the same x');
  my $o = $t->ornamentCreate('polygon', [outline => '2.3', '4.5'], -fill => '');
  is_deeply([$t->ornamentCoords($o)],
	    [$l2[0], $l2[1], $l2[2], $l2[1], $l3[2], $l3[3], $l4[2], $l3[3],
	     $l4[2], $l4[3], $l4[0], $l4[3], $l3[0], $l3[1], $l2[0], $l3[1]],
	    'outline: 8 corners clockwise from the top left of the first piece');
  is_deeply([$t->ornamentPoints($o)], [['outline', '2.3', '4.5']], 'points: an outline');
  $t->ornamentPoints($o, [outline => '2.3', '2.6']);
  my @b = $union->('2.3', '2.6');
  is_deeply([$t->ornamentCoords($o)], [@b[0, 1], @b[2, 1], @b[2, 3], @b[0, 3]],
	    'the outline of a range on one line: its box');
  $t->ornamentPoints($o, [at => '1.0'], [outline => '2.3', '2.6'], [at => '1.1']);
  is(scalar(my @c = $t->ornamentCoords($o)), 12, 'an outline among other points');
  $t->ornamentDelete($o);
  $o = $t->ornamentCreate('line', [outline => '2.3', '3.4']);
  is(scalar(@c = $t->ornamentCoords($o)), 16, 'an outline in a line');
  $t->ornamentDelete($o);
  for my $bad (['rectangle', [outline => '2.3', '2.5'], [at => '1.0']],
	       ['line', [mix => 1, [outline => '2.3', '2.5']], [at => '1.0']],
	       ['line', [offset => [outline => '2.3', '2.5'], 1, 1], [at => '1.0']]) {
    eval { $t->ornamentCreate(@$bad) };
    like($@, qr/an outline is allowed only as a point of a line or a polygon/,
	 "outline refused: $bad->[0], $bad->[1][0]");
  }
  eval { pt([outline => '2.3', '2.5']) };
  like($@, qr/an outline is allowed only/, 'outline refused by ornament point');
  is_deeply([$t->ornamentNames], [], 'nothing left');
}

# Inside a block: the display lines of its leaves.
{
  my $f = $mw->eText(-width => 40, -height => 6, -font => 'Courier 12',
		     -highlightthickness => 0)->pack;
  $f->blockConfigure('Frac', -layoutdepth => 1, -layoutwidths => [2],
		     -layoutcmd => sub {
		       my ($data, $x, $super, $sub) = @_;
		       my $w = $super->[2] > $sub->[2] ? $super->[2] : $sub->[2];
		       my $h = $super->[4] + 6 + $sub->[4];
		       return ([-1, 0, 0, $w, $w, $h, $super->[4] + 3],
			       [$super->[0], 0, 0, $super->[2], $super->[2],
				$super->[4], $super->[5]],
			       [$sub->[0], 0, $super->[4] + 6, $sub->[2], $sub->[2],
				$sub->[4], $sub->[5]]);
		     });
  $f->insert('end', "a numer\ndenom b\n");
  $f->blockInsert('Frac', '1.2', '2.5');
  $mw->update;
  my ($s, $e) = ('1.3', $f->index('1.3 + 11c'));
  my @n = $f->ornamentPoint([line => $s, $e, 0, 'nw']);
  my @d = $f->ornamentPoint([line => $s, $e, 1, 'nw']);
  is_deeply([@n[0, 1]], [($f->bbox('1.3'))[0, 1]], 'in a block: line 0 is the first leaf');
  ok($d[1] > $n[1] + 10, 'line 1 is the second leaf, below it');
  my $o = $f->ornamentCreate('polygon', [outline => $s, $e]);
  my @c = $f->ornamentCoords($o);
  my @se = $f->ornamentPoint([line => $s, $e, 1, 'se']);
  is_deeply([@c[0, 1]], [@n[0, 1]], 'its outline starts at the top left of the first leaf');
  cmp_ok(scalar(@c) / 2, '>=', 4, 'its outline has corners');
  is((sort { $b <=> $a } map { $c[2*$_ + 1] } 0 .. $#c/2)[0], $se[1],
     'it reaches the bottom of the second leaf');
  $f->destroy;
}

# Distances in em and ex of the font of the point; yx.
{
  my $font = $t->cget('-font');
  my $em = $t->fontMeasure($font, 'M');
  my $ex = $t->fontMetrics($font, '-ascent') / 2;
  my @p = pt([at => '2.5']);
  is_deeply([pt([offset => [at => '2.5'], '1em', '-1ex'])], [$p[0] + $em, $p[1] - $ex, 1],
	    'offset in em and ex');
  is_deeply([pt([offset => [at => '2.5'], '0.5em', '2'])], [$p[0] + $em/2, $p[1] + 2, 1],
	    'em with pixels');
  my @q = pt([at => '3.7', 'se']);
  is_deeply([pt([yx => [at => '2.5'], [at => '3.7', 'se']])], [$q[0], $p[1], 1],
	    'yx: the y of the first point, the x of the second');
  my $big = 'Courier 24';
  $t->tagConfigure('big', -font => $big);
  $t->tagAdd('big', '4.2', '4.4');
  $mw->update;
  my $bem = $t->fontMeasure($big, 'M');
  my $bex = $t->fontMetrics($big, '-ascent') / 2;
  my @r = pt([range => '4.0', '4.6']);
  is_deeply([pt([offset => [range => '4.0', '4.6'], '1em', '1ex'])],
	    [$r[0] + $bem, $r[1] + $bex, 1], 'a range: its largest font by default');
  is_deeply([pt([offset => [range => '4.0', '4.6'], '1emmin', '1exmin'])],
	    [$r[0] + $em, $r[1] + $ex, 1], 'emmin, exmin: its smallest');
  is_deeply([pt([offset => [range => '4.0', '4.6'], '1emmid', '1exmid'])],
	    [$r[0] + ($em + $bem)/2, $r[1] + ($ex + $bex)/2, 1], 'emmid, exmid');
  is_deeply([pt([offset => [range => '4.0', '4.6'], '1emmax', '1exmax'])],
	    [$r[0] + $bem, $r[1] + $bex, 1], 'emmax, exmax');
  my @a = pt([at => '4.4']);
  is_deeply([pt([offset => [at => '4.4'], '1em', 0])], [$a[0] + $em, $a[1], 1],
	    'an at point: the font of the character after the position');
  @a = pt([at => [leftward => '4.4']]);
  is_deeply([pt([offset => [at => [leftward => '4.4']], '1em', 0])], [$a[0] + $bem, $a[1], 1],
	    'leftward: the font of the character before it');
  @a = pt([at => '4.3', 'm']);
  is_deeply([pt([at => '4.3', 'mw'])], [(pt([at => '4.3']))[0], (pt([at => '4.3']))[1] - $bex/2, 1],
	    'the mid line in the font of the character');
  @a = pt([mix => 1, [at => '4.3'], 1, [at => '4.0']]);
  is_deeply([pt([offset => [mix => 1, [at => '4.3'], 1, [at => '4.0']], '1em', 0])],
	    [$a[0] + $bem, $a[1], 1], 'mix: the font of its first point');
  @a = pt([xy => [at => '4.0'], [at => '4.3']]);
  is_deeply([pt([offset => [xy => [at => '4.0'], [at => '4.3']], '1em', 0])],
	    [$a[0] + $em, $a[1], 1], 'xy: the font of its first point');
  @a = pt([offset => [offset => [at => '4.3'], 0, 0], '1em', 0]);
  is($a[0], (pt([at => '4.3']))[0] + $bem, 'offset: the font of its point');
  $t->tagAdd('big', '25.0', '25.5');
  @a = pt([at => '25.2']);
  is_deeply([pt([offset => [at => '25.2'], '1em', '1ex'])], [$a[0] + $em, $a[1] + $ex, 0],
	    'a stand-in: the font of the widget');
  my $o = $t->ornamentCreate('line', [offset => [at => '2.0'], '0.5em', '-1ex'],
			     [yx => [at => '2.0'], [at => '2.3']]);
  is_deeply([$t->ornamentPoints($o)],
	    [['offset', ['at', '2.0', 'bw'], '0.5em', '-1ex'],
	     ['yx', ['at', '2.0', 'bw'], ['at', '2.3', 'bw']]], 'points: units, yx');
  $t->ornamentDelete($o);
  $t->tagDelete('big');
  eval { pt([offset => [at => '2.0'], 'em', 0]) };
  like($@, qr/bad screen distance "em"/, 'a unit without a number');
  eval { pt([offset => [at => '2.0'], '1en', 0]) };
  like($@, qr/bad screen distance "1en"/, 'an unknown unit');
  $mw->update;
}

# Arcs and texts.
{
  my $a = $t->ornamentCreate('arc', [at => '2.0', 'nw'], [at => '3.4', 'se']);
  is($t->ornamentCget($a, '-start'), 0, 'arc -start');
  is($t->ornamentCget($a, '-extent'), 90, 'arc -extent');
  is($t->ornamentCget($a, '-style'), 'pieslice', 'arc -style');
  is($t->ornamentCget($a, '-outline'), 'black', 'arc -outline');
  is(scalar(my @c = $t->ornamentCoords($a)), 4, 'arc: coords of its two points');
  $t->ornamentConfigure($a, -style => 'chord', -start => 45, -extent => -200,
			-fill => 'red', -dash => '2 2', -keep => 1);
  is($t->ornamentCget($a, '-style'), 'chord', 'configure -style');
  eval { $t->ornamentConfigure($a, -style => 'wedge') };
  like($@, qr/bad arc style "wedge"/, 'a bad style');
  $t->ornamentDelete($a);
  my $x = $t->ornamentCreate('text', [at => '2.0', 'n'], -text => 'Hi');
  is($t->ornamentCget($x, '-text'), 'Hi', 'text -text');
  is($t->ornamentCget($x, '-anchor'), 'center', 'text -anchor');
  is($t->ornamentCget($x, '-fill'), 'black', 'text -fill');
  is_deeply([$t->ornamentCoords($x)], [(pt([at => '2.0', 'n']))[0, 1]],
	    'text: coords of its point');
  $t->ornamentConfigure($x, -font => 'Courier 20', -anchor => 'sw');
  is($t->ornamentCget($x, '-anchor'), 'sw', 'configure -anchor');
  $t->ornamentDelete($x);
  my @errors = (
    [['arc', [at => '1.0']], qr/wrong # points for an arc: must be 2/],
    [['text', [at => '1.0'], [at => '1.1']], qr/wrong # points for a text: must be 1/],
    [['text', [outline => '1.0', '1.2']], qr/an outline is allowed only/],
    [['text', [at => '1.0'], -arrow => 'last'], qr/Bad option `-arrow/],
    [['arc', [at => '1.0'], [at => '1.1'], -anchor => 'n'], qr/Bad option `-anchor/],
  );
  for my $e (@errors) {
    eval { $t->ornamentCreate(@{$e->[0]}) };
    like($@, $e->[1], "error: $e->[1]");
  }
  is_deeply([$t->ornamentNames], [], 'none left');
}

# The x of a stand-in: remembered from when the position was displayed,
# else the middle of the text area, or proportional to its offset in its
# line with -ornamentproportional.  No line is laid out for it.
{
  my $o = $t->ornamentCreate('line', [at => '5.3'], [at => '12.0']);
  $mw->update;
  my @c = $t->ornamentCoords($o);
  is($c[0], ($t->bbox('5.3'))[0], 'a displayed position');
  $t->yview(8);
  $mw->update;
  @c = $t->ornamentCoords($o);
  ok($c[1] < 0, 'scrolled out of the window');
  is($c[0], ($t->bbox('9.3'))[0], 'its stand-in has the x it had when displayed');
  $t->ornamentPoints($o, [at => '5.6'], [at => '12.0']);
  is(($t->ornamentCoords($o))[0], $t->width / 2,
     'a new point never displayed: the middle');
  my $inset = ($t->bbox('9.0'))[0];
  $t->configure(-ornamentproportional => 1);
  is($t->cget('-ornamentproportional'), 1, '-ornamentproportional');
  my $len = length($t->get('5.0', '5.0 lineend'));
  is(($t->ornamentCoords($o))[0], $inset + ($t->width - 2*$inset) * 6 / $len,
     '-ornamentproportional: proportional to its offset in its line');
  is((pt([at => '5.0 lineend', 'nw']))[0], $t->width - $inset, 'the end of a line: the right');
  $t->configure(-ornamentproportional => 0);
  $t->ornamentDelete($o);
  $t->yview(0);
  $mw->update;
  # Horizontal scrolling moves a remembered x with the text.
  my $h = $mw->eText(-width => 20, -height => 3, -wrap => 'none', -font => 'Courier 12',
		     -highlightthickness => 0)->pack;
  $h->insert('end', join '', map { "$_ " . ('abcdefghij' x 6) . "\n" } 1 .. 20);
  $mw->update;
  my $ho = $h->ornamentCreate('line', [at => '1.10'], [at => '7.0']);
  $mw->update;
  my $x0 = ($h->ornamentCoords($ho))[0];
  is($x0, ($h->bbox('1.10'))[0], 'displayed');
  $h->yview(5);
  $mw->update;
  is(($h->ornamentCoords($ho))[0], $x0, 'not displayed: the x remembered');
  my $before = ($h->bbox('6.12'))[0];
  $h->xview(scroll => 4, 'units');
  $mw->update;
  my $shift = $before - ($h->bbox('6.12'))[0];
  ok($shift > 0, 'scrolled horizontally');
  is(($h->ornamentCoords($ho))[0], $x0 - $shift,
     'the stand-in moves with the text');
  $h->destroy;
}

# The commands.
my $id = $t->ornamentCreate('line', [at => '2.0', 'sw'], [at => '2.4', 'se'],
			    -fill => 'red', -width => 2, -arrow => 'last');
like($id, qr/^\d+$/, 'create returns an id');
is_deeply([$t->ornamentNames], [$id], 'names');
is($t->ornamentCget($id, '-width'), 2, 'cget');
is($t->ornamentCget($id, '-arrow'), 'last', 'cget -arrow');
my @c = $t->ornamentCoords($id);
is_deeply(\@c, [(pt([at => '2.0', 'sw']))[0, 1], (pt([at => '2.4', 'se']))[0, 1]],
	  'coords: the points as they are now');
my @pts = $t->ornamentPoints($id);
is_deeply(\@pts, [['at', '2.0', 'sw'], ['at', '2.4', 'se']], 'points');
$t->ornamentPoints($id, [at => '3.0'], [at => '3.4'], [at => '4.0']);
is(scalar(my @x = $t->ornamentCoords($id)), 6, 'points replaced');
$t->ornamentConfigure($id, -dash => '4 2', -capstyle => 'round');
is($t->ornamentCget($id, '-dash'), '4 2', 'configure -dash');

# Marks: the ornament follows the text.
$t->markSet('m', '5.5');
my $o2 = $t->ornamentCreate('rectangle', [at => 'm', 'nw'], [at => 'm+3c', 'se']);
my @before = $t->ornamentCoords($o2);
$t->insert('5.0', 'xxxx');
my @after = $t->ornamentCoords($o2);
ok($after[0] > $before[0], 'an ornament on a mark moves with the text');
$t->markUnset('m');
is_deeply([$t->ornamentCoords($o2)], [], 'no coords once its mark is gone');
$mw->update;
is(scalar(@bgerrors), 0, 'and no error while drawing it');
$t->ornamentDelete($o2);

# Nothing displayed: not drawn.
my $o3 = $t->ornamentCreate('oval', [at => '20.0', 'nw'], [at => '21.3', 'se']);
is_deeply([$t->ornamentCoords($o3)], [], 'an ornament off the window has no coords');
$t->ornamentDelete($o3, $id);
is_deeply([$t->ornamentNames], [], 'delete');

# Errors.
my @errors = (
  [['blob', [at => '1.0'], [at => '1.1']], qr/bad ornament type "blob"/],
  [['line', [at => '1.0']], qr/wrong # points for a line/],
  [['polygon', [at => '1.0'], [at => '1.1']], qr/wrong # points for a polygon/],
  [['oval', [at => '1.0'], [at => '1.1'], [at => '1.2']], qr/wrong # points for an oval/],
  [['line', [at => 'nosuchmark'], [at => '1.1']], qr/bad text index "nosuchmark"/],
  [['line', [at => '1.0', 'up'], [at => '1.1']], qr/bad anchor "up"/],
  [['line', [blob => '1.0'], [at => '1.1']], qr/bad point kind "blob"/],
  [['line', [mix => 1, [at => '1.0'], -1, [at => '1.1']], [at => '1.1']],
   qr/the weights of mix add up to 0/],
  [['line', [offset => [at => '1.0'], 'x', 1], [at => '1.1']], qr/bad screen distance/],
  [['line', [at => '1.0'], [at => '1.1'], -dash => 'a b'], qr/bad dash list/],
  [['line', [at => '1.0'], [at => '1.1'], -arrow => 'up'], qr/bad arrow spec/],
  [['line', [at => '1.0'], [at => '1.1'], -layer => 'top'], qr/bad layer/],
  [['line', [at => '1.0'], [at => '1.1'], -nosuch => 1], qr/Bad option `-nosuch/],
);
for my $e (@errors) {
  eval { $t->ornamentCreate(@{$e->[0]}) };
  like($@, $e->[1], "error: $e->[1]");
}
is_deeply([$t->ornamentNames], [], 'a failed create leaves no ornament');
eval { $t->ornamentDelete(99) };
like($@, qr/ornament "99" doesn't exist/, 'delete of an unknown id');

# Private marks: an index that names no mark and no tag becomes a mark
# of the ornament's own, which the program never sees.
{
  my $p = $mw->eText(-width => 40, -height => 6, -font => 'Courier 12',
		     -undo => 1)->pack;
  $p->insert('end', "line 1 abc\nline 2 abcdefgh\nline 3\n");
  $p->markSet(m => '3.2');
  $p->tagAdd('t', '3.0', '3.4');
  my @names0 = sort $p->markNames;
  my $o = $p->ornamentCreate('line', [at => '2.0'], [range => '2.2', '2.5', 'se'],
			     [at => 'insert'], [at => '2.0 lineend'],
			     [range => 'm', 't.last'], [at => [leftward => '2.7']],
			     [at => [rightward => 'm']]);
  is_deeply([sort $p->markNames], \@names0, 'private marks: not in mark names');
  my @marks = do { my @m; my $i = '1.0';
		   while (defined(my $n = $p->markNext($i)) ) { last if $n eq ''; push @m, $n; $i = $n } @m };
  is_deeply([sort @marks], \@names0, 'nor found by mark next');
  @marks = do { my @m; my $i = 'end';
		while (defined(my $n = $p->markPrevious($i))) { last if $n eq ''; push @m, $n; $i = $n } @m };
  is_deeply([sort @marks], \@names0, 'nor by mark previous');
  my @d = $p->dump('-mark', '1.0', 'end');
  is_deeply([sort grep { $_ ne 'mark' && !/^\d+\.\d+$/ } @d], \@names0, 'nor by dump');
  ok(!grep({ /\001/ } map { ref $_ ? (ref $_ eq 'ARRAY' ? @$_ : $$_) : $_ }
	   $p->blockList('1.0', 'end')), 'nor by block list');
  is_deeply([$p->ornamentPoints($o)],
	    [['at', '2.0', 'bw'], ['range', '2.2', '2.5', 'se'], ['at', 'insert', 'bw'],
	     ['at', '2.15', 'bw'], ['range', 'm', 't.last', 'bw'],
	     ['at', ['leftward', '2.7'], 'bw'], ['at', ['rightward', '3.2'], 'bw']],
	    'points: the indices of the private marks, the others as given');
  $p->insert('2.0', 'XYZ ');
  $p->insert('3.0', 'ab');
  is_deeply([map { $_->[1] } $p->ornamentPoints($o)],
	    ['2.4', '2.6', 'insert', '2.19', 'm', ['leftward', '2.11'], ['rightward', '3.4']],
	    'a private mark stays on its character');
  is(($p->ornamentPoints($o))[1][2], '2.9', 'the end of a range follows too');
  $p->insert('2.9', 'QQ');
  is(($p->ornamentPoints($o))[1][2], '2.9', 'text inserted at the end of a range stays outside');
  $p->insert('2.6', 'R');
  is_deeply([@{($p->ornamentPoints($o))[1]}[1, 2]], ['2.7', '2.10'],
	    'text inserted at its start goes before it');
  my $l = ($p->ornamentPoints($o))[5][1][1];
  is($l, '2.14', 'leftward: the mark has moved with the text before it');
  $p->insert($l, 'L');
  is_deeply(($p->ornamentPoints($o))[5][1], ['leftward', $l],
	    'leftward: text inserted at the mark goes after it');
  # Undo puts a private mark back with the text, as a program mark.
  $p->delete('2.0', '2.12');
  is(($p->ornamentPoints($o))[0][1], '2.0', 'deleted text: the mark at the deletion');
  $p->editUndo;
  is(($p->ornamentPoints($o))[0][1], '2.4', 'undo puts it back');
  is_deeply([sort $p->markNames], \@names0, 'and still no private mark in mark names');
  # The program cannot name them.
  my @err;
  for my $n (map { "\001orn$_" } 1 .. 40) {
    push @err, $n if eval { $p->markGravity($n); 1 } || eval { $p->index($n); 1 }
      || eval { $p->markData($n); 1 };
  }
  is_deeply(\@err, [], 'a private mark cannot be named (gravity, index, data)');
  eval { $p->markSet("\001x", '1.0') };
  like($@, qr/reserved/, 'mark set refuses a name starting with \\001');
  # Inside a block.
  $p->blockConfigure('B');
  $p->blockInsert('B', '1.2', '1.6');
  my $ob = $p->ornamentCreate('line', [at => '1.3'], [range => '1.4', '1.5']);
  my $flat; $flat = sub { map { ref $_ eq 'ARRAY' || ref($_) =~ /^Tk::Text::Block/ ? $flat->(@$_)
				: ref $_ ? $$_ : $_ } @_ };
  ok(!grep({ defined && /\001/ } $flat->($p->blockList('1.0', 'end'))),
     'nor by block list, inside a block');
  is_deeply([map { @$_[1 .. $#$_ - 1] } $p->ornamentPoints($ob)], ['1.3', '1.4', '1.5'],
	    'private marks inside a block');
  $p->ornamentDelete($ob);
  # Replacing the points or deleting the ornament unsets its marks:
  # watched through the process size over many ornaments.
  SKIP: {
    my $statm = '/proc/self/statm';
    skip "no $statm", 1 unless -r $statm;
    my $rss = sub { open my $fh, '<', $statm or return 0;
		    (split ' ', scalar <$fh>)[1] * 4096 };
    my $loop = sub {
      for (1 .. $_[0]) {
	my $id = $p->ornamentCreate('rectangle', [range => '1.1', '1.4'], [at => '2.3']);
	$p->ornamentPoints($id, [at => [leftward => '1.2']], [range => '1.0', '2.0']);
	$p->ornamentDelete($id);
      }
    };
    $loop->(500);
    my $n = 5000;
    my $before = $rss->();
    $loop->($n);
    my $grown = $rss->() - $before;
    cmp_ok($grown / $n, '<', 16, "private marks are freed ($grown bytes for $n ornaments)");
  }
  $p->ornamentCreate('line', [at => '1.0'], [at => '1.2']);
  $p->destroy;
  pass('a widget with private marks is destroyed');
}

# Auto-delete: an ornament whose text is all deleted goes with it.
{
  my $p = $mw->eText(-width => 40, -height => 6, -font => 'Courier 12',
		     -undo => 1)->pack;
  my $text = "line 1 abcdefgh\nline 2 abcdefgh\nline 3 abcdefgh\nline 4\n";
  my $reset = sub { $p->ornamentDelete($p->ornamentNames); $p->delete('1.0', 'end');
		    $p->insert('end', $text); $p->editReset };
  my $alive = sub { my $id = shift; scalar grep { $_ == $id } $p->ornamentNames };
  my @cases = (
    # points, deleted range, deleted?, name
    [[[at => '2.3'], [at => '2.5']], '2.0', '2.6', 1, 'at points all in the range'],
    [[[at => '2.3'], [at => '2.6']], '2.0', '2.6', 0, 'an at point just after the range'],
    [[[range => '2.2', '2.6', 'nw'], [range => '2.2', '2.6', 'se']], '2.2', '2.6', 1,
     'a range exactly deleted'],
    [[[range => '2.2', '2.6'], [at => '2.3']], '2.2', '2.5', 0, 'a range partly deleted'],
    [[[at => '2.1'], [at => '3.1']], '2.0', '3.0', 0, 'one of two lines deleted'],
    [[[at => '2.1'], [offset => [at => '3.1'], 2, 2]], '2.0', '4.0', 1, 'both, nested in offset'],
    [[[at => [leftward => '2.3']], [at => '2.2']], '2.2', '2.3', 1,
     'leftward: the character before the mark'],
    [[[at => [leftward => '2.3']], [at => '2.3']], '2.3', '2.4', 0,
     'leftward: not the character after it'],
    [[[at => 'insert'], [at => '2.3']], '1.0', 'end', 0, 'a program mark: never'],
    [[[at => '2.3'], [at => 'end']], '1.0', 'end', 0, 'end: never'],
    [[[at => '2.3'], [at => '2.4']], '1.0', 'end', 1, 'deleting everything'],
  );
  for my $c (@cases) {
    my ($pts, $from, $to, $gone, $name) = @$c;
    $reset->();
    my $id = $p->ornamentCreate('line', @$pts);
    $p->delete($from, $to);
    is(!$alive->($id), !!$gone, "auto-delete: $name");
  }
  $reset->();
  my $id = $p->ornamentCreate('line', [at => '2.3'], [at => '2.5'], -keep => 1);
  is($p->ornamentCget($id, '-keep'), 1, '-keep');
  $p->delete('2.0', '2.6');
  ok($alive->($id), '-keep 1: the ornament stays');
  is_deeply([map { $_->[1] } $p->ornamentPoints($id)], ['2.0', '2.0'],
	    'its marks are where the text was');
  $p->editUndo;
  is_deeply([map { $_->[1] } $p->ornamentPoints($id)], ['2.3', '2.5'],
	    'and go back with the undo');
  $p->ornamentConfigure($id, -keep => 0);
  $p->delete('2.0', '2.6');
  ok(!$alive->($id), '-keep 0: deleted');
  my @names = sort $p->markNames;
  $p->editUndo;
  is_deeply([$p->ornamentNames], [], 'undo does not bring it back');
  is_deeply([sort $p->markNames], \@names, 'nor its marks');
  $p->editRedo;
  $mw->update;
  SKIP: {
    skip 'no Tk::WinPhoto to capture the window', 1
      unless eval { require Tk::WinPhoto; 1 };
    my @w = map { $mw->eText(-width => 30, -height => 4, -font => 'Courier 12',
			     -highlightthickness => 0)->pack } 1 .. 2;
    $_->insert('end', $text) for @w;
    $w[0]->ornamentCreate('rectangle', [range => '2.2', '2.6', 'nw'],
			  [range => '2.2', '2.6', 'se'], -fill => 'red');
    $mw->update;
    $w[0]->delete('2.2', '2.6');
    $w[1]->delete('2.2', '2.6');
    my @shot = map { $mw->update;
		     $mw->Photo(-format => 'Window', -data => oct($_->id))->data } @w;
    ok($shot[0] eq $shot[1], 'auto-deleted: the pixels of a widget that never had it');
    $_->destroy for @w;
  }
  $p->destroy;
}

# Drawing: an ornament changes the pixels, and moving or deleting it
# leaves them as if it had never been drawn.  Compare with a widget that
# draws the final state from scratch.
SKIP: {
  skip 'no Tk::WinPhoto to capture the window', 6
    unless eval { require Tk::WinPhoto; 1 };
  my $text = join '', map { "line $_ " . ('x' x ($_ % 17)) . "\n" } 1..60;
  my @w = map { $mw->eText(-width => 30, -height => 8, -bd => 2, -padx => 3,
			   -pady => 1, -highlightthickness => 0,
			   -font => 'Courier 12')->pack } 1..2;
  my $shot = sub { $mw->update;
		   $mw->Photo(-format => 'Window', -data => oct($_[0]->id))->data };
  $_->insert('end', $text) for @w;
  my $plain = $shot->($w[0]);
  my @mk = (['line', [at => 'a', 'sw'], [at => 'b', 'ne'], [offset => [at => 'b', 's'], 0, 30],
	     -width => 3, -fill => 'red', -smooth => 1, -arrow => 'both'],
	    ['rectangle', [range => 'a', 'b', 'nw'], [range => 'a', 'b', 'se'],
	     -fill => 'yellow', -layer => 'under'],
	    ['polygon', [at => 'b', 'nw'], [at => 'c', 'se'], [at => 'c', 'sw'],
	     -fill => 'blue'],
	    ['polygon', [outline => 'a', 'c'], -outline => 'green', -width => 2],
	    ['line', [line => 'a', 'c', 1, 'nw'], [line => 'a', 'c', -1, 'me'],
	     -fill => 'magenta'],
	    ['arc', [at => 'a', 'nw'], [offset => [at => 'c', 'se'], '2em', '1ex'],
	     -start => 30, -extent => 200, -style => 'chord', -fill => 'cyan'],
	    ['arc', [at => 'b', 'nw'], [at => 'c', 'se'], -style => 'arc', -width => 2],
	    ['text', [offset => [at => 'b', 'n'], 0, '-1ex'], -text => 'note',
	     -anchor => 's', -fill => 'darkgreen']);
  $w[0]->markSet(a => '2.2'); $w[0]->markSet(b => '3.6'); $w[0]->markSet(c => '5.3');
  my @ids = map { $w[0]->ornamentCreate(@$_) } @mk;
  my $drawn = $shot->($w[0]);
  ok($drawn ne $plain, 'the ornaments are drawn');
  # Edit, scroll (lines are copied), scroll back, configure.
  $w[0]->insert('2.0', "ab\ncd ");
  $mw->update;
  $w[0]->yviewScroll(2, 'units');
  $mw->update;
  $w[0]->yviewScroll(-1, 'units');
  $mw->update;
  $w[0]->delete('4.0', '5.0');
  $w[0]->ornamentConfigure($ids[0], -width => 1);
  $mw->update;
  # The same state, drawn from scratch.
  $w[1]->insert('2.0', "ab\ncd ");
  $w[1]->delete('4.0', '5.0');
  $w[1]->yview(1);
  for my $m (qw(a b c)) { $w[1]->markSet($m => $w[0]->index($m)) }
  my @ids1 = map { $w[1]->ornamentCreate(@$_) } @mk;
  $w[1]->ornamentConfigure($ids1[0], -width => 1);
  is($w[0]->index('@0,0'), $w[1]->index('@0,0'), 'both show the same line first');
  my ($d0, $d1) = ($shot->($w[0]), $shot->($w[1]));
  ok($d0 eq $d1, 'edited, scrolled and reconfigured: the pixels of a fresh drawing');
  $w[0]->ornamentDelete(@ids);
  $w[1]->ornamentDelete(@ids1);
  ($d0, $d1) = ($shot->($w[0]), $shot->($w[1]));
  ok($d0 eq $d1, 'deleted: the same pixels in both');
  my $fresh = $mw->eText(-width => 30, -height => 8, -bd => 2, -padx => 3,
			 -pady => 1, -highlightthickness => 0,
			 -font => 'Courier 12')->pack;
  $fresh->insert('end', $w[0]->get('1.0', 'end - 1c'));
  $fresh->yview(1);
  ok($shot->($fresh) eq $d0, 'and those of a widget that never had ornaments');
  # A hidden ornament is not drawn.
  my $h = $w[0]->ornamentCreate('rectangle', [at => '3.0', 'nw'], [at => '3.4', 'se'],
				-fill => 'red', -state => 'hidden');
  ok($shot->($w[0]) eq $d0, 'a hidden ornament is not drawn');
  $w[0]->ornamentConfigure($h, -state => 'normal');
  ok($shot->($w[0]) ne $d0, 'shown when its state is normal');
  $_->destroy for @w, $fresh;
}

# Ornaments returned by a layout callback: drawn with the block, in
# pixels from its top left corner, under or over its text, in their
# order among its additional (stolen) lines; they are not leaves.
SKIP: {
  skip 'no Tk::WinPhoto to capture the window', 20
    unless eval { require Tk::WinPhoto; 1 };
  my $b = $mw->eText(-width => 30, -height => 5, -font => 'Courier 12',
		     -highlightthickness => 0)->pack;
  my $shot = sub { $mw->update;
		   $mw->Photo(-format => 'Window', -data => oct($b->id)) };
  my $px = sub { my ($ph, $x, $y) = @_; join ',', $ph->get($x, $y) };
  my (@extra, @args);
  $b->blockConfigure('P', -layoutcmd => sub {
    my ($info, $x, @leaves) = @_;
    @args = @leaves;
    my ($rc, $y, $w, $tw, $h, $base) = @{$leaves[0]};
    my @rest = map { [$_->[0], 10, 10 + $_->[1], @$_[2 .. 5]] } @leaves[1 .. $#leaves];
    return ([0, 0, 0, $w + 20, $tw + 20, $h + 20, $base + 10],
	    [1, 10, 10, $w, $tw, $h, $base], @extra, @rest);
  });
  $b->insert('1.0', "ab cdef gh\nstolen\n");
  $b->tagConfigure('blue', -background => 'blue');
  $b->tagAdd('blue', '2.0', '2.end');
  $b->blockInsert('P', '1.3', '1.7');
  my $plain = $shot->()->data;
  my @bb = $b->bbox('1.3');		# The block as a whole.
  @extra = (['rectangle', 2, 3, 9, 8, -fill => 'red', -outline => undef],
	    ['line', 0, 0, 20, 0, -fill => 'green']);
  $b->blockConfigure('P', -layoutdepth => -1);	# Lays it out again.
  my $ph = $shot->();
  is($px->($ph, $bb[0] + 5, $bb[1] + 5), '255,0,0', 'a rectangle in the block');
  is($px->($ph, $bb[0] + 2, $bb[1] + 3), '255,0,0', 'at its corner');
  isnt($px->($ph, $bb[0] + 10, $bb[1] + 9), '255,0,0', 'not beyond it');
  is($px->($ph, $bb[0] + 15, $bb[1]), '0,255,0', 'a line on the top of the block');
  is(scalar(@args), 1, 'the ornaments are not leaves');
  # Under and over the text: a box over the leaf hides its letters.
  my @leaf = $b->bbox('1.4');
  my ($lx, $ly) = ($leaf[0] - $bb[0], $leaf[1] - $bb[1]);
  my $box = sub { ['rectangle', $lx, $ly, $lx + 4*$leaf[2], $ly + $leaf[3],
		   -fill => 'yellow', -outline => undef, @_] };
  my $count = sub { my ($ph, $c) = @_; my $n = 0;
		    for my $x ($leaf[0] .. $leaf[0] + 4*$leaf[2] - 1) {
		      for my $y ($leaf[1] .. $leaf[1] + $leaf[3] - 1) {
			$n++ if $px->($ph, $x, $y) eq $c } } $n };
  @extra = ($box->(-layer => 'over'));
  $b->blockConfigure('P', -layoutdepth => -1);
  $ph = $shot->();
  is($count->($ph, '255,255,0'), 4*$leaf[2]*$leaf[3], 'over the text: all of it yellow');
  @extra = ($box->(-layer => 'under'));
  $b->blockConfigure('P', -layoutdepth => -1);
  $ph = $shot->();
  my $yellow = $count->($ph, '255,255,0');
  cmp_ok($yellow, '<', 4*$leaf[2]*$leaf[3] - 10, 'under the text: the letters are drawn on it');
  cmp_ok($yellow, '>', 10, 'and the box around them');
  # Among the stolen lines: an ornament under the text returned before
  # a stolen line is under it, one returned after it is over it.
  my $id = $b->blockAddline('2.0');
  my @sl = $b->bbox('2.0');
  my $under = sub { ['rectangle', 0, 0, 12, 12, -fill => 'red', -outline => undef,
		     -layer => 'under'] };
  @extra = ($under->(), [$id, 0, 0, @sl[2, 2, 3], $sl[3] - 3]);
  $b->blockConfigure('P', -layoutdepth => -1);
  $ph = $shot->();
  is($px->($ph, $bb[0] + 2, $bb[1] + 2), '0,0,255', 'returned before a stolen line: under it');
  @extra = ([$id, 0, 0, @sl[2, 2, 3], $sl[3] - 3], $under->());
  $b->blockConfigure('P', -layoutdepth => -1);
  $ph = $shot->();
  is($px->($ph, $bb[0] + 2, $bb[1] + 2), '255,0,0', 'returned after it: over it');
  # Errors are reported as other bad results: a background error, and
  # the block is laid out by default.
  @bgerrors = ();
  for my $bad (['line', 0, 0, 20, 'x'], ['line', 0, 0, 20], ['line', 1, 2],
	       ['oval', 0, 0, 1, 1, 2, 2], ['line', 0, 0, 5, 5, -bogus => 1],
	       ['line', 0, 0, 5, 5, -arrow => 'sideways']) {
    @extra = ($bad);
    $b->blockConfigure('P', -layoutdepth => -1);
    $mw->update;
  }
  is(scalar(@bgerrors), 6, 'each bad ornament is a background error');
  like($bgerrors[0], qr/isn't numeric.* in an ornament returned by the layout callback of block "P"/,
       'a coordinate that is no number');
  like(join("\n", @bgerrors[1 .. 5]),
       qr/odd number of coordinates.*\n.*wrong # points for a line.*\n.*wrong # points for an oval.*\n.*Bad option `-bogus.*\n.*bad arrow spec/,
       'odd coordinates, too few or too many points, bad options')
    or diag(join "\n", @bgerrors);
  # Several leaves: the ornaments may come anywhere after the first list.
  @bgerrors = ();
  $b->delete('1.0', 'end');
  $b->insert('1.0', "ab cd\nef gh\n");
  $b->blockInsert('P', '1.3', '2.2');
  @extra = (['oval', 0, 0, 10, 10, -fill => 'red']);
  $b->blockConfigure('P', -layoutdepth => -1);
  $mw->update;
  is(scalar(@args), 2, 'two leaves');
  is(scalar(@bgerrors), 0, 'an ornament between the lists of the leaves is accepted')
    or diag(join "\n", @bgerrors);
  # A smoothed line that is straight, on a half pixel: one row of
  # pixels, not steps between two (rounding of the smoothed points).
  $b->delete('1.0', 'end');
  $b->insert('1.0', "ab cd\n");
  $b->blockInsert('P', '1.3', '1.5');
  @extra = (['line', (map { ($_ * 7, 10.5) } 0 .. 6), -smooth => 1, -fill => 'red']);
  $b->blockConfigure('P', -layoutdepth => -1);
  $ph = $shot->();
  @bb = $b->bbox('1.3');
  my %rows;
  for my $x ($bb[0] + 2 .. $bb[0] + 40) {
    for my $y ($bb[1] + 8 .. $bb[1] + 13) {
      $rows{$y - $bb[1]}++ if $px->($ph, $x, $y) eq '255,0,0';
    }
  }
  is(join(',', sort keys %rows), '11', 'a straight smoothed line on a half pixel: one row');
  # A block nested in a leaf: its ornaments at its own corner.
  $b->delete('1.0', 'end');
  $b->insert('1.0', "ab cdefg hi\n");
  $b->blockInsert('P', '1.3', '1.9');
  $b->blockInsert('P', '1.5', '1.7');
  @extra = (['rectangle', 0, 0, 6, 6, -fill => 'red', -outline => undef]);
  $b->blockConfigure('P', -layoutdepth => -1);
  $ph = $shot->();
  my @in = $b->bbox('1.5');
  my @out = $b->bbox('1.3');
  isnt("@in[0, 1]", "@out[0, 1]", 'the nested block is inside the outer one');
  is($px->($ph, $in[0] + 3, $in[1] + 3), '255,0,0', 'the nested block draws at its corner');
  is($px->($ph, $out[0] + 3, $out[1] + 3), '255,0,0', 'the outer block at its own');
  @extra = ();
  $b->destroy;
  is(scalar(@bgerrors), 0, 'no background errors') or diag(join "\n", @bgerrors);
  @bgerrors = ();
}

# Templates of a block type (block configure -ornaments): their points
# are computed from the boxes of the block and of its leaves.
SKIP: {
  skip 'no Tk::WinPhoto to capture the window', 33
    unless eval { require Tk::WinPhoto; 1 };
  my $f = $mw->eText(-width => 30, -height => 5, -font => 'Courier 12',
		     -highlightthickness => 0)->pack;
  my $shot = sub { $mw->update;
		   $mw->Photo(-format => 'Window', -data => oct($f->id)) };
  my $px = sub { my ($ph, $x, $y) = @_; join ',', $ph->get($x, $y) };
  my $hide = 0;
  $f->blockConfigure('Frac', -layoutdepth => 1, -layoutwidths => [2],
		     -layoutcmd => sub {
		       my ($data, $x, $num, $den) = @_;
		       my $w = $num->[2] > $den->[2] ? $num->[2] : $den->[2];
		       my $h = $num->[4] + 6 + $den->[4];
		       return ([-1, 0, 0, $w + 8, $w + 8, $h, $num->[4] + 3],
			       [$num->[0], 4, 0, $num->[2], $num->[2], $num->[4], $num->[5]],
			       $hide ? [1] :
			       [$den->[0], 4, $num->[4] + 6, $den->[2], $den->[2],
				$den->[4], $den->[5]]);
		     });
  $f->insert('end', "a numer\ndenom b\n");
  $f->blockInsert('Frac', '1.2', '2.5');
  my $plain = $shot->()->data;
  my $bar = ['line', [xy => [block => 'w'], [mix => 1, [leaf => 0, 's'], 1, [leaf => 1, 'n']]],
	     [xy => [block => 'e'], [mix => 1, [leaf => 0, 's'], 1, [leaf => 1, 'n']]],
	     -fill => 'red'];
  $f->blockConfigure('Frac', -ornaments => [$bar]);
  my $got = $f->blockCget('Frac', '-ornaments');
  is(ref $got, 'ARRAY', 'cget -ornaments gives the list');
  is($got->[0][0], 'line', 'as given');
  my $ph = $shot->();
  my @bb = $f->bbox('1.2');		# The block.
  my @l0 = $f->bbox('1.8');		# The first leaf (its separator).
  my @l1 = $f->bbox('1.14');		# The second leaf (the tail).
  my $ybar = int(($l0[1] + $l0[3] + $l1[1]) / 2);
  is($px->($ph, $bb[0] + 1, $ybar), '255,0,0', 'the bar starts at the left of the block');
  is($px->($ph, $bb[0] + $bb[2] - 1, $ybar), '255,0,0', 'and reaches its right');
  isnt($px->($ph, $bb[0] + 1, $ybar - 2), '255,0,0', 'it is one pixel thick');
  # Anchors of leaves and of the block.
  my ($bx, $base) = $f->ornamentPoint([at => '1.3']);
  my (undef, $mid) = $f->ornamentPoint([at => '1.3', 'mw']);
  $f->blockConfigure('Frac', -ornaments => [
    ['rectangle', [block => 'nw'], [offset => [block => 'se'], -1, -1], -outline => 'blue'],
    ['line', [leaf => 0, 'bw'], [leaf => 0, 'be'], -fill => 'green'],
    ['line', [leaf => 0, 'mw'], [leaf => 0, 'me'], -fill => 'magenta'],
    ['rectangle', [leaf => 1, [0.5, 0.5]], [offset => [leaf => 1, 'c'], 2, 2],
     -fill => 'cyan', -outline => undef],
    ['line', [offset => [block => 'n'], '1em', 0], [offset => [block => 's'], '1em', 0],
     -fill => 'orange'],
  ]);
  $ph = $shot->();
  is($px->($ph, $bb[0], $bb[1]), '0,0,255', 'block nw is the corner of its bbox');
  is($px->($ph, $bb[0] + $bb[2] - 1, $bb[1] + $bb[3] - 1), '0,0,255', 'block se the other');
  is($px->($ph, $l0[0] + 2, $base), '0,255,0', 'leaf bw: the baseline of its first line');
  is($px->($ph, $l0[0] + $l0[2] - 2, $base), '0,255,0', 'leaf be: its right end');
  is($px->($ph, $l0[0] + 2, int($mid + 0.5)), '255,0,255', 'leaf mw: the mid line');
  is($px->($ph, int($l1[0] + $l1[2]/2) + 1, int($l1[1] + $l1[3]/2) + 1), '0,255,255',
     'a fraction anchor: the centre of the leaf');
  my $em = $f->fontMeasure($f->cget('-font'), 'M');
  is($px->($ph, int($bb[0] + $bb[2]/2 + $em), $bb[1] + 3), '255,165,0',
     'an offset in em of the font of the block');
  # A leaf that does not exist, or is not shown: that ornament is not
  # drawn for the block; the others are.
  @bgerrors = ();
  $f->blockConfigure('Frac', -ornaments => [['line', [leaf => 5, 'nw'], [block => 'se'],
					      -fill => 'red', -width => 3]]);
  is($shot->()->data, $plain, 'leaf 5 of a block of 2: not drawn');
  $f->blockConfigure('Frac', -ornaments => [$bar, ['rectangle', [leaf => 0, 'nw'], [leaf => 0, 'se'],
						    -outline => 'blue']]);
  $hide = 1;
  $f->blockConfigure('Frac', -layoutdepth => 1);
  $ph = $shot->();
  is($px->($ph, $bb[0] + 1, $ybar), '217,217,217', 'the second leaf hidden: no bar');
  is($px->($ph, $l0[0], $l0[1]), '0,0,255', 'the box of the first leaf is drawn');
  $hide = 0;
  is(scalar(@bgerrors), 0, 'no background errors for leaves not there');
  # Under the text: the letters stay visible.
  $f->blockConfigure('Frac', -layoutdepth => 1, -ornaments => [
    ['rectangle', [block => 'nw'], [block => 'se'], -fill => 'yellow', -outline => undef,
     -layer => 'under']]);
  $ph = $shot->();
  my ($yellow, $other) = (0, 0);
  for my $x ($l0[0] .. $l0[0] + $l0[2] - 1) {
    for my $y ($l0[1] .. $l0[1] + $l0[3] - 1) {
      $px->($ph, $x, $y) eq '255,255,0' ? $yellow++ : $other++ } }
  ok($yellow > 10 && $other > 10, "under the text ($yellow yellow, $other letters)");
  # Without a layout callback (the default layout).
  $f->blockConfigure('Plain', -ornaments => [
    ['rectangle', [block => 'nw'], [offset => [block => 'se'], -1, -1], -outline => 'red']]);
  $f->insert('end', "xx yy\n");
  $f->blockInsert('Plain', '2.0', '2.2');
  $ph = $shot->();
  my @pb = $f->bbox('2.0');
  is($px->($ph, $pb[0], $pb[1]), '255,0,0', 'the default layout: the box of the block');
  is($px->($ph, $pb[0] + $pb[2] - 1, $pb[1] + $pb[3] - 1), '255,0,0', 'its other corner');
  # Errors: refused when configured, the old value kept.
  my $old = $f->blockCget('Plain', '-ornaments');
  for my $bad ([[['line', [at => '1.0'], [block => 'n']]], qr/the point "at" is not allowed in a block type's -ornaments/],
	       [[['line', [block => 'n'], [offset => [range => '1.0', '1.2'], 1, 1]]], qr/"range" is not allowed/],
	       [[['polygon', [outline => '1.0', '1.2']]], qr/"outline" is not allowed/],
	       [[['line', [leaf => -1], [block => 'n']]], qr/bad leaf number "-1"/],
	       [[['line', [leaf => 0, 'q'], [block => 'n']]], qr/bad anchor "q"/],
	       [[['circle', [block => 'n']]], qr/bad ornament type "circle"/],
	       [[['oval', [block => 'n']]], qr/wrong # points for an oval/],
	       [[['line', [block => 'n'], [block => 's'], -nosuch => 1]], qr/Bad option `-nosuch/],
	       [[['line', [block => 'n'], [block => 's']], ['line', [block => 'n']]],
		qr/wrong # points for a line.*\(ornament 1 of -ornaments\)/]) {
    eval { $f->blockConfigure('Plain', -ornaments => $bad->[0]) };
    like($@, $bad->[1], "refused: $bad->[1]");
  }
  is($f->blockCget('Plain', '-ornaments'), $old, 'the old value is kept');
  eval { $f->ornamentCreate('line', [leaf => 0], [at => '1.0']) };
  like($@, qr/the point "leaf" is allowed only in a block type's -ornaments/,
       'a leaf point is refused by ornament create');
  eval { $f->ornamentPoint([block => 'n']) };
  like($@, qr/the point "block" is allowed only/, 'and by ornament point');
  $f->blockConfigure('Plain', -ornaments => []);
  is_deeply(scalar($f->blockCget('Plain', '-ornaments')), [], 'an empty list: no templates');
  $f->destroy;
  is(scalar(@bgerrors), 0, 'no background errors') or diag(join "\n", @bgerrors);
  @bgerrors = ();
}

# Destroying a widget with ornaments.
my $d = $mw->eText->pack;
$d->insert('end', "abc\n");
$d->ornamentCreate('line', [at => '1.0'], [at => '1.2'], -dash => '2 2');
$mw->update;
$d->destroy;
$mw->update;
pass('a widget with ornaments is destroyed');
is(scalar(@bgerrors), 0, 'no background errors') or diag(join "\n", @bgerrors);

done_testing();
