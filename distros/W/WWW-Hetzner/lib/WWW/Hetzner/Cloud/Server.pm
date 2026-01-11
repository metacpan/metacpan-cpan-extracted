package WWW::Hetzner::Cloud::Server;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Hetzner Cloud Server object

our $VERSION = '0.002';

use Moo;
use Carp qw(croak);
use namespace::clean;


has _client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
    init_arg => 'client',
);

has id => ( is => 'ro' );


has name => ( is => 'rw' );


has status => ( is => 'rwp' );


has locked => ( is => 'ro' );


has created => ( is => 'ro' );


has labels => ( is => 'rw', default => sub { {} } );


# Nested data stored as-is
has public_net => ( is => 'ro', default => sub { {} } );
has private_net => ( is => 'ro', default => sub { [] } );
has server_type_data => ( is => 'ro', init_arg => 'server_type', default => sub { {} } );
has datacenter_data => ( is => 'ro', init_arg => 'datacenter', default => sub { {} } );
has image_data => ( is => 'ro', init_arg => 'image', default => sub { {} } );

# Convenience accessors

sub ipv4 { shift->public_net->{ipv4}{ip} }


sub ipv6 { shift->public_net->{ipv6}{ip} }


sub server_type { shift->server_type_data->{name} }


sub datacenter { shift->datacenter_data->{name} }


sub location { shift->datacenter_data->{location}{name} }


sub image { my $i = shift->image_data; $i ? $i->{name} : undef }


sub is_running { shift->status eq 'running' }


sub is_off { shift->status eq 'off' }


# Actions

sub update {
    my ($self) = @_;
    croak "Cannot update server without ID" unless $self->id;

    my $result = $self->_client->put("/servers/" . $self->id, {
        name   => $self->name,
        labels => $self->labels,
    });
    return $self;
}


sub delete {
    my ($self) = @_;
    croak "Cannot delete server without ID" unless $self->id;

    $self->_client->delete("/servers/" . $self->id);
    return 1;
}


sub power_on {
    my ($self) = @_;
    croak "Cannot power on server without ID" unless $self->id;

    $self->_client->post("/servers/" . $self->id . "/actions/poweron", {});
    return $self;
}


sub power_off {
    my ($self) = @_;
    croak "Cannot power off server without ID" unless $self->id;

    $self->_client->post("/servers/" . $self->id . "/actions/poweroff", {});
    return $self;
}


sub reboot {
    my ($self) = @_;
    croak "Cannot reboot server without ID" unless $self->id;

    $self->_client->post("/servers/" . $self->id . "/actions/reboot", {});
    return $self;
}


sub shutdown {
    my ($self) = @_;
    croak "Cannot shutdown server without ID" unless $self->id;

    $self->_client->post("/servers/" . $self->id . "/actions/shutdown", {});
    return $self;
}


sub rebuild {
    my ($self, $image) = @_;
    croak "Cannot rebuild server without ID" unless $self->id;
    croak "Image required" unless $image;

    $self->_client->post("/servers/" . $self->id . "/actions/rebuild", { image => $image });
    return $self;
}


sub refresh {
    my ($self) = @_;
    croak "Cannot refresh server without ID" unless $self->id;

    my $result = $self->_client->get("/servers/" . $self->id);
    my $data = $result->{server};

    $self->_set_status($data->{status});
    $self->name($data->{name});
    $self->labels($data->{labels} // {});

    return $self;
}


sub data {
    my ($self) = @_;
    return {
        id          => $self->id,
        name        => $self->name,
        status      => $self->status,
        locked      => $self->locked,
        created     => $self->created,
        labels      => $self->labels,
        public_net  => $self->public_net,
        private_net => $self->private_net,
        server_type => $self->server_type_data,
        datacenter  => $self->datacenter_data,
        image       => $self->image_data,
    };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Cloud::Server - Hetzner Cloud Server object

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $server = $cloud->servers->get($id);

    # Read attributes
    print $server->id, "\n";
    print $server->name, "\n";
    print $server->status, "\n";
    print $server->ipv4, "\n";

    # Check status
    if ($server->is_running) { ... }
    if ($server->is_off) { ... }

    # Update
    $server->name('new-name');
    $server->labels({ env => 'prod' });
    $server->update;

    # Power actions
    $server->shutdown;
    $server->power_on;
    $server->power_off;
    $server->reboot;

    # Rebuild with new image
    $server->rebuild('debian-13');

    # Delete
    $server->delete;

=head1 DESCRIPTION

This class represents a Hetzner Cloud server. Objects are returned by
L<WWW::Hetzner::Cloud::API::Servers> methods.

=head2 id

Server ID (read-only).

=head2 name

Server name (read-write).

=head2 status

Server status: running, off, starting, stopping, etc. (read-only).

=head2 locked

Whether the server is locked (read-only).

=head2 created

Creation timestamp (read-only).

=head2 labels

Labels hash (read-write).

=head2 ipv4

Public IPv4 address.

=head2 ipv6

Public IPv6 network.

=head2 server_type

Server type name, e.g. "cx22".

=head2 datacenter

Datacenter name.

=head2 location

Location name.

=head2 image

Image name.

=head2 is_running

    if ($server->is_running) { ... }

Returns true if server status is "running".

=head2 is_off

    if ($server->is_off) { ... }

Returns true if server status is "off".

=head2 update

    $server->name('new-name');
    $server->update;

Saves changes to name and labels back to the API.

=head2 delete

    $server->delete;

Deletes the server.

=head2 power_on

    $server->power_on;

Powers on the server.

=head2 power_off

    $server->power_off;

Hard power off (like pulling the power cord).

=head2 reboot

    $server->reboot;

Hard reboot.

=head2 shutdown

    $server->shutdown;

Graceful shutdown via ACPI.

=head2 rebuild

    $server->rebuild('debian-13');

Rebuilds the server with a new image. Data will be lost.

=head2 refresh

    $server->refresh;

Reloads server data from the API.

=head2 data

    my $hashref = $server->data;

Returns all server data as a hashref (for JSON serialization).

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-hetzner/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
