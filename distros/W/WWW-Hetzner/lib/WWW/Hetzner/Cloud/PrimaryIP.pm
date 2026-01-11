package WWW::Hetzner::Cloud::PrimaryIP;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Hetzner Cloud Primary IP object

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


has ip => ( is => 'ro' );


has type => ( is => 'ro' );


has assignee_id => ( is => 'ro' );


has assignee_type => ( is => 'ro' );


has datacenter => ( is => 'ro', default => sub { {} } );


has dns_ptr => ( is => 'ro', default => sub { [] } );


has auto_delete => ( is => 'rw' );


has blocked => ( is => 'ro' );


has labels => ( is => 'rw', default => sub { {} } );


has protection => ( is => 'ro', default => sub { {} } );


has created => ( is => 'ro' );


# Convenience
sub is_assigned { defined shift->assignee_id }


sub datacenter_name { shift->datacenter->{name} }


# Actions
sub update {
    my ($self) = @_;
    croak "Cannot update primary IP without ID" unless $self->id;

    my $result = $self->_client->put("/primary_ips/" . $self->id, {
        name        => $self->name,
        auto_delete => $self->auto_delete,
        labels      => $self->labels,
    });
    return $self;
}


sub delete {
    my ($self) = @_;
    croak "Cannot delete primary IP without ID" unless $self->id;

    $self->_client->delete("/primary_ips/" . $self->id);
    return 1;
}


sub assign {
    my ($self, $assignee_id, $assignee_type) = @_;
    croak "Cannot assign primary IP without ID" unless $self->id;
    croak "Assignee ID required" unless $assignee_id;
    $assignee_type //= 'server';

    $self->_client->post("/primary_ips/" . $self->id . "/actions/assign", {
        assignee_id   => $assignee_id,
        assignee_type => $assignee_type,
    });
    return $self;
}


sub unassign {
    my ($self) = @_;
    croak "Cannot unassign primary IP without ID" unless $self->id;

    $self->_client->post("/primary_ips/" . $self->id . "/actions/unassign", {});
    return $self;
}


sub change_dns_ptr {
    my ($self, $ip, $dns_ptr) = @_;
    croak "Cannot modify primary IP without ID" unless $self->id;
    croak "IP required" unless $ip;
    croak "dns_ptr required" unless defined $dns_ptr;

    $self->_client->post("/primary_ips/" . $self->id . "/actions/change_dns_ptr", {
        ip      => $ip,
        dns_ptr => $dns_ptr,
    });
    return $self;
}


sub refresh {
    my ($self) = @_;
    croak "Cannot refresh primary IP without ID" unless $self->id;

    my $result = $self->_client->get("/primary_ips/" . $self->id);
    my $data = $result->{primary_ip};

    $self->name($data->{name});
    $self->auto_delete($data->{auto_delete});
    $self->labels($data->{labels} // {});

    return $self;
}


sub data {
    my ($self) = @_;
    return {
        id            => $self->id,
        name          => $self->name,
        ip            => $self->ip,
        type          => $self->type,
        assignee_id   => $self->assignee_id,
        assignee_type => $self->assignee_type,
        datacenter    => $self->datacenter,
        dns_ptr       => $self->dns_ptr,
        auto_delete   => $self->auto_delete,
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

WWW::Hetzner::Cloud::PrimaryIP - Hetzner Cloud Primary IP object

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $pip = $cloud->primary_ips->get($id);

    # Read attributes
    print $pip->ip, "\n";
    print $pip->type, "\n";  # ipv4 or ipv6

    # Assign to server
    $pip->assign($server_id, 'server');
    $pip->unassign;

    # Update
    $pip->name('new-name');
    $pip->auto_delete(1);
    $pip->update;

    # Delete
    $pip->delete;

=head1 DESCRIPTION

This class represents a Hetzner Cloud primary IP. Objects are returned by
L<WWW::Hetzner::Cloud::API::PrimaryIPs> methods.

=head2 id

Primary IP ID (read-only).

=head2 name

Primary IP name (read-write).

=head2 ip

The IP address (read-only).

=head2 type

IP type: ipv4 or ipv6 (read-only).

=head2 assignee_id

Assigned resource ID, or undef if not assigned (read-only).

=head2 assignee_type

Type of assigned resource, e.g. "server" (read-only).

=head2 datacenter

Datacenter data hash (read-only).

=head2 dns_ptr

Arrayref of reverse DNS entries (read-only).

=head2 auto_delete

Whether to auto-delete when resource is deleted (read-write).

=head2 blocked

Whether the IP is blocked (read-only).

=head2 labels

Labels hash (read-write).

=head2 protection

Protection settings hash (read-only).

=head2 created

Creation timestamp (read-only).

=head2 is_assigned

Returns true if assigned to a resource.

=head2 datacenter_name

Returns datacenter name.

=head2 update

    $pip->name('new-name');
    $pip->auto_delete(1);
    $pip->update;

Saves changes to name, auto_delete, and labels.

=head2 delete

    $pip->delete;

Deletes the primary IP.

=head2 assign

    $pip->assign($server_id);
    $pip->assign($server_id, 'server');

Assign to a resource.

=head2 unassign

    $pip->unassign;

Unassign from current resource.

=head2 change_dns_ptr

    $pip->change_dns_ptr($pip->ip, 'server.example.com');

Change reverse DNS pointer.

=head2 refresh

    $pip->refresh;

Reloads primary IP data from the API.

=head2 data

    my $hashref = $pip->data;

Returns all primary IP data as a hashref (for JSON serialization).

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
