#!/usr/bin/false
# ABSTRACT: A single field change within a bug history entry
# PODNAME: WebService::Bugzilla::Bug::History::Change

package WebService::Bugzilla::Bug::History::Change 0.001;
use strictures 2;
use Moo;
use namespace::clean;

has added         => (is => 'ro');
has attachment_id => (is => 'ro', predicate => 1);
has field_name    => (is => 'ro');
has removed       => (is => 'ro');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Bugzilla::Bug::History::Change - A single field change within a bug history entry

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $history = $bz->bug->history($bug_id);
    for my $entry (@{$history}) {
        for my $change (@{ $entry->changes }) {
            say $change->field_name, ': ',
                $change->removed, ' -> ', $change->added;
            if ($change->has_attachment_id) {
                say '  (attachment ', $change->attachment_id, ')';
            }
        }
    }

=head1 DESCRIPTION

Represents a single field change within a bug history entry.  Multiple
changes can occur at the same time (in the same
L<WebService::Bugzilla::Bug::History> entry), typically when a user
modifies several fields in one operation.

Change objects are accessed via the C<changes> attribute of a
L<WebService::Bugzilla::Bug::History> object.

=head1 ATTRIBUTES

All attributes are read-only.

=over 4

=item C<added>

New value for the field.  For multi-value fields (like CC) this may be a
comma-separated string.

=item C<attachment_id>

Numeric attachment ID when the change relates to an attachment (e.g. a flag
or description change).  Use C<has_attachment_id> to check presence.

=item C<field_name>

Name of the field that was changed (e.g. C<status>, C<resolution>, C<cc>).

=item C<removed>

Previous value for the field.

=back

=head1 METHODS

=head2 has_attachment_id

    if ($change->has_attachment_id) { ... }

L<Moo> predicate method.  Returns true when C<attachment_id> is set.

=head1 SEE ALSO

L<WebService::Bugzilla::Bug::History> - history entry objects

L<WebService::Bugzilla::Bug> - bug objects

L<https://bmo.readthedocs.io/en/latest/api/core/v1/bug.html#bug-history> - Bugzilla Bug History REST API

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
