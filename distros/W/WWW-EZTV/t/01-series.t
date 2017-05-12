#!/usr/bin/env perl

use strict;
use Test::More;

BEGIN { use_ok( 'WWW::EZTV' ); }

ok( my $eztv = WWW::EZTV->new, 'Build eztv crawler' );

subtest 'Can retrieve shows' => sub {
    ok( $eztv->has_shows, 'Can fetch shows list' );
    isa_ok( $eztv->shows, 'Mojo::Collection' );
    isa_ok( $eztv->shows->[0], 'WWW::EZTV::Show' );
};

subtest 'All shows has name and URL' => sub {
    my $has_year = 0;
    $eztv->shows->each(sub {
        my $show = shift;
        ok( $show->name, 'Found show ' . $show->name );
        ok( $show->url, 'Has url ' . $show->url );
        ok( $show->status, 'Has status ' . $show->status );
        $has_year++ if $show->year;
    });
    ok( $has_year, "Some shows has year info" );
};

subtest 'Show object' => sub {
    ok( my $show = $eztv->shows->[0], 'Pick first show' );
    diag( $show->name . ' was choosen!' );
    ok( $show->has_episodes, 'Has episodes' );
    ok( $show->episodes, 'Retrieve episodes' );
    $show->episodes->each(sub{
        my $ep = shift;
        diag( 'Title:   '. $ep->title );
        diag( 'Name:    '. $ep->name );
        diag( 'Season:  '. $ep->season );
        diag( 'Number:  '. $ep->number );
        diag( 'Version: '. $ep->version );
        diag( 'Size:    '. $ep->size );
        ok( $ep->season >= 1, 'Has season' );
        ok( $ep->number >= 1, 'Has number' );

        ok( my $link = $ep->links->[0], 'Get first link' );
        ok( $link->url, 'Link has url' );
    });
};

done_testing();
