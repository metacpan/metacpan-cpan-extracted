package Zabbix::API::Item;

use strict;
use warnings;
use 5.010;
use Carp;

use Params::Validate qw/validate validate_with :types/;

use parent qw/Exporter Zabbix::API::CRUDE/;

use constant {
    ITEM_TYPE_ZABBIX => 0,
    ITEM_TYPE_SNMPV1 => 1,
    ITEM_TYPE_TRAPPER => 2,
    ITEM_TYPE_SIMPLE => 3,
    ITEM_TYPE_SNMPV2C => 4,
    ITEM_TYPE_INTERNAL => 5,
    ITEM_TYPE_SNMPV3 => 6,
    ITEM_TYPE_ZABBIX_ACTIVE => 7,
    ITEM_TYPE_AGGREGATE => 8,
    ITEM_TYPE_HTTPTEST => 9,
    ITEM_TYPE_EXTERNAL => 10,
    ITEM_TYPE_DB_MONITOR => 11,
    ITEM_TYPE_IPMI => 12,
    ITEM_TYPE_SSH => 13,
    ITEM_TYPE_TELNET => 14,
    ITEM_TYPE_CALCULATED => 15,
    ITEM_VALUE_TYPE_FLOAT => 0,
    ITEM_VALUE_TYPE_STR => 1,
    ITEM_VALUE_TYPE_LOG => 2,
    ITEM_VALUE_TYPE_UINT64 => 3,
    ITEM_VALUE_TYPE_TEXT => 4,
    ITEM_DATA_TYPE_DECIMAL => 0,
    ITEM_DATA_TYPE_OCTAL => 1,
    ITEM_DATA_TYPE_HEXADECIMAL => 2,
    ITEM_STATUS_ACTIVE => 0,
    ITEM_STATUS_DISABLED => 1,
    ITEM_STATUS_NOTSUPPORTED => 3
};

our @EXPORT_OK = qw/
ITEM_TYPE_ZABBIX
ITEM_TYPE_SNMPV1
ITEM_TYPE_TRAPPER
ITEM_TYPE_SIMPLE
ITEM_TYPE_SNMPV2C
ITEM_TYPE_INTERNAL
ITEM_TYPE_SNMPV3
ITEM_TYPE_ZABBIX_ACTIVE
ITEM_TYPE_AGGREGATE
ITEM_TYPE_HTTPTEST
ITEM_TYPE_EXTERNAL
ITEM_TYPE_DB_MONITOR
ITEM_TYPE_IPMI
ITEM_TYPE_SSH
ITEM_TYPE_TELNET
ITEM_TYPE_CALCULATED
ITEM_VALUE_TYPE_FLOAT
ITEM_VALUE_TYPE_STR
ITEM_VALUE_TYPE_LOG
ITEM_VALUE_TYPE_UINT64
ITEM_VALUE_TYPE_TEXT
ITEM_DATA_TYPE_DECIMAL
ITEM_DATA_TYPE_OCTAL
ITEM_DATA_TYPE_HEXADECIMAL
ITEM_STATUS_ACTIVE
ITEM_STATUS_DISABLED
ITEM_STATUS_NOTSUPPORTED/;

our %EXPORT_TAGS = (
    item_types => [
        qw/ITEM_TYPE_ZABBIX
        ITEM_TYPE_SNMPV1
        ITEM_TYPE_TRAPPER
        ITEM_TYPE_SIMPLE
        ITEM_TYPE_SNMPV2C
        ITEM_TYPE_INTERNAL
        ITEM_TYPE_SNMPV3
        ITEM_TYPE_ZABBIX_ACTIVE
        ITEM_TYPE_AGGREGATE
        ITEM_TYPE_HTTPTEST
        ITEM_TYPE_EXTERNAL
        ITEM_TYPE_DB_MONITOR
        ITEM_TYPE_IPMI
        ITEM_TYPE_SSH
        ITEM_TYPE_TELNET
        ITEM_TYPE_CALCULATED/
    ],
    value_types => [
        qw/ITEM_VALUE_TYPE_FLOAT
        ITEM_VALUE_TYPE_STR
        ITEM_VALUE_TYPE_LOG
        ITEM_VALUE_TYPE_UINT64
        ITEM_VALUE_TYPE_TEXT/
    ],
    data_types => [
        qw/ITEM_DATA_TYPE_DECIMAL
        ITEM_DATA_TYPE_OCTAL
        ITEM_DATA_TYPE_HEXADECIMAL/
    ],
    status_types => [
        qw/ITEM_STATUS_ACTIVE
        ITEM_STATUS_DISABLED
        ITEM_STATUS_NOTSUPPORTED/
    ]
);

sub id {

    ## mutator for id

    my ($self, $value) = @_;

    if (defined $value) {

        $self->data->{itemid} = $value;
        return $self->data->{itemid};

    } else {

        return $self->data->{itemid};

    }

}

sub prefix {

    my (undef, $suffix) = @_;

    if ($suffix) {

        return 'item'.$suffix;

    } else {

        return 'item';

    }

}

sub extension {

    return ( output => 'extend' );

}

sub collides {

    my $self = shift;

    return @{$self->{root}->query(method => $self->prefix('.get'),
                                  params => { filter => { key_ => $self->data->{key_} },
                                              hostids => [ $self->host->id ]})};

}

sub name {

    my $self = shift;

    return sprintf('%s/%s',
                   eval { $self->host->name } || '???',
                   $self->data->{key_} || '???');

}

sub graphs {

    ## accessor for this item's graphs

    my ($self, $value) = @_;

    if (defined $value) {

        croak 'Accessor graphs called as mutator';

    } else {

        unless (exists ($self->{graphs})) {

            my $graphs = $self->{root}->fetch('Graph', params => { itemids => [ $self->id ] });
            $self->{graphs} = $graphs;

        }

    }

    return $self->{graphs};

}

sub host {

    ## accessor for host

    my ($self, $value) = @_;

    if (defined $value) {

        croak 'Accessor host called as mutator';

    } else {

        unless (exists $self->{host}) {

            my $hosts = $self->{root}->fetch('Host', params => { hostids => [ $self->data->{hostid} ] });

            croak 'Unexpectedly found more than one host for a given item'
                if @{$hosts} > 1;

            $self->{host} = $hosts->[0];

        }

        return $self->{host};

    }

}

sub history {

    ## accessor for history

    ## DOES NOT CACHE!

    my $self = shift;

    my %extra_parameters = validate_with(params => \@_,
                                         spec => { time_from => { type => SCALAR, optional => 1 },
                                                   time_till => { type => SCALAR, optional => 1 } },
                                         allow_extra => 1);

    my $history = $self->{root}->query(method => 'history.get',
                                       params => { %extra_parameters,
                                                   itemids => [ $self->id ],
                                                   output => 'extend' });

    return $history;

}

sub delay {

    ## mutator for the item's polling period

    my ($self, $value) = @_;

    if ($value) {

        $self->data->{delay} = $value;

    }

    return $self->data->{delay};

}

1;
__END__
=pod

=head1 NAME

Zabbix::API::Item -- Zabbix item objects

=head1 SYNOPSIS

  use Zabbix::API::Item qw/:item_types/;

  # fetch a single item...
  my $item = $zabbix->fetch('Item', params => { filter => { itemid => 22379 } })->[0];

  # manipulate its properties...
  $item->data->{multiplier} = 3;

  # and update the properties on the server.
  $item->push;

  # fetch all items from a host
  my $host = $zabbix->fetch('Host', params => { filter => { hostid => 10105 } })->[0];
  my $items = $host->items;

  # create a new item
  my $new_item = Zabbix::API::Item->new(
      root => $zabbix,
      data => { type => ITEM_TYPE_SNMPV2C,
                value_type => ITEM_VALUE_TYPE_UINT64,
                snmp_oid => ...,
                snmp_community => ...,
                # that's right, key_
                key_ => 'mynewitem',
                # so far the following is the only way to create a "item belongs
                # to host" relationship
                hostid => $host->id,
      });

  # an itemid will be generated if the item does not already exist
  $new_item->push;

=head1 DESCRIPTION

Handles CRUD for Zabbix item objects.

This is a subclass of C<Zabbix::API::CRUDE>; see there for inherited methods.

=head1 METHODS

=over 4

=item collides()

Returns true if the item exists with this key on this hostid, false otherwise.

=item host()

Accessor for a local C<host> attribute, which it also happens to set from the
server data if it isn't set already.  The host is an instance of
C<Zabbix::API::Host>.

=item graphs()

Like C<host()>, returning an arrayref of C<Zabbix::API::Graph>
instances in which this item is involved.

=item history(PARAMS)

Accessor for the item's history data.  Calling this method does not store the
history data into the object, unlike other accessors.  History data is an AoH:

  [ { itemid => ITEMID,
      clock => UNIX_TIMESTAMP,
      value => VALUE }, ... ]

C<PARAMS> should be a hash containing arguments for the C<history.get> method
(see here: L<http://www.zabbix.com/documentation/1.8/api/history/get>).  The
time_from and time_till keys (with UNIX timestamps as values) are mandatory.
The C<itemids> and C<output> parameters are already set and cannot be
overwritten by the contents of C<PARAMS>.

=item delay(NEW_DELAY)

Mutator for the item's C<delay> value; that is, the polling period in
seconds.  This is just a shortcut to set C<delay> in the C<data>
hashref.  The method doesn't call C<pull()> or C<push()>, you need to
do it manually.

Returns the newly-set value.

=back

=head1 EXPORTS

Way too many constants, but for once they're documented (here:
L<http://www.zabbix.com/documentation/1.8/api/item/constants>).

Nothing is exported by default; you can use the tags C<:item_types>,
C<:value_types>, C<:data_types> and C<:status_types> (or import by name).

=head1 BUGS AND ODDITIES

This is probably because of the extremely smart way the Zabbix team has set up
their database schema, but what you'd expect to be C<"key"> in an item's data is
actually C<"key_">.

=head1 SEE ALSO

L<Zabbix::API::CRUDE>.

=head1 AUTHOR

Fabrice Gabolde <fabrice.gabolde@uperto.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 SFR

This library is free software; you can redistribute it and/or modify it under
the terms of the GPLv3.

=cut
