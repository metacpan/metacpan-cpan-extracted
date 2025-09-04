package Zabbix7::API::Proxy;

use strict;
use warnings;
use 5.010;
use Carp;

use Moo;
extends qw/Zabbix7::API::CRUDE/;

sub id {
    my ($self, $value) = @_;
    if (defined $value) {
        $self->data->{proxyid} = $value;
        Log::Any->get_logger->debug("Set proxyid: $value for proxy");
        return $self->data->{proxyid};
    }
    my $id = $self->data->{proxyid};
    Log::Any->get_logger->debug("Retrieved proxyid for proxy: " . ($id // 'none'));
    return $id;
}

sub _readonly_properties {
    return {
        proxyid => 1,
        lastaccess => 1,
        status => 1, # Added for Zabbix 7.0 (read-only)
    };
}

sub _prefix {
    my (undef, $suffix) = @_;
    return 'proxy' . ($suffix // '');
}

sub _extension {
    return (
        output => 'extend',
        selectHosts => ['hostid', 'host'], # Added for Zabbix 7.0
    );
}

sub name {
    my $self = shift;
    my $name = $self->data->{host} || '???';
    Log::Any->get_logger->debug("Retrieved name for proxy ID: " . ($self->id // 'new') . ": $name");
    return $name;
}

before 'create' => sub {
    my ($self) = @_;
    delete $self->data->{proxyid}; # Ensure proxyid is not sent
    delete $self->data->{status};  # status is read-only
    Log::Any->get_logger->debug("Preparing to create proxy: " . ($self->data->{host} // 'unknown'));
};

before 'update' => sub {
    my ($self) = @_;
    delete $self->data->{status}; # status is read-only
    Log::Any->get_logger->debug("Preparing to update proxy ID: " . ($self->id // 'new'));
};

1;
__END__
=pod

=head1 NAME

Zabbix7::API::Proxy -- Zabbix proxy objects

=head1 SYNOPSIS

  use Zabbix7::API::Proxy;
  # fetch a proxy by name
  my $proxy = $zabbix->fetch_single('Proxy', params => { filter => { host => "My Proxy" } });

=head1 DESCRIPTION

Handles CRUD for Zabbix proxy objects.

This is a subclass of C<Zabbix7::API::CRUDE>; see there for inherited
methods.

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
