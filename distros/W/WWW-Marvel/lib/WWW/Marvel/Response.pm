package WWW::Marvel::Response;
use base qw/ Class::Accessor /;
use strict;
use warnings;
use WWW::Marvel::Factory::Entity;
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw/ attributionHTML attributionText code copyright etag status /);

sub get_count  { $_[0]->{data}->{count} }
sub get_limit  { $_[0]->{data}->{limit} }
sub get_offset { $_[0]->{data}->{offset} }
sub get_total  { $_[0]->{data}->{total} }

# iterator
sub get_next_entity {
	my ($self) = @_;
	my $data = $self->_get_results->[ $self->_get_entity_index ];
	return if !defined $data;
	my $ent = $self->_entity_factory->identify( $data );
	return $ent;
}

sub reset_entity_iterator {
	my ($self) = @_;
	delete $self->{_internal}->{entity_index};
	return $self;
}

sub _entity_factory {
	$_[0]->{_internal}->{entity_factory} //= do {
		WWW::Marvel::Factory::Entity->new();
	};
}

sub _get_entity_index {
	my ($self) = @_;
	my $i = $self->{_internal}->{entity_index} // 0;
	if ($i < $self->get_count) {
		$self->{_internal}->{entity_index} = $i +1;
	}
	return $i;
}

sub _get_results { $_[0]->{data}->{results} }

1;
