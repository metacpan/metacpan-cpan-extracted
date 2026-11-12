#!/usr/bin/perl
# The demo's menu "Ornaments": each entry creates (or removes)
# ornaments of the demo's text widget.
use strict;
use warnings;
use FindBin;
use Test::More;

BEGIN {
  eval { require Tk; 1 } or plan skip_all => "Tk not available: $@";
}
use Tk::eText;

my $probe = eval { MainWindow->new };
plan skip_all => "no X display available ($@)" unless $probe;
# Hidden, not destroyed, until the demo's MainWindow is gone (see
# t/demo.t: TK_BUGS W7).
$probe->withdraw;
plan tests => 17;

our ($text, $top);		# the demo's globals (package main)
my @bgerrors;
{
  no warnings 'redefine';
  *Tk::Error = sub { my ($w, $err, @loc) = @_; push @bgerrors, $err };
}
$SIG{ALRM} = sub { diag("timeout"); exit 1 }; alarm 120;
$0 = "$FindBin::Bin/../demo/etext.pl";

my $menu;			# The menu of the menubutton "Ornaments".
sub find_menu {
  my @todo = ($top);
  while (my $w = shift @todo) {
    return $w->cget('-menu') if $w->isa('Tk::Menubutton') and $w->cget('-text') eq 'Ornaments';
    push @todo, $w->children;
  }
  undef;
}
sub entry { $menu->invoke($_[0]); $top->update }
sub names { [$text->ornamentNames] }
sub select_range { $text->tagRemove('sel', '1.0', 'end'); $text->tagAdd('sel', @_) }

my %ids;
my @steps = (
  sub {
    $menu = find_menu();
    ok($menu, 'the menu bar has "Ornaments"');
    is_deeply([map { $menu->entrycget($_, '-label') }
	       grep { $menu->type($_) eq 'command' } 0 .. $menu->index('last')],
	      ['Box under selection', 'Arrow from mark', 'Brace under selection', 'Remove all'],
	      'its entries');
    $text->delete('1.0', 'end');
    $text->insert('1.0', "The quick brown fox\njumps over the lazy dog\n");
    $top->update;
    is_deeply(names(), [], 'no ornaments at first');
  },
  sub {
    select_range('1.4', '1.9');
    entry('Box under selection');
    is(scalar(@{names()}), 1, 'Box under selection: one ornament');
    my $id = names()->[0];
    is($text->ornamentCget($id, '-layer'), 'under', 'under the text');
    is($text->ornamentCget($id, '-fill') ? 1 : 0, 1, 'filled');
    my @c = $text->ornamentCoords($id);
    my @b = $text->bbox('1.4');
    ok(@c == 4 && $c[0] < $b[0] && $c[1] < $b[1], 'around the selection');
    $ids{box} = $id;
  },
  sub {
    select_range('1.10', '1.15');
    entry('Arrow from mark');
    is(scalar(@{names()}), 1, 'Arrow from mark, first use: no ornament yet');
    is($text->index('ornArrowFrom'), '1.10', 'the origin is a mark at the selection start');
    select_range('2.10', '2.14');
    entry('Arrow from mark');
    my ($arrow) = grep { $_ != $ids{box} } @{names()};
    ok(defined $arrow, 'second use: an arrow');
    is_deeply([map { $text->ornamentCget($arrow, $_) } qw(-arrow -smooth -fill)],
	      ['last', 1, 'red'], 'a smoothed red line with an arrowhead at its end');
    ok(!grep({ $_ eq 'ornArrowFrom' } $text->markNames), 'the origin mark is gone');
    $ids{arrow} = $arrow;
  },
  sub {
    select_range('2.0', '2.5');
    entry('Brace under selection');
    my ($brace) = grep { $_ != $ids{box} && $_ != $ids{arrow} } @{names()};
    ok(defined $brace && $text->ornamentCget($brace, '-smooth'), 'Brace under selection: a smoothed line');
    my @c = $text->ornamentCoords($brace);
    my @b = $text->bbox('2.0');
    my @ys = map { $c[2*$_ + 1] } 0 .. $#c/2;
    ok(!grep({ $_ < $b[1] + $b[3] } @ys), 'under the selection');
    my ($low) = sort { $b <=> $a } @ys;
    my $mid = (sort { $a <=> $b } map { $c[2*$_] } grep { $ys[$_] == $low } 0 .. $#ys)[0];
    my @l = $text->bbox('2.0');
    my @r = $text->bbox('2.4');
    ok(abs($mid - ($l[0] + $r[0] + $r[2]) / 2) <= 1, 'its point is down in the middle');
  },
  sub {
    entry('Remove all');
    is_deeply(names(), [], 'Remove all: no ornaments left');
    is_deeply(\@bgerrors, [], 'no background errors') or diag(@bgerrors);
    $top->destroy;
    $probe->destroy;
  },
);
my $i = 0;
sub step {
  my $s = $steps[$i++];
  eval { $s->(); 1 } or diag("step $i failed: $@");
  $top->after(50, \&step) if $i < @steps and Tk::Exists($top);
}
BEGIN {
  require Tk;
  my $orig = \&Tk::MainLoop;
  no warnings 'redefine';
  *Tk::MainLoop = sub { $top->after(100, \&step); $orig->() };
}
do $0;
diag("demo died: $@") if $@;
