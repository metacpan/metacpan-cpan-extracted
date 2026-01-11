package WWW::Hetzner::Cloud::API::PrimaryIPs;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Hetzner Cloud Primary IPs API

our $VERSION = '0.002';

use Moo;
use Carp qw(croak);
use WWW::Hetzner::Cloud::PrimaryIP;
use namespace::clean;


has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub _wrap {
    my ($self, $data) = @_;
    return WWW::Hetzner::Cloud::PrimaryIP->new(
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

    my $result = $self->client->get('/primary_ips', params => \%params);
    return $self->_wrap_list($result->{primary_ips} // []);
}


sub get {
    my ($self, $id) = @_;
    croak "Primary IP ID required" unless $id;

    my $result = $self->client->get("/primary_ips/$id");
    return $self->_wrap($result->{primary_ip});
}


sub create {
    my ($self, %params) = @_;

    croak "name required" unless $params{name};
    croak "type required (ipv4 or ipv6)" unless $params{type};
    croak "assignee_type required" unless $params{assignee_type};
    croak "datacenter required" unless $params{datacenter};

    my $body = {
        name          => $params{name},
        type          => $params{type},
        assignee_type => $params{assignee_type},
        datacenter    => $params{datacenter},
    };

    $body->{assignee_id} = $params{assignee_id} if $params{assignee_id};
    $body->{auto_delete} = $params{auto_delete} if exists $params{auto_delete};
    $body->{labels}      = $params{labels}      if $params{labels};

    my $result = $self->client->post('/primary_ips', $body);
    return $self->_wrap($result->{primary_ip});
}


sub update {
    my ($self, $id, %params) = @_;
    croak "Primary IP ID required" unless $id;

    my $body = {};
    $body->{name}        = $params{name}        if exists $params{name};
    $body->{auto_delete} = $params{auto_delete} if exists $params{auto_delete};
    $body->{labels}      = $params{labels}      if exists $params{labels};

    my $result = $self->client->put("/primary_ips/$id", $body);
    return $self->_wrap($result->{primary_ip});
}


sub delete {
    my ($self, $id) = @_;
    croak "Primary IP ID required" unless $id;

    return $self->client->delete("/primary_ips/$id");
}


sub assign {
    my ($self, $id, $assignee_id, $assignee_type) = @_;
    croak "Primary IP ID required" unless $id;
    croak "Assignee ID required" unless $assignee_id;
    $assignee_type //= 'server';

    return $self->client->post("/primary_ips/$id/actions/assign", {
        assignee_id   => $assignee_id,
        assignee_type => $assignee_type,
    });
}


sub unassign {
    my ($self, $id) = @_;
    croak "Primary IP ID required" unless $id;

    return $self->client->post("/primary_ips/$id/actions/unassign", {});
}


sub change_dns_ptr {
    my ($self, $id, $ip, $dns_ptr) = @_;
    croak "Primary IP ID required" unless $id;
    croak "IP required" unless $ip;
    croak "dns_ptr required" unless defined $dns_ptr;

    return $self->client->post("/primary_ips/$id/actions/change_dns_ptr", {
        ip      => $ip,
        dns_ptr => $dns_ptr,
    });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Cloud::API::PrimaryIPs - Hetzner Cloud Primary IPs API

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $cloud = WWW::Hetzner::Cloud->new(token => $token);

    # List primary IPs
    my $pips = $cloud->primary_ips->list;

    # Create primary IP
    my $pip = $cloud->primary_ips->create(
        name          => 'my-primary-ip',
        type          => 'ipv4',
        assignee_type => 'server',
        datacenter    => 'fsn1-dc14',
    );

    # Assign to server
    $cloud->primary_ips->assign($pip->id, $server_id, 'server');

    # Unassign
    $cloud->primary_ips->unassign($pip->id);

    # Delete
    $cloud->primary_ips->delete($pip->id);

=head1 DESCRIPTION

This module provides the API for managing Hetzner Cloud primary IPs.
All methods return L<WWW::Hetzner::Cloud::PrimaryIP> objects.

=head2 list

    my $pips = $cloud->primary_ips->list;
    my $pips = $cloud->primary_ips->list(label_selector => 'env=prod');

Returns arrayref of L<WWW::Hetzner::Cloud::PrimaryIP> objects.

=head2 get

    my $pip = $cloud->primary_ips->get($id);

Returns L<WWW::Hetzner::Cloud::PrimaryIP> object.

=head2 create

    my $pip = $cloud->primary_ips->create(
        name          => 'my-ip',       # required
        type          => 'ipv4',        # required (ipv4 or ipv6)
        assignee_type => 'server',      # required
        datacenter    => 'fsn1-dc14',   # required
        assignee_id   => $server_id,    # optional
        auto_delete   => 1,             # optional
        labels        => { ... },       # optional
    );

Creates primary IP. Returns L<WWW::Hetzner::Cloud::PrimaryIP> object.

=head2 update

    $cloud->primary_ips->update($id,
        name        => 'new-name',
        auto_delete => 0,
        labels      => { ... },
    );

Updates primary IP. Returns L<WWW::Hetzner::Cloud::PrimaryIP> object.

=head2 delete

    $cloud->primary_ips->delete($id);

Deletes primary IP.

=head2 assign

    $cloud->primary_ips->assign($id, $assignee_id, $assignee_type);

Assign primary IP to resource (default assignee_type is 'server').

=head2 unassign

    $cloud->primary_ips->unassign($id);

Unassign primary IP from resource.

=head2 change_dns_ptr

    $cloud->primary_ips->change_dns_ptr($id, $ip, $dns_ptr);

Change reverse DNS pointer for the primary IP.

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
