# reform::Property.pm
# Binds a scalar (typically an instance field) to getter
# and setter methods.
#
# Written by Henning Koch <jaz@netalive.org>.

package reform::Property;

use strict;

# this is the constructor for scalar ties
sub TIESCALAR {
	my ($class, $object, $field) = @_;
	my $self = { object => $object,
	             field  => $field };
	bless($self, $class);
	$self;
} 

# this intercepts read accesses
sub FETCH 
{
	my ($self) = @_;
	my $getter = "\$self->{object}->get_" . $self->{field} . "()";
	# print "$getter\n";
	my $re = eval $getter;
	$@ and die "Error performing $getter: $@";
	$re;
} 

# this intercepts write accesses
sub STORE 
{
	my ($self, $value) = @_;
	my $setter = "\$self->{object}->set_" . $self->{field} . "(\$value)";
	# print "$setter\n";
	eval $setter;
	$@ and die "Error performing $setter: $@";
} 

1;

