package Zabbix7::API::Map;

use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;

use Moo;

extends qw/Exporter Zabbix7::API::CRUDE/;

use constant {
    MAP_ELEMENT_TYPE_HOST => 0,
    MAP_ELEMENT_TYPE_MAP => 1,
    MAP_ELEMENT_TYPE_TRIGGER => 2,
    MAP_ELEMENT_TYPE_HOSTGROUP => 3,
    MAP_ELEMENT_TYPE_IMAGE => 4,
};

our @EXPORT_OK = qw/
    MAP_ELEMENT_TYPE_HOST
    MAP_ELEMENT_TYPE_MAP
    MAP_ELEMENT_TYPE_TRIGGER
    MAP_ELEMENT_TYPE_HOSTGROUP
    MAP_ELEMENT_TYPE_IMAGE
/;

our %EXPORT_TAGS = (
    map_element_types => [
        qw/MAP_ELEMENT_TYPE_HOST
           MAP_ELEMENT_TYPE_MAP
           MAP_ELEMENT_TYPE_TRIGGER
           MAP_ELEMENT_TYPE_HOSTGROUP
           MAP_ELEMENT_TYPE_IMAGE/
    ],
);

sub _readonly_properties {
    return {
        sysmapid => 1,
        owner => 1, # Added for Zabbix 7.0 (read-only)
    };
}

sub id {
    my ($self, $value) = @_;
    if (defined $value) {
        $self->data->{sysmapid} = $value;
        Log::Any->get_logger->debug("Set sysmapid: $value for map");
        return $self->data->{sysmapid};
    }
    my $id = $self->data->{sysmapid};
    Log::Any->get_logger->debug("Retrieved sysmapid for map: " . ($id // 'none'));
    return $id;
}

sub _prefix {
    my (undef, $suffix) = @_;
    if ($suffix and $suffix =~ m/id(s?)/) {
        return 'sysmap' . $suffix;
    } elsif ($suffix) {
        return 'map' . $suffix;
    }
    return 'map';
}

sub _extension {
    return (
        output => 'extend',
        selectSelements => 'extend',
        selectLinks => 'extend',
        selectShapes => 'extend', # Added for Zabbix 7.0
        selectLines => 'extend', # Added for Zabbix 7.0
    );
}

sub name {
    my $self = shift;
    my $name = $self->data->{name} || '???';
    Log::Any->get_logger->debug("Retrieved name for map ID: " . ($self->id // 'new') . ": $name");
    return $name;
}

before 'create' => sub {
    my ($self) = @_;
    delete $self->data->{sysmapid}; # Ensure sysmapid is not sent
    delete $self->data->{owner};    # owner is read-only
    Log::Any->get_logger->debug("Preparing to create map: " . ($self->data->{name} // 'unknown'));
};

before 'update' => sub {
    my ($self) = @_;
    delete $self->data->{owner}; # owner is read-only
    Log::Any->get_logger->debug("Preparing to update map ID: " . ($self->id // 'new'));
};

1;
__END__
=pod

=head1 NAME

Zabbix7::API::Map -- Zabbix map objects

=head1 SYNOPSIS

  # TODO write the rest once there is something useful to do with map
  # objects

=head1 DESCRIPTION

Handles CRUD for Zabbix map objects.

This is a subclass of C<Zabbix7::API::CRUDE>; see there for inherited
methods.

L<Zabbix::API::Map> used to do useful things with a C<hosts>
attribute, but this is no longer the case.  Please send patches.

=head1 EXPORTS

The various integers representing map element types are implemented as constants:

  MAP_ELEMENT_TYPE_HOST
  MAP_ELEMENT_TYPE_MAP
  MAP_ELEMENT_TYPE_TRIGGER
  MAP_ELEMENT_TYPE_HOSTGROUP
  MAP_ELEMENT_TYPE_IMAGE

Nothing is exported by default; you can use the tag C<:map_element_types> (or
import by name).

=head1 SEE ALSO

L<Zabbix7::API::CRUDE>.

=head1 AUTHOR

SCOTTH

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, 2012, 2013, 2014 SFR
Copyright (C) 2020 Fabrice Gabolde
Copyright (C) 2025 ScottH

This library is free software; you can redistribute it and/or modify it under
the terms of the GPLv3.

=cut
