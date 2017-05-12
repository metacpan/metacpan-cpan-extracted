#!/usr/bin/perl

# vim:ts=2:sw=2:et:sta:nowrap

# a very controlled find, this time with rc=0

use strict;
use warnings;

use Test::More (
  'no_plan'
  );

BEGIN { use_ok('dtRdr::Book::ThoutBook_1_0') };

my $test_book = 'test_packages/indexing_check_r0/book.xml';
(-e $test_book) or die "missing '$test_book' file!";

my $book = dtRdr::Book::ThoutBook_1_0->new();
ok($book, 'constructor');
ok($book->load_uri($test_book), 'load');

# setup the data
my %node = map({$_ => $book->find_toc($_)} 'A'..'G');
foreach my $key (keys(%node)) {
  ok($node{$key}, 'got node');
  isa_ok($node{$key}, 'dtRdr::TOC');
  is($node{$key}->get_title, $key, 'title check');
}

########################################################################
# just get these out of the way up front
# NOTE: this also loads-up the cache (this assumes a lot about Book.pm)
expect_test($node{A}, '013456789');
expect_test($node{B}, '13');
expect_test($node{C}, '2');
expect_test($node{D}, '456');
expect_test($node{E}, '5');
expect_test($node{F}, '8');
expect_test($node{G}, '9');

########################################################################

sub tq { # test quoter -- shorthand for all of that hash stuff
  my ($v) = @_;
  $v =~ s/^ //;
  $v =~ s/ $//;
  my @d = split(/ +/, $v);
  my @map = qw(node string lwing rwing lands start end);
  (@d == @map) or die;
  # needed a shorthand for '' in qw
  $_ = (($_ eq '-') ? '' : $_) for @d;
  my %stuff = map({$map[$_] => $d[$_]} 0..$#map);
  $stuff{$_} = $node{$stuff{$_}} for qw(node lands);
  return(%stuff);
}
########################################################################
# I got tired of typing, so we'll just tabulate

# select-entire node checks
#             SRC STRING        LWING    RWING   DST  RANGE
find_test(tq(' A  013456789     -        -        A   0   9  '));
find_test(tq(' B  13            -        -        B   0   2  '));
find_test(tq(' C  2             -        -        C   0   1  '));
find_test(tq(' D  456           -        -        D   0   3  '));
find_test(tq(' E  5             -        -        E   0   1  '));
find_test(tq(' F  8             -        -        F   0   1  '));
find_test(tq(' G  9             -        -        G   0   1  '));

# some more complicated stuff
#             SRC STRING        LWING    RWING   DST  RANGE
find_test(tq(' A  013           -        456      A   0   3  '));
find_test(tq(' A  456789        013      -        A   3   9  '));
find_test(tq(' A  6789          01345    -        A   5   9  '));
find_test(tq(' A  0             -        13       A   0   1  '));
find_test(tq(' A  7             013456   89       A   6   7  '));
find_test(tq(' B  1             -        3        B   0   1  '));
find_test(tq(' B  3             1        -        B   1   2  '));
find_test(tq(' D  4             -        56       D   0   1  '));
find_test(tq(' D  6             45       -        D   2   3  '));
find_test(tq(' D  56            4        -        D   1   3  '));
find_test(tq(' D  45            -        6        D   0   2  '));

#             SRC STRING        LWING     RWING   DST  RANGE
find_test(tq(' A  13            0         456      B   0   2  '));
find_test(tq(' A  3             01        45       B   1   2  '));
find_test(tq(' A  456           013       789      D   0   3  ')); #
find_test(tq(' A  45            013       6789     D   0   2  ')); #
find_test(tq(' A  56            0134      789      D   1   3  ')); #
find_test(tq(' A  5             0134      6789     E   0   1  ')); #
find_test(tq(' A  78            013456    9        A   6   8  '));
find_test(tq(' A  8             0134567   9        F   0   1  ')); #
find_test(tq(' A  9             01345678  -        G   0   1  ')); #
find_test(tq(' A  5             4         6        E   0   1  ')); #
find_test(tq(' D  5             4         6        E   0   1  '));

########################################################################
sub expect_test {
  my ($node, $expect) = @_;
  my (undef,undef,$line) = caller;
  my $name = 'line '. $line;
  my $content = $book->get_content($node);
  $content = strip_html($content);
  is($content, $expect,               "content  ($name)");
}

sub find_test {
  my (%d) = @_;

  my (undef,undef,$line) = caller;
  my $name = $d{testname} || 'line '. $line;

  my $node = $d{node};
  my $range = $book->locate_string($node, $d{string}, $d{lwing}, $d{rwing});

  ok(eval{$range->isa('dtRdr::Range')}, "isa      ($name)");
  is($range->node->id, $d{lands}->id,   "lands in ($name)") or return;
  is($range->a, $d{start},              "start    ($name)");
  is($range->b, $d{end},                "end      ($name)");
}


########################################################################
sub strip_html {
  my ($content) = @_;
  $content =~ s{.*<body>}{}s;
  $content =~ s{</body>.*}{}s;
  $content =~ s/<[^>]+>//gs;
  $content =~ s/\s+//gs;
  return($content);
}
