#!/usr/bin/false

# ABSTRACT: Bugzilla Bug object and service
# PODNAME: WebService::Bugzilla::Bug

package WebService::Bugzilla::Bug 0.001;
use strictures 2;
use Moo;
use namespace::clean;

extends 'WebService::Bugzilla::Object';
with 'WebService::Bugzilla::Role::Updatable';

sub _unwrap_key { 'bugs' }

has alias            => (is => 'ro', lazy => 1, builder => '_build_alias');
has assigned_to      => (is => 'ro', lazy => 1, builder => '_build_assigned_to');
has blocks           => (is => 'ro', lazy => 1, builder => '_build_blocks');
has cc               => (is => 'ro', lazy => 1, builder => '_build_cc');
has component        => (is => 'ro', lazy => 1, builder => '_build_component');
has creation_time    => (is => 'ro', lazy => 1, builder => '_build_creation_time');
has depends_on       => (is => 'ro', lazy => 1, builder => '_build_depends_on');
has is_open          => (is => 'ro', lazy => 1, builder => '_build_is_open');
has keywords         => (is => 'ro', lazy => 1, builder => '_build_keywords');
has last_change_time => (is => 'ro', lazy => 1, builder => '_build_last_change_time');
has op_sys           => (is => 'ro', lazy => 1, builder => '_build_op_sys');
has platform         => (is => 'ro', lazy => 1, builder => '_build_platform');
has priority         => (is => 'ro', lazy => 1, builder => '_build_priority');
has product          => (is => 'ro', lazy => 1, builder => '_build_product');
has reporter         => (is => 'ro', lazy => 1, builder => '_build_reporter');
has resolution       => (is => 'ro', lazy => 1, builder => '_build_resolution');
has severity         => (is => 'ro', lazy => 1, builder => '_build_severity');
has status           => (is => 'ro', lazy => 1, builder => '_build_status');
has summary          => (is => 'ro', lazy => 1, builder => '_build_summary');
has target_milestone => (is => 'ro', lazy => 1, builder => '_build_target_milestone');
has url              => (is => 'ro', lazy => 1, builder => '_build_url');
has version          => (is => 'ro', lazy => 1, builder => '_build_version');
has whiteboard       => (is => 'ro', lazy => 1, builder => '_build_whiteboard');

my @attrs = qw(
    alias
    assigned_to
    blocks
    cc
    component
    creation_time
    depends_on
    is_open
    keywords
    last_change_time
    op_sys
    platform
    priority
    product
    reporter
    resolution
    severity
    status
    summary
    target_milestone
    url
    version
    whiteboard
);

for my $attr (@attrs) {
    my $build = "_build_$attr";
    {
        no strict 'refs';
        *{ $build } = sub {
            my ($self) = @_;
            $self->_fetch_full($self->_mkuri('bug/' . $self->id));
            return $self->_api_data->{$attr};
        };
    }
}

sub create {
    my ($self, %params) = @_;
    my $res = $self->client->post($self->_mkuri('bug'), \%params);
        return $self->new(
            client => $self->client,
            _data  => { id => $res->{id} },
        );
}

sub get {
    my ($self, $id) = @_;
    my $res = $self->client->get($self->_mkuri("bug/$id"));
    return unless $res->{bugs} && @{ $res->{bugs} };
        return $self->new(
            client => $self->client,
            _data  => $res->{bugs}[0],
        );
}

sub history {
    my ($self, $id) = @_;
    $id //= $self->id;
    require WebService::Bugzilla::Bug::History;
    require WebService::Bugzilla::Bug::History::Change;
    my $res = $self->client->get($self->_mkuri("bug/$id/history"));
    my @raw = @{ ($res->{bugs} // [])->[0]{history} // [] };
    return [
        map {
            my $entry = $_;
            WebService::Bugzilla::Bug::History->new(
                when    => $entry->{when},
                who     => $entry->{who},
                changes => [
                    map { WebService::Bugzilla::Bug::History::Change->new(%{$_}) }
                    @{ $entry->{changes} // [] }
                ],
            )
        } @raw
    ];
}

sub possible_duplicates {
    my ($self, $id) = @_;
    $id //= $self->id;
    my $res = $self->client->get($self->_mkuri("bug/$id/duplicates"));
    return [
            map {
                $self->new(
                    client => $self->client,
                    _data  => $_
                )
            }
            @{ $res->{bugs} // [] }
    ];
}

sub search {
    my ($self, %params) = @_;
    my $res = $self->client->get($self->_mkuri('bug'), \%params);
    return [
            map {
                $self->new(
                    client => $self->client,
                    _data  => $_
                )
            }
            @{ $res->{bugs} // [] }
    ];
}

sub last_visit {
    my ($self) = @_;
    require WebService::Bugzilla::BugUserLastVisit;
    return $self->client->bug_user_last_visit->get_bug($self->id);
}

sub update_visit {
    my ($self) = @_;
    require WebService::Bugzilla::BugUserLastVisit;
    return $self->client->bug_user_last_visit->update($self->id);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Bugzilla::Bug - Bugzilla Bug object and service

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $bug = $bz->bug->get(12345);
    say $bug->summary;
    say $bug->status, ' / ', $bug->resolution;

    # Search
    my $bugs = $bz->bug->search(product => 'Firefox', status => 'NEW');

    # Create
    my $new = $bz->bug->create(
        product   => 'TestProduct',
        component => 'General',
        summary   => 'Something is broken',
        version   => 'unspecified',
    );
    say 'Created bug ', $new->id;

    # Update
    $bug->update(status => 'RESOLVED', resolution => 'FIXED');

    # History
    my $history = $bug->history;

=head1 DESCRIPTION

Provides access to the
L<Bugzilla Bug API|https://bmo.readthedocs.io/en/latest/api/core/v1/bug.html>.
Bug objects expose many read-only attributes corresponding to Bugzilla bug
fields; all are lazy and fetched on first access.

=head1 ATTRIBUTES

All attributes are read-only and lazy.  Accessing any attribute on a
stub object (one created with only an C<id>) triggers a single API call
that populates every field at once.

=over 4

=item C<alias>

Arrayref of bug aliases.

=item C<assigned_to>

Login name of the assignee.

=item C<blocks>

Arrayref of bug IDs that this bug blocks.

=item C<cc>

Arrayref of login names on the CC list.

=item C<component>

The component name.

=item C<creation_time>

ISO 8601 datetime when the bug was filed.

=item C<depends_on>

Arrayref of bug IDs that this bug depends on.

=item C<is_open>

Boolean.  Whether the bug is in an open state.

=item C<keywords>

Arrayref of keyword strings.

=item C<last_change_time>

ISO 8601 datetime of the most recent change.

=item C<op_sys>

Operating system field.

=item C<platform>

Hardware platform field.

=item C<priority>

Priority level (e.g. C<P1>, C<P2>).

=item C<product>

Product name.

=item C<reporter>

Login name of the reporter.

=item C<resolution>

Resolution string (e.g. C<FIXED>, C<INVALID>), or empty when unresolved.

=item C<severity>

Severity level.

=item C<status>

Current status string (e.g. C<NEW>, C<ASSIGNED>, C<RESOLVED>).

=item C<summary>

One-line summary of the bug.

=item C<target_milestone>

Target milestone string.

=item C<url>

URL associated with the bug.

=item C<version>

Version string.

=item C<whiteboard>

Status-whiteboard text.

=back

=head1 METHODS

=head2 create

    my $bug = $bz->bug->create(%params);

Create a new bug.
See L<POST /rest/bug|https://bmo.readthedocs.io/en/latest/api/core/v1/bug.html#create-bug>.

Returns a stub L<WebService::Bugzilla::Bug> with the new C<id>.

=head2 get

    my $bug = $bz->bug->get($id);

Fetch a single bug by numeric ID.
See L<GET /rest/bug/{id}|https://bmo.readthedocs.io/en/latest/api/core/v1/bug.html#get-bug>.

Returns a L<WebService::Bugzilla::Bug> object, or C<undef> if not found.

=head2 history

    my $entries = $bug->history;
    my $entries = $bz->bug->history($id);

Retrieve the change history for a bug.
See L<GET /rest/bug/{id}/history|https://bmo.readthedocs.io/en/latest/api/core/v1/bug.html#bug-history>.

Returns an arrayref of L<WebService::Bugzilla::Bug::History> objects.

=head2 possible_duplicates

    my $dupes = $bug->possible_duplicates;
    my $dupes = $bz->bug->possible_duplicates($id);

Retrieve bugs that may be duplicates.

Returns an arrayref of L<WebService::Bugzilla::Bug> objects.

=head2 search

    my $bugs = $bz->bug->search(%params);

Search for bugs matching the given criteria.
See L<GET /rest/bug|https://bmo.readthedocs.io/en/latest/api/core/v1/bug.html#search-bugs>.

Returns an arrayref of L<WebService::Bugzilla::Bug> objects.

=head2 update

    my $updated = $bug->update(%params);
    my $updated = $bz->bug->update($id, %params);

Update an existing bug.
See L<PUT /rest/bug/{id}|https://bmo.readthedocs.io/en/latest/api/core/v1/bug.html#update-bug>.

Can be called as an instance method (uses the object's ID) or with an
explicit ID as the first argument.

Returns a L<WebService::Bugzilla::Bug> with the updated data.

=head2 last_visit

    my $visit = $bug->last_visit;

Convenience wrapper; returns the
L<WebService::Bugzilla::BugUserLastVisit> record for this bug.

=head2 update_visit

    my $visit = $bug->update_visit;

Convenience wrapper; marks the current user's last visit on this bug as
"now".

=head1 SEE ALSO

L<WebService::Bugzilla> - main client

L<WebService::Bugzilla::Bug::History> - history entry objects

L<WebService::Bugzilla::Bug::History::Change> - individual field changes

L<WebService::Bugzilla::BugUserLastVisit> - last-visit records

L<https://bmo.readthedocs.io/en/latest/api/core/v1/bug.html> - Bugzilla Bug REST API

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
