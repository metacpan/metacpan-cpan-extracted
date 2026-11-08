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
plan tests => 48;
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

$t->destroy;
$mw->destroy;
