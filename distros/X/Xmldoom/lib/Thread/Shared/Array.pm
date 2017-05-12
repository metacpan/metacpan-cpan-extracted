
package Thread::Shared::Array;

use threads::shared '1.02', qw/ share is_shared /;

use Thread::Shared;
use strict;

sub TIEARRAY
{
	my $class = shift;
	my $value = shift;

	if ( not defined $value or not is_shared $value )
	{
		$value = &share([]);
	}

	my $self = {
		array => $value
	};

	bless  $self, $class;
	return $self;
}

sub FETCH
{
	my ($self, $index) = @_;
	my $value = $self->{array}->[$index];
	if ( ref($value) )
	{
		$value = Thread::Shared::wrap($value);
	}
	return $value;
}

sub STORE
{
	my ($self, $index, $value) = @_;
	$self->{array}->[$index] = Thread::Shared::make_shared($value);
}

sub FETCHSIZE
{
	my $self = shift;
	return scalar @{$self->{array}};
}

sub STORESIZE
{
	my ($self, $count) = shift;

	if ( $count > $self->FETCHSIZE() )
	{
		foreach ( $count - $self->FETCHSIZE() .. $count )
		{
			$self->STORE($_, undef);
		}
	}
	elsif ( $count < $self->FETCHSIZE() )
	{
		foreach ( 0 .. $self->FETCHSIZE() - $count - 2 )
		{
			$self->POP();
		}
	}
}

sub EXTEND
{
	my ($self, $count) = shift;
	$self->STORESIZE($count);
}

sub EXISTS
{
	my ($self, $index) = shift;
	return exists $self->{array}->[$index];
}

sub DELETE
{
	my ($self, $index) = shift;
	delete $self->{array}->[$index];
}

sub CLEAR
{
	my $self = shift;
	$self->{array} = &share([]);
}

sub PUSH
{
	my $self = shift;
	foreach my $item ( @_ )
	{
		push @{$self->{array}}, Thread::Shared::make_sharable($item);
	}
	return $self->FETCHSIZE();
}

sub POP
{
	my $self = shift;
	my $value = pop @{$self->{array}};
	if ( ref($value) )
	{
		$value = Thread::Shared::wrap($value);
	}
	return $value;
}

sub SHIFT
{
	my $self = shift;
	my $value = shift @{$self->{array}};
	if ( ref($value) )
	{
		$value = Thread::Shared::wrap($value);
	}
	return $value;
}

sub UNSHIFT
{
	my $self = shift;
	my $value = unshift @{$self->{array}};
	if ( ref($value) )
	{
		$value = Thread::Shared::wrap($value);
	}
	return $value;
}

sub SPLICE
{
	my ($self, $offset, $length) = (shift, shift, shift);
	my @value = splice @{$self->{array}}, $offset, $length, @_;
	my $ref   = Thread::Shared::wrap(\@value);
	return @$ref;
}

sub UNTIE
{
	my $self = shift;
	# TODO: me!
}

sub DESTROY
{
	my $self = shift;
	# TODO: me!
}

1;

