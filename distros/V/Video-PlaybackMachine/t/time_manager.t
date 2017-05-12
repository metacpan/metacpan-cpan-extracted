# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use strict;

use Test::More tests => 9;
BEGIN { use_ok('Video::PlaybackMachine::TimeManager') };

use Video::PlaybackMachine::FillProducer::StillFrame;
use Video::PlaybackMachine::FillSegment;
use Log::Log4perl;

use constant FIFTEEN => 0;
use constant SEVEN => 1;
use constant TWENTY => 2;
use constant MGR => 3;

#########################


# Initialize the log file
my $conf = q(
log4perl.logger.Video		= ERROR, Screen1
log4perl.appender.Screen1	= Log::Log4perl::Appender::Screen
log4perl.appender.Screen1.layout = Log::Log4perl::Layout::SimpleLayout
);
Log::Log4perl::init(\$conf);


MAIN: {


  # Here we have your basic run where all of them fit.
  run_test(sub {
	     is(($_[MGR]->get_segment(45))[0], $_[FIFTEEN]);
	     is(($_[MGR]->get_segment(30))[0], $_[SEVEN]);
	     is(($_[MGR]->get_segment(23))[0], $_[TWENTY]);
	     ok( ! $_[MGR]->get_segment(5));
	    # ok( ! $_[MGR]->get_segment(45));
	   });

  # Here we have a run where only two of them fit.
  run_test(sub {
	     is(($_[MGR]->get_segment(35))[0], $_[FIFTEEN]);
	     is(($_[MGR]->get_segment(20))[0], $_[SEVEN], "Two fit #2");
	     ok(! $_[MGR]->get_segment(5) );
	   });

  # Here we have a run where only one of them fits.
  # Seven should only be played once, despite being potentially able
  # to fit twice.
  run_test(sub {
	     is(($_[MGR]->get_segment(14))[0], $_[SEVEN]);
	     # ok(! defined $_[MGR]->get_segment(7));
	   });
}

sub run_test_unimp {
  local $TODO = "unimplemented";
  run_test(@_);
}

##
## run_test()
##
## Arguments:
##   TEST_FUNC: coderef
##
## Bare-bones JUnit. Sets up test segments and a TimeManager, then
## passes them to TEST_FUNC to test them against a situation.
##
sub run_test {
  my ($test_func) = @_;
  
  my $fifteen = make_segment(15, 1, 0);

  my $seven = make_segment(7, 0, 1);

  my $twenty = make_segment(20, 2, 2);

  my $mgr = Video::PlaybackMachine::TimeManager->new($seven, $fifteen, $twenty);

  $test_func->($fifteen, $seven, $twenty, $mgr);
}


##
## make_segment()
##
## Arguments:
##   TIME -- int: seconds
##   PRIORITY -- int
##
## Return a segment which would display an imaginary still frame for
## TIME seconds at PRIORITY priority. Sequence will be order of creation.
##
sub make_segment {
  my ($time, $priority, $sequence) = @_;

  my $producer = 
    Video::PlaybackMachine::FillProducer::StillFrame->new(
							  image => '/dev/null',
							  time => $time
							 );

  return Video::PlaybackMachine::FillSegment->new(
						  name => "$time second",
						  sequence_order => $sequence,
						  priority_order => $priority,
						  producer => $producer
						 );

}

