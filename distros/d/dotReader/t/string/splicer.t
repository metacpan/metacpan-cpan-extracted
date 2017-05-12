#!/usr/bin/perl

# vim:ts=2:sw=2:et:sta:syntax=perl

use strict;
use warnings;

use Test::More (
  'no_plan'
  );

BEGIN { use_ok('dtRdr::String::Splicer') };

{
  my $str = "a   test string that's not very creative";
  #          01  12345678901234
  my $splicer = dtRdr::String::Splicer->new($str);
  ok($splicer->insert(0, '.') == 1, 'insert');
  is($splicer->string, ".a   test string that's not very creative", 'check');
  ok($splicer->insert(0, '-') == 1, 'insert');
  is($splicer->string, ".-a   test string that's not very creative", 'check');
  ok($splicer->insert(6, '#') == 1, 'insert');
  is($splicer->string, ".-a   test# string that's not very creative", 'check');
  #                       01  2345 678901234
  ok($splicer->insert(13, ' foo') == 4, 'insert');
  is($splicer->string, ".-a   test# string foo that's not very creative", 'check');
  #                       01  2345 678901234
}
{
  my $str = " \n\n   a   test string    that's not very creative";
  #          0       12  345678901234
  my $splicer = dtRdr::String::Splicer->new($str);
  ok($splicer->insert(0, 'e') == 1, 'insert');
  is($splicer->string, "e \n\n   a   test string    that's not very creative", 'check');
  #                      0       12  345678901234
  ok($splicer->insert(0, '-') == 1, 'insert');
  is($splicer->string, "e- \n\n   a   test string    that's not very creative", 'check');
  #                       0       12  345678901234
  ok($splicer->insert(1, 'o') == 1, 'insert');
  is($splicer->string, "e- \n\n   oa   test string    that's not very creative", 'check');
  #                       0        12  345678901234
  ok($splicer->insert(7, '#') == 1, 'insert');
  is($splicer->string, "e- \n\n   oa   test# string    that's not very creative", 'check');
  #                       0        12  3456 78901234
  ok($splicer->insert(14, ' foo') == 4, 'insert');
  is($splicer->string, "e- \n\n   oa   test# string foo    that's not very creative", 'check');
  #                       0        12  3456 7890123    4
}
