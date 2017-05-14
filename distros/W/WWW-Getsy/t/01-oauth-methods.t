#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use WWW::Getsy;
use Test::More;# tests => 'no_plan';

unless ($ENV{WWW_GETSY_RUN_TESTS}) {                                                                                                
    plan skip_all => 'set WWW_GETSY_RUN_TESTS';
    }

my $app = WWW::Getsy->new_with_options(
    path => '/listings/active',
    params => '{"limit" : "1"}',
    );

if ($app->authorized) {
    my $response = $app->oauth_request();
    ok(defined $response->content);
    #$app->pretty_print($response->content);
    my $content = $app->decode($response->content);
    my $listing_id = $content->{results}[0]->{listing_id};
    ok($listing_id =~ m/^\d+$/); 

    # create a favorite for the above listing id
    my $path = "/users/__SELF__/favorites/listings/$listing_id";
    my $post_app = WWW::Getsy->new_with_options(
        path => $path,
        method => 'post'
        );
    $post_app->authorized;
    $response = $post_app->oauth_request();
    $content = $post_app->decode($response->content);
    my $createfav_listing_id = $content->{results}[0]->{listing_id};
    ok($createfav_listing_id =~ m/^\d+$/); 

    # delete the favorite
    my $delete_app = WWW::Getsy->new_with_options(
        path => $path,
        method => 'delete'
        );
    $delete_app->authorized;
    $response = $delete_app->oauth_request();
    $content = $delete_app->decode($response->content);
    ok(scalar(@{$content->{results}}) == 0);
}


done_testing;
