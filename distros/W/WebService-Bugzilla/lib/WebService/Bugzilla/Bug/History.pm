#!/usr/bin/false
# ABSTRACT: A single bug history entry (one timestamp, one actor, N field changes)
# PODNAME: WebService::Bugzilla::Bug::History

package WebService::Bugzilla::Bug::History 0.001;
use strictures 2;
use Moo;
use namespace::clean;

has changes => (is => 'ro');
has when    => (is => 'ro');
has who     => (is => 'ro');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Bugzilla::Bug::History - A single bug history entry (one timestamp, one actor, N field changes)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $history = $bz->bug->history($bug_id);
    for my $entry (@{$history}) {
        say 'Changed by ', $entry->who, ' at ', $entry->when;
        for my $change (@{ $entry->changes }) {
            say '  ', $change->field_name, ': ',
                $change->removed, ' -> ', $change->added;
        }
    }

=head1 DESCRIPTION

Represents a single entry in a bug's change history.  Each entry
corresponds to a point in time when one or more fields were modified by a
single user.

History entries are obtained via the C<history> method on
L<WebService::Bugzilla::Bug>.
See L<GET /rest/bug/{id}/history|https://bmo.readthedocs.io/en/latest/api/core/v1/bug.html#bug-history>.

=head1 ATTRIBUTES

All attributes are read-only.

=over 4

=item C<changes>

Arrayref of L<WebService::Bugzilla::Bug::History::Change> objects, one for
each field modified in this entry.

=item C<when>

ISO 8601 datetime string indicating when the changes were made.

=item C<who>

Login name (or user hash) of the person who made the changes.

=back

=head1 SEE ALSO

L<WebService::Bugzilla::Bug> - bug objects

L<WebService::Bugzilla::Bug::History::Change> - individual field change objects

L<https://bmo.readthedocs.io/en/latest/api/core/v1/bug.html#bug-history> - Bugzilla Bug History REST API

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
