package perfSONAR_PS::Services::MP::Agent::Ping;

use version; our $VERSION = 0.09; 

=head1 NAME

perfSONAR_PS::Services::MP::Agent::Ping - A module that will run a ping and
return it's output in a suitable internal data structure.

=head1 DESCRIPTION

Inherited perfSONAR_PS::Services::MP::Agent::CommandLine class that allows a command to 
be executed. This class overwrites the parse and 

=head1 SYNOPSIS

  # create and setup a new Agent  
  my $agent = perfSONAR_PS::Services::MP::Agent::Ping( );
  $agent->init();
  
  # collect the results (i.e. run the command)
  if( $mp->collectMeasurements() == 0 )
  {
  	
  	# get the raw datastructure for the measurement
  	use Data::Dumper;
  	print "Results:\n" . Dumper $self->results() . "\n";

  }
  # opps! something went wrong! :(
  else {
    
    print STDERR "Command: '" . $self->commandString() . "' failed with result '" . $self->results() . "': " . $agent->error() . "\n"; 
    
  }


=cut

# derive from teh base agent class
use perfSONAR_PS::Services::MP::Agent::CommandLine;
our @ISA = qw(perfSONAR_PS::Services::MP::Agent::CommandLine);

use Log::Log4perl qw(get_logger);
our $logger = Log::Log4perl::get_logger( 'perfSONAR_PS::Services::MP::Agent::Ping' );

# command line
our $command = '/bin/ping -c %count% -i %interval% -s %packetSize% -t %ttl% %destination%';

=head2 new( $command, $options, $namespace)

Creates a new ping agent class

=cut
sub new
{
	my $package = shift;
	
	my %hash = ();
	# grab from the global variable
    if(defined $command and $command ne "") {
      $hash{"CMD"} = $command;
    }
    $hash{"OPTIONS"} = {
		'transport'	=> 'ICMP',
		'count'		=> 10,
		'interval'	=> 1,
		'packetSize'	=> 1000,
		'ttl'	=> 255,
	};
  	%{$hash{"RESULTS"}} = ();

  	bless \%hash => $package;
}


=head2 init()

inherited from parent classes. makes sure that the ping executable is existing.

=cut


=head2 command()

accessor/mutator for the ping executable file

=cut
sub command
{
	my $self = shift;
	if ( @_ ) {
		$self->{'CMD'} = shift;
	}
	return $self->{'CMD'};
}



=head2 cont( $string )

accessor/mutator method to set the number of packets to ping to

=cut
sub count
{
	my $self = shift;
	if ( @_ ) {
		$self->{'OPTIONS'}->{count} = shift;
	}
	return $self->{'OPTIONS'}->{count};
}

=head2 interval( $string )

accessor/mutator method to set the period between packet pings

=cut
sub interval
{
	my $self = shift;
	if ( @_ ) {
		$self->{'OPTIONS'}->{interval} = shift;
	}
	return $self->{'OPTIONS'}->{interval};
}


=head2 packetInterval( $string )

accessor/mutator method to set the period between packet pings

=cut
sub packetInterval
{
	my $self = shift;
	return $self->interval( @_ );
}



=head2 deadline( $string )

accessor/mutator method to set the deadline value of the pings

=cut
sub deadline
{
	my $self = shift;
	if ( @_ ) {
		$self->{'OPTIONS'}->{deadline} = shift;
	}
	return $self->{'OPTIONS'}->{deadline};
}

=head2 packetSize( $string )

accessor/mutator method to set the packetSize of the pings

=cut
sub packetSize
{
	my $self = shift;
	if ( @_ ) {
		$self->{'OPTIONS'}->{packetSize} = shift;
	}
	return $self->{'OPTIONS'}->{packetSize};
}

=head2 ttl( $string )

accessor/mutator method to set the ttl of the pings

=cut
sub ttl
{
	my $self = shift;
	if ( @_ ) {
		$self->{'OPTIONS'}->{ttl} = shift;
	}

	return $self->{'OPTIONS'}->{ttl};
}

=head2 ttl( $string )

accessor/mutator method to set the ttl of the pings

=cut
sub transport
{
	my $self = shift;
	if ( @_ ) {
		$self->{'OPTIONS'}->{ttl} = shift;
	}
	return $self->{'OPTIONS'}->{ttl};
}



=head2 parse()

parses the output from a command line measurement of pings

=cut
sub parse
{
	my $self = shift;
	my $cmdOutput = shift;
    # use this as indication of the start of the test in epoch secs
    my $time = shift; # work out start time of time
	my $endtime = shift;
	
	my $cmdRan = shift;

	my @pings = ();
	my @rtts = ();
	my @seqs = ();
	
    for( my $x = 1; $x < scalar @$cmdOutput - 4; $x++ ) {
    	
    	$logger->debug( "Analysing line: " . $cmdOutput->[$x] );
    	my @string = split /:/, $cmdOutput->[$x];
    	my $v = {};
    	
		( $v->{'bytes'} = $string[0] ) =~ s/\s*bytes.*$//;
		if ( $string[0] =~ m/ from(.*)\((.*)\)/ ) {
			my $dest = $1;
			$dest =~ s/\s//g;
			$self->destination( $dest )
				if $dest ne '';
			$self->destinationIp( $2 );
			$logger->debug( "reformatting destination to '" . $self->destination() 
					. "' and destination ip '" . $self->destinationIp() . "'" );
		} 
			
		foreach my $t ( split /\s+/, $string[1] ) {
		  $logger->debug( "looking at $t");
          if( $t =~ m/(.*)=(\s*\d+\.?\d*)/ ) { 
	        $v->{$1} = $2;
	        $logger->debug( "  found $1 with $2");
          } else {
            $v->{'units'} = $t; 
          }
		}
		push @pings, { 
			'timeValue' => $time + eval($v->{'time'}/1000), #timestamp,
			'value' => $v->{'time'}, # rtt
			'seqNum' => $v->{'icmp_seq'}, #seq
			'ttl' => $v->{'ttl'}, #ttl
			'numBytes' => $v->{'bytes'}, #bytes
			'units' => $v->{'units'} || 'ms',
		};
	
		push( @rtts, $v->{'time'} );
		push( @seqs, $v->{'icmp_seq'} )
 			if $v->{'icmp_seq'} =~ /^\d+$/;
	        	
  		# next time stamp
     	$time = $time + eval($v->{'time'}/1000);
    
    }

	# get rest of results
	my $sent = undef;
	my $recv = undef;
	# hires results from ping output
	for( my $x = (scalar @$cmdOutput - 2); $x < (scalar @$cmdOutput) ; $x++ ) {
		$logger->debug( "Analysing line: " . $cmdOutput->[$x]);
 		if ( $cmdOutput->[$x] =~ /^(\d+) packets transmitted, (\d+) received/ ) {
			$sent = $1;
			$recv = $2;
        } elsif ( $cmdOutput->[$x] =~ /^rtt min\/avg\/max\/mdev \= (\d+\.\d+)\/(\d+\.\d+)\/(\d+\.\d+)\/\d+\.\d+ ms/ ) {
    		$minRtt = $1; 
			$meanRtt = $2;
			$maxRtt = $3;
 		}
	}


	# set the internal results
	$self->results( {
						'sent' => $sent, 'recv' => $recv,
						'minRtt' => $minRtt, 'meanRtt' => $meanRtt, 'maxRtt' => $maxRtt,
						'singletons' => \@pings, 'rtts' => \@rtts, 'seqs' => \@seqs
					});

	return 0;
}




1;

