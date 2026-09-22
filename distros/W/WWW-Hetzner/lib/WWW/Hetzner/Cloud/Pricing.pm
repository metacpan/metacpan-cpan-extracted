package WWW::Hetzner::Cloud::Pricing;
# ABSTRACT: Hetzner Cloud Pricing object

our $VERSION = '0.101';

use Moo;
use namespace::clean;


has _client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
    init_arg => 'client',
);

has currency => ( is => 'ro' );


has vat_rate => ( is => 'ro' );


has image => ( is => 'ro', default => sub { {} } );


has volume => ( is => 'ro', default => sub { {} } );


has server_backup => ( is => 'ro', default => sub { {} } );


has floating_ips => ( is => 'ro', default => sub { [] } );


has primary_ips => ( is => 'ro', default => sub { [] } );


has server_types => ( is => 'ro', default => sub { [] } );


has load_balancer_types => ( is => 'ro', default => sub { [] } );


has floating_ip => ( is => 'ro', default => sub { {} } );


has traffic => ( is => 'ro' );


sub data {
    my ($self) = @_;
    return {
        currency            => $self->currency,
        vat_rate            => $self->vat_rate,
        image               => $self->image,
        volume              => $self->volume,
        server_backup       => $self->server_backup,
        floating_ips        => $self->floating_ips,
        primary_ips         => $self->primary_ips,
        server_types        => $self->server_types,
        load_balancer_types => $self->load_balancer_types,
        floating_ip         => $self->floating_ip,
        traffic             => $self->traffic,
    };
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Cloud::Pricing - Hetzner Cloud Pricing object

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    my $pricing = $cloud->pricing->get;

    print $pricing->currency, "\n";                    # EUR
    print $pricing->vat_rate, "\n";                    # 19.00
    print $pricing->image->{price_per_gb_month}{gross}, "\n";
    print $pricing->server_backup->{percentage}, "\n"; # 20.0

=head1 DESCRIPTION

This class represents the Hetzner Cloud price list. It is returned by
L<WWW::Hetzner::Cloud::API::Pricing/get>.

Pricing is a singleton read-only resource: there is exactly one price list per
project, it has no id and no name. Its attributes are the raw hashrefs and
arrayrefs of the API response -- money values are hashrefs with C<net> and
C<gross> keys, both decimal strings.

=head2 currency

Currency of all prices, e.g. "EUR".

=head2 vat_rate

VAT rate applied to the net prices, e.g. "19.00".

=head2 image

Image price hashref with C<price_per_gb_month>.

=head2 volume

Volume price hashref with C<price_per_gb_month>.

=head2 server_backup

Backup price hashref with C<percentage> -- backups cost that percentage of
the server price.

=head2 floating_ips

Arrayref of floating IP prices, one entry per C<type> (ipv4, ipv6), each
with per-location C<prices>.

=head2 primary_ips

Arrayref of primary IP prices, one entry per C<type> (ipv4, ipv6), each with
per-location C<prices>.

=head2 server_types

Arrayref of server type prices, each with C<id>, C<name> and per-location
C<prices>.

=head2 load_balancer_types

Arrayref of load balancer type prices, each with C<id>, C<name> and
per-location C<prices>.

=head2 floating_ip

Legacy single floating IP price hashref with C<price_monthly>. Superseded by
C<floating_ips>.

=head2 traffic

Legacy traffic price hashref with C<price_per_tb>. No longer part of the
current API response, where traffic is priced per server type; kept for
responses that still carry it.

=head2 data

    my $hashref = $pricing->data;

Returns all pricing data as a hashref (for JSON serialization).

=head1 SEE ALSO

=over 4

=item * L<WWW::Hetzner::Cloud::API::Pricing> - Pricing API

=item * L<WWW::Hetzner::Cloud> - Main Cloud API client

=item * L<WWW::Hetzner::Cloud::ServerType> - ServerType entity

=item * L<WWW::Hetzner::Cloud::LoadBalancerType> - LoadBalancerType entity

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
