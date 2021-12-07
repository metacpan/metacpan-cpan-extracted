package Yancy::Model;
our $VERSION = '1.085';
# ABSTRACT: Model layer for Yancy apps

#pod =head1 SYNOPSIS
#pod
#pod     # XXX: Allow using backend strings
#pod     my $model = Yancy::Model->new( backend => $backend );
#pod
#pod     my $schema = $model->schema( 'foo' );
#pod
#pod     my $id = $schema->create( $data );
#pod     my $count = $schema->delete( $id );
#pod     my $count = $schema->delete( $where );
#pod     my $count = $schema->set( $id, $data );
#pod     my $count = $schema->set( $where, $data );
#pod
#pod     my $item = $schema->get( $id );
#pod     my ( $items, $total ) = $schema->list( $where, $opts );
#pod     for my $item ( @$items ) {
#pod     }
#pod
#pod     my $success = $row->set( $data );
#pod     my $success = $row->delete();
#pod     my $data = $row->to_hash;
#pod
#pod =head1 DESCRIPTION
#pod
#pod B<NOTE>: This module is experimental and its API may change before
#pod Yancy v2!
#pod
#pod L<Yancy::Model> is a framework for your business logic. L<Yancy::Model>
#pod contains a number of schemas, L<Yancy::Model::Schema> objects. Each
#pod schema contains a number of items, L<Yancy::Model::Item> objects.
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
use Scalar::Util qw( blessed );
use Mojo::Util qw( camelize );
use Mojo::Loader qw( load_class );
use Mojo::Log;
use Yancy::Util qw( derp );
use Storable qw( dclone );

#pod =attr backend
#pod
#pod A L<Yancy::Backend> object.
#pod
#pod =cut

has backend => sub { die "backend is required" };

#pod =attr namespaces
#pod
#pod An array of namespaces to find Schema and Item classes. Defaults to C<[ 'Yancy::Model' ]>.
#pod
#pod =cut

has namespaces => sub { [qw( Yancy::Model )] };

#pod =attr log
#pod
#pod A L<Mojo::Log> object to log messages to.
#pod
#pod =cut

has log => sub { Mojo::Log->new };

has _schema => sub { {} };
has _config_schema => sub { {} };
has _auto_read => 1;

#pod =method new
#pod
#pod Create a new model with the given backend. In addition to any L</ATTRIBUTES>, these
#pod options may be given:
#pod
#pod =over
#pod
#pod =item schema
#pod
#pod A JSON schema configuration. By default, the information from
#pod L</read_schema> will be merged with this information. See
#pod L<Yancy::Guides::Schema/Documenting Your Schema> for more information.
#pod
#pod =item read_schema
#pod
#pod Read the backend database information to build the schema information.
#pod Enabled by default. Set to a false value to disable.
#pod
#pod =back
#pod
#pod =cut

sub new {
    my ( $class, @args ) = @_;
    my %args = @args == 1 ? %{ $args[0] } : @args;
    my $conf = $args{_config_schema} = delete $args{schema} if $args{schema};
    my $read = exists $args{read_schema} ? delete $args{read_schema} : 1;
    $args{ _auto_read } = $read;
    my $self = $class->SUPER::new(\%args);
    if ( $read ) {
        $self->read_schema;
    }
    elsif ( my @names = grep { delete $conf->{$_}{read_schema} } keys %$conf ) {
        $self->read_schema( @names );
    }
    return $self;
}

#pod =method find_class
#pod
#pod Find a class of the given type for an object of the given name. The name is run
#pod through L<Mojo::Util/camelize> before lookups.
#pod
#pod     unshift @{ $model->namespaces }, 'MyApp';
#pod     # MyApp::Schema::User
#pod     $class = $model->find_class( Schema => 'user' );
#pod     # MyApp::Item::UserProfile
#pod     $class = $model->find_class( Item => 'user_profile' );
#pod
#pod If a specific class cannot be found, a generic class for the type is found instead.
#pod
#pod     # MyApp::Schema
#pod     $class = $model->find_class( Schema => 'not_found' );
#pod     # MyApp::Item
#pod     $class = $model->find_class( Item => 'not_found' );
#pod
#pod =cut

sub find_class {
    my ( $self, $type, $name ) = @_;
    # First, a specific class for this named type.
    for my $namespace ( @{ $self->namespaces } ) {
        my $class = "${namespace}::${type}::" . camelize( $name );
        if ( my $e = load_class $class ) {
            if ( ref $e ) {
                die "Could not load $class: $e";
            }
            # Not found, try the next one
            next;
        }
        # No error, so this is the class we want
        return $class;
    }

    # Finally, try to find a generic type class
    for my $namespace ( @{ $self->namespaces } ) {
        my $class = "${namespace}::${type}";
        if ( my $e = load_class $class ) {
            if ( ref $e ) {
                die "Could not load $class: $e";
            }
            # Not found, try the next one
            next;
        }
        # No error, so this is the class we want
        return $class;
    }

    die "Could not find class for type $type or name $name";
}

#pod =method read_schema
#pod
#pod Read the schema from the L</backend> and prepare schema objects using L</find_class>
#pod to find the correct classes.
#pod
#pod =cut

sub read_schema {
    my ( $self, @names ) = @_;
    my $conf_schema = $self->_config_schema;
    my $read_schema;
    if ( @names ) {
        $read_schema = { map { $_ => $self->backend->read_schema( $_ ) } @names };
    }
    else {
        $read_schema = $self->backend->read_schema( @names );
        my %all_schemas = map { $_ => 1 } keys %$conf_schema, keys %$read_schema;
        @names = keys %all_schemas;
    }

    # Make all concrete schemas first, then any views.
    # XXX: x-view is deprecated. Remove the sort in v2.
    @names = sort { !!$conf_schema->{$a}{'x-view'} <=> !!$conf_schema->{$b}{'x-view'} } @names;

    for my $name ( @names ) {
        # ; use Data::Dumper;
        # ; say "Creating schema $name";
        # ; say "Has view " . Dumper $conf_schema->{$name}{'x-view'} if $conf_schema->{$name}{'x-view'};
        my $full_schema = _merge_schema( $conf_schema->{ $name } // {}, $read_schema->{ $name } // {} );
        if ( $full_schema->{'x-ignore'} ) {
            # Remember we're ignoring this schema
            $conf_schema->{ $name }{ 'x-ignore' } = 1;
            next;
        }
        $self->schema( $name, $full_schema );
    }
    return $self;
}

#pod =method schema
#pod
#pod Get or set a schema object.
#pod
#pod     $model = $model->schema( user => MyApp::Model::User->new );
#pod     $schema = $model->schema( 'user' );
#pod
#pod =cut

sub schema {
    my ( $self, $name, $data ) = @_;
    if ( !$data ) {
        if ( my $schema = $self->_schema->{ $name } ) {
            return $schema;
        }
        # Create a default schema
        my $conf = $self->_config_schema->{ $name };
        die "Schema $name is ignored" if $conf->{'x-ignore'};
        $self->schema( $name, $conf );
        return $self->_schema->{ $name };
    }
    if ( !blessed $data || !$data->isa( 'Yancy::Model::Schema' ) ) {
        my $class = $self->find_class( Schema => $name );
        $data = $class->new( model => $self, name => $name, json_schema => $data );
    }
    $self->_schema->{$name} = $data;
    return $self;
}

#pod =method json_schema
#pod
#pod Get the JSON Schema for every attached schema.
#pod
#pod =cut

sub json_schema {
  my ( $self, @names ) = @_;
  if ( !@names ) {
    @names = $self->schema_names;
  }
  return {
    map { $_ => $self->schema( $_ )->json_schema } @names
  };
}

#pod =method schema_names
#pod
#pod Get a list of all the schema names.
#pod
#pod =cut

sub schema_names {
    my ( $self ) = @_;
    my $conf = $self->_config_schema;
    my %all_schemas = map { $_ => 1 } grep !$conf->{$_}{'x-ignore'}, keys %$conf, keys %{ $self->_schema };
    return keys %all_schemas;
}

# _merge_schema( $keep, $merge );
#
# Merge the two schemas, returning the result.
sub _merge_schema {
    my ( $left, $right ) = @_;
    # ; use Data::Dumper;
    # ; say "Split schema " . Dumper( $left ) . Dumper( $right );
    my $keep = dclone $left;
    if ( my $right_props = $right->{properties} ) {
        my $keep_props = $keep->{properties} ||= {};
        for my $p ( keys %{ $right_props } ) {
            my $keep_prop = $keep_props->{ $p } ||= {};
            my $right_prop = $right_props->{ $p };
            for my $k ( keys %$right_prop ) {
                $keep_prop->{ $k } ||= $right_prop->{ $k };
            }
        }
    }
    for my $k ( keys %$right ) {
        next if $k eq 'properties';
        $keep->{ $k } ||= $right->{ $k };
    }
    # ; use Data::Dumper;
    # ; say "Merged schema " . Dumper $keep;
    return $keep;
}

1;

__END__

=pod

=head1 NAME

Yancy::Model - Model layer for Yancy apps

=head1 VERSION

version 1.085

=head1 SYNOPSIS

    # XXX: Allow using backend strings
    my $model = Yancy::Model->new( backend => $backend );

    my $schema = $model->schema( 'foo' );

    my $id = $schema->create( $data );
    my $count = $schema->delete( $id );
    my $count = $schema->delete( $where );
    my $count = $schema->set( $id, $data );
    my $count = $schema->set( $where, $data );

    my $item = $schema->get( $id );
    my ( $items, $total ) = $schema->list( $where, $opts );
    for my $item ( @$items ) {
    }

    my $success = $row->set( $data );
    my $success = $row->delete();
    my $data = $row->to_hash;

=head1 DESCRIPTION

B<NOTE>: This module is experimental and its API may change before
Yancy v2!

L<Yancy::Model> is a framework for your business logic. L<Yancy::Model>
contains a number of schemas, L<Yancy::Model::Schema> objects. Each
schema contains a number of items, L<Yancy::Model::Item> objects.

For information on how to extend this module to add your own schema
and item methods, see L<Yancy::Guides::Model>.

=head1 ATTRIBUTES

=head2 backend

A L<Yancy::Backend> object.

=head2 namespaces

An array of namespaces to find Schema and Item classes. Defaults to C<[ 'Yancy::Model' ]>.

=head2 log

A L<Mojo::Log> object to log messages to.

=head1 METHODS

=head2 new

Create a new model with the given backend. In addition to any L</ATTRIBUTES>, these
options may be given:

=over

=item schema

A JSON schema configuration. By default, the information from
L</read_schema> will be merged with this information. See
L<Yancy::Guides::Schema/Documenting Your Schema> for more information.

=item read_schema

Read the backend database information to build the schema information.
Enabled by default. Set to a false value to disable.

=back

=head2 find_class

Find a class of the given type for an object of the given name. The name is run
through L<Mojo::Util/camelize> before lookups.

    unshift @{ $model->namespaces }, 'MyApp';
    # MyApp::Schema::User
    $class = $model->find_class( Schema => 'user' );
    # MyApp::Item::UserProfile
    $class = $model->find_class( Item => 'user_profile' );

If a specific class cannot be found, a generic class for the type is found instead.

    # MyApp::Schema
    $class = $model->find_class( Schema => 'not_found' );
    # MyApp::Item
    $class = $model->find_class( Item => 'not_found' );

=head2 read_schema

Read the schema from the L</backend> and prepare schema objects using L</find_class>
to find the correct classes.

=head2 schema

Get or set a schema object.

    $model = $model->schema( user => MyApp::Model::User->new );
    $schema = $model->schema( 'user' );

=head2 json_schema

Get the JSON Schema for every attached schema.

=head2 schema_names

Get a list of all the schema names.

=head1 SEE ALSO

L<Yancy::Guides::Model>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
