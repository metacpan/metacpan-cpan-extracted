package WWW::Hetzner::Cloud::API::FloatingIPs;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Hetzner Cloud Floating IPs API

our $VERSION = '0.002';

use Moo;
use Carp qw(croak);
use WWW::Hetzner::Cloud::FloatingIP;
use namespace::clean;


has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub _wrap {
    my ($self, $data) = @_;
    return WWW::Hetzner::Cloud::FloatingIP->new(
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

    my $result = $self->client->get('/floating_ips', params => \%params);
    return $self->_wrap_list($result->{floating_ips} // []);
}


sub get {
    my ($self, $id) = @_;
    croak "Floating IP ID required" unless $id;

    my $result = $self->client->get("/floating_ips/$id");
    return $self->_wrap($result->{floating_ip});
}


sub create {
    my ($self, %params) = @_;

    croak "type required (ipv4 or ipv6)" unless $params{type};
    croak "home_location required" unless $params{home_location};

    my $body = {
        type          => $params{type},
        home_location => $params{home_location},
    };

    $body->{name}        = $params{name}        if $params{name};
    $body->{description} = $params{description} if $params{description};
    $body->{server}      = $params{server}      if $params{server};
    $body->{labels}      = $params{labels}      if $params{labels};

    my $result = $self->client->post('/floating_ips', $body);
    return $self->_wrap($result->{floating_ip});
}


sub update {
    my ($self, $id, %params) = @_;
    croak "Floating IP ID required" unless $id;

    my $body = {};
    $body->{name}        = $params{name}        if exists $params{name};
    $body->{description} = $params{description} if exists $params{description};
    $body->{labels}      = $params{labels}      if exists $params{labels};

    my $result = $self->client->put("/floating_ips/$id", $body);
    return $self->_wrap($result->{floating_ip});
}


sub delete {
    my ($self, $id) = @_;
    croak "Floating IP ID required" unless $id;

    return $self->client->delete("/floating_ips/$id");
}


sub assign {
    my ($self, $id, $server_id) = @_;
    croak "Floating IP ID required" unless $id;
    croak "Server ID required" unless $server_id;

    return $self->client->post("/floating_ips/$id/actions/assign", {
        server => $server_id,
    });
}


sub unassign {
    my ($self, $id) = @_;
    croak "Floating IP ID required" unless $id;

    return $self->client->post("/floating_ips/$id/actions/unassign", {});
}


sub change_dns_ptr {
    my ($self, $id, $ip, $dns_ptr) = @_;
    croak "Floating IP ID required" unless $id;
    croak "IP required" unless $ip;
    croak "dns_ptr required" unless defined $dns_ptr;

    return $self->client->post("/floating_ips/$id/actions/change_dns_ptr", {
        ip      => $ip,
        dns_ptr => $dns_ptr,
    });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Cloud::API::FloatingIPs - Hetzner Cloud Floating IPs API

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $cloud = WWW::Hetzner::Cloud->new(token => $token);

    # List floating IPs
    my $fips = $cloud->floating_ips->list;

    # Create floating IP
    my $fip = $cloud->floating_ips->create(
        type          => 'ipv4',
        home_location => 'fsn1',
        name          => 'my-floating-ip',
    );

    # Assign to server
    $cloud->floating_ips->assign($fip->id, $server_id);

    # Unassign
    $cloud->floating_ips->unassign($fip->id);

    # Delete
    $cloud->floating_ips->delete($fip->id);

=head1 DESCRIPTION

This module provides the API for managing Hetzner Cloud floating IPs.
All methods return L<WWW::Hetzner::Cloud::FloatingIP> objects.

=head2 list

    my $fips = $cloud->floating_ips->list;
    my $fips = $cloud->floating_ips->list(label_selector => 'env=prod');

Returns arrayref of L<WWW::Hetzner::Cloud::FloatingIP> objects.

=head2 get

    my $fip = $cloud->floating_ips->get($id);

Returns L<WWW::Hetzner::Cloud::FloatingIP> object.

=head2 create

    my $fip = $cloud->floating_ips->create(
        type          => 'ipv4',       # required (ipv4 or ipv6)
        home_location => 'fsn1',       # required
        name          => 'my-ip',      # optional
        description   => '...',        # optional
        server        => $server_id,   # optional
        labels        => { ... },      # optional
    );

Creates floating IP. Returns L<WWW::Hetzner::Cloud::FloatingIP> object.

=head2 update

    $cloud->floating_ips->update($id,
        name        => 'new-name',
        description => 'new description',
        labels      => { ... },
    );

Updates floating IP. Returns L<WWW::Hetzner::Cloud::FloatingIP> object.

=head2 delete

    $cloud->floating_ips->delete($id);

Deletes floating IP.

=head2 assign

    $cloud->floating_ips->assign($id, $server_id);

Assign floating IP to server.

=head2 unassign

    $cloud->floating_ips->unassign($id);

Unassign floating IP from server.

=head2 change_dns_ptr

    $cloud->floating_ips->change_dns_ptr($id, $ip, $dns_ptr);

Change reverse DNS pointer for the floating IP.

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
