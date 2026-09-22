package WWW::Hetzner::Cloud::Network;
# ABSTRACT: Hetzner Cloud Network object

our $VERSION = '0.101';

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


has ip_range => ( is => 'ro' );


has subnets => ( is => 'ro', default => sub { [] } );


has routes => ( is => 'ro', default => sub { [] } );


has servers => ( is => 'ro', default => sub { [] } );


has labels => ( is => 'rw', default => sub { {} } );


has protection => ( is => 'ro', default => sub { {} } );


has created => ( is => 'ro' );


has load_balancers => ( is => 'ro', default => sub { [] } );


has expose_routes_to_vswitch => ( is => 'ro', default => 0 );


# Actions
sub update {
    my ($self) = @_;
    croak "Cannot update network without ID" unless $self->id;

    my $result = $self->_client->put("/networks/" . $self->id, {
        name   => $self->name,
        labels => $self->labels,
    });
    return $self;
}


sub delete {
    my ($self) = @_;
    croak "Cannot delete network without ID" unless $self->id;

    $self->_client->delete("/networks/" . $self->id);
    return 1;
}


sub add_subnet {
    my ($self, %opts) = @_;
    croak "Cannot modify network without ID" unless $self->id;
    croak "ip_range required" unless $opts{ip_range};
    croak "network_zone required" unless $opts{network_zone};
    croak "type required" unless $opts{type};

    return $self->_client->networks->add_subnet($self->id, %opts);
}


sub delete_subnet {
    my ($self, $ip_range) = @_;
    croak "Cannot modify network without ID" unless $self->id;
    croak "ip_range required" unless $ip_range;

    return $self->_client->networks->delete_subnet($self->id, $ip_range);
}


sub add_route {
    my ($self, %opts) = @_;
    croak "Cannot modify network without ID" unless $self->id;
    croak "destination required" unless $opts{destination};
    croak "gateway required" unless $opts{gateway};

    return $self->_client->networks->add_route($self->id, %opts);
}


sub delete_route {
    my ($self, %opts) = @_;
    croak "Cannot modify network without ID" unless $self->id;
    croak "destination required" unless $opts{destination};
    croak "gateway required" unless $opts{gateway};

    return $self->_client->networks->delete_route($self->id, %opts);
}


sub refresh {
    my ($self) = @_;
    croak "Cannot refresh network without ID" unless $self->id;

    my $result = $self->_client->get("/networks/" . $self->id);
    my $data = $result->{network};

    $self->name($data->{name});
    $self->labels($data->{labels} // {});

    return $self;
}


sub data {
    my ($self) = @_;
    return {
        id         => $self->id,
        name       => $self->name,
        ip_range   => $self->ip_range,
        subnets    => $self->subnets,
        routes     => $self->routes,
        servers    => $self->servers,
        labels     => $self->labels,
        protection => $self->protection,
        created    => $self->created,
    };
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Cloud::Network - Hetzner Cloud Network object

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    my $network = $cloud->networks->get($id);

    # Read attributes
    print $network->name, "\n";
    print $network->ip_range, "\n";

    # Subnets
    $network->add_subnet(
        ip_range     => '10.0.1.0/24',
        network_zone => 'eu-central',
        type         => 'cloud',
    );
    $network->delete_subnet('10.0.1.0/24');

    # Routes
    $network->add_route(destination => '10.100.1.0/24', gateway => '10.0.0.1');
    $network->delete_route(destination => '10.100.1.0/24', gateway => '10.0.0.1');

    # Update
    $network->name('new-name');
    $network->update;

    # Delete
    $network->delete;

=head1 DESCRIPTION

This class represents a Hetzner Cloud network. Objects are returned by
L<WWW::Hetzner::Cloud::API::Networks> methods.

=head2 id

Network ID (read-only).

=head2 name

Network name (read-write).

=head2 ip_range

Network IP range in CIDR notation (read-only).

=head2 subnets

Arrayref of subnet definitions (read-only).

=head2 routes

Arrayref of route definitions (read-only).

=head2 servers

Arrayref of attached server IDs (read-only).

=head2 labels

Labels hash (read-write).

=head2 protection

Protection settings hash (read-only).

=head2 created

Creation timestamp (read-only).

=head2 load_balancers

Arrayref of attached load balancer IDs (read-only).

=head2 expose_routes_to_vswitch

Whether routes are exposed to vSwitch (read-only).

=head2 update

    $network->name('new-name');
    $network->update;

Saves changes to name and labels.

=head2 delete

    $network->delete;

Deletes the network.

=head2 add_subnet

    $network->add_subnet(
        ip_range     => '10.0.1.0/24',
        network_zone => 'eu-central',
        type         => 'cloud',
    );

Add a subnet. Required: ip_range, network_zone, type.

=head2 delete_subnet

    $network->delete_subnet('10.0.1.0/24');

Delete a subnet by IP range.

=head2 add_route

    $network->add_route(destination => '10.100.1.0/24', gateway => '10.0.0.1');

Add a route. Required: destination, gateway.

=head2 delete_route

    $network->delete_route(destination => '10.100.1.0/24', gateway => '10.0.0.1');

Delete a route. Required: destination, gateway.

=head2 refresh

    $network->refresh;

Reloads network data from the API.

=head2 data

    my $hashref = $network->data;

Returns all network data as a hashref (for JSON serialization).

=head1 SEE ALSO

=over 4

=item * L<WWW::Hetzner::Cloud::API::Networks> - Networks API

=item * L<WWW::Hetzner::Cloud> - Main Cloud API client

=item * L<WWW::Hetzner> - Main umbrella module

=back

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

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
