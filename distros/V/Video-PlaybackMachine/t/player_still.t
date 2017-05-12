# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use strict;

use Test::More skip_all => 'Need to implement non-Xine trivial player';
BEGIN { use_ok('Video::PlaybackMachine::Player') };


## Still frame
use constant TEST_STILL => 't/test_movies/test_logo.png';

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Video::PlaybackMachine::Player qw(PLAYER_STATUS_PLAY PLAYER_STATUS_STILL PLAYER_STATUS_STOP);
use POE;
use POE::Kernel;
use POE::Session;

##
## Verifies that player is initially stopped, starts a
## Xine movie, verifies the movie is running two seconds later.
## Then it waits for the movie to quit. If the movie quits,
## and make sure that it ran the right amount of time.
##
TESTS: {
  -e TEST_STILL or die "Couldn't find @{[ TEST_STILL ]}\n";
  POE::Session->create(
		       inline_states => {
					 _start => sub {
					   my ($heap, $session, $kernel) = @_[HEAP, SESSION, KERNEL];
					   $kernel->alias_set('Scheduler');
					   $heap->{player} = Video::PlaybackMachine::Player->new();
					   $heap->{player_session} = $heap->{player}->spawn();
					   $kernel->delay('check_still', 3);
					   $kernel->post($heap->{player_session}, 'play_still', TEST_STILL);
					 },
					 check_still => sub {
					   my ($heap, $kernel) = @_[HEAP, KERNEL];
					   ok( $heap->{player}->get_status() == PLAYER_STATUS_PLAY, "Player is playing still frame");
					 },
					}
		      );
  POE::Kernel->run();
}

