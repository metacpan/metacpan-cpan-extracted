package WWW::Hetzner::Cloud::API::LoadBalancers;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Hetzner Cloud Load Balancers API

our $VERSION = '0.002';

use Moo;
use Carp qw(croak);
use WWW::Hetzner::Cloud::LoadBalancer;
use namespace::clean;


has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub _wrap {
    my ($self, $data) = @_;
    return WWW::Hetzner::Cloud::LoadBalancer->new(
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

    my $result = $self->client->get('/load_balancers', params => \%params);
    return $self->_wrap_list($result->{load_balancers} // []);
}


sub get {
    my ($self, $id) = @_;
    croak "Load Balancer ID required" unless $id;

    my $result = $self->client->get("/load_balancers/$id");
    return $self->_wrap($result->{load_balancer});
}


sub create {
    my ($self, %params) = @_;

    croak "name required" unless $params{name};
    croak "load_balancer_type required" unless $params{load_balancer_type};
    croak "location required" unless $params{location};

    my $body = {
        name               => $params{name},
        load_balancer_type => $params{load_balancer_type},
        location           => $params{location},
    };

    $body->{algorithm}   = $params{algorithm}   if $params{algorithm};
    $body->{labels}      = $params{labels}      if $params{labels};
    $body->{network}     = $params{network}     if $params{network};
    $body->{network_zone}= $params{network_zone}if $params{network_zone};
    $body->{public_interface} = $params{public_interface} if exists $params{public_interface};
    $body->{services}    = $params{services}    if $params{services};
    $body->{targets}     = $params{targets}     if $params{targets};

    my $result = $self->client->post('/load_balancers', $body);
    return $self->_wrap($result->{load_balancer});
}


sub update {
    my ($self, $id, %params) = @_;
    croak "Load Balancer ID required" unless $id;

    my $body = {};
    $body->{name}   = $params{name}   if exists $params{name};
    $body->{labels} = $params{labels} if exists $params{labels};

    my $result = $self->client->put("/load_balancers/$id", $body);
    return $self->_wrap($result->{load_balancer});
}


sub delete {
    my ($self, $id) = @_;
    croak "Load Balancer ID required" unless $id;

    return $self->client->delete("/load_balancers/$id");
}


sub add_target {
    my ($self, $id, %opts) = @_;
    croak "Load Balancer ID required" unless $id;
    croak "type required" unless $opts{type};

    return $self->client->post("/load_balancers/$id/actions/add_target", \%opts);
}


sub remove_target {
    my ($self, $id, %opts) = @_;
    croak "Load Balancer ID required" unless $id;
    croak "type required" unless $opts{type};

    return $self->client->post("/load_balancers/$id/actions/remove_target", \%opts);
}


sub add_service {
    my ($self, $id, %opts) = @_;
    croak "Load Balancer ID required" unless $id;

    return $self->client->post("/load_balancers/$id/actions/add_service", \%opts);
}


sub delete_service {
    my ($self, $id, $listen_port) = @_;
    croak "Load Balancer ID required" unless $id;
    croak "listen_port required" unless $listen_port;

    return $self->client->post("/load_balancers/$id/actions/delete_service", {
        listen_port => $listen_port,
    });
}


sub attach_to_network {
    my ($self, $id, $network_id, %opts) = @_;
    croak "Load Balancer ID required" unless $id;
    croak "network required" unless $network_id;

    my $body = { network => $network_id };
    $body->{ip} = $opts{ip} if $opts{ip};

    return $self->client->post("/load_balancers/$id/actions/attach_to_network", $body);
}


sub detach_from_network {
    my ($self, $id, $network_id) = @_;
    croak "Load Balancer ID required" unless $id;
    croak "network required" unless $network_id;

    return $self->client->post("/load_balancers/$id/actions/detach_from_network", {
        network => $network_id,
    });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Cloud::API::LoadBalancers - Hetzner Cloud Load Balancers API

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $cloud = WWW::Hetzner::Cloud->new(token => $token);

    # List load balancers
    my $lbs = $cloud->load_balancers->list;

    # Create load balancer
    my $lb = $cloud->load_balancers->create(
        name               => 'my-lb',
        load_balancer_type => 'lb11',
        location           => 'fsn1',
    );

    # Add target
    $cloud->load_balancers->add_target($lb->id,
        type   => 'server',
        server => { id => 123 },
    );

    # Add service
    $cloud->load_balancers->add_service($lb->id,
        protocol         => 'http',
        listen_port      => 80,
        destination_port => 8080,
    );

    # Delete
    $cloud->load_balancers->delete($lb->id);

=head1 DESCRIPTION

This module provides the API for managing Hetzner Cloud load balancers.
All methods return L<WWW::Hetzner::Cloud::LoadBalancer> objects.

=head2 list

    my $lbs = $cloud->load_balancers->list;
    my $lbs = $cloud->load_balancers->list(label_selector => 'env=prod');

Returns arrayref of L<WWW::Hetzner::Cloud::LoadBalancer> objects.

=head2 get

    my $lb = $cloud->load_balancers->get($id);

Returns L<WWW::Hetzner::Cloud::LoadBalancer> object.

=head2 create

    my $lb = $cloud->load_balancers->create(
        name               => 'my-lb',       # required
        load_balancer_type => 'lb11',        # required
        location           => 'fsn1',        # required
        algorithm          => { type => 'round_robin' },  # optional
        labels             => { ... },       # optional
        network            => $network_id,   # optional
        network_zone       => 'eu-central',  # optional
        public_interface   => 1,             # optional
        services           => [ ... ],       # optional
        targets            => [ ... ],       # optional
    );

Creates load balancer. Returns L<WWW::Hetzner::Cloud::LoadBalancer> object.

=head2 update

    $cloud->load_balancers->update($id, name => 'new-name', labels => { ... });

Updates load balancer. Returns L<WWW::Hetzner::Cloud::LoadBalancer> object.

=head2 delete

    $cloud->load_balancers->delete($id);

Deletes load balancer.

=head2 add_target

    $cloud->load_balancers->add_target($id,
        type   => 'server',
        server => { id => 123 },
    );

Add a target to the load balancer.

=head2 remove_target

    $cloud->load_balancers->remove_target($id,
        type   => 'server',
        server => { id => 123 },
    );

Remove a target from the load balancer.

=head2 add_service

    $cloud->load_balancers->add_service($id,
        protocol         => 'http',
        listen_port      => 80,
        destination_port => 8080,
    );

Add a service to the load balancer.

=head2 delete_service

    $cloud->load_balancers->delete_service($id, $listen_port);

Delete a service from the load balancer.

=head2 attach_to_network

    $cloud->load_balancers->attach_to_network($id, $network_id, ip => '10.0.0.5');

Attach load balancer to a network.

=head2 detach_from_network

    $cloud->load_balancers->detach_from_network($id, $network_id);

Detach load balancer from a network.

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
