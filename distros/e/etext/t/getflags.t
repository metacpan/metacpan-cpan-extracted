#!/usr/bin/perl
# -getflags: the bits the manual does not document are reserved for the
# widget's own calls and are ignored when a program sets them (BUGS 30).
# Before the fix, bit 0x200 (used by the undo) left the node values out
# of "block list", and bit 0x100 added the undo's leaf defects to it.
use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require Tk; 1 } or plan skip_all => "Tk not available: $@";
}
use Tk::eText;

my $mw = eval { MainWindow->new };
plan skip_all => "no X display available ($@)" unless $mw;
plan tests => 6;

my $t = $mw->eText->pack;
$t->blockConfigure('F');
$t->insert('1.0', "x\nnum\nden\ny\n");
$t->blockInsert('F', '2.0', '3.3');
$t->blockNodedata('2.1', 1, 'R');
$t->blockNodedata('2.1', 0, 'N');

sub header { my ($b) = grep { ref($_) =~ /::Block$/ } $t->blockList('2.0', '2.end');
	     $b->[0] }
my $plain = header();
is_deeply($plain->[3], ['R', ['N'], [undef]], 'node values listed (no flags)');
for my $f (0x100, 0x200, 0x300, 0xff00) {
  $t->configure(-getflags => $f);
  is_deeply(header(), $plain, sprintf('-getflags 0x%x: block list unchanged', $f));
}
$t->configure(-getflags => 0);
is($t->get('2.1', '2.4'), 'num', 'get still works');
