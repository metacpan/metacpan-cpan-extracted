# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use strict;

#use Test::More tests => 6;
use Test::More skip_all => 'Test never ends...';
BEGIN { use_ok('Video::PlaybackMachine::Player') };


## NOTE: Test movie from ftp.tek.com/tv/test/streams
use constant TEST_MOVIE_1 => 't/test_movies/time_015.mp4';

## Still frame
use constant TEST_STILL => 't/test_movies/test_logo.png';

Log::Log4perl->init(\ <<EOF);
log4perl.logger.Video		= DEBUG, ScreenAppender1

log4perl.appender.ScreenAppender1 = Log::Log4perl::Appender::Screen
log4perl.appender.ScreenAppender1.stderr = 1
log4perl.appender.ScreenAppender1.layout = SimpleLayout
EOF


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Video::PlaybackMachine::Player qw(PLAYER_STATUS_PLAY PLAYER_STATUS_STOP);
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
  my $player = Video::PlaybackMachine::Player->new();
  $player->spawn();
  -e TEST_MOVIE_1 or die "Couldn't find TEST_MOVIE_1\n";
  POE::Session->create(
		       inline_states => {
					 _start => sub {
					   my ($heap, $session, $kernel) = @_[HEAP, SESSION, KERNEL];
					   $kernel->alias_set('Scheduler');
					   $heap->{player} = Video::PlaybackMachine::Player->new();
					   $heap->{player_session} = $heap->{player}->spawn();
					   $kernel->delay('check_running', 2);
					   $kernel->delay('terminate', 20);
					   $heap->{time} = time();
					   $kernel->post($heap->{player_session}, 'play', $session->postback( finished => [] ), 0, TEST_MOVIE_1);
					 },
					 check_running => sub {
					   my ($heap, $kernel) = @_[HEAP, KERNEL];
					   ok( $heap->{player}->get_status() == PLAYER_STATUS_PLAY, "Player is playing");
					 },
					 finished => sub {
					   my ($heap, $kernel) = @_[HEAP, KERNEL];
					   $heap->{length} =  time() - $heap->{time};
					   ok( $heap->{length} > 0, "Time ran forward. That's generally good.");
					   ok( abs( ($heap->{length} - 15) ) < 3, "Ended more or less on time.");
					   ok( $heap->{player}->get_status() == PLAYER_STATUS_STOP, "Player has stopped and has said so." );
					 },
					 terminate => sub {
					   my ($heap, $kernel) = @_[HEAP, KERNEL];
					   ok( exists $heap->{length} && defined $heap->{length}, "Player said that it finished.");
#					   exit(0);
					 }
					}
		      );
  POE::Kernel->run();
}

