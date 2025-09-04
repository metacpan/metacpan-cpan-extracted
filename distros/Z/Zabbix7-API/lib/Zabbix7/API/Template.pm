package Zabbix7::API::Template;

use strict;
use warnings;
use 5.010;
use Carp;

use Moo;
extends qw/Zabbix7::API::CRUDE/;

has 'items' => (is => 'ro',
                lazy => 1,
                builder => '_fetch_items');

sub id {
    my ($self, $value) = @_;
    if (defined $value) {
        $self->data->{templateid} = $value;
        Log::Any->get_logger->debug("Set templateid: $value for template");
        return $self->data->{templateid};
    }
    my $id = $self->data->{templateid};
    Log::Any->get_logger->debug("Retrieved templateid for template: " . ($id // 'none'));
    return $id;
}

sub _readonly_properties {
    return {
        templateid => 1,
        flags => 1, # Added for Zabbix 7.0 (read-only)
    };
}

sub _prefix {
    my (undef, $suffix) = @_;
    return 'template' . ($suffix // '');
}

sub _extension {
    return (
        output => 'extend',
        selectItems => ['itemid', 'name', 'key_'], # Added for Zabbix 7.0
        selectHosts => ['hostid', 'host'], # Added for Zabbix 7.0
    );
}

sub name {
    my $self = shift;
    my $name = $self->data->{host} || '???';
    Log::Any->get_logger->debug("Retrieved name for template ID: " . ($self->id // 'new') . ": $name");
    return $name;
}

sub _fetch_items {
    my $self = shift;
    my $items = $self->{root}->fetch('Item', params => { templateids => [ $self->id ] });
    Log::Any->get_logger->debug("Fetched " . scalar @$items . " items for template ID: " . ($self->id // 'new'));
    return $items;
}

before 'create' => sub {
    my ($self) = @_;
    delete $self->data->{templateid}; # Ensure templateid is not sent
    delete $self->data->{flags};     # flags is read-only
    Log::Any->get_logger->debug("Preparing to create template: " . ($self->data->{host} // 'unknown'));
};

before 'update' => sub {
    my ($self) = @_;
    delete $self->data->{flags}; # flags is read-only
    Log::Any->get_logger->debug("Preparing to update template ID: " . ($self->id // 'new'));
};

1;
__END__
=pod

=head1 NAME

Zabbix7::API::Template -- Zabbix template objects

=head1 SYNOPSIS

  TODO write this

=head1 DESCRIPTION

Handles CRUD for Zabbix template objects.

This is a subclass of C<Zabbix7::API::CRUDE>; see there for inherited methods.

=head1 METHODS

=over 4

=item items()

Accessor for the template's items.

=item name()

Accessor for the template's name (the "host" attribute); returns the empty
string if no name is set, for instance if the template has not been created on
the server yet.

=back

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
