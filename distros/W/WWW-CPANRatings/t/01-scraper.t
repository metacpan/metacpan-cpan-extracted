#!/usr/bin/env perl
use lib 'lib';
use Test::More;
use URI;
use Web::Scraper;
use WWW::CPANRatings;

my $rating_scraper = WWW::CPANRatings->rating_scraper();
my $res = $rating_scraper->scrape( URI->new("http://cpanratings.perl.org/dist/Moose") );
ok( $res );
ok( $res->{reviews} );

for my $review ( @{ $res->{reviews} } ) {
    ok( $review );
    ok( $review->{body} , 'body' );
    ok( $review->{dist} , 'dist' );
    ok( $review->{dist_link} , 'dist link' );
    ok( $review->{user} , 'user' );
    ok( $review->{user_link} , 'user link' );
    
}

done_testing;
