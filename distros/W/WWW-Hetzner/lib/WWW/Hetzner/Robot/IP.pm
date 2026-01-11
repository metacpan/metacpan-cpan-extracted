package WWW::Hetzner::Robot::IP;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Hetzner Robot IP entity

our $VERSION = '0.002';

use Moo;
use namespace::clean;

has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

has ip                => ( is => 'ro', required => 1 );


has server_number     => ( is => 'ro' );


has server_ip         => ( is => 'ro' );


has locked            => ( is => 'ro' );


has separate_mac      => ( is => 'ro' );


has traffic_warnings  => ( is => 'rw' );


has traffic_hourly    => ( is => 'rw' );


has traffic_daily     => ( is => 'rw' );


has traffic_monthly   => ( is => 'rw' );


sub update {
    my ($self) = @_;
    my $body = {};
    $body->{traffic_warnings} = $self->traffic_warnings if defined $self->traffic_warnings;
    $body->{traffic_hourly}   = $self->traffic_hourly   if defined $self->traffic_hourly;
    $body->{traffic_daily}    = $self->traffic_daily    if defined $self->traffic_daily;
    $body->{traffic_monthly}  = $self->traffic_monthly  if defined $self->traffic_monthly;
    return $self->client->post("/ip/" . $self->ip, $body);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Robot::IP - Hetzner Robot IP entity

=head1 VERSION

version 0.002

=head2 ip

IP address.

=head2 server_number

Associated server.

=head2 server_ip

Main server IP.

=head2 locked

Lock status.

=head2 separate_mac

Separate MAC address.

=head2 traffic_warnings

Traffic warning enabled.

=head2 traffic_hourly

Hourly traffic limit.

=head2 traffic_daily

Daily traffic limit.

=head2 traffic_monthly

Monthly traffic limit.

=head2 update

Updates the IP configuration via the API with current attribute values for
traffic_warnings, traffic_hourly, traffic_daily, and traffic_monthly.

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
