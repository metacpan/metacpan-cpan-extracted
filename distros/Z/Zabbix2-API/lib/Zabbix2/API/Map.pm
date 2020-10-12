package Zabbix2::API::Map;

use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;

use Moo;

extends qw/Exporter Zabbix2::API::CRUDE/;

use constant {
    MAP_ELEMENT_TYPE_HOST => 0,
    MAP_ELEMENT_TYPE_MAP => 1,
    MAP_ELEMENT_TYPE_TRIGGER => 2,
    MAP_ELEMENT_TYPE_HOSTGROUP => 3,
    MAP_ELEMENT_TYPE_IMAGE => 4
};

our @EXPORT_OK = qw/
MAP_ELEMENT_TYPE_HOST
MAP_ELEMENT_TYPE_MAP
MAP_ELEMENT_TYPE_TRIGGER
MAP_ELEMENT_TYPE_HOSTGROUP
MAP_ELEMENT_TYPE_IMAGE/;

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
    };
}

sub id {
    ## mutator for id
    my ($self, $value) = @_;
    if (defined $value) {
        $self->data->{sysmapid} = $value;
        return $self->data->{sysmapid};
    } else {
        return $self->data->{sysmapid};
    }
}

sub _prefix {
    my (undef, $suffix) = @_;
    if ($suffix) {
        if ($suffix =~ m/id(s?)/) {
            return 'sysmap'.$suffix;
        }
        return 'map'.$suffix;
    } else {
        return 'map';
    }
}

sub _extension {
    return (output => 'extend',
            selectSelements => 'extend',
            selectLinks => 'extend');
}

1;
__END__
=pod

=head1 NAME

Zabbix2::API::Map -- Zabbix map objects

=head1 SYNOPSIS

  # TODO write the rest once there is something useful to do with map
  # objects

=head1 DESCRIPTION

Handles CRUD for Zabbix map objects.

This is a subclass of C<Zabbix2::API::CRUDE>; see there for inherited
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

L<Zabbix2::API::CRUDE>.

=head1 AUTHOR

Fabrice Gabolde <fga@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, 2014 SFR

This library is free software; you can redistribute it and/or modify it under
the terms of the GPLv3.

=cut
