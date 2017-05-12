package perfSONAR_PS::Services::MP::Config::Schedule;

use version; our $VERSION = 0.09; 

=head1 NAME

perfSONAR_PS::Services::MP::Config::Schedule - Configuration module for the
support of scheduled tests for MPs

=head1 DESCRIPTION

The purpose of this module separate implementation of parsing configuration 
files for MPs so that they provide a consistent interface to allow the 
perfSONAR_PS::Services::MP::Scheduler class to determine the appropriate 
periodicity and offset times for running measurements by an MP.

=head1 SYNOPSIS

  # create the configuration object
  my $schedule = perfSONAR_PS::Services::MP::Config::Schedule->new();

  # set the configuration file to use (note that the definitions of how to
  # parse for the appropriate test periods, and offset times etc for the 
  # individual tests should be defined in an inherited class.
  $schedule->configFile( 'some-config-file-path' ); 
  if ( $schedule->load() == 0 ) {

	# get a list of the test id's to run
	my @testids = $schedule->getAllTestIds();
	
	# determine the period of time from now until the next test should run
	# this will automatically determine the periodicity and conduct
	# a random on the offset to calculate the appropriate time.
	my $time = $schedule->getTestTimeFromNow( $testids[0] );

    print "The next test for '$testid' will run in $time seconds from now.";

  } else {

	print "Something went wrong with parsing file '" . $schedule->configFile() . "'\n";
    return -1;

  }

=head1 API

This module exposes the following methods.

=cut

use Log::Log4perl qw(get_logger);
our $logger = Log::Log4perl::get_logger( 'perfSONAR_PS::Services::MP::Agent::Ping' );

use strict;

=head2 new

instantiate a new config object

=cut
sub new
{
  my ( $package ) = @_; 
  my %hash = ();
  
  $hash{"CONFFILE"} = undef;	# config file path
  $hash{"CONF"} = undef;		# internal representation of schedule

  bless \%hash => $package;
}

=head2 configFile

accessor/mutator method for the configuration file

=cut
sub configFile
{
	my $self = shift;
	my $file = shift;
	if ( $file ) {
		$self->{CONFFILE} = $file;
	}
	return $self->{CONFFILE};
}


=head2 config

accessor/mutator method for the configuration

=cut
sub config
{
	my $self = shift;
	my $conf = shift;
	if ( $conf ) {
		$self->{CONF} = $conf;
	}
	return $self->{CONF};
}


=head2 load( $file )

Load and parse the config file $file. Should be overridden by inheriting class.

Returns
   0 = everythign okay
  -1 = something failed

=cut
sub load
{
	my $self = shift;
	$logger->logdie( "load() should be overridden.");
	return -1;
}


=head2 store( $file )

Load and parse the config file $file. Should be overridden by inheriting class.

Returns
   0 = everythign okay
  -1 = something failed

=cut
sub store
{
	my $self = shift;
	$logger->logdie( "store() should be overridden.");
	return -1;
}


=head2 getAllTestIds()

Returns a list of all the testids that have been parsed.

=cut
sub getAllTestIds
{
	my $self = shift;
	return keys %{$self->config()};
}


=head2  getTestById( $testid )

Returns the test info hash of the test with id $testid (key of hash). The 
returned hash should be in a key/value format suitable for the configuration
tool to use.

=cut
sub getTestById
{
	my $self = shift;
	my $testid = shift;
	
	if ( ! defined $testid || $testid eq '' ) {
		$logger->logdie( "Missing parameter 'testid'");
	} else {
		if( ! exists $self->config()->{$testid} ) {
			$logger->fatal( "unique test with id '$testid' does not exist in ". $self->configFile() );
			return undef;
		}
			
		return $self->config()->{$testid};
	}
	
}

=head2 getTestPeriodById( $testid )

Returns the test period defined for test id '$testid'.

=cut
sub getTestPeriodById
{
	my $self = shift;
	my $testid = shift;
	
	return undef
		unless defined $testid;

	$logger->fatal( "unique test with id '$testid' does not define a test period.")
		unless exists $self->config()->{$testid}->{'measurementPeriod'};

	return $self->config()->{$testid}->{'measurementPeriod'};
}

=head2 getTestOffsetById( $testid )

Returns the test offset defined for test id '$testid'.

=cut
sub getTestOffsetById
{
	my $self = shift;
	my $testid = shift;
	
	return undef
		unless defined $testid;

	# return zero if there is no offset defined
	if( ! exists $self->config()->{$testid}->{'measurementOffset'} ) {
		return 0;
	}
	# otherwise return the value
	return $self->config()->{$testid}->{'measurementOffset'};
}

=head2 getTestOffsetTypeById( $testid )

Returns the test offset type defined for test id '$testid'.

=cut
sub getTestOffsetTypeById
{
	my $self = shift;
	my $testid = shift;
	
	return undef
		unless defined $testid;

	# return zero if there is no offset defined
	if( ! exists $self->config()->{$testid}->{'measurementOffsetType'} ) {
		return 'Flat';
	}
	# otherwise return the value
	# TODO: Validate, enumerate types (Flat, Gaussian etc)
	return $self->config()->{$testid}->{'measurementOffsetType'};
}


=head2 getTextNextTimeFromNow( $testid )

Determines the amonut of time from now until the next test for $testid should
start.

Returns
      n = seconds til next test
  undef = testid does not exist

=cut
sub getTestNextTimeFromNowById
{
	my $self = shift;
	my $testid = shift;

	return undef
		unless defined $testid && exists $self->config()->{$testid};
		
	# get the test period of the first testid in the array
	# don't bother doing the rest if it doesn't exist
	my $testing_period = $self->getTestPeriodById( $testid );
	return undef
		unless $testing_period;

    # get the test offset value of the first testid in the array
    my $testing_offset = $self->getTestOffsetById( $testid );
	return $testing_period
		unless $testing_offset;

    # get the test offset type of the first testid in the array
    my $testing_offset_type = $self->getTestOffsetTypeById( $testid );


    # to determine the next time that a testid should be run
    # $logger->debug( "OFFSET: " . $testing_offset_type . " " . $testing_offset );
    my $offset = undef;
    if ( $testing_offset_type eq 'Gausssian' ) {
	
	
	} else {
		
		# assume a flat random distro or plus or minus the offset
		$offset = rand( 2* $testing_offset ) - $testing_offset;

	}
	
	return $testing_period + $offset;
}


1;

=head1 SEE ALSO

L<perfSONAR_PS::Services::MP::Scheduler>,
L<perfSONAR_PS::Services::Config::PingER>,
L<perfSONAR_PS::Services::MP::Agent::Base>,

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
