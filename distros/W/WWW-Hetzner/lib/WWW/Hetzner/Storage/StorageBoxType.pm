package WWW::Hetzner::Storage::StorageBoxType;
# ABSTRACT: Hetzner Storage Box Type object

our $VERSION = '0.101';

use Moo;
use namespace::clean;


has _client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
    init_arg => 'client',
);

has id                       => ( is => 'ro' );
has name                     => ( is => 'ro' );
has description              => ( is => 'ro' );
has snapshot_limit           => ( is => 'ro' );
has automatic_snapshot_limit => ( is => 'ro' );
has subaccounts_limit        => ( is => 'ro' );
has size                     => ( is => 'ro' );
has prices                   => ( is => 'ro' );
has deprecation              => ( is => 'ro' );











sub data {
    my ($self) = @_;
    return {
        id                       => $self->id,
        name                     => $self->name,
        description              => $self->description,
        snapshot_limit           => $self->snapshot_limit,
        automatic_snapshot_limit => $self->automatic_snapshot_limit,
        subaccounts_limit        => $self->subaccounts_limit,
        size                     => $self->size,
        prices                   => $self->prices,
        deprecation              => $self->deprecation,
    };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Storage::StorageBoxType - Hetzner Storage Box Type object

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    my $type = $storage->storage_box_types->get_by_name('bx20');
    print $type->size, "\n";

=head1 DESCRIPTION

Represents a Storage Box type returned by
L<WWW::Hetzner::Storage::API::StorageBoxTypes>.

=head2 id

Storage Box Type ID (read-only).

=head2 name

Storage Box Type name, e.g. C<bx20> (read-only).

=head2 description

Human-readable description (read-only).

=head2 snapshot_limit

Maximum number of manual snapshots, or undef when unlimited (read-only).

=head2 automatic_snapshot_limit

Maximum number of automatic snapshots, or undef when unlimited (read-only).

=head2 subaccounts_limit

Maximum number of subaccounts (read-only).

=head2 size

Storage size in bytes (read-only).

=head2 prices

Arrayref of per-location pricing data (read-only).

=head2 deprecation

Deprecation data, or undef when not deprecated (read-only).

=head2 data

    my $hashref = $type->data;

Returns the complete Storage Box Type representation returned by the API.

=head1 SEE ALSO

=over 4

=item * L<WWW::Hetzner::Storage::API::StorageBoxTypes> - Storage Box Type controller

=item * L<WWW::Hetzner::Storage> - Storage client

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
