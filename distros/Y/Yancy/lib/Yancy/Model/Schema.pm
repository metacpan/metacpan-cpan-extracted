package Yancy::Model::Schema;
our $VERSION = '1.087';
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
use Mojo::JSON qw( true false );
use Yancy::Util qw( json_validator is_type derp );

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

#pod =attr json_schema
#pod
#pod The JSON Schema for this schema.
#pod
#pod =cut

has json_schema => sub { die 'json_schema is required' };

sub _backend { shift->model->backend };
has _item_class => sub {
    my $self = shift;
    return $self->model->find_class( Item => $self->name );
};
sub _log { shift->model->log };

sub new {
  my ( $class, @args ) = @_;
  my $self = $class->SUPER::new( @args );
  $self->_check_json_schema;
  return $self;
}

#pod =method id_field
#pod
#pod The ID field for this schema. Either a single string, or an arrayref of
#pod strings (for composite keys).
#pod
#pod =cut

sub id_field {
    my ( $self ) = @_;
    return $self->json_schema->{'x-id-field'} // 'id';
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

#pod =method validate
#pod
#pod Validate an item. Returns a list of errors (if any).
#pod
#pod =cut

sub validate {
    my ( $self, $item, %opt ) = @_;
    my $schema = $self->json_schema;

    if ( $opt{ properties } ) {
        # Only validate these properties
        $schema = {
            type => 'object',
            required => [
                grep { my $f = $_; grep { $_ eq $f } @{ $schema->{required} || [] } }
                @{ $opt{ properties } }
            ],
            properties => {
                map { $_ => $schema->{properties}{$_} }
                grep { exists $schema->{properties}{$_} }
                @{ $opt{ properties } }
            },
            additionalProperties => 0, # Disallow any other properties
        };
    }

    my $v = json_validator();
    $v->schema( $schema );

    my @errors;
    # This is a shallow copy of the item that we will change to pass
    # Yancy-specific additions to schema validation
    my %check_item = %$item;
    for my $prop_name ( keys %{ $schema->{properties} } ) {
        my $prop = $schema->{properties}{ $prop_name };

        # These blocks fix problems with validation only. If the
        # problem is the database understanding the value, it must be
        # fixed in the backend class.

        # Pre-filter booleans
        if ( is_type( $prop->{type}, 'boolean' ) && defined $check_item{ $prop_name } ) {
            my $value = $check_item{ $prop_name };
            if ( $value eq 'false' or !$value ) {
                $value = false;
            } else {
                $value = true;
            }
            $check_item{ $prop_name } = $value;
        }
        # An empty date-time, date, or time must become undef: The empty
        # string will never pass the format check, but properties that
        # are allowed to be null can be validated.
        if ( is_type( $prop->{type}, 'string' ) && $prop->{format} && $prop->{format} =~ /^(?:date-time|date|time)$/ ) {
            if ( exists $check_item{ $prop_name } && !$check_item{ $prop_name } ) {
                $check_item{ $prop_name } = undef;
            }
            # The "now" special value will not validate yet, but will be
            # replaced by the Backend with something useful
            elsif ( ($check_item{ $prop_name }//$prop->{default}//'') eq 'now' ) {
                $check_item{ $prop_name } = '2021-01-01 00:00:00';
            }
        }
        # Always add dummy passwords to pass required checks
        if ( $prop->{format} && $prop->{format} eq 'password' && !$check_item{ $prop_name } ) {
            $check_item{ $prop_name } = '<PASSWORD>';
        }

        # XXX: JSON::Validator 4 moved support for readOnly/writeOnly to
        # the OpenAPI schema classes, but we use JSON Schema internally,
        # so we need to make support ourselves for now...
        if ( $prop->{readOnly} && exists $check_item{ $prop_name } ) {
            push @errors, JSON::Validator::Error->new(
                "/$prop_name", "Read-only.",
            );
        }
    }

    push @errors, $v->validate( \%check_item );
    return @errors;
}

#pod =method get
#pod
#pod Get an item by its ID. Returns a L<Yancy::Model::Item> object.
#pod
#pod =cut

sub get {
    my ( $self, $id, %opt ) = @_;
    return $self->build_item( $self->_backend->get( $self->name, $id, %opt ) // return undef );
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
    if ( my @errors = $self->validate( $data ) ) {
        $self->_log->error(
            sprintf 'Error validating new item in schema "%s": %s',
            $self->name,
            join ', ', @errors
        );
        die \@errors; # XXX: Throw an exception instead that can stringify to something useful
    }
    my $retval = eval { $self->_backend->create( $self->name, $data ) };
    if ( my $error = $@ ) {
        $self->_log->error(
            sprintf 'Error creating item in schema "%s": %s',
            $self->name, $error,
        );
        die $error;
    }
    return $retval;
}

#pod =method set
#pod
#pod Set the given fields in an item. See also L<Yancy::Model::Item/set>.
#pod
#pod =cut

sub set {
    my ( $self, $id, $data ) = @_;
    if ( my @errors = $self->validate( $data, properties => [ keys %$data ] ) ) {
        $self->_log->error(
            sprintf 'Error validating item with ID "%s" in schema "%s": %s',
            $id, $self->name,
            join ', ', @errors
        );
        die \@errors; # XXX: Throw an exception instead that can stringify to something useful
    }
    my $retval = eval { $self->_backend->set( $self->name, $id, $data ) };
    if ( my $error = $@ ) {
        $self->_log->error(
            sprintf 'Error setting item with ID "%s" in schema "%s": %s',
            $id, $self->name, $error,
        );
        die $error;
    }
    return $retval;
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

sub _check_json_schema {
    my ( $self ) = @_;
    my $name = $self->name;
    my $json_schema = $self->json_schema;

    # Deprecate x-view. Yancy::Model is a much better
    # solution to that.
    derp q{x-view is deprecated and will be removed in v2. }
        . q{Use Yancy::Model or your database's CREATE VIEW instead}
        if $json_schema->{'x-view'};

    $json_schema->{ type } //= 'object';
    my $props = $json_schema->{properties};
    if ( $json_schema->{'x-view'} && !$props ) {
        my $real_name = $json_schema->{'x-view'}->{schema};
        my $real_schema = $self->model->schema( $real_name )
          // die qq{Could not find x-view schema "$real_name" for schema "$name"};
        $props = $real_schema->json_schema->{properties};
    }
    die qq{Schema "$name" has no properties. Does it exist?} if !$props;

    my $id_field = $self->id_field;
    my @id_fields = ref $id_field eq 'ARRAY' ? @$id_field : ( $id_field );
    # ; say "$name ID field: @id_fields";
    # ; use Data::Dumper;
    # ; say Dumper $props;

    for my $field ( @id_fields ) {
        if ( !$props->{ $field } ) {
            die sprintf "ID field missing in properties for schema '%s', field '%s'."
                . " Add x-id-field to configure the correct ID field name, or"
                . " add x-ignore to ignore this schema.",
                    $name, $field;
        }
    }
}

1;

__END__

=pod

=head1 NAME

Yancy::Model::Schema - Interface to a single schema

=head1 VERSION

version 1.087

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

=head2 json_schema

The JSON Schema for this schema.

=head1 METHODS

=head2 id_field

The ID field for this schema. Either a single string, or an arrayref of
strings (for composite keys).

=head2 build_item

Turn a hashref of row data into a L<Yancy::Model::Item> object using
L<Yancy::Model/find_class> to find the correct class.

=head2 validate

Validate an item. Returns a list of errors (if any).

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
