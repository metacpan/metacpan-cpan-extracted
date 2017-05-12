package Tie::JCR;

use strict;
use warnings;

our $VERSION = '0.02';

use Carp;
use Java::JCR;

=head1 NAME

Tie::JCR - A tied hash interface for Java::JCR::Node

=head1 SYNOPSIS

  use Data::Dumper;
  use Java::JCR;
  use Java::JCR::Jackrabbit;
  use Tie::JCR;

  my $repository = Java::JCR::Jackrabbit->new;
  my $session = $respoitory->session;
  my $root_node = $session->get_root_node;
  tie my %root, 'Tie::JCR', $root_node;

  # Expensive, but we can dump the whole tree:
  print Dumper(\%root);

  my $type = $root{'jcr:primaryType'};
  my $uuid = $root{'jcr:uuid'};
  my $foo = $root{'foo'};
  my $nested_bar = $root{'qux'}{'baz'}{'bar'};

=head1 DESCRIPTION

This provides a very simple, read-only interface to a node from L<Java::JCR>. Each key represents the names of items within the node. Each value is either a scalar for non-multiple child properties, an array for multiple child properties, or nested hashes for child nodes. In the case of same-name children, you may see an array returned containing scalars and hashes for a mixture of properties and nodes.

=head2 CHANGES ARE TRANSIENT

Changes made to the tied hash are transient and only act to override the local cache. If you want to make changes to node, you must do so through the L<Java::JCR> API. This is primarily meant as a convenience interface, not as a serious front-end to the JCR.

=head2 SUPPORTED OPERATIONS

The only hash operation that isn't implemented is CLEAR. Therefore, all of the following will work:

  tie my %hash, 'Tie::JCR', $node;
  my $value = $node{'property_name'};
  my $child_node = $node{'node_name'};

  # store a value temporarily IN THIS HASH ONLY, doesn't affect the JCR
  $node{'temp_value'} = 'blah';

  # make the property undefined IN THIS HASH ONLY, doesn't affect the JCR
  delete $node{'property_name'};

  # defined === exists since null values are not permitted in the JCR
  my $has_item = exists $node{'item_name'};

  my @keys = keys %node;
  my @values = values %node;
  while (my ($key, $value) = each %node) {
      print $key, " = ", $value, "\n";
  }

  # returns true if has_nodes or has_properties
  my $has_children = scalar %node;

=head2 CACHING

The fetch, store, and delete operations modify an internal cache. By using the cache, some speed can be gained by avoiding a second JCR API call. This is also how the store and delete operations make transient changes, by storing values in the cache.

=head2 INTERNAL METHODS

In addition, you can use the tied object to get the node back:

  my $node_obj = (tied %node)->node;

You may also wish to clear out any local changes used with store or otherwise held in the internal cache:

  (tied %node)->clear_cache;

=head2 JCR TYPES

The fetch operation handles all the various JCR types properly. Longs will be treated as longs, doubles as doubles, booleans as booleans, dates as dates, references as nodes, and everything else as a string.

=cut

sub TIEHASH {
    my ($class, $node) = @_;
    return bless { 
        node  => $node,
        cache => {},
    }, $class;
}

sub node {
    my $self = shift;
    return $self->{node};
}

sub cache {
    my $self = shift;
    return $self->{cache};
}

sub clear_cache {
    my $self = shift;
    $self->{cache} = {};
}

sub FETCH {
    my ($self, $key) = @_;

    if (exists $self->cache->{$key}) {
        return $self->cache->{$key};
    }

    else {
        my $node = $self->node;
        if ($node->has_node($key)) {
            tie my %child_node, 'Tie::JCR', $node->get_node($key);
            return $self->cache->{$key} = \%child_node;
        }

        elsif ($node->has_property($key)) {
            my $property   = $node->get_property($key);
            my $definition = $property->get_definition;
            my $type       = $definition->get_required_type;
            my $multiple   = $definition->is_multiple;

            my $get_function 
                = $type == $Java::JCR::PropertyType::DATE      ? 'get_date'
                : $type == $Java::JCR::PropertyType::BOOLEAN   ? 'get_boolean'
                : $type == $Java::JCR::PropertyType::DOUBLE    ? 'get_double'
                : $type == $Java::JCR::PropertyType::LONG      ? 'get_long'
                :                                                'get_string';

            my $value 
                = $multiple ? 
                    [ map { $_->$get_function() } @{ $property->get_values } ]
                :   $property->$get_function();

            if ($type == $Java::JCR::PropertyType::REFERENCE) {
                my $session = $node->get_session;

                if ($multiple) {
                    $value = {
                        map {
                            my $node = $session->get_node_by_uuid($_);
                            tie my %node, 'Tie::JCR', $node;
                            ($node->get_name => \%node);
                        } @$value
                    };
                }

                else {
                    $value = $session->get_node_by_uuid($value);
                }
            }

            return $self->cache->{$key} = $value;
        }

        else {
            return $self->cache->{$key} = undef;
        }
    }
}

sub STORE {
    my ($self, $key, $value) = @_;

    return $self->cache->{$key} = $value;
}

sub DELETE {
    my ($self, $key, $value) = @_;

    $self->cache->{$key} = undef;
}

sub CLEAR {
    my ($self) = @_;

    die "CLEAR is not implemented.";
}

sub EXISTS {
    my ($self, $key) = @_;
    my $node = $self->node;

    if (exists $self->cache->{$key}) {
        return defined $self->cache->{$key};
    }

    else {
        return $node->has_node($key) || $node->has_property($key);
    }
}

sub FIRSTKEY {
    my ($self) = @_;
    my $node = $self->node;

    $self->{current_iterators} = [ $node->get_nodes, $node->get_properties ];

    return $self->NEXTKEY;
}

sub NEXTKEY {
    my ($self) = @_;

    my $current_iterators = $self->{current_iterators};
    if (defined $current_iterators && @$current_iterators) {
        while (@$current_iterators && !$current_iterators->[0]->has_next) {
            shift @$current_iterators;
        }

        if (!@$current_iterators) {
            return;
        }

        my $curr_iter = $current_iterators->[0];
        
        my $item 
            = $curr_iter->can('next_node')     ? $curr_iter->next_node
            : $curr_iter->can('next_property') ? $curr_iter->next_property
            : $curr_iter->can('next')          ? $curr_iter->next
            : croak "Unknown iterator type missing next_node, ",
                    "next_property, and next method. An iterator must ",
                    "provide one of those.";

        return $item->get_name;
    }

    else {
        return;
    }
}

sub SCALAR {
    my ($self) = @_;
    my $node = $self->node;

    return $node->has_nodes || $node->has_properties;
}

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2006 Andrew Sterling Hanenkamp E<lt>hanenkamp@cpan.orgE<gt>.  All 
Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.

=cut

1
