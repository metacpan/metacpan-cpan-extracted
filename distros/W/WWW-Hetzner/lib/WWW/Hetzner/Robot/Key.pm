package WWW::Hetzner::Robot::Key;
# ABSTRACT: Hetzner Robot SSH Key entity

our $VERSION = '0.101';

use Moo;
use namespace::clean;

has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

has name        => ( is => 'rw', required => 1 );


has fingerprint => ( is => 'ro', required => 1 );


has type        => ( is => 'ro' );


has size        => ( is => 'ro' );


has data        => ( is => 'ro' );


sub delete {
    my ($self) = @_;
    return $self->client->delete("/key/" . $self->fingerprint);
}


sub update {
    my ($self) = @_;
    return $self->client->post("/key/" . $self->fingerprint, {
        name => $self->name,
    });
}



1.

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Robot::Key - Hetzner Robot SSH Key entity

=head1 VERSION

version 0.101

=head2 name

Key name.

=head2 fingerprint

Key fingerprint (unique ID).

=head2 type

Key type (e.g. ED25519, RSA).

=head2 size

Key size in bits.

=head2 data

Public key data.

=head2 delete

    $key->delete;

=head2 update

    $key->name('new-name');
    $key->update;

=head1 SEE ALSO

=over 4

=item * L<WWW::Hetzner::Robot::API::Keys> - Keys API

=item * L<WWW::Hetzner::Robot> - Main Robot API client

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
