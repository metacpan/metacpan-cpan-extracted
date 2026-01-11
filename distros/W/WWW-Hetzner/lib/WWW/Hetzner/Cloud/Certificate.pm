package WWW::Hetzner::Cloud::Certificate;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Hetzner Cloud Certificate object

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


has certificate => ( is => 'ro' );


has domain_names => ( is => 'ro', default => sub { [] } );


has fingerprint => ( is => 'ro' );


has status => ( is => 'ro', default => sub { {} } );


has type => ( is => 'ro' );


has labels => ( is => 'rw', default => sub { {} } );


has created => ( is => 'ro' );


has not_valid_before => ( is => 'ro' );


has not_valid_after => ( is => 'ro' );


# Convenience
sub is_managed { shift->type eq 'managed' }


sub is_valid { (shift->status->{issuance} // '') eq 'completed' }


# Actions
sub update {
    my ($self) = @_;
    croak "Cannot update certificate without ID" unless $self->id;

    $self->_client->put("/certificates/" . $self->id, {
        name   => $self->name,
        labels => $self->labels,
    });
    return $self;
}


sub delete {
    my ($self) = @_;
    croak "Cannot delete certificate without ID" unless $self->id;

    $self->_client->delete("/certificates/" . $self->id);
    return 1;
}


sub retry {
    my ($self) = @_;
    croak "Cannot retry certificate without ID" unless $self->id;
    croak "Only managed certificates can be retried" unless $self->is_managed;

    $self->_client->post("/certificates/" . $self->id . "/actions/retry", {});
    return $self;
}


sub data {
    my ($self) = @_;
    return {
        id               => $self->id,
        name             => $self->name,
        certificate      => $self->certificate,
        domain_names     => $self->domain_names,
        fingerprint      => $self->fingerprint,
        status           => $self->status,
        type             => $self->type,
        labels           => $self->labels,
        created          => $self->created,
        not_valid_before => $self->not_valid_before,
        not_valid_after  => $self->not_valid_after,
    };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Cloud::Certificate - Hetzner Cloud Certificate object

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $cert = $cloud->certificates->get($id);

    print $cert->name, "\n";
    print $cert->type, "\n";  # uploaded or managed
    print join(", ", @{$cert->domain_names}), "\n";

    # Update
    $cert->name('new-name');
    $cert->update;

    # Delete
    $cert->delete;

=head1 DESCRIPTION

This class represents a Hetzner Cloud certificate. Objects are returned by
L<WWW::Hetzner::Cloud::API::Certificates> methods.

=head2 id

Certificate ID (read-only).

=head2 name

Certificate name (read-write).

=head2 certificate

Certificate PEM content (read-only).

=head2 domain_names

Arrayref of domain names covered by this certificate (read-only).

=head2 fingerprint

Certificate fingerprint (read-only).

=head2 status

Certificate status hash (read-only).

=head2 type

Certificate type: uploaded or managed (read-only).

=head2 labels

Labels hash (read-write).

=head2 created

Creation timestamp (read-only).

=head2 not_valid_before

Certificate validity start timestamp (read-only).

=head2 not_valid_after

Certificate validity end timestamp (read-only).

=head2 is_managed

Returns true if this is a managed certificate.

=head2 is_valid

Returns true if certificate issuance is completed.

=head2 update

    $cert->name('new-name');
    $cert->update;

Saves changes to name and labels.

=head2 delete

    $cert->delete;

Deletes the certificate.

=head2 retry

    $cert->retry;

Retries issuance for a managed certificate.

=head2 data

    my $hashref = $cert->data;

Returns all certificate data as a hashref (for JSON serialization).

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
