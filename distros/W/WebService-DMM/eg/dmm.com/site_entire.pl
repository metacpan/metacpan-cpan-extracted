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
    site    => 'DMM.com',
    sort    => 'date',
    keyword => 'プリキュア',
    hits    => 10,
);

for my $key (qw/result_count total_count first_position/) {
    printf "%s: %d\n", $key, $res->$key;
}

my $index = 1;
for my $item (@{ $res->items }) {
    printf "[%d]\n", $index;
    for my $key (qw/service_name floor_name category_name
                    content_id product_id
                    title url affiliate_url date/) {
        printf "\t%s: %s\n", $key, $item->$key;
    }

    for my $p (qw/actors authors directors fighters/) {
        next unless @{$item->$p};

        print "\t$p\n";
        for my $person ( @{$item->$p} ) {
            printf "\t\t%s(%s)\n", $person->name, $person->ruby;
        }
        print "\n";
    }

    print "\tprice\n";
    for my $p (qw/price price_all list_price/) {
        my $val = $item->$p;
        print "\t\t$p: $val\n" if defined $item->$p;
    }

    print "\tdelivery\n";
    for my $delivery ( @{$item->deliveries} ) {
        printf "\t\t%s(%s)\n", $delivery->type, $delivery->price;
    }
    print "\n";

    $index++;
}
