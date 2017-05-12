#!/usr/bin/env perl

use strict;
use Test::More;

BEGIN { use_ok( 'WWW::EZTV' ); }

ok( my $eztv = WWW::EZTV->new, 'Build eztv crawler' );

my $show;

subtest 'Find a show' => sub {
    ok( $eztv->has_shows, 'Can fetch shows list' );
    ok( $show = $eztv->find_show(sub{ $_->name =~ /^the walking dead/i }), 'Find a known show' );
    is( $show->name, 'The Walking Dead', 'Name looks good' );
    ok( $show->url, 'Has url ' . $show->url );
    ok( $show->status, 'Has status ' . $show->status );
};

subtest 'Find episodes' => sub {
    ok( $show->has_episodes, 'Show fetch show episodes' );
    ok( my $ep = $show->find_episode(sub{ $_->season == 6 && $_->number == 16 && $_->quality eq 'standard' }), 'Find a known episode' );
    diag( 'Title:   ' . $ep->title );
    diag( 'Version: ' . $ep->version );
    diag( 'Size:    ' . $ep->size );
    is( $ep->name, 'The Walking Dead', 'Name looks good' );

    ok( $ep->has_links, 'Episode has links' );
    ok( my $link = $ep->find_link(sub{ $_->type eq 'torrent' }), 'Find a torrent link' );
    ok( $link->url, 'Link has URL' );
};

done_testing();
