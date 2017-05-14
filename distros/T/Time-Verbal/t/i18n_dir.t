#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use Time::Verbal;

{
    my $tv = Time::Verbal->new(i18n_dir => "/tmp");
    is $tv->i18n_dir, "/tmp";
}

{
    use FindBin;

    my $tv = Time::Verbal->new(locale => "zh_TW", i18n_dir => $FindBin::Bin . "/i18n");
    is $tv->distance(time, time + 86400 * 400), "應該是一年多";
    for (my $d = 0; $d < 86400; $d += 59) {
        like $tv->distance(time, time + $d), qr/^應該是/;
    }
}

done_testing;
