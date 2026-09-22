package WWW::Hetzner::Cloud::API::Pricing;
# ABSTRACT: Hetzner Cloud Pricing API

our $VERSION = '0.101';

use Moo;
use WWW::Hetzner::Cloud::Pricing;
use namespace::clean;


has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);


sub get {
    my ($self) = @_;

    my $result = $self->client->get('/pricing');
    return WWW::Hetzner::Cloud::Pricing->new(
        client => $self->client,
        %{ $result->{pricing} // {} },
    );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Cloud::API::Pricing - Hetzner Cloud Pricing API

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    use WWW::Hetzner::Cloud;

    my $cloud = WWW::Hetzner::Cloud->new(token => $ENV{HETZNER_API_TOKEN});

    my $pricing = $cloud->pricing->get;

    printf "Currency: %s (VAT %s%%)\n", $pricing->currency, $pricing->vat_rate;

    for my $type (@{ $pricing->server_types }) {
        for my $price (@{ $type->{prices} }) {
            printf "%s @ %s: %s/month\n",
                $type->{name}, $price->{location}, $price->{price_monthly}{gross};
        }
    }

=head1 DESCRIPTION

This module provides access to Hetzner Cloud pricing. Unlike the other Cloud
resources C</pricing> is not a collection but a single object, so this
controller offers only C<get> -- there is no C<list> and nothing to look up
by id or name.

=head2 get

    my $pricing = $cloud->pricing->get;

Returns the current prices as a single L<WWW::Hetzner::Cloud::Pricing>
object.

=head1 SEE ALSO

=over 4

=item * L<WWW::Hetzner::Cloud> - Main Cloud API client

=item * L<WWW::Hetzner::Cloud::Pricing> - Pricing entity class

=item * L<WWW::Hetzner::CLI::Cmd::Pricing> - Pricing CLI commands

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
