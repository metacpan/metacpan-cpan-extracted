#!/usr/bin/false
# ABSTRACT: A single legal value for a Bugzilla field
# PODNAME: WebService::Bugzilla::Field::Value

package WebService::Bugzilla::Field::Value 0.001;
use strictures 2;
use Moo;
use Types::Standard qw( Bool );
use namespace::clean;

has can_change_to     => (is => 'ro');
has description       => (is => 'ro');
has is_active         => (is => 'ro', isa => Bool);
has is_open           => (is => 'ro');
has name              => (is => 'ro');
has sort_key          => (is => 'ro');
has visibility_values => (is => 'ro');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Bugzilla::Field::Value - A single legal value for a Bugzilla field

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $field = $bz->field->get_field('bug_status');
    for my $value (@{ $field->values }) {
        say 'Value: ', $value->name;
        say '  Active: ', $value->is_active ? 'yes' : 'no';
        say '  Sort key: ', $value->sort_key;
        if ($value->can_change_to) {
            say '  Can change to: ', join(', ', @{ $value->can_change_to });
        }
    }

=head1 DESCRIPTION

Represents a single valid value for an enumerated Bugzilla field (status,
priority, resolution, custom selects, etc.).

Field value objects are accessed via the C<values> attribute of a
L<WebService::Bugzilla::Field> object.
See L<GET /rest/field/bug/{field}|https://bmo.readthedocs.io/en/latest/api/core/v1/field.html#fields>.

=head1 ATTRIBUTES

All attributes are read-only.

=over 4

=item C<can_change_to>

Arrayref of value names that bugs can transition to from this value.  Only
applicable for workflow fields like status.

=item C<description>

Human-readable description of what this value means.

=item C<is_active>

Boolean.  Whether this value is active (can be used for new bugs or
transitions).

=item C<is_open>

Boolean.  For status values, whether bugs with this status are considered
open (not yet resolved).

=item C<name>

Internal value name (e.g. C<OPEN>, C<ASSIGNED>, C<RESOLVED>).

=item C<sort_key>

Numeric key used to order values within the field.

=item C<visibility_values>

Arrayref of values for another field that control when this value is
visible.  Used for dependent selects.

=back

=head1 SEE ALSO

L<WebService::Bugzilla::Field> - field definition objects

L<WebService::Bugzilla> - main client

L<https://bmo.readthedocs.io/en/latest/api/core/v1/field.html> - Bugzilla Field REST API

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
