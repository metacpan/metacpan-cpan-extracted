package WWW::VastAI::API::Offers;
our $VERSION = '0.001';
# ABSTRACT: Marketplace offer search for Vast.ai

use Moo;
use WWW::VastAI::Offer;
use namespace::clean;

has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub _wrap {
    my ($self, $data) = @_;
    return WWW::VastAI::Offer->new(
        client => $self->client,
        data   => $data,
    );
}

sub search {
    my ($self, %filters) = @_;

    my $result = $self->client->request_op('searchOffers', body => \%filters);
    my $offers = ref $result eq 'HASH' ? ($result->{offers} || $result->{results} || []) : ($result || []);
    return [ map { $self->_wrap($_) } @{$offers} ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::VastAI::API::Offers - Marketplace offer search for Vast.ai

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $offers = $vast->offers->search(
        limit    => 10,
        verified => { eq => \1 },
        rentable => { eq => \1 },
        rented   => { eq => \0 },
    );

=head1 DESCRIPTION

Provides access to the Vast.ai offer search endpoint. Search results are
returned as L<WWW::VastAI::Offer> objects.

=head1 METHODS

=head2 search

    my $offers = $vast->offers->search(%filters);

Runs a marketplace search with the given filter body and returns an arrayref of
L<WWW::VastAI::Offer> objects.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-vastai/issues>.

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
