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

my $netflix = WWW::Netflix->new( );
isa_ok( $netflix, 'WWW::Netflix' );
ok( $netflix->login( $user, $pass ), 'Successfully logged in for setter' );


my $test_movie = {
    title       => "Who's Afraid of Virginia Woolf?",
    movie_id    => 1120753,
};


ok( $netflix->queueMovie( $test_movie->{ movie_id } ), 'Queued a movie' );

diag( 'Waiting a few seconds ... ' );
sleep 4;


$netflix = WWW::Netflix->new( );
isa_ok( $netflix, 'WWW::Netflix' );
ok( $netflix->login( $user, $pass ), 'Successfully logged in for getter' );

my $q = $netflix->getQueue();

my $found_movie = 0;
for my $movie ( @{ $q->{ queued } } ) {
    $found_movie = 1 if $movie->[0] eq $test_movie->{ movie_id };
}

ok( $found_movie, 'Found queued movie from retrieved queue.' );
