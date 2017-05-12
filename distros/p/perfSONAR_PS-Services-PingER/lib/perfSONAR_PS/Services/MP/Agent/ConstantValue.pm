use perfSONAR_PS::Common;

package perfSONAR_PS::Services::MP::Agent::ConstantValue;

use version; our $VERSION = 0.09; 

=head1 NAME

perfSONAR_PS::Services::MP::Agent::ConstantValue - A perfsonar MP Agent class that returns
a constant value.

=head1 DESCRIPTION

This module returns a constant value. It inherits from 
perfSONAR_PS::MP::Agent::Base to provide a consistent interface.


=head1 SYNOPSIS

  # create and setup a new Agent  
  my $agent = perfSONAR_PS::Services::MP::Agent::ConstantValue( 5 );
  
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
our $logger = Log::Log4perl::get_logger( 'perfSONAR_PS::Services::MP::Agent::ConstantValue' );


=head2 new( $value )

Creates a new agent class

  $value = constant value to set

=cut
sub new {
  my ($package, $value ) = @_; 
  my %hash = ();
 
  $hash{"RESULTS"} = $value if defined $value;

  bless \%hash => $package;
}


=head2 init()

No initiation needed, do nothing

=cut
sub init
{
	my $self = shift;
	return 0;
}


=head2 collectMeasurements( )

Always okay as long as the constant value is set.

 -1 = something failed
  0 = command ran okay

=cut
sub collectMeasurements 
{
  	my ($self) = @_;

	if ( defined $self->results() ) {
		$logger->debug( "Collecting constant value '" . $self->results() . "'" );
		return 0;
	}
	else {
		$self->error( "No constant value defined");
		$logger->error( $self->error() );
		return -1;
	}
}


=head2 results( )

Returns the results (ie the constant value assigned in the constructor). No need to redefine 
here as it's inherited.

=cut





1;