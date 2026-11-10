#!/usr/bin/perl
# Undo and redo of block split, block insert, block trim, tag add and
# tag remove (recorded since 2.04): each is reversed exactly (text,
# structure, tags, values), redone exactly, and is an edit of its own
# kind for -autoseparators.  The values are objects whose DESTROY
# method records that it ran (as in t/values.t).
use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require Tk; 1 } or plan skip_all => "Tk not available: $@";
}
use Tk::eText;
use Data::Dumper;
$Data::Dumper::Indent = 0; $Data::Dumper::Terse = 1; $Data::Dumper::Sortkeys = 1;

my $mw = eval { MainWindow->new };
plan skip_all => "no X display available ($@)" unless $mw;
plan tests => 260;
$mw->geometry('+10+10');

my @log;			# names of the objects destroyed, in order
{
  package V;
  sub new { my ($class, $name) = @_; bless { n => $name }, $class }
  sub DESTROY { push @log, $_[0]{n} }
}
sub freed (&) { @log = (); $_[0]->(); my @r = @log; @log = (); return \@r }

my $t = $mw->eText(-width => 40, -height => 8, -undo => 1)->pack;
$t->blockConfigure('F');
$t->blockConfigure('G');
$t->blockConfigure('E', -empty => 1);
$t->debug(1);

# The whole state: the block list (values by name, the insert and
# current marks left out, adjacent strings joined), the structure of
# the blocks of line 1, the tag ranges and the marks.
sub norm {
  my $x = shift;
  return "V:$x->{n}" if ref $x eq 'V';
  if (ref $x && UNIVERSAL::isa($x, 'ARRAY')) {
    my @a;
    for my $e (@$x) {
      next if ref($e) =~ /Mark/ && (UNIVERSAL::isa($e, 'ARRAY') ? $e->[0] : $$e) =~ /^(insert|current)$/;
      my $n = norm($e);
      if (ref $n && $n->[0] eq 'Tk::Text::String' && @a && ref $a[-1] && $a[-1][0] eq 'Tk::Text::String') {
	$a[-1][1] .= $n->[1];
      } else {
	push @a, $n;
      }
    }
    return [ref($x), @a];
  }
  return [ref($x), $$x] if ref $x && UNIVERSAL::isa($x, 'SCALAR');
  return $x;
}
sub state {
  my @l = $t->blockList('1.0', 'end');
  my @s = (norm(\@l));
  for my $i (0 .. 30) {
    my @b = $t->blockAt("1.$i");
    push @s, [$i, $b[4]] if @b;
  }
  push @s, map { [$_, $t->tagRanges($_)] } qw(b c);
  push @s, [map { "$_=" . $t->index($_) } sort grep { !/^(insert|current)$/ } $t->markNames];
  return Dumper(\@s);
}
sub fresh {
  $t->delete('1.0', 'end');
  $t->tagRemove($_, '1.0', 'end') for qw(b c);
  $t->insert('1.0', $_[0]);
  $t->editReset;
}
sub text { $t->get('1.0', '1.end') }
sub nv { my $v = $t->blockNodedata(@_); defined $v ? (ref $v ? $v->{n} : $v) : undef }
sub rv { my $v = $t->tagData(@_); defined $v ? (ref $v ? $v->{n} : $v) : undef }

# Do something, check that undo gives the state before back, redo the
# state after, twice; return the state after.
sub roundtrip {
  my ($name, $code) = @_;
  my $before = state();
  $t->editSeparator;
  $code->();
  my $after = state();
  isnt($after, $before, "$name: changes something");
  $t->editUndo;
  is(state(), $before, "$name: undo restores the state before");
  $t->editRedo;
  is(state(), $after, "$name: redo the state after");
  $t->editUndo;
  $t->editRedo;
  is(state(), $after, "$name: and again");
  return $after;
}

# ---------------------------------------------------------------------
# block split
fresh("num\nden\n");
$t->blockInsert('F', '1.0', '2.3');
$t->editReset;
is(text(), '{num|den}', 'a fraction');
roundtrip('split at level 0', sub { $t->blockSplit('1.2', 0) });
is(text(), '{n|um|den}', 'the leaf is split');
$t->editUndo;
roundtrip('split at level 1', sub { $t->blockSplit('1.6', 1) });
is_deeply(($t->blockAt('1.0'))[4], [[3, 1], [2]], 'a node more');
$t->editUndo;
$t->blockNodedata('1.2', -1, V->new('root'));
$t->blockNodedata('1.2', 0, V->new('num'));
$t->editReset;
roundtrip('split adding levels above the root', sub { $t->blockSplit('1.6', 3) });
is(nv('1.2', -1), 'root', 'the root value moved to the new root');
is_deeply(freed { $t->editUndo }, [], 'undo frees nothing');
is_deeply(($t->blockAt('1.0'))[4], [3, 3], 'the levels added are gone');
is(nv('1.2', -1), 'root', 'the root keeps its value');
is(nv('1.2', 0), 'num', 'and the leaf');
roundtrip('split outside blocks', sub { $t->blockSplit('2.0', 1) });

# ---------------------------------------------------------------------
# block insert
fresh("abcdef\nghi\n");
roundtrip('block insert in a line', sub { $t->blockInsert('G', '1.1', '1.4') });
fresh("abcdef\nghi\n");
$t->tagAdd('b', '1.0', '1.3');
$t->editReset;
roundtrip('block insert over lines', sub { $t->blockInsert('G', '1.2', '2.1') });
fresh("abcdef\nghi\n");
roundtrip('block insert of an empty block', sub { $t->blockInsert('F', '1.3') });
roundtrip('block insert of an -empty block', sub { $t->blockInsert('E', '1.3') });

# Inside a block: leaves moved whole keep their values, which the undo
# gives back to the leaves of the enclosing block; the merge of the
# leaves left on both sides is undone.
fresh("aa\nbb\ncc\ndd\nee\n");
$t->blockInsert('F', '1.0', '5.2');	# {aa|bb|cc|dd|ee}
$t->editReset;
my %pos = (aa => '1.1', bb => '1.4', cc => '1.7', dd => '1.10', ee => '1.13');
$t->blockNodedata($pos{$_}, 0, V->new($_)) for keys %pos;
$t->editReset;
roundtrip('block insert over whole leaves', sub { $t->blockInsert('G', '1.4', '1.12') });
is(text(), '{aa|{bb|cc|dd}|ee}', 'the leaves are in the new block');
is(nv('1.8', 0), 'cc', 'with their values');
is_deeply(freed { $t->editUndo }, [], 'undo frees nothing');
is(join(',', map { nv($pos{$_}, 0) } qw(aa bb cc dd ee)), 'aa,bb,cc,dd,ee',
   'every leaf has its value back');
$t->editRedo;
$t->editUndo;
roundtrip('block insert cutting leaves', sub { $t->blockInsert('G', '1.5', '1.11') });
is(text(), '{aa|b{b|cc|d}d|ee}', 'cut leaves');
is(nv('1.4', 0), 'bb', 'the joined leaf keeps the first value');
$t->editUndo;
is(join(',', map { nv($pos{$_}, 0) } qw(aa bb cc dd ee)), 'aa,bb,cc,dd,ee',
   'undo: every leaf has its value back');
$t->blockNodedata('1.4', 0, undef);
$t->editReset;
roundtrip('block insert cutting leaves, the first without a value', sub { $t->blockInsert('G', '1.5', '1.11') });
is(nv('1.4', 0), 'dd', 'the joined leaf took the value of the last');
$t->editUndo;
ok(!defined nv('1.4', 0), 'undo: the first leaf has none');
is(nv('1.10', 0), 'dd', 'the last has its value back');

# Values and instance data of the new block come back with the redo.
fresh("abcdef\n");
$t->blockInsert('G', '1.1', '1.4');
$t->blockData('1.2', V->new('data'));
$t->blockNodedata('1.2', 0, V->new('leaf'));
$t->blockNodedata('1.2', -1, V->new('root'));
is_deeply(freed { $t->editUndo }, [], 'undo of block insert keeps the values and data of the block');
is(text(), 'abcdef', 'the block is gone');
is_deeply(freed { $t->editRedo }, [], 'redo');
is(text(), 'a{bcd}ef', 'the block is back');
is(nv('1.2', 0) . ',' . nv('1.2', -1), 'leaf,root', 'with its values');
is($t->blockData('1.2')->{n}, 'data', 'and its instance data');
my $f = freed { $t->editUndo; $t->editReset };
is_deeply([sort @$f], [qw(data leaf root)], 'edit reset frees them');

# Over several nodes of the enclosing block: the block insert flattens
# the separators of its range, and its undo gives each of them, and the
# one after the range, its level back; the nodes come back with their
# values (BUGS 18: they came back as children of the first node, and
# the values of the nodes emptied were freed).  The manual's example
# {ab|cd|ef|gh} with the nodes (ab cd) and (ef gh), and {ab|cd|ef} with
# three nodes, as in the investigation's reproducer; then a tree of
# three levels, {ab|cd|ef|gh|ij} with the nodes ((ab cd)) ((ef gh) (ij)).
sub struct { my @b = $t->blockAt('1.0'); return $b[4] }
sub leafvalues {
  my ($levels, @pos) = @_;
  for my $p (@pos) {
    (my $n = $t->get($p, "$p +2c")) =~ s/\W//g;
    for my $l (0 .. $levels) {
      $t->blockNodedata($p, $l, V->new("$l:$n")) unless defined $t->blockNodedata($p, $l);
    }
  }
}
fresh("abcdefgh\n");
$t->blockInsert('F', '1.0', '1.8');
$t->blockSplit('1.5', 1);
$t->blockSplit('1.3', 0);
$t->blockSplit('1.9', 0);			# {ab|cd|ef|gh}
is_deeply(struct(), [[2, 2], [2, 2]], 'two nodes of two leaves');
leafvalues(1, qw(1.1 1.4 1.7 1.10));
$t->editReset;
my $orig = state();
roundtrip('block insert over two nodes', sub { $t->blockInsert('G', '1.2', '1.9') });
is(text(), '{a{b|cd|ef}|gh}', 'the manual\'s example');
is_deeply(freed { $t->editUndo }, [], 'its undo frees nothing');
is_deeply(struct(), [[2, 2], [2, 2]], 'the nodes are back');
is(join(',', map { nv($_, 1) } qw(1.1 1.4 1.7 1.10)), '1:ab,1:ab,1:ef,1:ef',
   'with their values');
is(state(), $orig, 'all of it');

fresh("abcdef\n");
$t->blockInsert('F', '1.0', '1.6');
$t->blockSplit('1.3', 1);
$t->blockSplit('1.6', 1);			# {ab|cd|ef}
is_deeply(struct(), [[2], [2], [2]], 'three nodes');
leafvalues(1, qw(1.1 1.4 1.7));
$t->editReset;
roundtrip('block insert emptying two nodes', sub { $t->blockInsert('G', '1.2', '1.8') });
is(text(), '{a{b|cd|e}f}', 'one node left');
is_deeply(freed { $t->editUndo }, [], 'its undo frees nothing');
is_deeply(struct(), [[2], [2], [2]], 'the three nodes are back');
is(join(',', map { nv($_, 1) } qw(1.1 1.4 1.7)), '1:ab,1:cd,1:ef', 'with their values');

for my $case (['1.2', '1.11', 'from inside a leaf to inside one, across levels 0 to 2'],
	      ['1.1', '1.14', 'from the start of the first leaf into the last'],
	      ['1.4', '1.12', 'over whole leaves'],
	      ['1.7', '1.15', 'from a leaf start to the tail'],
	      ['1.5', '1.8', 'over the separator of level 2 only']) {
  my ($i1, $i2, $what) = @$case;
  fresh("abcdefghij\n");
  $t->blockInsert('F', '1.0', '1.10');
  $t->blockSplit('1.3', 0);
  $t->blockSplit('1.6', 2);
  $t->blockSplit('1.9', 0);
  $t->blockSplit('1.12', 1);			# {ab|cd|ef|gh|ij}
  is_deeply(struct(), [[[2, 2]], [[2, 2], [2]]], "three levels ($what)");
  leafvalues(2, qw(1.1 1.4 1.7 1.10 1.13));
  $t->editReset;
  $orig = state();
  roundtrip("block insert $what", sub { $t->blockInsert('G', $i1, $i2) });
  is_deeply(freed { $t->editUndo }, [], "block insert $what: its undo frees nothing");
  is(state(), $orig, "block insert $what: the nodes and values are back");
}

# ---------------------------------------------------------------------
# block trim
for my $case ([qw(R C)], ['R', undef], [undef, 'C'], [undef, undef]) {
  my ($r, $c) = @$case;
  my $name = 'trim, root ' . ($r ? 'with' : 'without') . ' a value, child ' . ($c ? 'with' : 'without');
  fresh("num\nden\n");
  $t->blockInsert('F', '1.0', '2.3');
  $t->blockSplit('1.6', 2);			# a root above, two nodes below it
  $t->delete('1.6');				# root - node - leaves
  $t->blockNodedata('1.2', -1, V->new($r)) if $r;
  $t->blockNodedata('1.2', -2, V->new($c)) if $c;
  $t->editReset;
  roundtrip($name, sub { $t->blockTrim('1.2') });
  is_deeply(freed { $t->editUndo }, [], "$name: undo frees nothing");
  is((nv('1.2', -1) // '-') . ',' . (nv('1.2', -2) // '-'), ($r // '-') . ',' . ($c // '-'),
     "$name: the values are back where they were");
}

# The root's value set or unset between the undo and the redo of a trim:
# the redo decides again whether the root has one.
for my $case (['set', undef, 'U', 'U,C'], ['unset', 'R', undef, '-,C']) {
  my ($what, $r, $after, $want) = @$case;
  fresh("num\nden\n");
  $t->blockInsert('F', '1.0', '2.3');
  $t->blockSplit('1.6', 2);
  $t->delete('1.6');
  $t->blockNodedata('1.2', -1, V->new($r)) if $r;
  $t->blockNodedata('1.2', -2, V->new('C'));
  $t->editReset;
  $t->blockTrim('1.2');
  $t->editUndo;
  $t->blockNodedata('1.2', -1, $after ? V->new($after) : undef);
  my $before = state();
  $t->editRedo;
  $t->editUndo;
  is(state(), $before, "trim, the root's value $what after the undo: redo and undo give the state back");
  is((nv('1.2', -1) // '-') . ',' . (nv('1.2', -2) // '-'), $want, "trim, root value $what: the values are where they were");
}

# ---------------------------------------------------------------------
# tag add and tag remove
fresh("abcdefghij\nklmnop\n");
$t->tagAdd('b', '1.1', '1.3', '1.6', '1.8', '2.2', '2.4');
$t->tagAdd('c', '1.0', '2.0');
$t->editReset;
roundtrip('tag add over gaps', sub { $t->tagAdd('b', '1.2', '2.3') });
roundtrip('tag remove', sub { $t->tagRemove('b', '1.2', '1.7') });
roundtrip('tag add of a new tag', sub { $t->tagAdd('n', '1.0', '1.5') });
$t->tagDelete('n');
$t->editReset;

# Values: losers of a merge, a run moved, a run shortened, a run gone.
fresh("abcdefghij\nklmnop\n");
$t->tagAdd('b', '1.1', '1.3', '1.6', '1.8');
$t->editReset;
$t->tagData('b', '1.1', V->new('x'));
$t->tagData('b', '1.6', V->new('y'));
$t->editReset;
is_deeply(freed { $t->tagAdd('b', '1.2', '1.7') }, [], 'a merge: the loser is kept for the undo');
is(rv('b', '1.6'), 'x', 'the merged run has the left value');
is_deeply(freed { $t->editUndo }, [], 'undo');
is(rv('b', '1.1') . ',' . rv('b', '1.6'), 'x,y', 'both runs have their values');
$t->tagData('b', '1.1', undef);
$t->editReset;
$t->tagAdd('b', '1.2', '1.7');
is(rv('b', '1.1'), 'y', 'a merge, the left run without a value: the right value');
$t->editUndo;
ok(!defined rv('b', '1.1'), 'undo: the left run has none');
is(rv('b', '1.6'), 'y', 'the right one its own');
is_deeply(freed { $t->tagAdd('b', '1.0', '1.7') }, [], 'a run extended at its start');
$t->editUndo;
is(rv('b', '1.6'), 'y', 'undo: the value stays with the run');
is_deeply(freed { $t->tagRemove('b', '1.5', '1.9') }, [], 'a run removed: its value is kept');
ok(!$t->tagNames('1.6'), 'the run is gone') or diag($t->tagNames('1.6'));
$t->editUndo;
is(rv('b', '1.6'), 'y', 'undo: it is back with its value');
is_deeply(freed { $t->tagRemove('b', '1.5', '1.9'); $t->editReset }, ['y'],
	  'edit reset frees what the step kept');

# The selection is not recorded; nor is a change that changes nothing.
fresh("abcdef\n");
$t->insert('1.0', 'X');
$t->tagAdd('sel', '1.0', '1.3');
$t->tagRemove('sel', '1.0', 'end');
$t->tagRemove('b', '1.0', 'end');
$t->editUndo;
is(text(), 'abcdef', 'tag add and remove of sel, and a tag remove that removes nothing, are not undone');

# A tag add or remove over an empty range (tag add b end) changes
# nothing: no undo step, the modified flag unchanged.
fresh("abc\n");
$t->insert('1.0', 'X');
$t->editSeparator;
$t->editModified(0);
$t->tagAdd('b', 'end');
$t->tagAdd('b', '1.2', '1.2');
$t->tagRemove('b', 'end');
ok(!$t->editModified, 'tag add and remove over an empty range do not modify');
$t->editUndo;
is(text(), 'abc', 'and make no undo step (the undo takes back the insertion)');

# ---------------------------------------------------------------------
# Edit kinds: each of these is a kind of its own (-autoseparators):
# a change of kind starts a new step, a run of the same kind is one.
fresh("abcdef\n");
$t->insert('1.0', 'X');
$t->tagAdd('b', '1.0', '1.2');
$t->tagAdd('b', '1.3', '1.4');
$t->blockInsert('F', '1.5');
$t->editUndo;
is(text(), 'Xabcdef', 'undo takes back the block insert alone');
is(join(' ', $t->tagRanges('b')), '1.0 1.2 1.3 1.4', 'not the tags');
$t->editUndo;
is(join(' ', $t->tagRanges('b')), '', 'the two tag adds are one step');
is(text(), 'Xabcdef', 'the insertion is another');
$t->editUndo;
is(text(), 'abcdef', 'which comes last');
$t->configure(-autoseparators => 0);
$t->insert('1.0', 'X');
$t->tagAdd('b', '1.0', '1.2');
$t->blockSplit('1.3');
$t->editUndo;
is(text() . '|' . join(' ', $t->tagRanges('b')), 'abcdef|', 'without -autoseparators, one step');
$t->configure(-autoseparators => 1);

# Without -undo too, tag add and remove count for the modified flag
# (not those of sel, nor those that change nothing).
{
  my $u = $mw->eText(-undo => 0)->pack;
  $u->insert('1.0', "abcdef\n");
  $u->editModified(0);
  $u->tagAdd('sel', '1.0', '1.2');
  $u->tagAdd('b', '1.0', '1.0');
  ok(!$u->editModified, '-undo 0: tag add of sel or of nothing does not modify');
  $u->tagAdd('b', '1.0', '1.3');
  ok($u->editModified, '-undo 0: tag add modifies');
  $u->editModified(0);
  $u->tagAdd('b', '1.1', '1.2');
  ok(!$u->editModified, '-undo 0: tag add where the tag is does not');
  $u->tagRemove('b', '1.0', '1.3');
  ok($u->editModified, '-undo 0: tag remove modifies');
  $u->tagAdd('b', '1.0', '1.2', '1.4', '1.6');
  $u->editModified(0);
  $u->tagRemove('b', '1.2', '1.4');
  ok(!$u->editModified, '-undo 0: tag remove where the tag is not does not');
  $u->tagAdd('b', '1.0', '1.6');
  ok($u->editModified, '-undo 0: tag add over a gap modifies (tagged at the start)');
  $u->editModified(0);
  $u->tagRemove('b', '1.0', '1.6');
  $u->tagAdd('b', '1.3', '1.4');
  $u->editModified(0);
  $u->tagRemove('b', '1.0', '1.5');
  ok($u->editModified, '-undo 0: tag remove of a run inside (untagged at the start) modifies');
  $u->editModified(0);
  $u->tagAdd('b', '1.0', '1.2');
  $u->tagAdd('c', '1.2', '1.3');
  $u->editModified(0);
  $u->tagAdd('b', '1.0', '1.2');
  $u->tagRemove('c', '1.0', '1.2');
  ok(!$u->editModified, '-undo 0: a toggle at the end of the range does not count');
  $u->destroy;
}

# The modified flag follows these changes and their undo.
fresh("abcdef\n");
$t->editModified(0);
$t->blockInsert('F', '1.1', '1.3');
ok($t->editModified, 'block insert modifies');
$t->editUndo;
ok(!$t->editModified, 'its undo takes it back');
$t->tagAdd('b', '1.1', '1.3');
ok($t->editModified, 'tag add modifies');
$t->editUndo;
ok(!$t->editModified, 'its undo takes it back');

# A deletion through the end of the text takes the tags off the final
# newline that stays; the undo puts them back.
fresh("abc\ndef\n");
$t->tagAdd('b', '1.1', 'end');
$t->editReset;
my $before = state();
$t->delete('1.2', 'end');
$t->editUndo;
is(state(), $before, 'undo of a deletion to the end restores the tags of the final newline');

# A redo that the command would refuse does nothing: a block type made
# -empty since the undo is not re-created over contents (that crashed).
$t->blockConfigure('H');
fresh("abcdef\n");
$t->blockInsert('H', '1.1', '1.4');
$t->blockData('1.2', V->new('hdata'));
$t->editUndo;
$t->blockConfigure('H', -empty => 1);
is_deeply(freed { $t->editRedo }, [], 'redo of block insert of a type made -empty: nothing freed');
is(text(), 'abcdef', 'and no block made');
$mw->update;
ok(1, 'the display survives it');
is_deeply(freed { $t->editReset }, ['hdata'], 'the kept instance data is freed with the step');

# ---------------------------------------------------------------------
# The instance data of the blocks a deletion deletes or dissolves goes
# into the undo step as a record (the step's block list leaves it out),
# addressed by the block's head: the undo gives the same container back
# to the block it re-creates, the redo takes it again, and discarding
# the step frees it.  Also for a block left in the remains of a cut
# block (the undo takes the remains out and puts the list in).
sub bd {
  my $v = eval { $t->blockData($_[0]) };
  defined $v ? (ref $v ? $v->{n} : $v) : '-';
}
sub withdata {
  fresh("ab cdefg hi\n");
  $t->blockInsert('F', '1.3', '1.8');
  $t->blockInsert('G', '1.5', '1.7');
  $t->blockInsert('E', '1.1');		# a.b {c{de}fg} hi
  $t->blockData('1.1', V->new('E'));
  $t->blockData('1.5', V->new('F'));
  $t->blockData('1.7', V->new('G'));
  $t->editReset;
}
sub alldata { join ',', map { bd($_) } qw(1.1 1.5 1.7) }
sub instancedata {		# the names of the instance data in a block list
  map {
    my $e = $_;
    ref($e) =~ /::Empty$/ ? (ref $e->[1] ? $e->[1]{n} : ())
      : ref($e) =~ /::Block$/ ? ((ref $e->[0][2] ? $e->[0][2]{n} : ()),
				 instancedata(@$e[1 .. $#$e]))
      : ();
  } @_;
}
for my $case (['1.0', '1.4', 'an empty block'],
	      ['1.3', '1.14', 'a block and the one nested in it'],
	      ['1.6', '1.14', 'a nested block, the enclosing one cut (dissolved)'],
	      ['1.11', '1.14', 'the tail of a block, a nested one in its remains'],
	      ['1.0', '1.6', 'the head of a block, a nested one in its remains']) {
  my ($i1, $i2, $what) = @$case;
  withdata();
  is(text() . ' ' . alldata(), 'a.b {c{de}fg} hi E,F,G', "deleting $what: the blocks and their data");
  my @at = qw(1.1 1.5 1.7);
  my @objects = map { scalar $t->blockData($_) } @at;
  is_deeply(freed { roundtrip("deleting $what", sub { $t->delete($i1, $i2) }) }, [],
	    "deleting $what: undo and redo free nothing");
  $t->editUndo;
  is(alldata(), 'E,F,G', "deleting $what: undo gives the data back");
  ok(!grep({ $objects[$_] != $t->blockData($at[$_]) } 0 .. 2),
     "deleting $what: the same objects");
  @objects = ();
  $t->editRedo;
  my %kept = map { $_ => 1 } qw(E F G);
  delete $kept{$_} for instancedata($t->blockList('1.0', 'end'));
  my $gone = freed { $t->editReset };
  is_deeply([sort @$gone], [sort keys %kept],
	    "deleting $what: edit reset frees what the step kept");
}

# The redo of an insertion re-inserts it from a block list taken when it
# was undone: a block found in the inserted range then (made here with
# -undo off) gets its instance data back from the step.
fresh("ab\n");
$t->insert('1.1', 'XY');
$t->configure(-undo => 0);
$t->blockInsert('E', '1.2');		# aXEYb: the insertion was 1.1-1.3
$t->blockData('1.2', V->new('ins'));
$t->configure(-undo => 1);
my $object = $t->blockData('1.2');
is_deeply(freed { $t->editUndo }, [], 'undo of an insertion holding a block: nothing freed');
is(text(), 'aYb', 'the insertion is undone');
is_deeply(freed { $t->editRedo }, [], 'its redo: nothing freed');
is(text(), 'aX.Yb', 'the block is back');
is(bd('1.2'), 'ins', 'with its instance data');
ok($t->blockData('1.2') == $object, 'the same object');
undef $object;
$t->editUndo;
is_deeply(freed { $t->editReset }, ['ins'], 'discarding the step frees it');

# A value set, after a deletion that dissolved a block, on a leaf made of
# what was left of the block: the undo takes the remains out and finds
# no such leaf in the text it restores.  The value waits in the step,
# and the redo gives it back (BUGS 26: it was freed).
fresh("poo\n");
$t->blockInsert('F', '1.0', '1.3');
$t->blockSplit('1.2', 0);
$t->blockSplit('1.1', 0);
$t->blockInsert('G', '1.1', '1.5');
is(text(), '{{|p|o}o}', 'a block in a block');
$t->editReset;
$t->delete('1.5', '1.8');		# dissolves G
is(text(), '{|p|}', 'the inner block dissolved');
$t->blockNodedata('1.4', 0, V->new('later'));
is_deeply(freed { $t->editUndo }, [], 'the undo frees nothing');
is_deeply(freed { $t->editRedo }, [], 'nor the redo');
is(nv('1.4', 0), 'later', 'which gives the value back');
$t->blockNodedata('1.4', 0, undef);
$t->editReset;

is_deeply(freed { $t->destroy; $mw->update }, [], 'nothing left');
$mw->destroy;
