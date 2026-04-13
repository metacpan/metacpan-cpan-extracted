#!/usr/bin/false
# ABSTRACT: Bugzilla Field object and service
# PODNAME: WebService::Bugzilla::Field

package WebService::Bugzilla::Field 0.001;
use strictures 2;
use Moo;
use namespace::clean;

extends 'WebService::Bugzilla::Object';

has display_name     => (is => 'ro');
has is_custom        => (is => 'ro');
has is_mandatory     => (is => 'ro');
has is_on_bug_entry  => (is => 'ro');
has name             => (is => 'ro');
has type             => (is => 'ro');
has value_field      => (is => 'ro');
has values           => (is => 'ro');
has visibility_field => (is => 'ro');
has visibility_values => (is => 'ro');

sub get {
    my ($self) = @_;
    require WebService::Bugzilla::Field::Value;
    my $res = $self->client->get($self->_mkuri('field/bug'));
    return [
        map {
            my $f = $_;
            $self->new(
                client => $self->client,
                %{ $f },
                values => [
                    map { WebService::Bugzilla::Field::Value->new(%{$_}) }
                            @{ $f->{values} // [] }
                ],
            )
        }
        @{ $res->{fields} // [] }
    ];
}

sub get_field {
    my ($self, $id_or_name) = @_;
    require WebService::Bugzilla::Field::Value;
    my $res = $self->client->get($self->_mkuri("field/bug/$id_or_name"));
    return unless $res->{fields} && @{ $res->{fields} };
    my $f = $res->{fields}[0];
    return $self->new(
        client => $self->client,
        %{ $f },
        values => [
            map { WebService::Bugzilla::Field::Value->new(%{$_}) }
            @{ $f->{values} // [] }
        ],
    );
}

sub legal_values {
    my ($self, $field, $product_id) = @_;
    my $path = defined $product_id
        ? "field/bug/$field/$product_id/values"
        : "field/bug/$field/values";
    my $res = $self->client->get($self->_mkuri($path));
    return $res->{values};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Bugzilla::Field - Bugzilla Field object and service

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $fields = $bz->field->get;
    for my $f (@{$fields}) {
        say $f->name, ' (', $f->display_name, ')';
    }

    my $status = $bz->field->get_field('bug_status');
    for my $v (@{ $status->values }) {
        say $v->name;
    }

=head1 DESCRIPTION

Provides access to the
L<Bugzilla Field API|https://bmo.readthedocs.io/en/latest/api/core/v1/field.html>.
Field objects describe bug field definitions and provide helpers to list
field metadata and legal values.

=head1 ATTRIBUTES

All attributes are read-only.

=over 4

=item C<display_name>

Human-readable label for the field.

=item C<is_custom>

Boolean.  Whether the field is a custom field.

=item C<is_mandatory>

Boolean.  Whether the field is required.

=item C<is_on_bug_entry>

Boolean.  Whether the field appears on the new-bug entry form.

=item C<name>

Internal field name (e.g. C<bug_status>).

=item C<type>

Numeric field type identifier.

=item C<value_field>

Name of the field that controls which values are valid for this field.

=item C<values>

Arrayref of L<WebService::Bugzilla::Field::Value> objects representing
the legal values for this field.

=item C<visibility_field>

Name of the field that controls whether this field is visible.

=item C<visibility_values>

Arrayref of values of the C<visibility_field> for which this field is shown.

=back

=head1 METHODS

=head2 get

    my $fields = $bz->field->get;

List all bug field definitions.
See L<GET /rest/field/bug|https://bmo.readthedocs.io/en/latest/api/core/v1/field.html#fields>.

Returns an arrayref of L<WebService::Bugzilla::Field> objects.

=head2 get_field

    my $f = $bz->field->get_field($id_or_name);

Fetch a single field definition by numeric ID or name.
See L<GET /rest/field/bug/{id_or_name}|https://bmo.readthedocs.io/en/latest/api/core/v1/field.html#fields>.

Returns a L<WebService::Bugzilla::Field>, or C<undef> if not found.

=head2 legal_values

    my $values = $bz->field->legal_values($field);
    my $values = $bz->field->legal_values($field, $product_id);

Return legal values for a field, optionally scoped to a product.
See L<GET /rest/field/bug/{field}/values|https://bmo.readthedocs.io/en/latest/api/core/v1/field.html#legal-values>.

Returns an arrayref of value hashrefs.

=head1 SEE ALSO

L<WebService::Bugzilla> - main client

L<WebService::Bugzilla::Field::Value> - individual field value objects

L<https://bmo.readthedocs.io/en/latest/api/core/v1/field.html> - Bugzilla Field REST API

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
