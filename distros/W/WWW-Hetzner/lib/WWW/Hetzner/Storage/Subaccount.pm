package WWW::Hetzner::Storage::Subaccount;
# ABSTRACT: Hetzner Storage Box Subaccount object

our $VERSION = '0.101';

use Moo;
with 'WWW::Hetzner::Role::HasAction';
use Carp qw(croak);
use WWW::Hetzner::Storage::API::Subaccounts;
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

has id              => ( is => 'ro' );
has storage_box     => ( is => 'ro' );
has name            => ( is => 'rw' );
has home_directory  => ( is => 'ro' );
has access_settings => ( is => 'ro' );
has description     => ( is => 'rw' );
has labels          => ( is => 'rw' );
has username        => ( is => 'ro' );
has server          => ( is => 'ro' );
has created         => ( is => 'ro' );











sub _require_id {
    my ($self) = @_;
    croak 'Cannot use subaccount without ID' unless $self->id;
}

sub _controller {
    my ($self) = @_;
    return WWW::Hetzner::Storage::API::Subaccounts->new(
        client         => $self->_client,
        storage_box_id => $self->_storage_box_id,
    );
}


sub update {
    my ($self) = @_;
    $self->_require_id;

    return $self->_controller->update(
        $self->id,
        name        => $self->name,
        description => $self->description,
        labels      => $self->labels,
    );
}


sub delete {
    my ($self) = @_;
    $self->_require_id;
    return $self->_controller->delete($self->id);
}


sub change_home_directory {
    my ($self, %params) = @_;
    $self->_require_id;
    return $self->_controller->change_home_directory($self->id, %params);
}


sub reset_subaccount_password {
    my ($self, %params) = @_;
    $self->_require_id;
    return $self->_controller->reset_subaccount_password($self->id, %params);
}


sub update_access_settings {
    my ($self, %params) = @_;
    $self->_require_id;
    return $self->_controller->update_access_settings($self->id, %params);
}


sub data {
    my ($self) = @_;
    return {
        id              => $self->id,
        storage_box     => $self->storage_box,
        name            => $self->name,
        home_directory  => $self->home_directory,
        access_settings => $self->access_settings,
        description     => $self->description,
        labels          => $self->labels,
        username        => $self->username,
        server          => $self->server,
        created         => $self->created,
    };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Storage::Subaccount - Hetzner Storage Box Subaccount object

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    my $subaccount = $box->subaccounts->get($id);
    $subaccount->description('application backup account');
    my $updated = $subaccount->update;

=head1 DESCRIPTION

Represents a Storage Box subaccount returned by
L<WWW::Hetzner::Storage::API::Subaccounts>.

=head2 id

Subaccount ID (read-only).

=head2 storage_box

ID of the parent Storage Box (read-only).

=head2 name

Subaccount name (read-write).

=head2 home_directory

Home directory path (read-only).

=head2 access_settings

Access settings data (read-only).

=head2 description

Subaccount description (read-write).

=head2 labels

Labels hashref (read-write).

=head2 username

Subaccount username (read-only).

=head2 server

Subaccount server data (read-only).

=head2 created

Creation timestamp (read-only).

=head2 update

    my $updated = $subaccount->update;

Saves the object's current name, description, and labels. Returns the updated
Subaccount.

=head2 delete

    my $action = $subaccount->delete;

Deletes this subaccount and returns its action.

=head2 change_home_directory

    my $action = $subaccount->change_home_directory(
        home_directory => '/home/new-user',
    );

Changes this subaccount's home directory and returns its action.

=head2 reset_subaccount_password

    my $action = $subaccount->reset_subaccount_password(password => 'secret');

Resets this subaccount's password and returns its action.

=head2 update_access_settings

    my $action = $subaccount->update_access_settings(%settings);

Updates this subaccount's access settings and returns its action.

=head2 data

    my $hashref = $subaccount->data;

Returns the complete Subaccount representation returned by the API.

=head1 SEE ALSO

=over 4

=item * L<WWW::Hetzner::Storage::API::Subaccounts> - Subaccount controller

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
