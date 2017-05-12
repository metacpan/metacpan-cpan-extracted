# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================
package LS::Service::Fault;

use Carp qw(:DEFAULT);

use strict;
use warnings;

use vars qw( $METHODS );

use LS;

use base 'LS::Base';

sub BEGIN {

	$METHODS = [
		'message',
		'code',
		'trace',
	];
	
	LS::makeAccessorMethods($METHODS, __PACKAGE__);
}


#
# new( %options ) -
#
sub new {

	my ($self, %options) = @_;
	
	unless (ref $self) {
		
		$self = bless {

			_fault_to_strings=> {},
			_fault_to_code=> {},

		}, $self;
		
		$self->{'_fault_to_strings'} = {
			'^(bad|invalid)\s+(soap\s+)?(message|msg)\s+(format)'=> 500,
			'^(unknown|unrecognized)\s+(method|function|operation)(\s+call)?'=> 500,
			'^(bad|invalid)\s+(method|function|operation)(\s+call)?'=> 500,
			'^(malformed|bad|invalid)\s+(lsid)'=> 200,
			'^(unknown|unrecognized)\s+(lsid)'=> 201,
			'^data\s+(not\s+|un-?)available'=> 300,
			'^(data\s+range\s+not\s+valid)'=> 301,
			'^metadata\s+(not\s+|un-?)available'=> 400,
			'^metadata\s+format\s+(not\s+|un-?)available'=> 401,
			'^internal\s+((server|processing)\s+)?error'=> 500,
			'^(method|function|operation)\s+(not\s+|un-?)(available|implemented)'=> 501,
			};

		$self->{'_fault_to_code'} = {
			200=> 'Malformed LSID',
			201=> 'Unknown LSID',
			300=> 'Data not available',
			301=> 'Data range not valid',
			400=> 'Metadata not available',
			401=> 'Metadata format not available',
			500=> 'Internal processing error',
			501=> 'Method not implemented',

			# Platform error codes
			};
	}

	return $self;
}


#
# message( $message ) -
#


#
# code( $code ) -
#


#
# trace( $trace ) -
#


#
# fault( $message ) -
#
sub fault {
	
	my $self = shift->new();
	my $msg = shift;
	
	unless($msg) {

		$self->code(500);
		$self->message('Internal Error');
		$self->trace(Carp::longmess('No message specified'));

		return $self;
	}

	$self->code($self->_fault_string_to_code($msg));
	
	unless($self->code) {

		$self->code(500);
		$self->message('Internal Error');
		$self->trace(Carp::longmess('Could not resolve message: ' . $msg . ' to a LSID error code'));

		return $self;
	}
	
	my $fixed_msg = $self->_code_to_fault_string($self->code());
	
	my $fc = ($self->code() < 500) ? 'Client' : 'Server';
	
	my $fault = $self->code() . " $fc Error: $fixed_msg";
	
	$self->message($fault);
	$self->trace(Carp::longmess('Stack trace'));

	return $self;
}

#
# create( $message ) -
#
sub create {

	return shift->fault(@_);
}


#
# clientFault( $message, $errorCode ) -
#
sub clientFault {
	
	my $self = shift->new();
	my ($msg, $errc) = @_;

	unless ($msg && $errc) {

		$self->code(500);
		$self->message('Internal Error');
		$self->trace(Carp::longmess('Error message and code must be specified'));

		return $self;
	}
	
	$self->message($msg);
	$self->code($errc);
	
	unless($self->code()) {

		$self->code(500);
		$self->message('Internal Error');
		$self->trace(Carp::longmess('Could not resolve message: ' . $msg . ' to a LSID error code'));

		return $self;
	}

	my $fault = $self->code() . ' Client Error: ' . $self->message();
	
	$self->message($fault);
	$self->trace(Carp::longmess('Stack trace'));

	return $self;
}


#
# serverFault( $message, $errorCode ) -
#
sub serverFault {
	
	my $self = shift->new();
	my ($msg, $errc) = @_;

	unless ($msg && $errc) {

		$self->code(500);
		$self->message('Internal Error');
		$self->trace(Carp::longmess('Error message and code must be specified'));

		return $self;
	}
	
	$self->message($msg);
	$self->code($errc);
	
	unless($self->code()) {

		$self->code(500);
		$self->message('Internal Error');
		$self->trace(Carp::longmess('Could not resolve message: ' . $msg . ' to a LSID error code'));

		return $self;
	}

	my $fault = $self->code() . ' Server Error: ' . $self->message();
	
	$self->message($fault);
	$self->trace(Carp::longmess('Stack trace'));

	return $self;
}


#
# as_string( ) - Returns the string representation of this fault
#
sub as_string {

	my $self = shift;

	return "Code: " . $self->code() . "\n" . "Message: ". $self->message() . "\n" . "Stack trace: " . $self->trace();
}


#
# _fault_string_to_code( $fault ) -
#
sub _fault_string_to_code {
	
	my ($self, $fault) = @_;
	
	return undef unless ($fault);
	
	$fault=~ s/^\s+//;
	
	while (my ($ptn, $code) = each(%{ $self->{'_fault_to_strings'} })) {
		
		return $code if ($fault =~ /$ptn/i);
	}
	
	return undef;
}


#
# _code_to_fault_string( $code ) -
#
sub _code_to_fault_string {
	
	my ($self, $code) = @_;
	
	return undef unless ($code);
	return undef unless (exists($self->{'_fault_to_code'}->{ $code }));
	
	return $self->{'_fault_to_code'}->{$code};
}

1;

__END__

=head1 NAME

LS::Service::Fault - Generic fault generation for authority framework

=head1 SYNOPSIS

=head1 DESCRIPTION

The Fault class provides convenient methods for creating faults within
authorities.

=head1 CONSTRUCTORS

=over 

=item new

This will construct a new Fault object

=back

=head1 METHODS

=over

=item clientFault ( $msg, $error_code)

Create a _CUSTOM_ client fault with the specified message (L<$msg>) and
error code (L<$error_code>).

=back

=item serverFault( $msg, )

Create a _CUSTOM_ server fault with the specified message (L<$msg>) and
error code (L<$error_code>).

=item fault( $msg )

This creates a predefined fault based on the message. See the
constructor code for more information on what messages can be passed to
this function.

=head1 COPYRIGHT

Copyright (c) 2002,2003 IBM Corporation.
All rights reserved.   This program and the accompanying materials
are made available under the terms of the Common Public License v1.0
which accompanies this distribution, and is available at
L<http://www.opensource.org/licenses/cpl.php>

=cut
