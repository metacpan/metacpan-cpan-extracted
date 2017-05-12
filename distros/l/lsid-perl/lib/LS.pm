# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation
# All rights reserved.  This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
#
# =====================================================================
use Error qw(:try);

package LS;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.1.7';

=head1 NAME

LS - Perl module for building clients and servers which resolve and perform
metadata queries on LSIDs.

=head1 SYNOPSIS

 use LS::ID;
 use LS::Locator;

 $lsid = LS::ID->new(
    'urn:lsid:biomoby.org:servicetype:Retrieval:2001-09-21T16-00-00Z'
     );

 $locator = LS::Locator->new();
 $authority = $locator->resolveAuthority($lsid);

 $resource = $authority->getResource($lsid);

 $data = $resource->getData();
 
 $response = $data->response();

 # $response is a filehandle, so you can use it as with any other

 print <$response>;


=head1 DESCRIPTION

The LS module is used for building clients and servers which resolve LSIDs
and perform metadata queries on LSIDs.  More information on LSIDs can be
found at L<http://www.omg.org/cgi-bin/doc?dtc/04-05-01>


=head2 makeAccessorMethods( $methodList, $package )

 Creates default accessor methods for an array ref of method names
 in the package specified by $package

=cut

sub makeAccessorMethods {

	my $methodList = shift;
	my $package = shift;
	
	unless(UNIVERSAL::isa($methodList, 'ARRAY')) {
	
		return undef;
	}
	
	unless($package) {
		
		return undef;
	}
	
	# 
	# Create the accessor / mutator methods for the bindings class
	#
	for my $field (@{ $methodList }) {
	
		no strict "refs";
	
		my $slot = "${package}__${field}";
		my $fn = "${package}::${field}";
		
		*$fn= sub {
	
			my $self = shift;
			
			@_ ? $self->{ $slot } = $_[0] : return $self->{ $slot };
		}
	}
}

=head1 SEE ALSO

L<LS::ID>, L<LS::Locator>, L<LS::Authority>, L<LS::Resource>, L<LS::Service>, L<LS::SOAP::Service>, L<LS::HTTP::Service>,
L<http://www.omg.org/cgi-bin/doc?dtc/04-05-01>, L<http://oss.software.ibm.com/developerworks/projects/lsid>

=head1 AUTHOR

IBM

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002,2003 IBM Corporation 
All rights reserved.   This program and the accompanying materials
are made available under the terms of the Common Public License v1.0
which accompanies this distribution, and is available at
http://www.opensource.org/licenses/cpl.php

=cut

package LS::Base;

use strict;
use warnings;

use vars qw( $_ERR $_STACK_TRACE );

use Carp qw(:DEFAULT);


=head1 NAME

LS::Base - This package is the base package that all other LS packages inherit from.

=head1 VARIABLES

A list of variables used in this package.

=head2 $_ERR

 Package error string.

=cut

$_ERR = '';

=head2 $_STACK_TRACE

 Holds the Carp stack traces
 
=cut

$_STACK_TRACE = [];

=head2 appendError( $extraMessage )

 Appends additional information to the error string
 Parameters - $extraMessage, Required. The additional information to store.

=cut

sub appendError {

	my ($self, $error) = @_;

	if($self && ref $self) {

		$self->{'_err'} .= "\n -> $error";
	}
	else {

		$_ERR .= "\n -> $error";
	}
}


=head2 recordError( $errorMessage ) - Records the message in the class's error string

 Parameters - $errorMessage, Required. The message to be stored in the class's
 rror string.

=cut

sub recordError {

	my ($self, $error) = @_;

	if($self && ref $self) {

		$self->{'_err'} = $error;
	}
	else {

		$_ERR = $error;
	}
}

=head2 addStackTrace( )

 Appends a Carp stack trace to the error string
 
=cut

sub addStackTrace {

	my $self = shift;
	my $previousTraces = shift;

	if($self && ref $self) {

		# Initialize the stack traces on the first call
		$self->{'_stack_trace'} = [] unless(UNIVERSAL::isa($self->{'_stack_trace'}, 'ARRAY'));

		# Copy an applicable stack traces in before adding our own
		@{ $self->{'_stack_trace'} } = @{ $previousTraces } if( ref $previousTraces eq 'ARRAY');

		push @{ $self->{'_stack_trace'} }, Carp::longmess('Stack trace');
	}
	else {

		# Copy an applicable stack traces in before adding our own
		@{ $_STACK_TRACE } = @{ $previousTraces } if( ref $previousTraces eq 'ARRAY');

		push @{ $_STACK_TRACE }, Carp::longmess('Stack trace');
	}
}

=head2 getStackTrace( )

 Retrieves a copy (in the form of an arrayref) of the 
 stack traces associated with this object.

 Returns - An arrayref that is a COPY of the arrayref containing
 all of the stack traces.

=cut

sub getStackTrace {

	my $self = shift;

	my $copy = [];

	foreach my $st (@{ $self->{'_stack_trace'} }) {

		push @{ $copy }, $st;
	}

	# Eh, there won't be that many of them
	@{ $copy } = reverse( @{ $copy } );

	return $copy;
}


=head2 hasStackTrace( )

 Determins whether or not a stack trace is present

 Returns - True if there is a stack trace
 		   False / undef if no stack trace is available
=cut

sub hasStackTrace {

	my $self = shift;

	if($self && ref $self) {

		return (scalar(@{ $self->{'_stack_trace'} } > 0) );
	}
	else {

		return (scalar(@{ $_STACK_TRACE }) > 0);
	}
}


=head2 clearStackTrace( )

 Clears the stack trace
 
=cut

sub clearStackTrace {

	my $self = shift;

	if($self && ref $self) {

		$self->{'_stack_trace'} = [];
	}
	else {

		$_STACK_TRACE = [];
	}
}


=head2 errorString( )

 Returns one of two error strings:

 1. if the class has been blessed in to a reference, the internal
 class error string is returned.
 2. if the class has not been blessed in to a reference, the package
 error string is returned.

 These values may be undef if no error has occured.
 
=cut

sub errorString {

        my $self = shift;

        if ($self && ref $self) {

		return $self->{'_err'};
        }

        return $_ERR;
}


=head2 error_string( )

 Synonym for errorString
 
=cut

sub error_string {

        my $self = shift;
        return $self->errorString();
}


=head2 errorDetails( )

 Returns the complete error with all applicable 
 stack traces.

 Returns - A very detailed error message
 
=cut

sub errorDetails {

        my $self = shift;

	my $errorMessage;

        if ($self && ref $self) {

		$errorMessage = $self->{'_err'};

		foreach my $st (@{ $self->{'_stack_trace'} }) {

			$errorMessage .= "\n\n" . $st;
		}

		return $errorMessage;
        }

	$errorMessage = $_ERR;

	foreach my $st (@{ $self->{'_stack_trace'} }) {

		$errorMessage .= "\n\n" . $st;
	}

        return $errorMessage;
}

=head1 SEE ALSO

L<LS::ID>, L<LS::Locator>, L<LS::Authority>, L<LS::Resource>, L<LS::Service>, L<LS::SOAP::Service>, L<LS::HTTP::Service>,
L<http://www.omg.org/cgi-bin/doc?dtc/04-05-01>, L<http://oss.software.ibm.com/developerworks/projects/lsid>

=head1 AUTHOR

IBM

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002,2003 IBM Corporation 
All rights reserved.   This program and the accompanying materials
are made available under the terms of the Common Public License v1.0
which accompanies this distribution, and is available at
http://www.opensource.org/licenses/cpl.php

=cut

package LS::Exception;

use strict;
use warnings;

use base 'Error';
use overload ('""' => 'stringify');


sub new
{
	my $self = shift;
	
	my $text = shift;
	my $object = shift;
	
	local $Error::Depth = $Error::Depth + 1;
	local $Error::Debug = 1;
	
	return $self->SUPER::new(-text=> ($text || ""), -object=> $object);
}


package LS::InvalidParameterException;
use base 'LS::Exception';

package LS::MalformedParameterException;
use base 'LS::Exception';

package LS::RuntimeException;
use base 'LS::Exception';

package LS::ClientException;
use base 'LS::Exception';

1;

__END__
