package Zabbix7::API::Application;

use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;
use Moo;
extends qw/Zabbix7::API::CRUDE/;
use Log::Any; # Added for debugging


has 'items' => (is => 'ro',
                lazy => 1,
                builder => '_fetch_items');
has 'host' => (is => 'ro',
               lazy => 1,
               builder => '_fetch_host');

sub id {
    my ($self, $value) = @_;
    if (defined $value) {
        $self->data->{applicationid} = $value;
        return $self->data->{applicationid};
    }
    return $self->data->{applicationid};
}

sub _readonly_properties {
    return {
        applicationid => 1,
        hostid => 1, # hostid is read-only in Zabbix 7.0
        flags => 1, # Added for Zabbix 7.0 (read-only)
    };
}

sub _prefix {
    my (undef, $suffix) = @_;
    return 'application' . ($suffix // '');
}

sub _extension {
    return (
        output => 'extend',
        selectItems => 'extend', # Added for Zabbix 7.0
        selectHosts => ['hostid', 'host'], # Added for Zabbix 7.0
    );
}

sub name {
    my $self = shift;
    return $self->data->{name} || '???';
}

sub _fetch_items {
    my $self = shift;
    my $items = $self->{root}->fetch('Item', params => { applicationids => [ $self->id ] });
    Log::Any->get_logger->debug("Fetched " . scalar @$items . " items for application ID: " . $self->id);
    return $items;
}

sub _fetch_host {
    my $self = shift;
    my $host = $self->{root}->fetch_single('Host', params => { applicationids => [ $self->id ] });
    Log::Any->get_logger->debug("Fetched host for application ID: " . $self->id);
    return $host;
}

before 'update' => sub {
    my ($self) = @_;
    delete $self->data->{hostid}; # hostid is read-only
    delete $self->data->{flags}; # flags is read-only
};

1;
__END__
=pod

=head1 NAME

Zabbix7::API::Application -- Zabbix application objects

=head1 SYNOPSIS

  # fetch a single app
  my $app = $zabber->fetch_single('Application',
                                  params => { filter => { name => 'CPU' },
                                              hostids => [ 12345 ] });
  # get its parent host (costs one API call)
  my $host = $app->host;
  # get its child items
  my $items = $app->items;

=head1 DESCRIPTION

Handles CRUD for Zabbix application objects.

This is a subclass of C<Zabbix7::API::CRUDE>; see there for inherited
methods.

=head1 ATTRIBUTES

=head2 host

(read-only L<Zabbix7::API::Host> object)

This attribute is lazily populated from the application's host from
the server.

=head2 items

(read-only arrayref of L<Zabbix7::API::Item> objects)

This attribute is lazily populated from the application's items from
the server.

=head1 SEE ALSO

L<Zabbix7::API::CRUDE>

=head1 AUTHOR

SCOTTH

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, 2012, 2013, 2014 SFR
Copyright (C) 2020 Fabrice Gabolde
Copyright (C) 2025 ScottH

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
