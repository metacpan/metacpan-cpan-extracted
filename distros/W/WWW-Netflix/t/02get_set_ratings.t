use strict;
use warnings;
use Test::More;
use blib;

use WWW::Netflix;

my ($user, $pass) = @ENV{ qw/ NETFLIX_TEST_USER NETFLIX_TEST_PASS / };

unless ( defined( $user ) and defined( $pass ) and $user and $pass ) {
    plan( 'skip_all', 'Please see README.test for information on testing' );
}
else {
    plan( 'no_plan' );
}

my $test_movie = {
    title       => "Who's Afraid of Virginia Woolf?",
    movie_id    => 1120753,
};

my $netflix_setter = WWW::Netflix->new( );
isa_ok( $netflix_setter, 'WWW::Netflix' );
ok( $netflix_setter->login( $user, $pass ), 'Successfully logged in for setter' );

$netflix_setter->setRating( $test_movie->{ movie_id }, 5 );

diag( 'Waiting a few seconds ... ' );
sleep 10;

my $netflix_getter = WWW::Netflix->new( );
isa_ok( $netflix_getter , 'WWW::Netflix' );
ok( $netflix_getter->login( $user, $pass ), 'Successfully logged in for getter' );

is( $netflix_getter->getRating( $test_movie->{ movie_id } ), 5, 'rating set and retrieved correctly' );

