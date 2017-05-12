# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================

package LS::SOAP::Fault;

use strict;
use warnings;

use vars qw(@ISA);

use SOAP::Lite;

use LS::Service::Fault;

@ISA = ( 'SOAP::Fault', 'LS::Service::Fault' );

#
# LS::Service::Fault related methods
#


#
# fault -
#
sub fault {
	
	my ($self, $msg) = @_;
	
	if($msg) {

		unless($self->LS::Service::Fault::fault($msg)) {

			return $self
				->faultcode('Server')
				->faultstring('Internal error')
				->description('Unable to create base fault')
				->errorcode(500)
		}
	} 

	my $fc = ($self->code < 500) ? 'Client' : 'Server';
	
	return $self
		->faultcode($fc)
		->faultstring($self->message())
		->description('<![CDATA[' . $self->trace() . ']]>')
		->errorcode($self->code());
}


#
# SOAP::Fault related methods
#

#
# errorcode -
#
sub errorcode {
	my $self = UNIVERSAL::isa($_[0] => __PACKAGE__) ? shift->new() : __PACKAGE__->new();

	if (@_) { $self->{'errorcode'} = shift; return $self }
	return $self->{'errorcode'};
}


#
# description -
#
sub description {
	my $self = UNIVERSAL::isa($_[0] => __PACKAGE__) ? shift->new() : __PACKAGE__->new();

	if (@_) { $self->{'description'} = shift; return $self }
	return $self->{'description'};
}


#
# faultdetail -
#
sub faultdetail {
	my $self = UNIVERSAL::isa($_[0] => __PACKAGE__) ? shift->new() : __PACKAGE__->new();

	if (@_) { return $self }

	return 
		'<errorcode>' . (defined $self->errorcode() ? $self->errorcode() : '') . '</errorcode>' .
		'<description>' . (defined $self->description() ? $self->description() : '') . '</description>';
}

1;

__END__

=head1 NAME

LS::SOAP::Service - SOAP service for LSID authority, metadata, and data operations

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 FAULTS

The LS::SOAP::Fault class is provided to aid in creating SOAP faults.
In addition to the methods of SOAP::Fault, LS::SOAP::Fault provides
get/set methods for an errorcode number and description string, which
are placed in the fault details.

=over

=item errorcode ( $num )

Sets or retrieves the numeric errorcode of the error.

=item description ( $desc_string )

Sets or retrieves a detailed, human readable description of the error.

Examples:

 sub getAvailablesServices {
 	my $self = shift;
 	my ($lsid_string) = @_;

	if (!known(LS::ID->new($lsid_string))) {
	 	die LS::SOAP::Fault->faultcode('Client')
		                   ->faultstring('Unknown LSID')
		                   ->errorcode(201)
		                   ->description(
		                   	'The LSID ' . 
		                   	$lsid_string . 
		                   	' is not known to this authority.'
		                     );
	}

	return "<wsdl></wsdl>";
 }

=back

