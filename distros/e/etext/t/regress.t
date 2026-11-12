#!/usr/bin/perl
# Regression tests for defects found while reviewing the 2.00 port.
use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require Tk; 1 } or plan skip_all => "Tk not available: $@";
}
use Tk::eText;

my $mw = eval { MainWindow->new };
plan skip_all => "no X display available ($@)" unless $mw;
plan tests => 92;
$mw->geometry('+10+10');

# Collect background errors (Tk::Error) instead of printing them.
my @bgerrors;
{
  no warnings 'redefine';
  *Tk::Error = sub { my ($w, $err, @loc) = @_; push @bgerrors, $err };
}

my $t = $mw->eText(-width => 40, -height => 10)->pack;
$t->insert('end', "Hello world line\nSecond line here\nthird\n");
$mw->update;

# tag prevrange used to dereference a NULL pointer (segfault) whenever
# the tag's last toggle was not on the last line of its B-tree node.
$t->tagAdd('x', '2.0', '2.3');
is_deeply([$t->tagPrevrange('x', 'end')], ['2.0', '2.3'],
	  'tag prevrange finds a range on an earlier line');
is_deeply([$t->tagNextrange('x', '1.0')], ['2.0', '2.3'], 'tag nextrange');
is_deeply([$t->tagPrevrange('x', '2.0')], [], 'tag prevrange: nothing before');
$t->tagAdd('x', '1.6', '1.11');
is_deeply([$t->tagPrevrange('x', 'end')], ['2.0', '2.3'], 'tag prevrange: last range');
is_deeply([$t->tagPrevrange('x', '2.0')], ['1.6', '1.11'], 'tag prevrange: earlier range');
is_deeply([$t->tagRanges('x')], ['1.6', '1.11', '2.0', '2.3'], 'tag ranges');

# Case-insensitive search lower-cased the extracted line through a stale
# pointer (heap corruption) as soon as the line did not fit the initial
# buffer.
$t->delete('1.0', 'end');
$t->insert('end', "a\tb\tc\n" . ('x' x 200) . "\nLine three\n");
is($t->search('-nocase', 'LINE', '1.0'), '3.0', 'nocase search after a long line');
is($t->search('-nocase', 'line THREE', '1.0'), '3.0', 'nocase search, mixed case');
is($t->search('-nocase', '-regexp', 'l[i]ne', '1.0'), '3.0', 'nocase regexp search');
my $n = 0;
is($t->search('-nocase', '-count', \$n, 'XXX', '1.0'), '2.0', 'nocase search with -count');
is($n, 3, '-count variable set');
ok(!defined($t->search('-nocase', 'absent', '1.0')), 'nocase search: no match');

# window cget -align died ("Modification of a read-only value").
my $l = $t->Label(-text => 'w');
$t->windowCreate('3.4', -window => $l, -align => 'top');
is($t->windowCget('3.4', '-align'), 'top', 'window cget -align');
is(scalar(my @wc = $t->windowConfigure('3.4')), 6, 'window configure lists all options');
$t->windowConfigure('3.4', -align => 'center');
is($t->windowCget('3.4', '-align'), 'center', 'window -align center round-trips');

# The index of a window inside a block, by its name, was the position
# inside the block (an image's was right), and window cget and
# configure looked for the segment on the outer line only, so a window
# inside a block could not be addressed at all.
$t->blockConfigure('Std');
$t->blockInsert('Std', '3.2', '3.6');
is($t->index($l->PathName), '3.5', 'index by window name inside a block');
is($t->windowCget($l->PathName, '-align'), 'center', 'window cget inside a block by name');
$t->windowConfigure('3.5', -padx => 7);
is($t->windowCget('3.5', '-padx'), 7, 'window configure inside a block by index');

# tag bind query without a binding croaked with an empty message.
$t->tagConfigure('tg');
is_deeply([grep { defined } $t->tagBind('tg', '<Button-1>')], [],
	  'tag bind query without binding');
$t->tagBind('tg', '<Button-1>', sub { 1 });
ok(defined($t->tagBind('tg', '<Button-1>')), 'tag bind query with binding');

# dump read past the argument vector when the last argument started
# with '-'; dump -command twice leaked the first callback.
ok(!eval { $t->dump('-all'); 1 }, 'dump without index is an error');
like($@, qr/Usage/, 'dump without index: usage message');
ok(!eval { $t->dump('-command', sub {}, '-command', sub {}, '1.0'); 1 },
   'dump with two -command options is an error');

# A layout callback returning a single row (the whole block geometry,
# which is all an -empty block needs) was mis-parsed.
my $calls = 0;
$t->blockConfigure('E', -empty => 1,
		   -layoutcmd => sub { $calls++; return ([-1, 0, 0, 20, 20, 10, 8]) });
$t->blockInsert('E', '3.1');
$mw->update;
cmp_ok($calls, '>=', 1, 'single-row layout callback was called');
is_deeply(\@bgerrors, [], 'single-row layout callback result accepted')
  or diag(@bgerrors);

# tag prevrange around and inside blocks: compare with the answer
# computed from "tag ranges" (first character of the range before index1
# and not before index2, the closest such range).
{
  sub expected_prev {
    my ($w, $tag, $i1, $i2) = @_;
    my @r = $w->tagRanges($tag);
    my $best;
    while (@r) {
      my ($s, $e) = splice @r, 0, 2;
      next unless $w->compare($s, '<', $i1);
      next if defined $i2 && $w->compare($s, '<', $i2);
      $best = [$s, $e] if !$best || $w->compare($s, '>', $best->[0]);
    }
    return $best ? @$best : ();
  }
  my @cases = (
    ['inside a block',      "Hello world line\nSecond line\n", [['1.6', '1.11']], [['y', '1.8', '1.10']]],
    ['across block start',  "Hello world line\nSecond line\n", [['1.6', '1.11']], [['y', '1.2', '1.9']]],
    ['across block end',    "Hello world line\nSecond line\n", [['1.6', '1.11']], [['y', '1.9', '1.16']]],
    ['two blocks, nested',  "ab cdefg hi\nxx\n", [['1.3', '1.8'], ['1.5', '1.8']], [['y', '1.1', '1.7'], ['y', '2.0', '2.1']]],
    ['selection over all',  "ab cdefgh ij\nkl mnop qr\nst\n", [['1.3', '1.9'], ['2.3', '2.7']], [['y', '1.0', 'end']]],
  );
  for my $case (@cases) {
    my ($name, $content, $blocks, $tags) = @$case;
    my $w = $mw->eText(-width => 40, -height => 6)->pack;
    $w->blockConfigure('Std');
    $w->insert('end', $content);
    $w->blockInsert('Std', @$_) for @$blocks;
    $w->tagAdd(@$_) for @$tags;
    $mw->update;
    my @pos;
    my $lines = $w->index('end'); $lines =~ s/\..*//;
    for my $l (1 .. $lines) {
      (my $n = $w->index("$l.0 lineend")) =~ s/.*\.//;
      push @pos, "$l.$_" for 0 .. $n;
    }
    push @pos, 'end';
    my $bad = 0;
    for my $i1 (@pos) {
      for my $i2 (undef, @pos) {
	my @got = $w->tagPrevrange('y', $i1, (defined $i2 ? $i2 : ()));
	my @exp = expected_prev($w, 'y', $i1, $i2);
	$bad++ if "@got" ne "@exp";
      }
    }
    is($bad, 0, "tag prevrange, $name: all positions agree with tag ranges");
    $w->destroy;
  }
  # tag nextrange in the same layouts: the range closest to index1 whose
  # first character is at or after index1 and before index2.  It missed a
  # range starting at index1 inside a block (it looked for the on-toggle in
  # the outer line), and the B-tree search compared a stop position inside
  # a block with internal offsets.
  sub expected_next {
    my ($w, $tag, $i1, $i2) = @_;
    my @r = $w->tagRanges($tag);
    my $best;
    while (@r) {
      my ($s, $e) = splice @r, 0, 2;
      next if $w->compare($s, '<', $i1);
      next if defined $i2 && $w->compare($s, '>=', $i2);
      $best = [$s, $e] if !$best || $w->compare($s, '<', $best->[0]);
    }
    return $best ? @$best : ();
  }
  push @cases, ['ranges in and out', "ab cdefgh ij\nkl mnop qr\nst\n", [['1.3', '1.9'], ['2.3', '2.7']],
		[['y', '1.0', '1.2'], ['y', '1.5', '1.7'], ['y', '1.11', '2.5'], ['y', '3.0', '3.1']]];
  for my $case (@cases) {
    my ($name, $content, $blocks, $tags) = @$case;
    my $w = $mw->eText(-width => 40, -height => 6)->pack;
    $w->blockConfigure('Std');
    $w->insert('end', $content);
    $w->blockInsert('Std', @$_) for @$blocks;
    $w->tagAdd(@$_) for @$tags;
    $mw->update;
    my @pos;
    my $lines = $w->index('end'); $lines =~ s/\..*//;
    for my $l (1 .. $lines) {
      (my $n = $w->index("$l.0 lineend")) =~ s/.*\.//;
      push @pos, "$l.$_" for 0 .. $n;
    }
    push @pos, 'end';
    my $bad = 0;
    for my $i1 (@pos) {
      for my $i2 (undef, @pos) {
	my @got = $w->tagNextrange('y', $i1, (defined $i2 ? $i2 : ()));
	my @exp = expected_next($w, 'y', $i1, $i2);
	$bad++ if "@got" ne "@exp";
      }
    }
    is($bad, 0, "tag nextrange, $name: all positions agree with tag ranges");
    $w->destroy;
  }
  # A tag that changes the font inside a block: the display line must be
  # laid out again (TkTextRedrawTag used to hand internal indices to the
  # display-line search).
  {
    my $w = $mw->eText(-width => 40, -height => 6)->pack;
    $w->blockConfigure('Std');
    $w->insert('end', "ab cdefgh ij\n");
    $w->blockInsert('Std', '1.3', '1.9');
    $w->tagConfigure('big', -font => 'Helvetica 36');
    $mw->update;
    my $h0 = ($w->dlineinfo('1.0'))[3];
    $w->tagAdd('big', '1.5', '1.7');
    $mw->update;
    my $h1 = ($w->dlineinfo('1.0'))[3];
    $w->tagRemove('big', '1.0', 'end');
    $mw->update;
    my $h2 = ($w->dlineinfo('1.0'))[3];
    ok($h1 > $h0 && $h2 == $h0, "a font tag inside a block relays out the line ($h0 -> $h1 -> $h2)");
    $w->destroy;
  }
  # Tk's own text widget deviates from its documentation here (it returns
  # a range starting before index2); we follow the documentation.
  my $w = $mw->eText(-width => 40, -height => 6)->pack;
  $w->insert('end', "ab cd\nef\n");
  $w->tagAdd('y', '1.0', '2.1');
  is_deeply([$w->tagPrevrange('y', '2.0', '1.1')], [], 'range starting before index2 is not returned');
  $w->destroy;
}

# Deleting all of a block but its head, or all but its tail, deletes the
# block (as documented).  It also freed the block's last newline while
# the outer line still linked to it, and went on rebalancing from an
# internal line of the destroyed block: a crash, or heap corruption.
for my $case (['x ', '1.2', '1.4', '1.3', '1.9', 'all but the head'],
	      ['x ', '1.2', '1.4', '1.2', '1.8', 'all but the tail'],
	      ['', '1.0', '1.2', '1.1', '1.7', 'all but the head, block at the start of the line'],
	      ['', '1.0', '1.2', '1.0', '1.6', 'all but the tail, block at the start of the line']) {
  my ($prefix, $at, $inside, $i1, $i2, $what) = @$case;
  my $w = $mw->eText(-width => 40, -height => 6)->pack;
  $w->blockConfigure('Std');
  $w->insert('end', "${prefix}ab\ncd y\n");
  $w->blockInsert('Std', $at, '2.2');		# x {ab|cd} y
  $w->markSet('m', $inside);
  $w->delete($i1, $i2);
  $mw->update;
  is($w->get('1.0', 'end') . ' ' . $w->index('m'), "$prefix y\n\n $at", "deleting $what deletes the block");
  $w->insert($at, 'Z');
  $mw->update;
  is($w->get('1.0', 'end'), "${prefix}Z y\n\n", 'and the line is still usable');
  $w->destroy;
}

# The editXxx spellings reach the edit subcommand (once a stub that croaked).
ok($t->editModified, 'editModified reports the changes made so far');
$t->editModified(0);
is($t->editModified, 0, 'editModified(0) clears the flag');

# Scrolling copies the lines still visible and redraws the rest
# (TkScrollWindow, as in Tk 8.4).  The tk4.0 code waited for
# GraphicsExpose/NoExpose with XWindowEvent, an empty stub on Win32.
# Compare the pixels of a widget scrolled twice with those of one drawn
# from scratch at the same place.
SKIP: {
  skip 'no Tk::WinPhoto to capture the window', 4
    unless eval { require Tk::WinPhoto; 1 };
  my $text = join '', map { "line $_ " . ('x' x ($_ % 17)) . "\n" } 1..60;
  my @w = map { $mw->eText(-width => 30, -height => 8, -bd => 2, -padx => 3,
			   -pady => 1, -highlightthickness => 0)->pack } 1..2;
  $w[0]->insert('end', $text);
  $mw->update;
  $w[0]->yviewScroll(3, 'units');	# copies most lines up
  $mw->update;
  $w[0]->yviewScroll(-1, 'units');	# and down
  $mw->update;
  $w[1]->insert('end', $text);		# never displayed elsewhere:
  $w[1]->yview(2);			# no copy (line 0-based here)
  $mw->update;
  is($w[0]->index('@0,0'), '3.0', 'scrolled by one unit, three, back one');
  is($w[1]->index('@0,0'), '3.0', 'the reference shows the same line first');
  my ($d0, $d1) = map { $mw->Photo(-format => 'Window', -data => oct($_->id))->data } @w;
  ok(length($d0) > 1000, 'the window could be captured');
  ok($d0 eq $d1, 'the scrolled pixels equal those drawn from scratch');
  $_->destroy for @w;
}

# A wrong block subcommand: the error lists every valid one.
ok(!eval { $t->block('nosuch'); 1 }, 'a wrong block subcommand is an error');
like($@, qr/^bad block option "nosuch":  must be at, addline, cget, configure, data, delete, deletelines, flatten, insert, list, names, nodedata, of, split, sprout or trim/,
     'which lists all the subcommands, data included');

# After an undo, the next edit starts an undo step of its own: a second
# deletion used to join the step of the insertion before the first one,
# and its undo then took the insertion back as well.
{
  my $u = $mw->eText(-undo => 1)->pack;
  $u->insert('end', "one two three\n");
  $u->editSeparator;
  $u->delete('1.0', '1.4'); $u->editUndo;
  $u->delete('1.4', '1.8'); $u->editUndo;
  is($u->get('1.0', 'end'), "one two three\n\n", 'delete, undo, delete, undo restores the text');
  $u->delete('1.0', '1.4'); $u->editUndo; $u->editRedo;
  $u->delete('1.0', '1.4'); $u->editUndo;
  is($u->get('1.0', 'end'), "two three\n\n", 'and a deletion after a redo is a step of its own');
  $u->destroy;
}

# A backward tag search in a block with two levels of nodes under its
# root (tag prevrange, the run of a value, the undo of a block split)
# walked off a list of nodes in FindTagEnd: a segfault.
{
  my $u = $mw->eText->pack;
  $u->blockConfigure('F');
  $u->insert('end', "ab\ncd\nef\n");
  $u->blockInsert('F', '1.0', '3.2');
  $u->blockSplit('1.4', 1);
  $u->blockSplit('1.4', 2);
  $u->tagAdd('c', '1.9', '1.10');
  is(join(' ', $u->tagPrevrange('c', 'end')), '1.9 1.10',
     'tag prevrange in a block with nested nodes');
  $u->tagAdd('c', '1.1', '1.2');
  is(join(' ', $u->tagPrevrange('c', '1.9')), '1.1 1.2', 'from inside the block too');
  $u->tagData('c', '1.9', 'v');
  is($u->tagData('c', '1.9'), 'v', 'and the run of a value there');
  $u->destroy;
}

# block list of a block whose only leaf is empty left out what is in
# that leaf (marks, tag toggles), and the undo of a deletion, which
# re-creates the text from that list, did not put them back.
{
  my $u = $mw->eText(-undo => 1)->pack;
  $u->blockConfigure('F');
  $u->insert('end', "ab\ncd\n");
  $u->blockInsert('F', '1.1');
  $u->markSet('m', '1.2');
  $u->markGravity('m', 'left');
  $u->tagAdd('c', '1.0', '1.2');
  my ($b) = grep { ref $_ eq 'Tk::Text::Block' } $u->blockList('1.0', 'end');
  is(join(' ', map { ref($_) =~ /Mark|Tag/ ? ref($_) . "($$_)" : ref $_ } @$b[1 .. $#$b]),
     'Tk::Text::MarkLeft(m) Tk::Text::TagOff(c)', 'the empty leaf of a block is listed');
  $u->editReset;
  $u->delete('1.0', '2.0');
  $u->editUndo;
  is($u->index('m'), '1.2', 'the undo of a deletion puts the mark in it back');
  is(join(' ', $u->tagRanges('c')), '1.0 1.2', 'and the end of the tag');
  $u->destroy;
}

# A block insert over several lines moves the lines after the first
# into the block: if the first line on display was one of them, the
# next redisplay crashed (the view now goes to the first line).  The
# undo and redo of block changes show the insert mark (see), so they
# reached it too.
{
  my $u = $mw->eText(-undo => 1, -autoseparators => 0)->pack;
  $u->blockConfigure($_) for qw(F G);
  $u->insert('1.0', "ab\ncdef\n");
  $u->blockInsert('F', '2.2', '2.4');
  $u->see('2.3');
  $u->blockInsert('G', '1.1', '2.0');
  $mw->update;
  is($u->get('1.0', '1.end'), 'a{b|}cd{ef}', 'redisplay after block insert over the first line shown');
  $u->delete('1.0', 'end');
  $u->insert('1.0', "abcdef\nghijkl\nmnopqr\nstu\n");
  $u->blockInsert('F', '1.4', '1.6');
  $u->editReset;
  $u->blockSplit('1.2', 1); $u->editSeparator;
  $u->insert('2.3', "x\ny", 'c'); $u->editSeparator;
  $u->blockInsert('G', '1.1', '2.0'); $u->editSeparator;
  $mw->update;
  $u->editUndo for 1 .. 2;
  $mw->update;
  $u->editRedo for 1 .. 2;
  $mw->update;
  is($u->get('1.0', '1.end'), 'a{b|}cd{x|yef}', 'undo and redo of it, with redisplays');
  $u->destroy;
}

# Tag searches in a block whose tree has inner nodes: a node of the
# block skipped for having no toggle of the tag was not checked for the
# end of the search, which went on past it (tag remove removed the tag
# far beyond the range, the undo of tag add lost the ranges before).
# Every tag remove range against a model, and tag nextrange/prevrange.
{
  my $u = $mw->eText->pack;
  $u->blockConfigure('F');
  $u->insert('1.0', "abc\ndef\nghi\n");
  $u->blockInsert('F', '1.0', '3.3');
  $u->blockSplit('1.4', 1);			# {abc||def|ghi}: two nodes
  my $n = length $u->get('1.0', '1.end');
  my $model = sub {
    my @on = @_; my @r;
    for my $i (0 .. $n - 1) {
      if ($on[$i] && !($i && $on[$i - 1])) { push @r, "1.$i" }
      if ($on[$i] && ($i == $n - 1 || !$on[$i + 1])) { push @r, '1.' . ($i + 1) }
    }
    join ' ', @r;
  };
  my ($bad, $badn, $badp, $badv) = (0, 0, 0, 0);
  for my $add ([1, $n - 1], [2, 9], [6, 13]) {
    for my $a (0 .. $n - 1) {
      for my $b ($a + 1 .. $n) {
	$u->tagRemove($_, '1.0', 'end') for qw(b v);
	$u->tagAdd($_, "1.$add->[0]", "1.$add->[1]") for qw(b v);
	$u->tagData('v', "1.$add->[0]", 'val');		# runs with values
	$u->tagRemove($_, "1.$a", "1.$b") for qw(b v);
	$badv++ if join(' ', $u->tagRanges('v')) ne join(' ', $u->tagRanges('b'));
	my @on = map { $_ >= $add->[0] && $_ < $add->[1] && !($_ >= $a && $_ < $b) } 0 .. $n - 1;
	my $want = $model->(@on);
	if (join(' ', $u->tagRanges('b')) ne $want) {
	  diag("add @$add, remove $a $b: got " . join(' ', $u->tagRanges('b')) . ", want $want") unless $bad++;
	}
	my ($first) = grep { $on[$_] && !($_ && $on[$_ - 1]) && $_ >= $a } 0 .. $n - 1;
	my @nr = $u->tagNextrange('b', "1.$a", "1.$b");
	$badn++ if (defined $first && $first < $b) ? !@nr || $nr[0] ne "1.$first" : scalar @nr;
	my ($last) = reverse grep { $on[$_] && !($_ && $on[$_ - 1]) && $_ < $b } 0 .. $n - 1;
	my @pr = $u->tagPrevrange('b', "1.$b", "1.$a");
	my $endlast = defined $last ? (grep { $_ > $last && !$on[$_] } $last .. $n - 1)[0] // $n : undef;
	$badp++ if (defined $last && $endlast > $a) ? !@pr || $pr[0] ne "1.$last" : scalar @pr;
      }
    }
  }
  is($bad, 0, 'tag remove in a block with inner nodes removes the range only');
  is($badn, 0, 'tag nextrange stops at its end there');
  is($badp, 0, 'tag prevrange too');
  is($badv, 0, 'the same for a tag with run values');

  # Searches starting inside a tagged range (the loop above emptied the
  # range searched first): nextrange gives the first range starting at
  # or after the start, prevrange the last starting before the end and
  # not before the start (as in Tk).
  my ($badin, $cases) = (0, 0);
  for my $add ([[1, 4], [6, 9], [11, 13]], [[2, 12]], [[0, 5], [8, 14]]) {
    $u->tagRemove('b', '1.0', 'end');
    $u->tagAdd('b', map { ("1.$_->[0]", "1.$_->[1]") } @$add);
    my @r = map { [$_->[0], $_->[1]] } @$add;
    for my $a (0 .. $n - 1) {
      for my $b ($a + 1 .. $n) {
	my ($nx) = grep { $_->[0] >= $a && $_->[0] < $b } @r;
	my @want = $nx ? ("1.$nx->[0]", "1.$nx->[1]") : ();
	my @got = $u->tagNextrange('b', "1.$a", "1.$b");
	$badin++, diag("nextrange 1.$a 1.$b: @got, want @want") if "@got" ne "@want" && !$badin;
	my ($pv) = reverse grep { $_->[0] < $b && $_->[0] >= $a } @r;
	@want = $pv ? ("1.$pv->[0]", "1.$pv->[1]") : ();
	@got = $u->tagPrevrange('b', "1.$b", "1.$a");
	$badin++, diag("prevrange 1.$b 1.$a: @got, want @want") if "@got" ne "@want" && !$badin;
	$cases++;
      }
    }
  }
  is($badin, 0, "tag nextrange/prevrange from inside ranges in such a block ($cases cases)");
  $u->destroy;
}

# Block insert over lines in different nodes of the text's tree (more
# than a dozen lines): the lines after the last one were linked into
# the first one's node, the counts went to the wrong nodes, and the
# node of the last line was not rebalanced (the B-tree check, debug 1,
# aborted).  Each range here crosses nodes; undo and redo too.
{
  my $u = $mw->eText(-undo => 1)->pack;
  $u->blockConfigure('G');
  $u->debug(1);
  my $text = join('', map { "l$_\n" } 1 .. 60);
  my $ok = 0;
  for my $r (['12.1', '13.0'], ['12.1', '20.0'], ['42.0', '61.0'], ['5.1', '50.1'], ['2.0', '59.0']) {
    $u->delete('1.0', 'end');
    $u->insert('1.0', $text);
    $u->tagAdd('b', '3.0', '45.1');
    $u->editReset;
    my $before = $u->get('1.0', 'end');
    $u->blockInsert('G', @$r);
    $u->see('end'); $mw->update;
    $u->editUndo;
    $ok++ if $u->get('1.0', 'end') eq $before;
    $u->editRedo;
    $u->see('1.0'); $mw->update;
  }
  is($ok, 5, 'block insert over lines of several nodes, with the B-tree check');
  # The node of the last line emptied and freed: its parent was not
  # rebalanced (bad child count).
  $u->delete('1.0', 'end');
  $u->insert('1.0', join('', map { "l$_\n" } 1 .. 100));
  $u->blockInsert('G', '36.0', '66.0');
  $u->blockInsert('G', '2.3', '30.1');
  $mw->update;
  $u->editUndo; $u->editUndo; $u->editRedo; $u->editRedo;
  is($u->index('end'), '44.0', 'block insert emptying the node of its last line');
  $u->destroy;
}

# The same fault reached through the undo of a deletion inside a block
# (the review's fuzzer, crash-823: "TkBTreeStartSearch got index in
# internal BTree", an abort): a redisplay after each change.
{
  my $u = $mw->eText(-undo => 1, -autoseparators => 0, -width => 40, -height => 8)->pack;
  $u->blockConfigure($_) for qw(F G);
  $u->debug(1);
  my $step = sub { $_[0]->(); $u->editSeparator; $mw->update };
  $step->(sub { $u->insert('1.0', "abcdef\nghijkl\nmnopqr\nstu\n") });
  $step->(sub { $u->blockSplit('4.1', 0) });
  $step->(sub { $u->blockInsert('G', '1.6', '7.0') });
  $u->editReset;
  $step->(sub { $u->blockSplit('1.24', 1) });
  $step->(sub { $u->insert('1.0', "x\ny") });
  $step->(sub { $u->tagAdd('b', '1.1', '2.27') });
  $step->(sub { $u->blockSplit('2.28', 0) });
  $step->(sub { $u->insert('2.21', "\n") });
  $step->(sub { $u->insert('1.1', 'ab', 'c') });
  $step->(sub { $u->insert('1.3', "rs\n", 'b') });
  $step->(sub { $u->delete('2.2', '3.20') });
  $step->(sub { $u->editUndo });
  $step->(sub { $u->blockInsert('F', '1.1', '3.4') });
  my $before = $u->get('1.0', 'end');
  $step->(sub { $u->delete('1.25', '1.40') });
  $step->(sub { $u->editUndo });
  is($u->get('1.0', 'end'), $before, 'undo of a deletion in a block after a block insert over lines');
  $u->destroy;
}

# And crash831 ("SplitSeg reached end of line!", an abort): a separator
# deleted and made again, then two block inserts, no undo.
{
  my $u = $mw->eText(-undo => 0, -width => 40, -height => 8)->pack;
  $u->blockConfigure($_) for qw(F G);
  $u->debug(1);
  $u->insert('1.0', "abcdef\nghijkl\nmnopqr\nstu\n");
  $u->blockSplit('2.5', 2); $u->blockSplit('2.2', 2);
  $u->blockInsert('F', '6.0', '7.0'); $u->blockSplit('6.3', 0); $u->blockInsert('F', '1.5', '5.1');
  $mw->update;
  $u->blockSplit('2.6', 1); $mw->update;
  $u->delete('2.6'); $mw->update;
  $u->blockSplit('2.6', 1); $mw->update;
  $u->markSet('insert', '2.7'); $u->see('insert'); $mw->update;
  $u->blockInsert('G', '1.2', '2.8'); $mw->update;
  $u->blockInsert('F', '1.22', '1.26'); $mw->update;
  is($u->get('1.0', '1.end'), 'ab{cde{f|gh|ijk|l|m}no{pqr|}{st|u||}}', 'block inserts after a separator deleted and made again');
  $u->destroy;
}

# tag names at the head of a block left out a tag that switches off
# inside the block, although tag ranges covers the head (BUGS 20).  At
# every position, tag names must agree with tag ranges, for ranges that
# start before, at or inside a block and end inside or after it.
{
  my $w = $mw->eText(-width => 40, -height => 6)->pack;
  $w->blockConfigure('Std');
  $w->blockConfigure('E', -empty => 1);
  my @ranges = (['1.0', '1.6'], ['1.1', '1.6'], ['1.3', '1.6'], ['1.4', '1.6'],
		['1.5', '1.12'], ['1.0', '1.12'], ['1.3', '1.11'], ['1.3', '1.10'],
		['1.6', '2.5'], ['1.2', '1.4'], ['1.7', '1.8'], ['1.0', '3.1'],
		['2.0', '2.6'], ['1.11', '2.4']);
  my ($bad, $badheads, $heads) = (0, 0, 0);
  my %heads = map { $_ => 1 } qw(1.3 1.6 2.2 2.5);	# the -empty block too
  for my $r (@ranges) {
    $w->delete('1.0', 'end');
    $w->tagRemove('y', '1.0', 'end');
    $w->insert('end', "ab cdefgh ij\nkl mnop qr\nst\n");
    $w->blockInsert('Std', '1.3', '1.9');	# ab {cdefgh} ij
    $w->blockInsert('Std', '1.6', '1.8');	# ab {cd{ef}gh} ij
    $w->blockInsert('E', '2.4');		# kl m.nop qr
    $w->blockInsert('Std', '2.2', '2.6');	# kl{ m.n}op qr
    is($w->get('1.0', '2.end'), "ab {cd{ef}gh} ij\nkl{ m.n}op qr", 'blocks') if $r == $ranges[0];
    $w->tagAdd('y', @$r);
    my @r = $w->tagRanges('y');
    my $lines = $w->index('end'); $lines =~ s/\..*//;
    for my $l (1 .. $lines - 1) {
      (my $n = $w->index("$l.0 lineend")) =~ s/.*\.//;
      for my $i (map { "$l.$_" } 0 .. $n) {
	my $in = 0;
	for (my $k = 0; $k < @r; $k += 2) {
	  $in ||= $w->compare($i, '>=', $r[$k]) && $w->compare($i, '<', $r[$k + 1]);
	}
	my $named = grep { $_ eq 'y' } $w->tagNames($i);
	my $head = $heads{$i};
	$heads++ if $head;
	next if !$named == !$in;
	$bad++;
	$badheads++ if $head;
	diag("y on @$r: tag names $i says " . ($named ? 'on' : 'off'));
      }
    }
  }
  ok($heads > 0, "block heads among the positions checked ($heads)");
  is($badheads, 0, 'tag names agrees with tag ranges at the heads of blocks');
  is($bad, 0, 'and at every other position');
  $w->destroy;
}

# An -empty block whose line changed (a newline or a block split before
# it) did not know its new line, nor one nested in a block when the
# block insert moved it there: "block at" on its head crashed, and the
# B-tree check now looks for it (BUGS 25).
{
  my $w = $mw->eText;
  $w->debug(1);
  $w->blockConfigure('E', -empty => 1);
  $w->blockConfigure('F');
  $w->insert('end', "abcde\n");
  $w->blockInsert('E', '1.2');
  $w->blockInsert('F', '1.1', '1.4');		# a{b.c}de: E nested in F
  is(($w->blockAt('1.3'))[2], 'E', 'block at on an -empty block nested in a block');
  ok(eval { $w->insert('1.1', "x\n"); 1 }, 'a newline before it') or diag $@;
  is(($w->blockAt('2.2'))[2], 'E', 'block at, after');
  ok(eval { $w->blockSplit('2.1', 0); 1 }, 'a split before it') or diag $@;
  $w->destroy;
}

# The bounding box of a position inside a leaf of a block, once the
# block had been drawn, was off by the top of the block in the window:
# the display keeps the internal lines of a drawn block in window
# coordinates, the bbox took them as relative to the block (BUGS 32).
{
  my $w = $mw->eText(-font => '10x20', -borderwidth => 0,
		     -highlightthickness => 0, -pady => 20);
  $w->pack;
  $w->blockConfigure('P', -layoutcmd => sub {
    my ($data, $x, $leaf) = @_;
    ([-1, 0, 0, 50, 50, 60, 40], [1, 5, 30, @$leaf[2, 2, 4, 5]]);
  });
  $w->insert('1.0', "a\n");
  $w->blockInsert('P', '1.1');
  $w->insert('1.2', 'x');
  $w->update;
  my @head = $w->bbox('1.1');
  is(($w->bbox('1.2'))[1] - $head[1], 30, 'bbox: the leaf is where the layout callback put it');
  is(($w->bbox('1.3'))[1] - $head[1], 30, 'and the tail (the leaf as a whole)');
  $w->destroy;
}

# The tail of a block that ends a display line (the text after it
# wrapped) had the box of a last character of a display line, up to the
# right edge of the window, not its last leaf's (BUGS 33).
{
  my $w = $mw->eText(-font => '10x20', -width => 5, -wrap => 'char',
		     -borderwidth => 0, -highlightthickness => 0, -padx => 0);
  $w->pack;
  $w->blockConfigure('P', -layoutcmd => sub {
    my ($data, $x, $leaf) = @_;
    ([-1, 0, 0, 50, 50, 22, 17], [1, 5, 0, @$leaf[2, 2, 4, 5]]);
  });
  $w->insert('1.0', "dddddd");
  $w->blockInsert('P', '1.0');
  $w->insert('1.1', 'nk');		# {nk}dddddd: the d's wrap
  $w->update;
  my @leaf = ($w->bbox('1.1'))[0, 1];
  push @leaf, ($w->bbox('1.2'))[0] + ($w->bbox('1.2'))[2] - $leaf[0], ($w->bbox('1.2'))[3];
  is_deeply([$w->bbox('1.3')], \@leaf, 'bbox: the tail of a block at the end of a display line is its leaf');
  $w->destroy;
}

# A position from the mouse beyond the end of a display line that ends
# with a multi-byte character (wrapped) was inside the character
# (DLinePixelIndex counted back one byte): a mark set there, and the
# mark "current" whenever the pointer was there at a redisplay, split
# the character, and the text got NUL bytes (BUGS 34).
{
  my $w = $mw->eText(-font => '10x20', -width => 8, -wrap => 'char');
  $w->pack;
  my $s = "\x{221e}" x 30;
  $w->insert('1.0', $s);
  $w->update;
  my @warn;
  local $SIG{__WARN__} = sub { push @warn, @_ };
  my $i = $w->index('@500,5');
  $w->markSet('m', '@500,5');
  $w->update;
  is($w->get('1.0', '1.end'), $s, 'a mark set beyond a wrapped line of multi-byte characters leaves the text');
  is($w->index('m'), $i, 'it is at the last character of the display line');
  is_deeply(\@warn, [], 'no malformed UTF-8');
  $w->destroy;
}

# "mark next" skipped a mark at the very start of the first leaf line of
# a block (it went into the block's tree and stepped past the first
# segment there), and "mark previous" searched only the first leaf line
# of a block before the index and none of the line after the block
# (BUGS 35).  Both must agree with the order of "dump".
{
  my $w = $mw->eText;
  $w->blockConfigure('B');
  $w->insert('1.0', "line 1 abc\n");
  $w->blockInsert('B', '1.2', '1.6');
  $w->markSet(m => '1.3');
  is($w->markNext('1.0'), 'm', 'mark next finds a mark at the start of a leaf');
  is($w->markPrevious('insert'), 'm', 'mark previous finds it from after the block');
  $w->delete('1.0', 'end');
  $w->insert('1.0', "line 1 abc defg\nxy\n");
  $w->blockInsert('B', '1.2', '1.12');
  $w->insert('1.6', "\n");			# two leaves
  $w->blockInsert('B', '1.8', '1.10');		# a nested block
  my @idx;
  for (my $i = '1.0'; ; $i = $w->index("$i+1c")) {
    push @idx, $i;
    last if $w->compare($i, '>=', 'end');
  }
  $w->markSet("n$_", $idx[$_]) for 0 .. $#idx;
  my @d = $w->dump('-mark', '1.0', 'end');
  my @all = map { [$d[3*$_ + 1], $d[3*$_ + 2]] } 0 .. @d/3 - 1;
  my @bad;
  for my $k (0 .. $#all) {
    my $name = $all[$k][0];
    my $next = $k < $#all ? $all[$k + 1][0] : '';
    my $prev = $k > 0 ? $all[$k - 1][0] : '';
    push @bad, "next $name" if ($w->markNext($name) // '') ne $next;
    push @bad, "previous $name" if ($w->markPrevious($name) // '') ne $prev;
  }
  is("@bad", '', 'mark next and previous of each mark follow dump');
  @bad = ();
  for my $i (@idx) {
    my ($next) = map { $_->[0] } grep { $w->compare($_->[1], '>=', $i) } @all;
    my @before = grep { $w->compare($_->[1], '<', $i) } @all;
    push @bad, "next $i" if ($w->markNext($i) // '') ne ($next // '');
    push @bad, "previous $i"
	if ($w->markPrevious($i) // '') ne (@before ? $before[-1][0] : '');
  }
  is("@bad", '', 'mark next and previous of each index follow dump');
  is(scalar(grep { $_->[0] =~ /^n/ } @all), scalar(@idx), 'every mark is in dump');
  $w->destroy;
}

$t->destroy;
$mw->destroy;
