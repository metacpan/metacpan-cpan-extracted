package perfSONAR_PS::Services::MP::Scheduler;

=head1 NAME

perfSONAR_PS::Services::MP::Scheduler - A module that will implements a very 
simple scheduler from which MP's can inherit to run tests etc.

=head1 DESCRIPTION

This module allows a more intelligent method of running tests in a non-periodic
fashion. It does this with the configuration of a 
perfSONAR_PS::Services::MP::Config module that provides a list and configuration
of the tests to be run.

This module keeps two data structures of interest: 
  METADATA which contains all the tests indexed by the metadataId, and
  SCHEDULE which maintains a hash of epoch time of the test with the metadataId (we do not point to the METADATA
 datastructure directly as we need the id's sometimes.)

=head1 SYNOPSIS

  # create a new MP that inherits this scheduler
  my $mp = perfSONAR_PS::Schedule::MP::PingER->new( $config );
  
  # set up the schedule with the list of tests and fork off a manager class
  # that will spawn off tests according to a schedule that should be also
  # defined here.
  $mp->init();
  
=head1 API

This module exposes the following methods.

=cut

# inherit from the base, so that the scheduling methods are available as change of 
# parent class

use perfSONAR_PS::Services::Base;
use base 'perfSONAR_PS::Services::Base';

use version; our $VERSION = 0.09; 

use fields qw( SCHEDULE METADATA MAXCHILDREN );

use Time::HiRes qw ( &gettimeofday );
use POSIX;

use Log::Log4perl qw(get_logger);
our $logger = get_logger( CLASS );

use constant CLASS => 'perfSONAR_PS::Services::MP::Scheduler';

use strict;

# basename for configuration key
our $basename = undef;

my $MANAGER_PID = undef;
my $CHILDREN_OCCUPIED = 0;
my %CHILD = ();
my $i = 0;


=head2 new

Create a new MP Scheduler class
  $conf is ref to hash of configuration settings
  
=cut
sub new {
	my $package = shift;
	
	my $self = $package->SUPER::new( @_ );
	$self->{SCHEDULE} = {};
	$self->{METADATA} = {};
	$self->{MAXCHILDREN} = 2;

	return $self;
}


=head2 schedule

accessor/mutator for the schedule

=cut
sub schedule
{
	my $self = shift;
	if ( @_ ) {
		$self->{SCHEDULE} = shift;
	}
	return $self->{SCHEDULE};
}


=head2 config

accessor/mutator for the config storing the mp::config::schedule package

=cut
sub config
{
	my $self = shift;
	if ( @_ ) {
		$self->{METADATA} = shift;
	}
	return $self->{METADATA};
}


=head2 init( $handler )

Initiate the mp. This should involve:
- setting the configuration defaults to be used
- setting up the schedule for the tests (by using a 
	perfSONAR_PS::Services::MP::Config::Schedule - or inherited object)
- attaching message handlers for the daemon architecture from $handler
- forking off a scheduler to manage the starting of new measurements.

=cut
sub init
{
	my $self = shift;
	my $handler = shift;

	# this should be inherited

	# check handler type
	$logger->logdie( "Handler is of incorrect type: $handler")
		unless ( UNIVERSAL::can( $handler, 'isa') 
			&& $handler->isa( 'perfSONAR_PS::RequestHandler' ) );

	# set up defaults in the config

	# create a config object and set it to the file 'file'
	my $schedule = perfSONAR_PS::Services::MP::Config::Schedule->new();
	$schedule->load( 'file' );
	
    # set up the schedule with the list of tests
	$self->addTestSchedule( $schedule );	

	# add the appropiate 
	#$handler->addMessageHandler("SetupDataRequest", "", $self);
	#$handler->addMessageHandler("MetadataKeyRequest", "", $self);

	return 0;
}

=head2 prepareMetadata

prepare the metadata; in this case, we add the relevant tests into the 
schedule in preparation for run()

=cut
sub prepareMetadata
{
	my $self = shift;
	
	my @testids = $self->config()->getAllTestIds();
	
	$logger->debug( "TESTS: \n" . join "\n", @testids );
	$logger->logdie( "Scheduler could not determine any tests to run.")
		if ( scalar @testids < 1 );
	
	# popule schedule
	my $now = &getNowTime();
	foreach my $id ( @testids ) {
		my $delta = $self->config()->getTestNextTimeFromNowById( $id );
		next if ! defined $delta;
		my $time = $now + $delta;
		$logger->debug( "Add testid '$id' to run at '$time' delta=" . $delta );
		$self->addNextTest( $time, $id );
	}	
	return 0;
}


=head2 parseMetadata

Populates the schedule for tests to be run

=cut
sub parseMetadata
{
	my $self = shift;
	return 0;
}


=head2 needLS( boolean )

is the mp service setup to register with a LS?

=cut
sub needLS($) {
	my ($self) = @_;
	return 0;
}

=head2 registerLS()

actually register the MP service with a LS, ie send some xml of the metadata 
available form the MP service (ie what tests it can run)

=cut
sub registerLS($) {
	my $self = shift;
	return 0;
}



=head2 addTestSchedule( $config )

Adds the schedule list of tests from the perfSONAR_PS::MP::Config::Schedule 
object

=cut
sub addTestSchedule
{
	my $self = shift;
	my $schedule = shift;

	$logger->logdie( 'missing argument schedule')
		unless defined $schedule;

	$self->config( $schedule );
	
	$logger->logdie( "argument must be of object type perfSONAR_PS::Services::MP::Config::Schedule")
		unless UNIVERSAL::can( $schedule, 'isa') 
				&& $schedule->isa( 'perfSONAR_PS::Services::MP::Config::Schedule' );

	$logger->info( "Initiating scheduler with " . scalar $self->config()->getAllTestIds() . " tests" );

	$self->parseMetadata();
	$self->prepareMetadata();
	
	return 0;
}




=head2 getNowTime

Returns the current time in epoch seconds

=cut
sub getNowTime
{
  	my ( $nowTime, $nowMSec ) = &gettimeofday;
	return $nowTime . '.' . $nowMSec;
}


=head2 shiftNextTest()

removes the next test from the schedule

Returns ( $time, $testid ) for the time in epoch seconds $time when test with 
id $testid should be started. If there is no test defined, returns (undef,undef)

=cut
sub shiftNextTest
{
	my $self = shift;
	my ( $time, $testid ) = $self->peekNextTest();

	if ( defined $time ) {
		# may be an array	
		my $array = $self->schedule()->{$time};
		my $test = shift @$array;

		# put it back if we still have entries for same time
		if ( scalar @$array ) {
			$self->schedule()->{$time} = $array;
		}
		# or clear it if empty
		else {
			delete $self->schedule()->{$time};
		}	
		return ( $time, $testid );
	}
	return ( undef, undef );
}


=head2 peekNextTest()

Gives the next testid without removing it from the schedule

Returns ( $time, $testid ); where $start is the epoch seconds when the test $testid should start.
If there is no next test, then will return (undef, undef);

=cut
sub peekNextTest
{
	my $self = shift;

	my @times = sort {$a<=>$b} keys %{$self->schedule()};
	if ( scalar @times ) {

		my $time = $times[0];
		my $test = $self->schedule()->{$time}->[0];
		my ( $testid, @tmp ) = keys %$test; #FIXME
	
		return ( $time, $testid );

	}
	
	return ( undef, undef );
}


=head2 addNextTest( $time, $testid )

Places the test with id $testid into the schedule to run at time $time.

=cut
sub addNextTest
{
	my $self = shift;
	my $time = shift;
	my $testid = shift;

	# if tehre is already at test at this time, append it
	push @{$self->schedule()->{$time}}, { $testid => 1 };
	
	return;
}


=head2 maxChildren( $number )

accessor/mutator for the number of max child threads/processes

=cut
sub maxChildren
{
	my $self = shift;
	return $self->{MAXCHILDREN};
}


# make sure we kill the forking manager also when a signal is sent
sub KILL
{
	my $logger = get_logger( CLASS );
	kill( "TERM", $MANAGER_PID);
	my $pid = undef;
	exit;
}


# takes care of dead children
sub REAPER {                
	my $logger = get_logger( CLASS );        
    $SIG{CHLD} = \&REAPER;
    my $pid = undef;
    while( ( $pid = waitpid( -1, &WNOHANG) ) > 0 ) 
    {
		my %map = reverse %CHILD;
   	 	my $child = $map{$pid};
			
		delete $CHILD{$child} if defined $child && $CHILD{$child};
		
		$CHILDREN_OCCUPIED = keys %CHILD;
		$logger->debug( "Child thread $pid died (left " . $CHILDREN_OCCUPIED . ")" );

    }
    return;
}


=head2 run()

Forks off a new instance that will act as a manager/boss class for the scheduling
and forking off of new measurements.

=cut
sub run
{
	my $self = shift;
	my $processName = shift;
	
	# don't bother if there are no tests
	if ( scalar keys %{$self->schedule()} < 1 ) {
		$logger->logdie( "No tests are scheduled - please check " 
				. $self->config()->configFile() );
	}
	
	my $sigset = POSIX::SigSet->new(SIGINT);
    sigprocmask( SIG_BLOCK, $sigset)
        or $logger->logdie( "Can't block SIGINT for fork: $!\n" );
    
	my $pid = undef;
	$SIG{INT} = \&KILL;
	$SIG{CHLD} = \&REAPER;

    # fork!
    $logger->logdie( "fork failed: $!" ) 
		unless defined ($pid = fork);

    if ($pid) 
    {
        # Parent records the child's birth and returns.
        sigprocmask(SIG_UNBLOCK, $sigset)
            or $logger->logdie( "Can't unblock SIGINT for fork: $!\n" );
				
		$MANAGER_PID = $pid;
		
	} elsif ($pid == 0) {

		# setup handler to exit children
		$SIG{INT} = sub { 
						  my $logger = get_logger( CLASS );
						  foreach my $pid ( keys %CHILD ){
							#$logger->fatal( "killing $pid ");
							kill( "TERM", -$$ );
						  } 
						};

		$0 = $processName;
		$self->__run();
		
		exit(0);
	}
	
	return 0;
}

=head2 __run( )

Starts an endless loop scheduling and running tests as defined in $self->{'STORE'} until the
program is terminated.

=cut
sub __run
{
	my $self = shift;

	while( 1 )
	{
    
		my $badExit = 0;
		
		# wait for a signal from a dead child or something
		# if all children are occupised

		if ( $CHILDREN_OCCUPIED >= $self->maxChildren() ) {
			$logger->warn("Scheduler at max forks (" . $self->maxChildren() . "); waiting...");
			sleep;
		}
	
		if (! exists $CHILD{$i} )
		{
			# block until next scheduled test is up
			my ( $testTime, $testid ) = $self->waitForNextTest();
	
			if ( defined $testid )
			{
				my $sigset = $self->blockInterrupts('while');
				
				# actually do the test!
				my $now = &getNowTime();
				( $testTime, $testid ) = $self->shiftNextTest();
				
				# determine when to run the next iteration of this test
				my $delta = $self->config()->getTestNextTimeFromNowById( $testid );
				$logger->debug( "testid '" . $testid . "' will run again in $delta seconds");
				$self->addNextTest( $now + $delta, $testid );
				
				$self->unblockInterrupts( $sigset, 'while');
				
				# determine the test details and run it
				$self->doTest( $i, $testid );
				
			} 
			else {
				$badExit = 1;
			}
		}
	
		my $sigset = $self->blockInterrupts('while-check');
		
		if ( ! $badExit ) {
			$i++;
			$i -= $self->maxChildren() if( $i >= $self->maxChildren() );
		}

		$self->unblockInterrupts($sigset, 'while-check');

	}
	return;
}


=head2 blockInterrupts

block signal interruption

=cut
sub blockInterrupts
{
	my $self = shift;
        my $str = shift;
        # need to block interrupts in case we are still loading etc.
        my $sigset   = POSIX::SigSet->new; 
        my $blockset = POSIX::SigSet->new( SIGCHLD, SIGHUP, SIGUSR1, SIGUSR2, SIGINT );

        #$logger->debug( "BLOCKING INTERRUPTS for $str");

        sigprocmask(SIG_BLOCK, $blockset, $sigset) 
            or $logger->logdie( "Could not block interrupt signals: $!" );      
        
        return $sigset;
}
=head2 unblockInterrupts

allow interrupts to do as they did

=cut
sub unblockInterrupts
{
	my $self = shift;
        my $sigset = shift;
        my $str = shift;
        return 1 if ! defined $sigset;
        
        #$logger->debug( "DONE BLOCKING INTERRUPTS for $str");
        
        sigprocmask(SIG_SETMASK, $sigset)
            or $logger->logdie( "Could not restore interrupt signals: $!" );
        return 1;
}



=head2 waitForNextTest( )

Blocking function that sleeps until the next test. Problem is that ipc can 
cause the sleep to exit for any signal. Therefore, some cleverness in 
determine the actual slept time is required.

=cut
sub waitForNextTest
{
	my $self = shift;

	my $sigset = $self->blockInterrupts('wait');

	my ( $time, $testid ) = $self->peekNextTest();
	my $now = &getNowTime();
	my $wait = $time - $now;
	$logger->debug( "Waiting $wait seconds for the next test at " . $time );

	$self->unblockInterrupts($sigset, 'wait');

	# wait some time for a signal
	if ( $wait > 0.0 ) {
		
		select( undef, undef, undef, $wait );

		# if we are before the next test time, do not do anything!
		if ( $now < $time )
		{
			return ( undef, undef );
		}

	# we are behind schedule
	} else {
		# don't do anytthing
	}

	return ( $time, $testid );
}

=head2 doTest( $pid, $testid )

Spawns off a forked instance in order to run the test with id $testid. It will 
create a perfSONAR_PS::MP::Agent class that will actuall deal with the 
running of the test and collation of the results.

The forked instance will also deal with the storage defintions by calling the 
$self->storeData() method which should be overridden by inheriting classes to
store the output of the $agent into an MA.

Forked instance will exit at the end of the test. Success and or failure is
not propogated back up the stack.

=cut
sub doTest
{
	my $self = shift;
	my $forkedProcessNumber = shift;
	my $testid = shift;
	
	$logger->logdie( "Missing argument testid")
		unless defined $testid;
		
   # block signal for fork
    my $sigset = POSIX::SigSet->new(SIGINT);
    sigprocmask( SIG_BLOCK, $sigset)
        or $logger->logdie( "Can't block SIGINT for fork: $!\n" );
 
	my $pid = undef;

    # fork!
    $logger->logdie( "fork failed: $!" ) 
		unless defined ($pid = fork);
    
    if ($pid) 
    {
        # Parent records the child's birth and returns.
        sigprocmask(SIG_UNBLOCK, $sigset)
            or $logger->logdie( "Can't unblock SIGINT for fork: $!\n" );

        # keep state for the parent to keep count of children etc.
		my $sigset = $self->blockInterrupts('fork');
		
        $CHILD{$forkedProcessNumber} = $pid;
        $CHILDREN_OCCUPIED++;
        
		$self->unblockInterrupts($sigset,'fork');

        return;
    }
    else 
    {
   
        $SIG{INT} = 'DEFAULT';      # make SIGINT kill us as it did before
		$SIG{USR1} = 'DEFAULT';
		$SIG{USR2} = 'DEFAULT';
	    $SIG{HUP} = 'DEFAULT';
		
		# run the test
		my $test = $self->config()->getTestById( $testid );
		$logger->debug( "RUN TEST: " . Data::Dumper::Dumper $test );
		my $agent = $self->getAgent( $test );
		
		# collector will return -1 if error occurs
		if ( $agent->collectMeasurements() < 0 ) {
			
			# error!
			$logger->fatal( "Could not collect measurement for '$testid'" );
			
		} else {

			# get the results out
			$logger->info( "Collecting measurements for '$testid'");	
			# write to teh stores
			$self->storeData( $agent, $testid );

		}			
		exit;
    }

}


=head2 getAgent( $test )

Returns the relevant perfSONAR_PS::MP::Agent class to use for the test. As
this class should be inherieted, this method should be overridden to return
the appropraote agent to use for the hash $test that contains the parameters
for the test.

=cut
sub getAgent
{
	my $self = shift;
	$logger->logdie( "getAgent should be inherited");
	# don't forget to init() the agent!
	return undef;
}

=head2 storeData( $agent, $testid )

Does the relevant storage of data collected from the $agent for the test id
$testid. 

=cut
sub storeData
{
	my $self = shift;
	my $agent = shift;
	my $testid = shift;

	$logger->logdie( "storeData should be overridden");
	
	return -1;
}

1;


=head1 SEE ALSO

L<perfSONAR_PS::Services::Config::Schedule>,
L<perfSONAR_PS::Services::MP::Agent::Base>,
L<perfSONAR_PS::Services::Base>,

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS 
  
Questions and comments can be directed to the author, or the mailing list. 

=head1 VERSION

$Id: Base.pm 524 2007-09-05 17:35:50Z aaron $

=head1 AUTHOR

Yee-Ting Li, ytl@slac.stanford.edu

=head1 LICENSE
 
You should have received a copy of the Internet2 Intellectual Property Framework along
with this software.  If not, see <http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT
 
Copyright (c) 2004-2007, Internet2 and the University of Delaware

All rights reserved.

=cut
