#!/usr/bin/perl
# dump looks into blocks: text, marks, tags, windows and images inside a
# block are reported with external indices, between "block" and
# "blockend" elements.
use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require Tk; 1 } or plan skip_all => "Tk not available: $@";
}
use Tk::eText;

my $mw = eval { MainWindow->new };
plan skip_all => "no X display available ($@)" unless $mw;
plan tests => 31;
$mw->geometry('+10+10');

my $w = $mw->eText(-width => 30, -height => 8)->pack;
$w->blockConfigure('Std');
$w->insert('end', "ab cdefgh ij\nsecond\n");
$w->blockInsert('Std', '1.3', '1.9');		# {cdefgh}
$w->tagAdd('t', '1.5', '1.7');			# inside the block
$w->markSet('m', '1.6');
$mw->update;
is($w->get('1.0', '1.end'), 'ab {cdefgh} ij', 'the layout');

sub triples { my @d = @_; my @t; push @t, [splice @d, 0, 3] while @d; @t }
my @all = triples($w->dump('-all', '1.0', 'end'));
is(join('', map { $_->[1] } grep { $_->[0] eq 'text' } @all), "ab cdefgh\n ij\nsecond\n\n",
   'dump -text reports the text inside the block too (the block ends with its newline)');
my @inside = grep { $_->[2] =~ /^1\.[3-9]$/ } @all;
is(join(' ', map { "$_->[0]:$_->[1]\@$_->[2]" } @inside),
   "block:Std\@1.3 text:c\@1.4 tagon:t\@1.5 text:d\@1.5 mark:m\@1.6 text:e\@1.6 tagoff:t\@1.7 text:fgh\n\@1.7",
   'elements inside the block with external indices');
my ($blk) = grep { $_->[0] eq 'block' } @all;
my ($end) = grep { $_->[0] eq 'blockend' } @all;
is("$blk->[1] $blk->[2] $end->[1] $end->[2]", 'Std 1.3 Std 1.11', 'block and blockend elements');
my $bad = 0;
for my $t (@all) { $bad++ if $w->index($t->[2]) ne $t->[2] }
is($bad, 0, 'all indices round-trip');
is_deeply([$w->dump('-mark', '1.0', 'end')], ['mark', 'current', '1.0', 'mark', 'm', '1.6', 'mark', 'insert', '3.0'],
	  'dump -mark finds the mark inside the block');
is_deeply([$w->dump('-tag', '1.0', 'end')], ['tagon', 't', '1.5', 'tagoff', 't', '1.7'],
	  'dump -tag finds the toggles inside the block');
is_deeply([$w->dump('-block', '1.0', 'end')], ['block', 'Std', '1.3', 'blockend', 'Std', '1.11'],
	  'dump -block');
is_deeply([$w->dump('-text', '1.5', '1.8')], ['text', 'd', '1.5', 'text', 'e', '1.6', 'text', 'f', '1.7'],
	  'a range inside the block');
is_deeply([$w->dump('-text', '-block', '1.2', '1.6')], ['text', ' ', '1.2', 'block', 'Std', '1.3', 'text', 'c', '1.4', 'text', 'd', '1.5'],
	  'a range starting outside and ending inside (no blockend)');
is_deeply([$w->dump('-text', '-block', '1.6', '1.13')], ['text', 'e', '1.6', 'text', "fgh\n", '1.7', 'blockend', 'Std', '1.11', 'text', ' i', '1.11'],
	  'a range starting inside and ending outside (no block)');
my @cb;
$w->dump('-all', -command => sub { push @cb, [@_] }, '1.3', '1.8');
is(join(' ', map { "$_->[0]\@$_->[2]" } @cb), 'block@1.3 text@1.4 tagon@1.5 text@1.5 mark@1.6 text@1.6 tagoff@1.7 text@1.7',
   'dump -command gets the same elements');

# Nested blocks, an image inside, the end of the text.
$w->blockInsert('Std', '1.6', '1.8');			# {cd{ef}gh}
my $img = $w->imageCreate('1.7', -image => $mw->Photo(-width => 3, -height => 3));
$mw->update;
is($w->get('1.0', '1.end'), 'ab {cd{ef}gh} ij', 'nested layout');
@all = triples($w->dump('-all', '1.0', '2.0'));
is(join(' ', map { "$_->[0]:$_->[1]\@$_->[2]" } grep { $_->[0] =~ /block|image/ } @all),
   "block:Std\@1.3 block:Std\@1.6 image:$img\@1.7 blockend:Std\@1.11 blockend:Std\@1.14",
   'nested blocks and an image inside them');
is(join('', map { $_->[1] } grep { $_->[0] eq 'text' } @all), "ab cdef\ngh\n ij\n",
   'text of nested blocks (each block ends with its newline)');
is_deeply([$w->dump('-image', '1.0', 'end')], ['image', $img, '1.7'], 'dump -image finds the image inside the blocks');
my @e = $w->dump('-all', '2.0', 'end');
is(join(' ', map { $e[3 * $_] . '@' . $e[3 * $_ + 2] } 0 .. $#e / 3), 'text@2.0 mark@3.0 text@3.0', 'the end of the text, as Tk::Text reports it');
$w->destroy;
# dump -values: a fourth field in every entry, the value of a mark or of
# the run a tagon starts (a copy), undef for everything else.
{
  my $v = $mw->eText(-width => 30, -height => 4)->pack;
  $v->blockConfigure('Std');
  $v->insert('end', "abcdef\nxy\n");
  $v->tagAdd('t', '1.1', '1.3', '1.4', '1.5');
  $v->tagData('t', '1.4', {run => 2});
  $v->markSet('m', '1.2');
  $v->markData('m', 'mv');
  $v->markSet('n', '1.3');
  my @plain = $v->dump('-all', '1.0', '1.end');
  sub quads { my @d = @_; my @q; push @q, [splice @d, 0, 4] while @d; @q }
  my @q = quads($v->dump('-all', '-values', '1.0', '1.end'));
  is(scalar(@q) * 3, scalar(@plain), 'dump -values: as many entries as without it');
  is_deeply([map { [@$_[0 .. 2]] } @q], [triples(@plain)], 'the same first three fields');
  my %val = map { ("$_->[0] $_->[1] $_->[2]" => $_->[3]) } @q;
  is($val{'mark m 1.2'}, 'mv', 'a mark with a value has it as the fourth field');
  ok(exists $val{'mark n 1.3'} && !defined $val{'mark n 1.3'}, 'a mark without one has undef');
  is_deeply($val{'tagon t 1.4'}, {run => 2}, 'the tagon of a run with a value has it');
  ok(!defined $val{'tagon t 1.1'}, 'a run without one has undef');
  ok(!defined $val{'tagoff t 1.3'} && !defined $val{'text a 1.0'}, 'tagoff and text entries have undef');
  is_deeply([$v->dump('-values', '1.0', '1.end')], [$v->dump('-all', '-values', '1.0', '1.end')],
	    '-values alone means -all -values');
  is_deeply([$v->dump('-mark', '-values', '1.2', '1.4')], ['mark', 'm', '1.2', 'mv', 'mark', 'n', '1.3', undef],
	    'dump -mark -values');
  my @cb;
  $v->dump('-tag', '-mark', '-values', -command => sub { push @cb, [@_] }, '1.0', '1.end');
  is_deeply([map { [$_->[0], $_->[1], $_->[2], (ref $_->[3] ? $_->[3]{run} : $_->[3])] } @cb],
	    [['tagon', 't', '1.1', undef], ['mark', 'm', '1.2', 'mv'], ['tagoff', 't', '1.3', undef],
	     ['mark', 'n', '1.3', undef], ['tagon', 't', '1.4', 2], ['tagoff', 't', '1.5', undef]],
	    'dump -values -command: the callback gets the value as a fourth argument');
  @cb = ();
  $v->dump('-tag', -command => sub { push @cb, scalar @_ }, '1.0', '1.end');
  is_deeply(\@cb, [3, 3, 3, 3], 'without -values, three arguments as before');
  # Inside a block, and a node value is not reported.
  $v->blockInsert('Std', '2.0', '2.2');
  $v->blockNodedata('2.1', 0, 'leaf');
  $v->markSet('in', '2.2');
  $v->markData('in', 'iv');
  my @b = quads($v->dump('-values', '2.0', '2.end'));
  is_deeply([map { "$_->[0]:" . ($_->[3] // '-') } @b],
	    ['block:-', 'text:-', 'mark:iv', 'text:-', 'blockend:-'],
	    'a mark inside a block has its value; the block entries have none');
  ok(!eval { $v->dump('-x', '1.0'); 1 }, 'an unknown option is an error');
  like($@, qr/-values\?/, 'the usage names -values');
  $v->destroy;
}

$mw->destroy;
