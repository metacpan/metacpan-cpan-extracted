package Yancy::Model::Schema;
our $VERSION = '1.076';
# ABSTRACT: Interface to a single schema

#pod =head1 SYNOPSIS
#pod
#pod     my $schema = $app->model->schema( 'foo' );
#pod
#pod     my $id = $schema->create( $data );
#pod     my $item = $schema->get( $id );
#pod     my $count = $schema->delete( $id );
#pod     my $count = $schema->delete( $where );
#pod     my $count = $schema->set( $id, $data );
#pod     my $count = $schema->set( $where, $data );
#pod
#pod     my $res = $schema->list( $where, $opts );
#pod     for my $item ( @{ $res->{items} } ) { ... }
#pod
#pod =head1 DESCRIPTION
#pod
#pod B<NOTE>: This module is experimental and its API may change before
#pod Yancy v2!
#pod
#pod For information on how to extend this module to add your own schema
#pod and item methods, see L<Yancy::Guides::Model>.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Yancy::Guides::Model>, L<Yancy::Model>
#pod
#pod =cut

use Mojo::Base -base;

#pod =attr model
#pod
#pod The L<Yancy::Model> object that created this schema object.
#pod
#pod =cut

has model => sub { die 'model is required' };

#pod =attr name
#pod
#pod The name of the schema.
#pod
#pod =cut

has name => sub { die 'name is required' };

sub _backend { shift->model->backend };
has _item_class => sub {
    my $self = shift;
    return $self->model->find_class( Item => $self->name );
};

#pod =method info
#pod
#pod The JSON Schema for this schema.
#pod
#pod =cut

sub info {
    my ( $self ) = @_;
    return $self->_backend->schema->{ $self->name };
}

#pod =method id_field
#pod
#pod The ID field for this schema. Either a single string, or an arrayref of
#pod strings (for composite keys).
#pod
#pod =cut

sub id_field {
    my ( $self ) = @_;
    return $self->info->{'x-id-field'} // 'id';
}

#pod =method build_item
#pod
#pod Turn a hashref of row data into a L<Yancy::Model::Item> object using
#pod L<Yancy::Model/find_class> to find the correct class.
#pod
#pod =cut

sub build_item {
    my ( $self, $data ) = @_;
    return $self->_item_class->new( { data => $data, schema => $self } );
}

#pod =method get
#pod
#pod Get an item by its ID. Returns a L<Yancy::Model::Item> object.
#pod
#pod =cut

sub get {
    my ( $self, $id ) = @_;
    return $self->build_item( $self->_backend->get( $self->name, $id ) // return undef );
}

#pod =method list
#pod
#pod List items. Returns a hash reference with C<items> and C<total> keys. The C<items> is
#pod an array ref of L<Yancy::Model::Item> objects. C<total> is the total number of items
#pod that would be returned without any C<offset> or C<limit> options.
#pod
#pod =cut

sub list {
    my ( $self, $where, $opt ) = @_;
    my $res = $self->_backend->list( $self->name, $where, $opt );
    return { items => [ map { $self->build_item( $_ ) } @{ $res->{items} } ], total => $res->{total} };
}

#pod =method create
#pod
#pod Create a new item. Returns the ID of the created item.
#pod
#pod =cut

sub create {
    my ( $self, $data ) = @_;
    return $self->_backend->create( $self->name, $data );
}

#pod =method set
#pod
#pod Set the given fields in an item. See also L<Yancy::Model::Item/set>.
#pod
#pod =cut

sub set {
    my ( $self, $id, $data ) = @_;
    # XXX: Use get() to get the item instance first? Then they could
    # override set() to do things...
    return $self->_backend->set( $self->name, $id, $data );
}

#pod =method delete
#pod
#pod Delete an item. See also L<Yancy::Model::Item/delete>.
#pod
#pod =cut

sub delete {
    my ( $self, $id ) = @_;
    # XXX: Use get() to get the item instance first? Then they could
    # override delete() to do things...
    return $self->_backend->delete( $self->name, $id );
}

1;

__END__

=pod

=head1 NAME

Yancy::Model::Schema - Interface to a single schema

=head1 VERSION

version 1.076

=head1 SYNOPSIS

    my $schema = $app->model->schema( 'foo' );

    my $id = $schema->create( $data );
    my $item = $schema->get( $id );
    my $count = $schema->delete( $id );
    my $count = $schema->delete( $where );
    my $count = $schema->set( $id, $data );
    my $count = $schema->set( $where, $data );

    my $res = $schema->list( $where, $opts );
    for my $item ( @{ $res->{items} } ) { ... }

=head1 DESCRIPTION

B<NOTE>: This module is experimental and its API may change before
Yancy v2!

For information on how to extend this module to add your own schema
and item methods, see L<Yancy::Guides::Model>.

=head1 ATTRIBUTES

=head2 model

The L<Yancy::Model> object that created this schema object.

=head2 name

The name of the schema.

=head1 METHODS

=head2 info

The JSON Schema for this schema.

=head2 id_field

The ID field for this schema. Either a single string, or an arrayref of
strings (for composite keys).

=head2 build_item

Turn a hashref of row data into a L<Yancy::Model::Item> object using
L<Yancy::Model/find_class> to find the correct class.

=head2 get

Get an item by its ID. Returns a L<Yancy::Model::Item> object.

=head2 list

List items. Returns a hash reference with C<items> and C<total> keys. The C<items> is
an array ref of L<Yancy::Model::Item> objects. C<total> is the total number of items
that would be returned without any C<offset> or C<limit> options.

=head2 create

Create a new item. Returns the ID of the created item.

=head2 set

Set the given fields in an item. See also L<Yancy::Model::Item/set>.

=head2 delete

Delete an item. See also L<Yancy::Model::Item/delete>.

=head1 SEE ALSO

L<Yancy::Guides::Model>, L<Yancy::Model>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
