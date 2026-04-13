#!/usr/bin/false
# ABSTRACT: Bugzilla Classification object and service
# PODNAME: WebService::Bugzilla::Classification

package WebService::Bugzilla::Classification 0.001;
use strictures 2;
use Moo;
use namespace::clean;

extends 'WebService::Bugzilla::Object';

has description => (is => 'ro');
has name        => (is => 'ro');
has products    => (is => 'ro');
has sort_key    => (is => 'ro');

sub get {
    my ($self, $id_or_name) = @_;
    my $res = $self->client->get($self->_mkuri("classification/$id_or_name"));
    return unless $res->{classifications} && @{ $res->{classifications} };
    return $self->new(
        client => $self->client,
        %{ $res->{classifications}[0] }
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Bugzilla::Classification - Bugzilla Classification object and service

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $class = $bz->classification->get('Client Software');
    say $class->name, ': ', $class->description;

    for my $p (@{ $class->products }) {
        say '  ', $p->{name};
    }

=head1 DESCRIPTION

Provides access to the
L<Bugzilla Classification API|https://bmo.readthedocs.io/en/latest/api/core/v1/classification.html>.
Classification objects represent the top-level grouping of products.

=head1 ATTRIBUTES

All attributes are read-only.

=over 4

=item C<description>

Human-readable description of the classification.

=item C<name>

Classification name.

=item C<products>

Arrayref of product data hashes belonging to this classification.

=item C<sort_key>

Numeric sort key for ordering classifications.

=back

=head1 METHODS

=head2 get

    my $class = $bz->classification->get($id_or_name);

Fetch a classification by numeric ID or name.
See L<GET /rest/classification/{id_or_name}|https://bmo.readthedocs.io/en/latest/api/core/v1/classification.html#get-classification>.

Returns a L<WebService::Bugzilla::Classification>, or C<undef> if not found.

=head1 SEE ALSO

L<WebService::Bugzilla> - main client

L<WebService::Bugzilla::Product> - product objects

L<https://bmo.readthedocs.io/en/latest/api/core/v1/classification.html> - Bugzilla Classification REST API

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
