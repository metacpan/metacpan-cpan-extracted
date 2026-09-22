package WWW::Hetzner::Cloud::LoadBalancerType;
# ABSTRACT: Hetzner Cloud LoadBalancerType object

our $VERSION = '0.101';

use Moo;
use namespace::clean;


has _client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
    init_arg => 'client',
);

has id => ( is => 'ro' );


has name => ( is => 'ro' );


has description => ( is => 'ro' );


has max_connections => ( is => 'ro' );


has max_services => ( is => 'ro' );


has max_targets => ( is => 'ro' );


has max_assigned_certificates => ( is => 'ro' );


has prices => ( is => 'ro', default => sub { [] } );


has deprecated => ( is => 'ro' );


has deprecation => ( is => 'ro' );


sub data {
    my ($self) = @_;
    return {
        id                        => $self->id,
        name                      => $self->name,
        description               => $self->description,
        max_connections           => $self->max_connections,
        max_services              => $self->max_services,
        max_targets               => $self->max_targets,
        max_assigned_certificates => $self->max_assigned_certificates,
        prices                    => $self->prices,
        deprecated                => $self->deprecated,
        deprecation               => $self->deprecation,
    };
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Cloud::LoadBalancerType - Hetzner Cloud LoadBalancerType object

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    my $type = $cloud->load_balancer_types->get_by_name('lb11');

    print $type->name, "\n";            # lb11
    print $type->max_connections, "\n"; # 20000
    print $type->max_services, "\n";    # 5
    print $type->max_targets, "\n";     # 25

=head1 DESCRIPTION

This class represents a Hetzner Cloud load balancer type (connection, service
and target limits). Objects are returned by
L<WWW::Hetzner::Cloud::API::LoadBalancerTypes> methods.

Load balancer types are read-only resources.

=head2 id

Load balancer type ID.

=head2 name

Load balancer type name, e.g. "lb11", "lb21", "lb31".

=head2 description

Human-readable description.

=head2 max_connections

Maximum number of simultaneous open connections.

=head2 max_services

Maximum number of services.

=head2 max_targets

Maximum number of targets.

=head2 max_assigned_certificates

Maximum number of certificates that can be assigned.

=head2 prices

Arrayref of per-location prices, each a hashref with C<location>,
C<price_hourly>, C<price_monthly>, C<included_traffic> and
C<price_per_tb_traffic>.

=head2 deprecated

Deprecation timestamp if deprecated, undef otherwise.

=head2 deprecation

Deprecation hashref with C<announced> and C<unavailable_after> timestamps,
undef unless the type is deprecated.

=head2 data

    my $hashref = $type->data;

Returns all load balancer type data as a hashref (for JSON serialization).

=head1 SEE ALSO

=over 4

=item * L<WWW::Hetzner::Cloud::API::LoadBalancerTypes> - Load Balancer Types API

=item * L<WWW::Hetzner::Cloud> - Main Cloud API client

=item * L<WWW::Hetzner::Cloud::LoadBalancer> - LoadBalancer entity

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
