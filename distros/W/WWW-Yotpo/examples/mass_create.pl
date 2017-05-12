#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use WWW::Yotpo;
use Data::Dumper;

die "ENV YOTPO_CLIENT_ID and YOTPO_CLIENT_SECRET is required."
    unless $ENV{YOTPO_CLIENT_ID} and $ENV{YOTPO_CLIENT_SECRET};

my $yotpo = WWW::Yotpo->new(
    client_id => $ENV{YOTPO_CLIENT_ID},
    client_secret => $ENV{YOTPO_CLIENT_SECRET},
);

REDO:
my $access_token;
my $token_file = "$Bin/.token";
if (-e $token_file) {
    open(my $fh, '<', $token_file) or die $!;
    $access_token = do { local $/; <$fh> };
    close($fh);
    $access_token =~ s/^\s+|\s+$//g;
} else {
    my $token = $yotpo->oauth_token();
    die Dumper(\$token) unless $token->{access_token};
    $access_token = $token->{access_token};
    open(my $fh, '>', $token_file);
    print $fh $access_token;
    close($fh);
}

my $res = $yotpo->mass_create(
    utoken => $access_token,
    platform => 'general',
    orders => [
        {
            "email" => "client\@example.com",
            "customer_name" => "bob",
            "order_id" => "1121",
            "order_date" => "2013-05-01",
            "currency_iso" => "USD",
            "products" => {
                "11121" => {
                    "url" => "http://example_product_url1.com",
                    "name" => "product1",
                    "image" => "http://example_product_image_url1.com",
                    "description" => "this is the description of a product",
                    "price" => "100"
                },
                 "11133" => {
                    "url" => "http://example_product_url2.com",
                    "name" => "product2",
                    "image" => "http://example_product_image_url2.com",
                    "description" => "this is another description of a different product",
                    "price" => "200"
                }
            },
        },
        {
            "email" => "client1\@example.com",
            "customer_name" => "bob1",
            "order_id" => "1122",
            "products" => {
                "11121" => {
                    "url" => "http://example_product_url1.com",
                    "name" => "product1",
                    "image" => "http://example_product_image_url1.com",
                    "description" => "this is the description of a product"
                },
                "11133" => {
                    "url" => "http://example_product_url2.com",
                    "name" => "product2",
                    "image" => "http://example_product_image_url2.com",
                    "description" => "this is another description of a different product"
                }
            }
        }
    ]
);

print Dumper(\$res);

1;