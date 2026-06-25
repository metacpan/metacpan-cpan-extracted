#!/bin/false
# ABSTRACT: Role for service control methods (status/start/stop/restart/reconfigure)
# PODNAME: WebService::OPNsense::Role::Service
use strictures 2;

package WebService::OPNsense::Role::Service;
$WebService::OPNsense::Role::Service::VERSION = '0.001';
use Moo::Role;
use namespace::clean;

with 'WebService::OPNsense::Role::APIPath';

sub reconfigure {
    my ($self) = @_;
    return $self->client->post( $self->_path('reconfigure') );
}

sub restart {
    my ($self) = @_;
    return $self->client->post( $self->_path('restart') );
}

sub start {
    my ($self) = @_;
    return $self->client->post( $self->_path('start') );
}

sub status {
    my ($self) = @_;
    return $self->client->get( $self->_path('status') );
}

sub stop {
    my ($self) = @_;
    return $self->client->post( $self->_path('stop') );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Role::Service - Role for service control methods (status/start/stop/restart/reconfigure)

=head1 VERSION

version 0.001

=for Pod::Coverage _api_path _path client reconfigure restart start status stop

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
