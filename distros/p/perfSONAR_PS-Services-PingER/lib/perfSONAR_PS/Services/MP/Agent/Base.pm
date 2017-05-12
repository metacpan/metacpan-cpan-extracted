package perfSONAR_PS::Services::MP::Agent::Base;

use version; our $VERSION = 0.09; 

=head1 NAME

perfSONAR_PS::Services::MP::Agent::Base - A module that contains the basic methods 
involved in gathering data by some means and parsing it's output.
This module should be inherited to provide a consistent interface to the
gathering (collecting), parsing and storage of data for different 
perfsonar MP services.

=head1 DESCRIPTION

The purpose of this module is to create objects that contain all necessary 
information to make measurements and understand the output. 

=head1 SYNOPSIS

  # create a new agent
  my $agent = new perfSONAR_PS::Services::MP::Agent::Base();
  
  # do some setting up
  $agent->init();
  
  # perform the measurement collection
  if ( $agent->collectMeasurements() == 0 ) {
  	# we have successfully collected the measurements, we must now extract the
  	# results into a form which is useable
  	  	
  	# spit out something useful
  	use Data::Dumper;
  	print "Results in raw parsed: " . Dumper $agent->results() . "\n";
  	
  	# or as XML
  	print "Results XML: " . $agent->xml() . "\n";
  	
  } else {
    # all errors should be stored under $agent->error()
  	print STDERR "Could not collect measurements: " . $agent->error() . "\n";
  }
  
  

=cut

use perfSONAR_PS::Common;

use Log::Log4perl qw(get_logger);
our $logger = Log::Log4perl::get_logger( 'perfSONAR_PS::Services::MP::Agent::Base' );


=head2 new()

Creates a new agent class, all results should be stored under $self->{RESULTS} 
in some format that is understood internally by the class.
This should be overloaded by inheriting classes.

=cut
sub new {
	my ($package ) = @_; 
	my $self = {
		'RESULTS' => {},
		'OPTIONS' => {},
		'ERRORMSG' => undef,
		'TIMEOUT' => 60,	# seconds timeout		
	};

	bless( $self, $package );
	return $self;
}

=head2 error( $text )

accessor/mutator method for storage and or retrieval of errors in executation
all methods should call this method with a human readable string $text 
when things go wrong

=cut
sub error
{
	my $self = shift;
	if ( @_ ) {
		$self->{ERRORMSG} = shift;
	}
	return $self->{ERRORMSG};
}

=head2 timeout

accessor/mutator for the timeout value of command line run's

=cut
sub timeout
{
	my $self = shift;
	if ( @_ ) {
		$self->{'TIMEOUT'} = shift;
	}
	return $self->{'TIMEOUT'};
}

=head2 init()

Initiate any datastructures/connections etc prior to collecting any measurements

Return:

  -1 = something failed
   0 = initialisation was okay

Should be overloaded by inherited classes when needed.
=cut
sub init
{
	my $self = shift;
	return 0;
}


=head2 collectMeasurements( )

Do something to enable the collection of the results. After running the command
we MUST always call the parse() function in order to format the output into
an understanable datastructure which can then be used later.

Return:

 -1 = something failed
  0 = command ran okay

This method should be inherited.  
=cut
sub collectMeasurements
{
  my ($self) = @_;
  $logger->logdie( "parse() is a virtual method, please override with inherited implementation.");
  
  # example flow; we gather the output from running some tool and then 
  # we need to translate the output into some internal datastructure using
  # the parse() method.
  
  my $output = 'Output from some tool';
  $self->parse( $output );
    
  return 0;
}


=head2 parse( \@results, $time )

Parses the data in the array of string @results into internal hash of variable=value.
on success, returns 0, otherwise -1;

=cut
sub parse
{
	my $self = shift;
	my $cmdOutput = shift;
    
    my $time = shift; # work out start time of time
    
    $logger->logdie( "parse() is a virtual method, please override with inherited implementation.");

	return -1;
}




=head2 destination( $string )

accessor/mutator method to set the destination to ping to

=cut
sub source
{
	my $self = shift;
	my $src = shift;
	
	if ( $src ) {
		$self->{'OPTIONS'}->{source} = $src;
	}

	return $self->{'OPTIONS'}->{source};
}

=head2 destinationIp( $string )

accessor/mutator method to set the destination ip to ping to

=cut
sub sourceIp
{
	my $self = shift;
	my $src = shift;
	
	if ( $src ) {
		$self->{'OPTIONS'}->{sourceIp} = $src;
	}

	return $self->{'OPTIONS'}->{sourceIp};
}




=head2 destination( $string )

accessor/mutator method to set the destination to ping to

=cut
sub destination
{
	my $self = shift;
	my $dest = shift;
	
	if ( $dest ) {
		$self->{'OPTIONS'}->{destination} = $dest;
	}

	return $self->{'OPTIONS'}->{destination};
}

=head2 destinationIp( $string )

accessor/mutator method to set the destination ip to ping to

=cut
sub destinationIp
{
	my $self = shift;
	my $dest = shift;
	
	if ( $dest ) {
		$self->{'OPTIONS'}->{destinationIp} = $dest;
	}

	return $self->{'OPTIONS'}->{destinationIp};
}





=head2 results(  )

Accessor/Mutator function for the result of the output in some internal datastructure.

=cut
sub results {
  my $self = shift;
  if ( @_ ) {
  	$self->{'RESULTS'} = shift;
  }
  return $self->{'RESULTS'};
}


=head2 fromDOM( )

Accepts a DOM object and determines the relative paramters to create and use
for the test

=cut
sub fromDOM()
{
	my $self = shift;
	my $dom = shift;
	
	# check input
	$logger->logdie("Input is not a dom object")
		unless UNIVERSAL::can( $dom, 'isa' ) && $dom->isa( 'XML::LibXML::Document');
		
	$logger->logdie( "fromDOM() is virtual and should be overridden");
	
	return -1;
}

=head2 toDOM(  )

Returns the full nmwg message (metadata and data elements) for the results 
that have been collected. Output should be a XML::LibXML::Document object.

=cut
sub toDOM
{
  my $self = shift;

  $logger->logdie( "resultsXML() is a virtual method, please override with inherited implementation.");

  return;
}

=head2 resultsSQL( $namespace )

Returns the relevant SQL insert or update statement for the results.

=cut
sub toSQL
{	
  my $self = shift;

  $logger->logdie( "resultsSQL() is a virtual method, please override with inherited implementation.");

  return;
}

=head2 resultsRRD( $namespace )

Returns the relevant RRD statement for the results.

=cut
sub toRRD {
	
  my $self = shift;

  $logger->logdie( "resultsRRD() is a virtual method, please override with inherited implementation.");

  return;
}


1;


=head1 SEE ALSO

L<perfSONAR_PS::Common>, 

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS 
  
Questions and comments can be directed to the author, or the mailing list. 

=head1 VERSION

$Id: PingER.pm 242 2007-06-19 21:22:24Z zurawski $

=head1 AUTHOR

Yee-Ting Li, E<lt>ytl@slac.stanford.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Internet2

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut