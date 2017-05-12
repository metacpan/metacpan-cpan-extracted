use strict;
use warnings;

use Test::More tests => 2;
use Word::Segmenter::Chinese::Lite qw(wscl_seg wscl_set_mode);

wscl_set_mode("unigram");
my @r1 = wscl_seg("中华人民共和国成立了");
my @r1_expect = (
  "中",
  "华",
  "人",
  "民",
  "共",
  "和",
  "国",
  "成",
  "立",
  "了",
);
is_deeply(\@r1, \@r1_expect);

wscl_set_mode("obigram");
my @r2 = wscl_seg("中华人民共和国成立了");
my @r2_expect = (
  "中华",
  "华人",
  "人民",
  "民共",
  "共和",
  "和国",
  "国成",
  "成立",
  "立了",
  "了",
  '',
);
is_deeply(\@r2, \@r2_expect);
