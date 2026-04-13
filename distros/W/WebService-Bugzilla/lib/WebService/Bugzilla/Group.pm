#!/usr/bin/false
# ABSTRACT: Bugzilla Group object and service
# PODNAME: WebService::Bugzilla::Group

package WebService::Bugzilla::Group 0.001;
use strictures 2;
use Moo;
use namespace::clean;

extends 'WebService::Bugzilla::Object';
with 'WebService::Bugzilla::Role::Updatable';

sub _unwrap_key { 'groups' }

has description  => (is => 'ro', lazy => 1, builder => '_build_description');
has icon_url     => (is => 'ro', lazy => 1, builder => '_build_icon_url');
has is_active    => (is => 'ro', lazy => 1, builder => '_build_is_active');
has is_bug_group => (is => 'ro', lazy => 1, builder => '_build_is_bug_group');
has membership   => (is => 'ro', lazy => 1, builder => '_build_membership');
has name         => (is => 'ro', lazy => 1, builder => '_build_name');
has user_regexp  => (is => 'ro', lazy => 1, builder => '_build_user_regexp');

my @attrs = qw(
    description
    icon_url
    is_active
    is_bug_group
    membership
    name
    user_regexp
);

for my $attr (@attrs) {
    my $build = "_build_$attr";
    {
        no strict 'refs';
        *{ $build } = sub {
            my ($self) = @_;
            my $id_or_name = $self->_api_data->{name} // $self->id;
            $self->_fetch_full($self->_mkuri("group/$id_or_name"));
            return $self->_api_data->{$attr};
        };
    }
}

sub create {
    my ($self, %params) = @_;
    my $res = $self->client->post($self->_mkuri('group'), \%params);
    return $self->new(
        client => $self->client,
        _data  => { %params, id => $res->{id} },
    );
}

sub get {
    my ($self, $id_or_name) = @_;
    my $res = $self->client->get($self->_mkuri("group/$id_or_name"));
    return unless $res->{groups} && @{ $res->{groups} };
    return $self->new(
        client => $self->client,
        _data  => $res->{groups}[0],
    );
}

sub search {
    my ($self, %params) = @_;
    my $res = $self->client->get($self->_mkuri('group'), \%params);
    return [
        map {
            $self->new(
                client => $self->client,
                _data  => $_
            )
        }
        @{ $res->{groups} // [] }
    ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Bugzilla::Group - Bugzilla Group object and service

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $group = $bz->group->get('admin');
    say $group->name, ': ', $group->description;

    my $groups = $bz->group->search(membership => 1);

=head1 DESCRIPTION

Provides access to the
L<Bugzilla Group API|https://bmo.readthedocs.io/en/latest/api/core/v1/group.html>.
Group objects represent user groups in Bugzilla and expose attributes about
the group plus helper methods to create, fetch, search, and update groups.

=head1 ATTRIBUTES

All attributes are read-only and lazy.

=over 4

=item C<description>

Human-readable description of the group.

=item C<icon_url>

URL for the group's icon, if any.

=item C<is_active>

Boolean.  Whether the group is active.

=item C<is_bug_group>

Boolean.  Whether the group controls bug visibility.

=item C<membership>

Membership information for the authenticated user.

=item C<name>

Group name.

=item C<user_regexp>

Regular expression for automatic membership.

=back

=head1 METHODS

=head2 create

    my $group = $bz->group->create(%params);

Create a new group.
See L<POST /rest/group|https://bmo.readthedocs.io/en/latest/api/core/v1/group.html#create-group>.

=head2 get

    my $group = $bz->group->get($id_or_name);

Fetch a group by numeric ID or name.
See L<GET /rest/group/{id}|https://bmo.readthedocs.io/en/latest/api/core/v1/group.html#get-group>.

Returns a L<WebService::Bugzilla::Group>, or C<undef> if not found.

=head2 search

    my $groups = $bz->group->search(%params);

Search for groups.
See L<GET /rest/group|https://bmo.readthedocs.io/en/latest/api/core/v1/group.html#list-groups>.

Returns an arrayref of L<WebService::Bugzilla::Group> objects.

=head2 update

    my $updated = $group->update(%params);
    my $updated = $bz->group->update($id, %params);

Update a group.
See L<PUT /rest/group/{id}|https://bmo.readthedocs.io/en/latest/api/core/v1/group.html#update-group>.

=head1 SEE ALSO

L<WebService::Bugzilla> - main client

L<https://bmo.readthedocs.io/en/latest/api/core/v1/group.html> - Bugzilla Group REST API

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
