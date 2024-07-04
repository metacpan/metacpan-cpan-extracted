package TodoStorage;

use Kelp::Base;
use List::Util qw(max);

attr storage => sub { {} };

# A very simple storage class for TODOs. Keeps them in local process memory, so
# they are lost after restarting the application.

sub stored
{
	my ($self) = @_;

	return [keys %{$self->storage}];
}

sub get
{
	my ($self, $id) = @_;

	return $self->storage->{$id};
}

sub set
{
	my ($self, $id, $entity) = @_;
	return undef unless defined $entity;

	if (!defined $id) {
		my $max = max keys %{$self->storage};
		$id = ($max // 0) + 1;
	}

	$self->storage->{$id} = $entity;
	return $id;
}

sub unset
{
	my ($self, $id) = @_;
	my $stored = delete $self->storage->{$id};

	return defined $stored;
}

1;

