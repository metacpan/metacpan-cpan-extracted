###########################################################################
### Trinket::DataType::object_list
###
### Ordered list of objects datatype handler
###
### $Id: Object.pm,v 1.3 2001/02/19 20:01:53 deus_x Exp $
###
### TODO:
###
###
###########################################################################

package Trinket::DataType::object_list;

BEGIN {
	our $VERSION = "0.0";
    our @ISA = qw( Trinket::DataType );
}

use strict;
use Trinket::Object;
use Trinket::DataType;

use constant TYPE_OBJECT_REF => 0;
use constant TYPE_OBJECT_ID  => 1;

sub set {
	my ($pkg, $self, $name, $in_list) = @_;

	return undef if (ref($in_list) ne 'ARRAY');
	
	### If this property isn't dirty already, save the clean value and
	### then flag it as dirty.
	if (! $self->[OBJ_PROPS]->{$name}->[PROP_DIRTY]) {
		$self->[OBJ_PROPS]->{$name}->[PROP_CLEAN_VALUE] =
		  $self->[OBJ_PROPS]->{$name}->[PROP_VALUE];
		$self->[OBJ_PROPS]->{$name}->[PROP_DIRTY] = 1;
	}

	my $dir = $self->get_directory();
	my $obj_list = [];

	foreach my $obj_val (@$in_list) {

		my $curr_val = [];

		if (!ref($obj_val)) {
			if (defined $dir) {
				$obj_val = $dir->retrieve($obj_val);
			} else {
				next;
			}
		}

		if ( (defined $dir) && (defined $obj_val) && ($obj_val->get_directory() eq $dir) ) {
			$curr_val->[TYPE_OBJECT_ID]  = $obj_val->get_id();
			$curr_val->[TYPE_OBJECT_REF] = undef;
			push @$obj_list, $curr_val;
		} else {
			$curr_val->[TYPE_OBJECT_ID]  = undef;
			$curr_val->[TYPE_OBJECT_REF] = $obj_val;
			push @$obj_list, $curr_val;
		}
	}
	
	### Finally, set the new value.
	$self->[OBJ_PROPS]->{$name}->[PROP_VALUE] = $obj_list;
	return $in_list;
}

sub get {
	my ($pkg, $self, $name) = @_;
	
	my $dir      = $self->get_directory();
	my $list     = $self->[OBJ_PROPS]->{$name}->[PROP_VALUE];
	my $out_list = [];
	
	return undef if (ref($list) ne 'ARRAY' );

	for (my $i=0; $i<scalar(@$list); $i++) {
		my $id = $self->[OBJ_PROPS]->{$name}->[PROP_VALUE]->[$i]->[TYPE_OBJECT_ID];
		
		if ((defined $id) && (defined $dir)) {
			push @$out_list, $dir->retrieve($id);
		} else {
			my $obj_val =
			  $self->[OBJ_PROPS]->{$name}->[PROP_VALUE]->[$i]->[TYPE_OBJECT_REF];
			if ( (defined $dir) && ($obj_val->get_directory() eq $dir) ) {
				$self->[OBJ_PROPS]->{$name}->[PROP_VALUE]->[$i]->[TYPE_OBJECT_ID] =
				  $obj_val->get_id();
				$self->[OBJ_PROPS]->{$name}->[PROP_VALUE]->[$i]->[TYPE_OBJECT_REF] =
				  undef;
			}
			push @$out_list, $obj_val;
		}
	}

	return $out_list;
}


1;

__END__

