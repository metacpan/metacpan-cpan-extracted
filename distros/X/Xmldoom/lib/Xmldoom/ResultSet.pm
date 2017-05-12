
package Xmldoom::ResultSet;

use strict;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $class_name;
	my $result;
	my $conn;
	my $parent;

	if ( ref($args) eq 'HASH' )
	{
		$class_name = $args->{class};
		$result     = $args->{result};
		$conn       = $args->{conn};
		$parent     = $args->{parent};
	}
	else
	{
		$class_name = $args;
		$result     = shift;
		$conn       = shift;
		$parent     = shift;
	}

	my $self = {
		class  => $class_name,
		result => $result,
		conn   => $conn,
		parent => $parent,
	};

	bless  $self, $class;
	return $self;
}

sub next
{
	my $self = shift;

	if ( not $self->{result}->next() )
	{
		if ( $self->{conn} )
		{
			$self->{conn}->disconnect();
			$self->{conn} = undef;
		}

		return 0;
	}

	return 1;
}

sub get_object
{
	my $self = shift;

	# create our object
	return $self->{class}->new(undef, { 
		data   => $self->{result}->get_row(),
		parent => $self->{parent}
	});
}

sub DESTROY
{
	my $self = shift;

	if ( $self->{conn} )
	{
		$self->{conn}->disconnect();
		$self->{conn} = undef;
	}
}

1;

