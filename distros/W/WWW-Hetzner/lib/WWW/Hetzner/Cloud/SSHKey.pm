package WWW::Hetzner::Cloud::SSHKey;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Hetzner Cloud SSHKey object

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


has public_key => ( is => 'ro' );


has fingerprint => ( is => 'ro' );


has created => ( is => 'ro' );


has labels => ( is => 'rw', default => sub { {} } );


sub update {
    my ($self) = @_;
    croak "Cannot update SSH key without ID" unless $self->id;

    $self->_client->put("/ssh_keys/" . $self->id, {
        name   => $self->name,
        labels => $self->labels,
    });
    return $self;
}


sub delete {
    my ($self) = @_;
    croak "Cannot delete SSH key without ID" unless $self->id;

    $self->_client->delete("/ssh_keys/" . $self->id);
    return 1;
}


sub data {
    my ($self) = @_;
    return {
        id          => $self->id,
        name        => $self->name,
        public_key  => $self->public_key,
        fingerprint => $self->fingerprint,
        created     => $self->created,
        labels      => $self->labels,
    };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Cloud::SSHKey - Hetzner Cloud SSHKey object

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $key = $cloud->ssh_keys->get($id);

    # Read attributes
    print $key->id, "\n";
    print $key->name, "\n";
    print $key->fingerprint, "\n";
    print $key->public_key, "\n";

    # Update
    $key->name('renamed-key');
    $key->labels({ env => 'prod' });
    $key->update;

    # Delete
    $key->delete;

=head1 DESCRIPTION

This class represents a Hetzner Cloud SSH key. Objects are returned by
L<WWW::Hetzner::Cloud::API::SSHKeys> methods.

=head2 id

SSH key ID (read-only).

=head2 name

SSH key name (read-write).

=head2 public_key

The public key content (read-only).

=head2 fingerprint

SSH key fingerprint (read-only).

=head2 created

Creation timestamp (read-only).

=head2 labels

Labels hash (read-write).

=head2 update

    $key->name('new-name');
    $key->update;

Saves changes to name and labels back to the API.

=head2 delete

    $key->delete;

Deletes the SSH key.

=head2 data

    my $hashref = $key->data;

Returns all SSH key data as a hashref (for JSON serialization).

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
