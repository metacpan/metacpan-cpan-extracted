
package Xmldoom::Object::LinkAttribute;

use strict;

sub new
{
	my $class = shift;
	my $attr  = shift;

	my $self = {
		attr => $attr
	};

	bless  $self, $class;
	return $self;
}

sub is_local { return 0; }
sub get      { return shift->{attr}->get(); }

sub set
{
	die "You shouldn't be setting LinkAttributes!";
}

1;

