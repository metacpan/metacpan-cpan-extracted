#!/usr/bin/perl

# vim:ts=2:sw=2:et:sta:nowrap

# finding a location with some selected text

use strict;
use warnings;

use Test::More;
my $test_book;
BEGIN {
  $test_book = 'books/test_packages/QuickStartGuide.jar';
  unless(-e $test_book) {
    plan skip_all => 'extra books/ dir not available';
  }
  else {
    plan 'no_plan';
  }
}

BEGIN { use_ok('dtRdr::Book::ThoutBook_1_0_jar') };
BEGIN { use_ok('dtRdr::Highlight') };

my $book = dtRdr::Book::ThoutBook_1_0_jar->new();
ok($book, 'constructor');
ok($book->load_uri($test_book), 'load');

# setup the data
my $node = ($book->toc->children)[1];
ok($node, 'got node');
ok($node->get_title eq 'INTRODUCTION', 'title check');

# can't do locate before get_content()
eval {$book->locate_string($node, qw(b a c))};
like($@ , qr/^no cache/, 'no locate before cache is built');

my $content = $book->get_content($node);

{
# search for:
my $lwing  = "an open source (GPL 2.0) cross-platform multi-document " .
             "help system (written in Java) that ";
my $string = "organizes new and existing content";
my $rwing  = ". Developers can browse, search, bookmark, and append " .
             "a library of their favorite reference documentation";

# feed it a node, string, and two wings
my $range = $book->locate_string($node, $string, $lwing, $rwing);
# make sure it comes up with the right location
isa_ok($range, 'dtRdr::Selection');
is($range->a, 124, 'start');
is($range->b, 158, 'end');
is($range->node, $node, 'node');
}
{
# search for:
my $lwing  = '';
my $string = 'INTRO';
my $rwing  = 'DUCTION The ThoutReaderTM is an open source (GPL 2.0) ' .
             'cross-platform multi-document ' .
             'help system (written in Java) that';

# feed it a node, string, and two wings
my $range = $book->locate_string($node, $string, $lwing, $rwing);
# make sure it comes up with the right location
isa_ok($range, 'dtRdr::Range');
is($range->a, 0, 'start');
is($range->b, 5, 'end');
is($range->node, $node, 'node');
}
{
# search for:
my $lwing  = "Use OSoft's high site traffic to distribute your content. Contact us at ";
my $string = 'author@osoft.com';
my $rwing  = '';

# XXX this is broken ATM because we're getting closer to the correct node now
my $range = $book->locate_string($node, $string, $lwing, $rwing);
# make sure it comes up with the right location
isa_ok($range, 'dtRdr::Range');
{
  # go back and check against original node
  my $hl = dtRdr::Highlight->claim($range);
  isa_ok($hl, 'dtRdr::Highlight');
  my $ohl = $book->localize_annotation($hl, $node);
  isa_ok($ohl, 'dtRdr::Highlight');
  is($ohl->node, $node, 'in orig node');
  is($ohl->a, 4464, 'start in orig node');
  is($ohl->b, 4480, 'end in orig node');
}
# NOTE was 4470 before twig -> 4464
# after localization: 4464-(2977-104) = 1591
#   BUT the TOC via twig changes that bump back by 6 again because the
#   node in which it lands contains no utf8 chars (so this was actually
#   incorrect before)
# finally:  4464-(2977-6-104) = 1597
0 and dtRdr::Logger->editor(sub {$book->get_cache_chars($node)});
is($range->a, 1597, 'start');
# NOTE was 4486 before twig -> 4480
# after localization:  4480-(2977-104) = 1607
# finally:  4480-(2977-6-104) = 1613
is($range->b, 1613, 'end');
is($range->node->id, '14', 'node (in child even)');
}
