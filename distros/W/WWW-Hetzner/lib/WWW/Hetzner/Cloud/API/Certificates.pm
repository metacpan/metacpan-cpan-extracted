package WWW::Hetzner::Cloud::API::Certificates;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Hetzner Cloud Certificates API

our $VERSION = '0.002';

use Moo;
use Carp qw(croak);
use WWW::Hetzner::Cloud::Certificate;
use namespace::clean;


has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub _wrap {
    my ($self, $data) = @_;
    return WWW::Hetzner::Cloud::Certificate->new(
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

    my $result = $self->client->get('/certificates', params => \%params);
    return $self->_wrap_list($result->{certificates} // []);
}


sub get {
    my ($self, $id) = @_;
    croak "Certificate ID required" unless $id;

    my $result = $self->client->get("/certificates/$id");
    return $self->_wrap($result->{certificate});
}


sub create {
    my ($self, %params) = @_;

    croak "name required" unless $params{name};
    croak "type required (uploaded or managed)" unless $params{type};

    my $body = {
        name => $params{name},
        type => $params{type},
    };

    # For uploaded certificates
    $body->{certificate} = $params{certificate} if $params{certificate};
    $body->{private_key} = $params{private_key} if $params{private_key};

    # For managed certificates
    $body->{domain_names} = $params{domain_names} if $params{domain_names};

    $body->{labels} = $params{labels} if $params{labels};

    my $result = $self->client->post('/certificates', $body);
    return $self->_wrap($result->{certificate});
}


sub update {
    my ($self, $id, %params) = @_;
    croak "Certificate ID required" unless $id;

    my $body = {};
    $body->{name}   = $params{name}   if exists $params{name};
    $body->{labels} = $params{labels} if exists $params{labels};

    my $result = $self->client->put("/certificates/$id", $body);
    return $self->_wrap($result->{certificate});
}


sub delete {
    my ($self, $id) = @_;
    croak "Certificate ID required" unless $id;

    return $self->client->delete("/certificates/$id");
}


sub retry {
    my ($self, $id) = @_;
    croak "Certificate ID required" unless $id;

    return $self->client->post("/certificates/$id/actions/retry", {});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Cloud::API::Certificates - Hetzner Cloud Certificates API

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $cloud = WWW::Hetzner::Cloud->new(token => $token);

    # List certificates
    my $certs = $cloud->certificates->list;

    # Create managed certificate (Let's Encrypt)
    my $cert = $cloud->certificates->create(
        name         => 'my-cert',
        type         => 'managed',
        domain_names => ['example.com', 'www.example.com'],
    );

    # Create uploaded certificate
    my $cert = $cloud->certificates->create(
        name        => 'my-cert',
        type        => 'uploaded',
        certificate => $pem_cert,
        private_key => $pem_key,
    );

    # Delete
    $cloud->certificates->delete($cert->id);

=head1 DESCRIPTION

This module provides the API for managing Hetzner Cloud certificates.
All methods return L<WWW::Hetzner::Cloud::Certificate> objects.

=head2 list

    my $certs = $cloud->certificates->list;
    my $certs = $cloud->certificates->list(label_selector => 'env=prod');

Returns arrayref of L<WWW::Hetzner::Cloud::Certificate> objects.

=head2 get

    my $cert = $cloud->certificates->get($id);

Returns L<WWW::Hetzner::Cloud::Certificate> object.

=head2 create

    # Managed certificate (Let's Encrypt)
    my $cert = $cloud->certificates->create(
        name         => 'my-cert',      # required
        type         => 'managed',      # required
        domain_names => ['example.com'],# required for managed
        labels       => { ... },        # optional
    );

    # Uploaded certificate
    my $cert = $cloud->certificates->create(
        name        => 'my-cert',       # required
        type        => 'uploaded',      # required
        certificate => $pem_cert,       # required for uploaded
        private_key => $pem_key,        # required for uploaded
        labels      => { ... },         # optional
    );

Creates certificate. Returns L<WWW::Hetzner::Cloud::Certificate> object.

=head2 update

    $cloud->certificates->update($id, name => 'new-name', labels => { ... });

Updates certificate. Returns L<WWW::Hetzner::Cloud::Certificate> object.

=head2 delete

    $cloud->certificates->delete($id);

Deletes certificate.

=head2 retry

    $cloud->certificates->retry($id);

Retry issuance of a managed certificate that failed.

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
