package WebService::Toggl::Role::Set;

use Moo::Role;
with 'WebService::Toggl::Role::Base';

requires 'list_of';

has raw => (is => 'ro', lazy => 1, builder => 1);
sub _build_raw {
    my ($self) = @_;
    my $response = $self->api_get( $self->my_url );
    return $response->data;
}


sub all {
    my ($self) = @_;
    my $new_class = $self->list_of;
    return map { $self->new_item_from_raw($new_class, $_) } @{$self->raw};
}


1;
__END__

=encoding utf-8

=head1 NAME

WebService::Toggl::Role::Set - Common behavior for Sets of API objects

=head1 DESCRIPTION

This role provide behavior common to all Sets of
C<WebService::Toggl::API::> objects.

=head1 REQUIRES

=head2 list_of

The class name of the objects this set comprises.

=head1 ATTRIBUTES

=head2 raw

The raw data returned from query the collection endpoint.

=head1 METHODS

=head2 all

Returns a list of objects in the set.  The objects are constructed
from the raw data in the Set, so no additional queries are necessary.

=head1 LICENSE

Copyright (C) Fitz Elliott.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Fitz Elliott E<lt>felliott@fiskur.orgE<gt>

=cut

