package WWW::Hetzner::Storage::Snapshot;
# ABSTRACT: Hetzner Storage Box Snapshot object

our $VERSION = '0.101';

use Moo;
with 'WWW::Hetzner::Role::HasAction';
use Carp qw(croak);
use WWW::Hetzner::Storage::API::Snapshots;
use namespace::clean;


has _client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
    init_arg => 'client',
);

has _storage_box_id => (
    is       => 'ro',
    required => 1,
    init_arg => 'storage_box_id',
);

has id           => ( is => 'ro' );
has storage_box  => ( is => 'ro' );
has name         => ( is => 'ro' );
has description  => ( is => 'rw' );
has labels       => ( is => 'rw' );
has stats        => ( is => 'ro' );
has is_automatic => ( is => 'ro' );
has created      => ( is => 'ro' );









sub _require_id {
    my ($self) = @_;
    croak 'Cannot use snapshot without ID' unless $self->id;
}

sub _controller {
    my ($self) = @_;
    return WWW::Hetzner::Storage::API::Snapshots->new(
        client         => $self->_client,
        storage_box_id => $self->_storage_box_id,
    );
}


sub update {
    my ($self) = @_;
    $self->_require_id;

    return $self->_controller->update(
        $self->id,
        description => $self->description,
        labels      => $self->labels,
    );
}


sub delete {
    my ($self) = @_;
    $self->_require_id;
    return $self->_controller->delete($self->id);
}


sub data {
    my ($self) = @_;
    return {
        id           => $self->id,
        storage_box  => $self->storage_box,
        name         => $self->name,
        description  => $self->description,
        labels       => $self->labels,
        stats        => $self->stats,
        is_automatic => $self->is_automatic,
        created      => $self->created,
    };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Storage::Snapshot - Hetzner Storage Box Snapshot object

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    my $snapshot = $box->snapshots->get($id);
    $snapshot->description('before upgrade');
    my $updated = $snapshot->update;

=head1 DESCRIPTION

Represents a Storage Box snapshot returned by
L<WWW::Hetzner::Storage::API::Snapshots>.

=head2 id

Snapshot ID (read-only).

=head2 storage_box

ID of the parent Storage Box (read-only).

=head2 name

Snapshot name (read-only).

=head2 description

Snapshot description (read-write).

=head2 labels

Labels hashref (read-write).

=head2 stats

Snapshot statistics data (read-only).

=head2 is_automatic

True when the snapshot was created by a snapshot plan (read-only).

=head2 created

Creation timestamp (read-only).

=head2 update

    my $updated = $snapshot->update;

Saves the object's current description and labels. Returns the updated
Snapshot.

=head2 delete

    my $action = $snapshot->delete;

Deletes this snapshot and returns its action.

=head2 data

    my $hashref = $snapshot->data;

Returns the complete Snapshot representation returned by the API.

=head1 SEE ALSO

=over 4

=item * L<WWW::Hetzner::Storage::API::Snapshots> - Snapshot controller

=item * L<WWW::Hetzner::Storage::StorageBox> - Parent Storage Box entity

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
