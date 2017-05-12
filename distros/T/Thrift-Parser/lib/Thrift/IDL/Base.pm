package Thrift::IDL::Base;

=head1 NAME

Thrift::IDL::Base

=head1 DESCRIPTION

Base class for most L<Thrift::IDL> subclasses.

=cut

use strict;
use warnings;
use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(parent comments));

=head1 METHODS

=head2 parent

=head2 comments

Accessors

=cut

use overload
	'""' => \&_overload_string,
	'eq' => \&_overload_string;

sub _overload_string {
	my $self = shift;
	return $self->can('to_str') ? $self->to_str : ref($self);
}

=head2 children_of_type ($type)

  my $comments = $obj->children_of_type('Thrift::IDL::Comment');

Returns an array ref of all child objects of the given class

=cut

sub children_of_type {
    my ($self, $type) = @_;

    my $cache_key = 'children.' . $type;
    return $self->{$cache_key} if $self->{$cache_key};

    $self->{$cache_key} = [];
    foreach my $child (@{ $self->{children} }) {
        push @{ $self->{$cache_key} }, $child if $child->isa($type);
    }
    return $self->{$cache_key};
}

=head2 array_search ($value, $array_method, $method)

  my $Calculator_service = $document->array_search('Calculator', 'services', 'name');

Given a method $array_method which returns an array of objects on $self, return the object which has $value = $object->$method

=cut

sub array_search {
    my ($self, $value, $array_method, $method) = @_;

    my $cache_key = join '.', 'array_idx', $array_method, $method;
    if (! $self->{$cache_key}) {
        $self->{$cache_key} = {
            map { $_->$method => $_ }
            @{ $self->$array_method }
        };
    }
    return $self->{$cache_key}{$value};
}

=head2 setup

A struct has children of type L<Thrift::IDL::Field> and L<Thrift::IDL::Comment>. Walk through all these children and associate the comments with the fields that preceeded them (if perl style) or with the field following.

=cut

sub _setup {
    my ($self, $key) = @_;
	return if $self->{"_setup_called_$key"}++;

	my (@fields, @comments, $last_field);
	foreach my $child (@{ $self->$key }) {
		if ($child->isa('Thrift::IDL::Field')) {
			$child->{comments} = [ @comments ];
			push @fields, $child;
			$last_field = $child;
			@comments = ();
		}
		elsif ($child->isa('Thrift::IDL::Comment')) {
			# Perl-style comments are postfix to the previous element
			if ($child->style eq 'perl_single') {
				push @{ $last_field->{comments} }, $child;
			}
			else {
				push @comments, $child;
			}
		}
		else {
			die "Unrecognized child of ".ref($self)." (".ref($child)."\n";
		}
	}
	$self->$key(\@fields);
}

1;
