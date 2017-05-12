#!/usr/bin/perl

use strict;
use warnings;

use inc::testplan(1, 1 + 3);

BEGIN { use_ok('dtRdr::Book') };

#             01234567890123456
my $string = "abcaaaabcbffffabc";
{
  my @matches = dtRdr::Book::_context_match(\$string, 'a', 'b', 'c');
  ok(@matches, 'something matched');
  is(scalar(@matches), 3, '3 matches');
  my @expect = (
    [1,2],
    [7,8],
    [15,16],
  );
  is_deeply(\@matches, \@expect, 'match positions');
}

done;
# vim:ts=2:sw=2:et:sta:nowrap
