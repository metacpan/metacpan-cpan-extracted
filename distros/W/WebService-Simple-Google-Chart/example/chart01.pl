#!/usr/bin/perl

use strict;
use warnings;
use WebService::Simple::Google::Chart;

my $chart = WebService::Simple::Google::Chart->new;
my $url = $chart->get_url(
    {
        chs => "250x100",
        cht => "p3",
   },
    { foo => 200, bar => 130, hoge => 70 }
);

print $url . "\n";
$chart->render_to_file("foo.png");
