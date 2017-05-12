# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================
package LS::ID;

use strict;
use warnings;

use base 'URI::urn';


#
# new - Creates a new LS::ID object from a string
#
#	Parameters: A URI containing the LSID
#
#	Returns: An LS::ID object if successful,
#		 undef if the URI is not in the correct form
#
sub new {
	my ($class, $uri) = @_;

	return undef unless _is_valid($uri);

	return bless \$uri, $class;
}


#
# _is_valid - Determines whether or not the LSID is a valid LSID
#
#	Returns: undef if the LSID is not valid,
#		 true if the LSID is valid
#
sub _is_valid {
	my ($string) = @_;

	return $string =~ /^[uU][rR][nN]:[lL][sS][iI][dD]:[A-Za-z0-9][\w\(\)\+\,\-\.\=\@\;\$\"\!\*\']*:[A-Za-z0-9][\w\(\)\+\,\-\.\=\@\;\$\"\!\*\']*:[A-Za-z0-9][\w\(\)\+\,\-\.\=\@\;\$\"\!\*\']*(:[A-Za-z0-9][\w\(\)\+\,\-\.\=\@\;\$\"\!\*\']*)?$/;
}


#
# _component -
#
sub _component {
	my $self = shift;
	my $index = shift;

	my @components = split(/:/, $self->nss());
	my $value = $components[$index];

	if (@_) {
		if (($index == 3 && $_[0] eq '') || ($_[0] =~ /^[A-Za-z0-9][\w\(\)\+\,\-\.\=\@\;\$\"\_\!\*\']*$/)) {
			$components[$index] = $_[0];
			$self->nss(join(':', @components));
			
			return 1;
		}
		else {
			return undef;
		}
	}

	return $value;
}


#
# _authority - Access to the raw authority component of the LSID
#
#	Returns: The raw string of the authority component
#
sub _authority {
	my $self = shift;
	return $self->_component(0, @_);
}


#
# authority - Access to the authority component of the LSID
#
#	Returns: The authority component
#
sub authority {
	my $self = shift;
	return lc $self->_authority(@_);
}


#
# _namespace -
#
sub _namespace {
	my $self = shift;
	return $self->_component(1, @_);
}


#
# namespace - Access to the namespace component of the LSID
#
#	Returns: The namespace component
#
sub namespace {
	my $self = shift;
	return $self->_namespace(@_);
}


#
# _object -
#
sub _object {
	my $self = shift;
	return $self->_component(2, @_);
}


#
# object - Access to the object component of the LSID
#
#	Returns: The object component
#
sub object {
	my $self = shift;
	return $self->_object(@_);
}


#
# _revision -
#
sub _revision {
	my $self = shift;
	return $self->_component(3, @_);
}


#
# revision - Access to the revision component of the LSID
#
#	Returns: The revision component
#
sub revision {
	my $self = shift;
	return $self->_revision(@_);
}


#
# canonical - Retrieves the canonicalized form of the LSID
#
#	Parameters:
#
#	Returns: The canonicalized LSID if successful,
#		 undef if unsuccessful
#
sub canonical {

	my $self = shift;	
	my $nss = $self->nss;

	my $new = $self->SUPER::canonical();

	# If the scheme portion of the URN is not lowercase, e.g. "URN",
	# URI::canonical will reset the scheme to lc scheme, which in turn will
	# rebless the object as a URI::urn. In case this happens, we need to
	# rebless it as an LS::ID here.

	bless ($new, __PACKAGE__) if (ref $new ne __PACKAGE__);

	return $new if $nss !~ /[A-Z]/ && $nss !~ /:$/;

	$nss =~ s/:$//;

	$new = $new->clone() if $new == $self;
	$new->authority(lc($self->authority()));

	return $new;
}


1;

__END__

=head1 NAME

LS::ID - Life Science Identifiers

=head1 SYNOPSIS

 use LS::ID;

 $lsid = LS::ID->new('URN:LSID:pdb.org:PDB:112L:');

 $authority_id = $lsid->authority;
 $namespace = $lsid->namespace;
 $object_id = $lsid->object;
 $revision = $lsid->revision;

=head1 DESCRIPTION

LS::ID provides an interface to parse an LSID into its
constituent parts and to build an LSID as described at
L<http://www.omg.org/cgi-bin/doc?dtc/04-05-01>


=head1 CONSTRUCTORS

The following method is used to construct a new LS::ID object:

=over

=item new ( $str )

This class method creates a new LS::ID object. The string representation
of the LSID is given as an argument. If $str is not a valid LSID, undef
is returned. Otherwise, the new LSID object is returned.

Examples:

 $lsid = LS::ID->new('URN:LSID:pdb.org:PDB:112L:')

 if (!$lsid) {
 	print "Invalid LSID!";
 }

=back

=head1 METHODS

LS::ID supports the methods of URI::urn, plus the following.

=over

=item authority ( [$new_authority] )

Sets or retrieves the authority ID component of the LSID.

If the method is called with no argument, the current authority is
returned. The string returned by this method is always lowercase. If you
want the authority as it was written in the LSID in its original case,
use _authority instead.

If the method is called with a string argument, the authority is set to
the new value if it is a valid authority ID. A true value is returned if
the authority was successfully set, or a false value otherwise.

=item namespace ( [$new_namespace] )

Sets or retrieves the namespace component of the LSID.  

If the method is called with no argument, the current namespace is
returned. The string returned by this method is always lowercase. If you
want the namespace as it was written in the LSID in its original case,
use _namespace instead.

If the method is called with a string argument, the namespace is set to
the new value if it is a valid namespace. A true value is returned if
the namespace was successfully set, or a false value otherwise.

=item object ( [$new_object] )

Sets or retrieves the object ID component of the LSID.  

If the method is called with no argument, the current object ID is
returned. The string returned by this method is always lowercase. If you
want the object ID as it was written in the LSID in its original case,
use _object instead.

If the method is called with a string argument, the object ID is set to
the new value if it is a valid object ID. A true value is returned if
the object ID was successfully set, or a false value otherwise.

=item revision ( [$new_revision] )

Sets or retrieves the revision component of the LSID.

If the method is called with no argument, the current revision is
returned. The string returned by this method is always lowercase. If you
want the revision as it was written in the LSID in its original case,
use _revision instead.

If the method is called with a string argument, the revision is set to
the new value if it is a valid revision. A true value is returned if the
revision was successfully set, or a false value otherwise.

=item canonical ( )

Returns an LS::ID object which is a normalized version of the LSID. All
components are converted to lowercase, and if no revision is present,
any trailing : is removed.

For efficiency reasons, if the LSID already was in normalized form, then
a reference to it is returned instead of a copy.

=back

=head1 COPYRIGHT

Copyright (c) 2002,2003 IBM Corporation.
All rights reserved.   This program and the accompanying materials
are made available under the terms of the Common Public License v1.0
which accompanies this distribution, and is available at
L<http://www.opensource.org/licenses/cpl.php>
