###########################################################################
### Trinket::DataType::default
###
### Default object datatype handler
###
### $Id: Object.pm,v 1.3 2001/02/19 20:01:53 deus_x Exp $
###
### TODO:
###
###
###########################################################################

package Trinket::DataType::default;

BEGIN {
	our $VERSION = "0.0";
    our @ISA = qw( Trinket::DataType );
}

use strict;
no warnings qw( uninitialized );
use Trinket::Object;
use Trinket::DataType;

sub set {
	my ($pkg, $self, $name, $val) = @_;
	
	### If there is no change in values, do nothing.
	return $val if ($val eq $self->[OBJ_PROPS]->{$name}->[PROP_VALUE]);
	
	### If this property isn't dirty already, save the clean value and
	### then flag it as dirty.
	if ( (! $self->[OBJ_PROPS]->{$name}->[PROP_DIRTY]) &&
		 (! ($name eq 'class') || ($name eq 'directory') ) ) {

		$self->[OBJ_PROPS]->{$name}->[PROP_CLEAN_VALUE] =
		  $self->[OBJ_PROPS]->{$name}->[PROP_VALUE];
		$self->[OBJ_PROPS]->{$name}->[PROP_DIRTY] = 1;
	}
	
	### Finally, set the new value.
	return $self->[OBJ_PROPS]->{$name}->[PROP_VALUE] = $val;
}

sub get {
	my ($pkg, $self, $name) = @_;
	
	return $self->[OBJ_PROPS]->{$name}->[PROP_VALUE];
}

1;

__END__
