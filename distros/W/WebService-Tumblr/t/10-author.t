#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

use WebService::Tumblr;
use Try::Tiny;

plan skip_all => "Missing test Tumblr account/Config::Identity" unless -f 'identity' && eval { require Config::Identity };

my ( $tumblr, $dispatch, $post, $request, $response, $content );

my %identity = Config::Identity->load( 'identity' );

plan skip_all => "./identity is empty" unless %identity;

explain \%identity;

$tumblr = WebService::Tumblr->new( url => 'perl-tumblr', %identity );

$dispatch = $tumblr->write(
    type => 'regular',
    format => 'markdown',
    title => 'Test post',
    body => <<_END_,
# Hello, World.
_END_
    state => 'published',
);
ok( $dispatch->is_success );
$post = $dispatch->content;
ok( $post );
diag( $post );

$dispatch = $tumblr->delete(
    'post-id' => $post
);
ok( $dispatch->is_success );
is( $dispatch->content, 'Deleted' );

done_testing;

1;
