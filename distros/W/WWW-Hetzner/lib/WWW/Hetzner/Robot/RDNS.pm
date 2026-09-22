package WWW::Hetzner::Robot::RDNS;
# ABSTRACT: Hetzner Robot reverse DNS entry entity

our $VERSION = '0.101';

use Moo;
use namespace::clean;

has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

has ip  => ( is => 'ro', required => 1 );


has ptr => ( is => 'rw' );


sub update {
    my ($self) = @_;
    my $result = $self->client->post("/rdns/" . $self->ip, { ptr => $self->ptr });
    return $result->{rdns};
}


sub delete {
    my ($self) = @_;
    return $self->client->delete("/rdns/" . $self->ip);
}



1.

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Robot::RDNS - Hetzner Robot reverse DNS entry entity

=head1 VERSION

version 0.101

=head2 ip

IP address the entry belongs to (unique ID).

=head2 ptr

PTR record, the hostname the IP resolves back to.

=head2 update

    $rdns->ptr('mail.example.com');
    $rdns->update;

Writes the current C<ptr> back to the API.

=head2 delete

    $rdns->delete;

Removes the reverse DNS entry for this IP.

=head1 SEE ALSO

=over 4

=item * L<WWW::Hetzner::Robot::API::RDNS> - Reverse DNS API

=item * L<WWW::Hetzner::Robot> - Main Robot API client

=item * L<WWW::Hetzner::Robot::IP> - IP entity

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
