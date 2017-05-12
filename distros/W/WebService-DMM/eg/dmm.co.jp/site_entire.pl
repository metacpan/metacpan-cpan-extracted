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
    sort    => 'review',
    keyword => 'rio',
    hits    => 10,
    offset  => 11,
);
die "Failed to request" unless $res->is_success;

my $index = 1;
for my $item (@{$res->items}) {
    for my $actor (@{$item->actors}) {
        printf "%2d: %s(%s)\n", $index, $actor->name, $actor->ruby;
    }
    $index++;
}
