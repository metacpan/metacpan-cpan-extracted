use XML::LibXML;
use Data::Dumper;
use perfSONAR_PS::Services::MP::Config::Schedule;

package perfSONAR_PS::Services::MP::Config::PingER;
use base "perfSONAR_PS::Services::MP::Config::Schedule";

use version; our $VERSION = 0.09; 

=head1 NAME

perfSONAR_PS::Services::MP::Config::PingER - Configuration module for the support
of scheduled tests for PingER

=head1 DESCRIPTION

This class inherits perfSONAR_PS::MP::Config::Schedule in order to provide an
interface to the test periods and offsets defined for PingER tests.

In this implementation, we only handle the topology-like PingER schema.

=head1 SYNOPSIS

  # create the configuration object
  my $schedule = perfSONAR_PS::Services::MP::Config::PingER->new();

  # set the configuration file to use (note that the definitions of how to
  # parse for the appropriate test periods, and offset times etc for the 
  #individual tests should be defined in an inherited class.
  $schedule->configFile( 'some-config-file-path' ); 
  if ( $schedule->load() == 0 ) {

	# get a list of the test id's to run
	my @testids = $schedule->getAllTestIds();
	
	# determine the period of time from now until the next test should run
	my $time = $schedule->getTestTimeFromNow( $testids[0] );

    print "The next test for '$testid' will run in $time seconds from now.";

  } else {

	print "Something went wrong with parsing file '" . $schedule->configFile() . "'\n";
    return -1;

  }

=cut

use strict;

use Log::Log4perl qw( get_logger );
our $logger = Log::Log4perl->get_logger( 'perfSONAR_PS::Services::MP::Config::PingER');


=head2 new

constructor for object

=cut
sub new {
	my $self = shift;
	return $self->SUPER::new( @_ );
}

=head2 configFile

accessor/mutator method for the configuration file

=cut
sub configFile {
	my $self = shift;
	return $self->SUPER::configFile( @_ );
}

=head2 config

accessor/mutator method for the configuration

=cut
sub config {
	my $self = shift;
	return $self->SUPER::config( @_ );
}

=head2 getAllTestIds()

Returns a list of all the testids that have been parsed.

=cut
sub getAllTestIds {
	my $self = shift;
	return $self->SUPER::getAllTestIds( @_ );
}


=head2 load( $file )

Loads and parses the configuration file with schedule information '$file'. If
no argument is passed, then will use the file defined in accessor/mutator
$self->configFile().

Returns
   0  = everything parsed okay
  -1  = parsing and or loading failed.

=cut
sub load
{
	my $self = shift;
	my $confFile = shift;
	
	if ( $confFile ) {
		$self->configFile( $confFile );		
	}
	$logger->debug( "loading mp config file '" . $self->{CONFFILE} . "'");
	if ( ! -e $self->{CONFFILE} ) {
		$logger->error( "Landmarks file '$self->{CONFFILE}' does not exist");
		exit -1;
	} 
	
	my $parser = XML::LibXML->new();
	my $doc = $parser->parse_file( $self->{CONFFILE} );


	# get namespaces: TODO: use maxim's namespaces
	my $ns = {
		'pingertopo' => 'pingertopo',
		'nmtb' => 'nmtb',
		'nmwg'	=> 'nmwg',
	};

	# get the dest host s
	my $xpath = '//' . $ns->{pingertopo} . ':topology/' . $ns->{pingertopo} . ':domain/' . $ns->{pingertopo} . ':node';
	# make sure that it has children with tests
	$xpath .= '[child::' . $ns->{nmwg} . ':parameters/' . $ns->{nmwg} . ":parameter[\@name='measurementPeriod']]";

	# place to store al tests
	my $config = {};

	# keep tab on number of tests found
	my $found = 0;

	# loop through the resultant nodes with test and cast to a hash
	$logger->debug("Finding: $xpath");
	foreach my $node ( $doc->findnodes( $xpath ) ) { 

		# get the id of the node
		my $nodeid = $node->getAttribute( 'id' );
		$logger->debug( "Found node id '$nodeid'");
		#$logger->debug( "$node:\n"  . $node->toString() );
		
		my $ipAddress = undef;
		# determine the ip address also if exists
		foreach my $port ( $node->getChildrenByLocalName( 'port' ) ) {
			my $id = $port->getAttribute('id');
			foreach my $ip ( $port->getChildrenByLocalName('ipAddress') ) {
				$ipAddress = $ip->textContent;
				chomp( $ipAddress );
			}
		}	
		# get the destination name (hostName)
		my $destination = undef;
		foreach my $tag ( $node->getChildrenByLocalName( 'hostName') ) {
			$destination = $tag->textContent;
			chomp( $destination );
		}
		
		# get the tests and populat datastructure
		foreach my $test ( $node->getChildrenByLocalName( 'parameters') )
		{
			#$logger->debug( "Found: " . $test->toString() );
			$logger->debug( "Found new test");
			# find the params
			my $hash = {};
			foreach my $param ( $test->childNodes )
			{
				my $tag = $param->localname();
				next unless defined $tag && 
					$tag eq 'parameter';
					
				my $attr = $param->getAttribute( 'name' );
				if ( defined $attr 
					&& ( $attr eq 'packetSize'
						|| $attr eq 'count'
						|| $attr eq 'packetInterval'
						|| $attr eq 'ttl' 
						|| $attr eq 'measurementPeriod' 
						|| $attr eq 'measurementOffset' ) 
				) {
					my $value = $param->textContent;
					chomp( $value );
					# remap the packetinterval into interval so the agent can use it
					$attr = 'interval' if $attr eq 'packetInterval';
					$logger->debug( "Found: '$attr' with value '$value'" );
					$hash->{$attr} = $value;												
				}

			}
			
			# don't bother if we don't have a period to use
			next
				if ! exists $hash->{measurementPeriod};
			
			# create a special id to identify the test
			my $id = 'packetSize=' . $hash->{'packetSize'} 
				. ':count=' . $hash->{count} 
				. ':interval=' . $hash->{'interval'} 
				. ':ttl=' . $hash->{ttl};
				
			# add the destination details
			$hash->{destinationIp} = $ipAddress if $ipAddress;
			$hash->{destination} = $destination if $destination;
			
			$config->{$nodeid . ':' . $id} = $hash;
			$found++;

		}
				
	}
	
	if ( $found ) {
		$logger->debug( Data::Dumper::Dumper $config );
		$self->config( $config );
		$logger->debug( "Found $found unique tests");
		return 0;
	}
	else {
		$logger->error( "Could not determine any scheduled tests from landmarks file '$confFile'");
		return -1;
	}
}

=head2 getTestById( $testid )

Returns the test information for $testid. Datastructure is a hash of the
following format

$hash->{$testid}->{packetSize} = n (bytes)
$hash->{$testid}->{count} = n (packets)
$hash->{$testid}->{ttl} = n (hops)
$hash->{$testid}->{interval} = n (secs)
$hash->{$testid}->{offset} = n (secs)
$hash->{$testid}->{measurementPeriod} = n (secs)
$hash->{$testid}->{measurementOffset} = n (secs)

=cut
sub getTestById
{
	my $self = shift;
    $self->SUPER::getTestById( @_ );	
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
	$self->SUPER::getTestNextTimeFromNowById( @_ );
}



1;
