package perfSONAR_PS::Services::MP::Agent::SNMP;

use version; our $VERSION = 0.09; 

=head1 NAME

perfSONAR_PS::Services::MP::Agent::SNMP - A module that will query a SNMP device and
return it's output.

=head1 DESCRIPTION

Inherited perfSONAR_PS::MP::Agent::Base class that allows a command to 
be executed. Specific tools should inherit from this class and override
parse() in order to be able to format the command line output in a well
understood data structure.

=head1 SYNOPSIS

  # command line to run, variables are indicated with the '%...%' notation
  my $command = '/bin/ping -c %count% %destination%';
  
  # options to use, the above keys defined in $command will be 
  # substituted with the following values
  my %options = (
      'count' => 10,
      'destination' => 'localhost',
  );
  
  # create and setup a new Agent  
  my $agent = perfSONAR_PS::Services::MP::Agent::CommandLine( $command, $options );
  $agent->init();
  
  # collect the results (i.e. run the command)
  if( $mp->collectMeasurements() == 0 )
  {
  	
  	# get the raw datastructure for the measurement
  	print "Results:\n" . $self->results() . "\n";

  }
  # opps! something went wrong! :(
  else {
    
    print STDERR "Command: '" . $self->commandString() . "' failed with result '" . $self->results() . "': " . $agent->error() . "\n"; 
    
  }


=cut

use Net::SNMP;
use perfSONAR_PS::Common;

# derive from teh base agent class
use perfSONAR_PS::Services::MP::Agent::Base;
our @ISA = qw(perfSONAR_PS::Services::MP::Agent::Base);

use Log::Log4perl qw(get_logger);
our $logger = get_logger("perfSONAR_PS::Services::MP::Agent::SNMP");


=head2 new( $command, $options, $namespace)

Creates a new agent class

  $host = device to query
  $port = udp port number to query on $host
  $ver = snmp version number (1,2c,3)
  $comm = community string to use to query device
  $vars = hash of OIDs to query

=cut
sub new {
	my ($package, $host, $port, $ver, $comm, $vars, $cache_length) = @_;
	my %hash = ();

	if(defined $host and $host ne "") {
		$hash{"HOST"} = $host;
	}
	if(defined $port and $port ne "") {
		$hash{"PORT"} = $port;
	} else {
		$hash{"PORT"} = 161;
	}
	if(defined $ver and $ver ne "") {
		$hash{"VERSION"} = $ver;
	}
	if(defined $comm and $comm ne "") {
		$hash{"COMMUNITY"} = $comm;
	}
	if(defined $vars and $vars ne "") {
		$hash{"VARIABLES"} = \%{$vars};
	} else {
		$hash{"VARIABLES"} = ();
	}
	if (defined $cache_length and $cache_length ne "") {
		$hash{"CACHE_LENGTH"} = $cache_length;
	} else {
		$hash{"CACHE_LENGTH"} = 1;
	}

	$hash{"HOSTTICKS"} = 0;

	bless \%hash => $package;
}



=head2 init( )

Setup the snmp agent

=cut
sub init {
	my ($self) = @_;
	
	return $self->setSession();
}




=head2 collectMeasurement( @var )

collect the snmp oids defined. Optional list of variables to collect @var (otherwise
will use whatever was defined in the constructor or overloaded with $self->variables())

=cut
sub collectMeasurements
{
	my ($self, @var) = @_;
	return $self->collectVariables( @var );
}



=head2 host( $string )

accessor/mutator function for the host to query

=cut
sub host {
	my ($self, $host) = @_;

	if(defined $host and $host ne "") {
		$self->{HOST} = $host;
		$self->{HOSTTICKS} = 0;
	}
	
	return $self->{HOST};
}


=head2 port( $string )

accessor/mutator function for the udp port to query

=cut
sub port {
	my ($self, $port) = @_;

	if(defined $port and $port ne "") {
		$self->{PORT} = $port;
	} 
	return $self->{PORT};
}

=head2 version( $string )

accessor/mutator function for the snmp version to use

=cut
sub version {
	my ($self, $ver) = @_;

	if(defined $ver and $ver ne "") {
		$self->{VERSION} = $ver;
	} 
	return $self->{VERSION};
}

=head2 version( $string )

accessor/mutator function for the snmp community string

=cut
sub community {
	my ($self, $comm) = @_;

	if(defined $comm and $comm ne "") {
		$self->{COMMUNITY} = $comm;
	}
	return $self->{COMMUNITY};
}

=head2 variables( $string )

accessor/mutator function for the hash of snmp oids to collect
=cut
sub variables {
	my ($self, $vars) = @_;

	if(defined $vars and $vars ne "") {
		$self->{"VARIABLES"} = \%{$vars};
	} 
	
	return $self->{"VARIABLES"};
}

=head2 addVariable( $string )

Add the snmp oid to the list of variable to collect

=cut
sub addVariable {
	my ($self, $var) = @_;

	if(!defined $var or $var eq "") {
		$logger->error("Missing argument.");
	} else {
		$self->{VARIABLES}->{$var} = "";
	}
	return $var;
}

=head2 removeVariables( )

Clears the list of snmp oids to collect

=cut
sub removeVariables {
	my ($self) = @_;

	undef $self->{VARIABLES};
	$self->{VARIABLES} = {};
	return;
}

=head2 removeVariables( $string )

removes a single snmp oid variable from teh list to query

=cut
sub removeVariable {
	my ($self, $var) = @_;

	if(defined $var and $var ne "") {
		delete $self->{VARIABLES}->{$var};
	} else {
		$logger->error("Missing argument.");
	}
	return;
}


=head2 getVariableCount( )

determines the number of snmp oid variables to poll 

=cut
sub getVariableCount {
	my ($self) = @_;

	my $num = 0;
	foreach my $oid (keys %{$self->{VARIABLES}}) {
		$num++;
	}
	return $num;
}



=head2 collectVariables( )

Actually polls the host on port with community string and version the list of 
variables.

Input:
  @vars = list of oids to collect, if not supplied, will use $self->variables().

Returns:

  -1 = something went wrong (use $self->error() )
   0 = everything went okay
   
=cut
sub collectVariables {
	my $self = shift;
	my @vars = @_;


	if(defined $self->{SESSION}) {

		# get the oids to query
		my @oids = ();
		if( scalar @vars < 1 ) {
			foreach my $oid (keys %{$self->{VARIABLES}}) {
				$logger->fatal("ADD: " . $oid );
				push @oids, $oid;
			}
		} else {
			@oids = @vars;
		}

		$logger->fatal( "VARS: @vars (" . scalar @vars );

		# spit error if nothign to query
		if ( scalar @oids < 1 ) {
			$self->error( 'No variables defined to collect.' );
			$logger->error( $self->error() );
			return -1;
		}
		$logger->fatal( "OIDS: @oids (" . scalar @oids );
		
		# add the host ticks to increase resolution so we can track it
		push( @oids, '1.3.6.1.2.1.1.3.0' );
		
		# get results
		my $res = $self->{SESSION}->get_request(-varbindlist => \@oids) 
			or $logger->error("SNMP error.");

		if(!defined($res)) {
			
			my $msg = "SNMP error: ".$self->{SESSION}->error;
			$self->error( $msg );
			$logger->error($msg);
			return -1;
			
		} else {
			
			my %results = %{ $res };

			if (!defined $results{"1.3.6.1.2.1.1.3.0"}) {
				
				$logger->warn("Could not fetch host tick time values, getTime may be screwy");
				
			} else {
				
				my $new_ticks = $results{"1.3.6.1.2.1.1.3.0"} / 100;

				if ($self->{HOSTTICKS} == 0) {
					my($sec, $frac) = Time::HiRes::gettimeofday;
					$self->{REFTIME} = $sec.".".$frac;
				} else {
					$self->{REFTIME} += $new_ticks - $self->{HOSTTICKS};
				}

				$self->{HOSTTICKS} = $new_ticks;
			}
			
			$self->error('');
			return 0;
		}
	} else {
		my $msg = "Session to '". $self->host() . "' not found.";
		$self->error($msg);
		$logger->error($msg);
		return -1;
	}
	
}


=head2 setSession

creates and sets a Net::SNMP session for use in collection of oids

=cut
sub setSession {
	my ($self) = @_;

	if((defined $self->community() and $self->community() ne "") and
			(defined $self->version() and $self->version() ne "") and
			(defined $self->host() and $self->host() ne "") and
			(defined $self->port() and $self->port() ne "")) {

		($self->{SESSION}, $self->{ERROR}) = Net::SNMP->session(
									-community     => $self->community(),
									-version       => $self->version(),
									-hostname      => $self->host(),
									-port          => $self->port(),
									-translate     => [
									-timeticks => 0x0
									]) or $logger->error("Couldn't open SNMP session to '". $self->host() ."'.");

		if(!defined($self->{SESSION})) {
			$logger->error("SNMP error: ".$self->{ERROR});
			return -1;
		}
	}
	else {
		$logger->error("Session requires arguments 'host', 'port', version', and 'community'.");
		return -1;
	}
	return 0;
}

=head2 setSession

closes the Net::SNMP session

Returns 

  -1 = could not close the session;
   0 = closed session okay

=cut
sub closeSession {
	my ($self) = @_;

	if(defined $self->{SESSION}) {
		$self->{SESSION}->close;
	} else {
		$logger->error("Cannon close undefined session.");
		return -1;
	}
	return 0;
}




# cached method of collect()
sub getVar {
	my ($self, $var) = @_;
	my $logger = get_logger("perfSONAR_PS::MP::Status::SNMPAgent");

	if(!defined $var or $var eq "") {
		$logger->error("Missing argument.");
		return undef;
	} 

	if (!defined $self->{VARIABLES}->{$var} || !defined $self->{CACHED_TIME} || time() - $self->{CACHED_TIME} > $self->{CACHE_LENGTH}) {
		$self->{VARIABLES}->{$var} = "";

		my ($status, $res) = $self->collectVariables();
		if ($status != 0) {
			return undef;
		}

		my %results = %{ $res };

		$self->{CACHED} = \%results;
		$self->{CACHED_TIME} = time();
	}

	return $self->{CACHED}->{$var};
}



sub setCacheLength($$) {
	my ($self, $cache_length) = @_;

	if (defined $cache_length and $cache_length ne "") {
		$self->{"CACHE_LENGTH"} = $cache_length;
	}
}




sub getHostTime {
	my ($self) = @_;
	return $self->{REFTIME};
}

sub refreshVariables {
	my ($self) = @_;
	my ($status, $res) = $self->collectVariables();

	if ($status != 0) {
		return;
	}

	my %results = %{ $res };

	$self->{CACHED} = \%results;
	$self->{CACHED_TIME} = time();
}



1;
