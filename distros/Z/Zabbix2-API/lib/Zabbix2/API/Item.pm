package Zabbix2::API::Item;

use strict;
use warnings;
use 5.010;
use Carp;

use Params::Validate qw/validate validate_with :types/;
use Text::ParseWords;

use Moo;
extends qw/Exporter Zabbix2::API::CRUDE/;

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

has 'graphs' => (is => 'ro',
                 lazy => 1,
                 builder => '_fetch_graphs');

has 'host' => (is => 'ro',
               lazy => 1,
               builder => '_fetch_host');

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

sub _readonly_properties {
    ## hash of item properties that cannot be updated; they will be
    ## removed before pushing the item to the server
    return {
        itemid => 1,
        error => 1,
        flags => 1,
        lastclock => 1,
        lastns => 1,
        lastvalue => 1,
        prevvalue => 1,
        state => 1,
        templateid => 1,
    };
}

sub _prefix {
    my ($class, $suffix) = @_;
    if ($suffix) {
        return 'item'.$suffix;
    } else {
        return 'item';
    }
}

sub _extension {
    return ( output => 'extend' );
}

sub name {
    my $self = shift;
    return $self->data->{name};
}

sub expanded_name {

    my $self = shift;

    # we are not expanding hostmacros or globalmacros, those are problematic
    my $key = $self->data->{key_};
    my $token_re = qr/[0-9a-zA-Z_.-]+/;
    $key =~ m/^$token_re\[(.*)\]$/;
    my $arg_list = $1;

    return $self->name unless $arg_list;

    my @args = parse_line(',', 0, $arg_list);

    my $name = $self->data->{name};
    $name =~ s/\$(\d)/$args[$1 -1]/e;

    # if ($name =~ m/\{\$[A-Z0-9_.]+\}/) {
    #     die "there are macro names in this name, can't expand them";
    # }

    return $name;

}

sub _fetch_graphs {
    my $self = shift;
    my $graphs = $self->{root}->fetch('Graph', params => { itemids => [ $self->id ] });
    return $graphs;
}

sub _fetch_host {
    my $self = shift;
    my $host = $self->{root}->fetch_single('Host', params => { hostids => [ $self->data->{hostid} ] });
    return $host;
}

sub history {
    my ($self, %params) = @_;
    my $history = $self->{root}->query(method => 'history.get',
                                       params => { itemids => [ $self->id ],
                                                   output => 'extend',
                                                   history => $self->data->{value_type},
                                                   %params });
    return $history;
}

1;
__END__
=pod

=head1 NAME

Zabbix2::API::Item -- Zabbix item objects

=head1 SYNOPSIS

  use Zabbix2::API::Item qw/:item_types/;

  # fetch a single item...
  my $item = $zabbix->fetch_single('Item', params => { itemids => [ 22379 ] });

  # manipulate its properties...
  $item->data->{multiplier} = 3;

  # and update the properties on the server.
  $item->update;

  # fetch all items from a host
  my $host = $zabbix->fetch_single('Host', params => { hostids => [ 10105 ] });
  my $items = $host->items;

  # create a new item
  my $new_item = Zabbix2::API::Item->new(
      root => $zabbix,
      data => { type => ITEM_TYPE_SNMPV2C,
                value_type => ITEM_VALUE_TYPE_UINT64,
                snmp_oid => ...,
                snmp_community => ...,
                # that's right, key_
                key_ => 'mynewitem',
                hostid => $host->id,
      });
  $new_item->create;

=head1 DESCRIPTION

Handles CRUD for Zabbix item objects.

This is a subclass of C<Zabbix2::API::CRUDE>; see there for inherited
methods.

=head1 ATTRIBUTES

=head2 graphs

(read-only arrayref of L<Zabbix2::API::Graph> objects)

This attribute is lazily populated from the server with the graphs
containing the item.

=head2 host

(read-only L<Zabbix2::API::Host> object)

This attribute is lazily populated with the item's host from the
server.

=head1 METHODS

=head2 expanded_name

  my $name = $item->expanded_name;

Returns the item's name (its "name" property) with the macros
expanded.

Currently this only supports parameter replacement, so if the name is

  CPU $2 time

and the key is

  system.cpu.util[,idle]

the value returned should be "CPU idle time".

Host macros and global macros are not replaced because this feature is
not implemented directly in the API as far as I can tell, and a manual
implementation in this wrapper would require many calls to the API
macro endpoints.

=head2 history

  my $historical_data = $item->history(time_from => ...,
                                       ...);

Accessor for the item's history data.  Calling this method does not
store the history data into the object, unlike other accessors.
History data is an AoH:

  [ { itemid => ITEMID,
      clock => UNIX_TIMESTAMP,
      value => VALUE,
      ns => NANOSECONDS }, ... ]

The parameters should be suitable for the C<history.get> method (see
L<here|https://www.zabbix.com/documentation/2.2/manual/api/reference/history/get>).
The C<itemids>, C<output> and C<history> parameters are already set
(to the item's ID, "extend" and the item's value type, respectively),
but they can be overridden.

=head1 EXPORTS

Way too many constants, but for once they're documented (here:
L<https://www.zabbix.com/documentation/2.2/manual/api/reference/item/object>).

Nothing is exported by default; you can use the tags C<:item_types>,
C<:value_types>, C<:data_types> and C<:status_types> (or import by
name).

=head1 BUGS AND ODDITIES

This is probably because of the extremely smart way the Zabbix team
has set up their database schema, but what you'd expect to be C<"key">
in an item's data is actually C<"key_">.

=head1 SEE ALSO

L<Zabbix2::API::CRUDE>.

=head1 AUTHOR

Fabrice Gabolde <fga@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, 2014 SFR

This library is free software; you can redistribute it and/or modify
it under the terms of the GPLv3.

=cut
