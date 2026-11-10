#!/usr/bin/perl
# Regression tests for the memory leaks fixed in Tk::eText 2.00.
use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require Tk; 1 } or plan skip_all => "Tk not available: $@";
}
use Tk::eText;

my $mw = eval { MainWindow->new };
plan skip_all => "no X display available ($@)" unless $mw;
my $have_lt = eval { require Test::LeakTrace; 1 };
plan tests => 7;
$mw->geometry('+10+10');

{
  package Sentinel;
  sub new { my ($class, $flag) = @_; bless { flag => $flag }, $class }
  sub DESTROY { ${ $_[0]{flag} }++ }
}

# A trivial layout callback: one leaf, laid out as is.
sub layout_cb {
  my ($data, $x, $leaf) = @_;
  return ([-1, 0, 0, $leaf->[2], $leaf->[2], $leaf->[4], $leaf->[5]],
	  [$leaf->[0], 0, 0, $leaf->[2], $leaf->[2], $leaf->[4], $leaf->[5]]);
}

sub make_widget {
  my $t = $mw->eText(-width => 30, -height => 5)->pack;
  $t->blockConfigure('B', -layoutdepth => 1, -layoutwidths => [1],
		     -layoutcmd => \&layout_cb);
  $t->insert('end', "abc\ndef\n");
  $t->blockInsert('B', '1.1', '1.2');
  $t->markSet('insert', '1.2');		# cursor inside the block
  $mw->update;
  return $t;
}

# Moving the insertion cursor (and its blinking) re-lays-out the display
# line it is on; when that line holds a block, the layout callback runs.
sub relayouts {
  my ($t, $n) = @_;
  for my $i (1 .. $n) {
    $t->markSet('insert', '1.' . ($i % 3));
    $mw->update;
  }
}

# 1. Every invocation of the layout callback used to hand the callback an
#    extra reference to the widget object that was never released, so the
#    widget's Perl object (and whatever it holds) could never be freed.
{
  my $destroyed = 0;
  my $t = make_widget();
  $t->{sentinel} = Sentinel->new(\$destroyed);
  relayouts($t, 20);
  $t->destroy;
  $mw->update;
  undef $t;
  $mw->update;
  is($destroyed, 1, 'widget object released after destroy despite layout callbacks');
}

# 1b. Deleting a block type (or destroying the widget) did not release
#     the block's callbacks, so a -layoutcmd closure kept the widget alive.
{
  my $destroyed = 0;
  my $t = $mw->eText(-width => 30, -height => 5)->pack;
  $t->{sentinel} = Sentinel->new(\$destroyed);
  # The callbacks hold the widget itself (the usual [\&sub, $widget] form).
  $t->blockConfigure('C', -layoutcmd => [ sub { $_[1]->index('end') }, $t ]);
  $t->blockConfigure('D', -layoutcmd => [ sub { $_[1]->index('end') }, $t ]);
  $t->blockDelete('D');
  $mw->update;
  $t->destroy;
  $mw->update;
  undef $t;
  $mw->update;
  is($destroyed, 1, 'block callbacks released on block delete / widget destroy');
}

# 1c. Tag -data was never released.
{
  my $destroyed = 0;
  my $t = $mw->eText(-width => 30, -height => 5)->pack;
  $t->tagConfigure('T', -data => Sentinel->new(\$destroyed));
  $t->tagDelete('T');
  is($destroyed, 1, 'tag -data released on tag delete');
  $t->destroy;
}

SKIP: {
  skip 'Test::LeakTrace not installed', 3 unless $have_lt;
  my $t = make_widget();

  # 2. "block list" leaked one SV per call, and every typed element of the
  #    returned structure leaked its payload.
  Test::LeakTrace::leaks_cmp_ok(
    sub { for (1 .. 20) { my @l = $t->blockList('1.0', 'end') } },
    '<', 5, 'block list does not leak SVs');

  # 3. Other inspection commands, for good measure.
  Test::LeakTrace::leaks_cmp_ok(
    sub { for (1 .. 20) {
	    my @d = $t->dump('1.0', 'end');
	    my @o = $t->blockOf('1.2');
	    my @a = $t->blockAt('1.1');
	    my $s = $t->get('1.0', 'end');
	  } },
    '<', 5, 'dump / block of / block at / get do not leak SVs');

  # 4. Relayouts through the Perl layout callback.
  Test::LeakTrace::leaks_cmp_ok(
    sub { relayouts($t, 20) },
    '<', 5, 'relayout with a Perl layout callback does not leak SVs');

  $t->destroy;
}

# 5. Deleting an -empty block unlinked its segment from the line and
#    never freed it (72 bytes per block, since 1997).  No count of the
#    segments alive is kept, so the process's resident size is watched
#    over many deletions: the leak grew it by about 80 bytes each.
SKIP: {
  my $statm = '/proc/self/statm';
  skip "no $statm to measure the process size", 1 unless -r $statm;
  my $rss = sub {
    open my $fh, '<', $statm or return 0;
    my @f = split ' ', scalar <$fh>;
    return $f[1] * 4096;
  };
  my $t = $mw->eText->pack;
  $t->blockConfigure('E', -empty => 1);
  $t->insert('1.0', "abc\n");
  my $loop = sub {
    for (1 .. $_[0]) { $t->blockInsert('E', '1.1'); $t->delete('1.1') }
  };
  $loop->(2000);			# let Perl's own pools settle
  my $n = 50000;
  my $before = $rss->();
  $loop->($n);
  my $grown = $rss->() - $before;
  cmp_ok($grown / $n, '<', 8,
	 "deleting an -empty block frees it ($grown bytes for $n deletions)");
  $t->destroy;
}
$mw->destroy;
