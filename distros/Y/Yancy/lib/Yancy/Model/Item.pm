package Yancy::Model::Item;
our $VERSION = '1.085';
# ABSTRACT: Interface to a single item

#pod =head1 SYNOPSIS
#pod
#pod     my $schema = $model->schema( 'foo' );
#pod     my $item = $schema->get( $id );
#pod
#pod     $item->set( $data );
#pod     $item->delete;
#pod
#pod =head1 DESCRIPTION
#pod
#pod B<NOTE>: This module is experimental and it's API may change before
#pod Yancy v2!
#pod
#pod For information on how to extend this module to add your own schema
#pod and item methods, see L<Yancy::Guides::Model>.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Yancy::Guides::Model>
#pod
#pod =cut

use Mojo::Base -base;
use overload
    '%{}' => \&_hashref,
    fallback => 1;

sub _hashref {
    my ( $self ) = @_;
    # If we're not being called by ourselves or one of our superclasses,
    # we want to pretend we're a hashref of plain data.
    if ( !$self->isa( scalar caller ) ) {
        return $self->{data};
    }
    return $self;
}

sub TO_JSON {
    my ( $self ) = @_;
    return $self->{data};
}

#pod =attr schema
#pod
#pod The L<Yancy::Model::Schema> object containing this item.
#pod
#pod =cut

has schema => sub { die 'schema is required' };

#pod =attr data
#pod
#pod The row data for this item.
#pod
#pod =cut

has data => sub { die 'data is required' };

#pod =method model
#pod
#pod The L<Yancy::Model> object that contains this item.
#pod
#pod =cut

sub model { shift->schema->model }

#pod =method id
#pod
#pod The ID field for the item. Returns a string or a hash-reference (for composite keys).
#pod
#pod =cut

sub id {
    my ( $self ) = @_;
    my $id_field = $self->schema->id_field;
    my $data = $self->data;
    if ( ref $id_field eq 'ARRAY' ) {
        return { map { $_ => $data->{$_} } @$id_field };
    }
    return $data->{ $id_field };
}

#pod =method set
#pod
#pod Set data in this item. Returns true if successful.
#pod
#pod =cut

sub set {
    my ( $self, $data ) = @_;
    if ( $self->schema->set( $self->id, $data ) ) {
        $self->data->{ $_ } = $data->{ $_ } for keys %$data;
        return 1;
    }
    return 0;
}

#pod =method delete
#pod
#pod Delete this item from the database. Returns true if successful.
#pod
#pod =cut

sub delete {
    my ( $self ) = @_;
    return $self->schema->delete( $self->id );
}

1;

__END__

=pod

=head1 NAME

Yancy::Model::Item - Interface to a single item

=head1 VERSION

version 1.085

=head1 SYNOPSIS

    my $schema = $model->schema( 'foo' );
    my $item = $schema->get( $id );

    $item->set( $data );
    $item->delete;

=head1 DESCRIPTION

B<NOTE>: This module is experimental and it's API may change before
Yancy v2!

For information on how to extend this module to add your own schema
and item methods, see L<Yancy::Guides::Model>.

=head1 ATTRIBUTES

=head2 schema

The L<Yancy::Model::Schema> object containing this item.

=head2 data

The row data for this item.

=head1 METHODS

=head2 model

The L<Yancy::Model> object that contains this item.

=head2 id

The ID field for the item. Returns a string or a hash-reference (for composite keys).

=head2 set

Set data in this item. Returns true if successful.

=head2 delete

Delete this item from the database. Returns true if successful.

=head1 SEE ALSO

L<Yancy::Guides::Model>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
