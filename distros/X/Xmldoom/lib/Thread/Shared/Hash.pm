
package Thread::Shared::Hash;

use threads::shared '1.02', qw/ share is_shared /;

use Thread::Shared;
use strict;

sub TIEHASH 
{
	my $class = shift;
	my $value = shift;
	my $bless = shift;

	if ( not defined $value or not is_shared $value )
	{
		$value = &share({});
	}

	if ( $bless and $bless ne 'HASH' )
	{
		bless $value, $bless;
	}

	my $self = {
		hash => $value
	};

	bless  $self, $class;
	return $self;
}

sub get_shared_value { return shift->{hash}; }

sub FETCH
{
	my ($self, $key) = @_;

	my $value = $self->{hash}->{$key};
	if ( ref($value) )
	{
		$value = Thread::Shared::wrap($value);
	}
	return $value;
}

sub STORE
{
	my ($self, $key, $value) = @_;
	$self->{hash}->{$key} = Thread::Shared::make_sharable($value);
}

sub DELETE
{
	my ($self, $key) = @_;
	delete $self->{hash}->{$key};
}

sub CLEAR
{
	my $self = shift;

	foreach my $key ( keys %{$self->{hash}} )
	{
		delete $self->{hash}->{$key};
	}
}

sub EXISTS
{
	my ($self, $key) = shift;
	return exists $self->{hash}->{$key};
}

sub FIRSTKEY
{
	my $self = shift;
	# reset the each() iterator
	my $a = keys %{$self->{hash}};
	return each %{$self->{hash}};
}

sub NEXTKEY
{
	my $self = shift;
	return each %{$self->{hash}};
}

sub SCALAR
{
	my $self = shift;
	return scalar %{$self->{hash}};
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

