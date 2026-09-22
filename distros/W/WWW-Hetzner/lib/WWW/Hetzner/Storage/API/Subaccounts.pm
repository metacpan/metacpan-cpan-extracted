package WWW::Hetzner::Storage::API::Subaccounts;
# ABSTRACT: Hetzner Storage Box Subaccounts API

our $VERSION = '0.101';

use Moo;
use Carp qw(croak);
use WWW::Hetzner::Storage::Subaccount;
use namespace::clean;


has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

has storage_box_id => (
    is       => 'ro',
    required => 1,
);

with 'WWW::Hetzner::Role::HasActions';

has '+action_poll_path' => (
    default => sub { '/storage_boxes/actions' },
);

sub _base_path {
    my ($self) = @_;
    return '/storage_boxes/' . $self->storage_box_id . '/subaccounts';
}

sub _wrap {
    my ($self, $data, %extra) = @_;
    return WWW::Hetzner::Storage::Subaccount->new(
        client         => $self->client,
        storage_box_id => $self->storage_box_id,
        %$data,
        %extra,
    );
}

sub _wrap_list {
    my ($self, $list) = @_;
    return [ map { $self->_wrap($_) } @{ $list // [] } ];
}


sub list {
    my ($self, %params) = @_;

    my $result = $self->client->get($self->_base_path, params => \%params);
    return $self->_wrap_list($result->{subaccounts} // []);
}


sub get {
    my ($self, $id) = @_;
    croak 'Subaccount ID required' unless $id;

    my $result = $self->client->get($self->_base_path . "/$id");
    return $self->_wrap($result->{subaccount});
}


sub create {
    my ($self, %params) = @_;
    for my $field (qw(home_directory password)) {
        croak "$field required" unless defined $params{$field} && length $params{$field};
    }

    my $body = {
        home_directory => $params{home_directory},
        password       => $params{password},
    };
    for my $field (qw(access_settings description labels name)) {
        $body->{$field} = $params{$field} if exists $params{$field};
    }

    my $result = $self->client->post($self->_base_path, $body);
    return $self->_wrap(
        $result->{subaccount},
        action => $self->_wrap_action($result->{action}),
    );
}


sub update {
    my ($self, $id, %params) = @_;
    croak 'Subaccount ID required' unless $id;

    my $body = {};
    for my $field (qw(name description labels)) {
        $body->{$field} = $params{$field} if exists $params{$field};
    }

    my $result = $self->client->put($self->_base_path . "/$id", $body);
    return $self->_wrap($result->{subaccount});
}


sub delete {
    my ($self, $id) = @_;
    croak 'Subaccount ID required' unless $id;

    my $result = $self->client->delete($self->_base_path . "/$id");
    return $self->_wrap_action($result->{action});
}

sub _action {
    my ($self, $id, $name, $body) = @_;
    croak 'Subaccount ID required' unless $id;

    my $path = $self->_base_path . "/$id/actions/$name";
    my $result = $self->client->post($path, $body);
    return $self->_wrap_action($result->{action});
}


sub change_home_directory {
    my ($self, $id, %params) = @_;
    croak 'home_directory required' unless defined $params{home_directory} && length $params{home_directory};
    return $self->_action($id, 'change_home_directory', {
        home_directory => $params{home_directory},
    });
}


sub reset_subaccount_password {
    my ($self, $id, %params) = @_;
    croak 'password required' unless defined $params{password} && length $params{password};
    return $self->_action($id, 'reset_subaccount_password', {
        password => $params{password},
    });
}


sub update_access_settings {
    my ($self, $id, %params) = @_;
    my $body = {};
    for my $field (qw(reachable_externally readonly samba_enabled ssh_enabled webdav_enabled)) {
        $body->{$field} = $params{$field} if exists $params{$field};
    }
    return $self->_action($id, 'update_access_settings', $body);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Storage::API::Subaccounts - Hetzner Storage Box Subaccounts API

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    my $subaccounts = $box->subaccounts;
    my $subaccount = $subaccounts->create(
        home_directory => '/home/user',
        password       => 'secret',
    );

=head1 DESCRIPTION

Manages subaccounts within one Storage Box.

=head2 list

    my $subaccounts = $box->subaccounts->list(%query);

Returns an arrayref of L<WWW::Hetzner::Storage::Subaccount> objects. The API
accepts C<name>, C<label_selector>, C<sort>, and C<username> filters.

=head2 get

    my $subaccount = $box->subaccounts->get($id);

Returns a L<WWW::Hetzner::Storage::Subaccount>.

=head2 create

    my $subaccount = $box->subaccounts->create(%params);

Creates a subaccount. C<home_directory> and C<password> are required. Returns
a Subaccount with its creation action.

=head2 update

    my $subaccount = $box->subaccounts->update($id, %params);

Updates a subaccount's C<name>, C<description>, and/or C<labels>. Returns the
updated Subaccount without an action.

=head2 delete

    my $action = $box->subaccounts->delete($id);

Deletes a subaccount and returns its action.

=head2 change_home_directory

    my $action = $box->subaccounts->change_home_directory(
        $id, home_directory => '/home/new-user',
    );

Changes a subaccount's home directory and returns its action.

=head2 reset_subaccount_password

    my $action = $box->subaccounts->reset_subaccount_password(
        $id, password => 'secret',
    );

Resets a subaccount password and returns its action.

=head2 update_access_settings

    my $action = $box->subaccounts->update_access_settings($id, %settings);

Updates subaccount access settings and returns its action.

=head1 SEE ALSO

=over 4

=item * L<WWW::Hetzner::Storage::StorageBox> - Parent Storage Box entity

=item * L<WWW::Hetzner::Storage::Subaccount> - Subaccount entity

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
