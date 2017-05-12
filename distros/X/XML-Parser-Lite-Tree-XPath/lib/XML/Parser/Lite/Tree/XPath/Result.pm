package XML::Parser::Lite::Tree::XPath::Result;

use strict;
use Data::Dumper;

#
# types:
#
# Error		- value is error message string
# number	- value is numeric scalar
# boolean	- value is boolean scalar
# string	- value is string scalar
# nodeset	- value is arrayref of nodes and/or attributes
# node		- value is node
# attribute	- value is attribute
#

sub new {
	my $class = shift;
	my $self = bless {}, $class;

	$self->{type} = shift;
	$self->{value} = shift;

	return $self;
}

sub is_error {
	my ($self) = @_;
	return ($self->{type} eq 'Error') ? 1 : 0;
}

sub normalize {
	my ($self) = @_;

	if ($self->{type} eq 'nodeset'){

		# uniquify and sort
		my %seen = ();
		my @tags =  sort {
			$a->{order} <=> $b->{order}
		} grep {
			! $seen{$_->{order}} ++
		} @{$self->{value}};

		$self->{value} = \@tags;
	}
}

sub ret {
	my ($self, $a, $b) = @_;
	return  XML::Parser::Lite::Tree::XPath::Result->new($a, $b);
}

sub get_type {
	my ($self, $type) = @_;

	return $self if $self->is_error;

	return $self->get_number  if $type eq 'number';
	return $self->get_boolean if $type eq 'boolean';
	return $self->get_string  if $type eq 'string';
	return $self->get_nodeset if $type eq 'nodeset';
	return $self->get_node	  if $type eq 'node';

	return $self->ret('Error', "Can't get type '$type'");
}

sub get_boolean {
	my ($self) = @_;

	return $self if $self->{type} eq 'boolean';
	return $self if $self->is_error;

	if ($self->{type} eq 'number'){
		return $self->ret('boolean', 0) if $self->{value} eq 'NaN';
		return $self->ret('boolean', $self->{value} != 0);
	}

	if ($self->{type} eq 'string'){
		return $self->ret('boolean', length $self->{value} > 0);
	}

	if ($self->{type} eq 'nodeset'){
		return $self->ret('boolean', scalar(@{$self->{value}}) > 0);
	}

	if ($self->{type} eq 'node'){
		# todo
	}

	return $self->ret('Error', "can't convert type $self->{type} to boolean");
}

sub get_string {
	my ($self) = @_;

	return $self if $self->{type} eq 'string';
	return $self if $self->is_error;


	if ($self->{type} eq 'nodeset'){
		return $self->ret('string', '') unless scalar @{$self->{value}};

		my $node = $self->ret('node', $self->{value}->[0]);

		return $node->get_string;
	}

	if ($self->{type} eq 'node'){

		return $self->ret('string', $self->{value}->{value}) if $self->{value}->{type} eq 'attribute';

		die "can't convert a node of type $self->{value}->{type} to a string";
	}

	if ($self->{type} eq 'number'){
		return $self->ret('string', "$self->{value}");
	}

	if ($self->{type} eq 'boolean'){
		return $self->ret('string', $self->{value} ? 'true' : 'false');
	}

	return $self->ret('Error', "can't convert type $self->{type} to string");
}

sub get_nodeset {
	my ($self) = @_;

	return $self if $self->{type} eq 'nodeset';
	return $self if $self->is_error;

	if ($self->{type} eq 'node'){
		return $self->ret('nodeset', [$self->{value}]);
	}

	return $self->ret('Error', "can't convert type $self->{type} to nodeset");
}

sub get_node {
	my ($self) = @_;

	return $self if $self->{type} eq 'node';
	return $self if $self->is_error;

	return $self->ret('Error', "can't convert type $self->{type} to node");
}

sub get_number {
	my ($self) = @_;

	return $self if $self->{type} eq 'number';
	return $self if $self->is_error;

	if ($self->{type} eq 'string'){
		if ($self->{value} =~ m!^[\x20\x09\x0D\x0A]*(-?([0-9]+(\.([0-9]+)?)?)|(\.[0-9]+))[\x20\x09\x0D\x0A]*$!){

			return $self->ret('number', $1);
		}else{
			return $self->ret('number', 'NaN');
		}
	}

	if ($self->{type} eq 'boolean'){
		return $self->ret('number', $self->{value}?1:0);
	}

	return $self->ret('Error', "can't convert type $self->{type} to number");
}

1;
