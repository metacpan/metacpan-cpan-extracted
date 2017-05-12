#!/usr/bin/env perl
use strict;
use warnings;

use lib qw(../../lib);
use Config::Pit;
use WebService::DMM;

use utf8;
binmode STDOUT, ":utf8";

my $config = pit_get('dmm.co.jp', require => {
    affiliate_id => 'DMM Affiliate ID',
    api_id       => 'DMM API ID',
});

my $dmm = WebService::DMM->new(
    affiliate_id => $config->{affiliate_id},
    api_id       => $config->{api_id},
);

my $res = $dmm->search(
    site    => 'DMM.co.jp',
    sort    => 'date',
    service => 'mono',
    floor   => 'goods',
    hits    => 10,
    offset  => 11,
);

my $index = 1;
for my $item (@{$res->items}) {
    printf "[%2d] %s(%s)\n", $index, $item->title, $item->price;
    $index++;
}
