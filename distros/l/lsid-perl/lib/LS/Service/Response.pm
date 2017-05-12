# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================
package LS::Service::Response;

use strict;
use warnings;

use vars qw( $METHODS );

use LS;

sub BEGIN {

	$METHODS =[
	];
	
	LS::makeAccessorMethods($METHODS, __PACKAGE__);
}


#
# new( %params ) -
#
sub new {

	my ($self, %params) = @_;

	unless (ref $self) {	

		$self = bless {
			_expiration=> undef,
			_response=> undef,
			_format=> undef,
		}, $self;

		$self->expiration($params{'expiration'}) 
			if($params{'expiration'});

		$self->response($params{'response'})
			if($params{'response'});
			
		$self->format($params{'format'})
			if($params{'format'});
	}

	return $self;
}


#
# expiration( $expiration ) -
#
sub expiration {

	my $self = shift->new();

	$_[0] ? ($self->{'_expiration'} = $_[0], return $self) : $self->{'_expiration'};
}


#
# response( $response ) -
#
sub response {

	my $self = shift->new();

	$_[0] ? ($self->{'_response'} = $_[0], return $self) : $self->{'_response'};
}


#
# format( $format ) -
#
sub format {

	my $self = shift->new();

	$_[0] ? ($self->{'_format'} = $_[0], return $self) : $self->{'_format'};
}

1;

__END__

=head1 NAME

LS::Service::Response - Response object used in communication

=head1 SYNOPSIS

	$response_data = 'Your response data';

	$format = 'application/xml';
	
	$response = LS::Service::Response->new(response=> $response_data,
					       format=> $format);

=head1 DESCRIPTION

The LS::Service::Response object is used to communicate data from a remote service to
the LSID resolver application layer.

=head1 CONSTRUCTORS

=over 

=item new

This will construct a new LS::Service::Response object.

=back

=head1 METHODS

=over

=item expiration ( [ $expiration ] )

	Expiration date.

=item response( [ $data ] )

	Response data.
	
=item format( [ $format_string ] )

	Format string.

=back

=head1 COPYRIGHT

Copyright (c) 2002,2003 IBM Corporation.
All rights reserved.   This program and the accompanying materials
are made available under the terms of the Common Public License v1.0
which accompanies this distribution, and is available at
L<http://www.opensource.org/licenses/cpl.php>

=cut
