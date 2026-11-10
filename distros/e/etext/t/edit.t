#!/usr/bin/perl
# The edit subcommand: undo, redo, separators, the modified flag.
use strict;
use warnings;
use utf8;
use Test::More;

BEGIN {
  eval { require Tk; 1 } or plan skip_all => "Tk not available: $@";
}
use Tk::eText;
use Data::Dumper;
$Data::Dumper::Indent = 0; $Data::Dumper::Terse = 1;

my $mw = eval { MainWindow->new };
plan skip_all => "no X display available ($@)" unless $mw;
plan tests => 144;
$mw->geometry('+10+10');
binmode(Test::More->builder->$_, ':utf8') for qw(output failure_output);

my @bgerrors;
{
  no warnings 'redefine';
  *Tk::Error = sub { my ($w, $err, @loc) = @_; push @bgerrors, $err };
}

my $t = $mw->eText(-width => 30, -height => 8, -undo => 1)->pack;
my $modified = 0;
$t->bind('<<Modified>>', sub { $modified++ });
$mw->update;
is($t->cget('-undo'), 1, '-undo option');
is($t->cget('-maxundo'), 0, '-maxundo default');
is($t->cget('-autoseparators'), 1, '-autoseparators default');
is($t->editModified, 0, 'not modified at first');

# One insertion, undone and redone.
$t->insert('end', 'hello');
is($t->get('1.0', 'end'), "hello\n", 'inserted');
is($t->editModified, 1, 'modified after an insertion');
is($modified, 1, '<<Modified>> fired once');
$t->editUndo;
is($t->get('1.0', 'end'), "\n", 'undo removes the insertion');
is($t->editModified, 0, 'not modified after undoing everything');
is($modified, 2, '<<Modified>> fired again on the way back');
ok(!eval { $t->editUndo; 1 }, 'nothing more to undo');
like($@, qr/nothing to undo/, 'the error message says so');
$t->editRedo;
is($t->get('1.0', 'end'), "hello\n", 'redo puts it back');
ok(!eval { $t->editRedo; 1 }, 'nothing more to redo');
is($t->index('insert'), '1.5', 'the insertion cursor follows the redone text');
$t->editUndo;
is($t->index('insert'), '1.0', 'and goes back to the start when undone');

# Automatic separators: insertions group, a deletion starts a new group.
$t->editReset;
$t->insert('end', $_) for qw(a b c);
$t->insert('end', 'x');
$t->delete('1.0');
is($t->get('1.0', 'end'), "bcx\n", 'text before undo');
$t->editUndo;
is($t->get('1.0', 'end'), "abcx\n", 'undo reverts the deletion only');
$t->editUndo;
is($t->get('1.0', 'end'), "\n", 'the next undo reverts all four insertions at once');
ok(!eval { $t->editUndo; 1 }, 'stack empty');

# Explicit separators.
$t->editReset;
$t->insert('end', 'a');
$t->editSeparator;
$t->insert('end', 'b');
$t->editUndo;
is($t->get('1.0', 'end'), "a\n", 'edit separator splits insertions');
$t->editUndo;
is($t->get('1.0', 'end'), "\n", 'and the earlier group is undone next');

# No automatic separators.
$t->configure(-autoseparators => 0);
$t->editReset;
$t->insert('end', 'ab');
$t->delete('1.0');
$t->editUndo;
is($t->get('1.0', 'end'), "\n", 'without autoseparators an insertion and a deletion are one group');
$t->configure(-autoseparators => 1);

# -maxundo.
$t->editReset;
$t->configure(-maxundo => 2);
for my $c (qw(a b c)) { $t->insert('end', $c); $t->editSeparator }
$t->editUndo;
$t->editUndo;
is($t->get('1.0', 'end'), "a\n", 'two groups undone');
ok(!eval { $t->editUndo; 1 }, '-maxundo 2 kept only two groups');
$t->configure(-maxundo => 0);

# edit reset, edit modified.
$t->delete('1.0', 'end');
$t->insert('end', 'text');
$t->editReset;
ok(!eval { $t->editUndo; 1 }, 'edit reset empties the stack');
$t->editModified(0);
is($t->editModified, 0, 'edit modified 0');
my $before = $modified;
$t->insert('end', 'more');
is($t->editModified, 1, 'modified again after a change');
is($modified, $before + 1, '<<Modified>> for the change');
$t->editModified(1);
$t->delete('1.0', 'end');
is($t->editModified, 1, 'an explicitly set flag stays set');

# Several lines, blocks and multi-byte characters.
$t->editModified(0);
$t->editReset;
$t->delete('1.0', 'end');
$t->insert('end', "l1 \x{e9}\x{20ac}\nl2\nl3\n");
$t->editSeparator;
$t->delete('1.2', '3.1');
is($t->get('1.0', 'end'), "l13\n\n", 'multi-line deletion');
$t->editUndo;
is($t->get('1.0', 'end'), "l1 \x{e9}\x{20ac}\nl2\nl3\n\n", 'multi-line deletion undone, characters intact');
$t->blockConfigure('Std');
$t->blockInsert('Std', '1.3', '1.5');
$t->editSeparator;
is($t->get('1.0', '1.end'), "l1 {\x{e9}\x{20ac}}", 'a block');
$t->delete('1.0', '1.end');
$t->editUndo;
is($t->get('1.0', '1.end'), "l1 {\x{e9}\x{20ac}}", 'undo brings the deleted text back');
ok(defined($t->blockAt('1.3')), 'and the block with it');

# 8. Undo re-creates blocks (with their structure and instance data),
# tags and marks, from what "block list" reports.
$t->configure(-maxundo => 0);
$t->editReset;
$t->delete('1.0', 'end');
$t->blockConfigure('Frac', -layoutdepth => 1, -layoutwidths => [2],
		   -layoutcmd => sub {
		     my ($data, $x, $super, $sub) = @_;
		     my $w = $super->[2] > $sub->[2] ? $super->[2] : $sub->[2];
		     my $h = $super->[4] + 2 + $sub->[4];
		     return ([-1, 0, 0, $w, $w, $h, $super->[4] + 1],
			     [$super->[0], 0, 0, $super->[2], $super->[2], $super->[4], $super->[5]],
			     [$sub->[0], 0, $super->[4] + 2, $sub->[2], $sub->[2], $sub->[4], $sub->[5]]);
		   });
$t->insert('end', "x = num\nden + 1\n");
$t->blockInsert('Frac', '1.4', '2.3');		# x = {num|den} + 1
$t->tagConfigure('b', -foreground => 'blue');
$t->tagAdd('b', '1.6', '1.9');			# "um|d", across the leaves
$t->markSet('mk', '1.7');
$t->markGravity('mk', 'left');
$t->markSet('mr', '1.8');				# right gravity
$t->blockData('1.6', 'payload');
$mw->update;
my $doc = $t->get('1.0', 'end');
my @of = $t->blockOf('1.6');
my @dump = grep { $_ ne 'current' } $t->dump('-all', '1.0', 'end');
is($doc, "x = {num|den} + 1\n\n", 'a fraction with a tag and a mark inside');
$t->editSeparator;
$t->delete('1.0', 'end');
is($t->get('1.0', 'end'), "\n", 'deleted');
$t->editUndo;
$mw->update;
is($t->get('1.0', 'end'), $doc, 'undo brings the text back');
is_deeply([$t->blockOf('1.6')], \@of, 'with the block: its type, length, instance data and leaves');
is_deeply([$t->tagRanges('b')], ['1.6', '1.9'], 'with the tag inside the block');
is(join(' ', $t->index('mk'), $t->markGravity('mk'), $t->index('mr'), $t->markGravity('mr')), '1.7 left 1.8 right',
   'with the marks and their gravity (a right-gravity mark used to drift to the end)');
is_deeply([grep { $_ ne 'current' } $t->dump('-all', '1.0', 'end')], \@dump, 'dump -all is identical');
$t->editRedo;
is($t->get('1.0', 'end'), "\n", 'redo deletes it again');
$t->editUndo;
$mw->update;
is_deeply([$t->get('1.0', 'end'), $t->blockOf('1.6')], [$doc, @of], 'and undo brings it back again');
# Text deleted inside a block: the block stays, the text comes back.
$t->editSeparator;
$t->delete('1.6', '1.8');
$t->editUndo;
$mw->update;
is_deeply([$t->get('1.0', 'end'), $t->blockOf('1.6')], [$doc, @of], 'a deletion inside a block undone');
# A deletion that cuts a block: the widget dissolves the block (its
# remaining leaves become lines).  Undo takes those remains out and
# re-creates the block from the record of the smallest range around the
# deletion that cuts no block.
$t->editSeparator;
$t->delete('1.2', '1.7');
is($t->get('1.0', 'end'), "x m\nden + 1\n\n", 'a deletion cutting a block dissolves it');
$t->editUndo;
$mw->update;
is_deeply([$t->get('1.0', 'end'), $t->blockOf('1.6'), $t->tagRanges('b'), $t->index('mk')],
	  [$doc, @of, '1.6', '1.9', '1.7'], 'undone: the block is back, with its tag and mark');
is_deeply(\@bgerrors, [], 'no background errors') or diag(@bgerrors);
# An empty block.
$t->delete('1.0', 'end');
$t->blockConfigure('E', -empty => 1, -layoutcmd => sub { return ([-1, 0, 0, 20, 20, 10, 8]) });
$t->insert('end', "ab\n");
$t->blockInsert('E', '1.1');
$t->blockData('1.1', 'e-data');
$mw->update;
$t->editSeparator;
$t->delete('1.0', '1.end');
$t->editUndo;
$mw->update;
my @at = $t->blockAt('1.1');
is("$at[2] $at[3]", 'E e-data', 'an empty block with its data comes back');

# 9. Deletions that cut blocks, in a dozen layouts.  The widget dissolves
# a cut block (the documented behaviour); undo takes what the
# dissolution left out again and re-creates everything from the record
# of the smallest range around the deletion that cuts no block.  The
# text, "dump -all" and the block list must come back identical; redo
# must delete the same way again.
use Data::Dumper; $Data::Dumper::Indent = 0; $Data::Dumper::Sortkeys = 1;
sub snapshot {
  $t->markSet('insert', 'end');		# undo and redo move it
  my @d = $t->dump('-all', '1.0', 'end');
  my @k;
  while (@d) { my @e = splice @d, 0, 3; push @k, @e unless $e[0] eq 'mark' && $e[1] =~ /^(insert|current)$/ }
  return join("\n", $t->get('1.0', 'end'), "@k", Dumper([$t->blockList('1.0', 'end')]));
}
my $frac = sub { $t->blockInsert('Frac', @_) };
for my $case (
  ['head side', sub { $t->insert('end', "x = num\nden + 1\n"); $frac->('1.4', '2.3');
		      $t->tagAdd('b', '1.6', '1.9'); $t->markSet('mk', '1.7'); $t->markGravity('mk', 'left');
		      $t->blockData('1.6', 'payload') },
   '1.2', '1.7', "x m\nden + 1\n\n"],
  ['tail side', sub { $t->insert('end', "x = num\nden + 1\n"); $frac->('1.4', '2.3');
		      $t->tagAdd('b', '1.6', '1.9'); $t->markSet('mk', '1.7'); $t->blockData('1.6', 'payload') },
   '1.6', '1.15', "x = n 1\n\n"],
  ['two blocks, both cut', sub { $t->insert('end', "ab\ncd ef\ngh\n"); $frac->('1.0', '2.2'); $frac->('1.7', '2.2');
				 $t->tagAdd('u', '1.2', '1.9'); $t->markSet('m1', '1.3'); $t->markSet('m2', '1.11') },
   '1.2', '1.11', "a\ngh\n\n"],
  ['nested, the inner one cut', sub { $t->insert('end', "ab\ncd e\n"); $frac->('1.0', '2.4'); $t->blockInsert('Std', '1.2', '1.5') },
   '1.4', '1.8', "{ab e}\n\n"],
  ['nested, cut on both sides', sub { $t->insert('end', "pq\nrs t uv\nw\n"); $frac->('1.0', '2.4');
				      $t->blockInsert('Std', '1.2', '1.5'); $frac->('1.11', '2.1'); $t->tagAdd('b', '1.3', '1.13') },
   '1.4', '1.13', "pquv\nw\n\n"],
  ['cut inside an enclosing block', sub { $t->insert('end', "Ab\ncd e\n"); $frac->('1.0', '2.4'); $t->blockInsert('Std', '1.2', '1.5') },
   '1.1', '1.5', "{cd e}\n\n"],
  ['over several lines', sub { $t->insert('end', "ab\ncd\nxyz\nef\ngh\n"); $frac->('1.0', '2.2'); $frac->('3.0', '4.2');
			       $t->tagAdd('u', '1.1', '3.4'); $t->markSet('m1', '2.1'); $t->markSet('m2', '3.5') },
   '1.2', '3.5', "ah\n\n"],
  ['all but the head', sub { $t->insert('end', "x ab\ncd y\n"); $frac->('1.2', '2.2') }, '1.3', '1.9', "x  y\n\n"],
  ['all but the tail', sub { $t->insert('end', "x ab\ncd y\n"); $frac->('1.2', '2.2') }, '1.2', '1.8', "x  y\n\n"],
  ['a nested block and three levels among the remains',
   sub { $t->insert('end', "ab cd ef\ngh ij\n"); $frac->('1.0', '2.5'); $t->blockInsert('Std', '1.4', '1.6');
	 $t->blockSplit('1.12', 1); $t->blockData('1.5', 'inner'); $t->blockData('1.1', 'outer') },
   '1.9', '1.16', "{ab {cd} ij}\n\n"],
  ['tags across the cut, a mark in the remains',
   sub { $t->insert('end', "012 ab\ncd 9\n"); $frac->('1.4', '2.2'); $t->tagAdd('b', '1.1', '1.7');
	 $t->tagAdd('u', '1.6', '1.12'); $t->markSet('mk', '1.5') },
   '1.2', '1.8', "01cd 9\n\n"],
  ['from the head of one block into another', sub { $t->insert('end', "ab cd\nef\n"); $t->blockInsert('Std', '1.0', '1.2'); $frac->('1.5', '2.2') },
   '1.0', '1.7', "d\nef\n\n"],
) {
  my ($name, $setup, $i1, $i2, $after) = @$case;
  $t->editReset;
  $t->delete('1.0', 'end');
  $t->markUnset($_) for grep { !/^(insert|current)$/ } $t->markNames;
  $setup->();
  $mw->update;
  my $before = snapshot();
  $t->editSeparator;
  $t->delete($i1, $i2);
  $mw->update;
  is($t->get('1.0', 'end'), $after, "$name: the deletion dissolves the cut block(s)");
  my $deleted = snapshot();
  $t->editUndo;
  $mw->update;
  is(snapshot(), $before, "$name: undo restores text, dump and block list");
  $t->editRedo;
  $mw->update;
  is(snapshot(), $deleted, "$name: redo deletes the same way");
  $t->editUndo;
  $mw->update;
  is(snapshot(), $before, "$name: and undo restores again");
}
is_deeply(\@bgerrors, [], 'no background errors in the cut cases') or diag(@bgerrors);

# 10. Undo re-creates embedded images and windows (Tk's text widget
# does not).  An image comes back with its name, its image and its
# options; a window with a -create script is created again when
# displayed; the window of a -window option was destroyed with the
# deletion (as in Tk), so its segment comes back without a window,
# keeping its unit of index space.  The same inside a block and among
# the remains of a cut block.
my $photo = $mw->Photo(-width => 12, -height => 8);
my $photo2 = $mw->Photo(-width => 20, -height => 30);
sub snapshot_emb {		# text, dump, the images and windows with their options
  $t->markSet('insert', 'end');	# undo and redo move it, and it splits segments
  my @d = $t->dump('-all', '1.0', 'end');
  my @k;
  while (@d) { my @e = splice @d, 0, 3; push @k, @e unless $e[0] eq 'mark' && $e[1] =~ /^(insert|current)$/ }
  my @im = map { my $n = $_; "$n\@" . $t->index($n) . '[' . join(',', map { $t->imageCget($n, $_) // '' } qw(-image -align -padx -pady)) . ']' } sort $t->imageNames;
  my @wn = map { my $n = $_; "$n\@" . $t->index($n) . '[' . join(',', map { $t->windowCget($n, $_) } qw(-align -padx -pady -stretch)) . ']' } sort $t->windowNames;
  return join("\n", $t->get('1.0', 'end'), "@k", "@im", "@wn");
}
$t->editReset;
$t->delete('1.0', 'end');
$t->markUnset($_) for grep { !/^(insert|current)$/ } $t->markNames;
$t->insert('end', "ab cd ef\ngh ij\n");
$t->imageCreate('1.1', -image => $photo, -align => 'top', -padx => 2, -pady => 1);
$t->imageCreate('1.4', -image => $photo2, -name => 'pic');
$t->imageCreate('2.1', -name => 'empty');
my $created = 0;
$t->windowCreate('1.7', -create => sub { $created++; $t->Label(Name => 'cw', -text => 'c') },
		 -align => 'bottom', -padx => 3, -pady => 4, -stretch => 1);
my $lab = $t->Label(-text => 'w');
$t->windowCreate('2.4', -window => $lab, -align => 'top');
$mw->update;
is($created, 1, 'the -create script made its window');
my $with = snapshot_emb();
my $path = $lab->PathName;
(my $without = $with) =~ s/window \Q$path\E 2\.4/window  2.4/;
$without =~ s/ ?\Q$path\E\@2\.4\[[^\]]*\]//;
$t->editSeparator;
$t->delete('1.0', 'end');
$mw->update;
is(join(' ', $t->imageNames, $t->windowNames), '', 'the deletion took the images and windows out');
ok(!Tk::Exists($lab), 'and destroyed the -window window, as in Tk');
$t->editUndo;
$mw->update;
is(snapshot_emb(), $without, 'undo re-created the images and windows where they were, with their options; the destroyed window as an empty segment');
is($created, 2, 'the -create script made its window again');
$t->editRedo;
$mw->update;
is(join(' ', $t->imageNames, $t->windowNames), '', 'redo takes them out again');
$photo2->delete;
$t->editUndo;
$mw->update;
$without =~ s/pic\@1\.4\[[^,]*,/pic\@1.4[,/;
is(snapshot_emb(), $without, 'undone again: an image whose Tk image is gone comes back as an empty one, at its place');
# Inside a block, deleted with it.
$t->editReset;
$t->delete('1.0', 'end');
$t->insert('end', "xy z\n");
$t->imageCreate('1.1', -image => $photo, -align => 'top');
$t->windowCreate('1.3', -create => sub { $t->Label(Name => 'cw', -text => 'c') });
$t->blockInsert('Std', '1.0', '1.4');
$mw->update;
$with = snapshot_emb();
$t->editSeparator;
$t->delete('1.0', 'end');
$t->editUndo;
$mw->update;
is(snapshot_emb(), $with, 'an image and a window inside a block come back with it');
# Among the remains of a cut block (undo takes the remains out before
# re-creating the structure; the image and the window are in the record).
$t->editReset;
$t->delete('1.0', 'end');
$t->insert('end', "x = num\nden + 1\n");
$frac->('1.4', '2.3');
$t->imageCreate('1.10', -image => $photo, -padx => 5);
$t->windowCreate('1.12', -create => sub { $t->Label(Name => 'cw', -text => 'c') });
$mw->update;
$with = snapshot_emb();
$t->editSeparator;
$t->delete('1.2', '1.7');
$mw->update;
my ($iname) = $t->imageNames;
is($t->get('1.0', 'end') . $t->index($iname), "x m\nden + 1\n\n2.1", 'the deletion cut the block; the image is among the remains');
$t->editUndo;
$mw->update;
is(snapshot_emb(), $with, 'undo brings the image and the window among the remains back into the block');
$t->editRedo;
$mw->update;
$t->editUndo;
$mw->update;
is(snapshot_emb(), $with, 'and again after a redo');
is_deeply(\@bgerrors, [], 'no background errors with images and windows') or diag(@bgerrors);

# Undo re-creates the tags of the deleted text exactly: text put back
# inside what became one range of a tag does not take the tag where the
# deleted text did not have it.
{
  my $u = $mw->eText(-undo => 1)->pack;
  $u->insert('end', "abcdefghij\nklm\n");
  $u->tagAdd('b', '1.0', '1.3');
  $u->tagAdd('b', '1.6', '1.9');
  $u->editReset;
  $u->delete('1.2', '1.7');
  is(join(' ', $u->tagRanges('b')), '1.0 1.4', 'the deletion joined the two ranges');
  $u->editUndo;
  is(join(' ', $u->tagRanges('b')), '1.0 1.3 1.6 1.9', 'undo separates them again');
  $u->editRedo;
  $u->editUndo;
  is(join(' ', $u->tagRanges('b')), '1.0 1.3 1.6 1.9', 'after a redo too');
  # The gap is exactly the deleted range, and spans a line end.
  $u->tagRemove('b', '1.0', 'end');
  $u->tagAdd('b', '1.0', '1.4');
  $u->tagAdd('b', '2.1', '2.3');
  $u->tagAdd('c', '1.6', '1.8');
  $u->editReset;
  $u->delete('1.4', '2.1');
  is(join(' ', $u->tagRanges('b')), '1.0 1.6', 'joined over the line end');
  $u->editUndo;
  is(join(' ', $u->tagRanges('b')), '1.0 1.4 2.1 2.3', 'undo restores the gap over the line end');
  is(join(' ', $u->tagRanges('c')), '1.6 1.8', 'and the other tag in it');
  $u->destroy;
}

# The redo of an insertion re-inserts exactly what the insertion left:
# the tags it was inserted with, the leaves it made in a block (recorded
# in block-list form when the insertion is undone).
{
  my $u = $mw->eText(-undo => 1)->pack;
  $u->blockConfigure('F');
  $u->debug(1);
  $u->insert('end', "abcdef\nghi\n");
  $u->tagAdd('b', '1.0', '1.6');
  $u->editReset;
  my $state = sub { join '|', $u->get('1.0', 'end'), map { "$_:" . join(' ', $u->tagRanges($_)) } qw(b c) };
  $u->insert('1.3', 'XY', 'c', 'Z', '');		# cuts the run of b
  my $after = $state->();
  is($after, "abcXYZdef\nghi\n\n|b:1.0 1.3 1.6 1.9|c:1.3 1.5",
     'insert with tag lists: XY tagged c only, Z untagged');
  $u->editUndo;
  is($state->(), "abcdef\nghi\n\n|b:1.0 1.6|c:", 'undo takes it out');
  $u->editRedo;
  is($state->(), $after, 'redo puts it back with its tags (not with b, as plain text would get)');
  $u->editUndo; $u->editRedo; $u->editUndo; $u->editRedo;
  is($state->(), $after, 'again and again');

  # In a block: the leaves the insertion made come back.
  $u->delete('1.0', 'end');
  $u->insert('end', "num\nden\n");
  $u->blockInsert('F', '1.0', '2.3');
  $u->editReset;
  my $tree = sub { my @b = $u->blockAt('1.0'); join ' ', $u->get('1.0', '1.end'), Dumper($b[4]) };
  $u->insert('1.2', "a\nb");
  my $split = $tree->();
  $u->editUndo;
  isnt($tree->(), $split, 'undo of an insertion with a newline in a block');
  $u->editRedo;
  is($tree->(), $split, 'redo makes the same leaves again');

  # A mark set in the inserted text after the insertion: the undo moves
  # it to where the text was, the redo back to its place.
  $u->delete('1.0', 'end');
  $u->editReset;
  $u->insert('1.0', 'hello');
  $u->markSet('m', '1.2');
  $u->markGravity('m', 'left');
  $u->editUndo;
  is($u->index('m'), '1.0', 'undo of the insertion moves the mark out');
  $u->editRedo;
  is($u->index('m'), '1.2', 'redo puts it back in place');
  $u->destroy;
}

# A range starting exactly where a tag ends, the tag on again after it:
# the undo of its deletion, and the redo of its insertion, re-create the
# text without the tag (the off-toggle at the start of the range is not
# in the range's block list; the undo now records it).
{
  my $u = $mw->eText(-undo => 1)->pack;
  $u->insert('end', "abcdefgh\n");
  $u->tagAdd('c', '1.0', '1.2', '1.5', '1.8');
  $u->editReset;
  $u->delete('1.2', '1.5');
  is(join(' ', $u->tagRanges('c')), '1.0 1.5', 'the deletion joined the ranges');
  $u->editUndo;
  is(join(' ', $u->tagRanges('c')), '1.0 1.2 1.5 1.8', 'undo: the gap is untagged again');
  $u->delete('1.0', 'end');
  $u->insert('end', "ab\ncd\nef\n");
  $u->tagAdd('c', '1.1', '3.1');
  $u->editReset;
  $u->insert('2.0', "z\nw", 'b');
  my @r = map { join ' ', $u->tagRanges($_) } qw(b c);
  is_deeply(\@r, ['2.0 3.1', '1.1 2.0 3.1 4.1'], 'an insertion with its own tags in a run of c');
  $u->editUndo;
  $u->editRedo;
  is_deeply([map { join ' ', $u->tagRanges($_) } qw(b c)], \@r, 'its redo does not give it c');
  $u->destroy;
}

# A deletion that the final newline makes empty (only the newline was
# named, and it stays) records nothing and does not modify, unless
# the newline had tags, which it takes off (as Tk does) and records.
{
  my $u = $mw->eText(-undo => 1, -autoseparators => 0)->pack;
  $u->insert('1.0', "\n\n");
  $u->editReset;
  my $start = $u->get('1.0', 'end');
  $u->delete('1.1', '3.0'); $u->editSeparator;
  is($u->index('end'), '2.0', 'a deletion leaves a single empty line');
  $u->editModified(0);
  $u->delete('1.1', '2.0');
  ok(!$u->editModified, 'deleting what is left (nothing) does not modify');
  $u->editUndo;
  is($u->get('1.0', 'end'), $start, 'nor is it an undo step: the undo takes back the deletion before');
  $u->delete('1.0', 'end');
  $u->insert('1.0', "ab");
  $u->tagAdd('c', '1.0', 'end');
  $u->editReset;
  $u->delete('1.2', 'end');
  is(join(' ', $u->tagRanges('c')), '1.0 1.2', 'deleting nothing but the final newline takes its tags off');
  $u->editUndo;
  is(join(' ', $u->tagRanges('c')), '1.0 2.0', 'and the undo puts them back');
  # Only the selection on the final newline: not content.
  $u->tagRemove('c', '1.0', 'end');
  $u->insert('1.0', 'X');
  $u->editSeparator;
  $u->tagAdd('sel', '1.0', 'end');
  $u->editModified(0);
  $u->delete('1.3', 'end');
  ok(!$u->editModified, 'deleting nothing but a selected final newline does not modify');
  $u->editUndo;
  is($u->get('1.0', '1.end'), 'ab', 'nor makes an undo step');
  $u->destroy;
}

# The undo of a deletion re-creates tags from the list: a tag starting
# inside a block and going on after it lost its start when another tag
# was switched on and off later in the list (the mark of the first
# tag's start was reused for the second and unset with it).
{
  my $u = $mw->eText(-undo => 1)->pack;
  $u->blockConfigure('F');
  $u->insert('1.0', "abcdefgh\n");
  $u->blockInsert('F', '1.0', '1.3');		# {abc}defgh
  $u->tagAdd('b', '1.3', '1.9');
  $u->tagAdd('c', '1.6', '1.7');
  $u->editReset;
  $u->delete('1.0', '1.8');
  $u->editUndo;
  is(join(' ', map { join ' ', $u->tagRanges($_) } qw(b c)), '1.3 1.9 1.6 1.7',
     'undo of a deletion: a tag starting inside a block, another after it');
  $u->destroy;
}

# A deletion of a whole block between two runs of a tag joins them; the
# undo made the block where the joined run is, and the block's head and
# tail kept the tag.
{
  my $u = $mw->eText(-undo => 1)->pack;
  $u->blockConfigure('F');
  $u->blockConfigure('E', -empty => 1);
  $u->insert('1.0', "abcdefgh\n");
  $u->blockInsert('F', '1.2', '1.4');		# ab{cd}efgh
  $u->tagAdd('c', '1.0', '1.2', '1.7', '1.8');
  $u->editReset;
  $u->delete('1.1', '1.7');
  $u->editUndo;
  is(join(' ', $u->tagRanges('c')), '1.0 1.2 1.7 1.8', 'undo of a deletion of a block between two runs');
  $u->delete('1.0', 'end');
  $u->insert('1.0', "abcd\n");
  $u->blockInsert('E', '1.2');			# ab.cd
  $u->tagAdd('c', '1.0', '1.1', '1.4', '1.5');
  $u->editReset;
  $u->delete('1.1', '1.4');
  $u->editUndo;
  is(join(' ', $u->tagRanges('c')), '1.0 1.1 1.4 1.5', 'the same with an -empty block');
  $u->destroy;
}

# A block re-created in a run of a tag that the list switches off
# inside the block: its tail kept the tag.
{
  my $u = $mw->eText(-undo => 1)->pack;
  $u->blockConfigure('F');
  $u->insert('1.0', "abcdef\nghijkl\nmnopqr\nstu\n");
  $u->tagAdd('b', '1.2', '2.5', '4.0', '5.0');
  $u->blockInsert('F', '2.2', '3.3');		# gh{ijkl|mno}pqr
  $u->editReset;
  my $before = join ' ', $u->tagRanges('b');
  $u->delete('1.5', '3.3');
  $u->editUndo;
  is(join(' ', $u->tagRanges('b')), $before, 'undo: a tag switched off inside a re-created block is off on its tail');
  $u->destroy;
}

# The <<Undo>> and <<Redo>> virtual events (Control-z and friends).
$t->editReset;
$t->delete('1.0', 'end');
$t->insert('end', 'typed');
until ($t->viewable) { $mw->after(20); $mw->update }
$t->focusForce; $mw->update;
$t->eventGenerate('<<Undo>>'); $mw->update;
is($t->get('1.0', 'end'), "\n", '<<Undo>> undoes');
$t->eventGenerate('<<Redo>>'); $mw->update;
is($t->get('1.0', 'end'), "typed\n", '<<Redo>> redoes');
$t->eventGenerate('<<Redo>>'); $mw->update;
is($t->get('1.0', 'end'), "typed\n", '<<Redo>> with nothing to redo is harmless');
is_deeply(\@bgerrors, [], 'and not a background error') or diag(@bgerrors);
is_deeply(\@bgerrors, [], 'no background errors') or diag(@bgerrors);
$t->destroy;
$mw->destroy;
