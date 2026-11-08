#!/usr/bin/perl
# Basic, non-interactive exercise of the Tk::eText widget.
use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require Tk; 1 } or plan skip_all => "Tk not available: $@";
}
use Tk::eText;

my $mw = eval { MainWindow->new };
plan skip_all => "no X display available ($@)" unless $mw;
plan tests => 49;

$mw->geometry('+10+10');
my $t = $mw->eText(-width => 40, -height => 10, -wrap => 'word')->pack;
isa_ok($t, 'Tk::eText');
isa_ok($t, 'Tk::Text');
is($t->class, 'EText', 'widget class');
is($t->PathName, '.etext', 'path name');

# Plain text widget behaviour.
$t->insert('end', "Hello, world\nSecond line\n");
$mw->update;
is($t->index('end'), '4.0', 'index end');
is($t->get('1.0', 'end'), "Hello, world\nSecond line\n\n", 'get');
is($t->index('1.0 lineend'), '1.12', 'index arithmetic');
is($t->compare('1.0', '<', '2.0'), 1, 'compare');
my @bbox = $t->bbox('1.4');
is(scalar(@bbox), 4, 'bbox returns 4 numbers');
cmp_ok($bbox[2], '>', 0, 'bbox width positive');
my @dli = $t->dlineinfo('1.0');
is(scalar(@dli), 5, 'dlineinfo returns 5 numbers');
$t->tagConfigure('red', -foreground => 'red', -underline => 1);
$t->tagAdd('red', '1.0', '1.5');
is_deeply([$t->tagRanges('red')], ['1.0', '1.5'], 'tag ranges');
is_deeply([$t->tagNames('1.2')], ['red'], 'tag names at index');
$t->markSet('insert', '1.4');
is($t->index('insert'), '1.4', 'mark set');
is($t->search('line', '1.0'), '2.7', 'exact search');
is($t->search('-regexp', 'w.r', '1.0'), '1.7', 'regexp search');
is($t->search('-nocase', 'HELLO', '1.0'), '1.0', 'nocase search');
my @dump = $t->dump('1.0', '1.3');
ok((grep { $_ eq 'text' } @dump), 'dump reports text');
$mw->update;

# Blocks.
is_deeply([$t->blockNames], [], 'no block types yet');
$t->blockConfigure('Std');
is_deeply([$t->blockNames], ['Std'], 'block type created');
my @conf = $t->blockConfigure('Std');
cmp_ok(scalar(@conf), '>=', 4, 'block configure returns option list');
is(scalar($t->blockCget('Std', '-layoutdepth')), -1, 'block cget');

$t->blockInsert('Std', '1.2', '1.7');
$mw->update;
is($t->get('1.0', 'end'), "He{llo, }world\nSecond line\n\n",
   'block boundaries appear as braces in string representation');
is($t->index('end'), '4.0', 'line count unchanged by block');
ok(!defined($t->blockAt('1.3')), 'block at: not a block start');
my @of = $t->blockOf('1.3');
is($of[0], '1.2', 'block of: start index');
is($of[1], 7, 'block of: length in index space');
is($of[2], 'Std', 'block of: type');
is_deeply($of[4], [5], 'block of: structure (one leaf of 5 chars)');
my @at = $t->blockAt('1.2');
is($at[2], 'Std', 'block at: block start');

my @list = $t->blockList('1.0', 'end');
my @types = map { ref($_) || 'STRING' } @list;
like($types[0], qr/^Tk::Text::Mark(Left|Right)$/, 'list: current mark')
  or diag "@types";
ok((grep { $_ eq 'Tk::Text::Block' } @types), 'list: a block object');
ok((grep { $_ eq 'Tk::Text::NewLine' } @types), 'list: newline objects');
my ($block) = grep { ref $_ eq 'Tk::Text::Block' } @list;
is($block->[0][0], 'Std', 'block object carries its type');
is(join('', map { ref $_ eq 'Tk::Text::String' ? ${$_} : '' } @{$block}[1..$#$block]),
   'llo, ', 'block object carries its contents');
ok((grep { ref $_ eq 'Tk::Text::TagOff' } @{$block}[1..$#$block]),
   'block object carries the tag toggle inside it');

# Splitting, trimming, instance data.
$t->markSet('insert', '1.4');
$t->blockSplit('insert', 0);
$mw->update;
is($t->get('1.0', 'end'), "He{l|lo, }world\nSecond line\n\n",
   'block split 0: leaf separator shows as |');
$t->blockSplit('1.4', 1);
$mw->update;
my @of2 = $t->blockOf('1.3');
is($of2[1], 9, 'block split 1 extends the tree');
$t->blockData('1.3', 'payload');
is($t->blockData('1.3'), 'payload', 'block instance data');

# Layout callback.
my $calls = 0;
my @args;
$t->blockConfigure('Frac', -layoutdepth => 1, -layoutwidths => [2],
		   -layoutcmd => sub {
		     my ($data, $x, $super, $sub) = @_;
		     $calls++;
		     @args = @_;
		     my $w = $super->[2] > $sub->[2] ? $super->[2] : $sub->[2];
		     my $h = $super->[4] + 2 + $sub->[4];
		     return ([-1, 0, 0, $w, $w, $h, $super->[4] + 1],
			     [$super->[0], 0, 0, $super->[2], $super->[2],
			      $super->[4], $super->[5]],
			     [$sub->[0], 0, $super->[4] + 2, $sub->[2], $sub->[2],
			      $sub->[4], $sub->[5]]);
		   });
$t->insert('end', "num\nden\n");
$t->blockInsert('Frac', '4.0', '5.3');
$mw->update;
cmp_ok($calls, '>=', 1, 'layout callback was called');
is($args[0][0], 'Frac', 'layout callback: block name');
is($args[0][1], $t, 'layout callback: widget');
is(scalar(@args), 4, 'layout callback: two leaves');
is($args[2][0], 1, 'layout callback: leaf repeat count');
is($t->index('end'), '5.0', 'fraction occupies one line');

# Deleting through block boundaries and destroying the widget.
$t->delete('1.0', 'end');
$mw->update;
is($t->index('end'), '2.0', 'delete all');
is_deeply([$t->blockNames], ['Frac', 'Std'], 'block types survive deletion');
$t->blockDelete('Frac');
is_deeply([$t->blockNames], ['Std'], 'block type deleted');
$t->destroy;
$mw->update;
ok(!Tk::Exists($t), 'widget destroyed');
$mw->destroy;
