# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7;
BEGIN { use_ok('Video::PlaybackMachine::FillSegment') };

#########################

use Video::PlaybackMachine::FillProducer::StillFrame;

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

MAIN: {
  my $producer = Video::PlaybackMachine::FillProducer::StillFrame->new(
	image => '/dev/null',
	time => 15);
  my $segment = Video::PlaybackMachine::FillSegment->new(
							 name => 'Test Segment',
							 sequence_order => 2,
							 priority_order => 5,
							 producer => $producer,
							 multiple => 1
							);
  is($segment->name(), 'Test Segment');
  is($segment->sequence_order(), 2);
  is($segment->priority_order(), 5);
  is($segment->producer(), $producer);
  ok($segment->is_available(15));
  ok(! $segment->is_available(5));
}
