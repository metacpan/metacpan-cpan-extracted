###########################################################################
### Trinket::DataType::object
###
### Object datatype handler
###
### $Id: Object.pm,v 1.3 2001/02/19 20:01:53 deus_x Exp $
###
### TODO:
###
###
###########################################################################

package Trinket::DataType::object;

BEGIN {
	our $VERSION = "0.0";
    our @ISA = qw( Trinket::DataType );
}

use strict;
use Trinket::Object;
use Trinket::DataType;
use Carp qw( confess cluck );

use constant TYPE_OBJECT_REF => 0;
use constant TYPE_OBJECT_ID  => 1;

sub set {
	my ($pkg, $self, $name, $obj_val, $params) = @_;
	
	### If this property isn't dirty already, save the clean value and
	### then flag it as dirty.
	if (! $self->[OBJ_PROPS]->{$name}->[PROP_DIRTY]) {
		$self->[OBJ_PROPS]->{$name}->[PROP_CLEAN_VALUE] =
		  $self->[OBJ_PROPS]->{$name}->[PROP_VALUE];
		$self->[OBJ_PROPS]->{$name}->[PROP_DIRTY] = 1;
	}

	my $dir = $self->get_directory();

	if (!ref($obj_val)) {
		if (!defined $dir) {
			confess("No directory for $self, trying to set $name to $obj_val");
		}
		$obj_val = $dir->retrieve($obj_val);
	}
	
	if ( (defined $dir) && (defined $obj_val) && ($obj_val->get_directory() eq $dir) ) {
		$self->[OBJ_PROPS]->{$name}->[PROP_VALUE]->[TYPE_OBJECT_ID] =
		  $obj_val->get_id();
		$self->[OBJ_PROPS]->{$name}->[PROP_VALUE]->[TYPE_OBJECT_REF] =
		  undef;
	} else {
		$self->[OBJ_PROPS]->{$name}->[PROP_VALUE]->[TYPE_OBJECT_ID] =
		  undef;
		$self->[OBJ_PROPS]->{$name}->[PROP_VALUE]->[TYPE_OBJECT_REF] =
		  $obj_val;
	}
	
	return $obj_val;
}

sub get {
	my ($pkg, $self, $name, $params) = @_;
	
	my $dir = $self->get_directory();
	my $id = $self->[OBJ_PROPS]->{$name}->[PROP_VALUE]->[TYPE_OBJECT_ID];
	
	if ((defined $id) && (defined $dir)) {
		return $dir->retrieve($id);
	} else {
		my $obj_val =
		  $self->[OBJ_PROPS]->{$name}->[PROP_VALUE]->[TYPE_OBJECT_REF];

		if ( (defined $obj_val) && (defined $dir) && ($obj_val->get_directory() eq $dir) ) {
			$self->[OBJ_PROPS]->{$name}->[PROP_VALUE]->[TYPE_OBJECT_ID] =
			  $obj_val->get_id();
			$self->[OBJ_PROPS]->{$name}->[PROP_VALUE]->[TYPE_OBJECT_REF] =
			  undef;
		}
		return $obj_val;
	}
}

1;

__END__
