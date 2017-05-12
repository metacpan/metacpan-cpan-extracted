
package Xmldoom::Object::Attribute;

use strict;

sub new
{
	my $class = shift;
	my $value = shift;

	my $self = {
		value => $value
	};

	bless  $self, $class;
	return $self;
}

sub is_local { return 1; }
sub get      { return shift->{value}; }

sub set
{
	my ($self, $value) = @_;
	$self->{value} = $value;
}

1;

