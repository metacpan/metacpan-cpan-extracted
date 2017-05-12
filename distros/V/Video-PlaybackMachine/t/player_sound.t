use strict;

use FindBin '$Bin';

use POE;
use POE::Session;
use POE::Kernel;

use Video::PlaybackMachine::Player;

use Test::More skip_all => 'Need to finish this test';

my $player = Video::PlaybackMachine::Player->new();
$player->spawn();

# Initialize the log file
my $conf = q(
log4perl.logger.Video		= ERROR, Screen1
log4perl.appender.Screen1	= Log::Log4perl::Appender::Screen
log4perl.appender.Screen1.layout = Log::Log4perl::Layout::SimpleLayout
);
Log::Log4perl::init(\$conf);


POE::Session->create(

		     inline_states => {
				       _start => sub {
					 $_[KERNEL]->post('Player',
							  'play_music',
							  $_[SESSION]->postback('finished'),
							  "$Bin/test_movies/drunk_as_an_owl.ogg"
							 );
				       },
				       finished => sub {
					 
					 
				       }

				      }

);

$poe_kernel->run();
