use strict;
use warnings;

use Test::More tests => 4;
use Word::Segmenter::Chinese::Lite qw(wscl_seg);

my @r1 = wscl_seg("abc cbd ddd 123456");
my @r1_expect = qw(abc cbd ddd 123456);
is_deeply(\@r1, \@r1_expect);

my @r2 = wscl_seg("中华人民共和国成立了");
my @r2_expect = (
  "中华人民共和国",
  "成立",
  "了",
);
is_deeply(\@r2, \@r2_expect);

my @r3 = wscl_seg("oyeah中华人民共和国成立了");
my @r3_expect = (
  "中华人民共和国",
  "成立",
  "了",
  "oyeah",
);
is_deeply(\@r3, \@r3_expect);

my @r4 = wscl_seg("小明明天还要去上课学习语文和数学呢");
my @r4_expect = (
  "小明",
  "明天",
  "还要",
  "去",
  "上课",
  "学习",
  "语文",
  "和",
  "数学",
  "呢",
);
is_deeply(\@r4, \@r4_expect);



