package Yancy::Backend::Dbic;
our $VERSION = '0.012';
# ABSTRACT: A backend for DBIx::Class schemas

#pod =head1 SYNOPSIS
#pod
#pod     # yancy.conf
#pod     {
#pod         backend => 'dbic://My::Schema/dbi:Pg:localhost',
#pod         collections => {
#pod             ResultSet => { ... },
#pod         },
#pod     }
#pod
#pod     # Plugin
#pod     use Mojolicious::Lite;
#pod     plugin Yancy => {
#pod         backend => 'dbic://My::Schema/dbi:Pg:localhost',
#pod         collections => {
#pod             ResultSet => { ... },
#pod         },
#pod     };
#pod
#pod =head1 DESCRIPTION
#pod
#pod This Yancy backend allows you to connect to a L<DBIx::Class> schema to
#pod manage the data inside.
#pod
#pod See L<Yancy::Backend> for the methods this backend has and their return
#pod values.
#pod
#pod =head2 Backend URL
#pod
#pod The URL for this backend takes the form C<< dbic://<schema_class>/<dbi_dsn> >>
#pod where C<schema_class> is the DBIx::Class schema module name and C<dbi_dsn> is
#pod the full L<DBI> data source name (DSN) used to connect to the database.
#pod
#pod =head2 Collections
#pod
#pod The collections for this backend are the names of the
#pod L<DBIx::Class::Row> classes in your schema, just as DBIx::Class allows
#pod in the C<< $schema->resultset >> method.
#pod
#pod So, if you have the following schema:
#pod
#pod     package My::Schema;
#pod     use base 'DBIx::Class::Schema';
#pod     __PACKAGE__->load_namespaces;
#pod
#pod     package My::Schema::Result::People;
#pod     __PACKAGE__->table( 'people' );
#pod     __PACKAGE__->add_columns( qw/ id name email / );
#pod
#pod     package My::Schema::Result::Business
#pod     __PACKAGE__->table( 'business' );
#pod     __PACKAGE__->add_columns( qw/ id name email / );
#pod
#pod You could map that schema to the following collections:
#pod
#pod     {
#pod         backend => 'dbic://My::Schema/dbi:SQLite:test.db',
#pod         collections => {
#pod             People => {
#pod                 properties => {
#pod                     id => {
#pod                         type => 'integer',
#pod                         readOnly => 1,
#pod                     },
#pod                     name => { type => 'string' },
#pod                     email => { type => 'string' },
#pod                 },
#pod             },
#pod             Business => {
#pod                 properties => {
#pod                     id => {
#pod                         type => 'integer',
#pod                         readOnly => 1,
#pod                     },
#pod                     name => { type => 'string' },
#pod                     email => { type => 'string' },
#pod                 },
#pod             },
#pod         },
#pod     }
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Yancy::Backend>, L<DBIx::Class>, L<Yancy>
#pod
#pod =cut

use Mojo::Base 'Mojo';
use Scalar::Util qw( looks_like_number );
use Mojo::Loader qw( load_class );

has collections => ;
has dbic =>;

sub new {
    my ( $class, $backend, $collections ) = @_;
    if ( !ref $backend ) {
        my ( $dbic_class, $dsn, $optstr ) = $backend =~ m{^[^:]+://([^/]+)/([^?]+)(?:\?(.+))?$};
        if ( my $e = load_class( $dbic_class ) ) {
            die ref $e ? "Could not load class $dbic_class: $e" : "Could not find class $dbic_class";
        }
        $backend = $dbic_class->connect( $dsn );
    }
    my %vars = (
        collections => $collections,
        dbic => $backend,
    );
    return $class->SUPER::new( %vars );
}

sub _rs {
    my ( $self, $coll, $params, $opt ) = @_;
    $params ||= {}; $opt ||= {};
    my $rs = $self->dbic->resultset( $coll )->search( $params, $opt );
    $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
    return $rs;
}

sub create {
    my ( $self, $coll, $params ) = @_;
    my $created = $self->dbic->resultset( $coll )->create( $params );
    return { $created->get_columns };
}

sub get {
    my ( $self, $coll, $id ) = @_;
    return $self->_rs( $coll )->find( $id );
}

sub list {
    my ( $self, $coll, $params, $opt ) = @_;
    $params ||= {}; $opt ||= {};
    my %rs_opt = (
        order_by => $opt->{order_by},
    );
    if ( $opt->{limit} ) {
        die "Limit must be number" if !looks_like_number $opt->{limit};
        $rs_opt{ rows } = $opt->{limit};
    }
    if ( $opt->{offset} ) {
        die "Offset must be number" if !looks_like_number $opt->{offset};
        $rs_opt{ offset } = $opt->{offset};
    }
    my $rs = $self->_rs( $coll, $params, \%rs_opt );
    return { rows => [ $rs->all ], total => $self->_rs( $coll, $params )->count };
}

sub set {
    my ( $self, $coll, $id, $params ) = @_;
    return $self->dbic->resultset( $coll )->find( $id )->set_columns( $params )->update;
}

sub delete {
    my ( $self, $coll, $id ) = @_;
    $self->dbic->resultset( $coll )->find( $id )->delete;
}

sub read_schema {
    my ( $self ) = @_;
    my %schema;

    my @tables = $self->dbic->sources;
    for my $table ( @tables ) {
        # ; say "Got table $table";
        my $source = $self->dbic->source( $table );
        my @columns = $source->columns;
        for my $column ( @columns ) {
            my $c = $source->column_info( $column );
            # ; use Data::Dumper;
            # ; say Dumper $c;
            my $is_auto = $c->{is_auto_increment};
            $schema{ $table }{ properties }{ $column } = {
                $self->_map_type( $c ),
            };
            if ( !$c->{is_nullable} && !$is_auto && !$c->{default_value} ) {
                push @{ $schema{ $table }{ required } }, $column;
            }
        }
        my @keys = $source->primary_columns;
        if ( $keys[0] ne 'id' ) {
            $schema{ $table }{ 'x-id-field' } = $keys[0];
        }
    }

    return \%schema;
}

sub _map_type {
    my ( $self, $column ) = @_;
    my $db_type = $column->{data_type} // 'varchar';

    my @extra;
    if ( $column->{extra}{list} ) {
        @extra = ( enum => $column->{extra}{list} );
    }

    if ( $db_type =~ /^(?:text|varchar)/i ) {
        return ( type => 'string', @extra );
    }
    elsif ( $db_type =~ /^(?:int|integer|smallint|bigint|tinyint|rowid)/i ) {
        return ( type => 'integer', @extra );
    }
    elsif ( $db_type =~ /^(?:double|float|money|numeric|real)/i ) {
        return ( type => 'number', @extra );
    }
    elsif ( $db_type =~ /^(?:timestamp)/i ) {
        return ( type => 'string', format => 'date-time', @extra );
    }
    # Default to string
    return ( type => 'string', @extra );
}

1;

__END__

=pod

=head1 NAME

Yancy::Backend::Dbic - A backend for DBIx::Class schemas

=head1 VERSION

version 0.012

=head1 SYNOPSIS

    # yancy.conf
    {
        backend => 'dbic://My::Schema/dbi:Pg:localhost',
        collections => {
            ResultSet => { ... },
        },
    }

    # Plugin
    use Mojolicious::Lite;
    plugin Yancy => {
        backend => 'dbic://My::Schema/dbi:Pg:localhost',
        collections => {
            ResultSet => { ... },
        },
    };

=head1 DESCRIPTION

This Yancy backend allows you to connect to a L<DBIx::Class> schema to
manage the data inside.

See L<Yancy::Backend> for the methods this backend has and their return
values.

=head2 Backend URL

The URL for this backend takes the form C<< dbic://<schema_class>/<dbi_dsn> >>
where C<schema_class> is the DBIx::Class schema module name and C<dbi_dsn> is
the full L<DBI> data source name (DSN) used to connect to the database.

=head2 Collections

The collections for this backend are the names of the
L<DBIx::Class::Row> classes in your schema, just as DBIx::Class allows
in the C<< $schema->resultset >> method.

So, if you have the following schema:

    package My::Schema;
    use base 'DBIx::Class::Schema';
    __PACKAGE__->load_namespaces;

    package My::Schema::Result::People;
    __PACKAGE__->table( 'people' );
    __PACKAGE__->add_columns( qw/ id name email / );

    package My::Schema::Result::Business
    __PACKAGE__->table( 'business' );
    __PACKAGE__->add_columns( qw/ id name email / );

You could map that schema to the following collections:

    {
        backend => 'dbic://My::Schema/dbi:SQLite:test.db',
        collections => {
            People => {
                properties => {
                    id => {
                        type => 'integer',
                        readOnly => 1,
                    },
                    name => { type => 'string' },
                    email => { type => 'string' },
                },
            },
            Business => {
                properties => {
                    id => {
                        type => 'integer',
                        readOnly => 1,
                    },
                    name => { type => 'string' },
                    email => { type => 'string' },
                },
            },
        },
    }

=head1 SEE ALSO

L<Yancy::Backend>, L<DBIx::Class>, L<Yancy>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
