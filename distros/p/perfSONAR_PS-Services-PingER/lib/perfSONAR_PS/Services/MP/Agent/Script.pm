package perfSONAR_PS::Services::MP::Agent::Script;

use version; our $VERSION = 0.09; 

=head1 NAME

perfSONAR_PS::Services::MP::Agent::Script - A module that will run a given script and
return it's output.

=head1 DESCRIPTION

Inherited perfSONAR_PS::Services::MP::Agent::Base class that allows a command to 
be executed. Specific tools should inherit from this class and override
parse() in order to be able to format the command line output in a well
understood data structure.

=head1 SYNOPSIS

  # create and setup a new Agent  
  my $agent = perfSONAR_PS::Services::MP::Agent::Script( $command, $options );
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

# derive from teh base agent class
use perfSONAR_PS::Services::MP::Agent::Base;
our @ISA = qw(perfSONAR_PS::Services::MP::Agent::Base);

use Log::Log4perl qw(get_logger);
our $logger = Log::Log4perl::get_logger( 'perfSONAR_PS::Services::MP::Agent::Script' );


=head2 new( $command, $options )

Creates a new agent class

  $command = complete path to command line tool to run, eg /bin/myScript.pl
  $arguments = string of arguments to supply to above script.

=cut
sub new {
  my ($package, $command, $arguments ) = @_; 
  my %hash = ();
  if(defined $command and $command ne "") {
    $hash{"CMD"} = $command;
  }
  if(defined $arguments and $arguments ne "") {
    $hash{"OPTIONS"} = $arguments;
  } 
  $hash{"RESULTS"} = undef;

  bless \%hash => $package;
}


=head2 command( $string )

accessor/mutator function for the script to execute

=cut
sub command
{
	my $self = shift;
	if ( @_ ) {
		$self->{CMD} = shift;
	}
	return $self->{CMD};
}


=head2 arguments( $string )

accessor/mutator function for the arguments to be supplied to the script

=cut
sub arguments
{
	my $self = shift;
	if ( @_ ) {
		$self->{OPTIONS} = shift;
	}
	return $self->{OPTIONS};
}


=head2 init( )

does anything necessary before running the collect() such as modifying the 
options etc.
Check to see that the script exists
=cut
sub init
{
	my $self = shift;
	if( ! -e $self->command() ) {
		$self->error( "Script '" . $self->command() . "' not found.");
		$logger->error( $self->error() );
		return -1;
	}
	return 0;
}


=head2 collectMeasurements( )

Runs the command with the options specified in constructor. 

Returns:

 -1 = something failed
  0 = command ran okay

on success, this method should call the parse() method to determine the relevant performance
output from the script.

=cut
sub collectMeasurements
{
  	my ($self) = @_;

	my $cmd = $self->command();
  	open( SCRIPT, $cmd . ' ' .  $self->arguments() . " |" );
	my @lines = <SCRIPT>;
	close(SCRIPT);
		
	my $err = undef;
	if ( scalar @lines < 1 ) {
		$err = "script returned no output";
		$self->error($err);
		$logger->error($err);
		return -1;
	}
	
	if ( scalar @lines > 1 ) {
		$err = "script returned invalid output: more than one line";
		$self->error( $err );
		$logger->error($err);
		return -1;
	}

	chomp( $lines[0] );
	$logger->debug( "Cmd '$cmd' returned '@lines'" );

	$self->results( $lines[0] );

	return 0;

}



1;