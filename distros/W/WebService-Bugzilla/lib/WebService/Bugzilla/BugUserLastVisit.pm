#!/usr/bin/false
# ABSTRACT: Bugzilla BugUserLastVisit object and service
# PODNAME: WebService::Bugzilla::BugUserLastVisit

package WebService::Bugzilla::BugUserLastVisit 0.001;
use strictures 2;
use Moo;
use namespace::clean;

extends 'WebService::Bugzilla::Object';

has bug_id        => (is => 'ro');
has last_visit_ts => (is => 'ro');

sub get {
    my ($self, %params) = @_;
    my $res = $self->client->get($self->_mkuri('bug_user_last_visit'), \%params);
    return [
        map {
            $self->new(
                client => $self->client,
                %{ $_ }
            )
        }
        @{ $res // [] }
    ];
}

sub get_bug {
    my ($self, $id) = @_;
    my $res = $self->client->get($self->_mkuri("bug_user_last_visit/$id"));
    return unless $res && @{$res};
    return $self->new(
        client => $self->client,
        %{ $res->[0] }
    );
}

sub update {
    my $self = shift;
    my $id = $self->has_id ? $self->id : shift;
    my $res = $self->client->post($self->_mkuri("bug_user_last_visit/$id"), {});
    return unless $res && @{$res};
    return $self->new(
        client => $self->client,
        %{ $res->[0] }
    );
}

sub update_bugs {
    my ($self, @ids) = @_;
    my $res = $self->client->post($self->_mkuri('bug_user_last_visit'), \@ids);
    return [
        map {
            $self->new(
                client => $self->client,
                %{ $_ }
            )
        }
        @{ $res // [] }
    ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Bugzilla::BugUserLastVisit - Bugzilla BugUserLastVisit object and service

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $visits = $bz->bug_user_last_visit->get;
    for my $v (@{$visits}) {
        say 'Bug ', $v->bug_id, ' last visited: ', $v->last_visit_ts;
    }

    # Update last-visit for a single bug
    $bz->bug_user_last_visit->update(12345);

    # Bulk update
    $bz->bug_user_last_visit->update_bugs(12345, 67890);

=head1 DESCRIPTION

Provides access to the
L<Bugzilla Bug User Last Visit API|https://bmo.readthedocs.io/en/latest/api/core/v1/bug-user-last-visit.html>.
Records track when the authenticated user last visited each bug.

=head1 ATTRIBUTES

All attributes are read-only.

=over 4

=item C<bug_id>

Numeric ID of the bug.

=item C<last_visit_ts>

ISO 8601 datetime of the last visit.

=back

=head1 METHODS

=head2 get

    my $visits = $bz->bug_user_last_visit->get(%params);

Fetch last-visit records for the authenticated user.
See L<GET /rest/bug_user_last_visit|https://bmo.readthedocs.io/en/latest/api/core/v1/bug-user-last-visit.html>.

Returns an arrayref of L<WebService::Bugzilla::BugUserLastVisit> objects.

=head2 get_bug

    my $v = $bz->bug_user_last_visit->get_bug($bug_id);

Fetch the last-visit record for a specific bug.

Returns a L<WebService::Bugzilla::BugUserLastVisit>, or C<undef> if none.

=head2 update

    my $v = $bz->bug_user_last_visit->update($bug_id);
    my $v = $visit->update;

Update the last-visit timestamp for a single bug.

Returns the updated L<WebService::Bugzilla::BugUserLastVisit>.

=head2 update_bugs

    my $visits = $bz->bug_user_last_visit->update_bugs(@bug_ids);

Bulk-update last-visit timestamps for multiple bugs.

Returns an arrayref of L<WebService::Bugzilla::BugUserLastVisit> objects.

=head1 SEE ALSO

L<WebService::Bugzilla> - main client

L<WebService::Bugzilla::Bug> - bug objects

L<https://bmo.readthedocs.io/en/latest/api/core/v1/bug-user-last-visit.html> - Bugzilla Bug User Last Visit REST API

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
