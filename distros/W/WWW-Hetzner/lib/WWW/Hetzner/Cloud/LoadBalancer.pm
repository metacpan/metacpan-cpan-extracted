package WWW::Hetzner::Cloud::LoadBalancer;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Hetzner Cloud Load Balancer object

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


has public_net => ( is => 'ro', default => sub { {} } );


has private_net => ( is => 'ro', default => sub { [] } );


has location => ( is => 'ro', default => sub { {} } );


has load_balancer_type => ( is => 'ro', default => sub { {} } );


has protection => ( is => 'ro', default => sub { {} } );


has labels => ( is => 'rw', default => sub { {} } );


has targets => ( is => 'ro', default => sub { [] } );


has services => ( is => 'ro', default => sub { [] } );


has algorithm => ( is => 'ro', default => sub { {} } );


has created => ( is => 'ro' );


has outgoing_traffic => ( is => 'ro' );


has ingoing_traffic => ( is => 'ro' );


has included_traffic => ( is => 'ro' );


# Convenience
sub location_name { shift->location->{name} }


sub type_name { shift->load_balancer_type->{name} }


sub ipv4 { shift->public_net->{ipv4}{ip} }


sub ipv6 { shift->public_net->{ipv6}{ip} }


# Actions
sub update {
    my ($self) = @_;
    croak "Cannot update load balancer without ID" unless $self->id;

    my $result = $self->_client->put("/load_balancers/" . $self->id, {
        name   => $self->name,
        labels => $self->labels,
    });
    return $self;
}


sub delete {
    my ($self) = @_;
    croak "Cannot delete load balancer without ID" unless $self->id;

    $self->_client->delete("/load_balancers/" . $self->id);
    return 1;
}


sub add_target {
    my ($self, %opts) = @_;
    croak "Cannot modify load balancer without ID" unless $self->id;
    croak "type required" unless $opts{type};

    $self->_client->post("/load_balancers/" . $self->id . "/actions/add_target", \%opts);
    return $self;
}


sub remove_target {
    my ($self, %opts) = @_;
    croak "Cannot modify load balancer without ID" unless $self->id;
    croak "type required" unless $opts{type};

    $self->_client->post("/load_balancers/" . $self->id . "/actions/remove_target", \%opts);
    return $self;
}


sub add_service {
    my ($self, %opts) = @_;
    croak "Cannot modify load balancer without ID" unless $self->id;
    croak "protocol required" unless $opts{protocol};
    croak "listen_port required" unless $opts{listen_port};
    croak "destination_port required" unless $opts{destination_port};

    $self->_client->post("/load_balancers/" . $self->id . "/actions/add_service", \%opts);
    return $self;
}


sub delete_service {
    my ($self, $listen_port) = @_;
    croak "Cannot modify load balancer without ID" unless $self->id;
    croak "listen_port required" unless $listen_port;

    $self->_client->post("/load_balancers/" . $self->id . "/actions/delete_service", {
        listen_port => $listen_port,
    });
    return $self;
}


sub attach_to_network {
    my ($self, $network_id, %opts) = @_;
    croak "Cannot modify load balancer without ID" unless $self->id;
    croak "network required" unless $network_id;

    my $body = { network => $network_id };
    $body->{ip} = $opts{ip} if $opts{ip};

    $self->_client->post("/load_balancers/" . $self->id . "/actions/attach_to_network", $body);
    return $self;
}


sub detach_from_network {
    my ($self, $network_id) = @_;
    croak "Cannot modify load balancer without ID" unless $self->id;
    croak "network required" unless $network_id;

    $self->_client->post("/load_balancers/" . $self->id . "/actions/detach_from_network", {
        network => $network_id,
    });
    return $self;
}


sub refresh {
    my ($self) = @_;
    croak "Cannot refresh load balancer without ID" unless $self->id;

    my $result = $self->_client->get("/load_balancers/" . $self->id);
    my $data = $result->{load_balancer};

    $self->name($data->{name});
    $self->labels($data->{labels} // {});

    return $self;
}


sub data {
    my ($self) = @_;
    return {
        id                 => $self->id,
        name               => $self->name,
        public_net         => $self->public_net,
        private_net        => $self->private_net,
        location           => $self->location,
        load_balancer_type => $self->load_balancer_type,
        protection         => $self->protection,
        labels             => $self->labels,
        targets            => $self->targets,
        services           => $self->services,
        algorithm          => $self->algorithm,
        created            => $self->created,
    };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Cloud::LoadBalancer - Hetzner Cloud Load Balancer object

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $lb = $cloud->load_balancers->get($id);

    # Read attributes
    print $lb->name, "\n";
    print $lb->ipv4, "\n";

    # Add target
    $lb->add_target(type => 'server', server => { id => 123 });

    # Add service
    $lb->add_service(
        protocol         => 'http',
        listen_port      => 80,
        destination_port => 8080,
    );

    # Delete
    $lb->delete;

=head1 DESCRIPTION

This class represents a Hetzner Cloud load balancer. Objects are returned by
L<WWW::Hetzner::Cloud::API::LoadBalancers> methods.

=head2 id

Load balancer ID (read-only).

=head2 name

Load balancer name (read-write).

=head2 public_net

Public network configuration hash (read-only).

=head2 private_net

Arrayref of private network attachments (read-only).

=head2 location

Location data hash (read-only).

=head2 load_balancer_type

Load balancer type data hash (read-only).

=head2 protection

Protection settings hash (read-only).

=head2 labels

Labels hash (read-write).

=head2 targets

Arrayref of targets (read-only).

=head2 services

Arrayref of services (read-only).

=head2 algorithm

Algorithm configuration hash (read-only).

=head2 created

Creation timestamp (read-only).

=head2 outgoing_traffic

Outgoing traffic in bytes (read-only).

=head2 ingoing_traffic

Ingoing traffic in bytes (read-only).

=head2 included_traffic

Included traffic in bytes (read-only).

=head2 location_name

Returns location name.

=head2 type_name

Returns load balancer type name.

=head2 ipv4

Returns public IPv4 address.

=head2 ipv6

Returns public IPv6 address.

=head2 update

    $lb->name('new-name');
    $lb->update;

Saves changes to name and labels.

=head2 delete

    $lb->delete;

Deletes the load balancer.

=head2 add_target

    $lb->add_target(type => 'server', server => { id => 123 });

Add a target to the load balancer.

=head2 remove_target

    $lb->remove_target(type => 'server', server => { id => 123 });

Remove a target from the load balancer.

=head2 add_service

    $lb->add_service(
        protocol         => 'http',
        listen_port      => 80,
        destination_port => 8080,
    );

Add a service to the load balancer.

=head2 delete_service

    $lb->delete_service(80);

Delete a service by listen port.

=head2 attach_to_network

    $lb->attach_to_network($network_id);
    $lb->attach_to_network($network_id, ip => '10.0.0.5');

Attach load balancer to a network.

=head2 detach_from_network

    $lb->detach_from_network($network_id);

Detach load balancer from a network.

=head2 refresh

    $lb->refresh;

Reloads load balancer data from the API.

=head2 data

    my $hashref = $lb->data;

Returns all load balancer data as a hashref (for JSON serialization).

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
