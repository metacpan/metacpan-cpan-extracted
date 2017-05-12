
package Xmldoom::Definition::Property::PlaceHolder;
use base qw(Xmldoom::Definition::Property);

use strict;

use Data::Dumper;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $parent;
	my $prop_name;

	if ( ref($args) eq 'HASH' )
	{
		$parent     = $args->{parent};
		$prop_name  = $args->{name};
	}
	else
	{
		$parent    = $args;
		$prop_name = shift;

		# if you don't know, then there is no need to know.
		$args = {
			parent => $parent,
			name   => $prop_name,
		};
	}

	my $self = $class->SUPER::new( $args );
	$self->{prop_args} = $args;

	bless  $self, $class;
	return $self;
}

sub get_prop_args { return shift->{prop_args}; }

sub get_data_type 
{
	return { type => 'custom' };
}

1;

