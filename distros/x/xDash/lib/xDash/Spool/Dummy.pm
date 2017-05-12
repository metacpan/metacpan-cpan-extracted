package xDash::Spool::Dummy;
# Copyright 2005 Jerzy Wachowiak

use strict;
use warnings;
use vars qw( $VERSION );
use Carp;

$VERSION = '1.00';

# PUBLIC METHODS (convention: capital first letter)

sub new {

    my $class = shift;
    my $self = {};
    $self->{VERSION} = $VERSION;
    $self->{last_time} = time();
    $self->{interval} = 0.0;
    $self->{threads_counter} = 0;
    $self->{threads} = {};
    bless ( $self, $class );
    return $self
}

sub SetParameters {

#Contract: 
#	[1] Parameters as input
#	[2] Method checks if all needed paramters are set
#       [2] Method can suceeds when path formal argument is passed

    my $self = shift;

   $self->{parameters} = { @_ };
    unless ( defined( $self->{parameters}->{event_limit} ) ){
	croak 'xDash: Missing event limit in Spool->SetParameters().'
    }
    unless ( $self->{parameters}->{event_limit} >= 1 ){
	croak 'xDash: Event limit should be greater equal 1'
	.' in Spool->SetParameters().'
    }
    unless ( defined( $self->{parameters}->{mean_interoccurence_time} ) ){
	croak 'xDash: Missing event mean interoccurence time'
	.' in Spool->SetParameters().'
    }
    unless ( $self->{parameters}->{mean_interoccurence_time} > 0 ){
	croak 'xDash: Event mean interoccurence time should be greater 0'
	.' in Spool->SetParameters().'
    }
    return 1
}

sub Check {

#Contract: 
#	[1] No input parameters  
#       [2] If method suceeds a list of threads is returned
#	 (if nothing in the spool -> empty list)
#	[3] If error occours, an error hash is returned

    my $self = shift;
    
    my @threads = keys %{ $self->{threads} };
    if ( $self->{threads_counter} >= $self->{parameters}->{event_limit} ){
	return { threads => \@threads }
    }
    
    my $current_time = time();
    my $delta_time = $current_time - $self->{last_time};
    $self->{last_time} = $current_time;

    while ( 1 ) {
	# Poisson/exponential time series simulation...
	my $interoccurence_time
	 = -log( 1.0 - rand ) * $self->{parameters}->{mean_interoccurence_time};

	if ( $self->{interval} + $interoccurence_time < $delta_time ){
	    if ( $self->{threads_counter}++ 
	     >= $self->{parameters}->{event_limit} ){
		return { threads => \@threads }
	    }
	    $self->{threads}->{ $self->{threads_counter} } = undef;
	    push( @threads, $self->{threads_counter} );
	    $self->{interval} = $interoccurence_time + $self->{interval}
	}
	else {
	    $self->{interval} = $interoccurence_time - $self->{interval};
	    return { threads => \@threads }
	}
    }
}

sub Fetch {

#Contract: 
#	[1] Thread from spool as an input parameter  
#       [2] If method suceeds a hash with only body of the thread is returned
#	 (if nothing empty string '')
#	[3] If error occours, an error hash is returned
#	[4] For own handling should be overwriten
#	[5] $self->{threads}->{$thread} simulates thread body persistence
	
    my $self = shift;	
    my $thread = shift;

    unless ( defined $self->{threads}->{$thread} ){
	$self->{threads}->{$thread} = 'For own generating the body for'
	 ." thread $thread look inside xDash::Spool::Dummy"
	 .' and overwrite Fetch().'
    }
    return { body => $self->{threads}->{$thread} }
}

sub Remove { 

#Contract: 
#	[1] Thread from spool as an input parameter
#	[2] undef always returned

    my $self = shift;	
    my $thread = shift;

    delete $self->{threads}->{$thread};
    return 
}

sub Connect { return }
#Contract: 
#	[1] Not implemented
#	[2] undef always returned

sub Disconnect { return }
#Contract: 
#	No implementation needed for Dir.pm
#	No return value check in the xDash::Sender

1;
__END__
######################## User Documentation ##################

=pod

=head1 NAME

xDash::Spool::Dummy - Base class for Spool

=head1 SYNOPSIS

 package Spool;
 # Test settings:
 use base xDash::Spool::Dummy;
 sub SetParameters { shift->SUPER::SetParameters( 
  event_limit => 10, mean_interoccurence_time => 1 )

=head1 DESCRIPTION

=head2 USAGE

The module is developed in the object orientated way. It can be used as the 
base class for spool allowing easy testing, which has to implement a 
fixed set of methods, called by the derived class C<Spool>. 
C<Spool> is hardcoded in the C<xDash::Sender> (driver pattern).
The module auto generates jobs according 
to the Poisson/exponential time series simulation 
and places them in a virtual spool. A job is removed 
from the virtual spool only if a job 
confirmation comes back from the Archivist.
By deriving from the class, as the way of passing arguments, 
you have to implement explicit methods listed below .
The synopsis above is an example of the client script generated 
by the F<xdscr> after debugging.

For own generating the body of a event, look inside the code of 
C<xDash::Spool::Dummy> and overwrite the method C<Fetch()> in your 
derived class used as the base class for C<Spool>. 

=head2 METHODS

=over

=item SetParameters( event_limit => $number, 
mean_interoccurence_time => $time )

event_limit => $number, sets the upper limit of generated jobs; 
mean_interoccurence_time => $time, sets the mean interoccurence 
time for exponential time series simulation.

=back

=head1 BUGS

Any suggestions for improvement are welcomed!

If a bug is detected or nonconforming behavior, 
please send an error report to <jwach@cpan.org>.

=head1 COPYRIGHT

Copyright 2005 Jerzy Wachowiak <jwach@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the terms of the Apache 2.0 license attached to the module.

=head1 SEE ALSO

=over

=item L<xDash::Sender>

=back

=cut
