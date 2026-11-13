#!/usr/bin/perl
# "block list -values", "block cut" and "block paste": a piece of a
# block taken out with the values of what begins in it, and put in again
# as one command.  A value travels with the delimiter that begins its
# owner: a separator of depth k carries the values of the leaf and of
# the k nodes that begin after it.
use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require Tk; 1 } or plan skip_all => "Tk not available: $@";
}
use Tk::eText;
use Data::Dumper;
$Data::Dumper::Indent = 0; $Data::Dumper::Terse = 1;

my $mw = eval { MainWindow->new };
plan skip_all => "no X display available ($@)" unless $mw;
plan tests => 133;
$mw->geometry('+10+10');

my $t;
sub widget {
  $t->destroy if $t;
  $t = $mw->eText(-width => 80, -height => 6, @_)->pack;
  $t->blockConfigure($_) for qw(F G T);
  $t->debug(1);
  $t;
}

# The elements of a list, readable: strings as they are, a separator as
# "|depth" or "|[depth,defect,values...]", a block as {type:depth:node
# values contents}, toggles as <tag> or <tag=value> and </tag>, marks as
# ^name.
sub show {
  my $out = '';
  for my $e (@_) {
    my $c = ref $e;
    if ($c eq 'Tk::Text::String') { (my $s = $$e) =~ s/\n//; $out .= $s }
    elsif ($c eq 'Tk::Text::NewLine') { $out .= '\n' }
    elsif ($c eq 'Tk::Text::BlockSeparator') {
      $out .= '|' . (UNIVERSAL::isa($e, 'ARRAY') ? Dumper([@$e]) : $$e) . ' ' }
    elsif ($c eq 'Tk::Text::Block') {
      $out .= "{$e->[0][0]:$e->[0][1]:"
	. (defined $e->[0][2] ? "data=$e->[0][2]:" : '')
	. Dumper($e->[0][3]) . ' ' . show(@$e[1 .. $#$e]) . '}' }
    elsif ($c eq 'Tk::Text::TagOn') {
      my ($n, @v) = UNIVERSAL::isa($e, 'ARRAY') ? @$e : ($$e);
      $out .= @v ? "<$n=$v[0]>" : "<$n>" unless $n eq 'sel' }
    elsif ($c eq 'Tk::Text::TagOff') { $out .= "</$$e>" unless $$e eq 'sel' }
    elsif ($c =~ /^Tk::Text::Mark/) {
      my $n = UNIVERSAL::isa($e, 'ARRAY') ? $e->[0] : $$e;
      $out .= "^$n" unless $n eq 'insert' or $n eq 'current' }
  }
  $out;
}
# The whole text: every block is listed whole, with its node values in
# its header.
sub state { show($t->blockList('1.0', 'end - 1 c')) }
sub nv { my $v = eval { $t->blockNodedata(@_) }; defined $v ? $v : '-' }
sub dies_like { my ($code, $re, $name) = @_;
		my $ok = !eval { $code->(); 1 }; like($ok ? $@ : 'no error', $re, $name) }

# x{ab|cd||efgh}y on line 1: a root R with the nodes N0 (leaves ab, cd)
# and N1 (leaf efgh); the values ROOT, N0, N1 and L0, L1, L2.
sub three_leaves {
  widget(@_);
  $t->insert('1.0', 'xabcdefghy');
  $t->blockInsert('F', '1.1', '1.9');
  $t->blockSplit('1.4', 0);
  $t->blockSplit('1.7', 1);
  $t->blockNodedata('1.2', 0, 'L0'); $t->blockNodedata('1.5', 0, 'L1');
  $t->blockNodedata('1.8', 0, 'L2');
  $t->blockNodedata('1.2', 1, 'N0'); $t->blockNodedata('1.8', 1, 'N1');
  $t->blockNodedata('1.2', 2, 'ROOT');
  $t->editReset;
}
my $three = q({F:1:['ROOT',['N0',['L0'],['L1']],['N1',['L2']]] ab|0 cd|1 efgh});

# ---------------------------------------------------------------------
# 1. block list -values.
{
  three_leaves(-undo => 1);
  is(state(), "x${three}y", 'the block: two nodes, three leaves, six values');
  is(show($t->blockList('1.3', '1.9')), 'b|0 cd|1 e',
     'block list: the separators with their depths, no values');
  is(show($t->blockList('-values', '1.3', '1.9')),
     q(b|[0,0,'L1'] cd|[1,0,'L2','N1'] e),
     'block list -values: each separator with the values of the leaf and of the nodes it begins');
  is(show($t->blockList('-values', '1.2', '1.4')), 'ab',
     'no separator in the range: only the text');
  is(show($t->blockList('-values', '1.0', 'end - 1 c')), "x${three}y",
     'a block listed whole keeps its values in the header, its separators plain');
  is(show($t->blockList('-values', '1.5', '1.5')), '', 'an empty range');
  $t->blockNodedata('1.8', 1, undef);
  is(show($t->blockList('-values', '1.6', '1.9')), q(d|[1,0,'L2',undef] e),
     'a node without a value: undef in its place');
  dies_like(sub { $t->block('list', '-values', '1.2') }, qr/wrong # args.*\?-values\?/,
	    'block list: wrong # args');
  dies_like(sub { $t->block('list', '-nosuch', '1.2', '1.3') }, qr/wrong # args/,
	    'block list: an unknown switch');
}

# The example of the manual: a table of rows of cells.
{
  widget();
  $t->insert('1.0', 'abcd');
  $t->blockInsert('T', '1.0', '1.4');		# {abcd}
  $t->blockSplit('1.4', 0);			# {abc|d}
  $t->blockSplit('1.3', 1);			# {ab||c|d}
  $t->blockSplit('1.2', 0);			# {a|b||c|d}
  $t->blockNodedata('1.3', 0, 'B'); $t->blockNodedata('1.5', 0, 'C');
  $t->blockNodedata('1.7', 0, 'D'); $t->blockNodedata('1.5', 1, 'ROW2');
  is(state(), q({T:1:[undef,[undef,[undef],['B']],['ROW2',['C'],['D']]] a|0 b|1 c|0 d}),
     'a table: two rows of two cells');
  is(show($t->blockList('-values', '1.3', '1.6')), q(b|[1,0,'C','ROW2'] c),
     'a row separator carries the values of the cell and of the row it begins');
  is(show($t->blockList('-values', '1.2', '1.4')), q(|[0,0,'B'] b),
     'a cell separator that of its cell');
}

# ---------------------------------------------------------------------
# 2. block cut and block paste at the same place: the identity, values
# included; undo and redo of each, one step each.
{
  three_leaves(-undo => 1);
  my @cut = $t->blockCut('1.3', '1.9');
  is(show(@cut), q(b|[0,0,'L1'] cd|[1,0,'L2','N1'] e), 'block cut returns the list with the values');
  is(state(), q(x{F:1:['ROOT',['N0',['L0']]] afgh}y),
     'and deletes the range: the joined leaf and node keep their values');
  my @r = $t->blockPaste('1.3', \@cut);
  is("@r", '1.3 1.9', 'block paste returns the range it filled');
  is(state(), "x${three}y", 'pasted at the same place: text, tree and values as before');
  $t->editUndo;
  is(state(), q(x{F:1:['ROOT',['N0',['L0']]] afgh}y), 'undo of the paste');
  $t->editUndo;
  is(state(), "x${three}y", 'undo of the cut');
  $t->editRedo;
  is(state(), q(x{F:1:['ROOT',['N0',['L0']]] afgh}y), 'redo of the cut');
  $t->editRedo;
  is(state(), "x${three}y", 'redo of the paste');
  dies_like(sub { $t->editRedo }, qr/nothing to redo/, 'two steps, no more');
}

# The deletion of "block cut" against "delete": the end side's value
# does not move to a joined node that has none.
{
  three_leaves(-undo => 1);
  $t->blockNodedata('1.2', 0, undef);
  $t->blockNodedata('1.2', 1, undef);
  $t->delete('1.3', '1.9');
  is(state(), q(x{F:1:['ROOT',['N1',['L2']]] afgh}y),
     'delete: the joined leaf and node take the end side\'s values');
  $t->editUndo;
  my @cut = $t->blockCut('1.3', '1.9');
  is(state(), q(x{F:1:['ROOT',[undef,[undef]]] afgh}y),
     'block cut: they keep what they had, here nothing');
  is(show(@cut), q(b|[0,0,'L1'] cd|[1,0,'L2','N1'] e), 'the values left with the list');
  $t->blockPaste('1.3', \@cut);
  is(state(), q(x{F:1:['ROOT',[undef,[undef],['L1']],['N1',['L2']]] ab|0 cd|1 efgh}y),
     'and come back with it');
  $t->editUndo;
  is(state(), q(x{F:1:['ROOT',[undef,[undef]]] afgh}y),
     'undo of the paste: the leaf pasted into has no value again');
  $t->editUndo;
  is(state(), q(x{F:1:['ROOT',[undef,[undef],['L1']],['N1',['L2']]] ab|0 cd|1 efgh}y),
     'undo of the cut');
}

# The separator deleted and Enter typed loses the value of the second
# leaf; cut and paste keeps it (the fraction of the design note).
{
  widget(-undo => 1);
  $t->insert('1.0', 'xnumdeny');
  $t->blockInsert('F', '1.1', '1.7');
  $t->blockSplit('1.5', 0);
  $t->blockNodedata('1.2', 0, 'NUM'); $t->blockNodedata('1.6', 0, 'DEN');
  $t->blockNodedata('1.2', 1, 'ROOT');
  my $frac = q(x{F:0:['ROOT',['NUM'],['DEN']] num|0 den}y);
  is(state(), $frac, 'a fraction with values');
  $t->delete('1.5');
  $t->insert('1.5', "\n");
  is(state(), q(x{F:0:['ROOT',['NUM'],[undef]] num|0 den}y),
     'the separator deleted, then a newline: DEN is gone');
  $t->editUndo; $t->editUndo;
  is(state(), $frac, 'undone');
  my @sep = $t->blockCut('1.5', '1.6');
  is(show(@sep), q(|[0,0,'DEN'] ), 'the separator cut: it carries DEN');
  is(state(), q(x{F:0:['ROOT',['NUM']] numden}y), 'one leaf');
  $t->blockPaste('1.5', \@sep);
  is(state(), $frac, 'pasted: the fraction with DEN');
}

# ---------------------------------------------------------------------
# 3. Paste somewhere else.
{
  # Into a tree that is less deep: levels are added above its nodes,
  # the root keeps its value; the undo takes them away again.
  three_leaves(-undo => 1);
  $t->insert('1.end', 'pqrsz');
  $t->blockInsert('G', '1.14', '1.18');		# y{pqrs}z, the head at 1.14
  $t->blockNodedata('1.16', 0, 'Q');
  $t->editReset;
  my $g = q({G:0:[undef,['Q']] pqrs});
  is(state(), "x${three}y${g}z", 'a second block: a root with one leaf, which has a value');
  my @piece = $t->blockList('-values', '1.3', '1.9');
  my @r = $t->blockPaste('1.17', \@piece);
  is("@r", '1.17 1.23', 'the range filled');
  my $pasted = q({G:1:[undef,[undef,['Q'],['L1']],['N1',['L2']]] pqb|0 cd|1 ers});
  is(state(), "x${three}y${pasted}z",
     'pasted into a tree of one level: the tree it needs, the values of the piece on its nodes');
  $t->editUndo;
  is(state(), "x${three}y${g}z", 'undo: one level again, the leaf with its value');
  is(Dumper(($t->blockAt('1.14'))[4]), '[4]', 'block at: a root with one leaf of four characters');
  $t->editRedo;
  is(state(), "x${three}y${pasted}z", 'redo');
  $t->editUndo;

  # The same into a block that is a single leaf (no node at all).
  $t->blockFlatten('1.16', 1);
  $t->editReset;
  $g = q({G:-1:['Q'] pqrs});
  is(state(), "x${three}y${g}z", 'the second block flattened: a single leaf');
  $t->blockPaste('1.17', \@piece);
  is(state(), "x${three}y${pasted}z", 'pasted into a single leaf: the same tree');
  $t->editUndo;
  is(state(), "x${three}y${g}z", 'undo: a single leaf again');
  is(($t->blockAt('1.14'))[4], 4, 'block at: one leaf of four characters, no node');
  $t->editRedo;
  is(state(), "x${three}y${pasted}z", 'redo');
  $t->editUndo;

  # Outside blocks a separator is a newline, and its values have no
  # owner.
  @r = $t->blockPaste('1.0', \@piece);
  is("@r", '1.0 3.1', 'pasted outside blocks: three lines');
  is($t->get('1.0', '3.1'), "b\ncd\ne", 'the separators are newlines');
  $t->editUndo;
  is(state(), "x${three}y${g}z", 'undone');
}

# A whole block in the list: its type, instance data and node values.
{
  three_leaves(-undo => 1);
  $t->blockData('1.2', 'DATA');
  my @all = $t->blockList('-values', '1.0', '1.13');
  my $block = q({F:1:data=DATA:['ROOT',['N0',['L0'],['L1']],['N1',['L2']]] ab|0 cd|1 efgh});
  is(show(@all), "x$block", 'a list with a whole block');
  $t->insert('1.end', "\nline two");
  my @r = $t->blockPaste('2.4', \@all);
  is("@r", '2.4 2.17', 'the range filled');
  is(show($t->blockList('2.0', '2.end')), "linex$block two",
     'the block is there with its instance data and the values of its nodes');
  is($t->blockData('2.6'), 'DATA', 'block data');
  $t->editUndo;
  is($t->get('2.0', '2.end'), 'line two', 'undone');
  $t->editRedo;
  is(show($t->blockList('2.0', '2.end')), "linex$block two", 'redone, values included');

}

# A range that cuts a block: both commands delete as "delete" does (the
# block is dissolved); the list has the part as a block of its own.
{
  widget(-undo => 1);
  $t->insert('1.0', 'xnumdeny');
  $t->blockInsert('F', '1.1', '1.7');
  $t->blockSplit('1.5', 0);
  $t->blockNodedata('1.2', 0, 'NUM'); $t->blockNodedata('1.6', 0, 'DEN');
  $t->blockNodedata('1.2', 1, 'ROOT');
  $t->blockData('1.2', 'INST');
  my $frac = q(x{F:0:data=INST:['ROOT',['NUM'],['DEN']] num|0 den}y);
  is(state(), $frac, 'a fraction with instance data');
  my @cut = $t->blockCut('1.0', '1.4');
  is(show(@cut), q(x{F:0:data=INST:undef nu}), 'x{nu cut: the part is a block of its own in the list');
  is($t->get('1.0', 'end - 1 c'), "m\ndeny", 'the block is dissolved, as by delete');
  $t->blockPaste('1.0', \@cut);
  is(state(), q(x{F:0:data=INST:undef nu}m\ndeny), 'pasted: that block, not the old one');
  $t->editUndo; $t->editUndo;
  is(state(), $frac, 'the undo restores the cut block');

  # A block type the widget does not have: the contents without the
  # block.
  my @all = $t->blockList('-values', '1.0', 'end - 1 c');
  my $other = $mw->eText(-width => 20, -height => 3)->pack;
  $other->insert('1.0', 'AB');
  my @r = $other->blockPaste('1.1', \@all);
  is($other->get('1.0', 'end - 1 c'), "Axnum\ndenyB", 'no such block type there: its contents as text');
  is("@r", '1.1 2.4', 'the range');
  $other->destroy;

  # A tag the list does not mention: the pasted text is as text typed
  # at the place.
  $t->tagAdd('u', '1.2', '1.4');
  my @plain = $t->blockList('-values', '1.7', '1.9');	# en
  $t->blockPaste('1.3', \@plain);
  is($t->get('1.0', '1.end'), 'x{nenum|den}y', 'pasted inside a run of a tag');
  is(join(' ', $t->tagRanges('u')), '1.2 1.6', 'it has the tag of the place');
}

# ---------------------------------------------------------------------
# 4. The example of the design note (8.7): two rows, the fragments end
# in the middle of a cell with a span.  The span travels with the
# separator that begins its cell.
{
  widget(-undo => 1);
  $t->insert('1.0', "p1p2x1x2\nq1q2y1y2");
  for my $l (1, 2) {
    $t->blockInsert('T', "$l.0", "$l.8");
    $t->blockSplit("$l.5", 0);
  }
  $t->blockNodedata('1.7', 0, 'span2');
  $t->blockNodedata('2.7', 0, 'span3');
  my @f1 = $t->blockCut('1.3', '1.8');		# p2|x1
  my @f2 = $t->blockCut('2.3', '2.8');		# q2|y1
  is(show(@f1), q(p2|[0,0,'span2'] x1), 'the first fragment carries its span');
  is(show(@f2), q(q2|[0,0,'span3'] y1), 'and the second');
  is(state(), q({T:0:undef p1x2}\n{T:0:undef q1y2}),
     'the cells that are left have no span');
  $t->blockPaste('1.3', \@f2);
  $t->blockPaste('2.3', \@f1);
  is(state(), q({T:0:[undef,[undef],['span3']] p1q2|0 y1x2}\n{T:0:[undef,[undef],['span2']] q1p2|0 x1y2}),
     'exchanged: each span came with the first half of its cell');
  $t->editUndo for 1 .. 4;
  is(state(), q({T:0:[undef,[undef],['span2']] p1p2|0 x1x2}\n{T:0:[undef,[undef],['span3']] q1q2|0 y1y2}),
     'four undo steps: as at the start');
}

# ---------------------------------------------------------------------
# 5. Runs of tags and their values; marks.
{
  widget(-undo => 1);
  $t->insert('1.0', 'abcdefghij');
  $t->tagAdd('link', '1.2', '1.6');
  $t->tagData('link', '1.3', 'URL');
  $t->tagAdd('b', '1.4', '1.8');
  $t->markSet('m', '1.5'); $t->markSet('r', '1.5'); $t->markGravity('r', 'left');
  is(show($t->blockList('1.3', '1.7')), 'd<b>e^r^mf</link>g',
     'block list: the run already on is not mentioned at its start');
  is(show($t->blockList('-values', '1.3', '1.7')), '<link=URL>d<b>e^r^mf</link>g',
     'block list -values: it is, with a copy of its value');
  my @piece = $t->blockList('-values', '1.3', '1.7');
  $t->insert('1.end', "\n0123456789");
  $t->blockPaste('2.5', \@piece);
  is($t->get('2.0', '2.end'), '01234defg56789', 'pasted on another line');
  is(join(' ', $t->tagRanges('link')), '1.2 1.6 2.5 2.8', 'the run of link came along');
  is($t->tagData('link', '2.6'), 'URL', 'with its value');
  is(join(' ', $t->tagRanges('b')), '1.4 1.8 2.6 2.9',
     'a run still on at the end of the piece ends with it');
  is($t->index('m'), '1.5', 'without -marks the marks stay');
  $t->editUndo;
  is($t->get('2.0', '2.end'), '0123456789', 'undone');
  is(join(' ', $t->tagRanges('link')), '1.2 1.6', 'the run is gone with it');
  $t->editRedo;
  is($t->tagData('link', '2.6'), 'URL', 'redo: the run has its value');
  $t->editUndo;
  $t->blockPaste('2.5', \@piece, '-marks');
  is($t->index('m') . ' ' . $t->index('r'), '2.7 2.7', 'with -marks the marks move there');
  is($t->markGravity('m') . ' ' . $t->markGravity('r'), 'right left', 'with their gravities');

  # Pasted next to a run of the same tag that has a value: one run, the
  # value of the first.
  $t->tagData('link', '2.6', 'OTHER');
  $t->blockPaste('2.8', \@piece);
  is(join(' ', $t->tagRanges('link')), '1.2 1.6 2.5 2.11', 'joined with the run before it');
  is($t->tagData('link', '2.9'), 'OTHER', 'the run keeps the value it had');
}

# ---------------------------------------------------------------------
# 6. Cut and paste and the clipboard methods of the widget.
SKIP: {
  three_leaves(-undo => 1);
  skip 'no clipboard methods', 14 unless $t->can('clipboardCut');
  $t->tagAdd('sel', '1.3', '1.9');
  $t->clipboardCopy;
  my $clip = eval { $t->clipboardGet };
  skip 'the clipboard is not available here', 14 unless defined $clip;
  is($clip, 'b|cd|e', 'clipboardCopy: the string on the clipboard, as before');
  is(state(), "x${three}y", 'nothing changed');
  $t->markSet('insert', '1.13');		# Before the y, outside the block.
  $t->clipboardPaste;
  is($t->get('1.13', '3.1'), "b\ncd\ne", 'pasted outside the block: the separators are newlines there');
  is($t->index('insert'), '3.1', 'the cursor is after what was pasted');
  $t->editUndo;
  is(state(), "x${three}y", 'one undo step');
  $t->tagAdd('sel', '1.3', '1.9');
  $t->clipboardCut;
  is(state(), q(x{F:1:['ROOT',['N0',['L0']]] afgh}y), 'clipboardCut: as block cut');
  $t->markSet('insert', '1.3');
  $t->clipboardPaste;
  is(state(), "x${three}y", 'clipboardPaste: the structure and the values are back');
  $t->editUndo; $t->editUndo;
  is(state(), "x${three}y", 'two undo steps back');
  # Another owner of the clipboard: the string is pasted, as Tk::Text
  # does.
  $t->tagAdd('sel', '1.3', '1.9');
  $t->clipboardCopy;
  $t->tagRemove('sel', '1.0', 'end');
  $mw->clipboardClear; $mw->clipboardAppend('PLAIN');
  $t->markSet('insert', '1.2');
  $t->clipboardPaste;
  is($t->get('1.0', '1.end'), 'x{PLAINab|cd|efgh}y', 'a string from elsewhere is inserted as text');
  $t->editUndo;
  is(state(), "x${three}y", 'undone');
  # A selection that covers the cursor is replaced by the paste.
  $t->tagAdd('sel', '1.5', '1.7');
  $t->clipboardCut;				# cd
  is($t->get('1.0', '1.end'), 'x{ab||efgh}y', 'a leaf emptied');
  $t->tagAdd('sel', '1.2', '1.4');		# ab
  $t->markSet('insert', '1.3');
  $t->clipboardPaste;
  is($t->get('1.0', '1.end'), 'x{cd||efgh}y', 'the selection is replaced by what is pasted');
  is($t->index('insert'), '1.4', 'the cursor is after it');
}

# ---------------------------------------------------------------------
# 7. A disabled widget, errors, -valuecommand.
{
  three_leaves(-undo => 1);
  $t->configure(-state => 'disabled');
  my @cut = $t->blockCut('1.3', '1.9');
  is(show(@cut), q(b|[0,0,'L1'] cd|[1,0,'L2','N1'] e), 'disabled: block cut returns the list');
  is(state(), "x${three}y", 'and deletes nothing');
  $t->blockPaste('1.3', \@cut);
  is(state(), "x${three}y", 'block paste does nothing');
  $t->configure(-state => 'normal');
  dies_like(sub { $t->block('cut', '1.3') }, qr/wrong # args.*block cut index1 index2/,
	    'block cut: wrong # args');
  dies_like(sub { $t->block('paste', '1.3') }, qr/wrong # args.*block paste index list \?-marks\?/,
	    'block paste: wrong # args');
  dies_like(sub { $t->blockPaste('1.3', 'text') }, qr/bad list "text": must be a reference to an array/,
	    'block paste: the list must be an array');
  dies_like(sub { $t->blockPaste('1.3', \@cut, '-nosuch') }, qr/wrong # args/,
	    'block paste: an unknown switch');
  dies_like(sub { $t->blockPaste('nowhere', \@cut) }, qr/bad text index/, 'a bad index');
  is(state(), "x${three}y", 'nothing changed');
  is(join(' ', map "@$_", [$t->blockCut('1.5', '1.5')]), '', 'an empty range: nothing');
  my @r = $t->blockPaste('1.3', []);
  is("@r", '1.3 1.3', 'an empty list: nothing put in');
  ok(!eval { $t->editUndo; 1 }, 'and nothing recorded');
  # A list made by hand.
  @r = $t->blockPaste('1.3', [ bless(\(my $s1 = 'P'), 'Tk::Text::String'),
			       bless([1, 0, 'LV', 'NV'], 'Tk::Text::BlockSeparator'),
			       bless(\(my $s2 = 'Q'), 'Tk::Text::String') ]);
  is(state(), q(x{F:1:['ROOT',['N0',['L0']],['NV',['LV'],['L1']],['N1',['L2']]] aP|1 Qb|0 cd|1 efgh}y),
     'a list made by hand: a row separator with the values of the cell and of the row');
  $t->editUndo;
  is(state(), "x${three}y", 'undone');
}

{
  my @events;
  three_leaves(-undo => 1, -valuecommand => sub {
		 my ($w, $event, $kind, $where, $value, $cause) = @_;
		 push @events, "$cause: $event " . (defined $value ? $value : 'undef') . ' at '
		   . join(' ', map { ref $_ ? "[@$_]" : $_ } @$where) });
  $t->blockNodedata('1.2', 0, undef);
  @events = ();
  my @cut = $t->blockCut('1.3', '1.9');
  is(join('; ', sort @events),
     'block cut: stash L1 at 1.5 0; block cut: stash L2 at 1.8 0; block cut: stash N1 at 1.8 1',
     '-valuecommand: block cut stashes the values it takes, it moves none');
  @events = ();
  $t->blockPaste('1.3', \@cut);
  is("@events", '', 'block paste tells nothing: it detaches no value');
  $t->editUndo;
  is(join('; ', sort @events),
     'undo: stash L1 at 1.5 0; undo: stash L2 at 1.8 0; undo: stash N1 at 1.8 1',
     'the undo of the paste stashes the values the paste brought');
  @events = ();
  $t->editUndo;
  is(join('; ', sort @events),
     'undo: restore L1 at 1.5 0; undo: restore L2 at 1.8 0; undo: restore N1 at 1.8 1',
     'the undo of the cut gives back those of the cut');
  $t->configure(-undo => 0);
  @events = ();
  $t->blockCut('1.3', '1.9');
  is(join('; ', sort @events),
     'block cut: drop L1 at 1.5 0; block cut: drop L2 at 1.8 0; block cut: drop N1 at 1.8 1',
     'without -undo they are dropped (the list has copies)');
}

# ---------------------------------------------------------------------
# 8. Random documents: a block with up to three levels, sometimes a
# block nested in a leaf, values on most nodes; all leaves of a block
# equally deep.  For every range that cuts no block: cut and paste at
# the same place gives the text, the trees and the values back; and for
# every range the undo and the redo of both are exact.
{
  widget(-undo => 1);
  srand(20261112);
  my $val = 0;
  my $leaves = sub {
    my $head = shift;
    my @r = $t->blockAt("1.$head");
    my ($pos, @l) = ($head + 1);
    my $walk; $walk = sub { for my $c (@{$_[0]}) {
      if (ref $c) { $walk->($c) } else { push @l, [$pos, $c]; $pos += $c + 1 } } };
    $walk->(ref $r[4] ? $r[4] : [$r[4]]);
    @l;
  };
  my $splits = sub {
    my ($head, $n, $maxlevel) = @_;
    for (1 .. $n) {
      my $len = ($t->blockAt("1.$head"))[1];
      $t->blockSplit('1.' . ($head + 1 + int rand($len - 1)), int rand($maxlevel + 1));
    }
  };
  my $values = sub {
    my $head = shift;
    for my $l ($leaves->($head)) {
      for (my $level = 0; ; $level++) {
	last unless eval { $t->blockNodedata("1.$l->[0]", $level); 1 };
	next if rand() < 0.25;
	$t->blockNodedata("1.$l->[0]", $level, 'v' . $val++)
	  unless defined $t->blockNodedata("1.$l->[0]", $level);
      }
    }
  };
  my $inner = sub { my @r = $t->blockOf("1.$_[0]"); @r ? $r[0] : 'none' };
  my (%n, @bad);
  for my $doc (1 .. 60) {
    $t->delete('1.0', 'end');
    my $n = 14 + int rand 8;
    $t->insert('1.0', join '', map chr(97 + int rand 26), 1 .. $n);
    my $a = 1 + int rand 3;
    my $b = $n - 1 - int rand 3;
    $t->blockInsert('F', "1.$a", "1.$b");
    $splits->($a, int rand 6, 2);
    my @big = grep $_->[1] >= 3, $leaves->($a);
    if (@big and rand() < 0.6) {
      my $l = $big[rand @big];
      my $p = $l->[0] + int rand($l->[1] - 1);
      my $q = $p + 1 + int rand($l->[0] + $l->[1] - $p - 1);
      $t->blockInsert('G', "1.$p", "1.$q");
      $splits->($p, int rand 4, 1);
      $values->($p);
    }
    $values->($a);
    $t->editReset;
    my $end = length $t->get('1.0', '1.end');
    my $s0 = state();
    for (1 .. 12) {
      my $i = int rand $end; my $j = $i + 1 + int rand($end - $i);
      my $kind = $inner->($i) eq $inner->($j) ? 'none' : 'cut';
      my @frag = $t->blockCut("1.$i", "1.$j");
      my $s1 = state();
      $t->blockPaste("1.$i", \@frag);
      my $s2 = state();
      $n{$kind}{tried}++;
      $n{$kind}{same}++ if $s2 eq $s0;
      push @bad, "identity, document $doc, $i to $j" if $kind eq 'none' and $s2 ne $s0;
      $t->editUndo; my $u1 = state();
      $t->editUndo; my $u0 = state();
      $t->editRedo; my $r1 = state();
      $t->editRedo; my $r2 = state();
      $t->editUndo; $t->editUndo;
      my $ok = $u1 eq $s1 && $u0 eq $s0 && $r1 eq $s1 && $r2 eq $s2 && state() eq $s0;
      $n{$kind}{undo}++ if $ok;
      push @bad, "undo, document $doc, $i to $j" unless $ok;
    }
  }
  cmp_ok($n{none}{tried}, '>', 250, "ranges that cut no block: $n{none}{tried}");
  is($n{none}{same}, $n{none}{tried}, 'cut and paste at the same place: text, trees and values as before');
  is($n{none}{undo}, $n{none}{tried}, 'undo and redo of the cut and of the paste are exact');
  cmp_ok($n{cut}{tried}, '>', 250, "ranges that cut a block: $n{cut}{tried}");
  is($n{cut}{undo}, $n{cut}{tried}, 'there too undo and redo are exact');
  is("@bad[0 .. ($#bad > 4 ? 4 : $#bad)]", '', 'no failures');
}

# ---------------------------------------------------------------------
# 9. Two tables, an interval of each, exchanged: through a variable, and
# with no safe place (the second table holds both pieces for a moment).
# Expected: the items of each table (characters, and separators with
# the values of what they begin) with the two intervals exchanged.
{
  widget(-undo => 1);
  srand(1112);
  my $val;
  my $table = sub {
    my ($line, $upper, $deep) = @_;
    my @rows = map [map { join '', map chr(($upper ? 65 : 97) + int rand 26), 1 .. 1 + int rand 3 }
		    1 .. 2 + int rand 3], 1 .. 2 + int rand 3;
    my $text = join '', map @$_, @rows;
    $t->insert("$line.0", $text);
    $t->blockInsert('T', "$line.0", "$line." . length $text);
    my ($pos, @cuts) = (1);
    for my $r (0 .. $#rows) { for my $c (0 .. $#{$rows[$r]}) {
      push @cuts, [$pos, $c ? 0 : ($deep && rand() < 0.3 ? 2 : 1)] if $r or $c;
      $pos += length $rows[$r][$c];
    } }
    $t->blockSplit("$line.$_->[0]", $_->[1]) for reverse @cuts;
    my $len = ($t->blockAt("$line.0"))[1];
    for my $p (1 .. $len - 1) {
      for my $level (0 .. 3) {
	next if rand() < 0.2;
	eval { $t->blockNodedata("$line.$p", $level, 'v' . ++$val)
		 unless defined $t->blockNodedata("$line.$p", $level) };
      }
    }
    $len;
  };
  # The items inside the table on a line; and the values of what begins
  # with the table: its first leaf and the nodes above it, the root last.
  my $items = sub {
    my $line = shift;
    my $len = ($t->blockAt("$line.0"))[1];
    my @out;
    for my $e ($t->blockList('-values', "$line.1", "$line." . ($len - 1))) {
      if (ref $e eq 'Tk::Text::String') { push @out, split //, $$e }
      elsif (ref $e eq 'Tk::Text::BlockSeparator') { push @out, '|' . Dumper([@$e]) }
    }
    @out;
  };
  my $first = sub {
    my $line = shift;
    my @v;
    for (my $level = 0; ; $level++) {
      my $v; last unless eval { $v = $t->blockNodedata("$line.1", $level); 1 };
      push @v, defined $v ? $v : '-';
    }
    my $root = pop @v;
    pop @v while @v and $v[-1] eq '-';	# Nodes added below the root have none.
    join(' ', @v) . " / $root";
  };
  my %ways = (
    'through a variable' => sub {
      my ($i1, $j1, $i2, $j2) = @_;
      my @f1 = $t->blockCut("1.$i1", "1.$j1");
      my @f2 = $t->blockCut("2.$i2", "2.$j2");
      $t->blockPaste("1.$i1", \@f2);
      $t->blockPaste("2.$i2", \@f1);
    },
    'with no safe place' => sub {
      my ($i1, $j1, $i2, $j2) = @_;
      my $n = $j1 - $i1;
      my @f1 = $t->blockCut("1.$i1", "1.$j1");
      $t->blockPaste("2.$i2", \@f1);		# Table 2 holds both now.
      my @f2 = $t->blockCut('2.' . ($i2 + $n), '2.' . ($j2 + $n));
      $t->blockPaste("1.$i1", \@f2);
    },
  );
  for my $way (sort keys %ways) {
    my ($ok, $tried, $undo, $withsep, @bad) = (0, 0, 0, 0);
    for my $pair (1 .. 80) {
      $t->delete('1.0', 'end');
      $t->insert('1.0', "\n\n");
      $val = 0;
      my $len1 = $table->(1, 0, $pair % 2);
      my $len2 = $table->(2, 1, 0);
      $t->editReset;
      my @t1 = $items->(1); my @t2 = $items->(2);
      my ($h1, $h2) = ($first->(1), $first->(2));
      my $s0 = state();
      my $i1 = 1 + int rand($len1 - 2); my $j1 = $i1 + 1 + int rand($len1 - 1 - $i1);
      my $i2 = 1 + int rand($len2 - 2); my $j2 = $i2 + 1 + int rand($len2 - 1 - $i2);
      my @f1 = @t1[$i1 - 1 .. $j1 - 2]; my @f2 = @t2[$i2 - 1 .. $j2 - 2];
      my $want1 = join '', @t1[0 .. $i1 - 2], @f2, @t1[$j1 - 1 .. $#t1];
      my $want2 = join '', @t2[0 .. $i2 - 2], @f1, @t2[$j2 - 1 .. $#t2];
      $withsep++ if grep { /^\|/ } @f1, @f2;
      $ways{$way}->($i1, $j1, $i2, $j2);
      $tried++;
      my $good = join('', $items->(1)) eq $want1 && join('', $items->(2)) eq $want2
	&& $first->(1) eq $h1 && $first->(2) eq $h2;
      $ok++ if $good;
      push @bad, $pair unless $good;
      $t->editUndo for 1 .. 4;
      $undo++ if state() eq $s0;
    }
    cmp_ok($withsep, '>', 40, "$way: $withsep of $tried pairs of pieces hold separators");
    is($ok, $tried, "$way: both tables as expected, the values with their separators");
    is($undo, $tried, "$way: four undo steps give the two tables back");
    is("@bad[0 .. ($#bad > 4 ? 4 : $#bad)]", '', "$way: no failures");
  }
}

# ---------------------------------------------------------------------
# 10. Values that are objects are freed once: the list holds copies of
# the references, the undo steps the containers.
{
  my @log;
  {
    package CPV;
    sub new { my ($class, $name) = @_; bless { n => $name }, $class }
    sub DESTROY { push @log, $_[0]{n} }
  }
  widget(-undo => 1);
  $t->insert('1.0', 'xabcdy');
  $t->blockInsert('F', '1.1', '1.5');
  $t->blockSplit('1.4', 0);
  $t->blockNodedata('1.5', 0, CPV->new('second'));
  {
    my @cut = $t->blockCut('1.3', '1.6');
    is("@log", '', 'cut: the object is alive (in the list and in the undo step)');
    $t->blockPaste('1.3', \@cut);
    is(ref $t->blockNodedata('1.5', 0), 'CPV', 'pasted: the leaf has the object');
  }
  is("@log", '', 'the list is gone: still alive');
  $t->editReset;
  is("@log", '', 'the undo steps are gone: the leaf holds it');
  $t->delete('1.0', 'end');
  is("@log", '', 'deleted with its leaf: the undo step holds it');
  $t->editReset;
  is("@log", 'second', 'the step discarded: destroyed, once');
}

$t->destroy;
