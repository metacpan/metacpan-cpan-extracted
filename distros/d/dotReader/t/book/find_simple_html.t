#!/usr/bin/perl

# vim:ts=2:sw=2:et:sta:nowrap

use strict;
use warnings;

use Test::More (
  'no_plan'
  );

BEGIN { use_ok('dtRdr::Book::ThoutBook_1_0') };
BEGIN { use_ok('dtRdr::Highlight') };

use lib 'inc';

use dtRdrTestUtil::Expect;

open_book(
  'dtRdr::Book::ThoutBook_1_0',
  'test_packages/indexing_check_html/book.xml'
);
check_toc(['A'..'C']);

# NOTE:
#   xml allows &lt; &gt; &amp; &quot; &apos
#   all twig passes is &lt; and &amp; -- all else gets encoded

#expect_test('A', '&lt;&gt;>&amp;&quot;&apos;');
expect_test('A', q(&lt;>>&amp;"')); # XXX twig is too smart for us
expect_test('B', '>>&amp;');
expect_test('C', '>');

{
  my $range = find_test(q(A <>>&"' - - A 0 13 )) or die;
  # my $range = find_test(q(A &lt;>>&amp;"' - - A 0 13 ));
  my $hl = highlight($range);
  highlight_test('A', q(&lt;>>&amp;"'));
  highlight_test('B', q(>>&amp;));
  highlight_test('C', q(>));
}

# TODO delete that highlight, create one in B and retest
