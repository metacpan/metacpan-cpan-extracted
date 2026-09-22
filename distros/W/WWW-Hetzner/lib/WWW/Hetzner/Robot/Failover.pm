package WWW::Hetzner::Robot::Failover;
# ABSTRACT: Hetzner Robot failover IP entity

our $VERSION = '0.101';

use Moo;
use Carp qw(croak);
use namespace::clean;

has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

has ip               => ( is => 'ro', required => 1 );


has netmask          => ( is => 'ro' );


has server_ip        => ( is => 'ro' );


has server_ipv6_net  => ( is => 'ro' );


has server_number    => ( is => 'ro' );


has active_server_ip => ( is => 'rw' );


sub switch {
    my ($self, $active_server_ip) = @_;
    croak "Target server IP required" unless $active_server_ip;
    my $result = $self->client->post("/failover/" . $self->ip, {
        active_server_ip => $active_server_ip,
    });
    $self->active_server_ip($result->{failover}{active_server_ip});
    return $result->{failover};
}


sub delete {
    my ($self) = @_;
    my $result = $self->client->delete("/failover/" . $self->ip);
    return $result->{failover};
}



1.

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Robot::Failover - Hetzner Robot failover IP entity

=head1 VERSION

version 0.101

=head2 ip

The failover IP address (unique ID).

=head2 netmask

Netmask of the failover IP.

=head2 server_ip

Main IP of the server the failover IP is assigned to.

=head2 server_ipv6_net

IPv6 network of the server the failover IP is assigned to.

=head2 server_number

Number of the server the failover IP is assigned to.

=head2 active_server_ip

Main IP of the server the failover IP currently routes to. C<undef> when the
routing was deleted.

=head2 switch

    $failover->switch('198.51.100.10');

Routes the failover IP to another server and updates L</active_server_ip>
from the response.

=head2 delete

    $failover->delete;

Deletes the routing of the failover IP. The IP itself stays in the account -
this is not a cancellation.

=head1 SEE ALSO

=over 4

=item * L<WWW::Hetzner::Robot::API::Failover> - Failover API

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
