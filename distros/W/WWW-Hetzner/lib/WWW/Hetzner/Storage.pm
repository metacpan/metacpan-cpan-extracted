package WWW::Hetzner::Storage;
# ABSTRACT: Perl client for Hetzner Storage Box API

our $VERSION = '0.101';

use Moo;
use WWW::Hetzner::Storage::API::Actions;
use WWW::Hetzner::Storage::API::StorageBoxes;
use WWW::Hetzner::Storage::API::StorageBoxTypes;
use namespace::clean;


has token => (
    is      => 'ro',
    default => sub { $ENV{HETZNER_API_TOKEN} },
);


sub _check_auth {
    my ($self) = @_;
    unless ($self->token) {
        die "No Storage API token configured.\n\n" .
            "Set token via:\n" .
            "  Environment: HETZNER_API_TOKEN\n" .
            "  Option:      --token\n\n" .
            "Get token at: https://console.hetzner.cloud/ -> Select project -> Security -> API tokens\n";
    }
}

has base_url => (
    is      => 'ro',
    default => 'https://api.hetzner.com/v1',
);


with 'WWW::Hetzner::Role::HTTP';

around _request => sub {
    my ($orig, $self, @args) = @_;
    $self->_check_auth;
    return $self->$orig(@args);
};

has storage_boxes => (
    is      => 'lazy',
    builder => sub { WWW::Hetzner::Storage::API::StorageBoxes->new(client => shift) },
);


has storage_box_types => (
    is      => 'lazy',
    builder => sub { WWW::Hetzner::Storage::API::StorageBoxTypes->new(client => shift) },
);


has actions => (
    is      => 'lazy',
    builder => sub { WWW::Hetzner::Storage::API::Actions->new(client => shift) },
);



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Storage - Perl client for Hetzner Storage Box API

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    use WWW::Hetzner::Storage;

    my $storage = WWW::Hetzner::Storage->new(
        token => $ENV{HETZNER_API_TOKEN},
    );

    my $boxes = $storage->storage_boxes->list;

=head1 DESCRIPTION

This module provides access to Hetzner's Storage Box API.

=head2 token

Hetzner API token. Defaults to C<HETZNER_API_TOKEN>.

=head2 base_url

Base URL for the Storage Box API. Defaults to C<https://api.hetzner.com/v1>.

=head2 storage_boxes

Returns a L<WWW::Hetzner::Storage::API::StorageBoxes> instance.

=head2 storage_box_types

Returns a L<WWW::Hetzner::Storage::API::StorageBoxTypes> instance.

=head2 actions

Returns a L<WWW::Hetzner::Storage::API::Actions> instance.

=head1 SEE ALSO

=over 4

=item * L<WWW::Hetzner> - Main umbrella module

=item * L<WWW::Hetzner::Role::HTTP> - Shared HTTP transport seam

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
