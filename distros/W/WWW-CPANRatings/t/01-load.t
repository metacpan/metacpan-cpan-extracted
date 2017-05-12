#!/usr/bin/env perl
use Test::More;
use WWW::CPANRatings;

my $r = WWW::CPANRatings->new;
ok( $r );
ok( $r->rating_data );

ok( $r->get_ratings('Plack') );

my @reviews;
ok( @reviews = $r->get_reviews('Moose') );

for ( @reviews ) {
    ok( $_->{dist} );
    ok( $_->{dist_link} );
    ok( $_->{user} );
    ok( $_->{user_link} );
    ok( $_->{version} );
    # ok( $_->{ratings} );
    ok( $_->{created_on} );
    is( ref($_->{created_on}), 'DateTime' );
}

done_testing;
