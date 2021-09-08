#!/usr/bin/env perl
use Test2::V0;
use Time::Verbal;

my $now = time;

my $tv = Time::Verbal->new(locale => "zh-TW");
is $tv->distance($now, $now),      "不到一分鐘";
is $tv->distance($now, $now + 29), "不到一分鐘";
is $tv->distance($now, $now + 63), "一分鐘";
is $tv->distance($now, $now + 89), "一分鐘";
is $tv->distance($now, $now + 90), "2 分鐘";
is $tv->distance($now, $now + 119), "2 分鐘";
is $tv->distance($now, $now + 120), "2 分鐘";
is $tv->distance($now, $now + 3700), "大約一小時";
is $tv->distance($now, $now + 5400), "大約 2 小時";
is $tv->distance($now, $now + 10800), "大約 3 小時";
is $tv->distance($now, $now + 86405), "一天";
is $tv->distance($now, $now + 86400 * 300), "300 天";
is $tv->distance($now, $now + 86400 * 600), "一年多";

done_testing;
