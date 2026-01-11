package WWW::Hetzner::Cloud::API::Servers;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Hetzner Cloud Servers API

our $VERSION = '0.002';

use Moo;
use Carp qw(croak);
use WWW::Hetzner::Cloud::Server;
use namespace::clean;


has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub _wrap {
    my ($self, $data) = @_;
    return WWW::Hetzner::Cloud::Server->new(
        client => $self->client,
        %$data,
    );
}

sub _wrap_list {
    my ($self, $list) = @_;
    return [ map { $self->_wrap($_) } @$list ];
}


sub list {
    my ($self, %params) = @_;

    my $result = $self->client->get('/servers', params => \%params);
    return $self->_wrap_list($result->{servers} // []);
}


sub list_by_label {
    my ($self, $label_selector) = @_;
    return $self->list(label_selector => $label_selector);
}


sub get {
    my ($self, $id) = @_;
    croak "Server ID required" unless $id;

    my $result = $self->client->get("/servers/$id");
    return $self->_wrap($result->{server});
}


sub create {
    my ($self, %params) = @_;

    croak "name required" unless $params{name};
    croak "server_type required" unless $params{server_type};
    croak "image required" unless $params{image};

    my $body = {
        name        => $params{name},
        server_type => $params{server_type},
        image       => $params{image},
    };

    # Location/Datacenter (mutually exclusive)
    $body->{location}   = $params{location}   if $params{location};
    $body->{datacenter} = $params{datacenter} if $params{datacenter};

    # SSH Keys (array of names or IDs)
    $body->{ssh_keys} = $params{ssh_keys} if $params{ssh_keys};

    # Labels (hash)
    $body->{labels} = $params{labels} if $params{labels};

    # Cloud-init user data
    $body->{user_data} = $params{user_data} if $params{user_data};

    # Start server after create (default: true)
    $body->{start_after_create} = $params{start_after_create} // 1;

    # Placement group (ID or name)
    $body->{placement_group} = $params{placement_group} if $params{placement_group};

    # Networks (array of network IDs)
    $body->{networks} = $params{networks} if $params{networks};

    # Volumes (array of volume IDs)
    $body->{volumes} = $params{volumes} if $params{volumes};

    # Automount volumes
    $body->{automount} = $params{automount} if exists $params{automount};

    # Firewalls (array of firewall IDs)
    if ($params{firewalls}) {
        $body->{firewalls} = [
            map { { firewall => $_ } } @{$params{firewalls}}
        ];
    }

    # Public network configuration
    if ($params{public_net} || exists $params{enable_ipv4} || exists $params{enable_ipv6}) {
        $body->{public_net} = $params{public_net} // {};
        $body->{public_net}{enable_ipv4} = $params{enable_ipv4} if exists $params{enable_ipv4};
        $body->{public_net}{enable_ipv6} = $params{enable_ipv6} if exists $params{enable_ipv6};
        $body->{public_net}{ipv4} = $params{ipv4} if $params{ipv4};
        $body->{public_net}{ipv6} = $params{ipv6} if $params{ipv6};
    }

    my $result = $self->client->post('/servers', $body);
    return $self->_wrap($result->{server});
}


sub delete {
    my ($self, $id) = @_;
    croak "Server ID required" unless $id;

    return $self->client->delete("/servers/$id");
}


sub power_on {
    my ($self, $id) = @_;
    croak "Server ID required" unless $id;

    return $self->client->post("/servers/$id/actions/poweron", {});
}


sub power_off {
    my ($self, $id) = @_;
    croak "Server ID required" unless $id;

    return $self->client->post("/servers/$id/actions/poweroff", {});
}


sub reboot {
    my ($self, $id) = @_;
    croak "Server ID required" unless $id;

    return $self->client->post("/servers/$id/actions/reboot", {});
}


sub shutdown {
    my ($self, $id) = @_;
    croak "Server ID required" unless $id;

    return $self->client->post("/servers/$id/actions/shutdown", {});
}


sub rebuild {
    my ($self, $id, $image) = @_;
    croak "Server ID required" unless $id;
    croak "Image required" unless $image;

    return $self->client->post("/servers/$id/actions/rebuild", { image => $image });
}


sub change_type {
    my ($self, $id, $server_type, %opts) = @_;
    croak "Server ID required" unless $id;
    croak "Server type required" unless $server_type;

    return $self->client->post("/servers/$id/actions/change_type", {
        server_type     => $server_type,
        upgrade_disk    => $opts{upgrade_disk} // 1,
    });
}


sub reset {
    my ($self, $id) = @_;
    croak "Server ID required" unless $id;

    return $self->client->post("/servers/$id/actions/reset", {});
}


sub enable_rescue {
    my ($self, $id, %opts) = @_;
    croak "Server ID required" unless $id;

    my $body = { type => $opts{type} // 'linux64' };
    $body->{ssh_keys} = $opts{ssh_keys} if $opts{ssh_keys};

    return $self->client->post("/servers/$id/actions/enable_rescue", $body);
}


sub disable_rescue {
    my ($self, $id) = @_;
    croak "Server ID required" unless $id;

    return $self->client->post("/servers/$id/actions/disable_rescue", {});
}


sub request_console {
    my ($self, $id) = @_;
    croak "Server ID required" unless $id;

    return $self->client->post("/servers/$id/actions/request_console", {});
}


sub reset_password {
    my ($self, $id) = @_;
    croak "Server ID required" unless $id;

    return $self->client->post("/servers/$id/actions/reset_password", {});
}


sub attach_iso {
    my ($self, $id, $iso) = @_;
    croak "Server ID required" unless $id;
    croak "ISO required" unless $iso;

    return $self->client->post("/servers/$id/actions/attach_iso", { iso => $iso });
}


sub detach_iso {
    my ($self, $id) = @_;
    croak "Server ID required" unless $id;

    return $self->client->post("/servers/$id/actions/detach_iso", {});
}


sub enable_backup {
    my ($self, $id) = @_;
    croak "Server ID required" unless $id;

    return $self->client->post("/servers/$id/actions/enable_backup", {});
}


sub disable_backup {
    my ($self, $id) = @_;
    croak "Server ID required" unless $id;

    return $self->client->post("/servers/$id/actions/disable_backup", {});
}


sub update {
    my ($self, $id, %params) = @_;
    croak "Server ID required" unless $id;

    my $body = {};
    $body->{name}   = $params{name}   if exists $params{name};
    $body->{labels} = $params{labels} if exists $params{labels};

    my $result = $self->client->put("/servers/$id", $body);
    return $self->_wrap($result->{server});
}


sub wait_for_status {
    my ($self, $id, $status, $timeout) = @_;
    $timeout //= 120;

    my $start = time;
    while (time - $start < $timeout) {
        my $server = $self->get($id);
        return $server if $server->status eq $status;
        sleep 2;
    }

    croak "Timeout waiting for server $id to reach status '$status'";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Cloud::API::Servers - Hetzner Cloud Servers API

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use WWW::Hetzner::Cloud;

    my $cloud = WWW::Hetzner::Cloud->new(token => $ENV{HETZNER_API_TOKEN});

    # List all servers
    my $servers = $cloud->servers->list;

    # Create a server
    my $server = $cloud->servers->create(
        name        => 'my-server',
        server_type => 'cx22',
        image       => 'debian-12',
        location    => 'fsn1',
        ssh_keys    => ['my-key'],
        labels      => { env => 'prod' },
    );

    # Server is a WWW::Hetzner::Cloud::Server object
    print $server->id, "\n";
    print $server->ipv4, "\n";

    # Wait for server to be running
    $cloud->servers->wait_for_status($server->id, 'running');

    # Power actions via API
    $cloud->servers->shutdown($server->id);

    # Or directly on the object
    $server->power_on;
    $server->shutdown;

    # Update server
    $server->name('new-name');
    $server->update;

    # Delete server
    $server->delete;

=head1 DESCRIPTION

This module provides the API for managing Hetzner Cloud servers.
All methods return L<WWW::Hetzner::Cloud::Server> objects.

=head2 list

    my $servers = $cloud->servers->list;
    my $servers = $cloud->servers->list(label_selector => 'env=prod');

Returns an arrayref of L<WWW::Hetzner::Cloud::Server> objects.
Optional parameters: label_selector, name, status, sort.

=head2 list_by_label

    my $servers = $cloud->servers->list_by_label('env=production');

Convenience method to list servers by label selector.

=head2 get

    my $server = $cloud->servers->get($id);

Returns a L<WWW::Hetzner::Cloud::Server> object.

=head2 create

    my $server = $cloud->servers->create(
        name        => 'my-server',      # required
        server_type => 'cx23',           # required
        image       => 'debian-13',      # required
        location    => 'fsn1',           # optional
        datacenter  => 'fsn1-dc14',      # optional (alternative to location)
        ssh_keys    => ['my-key'],       # optional
        labels      => { env => 'prod' },# optional
        user_data   => '...',            # optional (cloud-init)
        start_after_create => 1,         # optional (default: true)
        placement_group => 'my-group',   # optional
        networks    => [123, 456],       # optional (network IDs)
        volumes     => [789],            # optional (volume IDs)
        automount   => 1,                # optional (automount volumes)
        firewalls   => [111, 222],       # optional (firewall IDs)
        enable_ipv4 => 1,                # optional (default: true)
        enable_ipv6 => 1,                # optional (default: true)
        ipv4        => 'primary-ip-id',  # optional (existing Primary IP)
        ipv6        => 'primary-ip-id',  # optional (existing Primary IP)
    );

Creates a new server. Returns a L<WWW::Hetzner::Cloud::Server> object.

=head2 delete

    $cloud->servers->delete($id);

Deletes a server.

=head2 power_on

    $cloud->servers->power_on($id);

Powers on a server.

=head2 power_off

    $cloud->servers->power_off($id);

Hard power off (like pulling the power cord).

=head2 reboot

    $cloud->servers->reboot($id);

Hard reboot.

=head2 shutdown

    $cloud->servers->shutdown($id);

Graceful shutdown via ACPI.

=head2 rebuild

    $cloud->servers->rebuild($id, 'debian-13');

Rebuilds server with a new image. Data on the server will be lost.

=head2 change_type

    $cloud->servers->change_type($id, 'cx33', upgrade_disk => 1);

Changes server type. Server must be powered off.

=head2 reset

    $cloud->servers->reset($id);

Hard reset the server.

=head2 enable_rescue

    $cloud->servers->enable_rescue($id, type => 'linux64', ssh_keys => ['my-key']);

Enable rescue mode for the server.

=head2 disable_rescue

    $cloud->servers->disable_rescue($id);

Disable rescue mode for the server.

=head2 request_console

    $cloud->servers->request_console($id);

Request a VNC console for the server.

=head2 reset_password

    $cloud->servers->reset_password($id);

Reset the root password of the server.

=head2 attach_iso

    $cloud->servers->attach_iso($id, $iso);

Attach an ISO to the server.

=head2 detach_iso

    $cloud->servers->detach_iso($id);

Detach an ISO from the server.

=head2 enable_backup

    $cloud->servers->enable_backup($id);

Enable automatic backups for the server.

=head2 disable_backup

    $cloud->servers->disable_backup($id);

Disable automatic backups for the server.

=head2 update

    $cloud->servers->update($id, name => 'new-name', labels => { env => 'dev' });

Updates server name or labels.

=head2 wait_for_status

    $cloud->servers->wait_for_status($id, 'running', 120);

Polls until server reaches the specified status. Default timeout is 120 seconds.

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
