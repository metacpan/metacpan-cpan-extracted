# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 5;
BEGIN { use_ok('Video::PlaybackMachine::FillProducer::StillFrame') };

use POE;
use POE::Kernel;
use POE::Session;

#########################


MAIN: {

  my $frame = Video::PlaybackMachine::FillProducer::StillFrame->new(
								    image => '/dev/null',
								    time => 15
								    );
  ok(! $frame->has_audio(), "Still frame doesn't have audio");
  isa_ok( $frame->time_layout(), 'Video::PlaybackMachine::TimeLayout::FixedTimeLayout');
  #is($frame->get_next(1), 2);

  my $still = '';
  my $time = 0;
  POE::Session->create(
		       inline_states => {
					 _start => sub {
					   $frame->start();
					 },
					 still_ready => sub {
					   $still = $_[ARG0];
					   $time = $_[ARG1];
					 },
					}
		      );
   POE::Kernel->run();
 TODO: {
    local $TODO = 'Need to fix test';
    is($still, '/dev/null');
    is($time, 15);
  }
}
