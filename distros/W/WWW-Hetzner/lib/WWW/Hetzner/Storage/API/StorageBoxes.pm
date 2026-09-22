package WWW::Hetzner::Storage::API::StorageBoxes;
# ABSTRACT: Hetzner Storage Boxes API

our $VERSION = '0.101';

use Moo;
use Carp qw(croak);
use WWW::Hetzner::Storage::StorageBox;
use namespace::clean;


has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

with 'WWW::Hetzner::Role::HasActions';
with 'WWW::Hetzner::Role::Pagination';

has '+action_poll_path' => (
    default => sub { '/storage_boxes/actions' },
);

sub _wrap {
    my ($self, $data, %extra) = @_;
    return WWW::Hetzner::Storage::StorageBox->new(
        client => $self->client,
        %$data,
        %extra,
    );
}

sub _wrap_list {
    my ($self, $list) = @_;
    return [ map { $self->_wrap($_) } @{ $list // [] } ];
}

sub _list_page {
    my ($self, %params) = @_;

    my $result = $self->client->get('/storage_boxes', params => \%params);
    return ($self->_wrap_list($result->{storage_boxes} // []), $result->{meta});
}


sub list {
    my ($self, %params) = @_;

    my ($entities) = $self->_list_page(%params);
    return $entities;
}


sub get {
    my ($self, $id) = @_;
    croak 'Storage Box ID required' unless $id;

    my $result = $self->client->get("/storage_boxes/$id");
    return $self->_wrap($result->{storage_box});
}


sub get_by_name {
    my ($self, $name) = @_;
    croak 'Name required' unless $name;

    my $boxes = $self->list_all(name => $name);
    for my $box (@$boxes) {
        return $box if $box->name eq $name;
    }
    return;
}


sub create {
    my ($self, %params) = @_;

    for my $field (qw(name location storage_box_type password)) {
        croak "$field required" unless defined $params{$field} && length $params{$field};
    }

    my $body = {
        name             => $params{name},
        location         => $params{location},
        storage_box_type => $params{storage_box_type},
        password         => $params{password},
    };
    for my $field (qw(labels ssh_keys access_settings)) {
        $body->{$field} = $params{$field} if exists $params{$field};
    }

    my $result = $self->client->post('/storage_boxes', $body);
    return $self->_wrap(
        $result->{storage_box},
        action => $self->_wrap_action($result->{action}),
    );
}


sub update {
    my ($self, $id, %params) = @_;
    croak 'Storage Box ID required' unless $id;

    my $body = {};
    for my $field (qw(name labels)) {
        $body->{$field} = $params{$field} if exists $params{$field};
    }

    my $result = $self->client->put("/storage_boxes/$id", $body);
    return $self->_wrap($result->{storage_box});
}


sub delete {
    my ($self, $id) = @_;
    croak 'Storage Box ID required' unless $id;

    my $result = $self->client->delete("/storage_boxes/$id");
    return $self->_wrap_action($result->{action});
}


sub folders {
    my ($self, $id, %params) = @_;
    croak 'Storage Box ID required' unless $id;

    my $result = $self->client->get("/storage_boxes/$id/folders", params => \%params);
    return $result->{folders} // [];
}

sub _action {
    my ($self, $id, $name, $body) = @_;
    croak 'Storage Box ID required' unless $id;

    my $result = $self->client->post("/storage_boxes/$id/actions/$name", $body);
    return $self->_wrap_action($result->{action});
}


sub change_protection {
    my ($self, $id, %params) = @_;
    my $body = {};
    $body->{delete} = $params{delete} if exists $params{delete};
    return $self->_action($id, 'change_protection', $body);
}


sub change_type {
    my ($self, $id, %params) = @_;
    croak 'storage_box_type required' unless $params{storage_box_type};
    return $self->_action($id, 'change_type', {
        storage_box_type => $params{storage_box_type},
    });
}


sub reset_password {
    my ($self, $id, %params) = @_;
    croak 'password required' unless $params{password};
    return $self->_action($id, 'reset_password', { password => $params{password} });
}


sub update_access_settings {
    my ($self, $id, %params) = @_;
    my $body = {};
    for my $field (qw(reachable_externally samba_enabled ssh_enabled webdav_enabled zfs_enabled)) {
        $body->{$field} = $params{$field} if exists $params{$field};
    }
    return $self->_action($id, 'update_access_settings', $body);
}


sub rollback_snapshot {
    my ($self, $id, %params) = @_;
    croak 'snapshot required' unless $params{snapshot};
    return $self->_action($id, 'rollback_snapshot', { snapshot => $params{snapshot} });
}


sub enable_snapshot_plan {
    my ($self, $id, %params) = @_;
    for my $field (qw(max_snapshots minute hour)) {
        croak "$field required" unless exists $params{$field};
    }

    my $body = {
        max_snapshots => $params{max_snapshots},
        minute        => $params{minute},
        hour          => $params{hour},
    };
    for my $field (qw(day_of_week day_of_month)) {
        $body->{$field} = $params{$field} if exists $params{$field};
    }
    return $self->_action($id, 'enable_snapshot_plan', $body);
}


sub disable_snapshot_plan {
    my ($self, $id) = @_;
    return $self->_action($id, 'disable_snapshot_plan', {});
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Storage::API::StorageBoxes - Hetzner Storage Boxes API

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    my $boxes = $storage->storage_boxes;
    my $box = $boxes->create(
        name             => 'my-box',
        location         => 'fsn1',
        storage_box_type => 'bx20',
        password         => 'secret',
    );

=head1 DESCRIPTION

Manages Hetzner Storage Boxes and the actions performed on them.

=head2 list

    my $boxes = $storage->storage_boxes->list(%query);

Returns one page of L<WWW::Hetzner::Storage::StorageBox> objects. The API
accepts C<name>, C<label_selector>, C<sort>, C<page>, and C<per_page>.

=head2 get

    my $box = $storage->storage_boxes->get($id);

Returns a L<WWW::Hetzner::Storage::StorageBox>.

=head2 get_by_name

    my $box = $storage->storage_boxes->get_by_name('my-box');

Returns the Storage Box of the supplied name, or undef when none exists.

=head2 create

    my $box = $storage->storage_boxes->create(%params);

Creates a Storage Box. C<name>, C<location>, C<storage_box_type>, and
C<password> are required. Returns a Storage Box with its creation C<action>.

=head2 update

    my $box = $storage->storage_boxes->update($id, %params);

Updates a Storage Box's C<name> and/or C<labels>. Returns the updated
L<WWW::Hetzner::Storage::StorageBox>, without an action.

=head2 delete

    my $action = $storage->storage_boxes->delete($id);

Deletes a Storage Box and returns its L<WWW::Hetzner::Action>.

=head2 folders

    my $folders = $storage->storage_boxes->folders($id, path => '/');

Returns an arrayref of folder-name strings.

=head2 change_protection

    my $action = $storage->storage_boxes->change_protection($id, delete => 1);

Changes delete protection and returns its action.

=head2 change_type

    my $action = $storage->storage_boxes->change_type(
        $id, storage_box_type => 'bx11',
    );

Changes the Storage Box type and returns its action.

=head2 reset_password

    my $action = $storage->storage_boxes->reset_password($id, password => 'secret');

Resets a Storage Box password and returns its action.

=head2 update_access_settings

    my $action = $storage->storage_boxes->update_access_settings($id, %settings);

Updates access settings and returns its action.

=head2 rollback_snapshot

    my $action = $storage->storage_boxes->rollback_snapshot($id, snapshot => $snapshot_id);

Rolls a Storage Box back to a snapshot and returns its action.

=head2 enable_snapshot_plan

    my $action = $storage->storage_boxes->enable_snapshot_plan($id, %schedule);

Enables a snapshot plan and returns its action. C<max_snapshots>, C<minute>,
and C<hour> are required.

=head2 disable_snapshot_plan

    my $action = $storage->storage_boxes->disable_snapshot_plan($id);

Disables a snapshot plan and returns its action.

=head1 SEE ALSO

=over 4

=item * L<WWW::Hetzner::Storage> - Storage client

=item * L<WWW::Hetzner::Storage::StorageBox> - Storage Box entity

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
