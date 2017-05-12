# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================

package LS::Client;

use strict;
use warnings;

use vars qw( $METHODS );

use LS;

use base 'LS::Base';

sub BEGIN {

	$METHODS = [
		'credentials',
	];
	
	LS::makeAccessorMethods($METHODS, __PACKAGE__);
}

#
# credentials( $crd_object ) - Sets/Gets the credentials object specified by crd_object.
#			       If crd_object is omitted, the current credentials are 
#			       returned.
#



package LS::Client::Credentials;

use strict;
use warnings;


#
# new -
#
#	Parameters:
#
#	Returns:
#
sub new {

	my $self = shift;

	my (%options) = @_;

	unless(ref $self) {

		$self = bless {

			_username=> undef,
			_password=> undef,
		}, $self;

		$self->username( $options{'username'} );
		$self->password( $options{'password'} );
	}

	return $self;
}


#
# username( $username ) - Sets/Gets the username portion of these credentials
#
#	Parameter: If present, becomes the username of the object
#
#	Returns: The username of this object
#
sub username {

	my $self = shift;

	@_ ? $self->{'_username'} = shift : $self->{'_username'};
}


#
# password ( $password ) -  Sets/Gets the password portion of these credentials
#
#	Parameter: If present, becomes the password of the object
#
#	Returns: The password of this object 
#
sub password {

	my $self = shift;

	@_ ? $self->{'_password'} = shift : $self->{'_password'};
}

1;

__END__

=head1 NAME

LS::Client - Base module for building LSID clients 

=head1 SYNOPSIS

 package MyClient;

 use vars qw(@ISA);

 use LS::Client;

 @ISA = ( 'LS::Client' );


 sub new {

   # Your client implementation 
 }

=head1 DESCRIPTION

The LS::Client module is used as a base class when building LSID clients.

=head1 METHODS

=over 

=item credentials( $crd_object )

	Sets/Gets the credentials object specified by crd_object.
	If crd_object is omitted, the current credentials are 
	returned.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002,2003 IBM Corporation 
All rights reserved.   This program and the accompanying materials
are made available under the terms of the Common Public License v1.0
which accompanies this distribution, and is available at
http://www.opensource.org/licenses/cpl.php

=cut

=head1 NAME

LS::Client::Credentials - Modules used to manipulate user credentials

=head1 SYNOPSIS

 my $credentials = LS::Client::Credentials->new();

 $credentials->username( 'username' );
 $credentials->password( 'password' );

 ... elsewhere in your application ...

 if($credentials->username() eq 'username') {

     # Do something
 }

=head1 DESCRIPTION

The LS::Client::Credentials object is used as a standard way to pass
user credentials in the framework.

=head1 METHODS

=over 

=item username( [ $username ] )

	Gets the username if no parameter is specified.

			- OR -

	Sets the username to the specified parameter.

=item password ( [ $password ] )

	Gets the password if no parameter is specified.

			- OR -

	Sets the password to the specified parameter.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002,2003 IBM Corporation 
All rights reserved.   This program and the accompanying materials
are made available under the terms of the Common Public License v1.0
which accompanies this distribution, and is available at
http://www.opensource.org/licenses/cpl.php

=cut

