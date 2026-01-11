package WWW::Hetzner::Cloud::FloatingIP;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Hetzner Cloud Floating IP object

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


has description => ( is => 'rw' );


has ip => ( is => 'ro' );


has type => ( is => 'ro' );


has server => ( is => 'ro' );


has dns_ptr => ( is => 'ro', default => sub { [] } );


has home_location => ( is => 'ro', default => sub { {} } );


has blocked => ( is => 'ro' );


has labels => ( is => 'rw', default => sub { {} } );


has protection => ( is => 'ro', default => sub { {} } );


has created => ( is => 'ro' );


# Convenience
sub is_assigned { defined shift->server }


sub location { shift->home_location->{name} }


# Actions
sub update {
    my ($self) = @_;
    croak "Cannot update floating IP without ID" unless $self->id;

    my $result = $self->_client->put("/floating_ips/" . $self->id, {
        name        => $self->name,
        description => $self->description,
        labels      => $self->labels,
    });
    return $self;
}


sub delete {
    my ($self) = @_;
    croak "Cannot delete floating IP without ID" unless $self->id;

    $self->_client->delete("/floating_ips/" . $self->id);
    return 1;
}


sub assign {
    my ($self, $server_id) = @_;
    croak "Cannot assign floating IP without ID" unless $self->id;
    croak "Server ID required" unless $server_id;

    $self->_client->post("/floating_ips/" . $self->id . "/actions/assign", {
        server => $server_id,
    });
    return $self;
}


sub unassign {
    my ($self) = @_;
    croak "Cannot unassign floating IP without ID" unless $self->id;

    $self->_client->post("/floating_ips/" . $self->id . "/actions/unassign", {});
    return $self;
}


sub change_dns_ptr {
    my ($self, $ip, $dns_ptr) = @_;
    croak "Cannot modify floating IP without ID" unless $self->id;
    croak "IP required" unless $ip;
    croak "dns_ptr required" unless defined $dns_ptr;

    $self->_client->post("/floating_ips/" . $self->id . "/actions/change_dns_ptr", {
        ip      => $ip,
        dns_ptr => $dns_ptr,
    });
    return $self;
}


sub refresh {
    my ($self) = @_;
    croak "Cannot refresh floating IP without ID" unless $self->id;

    my $result = $self->_client->get("/floating_ips/" . $self->id);
    my $data = $result->{floating_ip};

    $self->name($data->{name});
    $self->description($data->{description});
    $self->labels($data->{labels} // {});

    return $self;
}


sub data {
    my ($self) = @_;
    return {
        id            => $self->id,
        name          => $self->name,
        description   => $self->description,
        ip            => $self->ip,
        type          => $self->type,
        server        => $self->server,
        dns_ptr       => $self->dns_ptr,
        home_location => $self->home_location,
        blocked       => $self->blocked,
        labels        => $self->labels,
        protection    => $self->protection,
        created       => $self->created,
    };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Cloud::FloatingIP - Hetzner Cloud Floating IP object

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $fip = $cloud->floating_ips->get($id);

    # Read attributes
    print $fip->ip, "\n";
    print $fip->type, "\n";  # ipv4 or ipv6

    # Assign to server
    $fip->assign($server_id);
    $fip->unassign;

    # Change reverse DNS
    $fip->change_dns_ptr($fip->ip, 'server.example.com');

    # Update
    $fip->name('new-name');
    $fip->update;

    # Delete
    $fip->delete;

=head1 DESCRIPTION

This class represents a Hetzner Cloud floating IP. Objects are returned by
L<WWW::Hetzner::Cloud::API::FloatingIPs> methods.

=head2 id

Floating IP ID (read-only).

=head2 name

Floating IP name (read-write).

=head2 description

Floating IP description (read-write).

=head2 ip

The IP address (read-only).

=head2 type

IP type: ipv4 or ipv6 (read-only).

=head2 server

Assigned server ID, or undef if not assigned (read-only).

=head2 dns_ptr

Arrayref of reverse DNS entries (read-only).

=head2 home_location

Home location data hash (read-only).

=head2 blocked

Whether the IP is blocked (read-only).

=head2 labels

Labels hash (read-write).

=head2 protection

Protection settings hash (read-only).

=head2 created

Creation timestamp (read-only).

=head2 is_assigned

Returns true if assigned to a server.

=head2 location

Returns home location name.

=head2 update

    $fip->name('new-name');
    $fip->update;

Saves changes to name, description, and labels.

=head2 delete

    $fip->delete;

Deletes the floating IP.

=head2 assign

    $fip->assign($server_id);

Assign to a server.

=head2 unassign

    $fip->unassign;

Unassign from current server.

=head2 change_dns_ptr

    $fip->change_dns_ptr($fip->ip, 'server.example.com');

Change reverse DNS pointer.

=head2 refresh

    $fip->refresh;

Reloads floating IP data from the API.

=head2 data

    my $hashref = $fip->data;

Returns all floating IP data as a hashref (for JSON serialization).

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
