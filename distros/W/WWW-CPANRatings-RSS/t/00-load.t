#!/usr/bin/env perl

use Test::More tests => 109;

BEGIN {
    use_ok('XML::Simple');
    use_ok('LWP::UserAgent');
	use_ok( 'WWW::CPANRatings::RSS' );
    use_ok('Class::Data::Accessor');
}

diag( "Testing WWW::CPANRatings::RSS $WWW::CPANRatings::RSS::VERSION, Perl $], $^X" );

my $rate = WWW::CPANRatings::RSS->new;
isa_ok($rate, 'WWW::CPANRatings::RSS');
can_ok($rate, qw/new fetch error ratings ua/);
isa_ok($rate->ua, 'LWP::UserAgent');

diag("Starting fetch");
my $ratings_ref = $rate->fetch;

SKIP: {
    if ( not defined $ratings_ref ) {
        diag("Got error: " . $rate->error);
        ok( length($rate->error), "we have error message");
        skip("Got a fetch error", 101);
    }
    is( ref $ratings_ref, 'ARRAY', "fetch returned a hashref");
    is_deeply( $ratings_ref, $rate->ratings, 'ratings and fetch return the same thing');

    for my $item ( @$ratings_ref ) {
        like( $item->{link}, qr|http://cpanratings.perl.org/#\d+| );
        for ( qw/comment creator dist/ ) {
            ok( length($item->{$_}), "$_ is present" );
        }

        like( $item->{rating}, qr{^(\d+|N/A)$}, 'rating is valid' );
    }
}

