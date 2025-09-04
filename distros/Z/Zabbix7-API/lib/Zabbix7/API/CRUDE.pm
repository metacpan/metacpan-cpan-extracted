package Zabbix7::API::CRUDE;
use strict;
use warnings;
use 5.010;
use Carp;
use Scalar::Util qw/blessed/;
use Moo;
use Log::Any; # Added for better debugging

has 'data' => (is => 'ro', writer => '_set_data', default => sub { {} });
has 'root' => (is => 'ro', required => 1);

sub short_class {
    my $self = shift;
    my $class = blessed($self) // $self;
    $class =~ s/^Zabbix7::API:://;
    return $class;
}

sub id {
    my ($self, $value) = @_;
    if (defined $value) {
        $self->data->{$self->_prefix('id')} = $value;
    }
    return $self->data->{$self->_prefix('id')};
}

sub node_id {
    my $self = shift;
    croak(sprintf(q{%s class object does not have a local ID, can't tell the node ID},
                  $self->short_class)) unless $self->id;
    return unless $self->id > 100_000_000_000_000;
    return int($self->id/100_000_000_000_000);
}

sub _prefix {
    croak 'Class '.(ref shift).' does not implement required method _prefix()';
}

sub _extension {
    croak 'Class '.(ref shift).' does not implement required method _extension()';
}

sub name {
    croak 'Class '.(ref shift).' does not implement required method name()';
}

sub pull {
    my $self = shift;
    croak(sprintf(q{Cannot pull data from server into a %s without ID}, $self->short_class))
        unless $self->id;
    my $data = $self->root->query(
        method => $self->_prefix('.get'),
        params => {
            $self->_prefix('ids') => [$self->id],
            $self->_extension
        }
    )->[0];
    croak(sprintf(q{%s class object has a local ID that does not appear to exist on the server},
                  $self->short_class)) unless $data;
    $self->_set_data($data);
    Log::Any->get_logger->debug("Pulled data for $self->short_class ID: " . $self->id);
    return $self;
}

sub exists {
    my $self = shift;
    if (my $id = $self->id) {
        my $response = $self->root->query(
            method => $self->_prefix('.get'),
            params => {
                $self->_prefix('ids') => [$id],
                countOutput => 1
            }
        );
        Log::Any->get_logger->debug("Checked existence of $self->short_class ID: $id, exists: $response");
        return !!$response;
    } else {
        croak(sprintf(q{Cannot tell if a '%s' object exists on the server without the %s property},
                      $self->short_class, $self->_prefix('id')));
    }
}

sub create {
    my $self = shift;
    my %data = %{$self->data};
    if ($self->can('_readonly_properties')) {
        delete @data{keys(%{$self->_readonly_properties})};
    }

    my $results = eval {
        $self->root->query(
            method => $self->_prefix('.create'),
            params => \%data
        )
    };
    if (my $error = $@) {
        Log::Any->get_logger->error("Failed to create $self->short_class: $error");
        croak "Failed to create $self->short_class: $error";
    }

    my $id = $results->{$self->_prefix('ids')}->[0];
    $self->id($id);
    Log::Any->get_logger->debug("Created $self->short_class with ID: $id");

    if ($self->root->pull_after_push_mode) {
        $self->pull;
    }
    return $self;
}

sub update {
    my $self = shift;
    if (my $id = $self->id) {
        my %data = %{$self->data};
        if ($self->can('_readonly_properties')) {
            delete @data{keys(%{$self->_readonly_properties})};
        }
        $data{$self->_prefix('id')} = $id; # Ensure ID is included

        my $results = eval {
            $self->root->query(
                method => $self->_prefix('.update'),
                params => \%data
            )
        };
        if (my $error = $@) {
            Log::Any->get_logger->error("Failed to update $self->short_class ID: $id: $error");
            croak "Failed to update $self->short_class ID: $id: $error";
        }

        Log::Any->get_logger->debug("Updated $self->short_class ID: $id");
        if ($self->root->pull_after_push_mode) {
            $self->pull;
        }
    } else {
        croak(sprintf(q{Cannot update new %s, need to create it or fetch it first},
                      $self->short_class));
    }
    return $self;
}

sub delete {
    my $self = shift;
    if (my $id = $self->id) {
        my $response = eval {
            $self->root->query(
                method => $self->_prefix('.delete'),
                params => [{ $self->_prefix('id') => $id }] # Zabbix 7.0 expects array of objects
            )
        };
        if (my $error = $@) {
            Log::Any->get_logger->error("Failed to delete $self->short_class ID: $id: $error");
            croak "Failed to delete $self->short_class ID: $id: $error";
        }
        Log::Any->get_logger->debug("Deleted $self->short_class ID: $id");
    } else {
        croak(sprintf(q{Useless call of delete() on a %s that does not have a %s},
                      $self->short_class, $self->_prefix('id')));
    }
    return $self;
}

1;
__END__
=pod

=head1 NAME

Zabbix7::API::CRUDE -- Base abstract class for most Zabbix7::API::* objects

=head1 SYNOPSIS

  package Zabbix7::API::Unicorn;

  use Moo;
  extends 'Zabbix7::API::CRUDE';

  # now override some virtual methods so that it works for the specific case of
  # unicorns

  sub id { ... }
  sub _prefix { ... }
  sub _extension { ... }

=head1 DESCRIPTION

This module handles most aspects of pushing, pulling and deleting the
various types of Zabbix objects.  You do not want to use this
directly; a few abstract methods need to be implemented by a subclass.

=head1 ATTRIBUTES

Note that subclasses may define their own attributes in addition to
the ones in this base class.

=head2 data

(read-only hashref of object properties, defaults to C<{}>)

This is where the object properties obtained from the server are
stored.  To update the object on the server, modify the contents of
the hashref and call the C<update> method.  Similarly, to create a
brand new object on the server, create a Perl object with the desired
properties in the C<data> attribute, and call the C<create> method.

=head2 root

(read-only required L<Zabbix7::API> instance)

Reference to the current Zabbix connection object.

=head1 METHODS

=head2 _readonly_properties (optional abstract method)

  (not intended for public consumption)

This method, if implemented in a subclass, must return a hashref whose
keys are property names.  Those properties will be filtered out when
the create and update methods are called.  This is sometimes necessary
because Zabbix complains that read-only properties must not be
updated, even when their values have not changed.

=head2 create

  my $unicorn = Zabbix7::API::Unicorn->new(...);
  $unicorn->create;

This method calls the corresponding API C<CLASS.create> method, which
returns the ID of the new object.  This ID is then set in the object.

If C<pull_after_push_mode> is true in the L<Zabbix7::API> object, the
API C<CLASS.get> method is then called to fetch the values of all
server-generated properties.

=head2 delete

  $unicorn->delete;

This method calls the corresponding API C<CLASS.delete> method.  The
object itself is not modified; you should probably stop using it
afterwards as it will no longer exist on the server.

An exception is thrown if the object does not have an ID.

=head2 exists

  $unicorn->exists or say 'deleted';

This method checks that the ID still exists on the server.  This is
usually a good way to determine if the object has been deleted on the
server, since Zabbix object IDs are not usually reused.

An exception is thrown if the object does not have an ID.

=head2 _extension (required abstract method)

  (not intended for public consumption)

This method's return value will be added to the API method call
parameters when trying to fetch an object from the server.  It should
return valid C<CLASS.get> parameters as a hash (not a hashref, mind).
E.g., L<Zabbix7::API::Item>'s implementation is as follows:

  sub _extension {
      return (output => 'extend');
  }

=head2 id (required abstract method)

  # accessor
  say 'the id is '. $unicorn->id;
  # mutator
  $unicorn->id(3);

This method must implement a mutator for the object's ID.  This is
generally a wrapper around the "unicornid" key in the data attribute.

=head2 name (optional abstract method)

  say 'this thing is ' . $unicorn->name;

This method should return a human-readable name for the object;
e.g. the implementation in the L<Zabbix7::API::Item> class returns the
parent host's name and the item's key, separated by a slash.  No
guarantees are made on the unicity or even usefulness of any
implementation of this method, nor are any required.

Currently, not all subclasses implement this method, since it is
optional.  If you have a good implementation for a missing C<name>
method, please send a patch!

=head2 node_id

  say 'the unicorn lives on node ' . $unicorn->node_id;

This method returns the object's node's ID, or false if it does not
live on a decentralized setup.  Note that node-based setups are being
deprecated in the 2.x series.

An exception is thrown if the object does not have an ID.

=head2 _prefix (required abstract method)

  (not intended for public consumption)

This method is where most class differentiation is done.  It receives
a single argument, usually a method name (prepended by a dot), and it
should return the derivation appropriate for the class.

Most implementations just return a constant string prepended to the
argument, e.g. Item's implementation returns "item$suffix":
"item.create", etc.  However, some implementations are more
complicated; the Macro class, for instance, needs to check the
instance to determine if it is used as a host macro or a global macro.

=head2 pull

  $unicorn->pull;

The C<pull> method fetches an object's properties from the server and
sets the C<data> attribute with them.

An exception is thrown if the object does not have an ID.

Note that this method is not aware if you previously retrieved the
object with an "output" parameter to limit the columns retrieved, so
it will pull all columns from the server every time.

=head2 short_class

  # this is a Unicorn
  say 'this is a ' . $unicorn->short_class;

This method returns a shortened class name.  The "Zabbix7::API::"
prefix is removed.

=head2 update

  $unicorn->data->{some_property} = 'some_value';
  $unicorn->update;

This is the opposite of C<pull>.

=head1 "PARTIAL" SUBCLASSES

Some subclasses do not actually need to be a full implementation to be
useful; e.g. the L<Zabbix7::API::HostInterface> class is only ever
manipulated through L<Zabbix7::API::Host> instances.  Calling C<fetch>
with the intent of creating objects of these classes will throw an
exception.

=head1 SEE ALSO

L<Zabbix7::API>
The Zabbix API documentation, at L<https://www.zabbix.com/documentation/current/en/manual/api>

=head1 AUTHOR

SCOTTH

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, 2012, 2013, 2014 SFR
Copyright (C) 2020 Fabrice Gabolde
Copyright (C) 2025 ScottH

This library is free software; you can redistribute it and/or modify
it under the terms of the GPLv3.

=cut
