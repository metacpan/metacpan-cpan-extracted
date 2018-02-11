package Yancy::Backend::Pg;
our $VERSION = '0.014';
# ABSTRACT: A backend for Postgres using Mojo::Pg

#pod =head1 SYNOPSIS
#pod
#pod     # yancy.conf
#pod     {
#pod         backend => 'pg://user:pass@localhost/mydb',
#pod         collections => {
#pod             table_name => { ... },
#pod         },
#pod     }
#pod
#pod     # Plugin
#pod     use Mojolicious::Lite;
#pod     plugin Yancy => {
#pod         backend => 'pg://user:pass@localhost/mydb',
#pod         collections => {
#pod             table_name => { ... },
#pod         },
#pod     };
#pod
#pod =head1 DESCRIPTION
#pod
#pod This Yancy backend allows you to connect to a Postgres database to manage
#pod the data inside. This backend uses L<Mojo::Pg> to connect to Postgres.
#pod
#pod See L<Yancy::Backend> for the methods this backend has and their return
#pod values.
#pod
#pod =head2 Backend URL
#pod
#pod The URL for this backend takes the form C<<
#pod pg://<user>:<pass>@<host>:<port>/<db> >>.
#pod
#pod Some examples:
#pod
#pod     # Just a DB
#pod     pg:///mydb
#pod
#pod     # User+DB (server on localhost:5432)
#pod     pg://user@/mydb
#pod
#pod     # User+Pass Host and DB
#pod     mysql://user:pass@example.com/mydb
#pod
#pod =head2 Collections
#pod
#pod The collections for this backend are the names of the tables in the
#pod database.
#pod
#pod So, if you have the following schema:
#pod
#pod     CREATE TABLE people (
#pod         id SERIAL,
#pod         name VARCHAR NOT NULL,
#pod         email VARCHAR NOT NULL
#pod     );
#pod     CREATE TABLE business (
#pod         id SERIAL,
#pod         name VARCHAR NOT NULL,
#pod         email VARCHAR NULL
#pod     );
#pod
#pod You could map that schema to the following collections:
#pod
#pod     {
#pod         backend => 'pg://user@/mydb',
#pod         collections => {
#pod             People => {
#pod                 required => [ 'name', 'email' ],
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
#pod                 required => [ 'name' ],
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
#pod L<Mojo::Pg>, L<Yancy>
#pod
#pod =cut

use Mojo::Base 'Mojo';
use Scalar::Util qw( looks_like_number );
BEGIN {
    eval { require Mojo::Pg; Mojo::Pg->VERSION( 3 ); 1 }
        or die "Could not load Pg backend: Mojo::Pg version 3 or higher required\n";
}

has pg =>;
has collections =>;

sub new {
    my ( $class, $backend, $collections ) = @_;
    if ( !ref $backend ) {
        my ( $connect ) = $backend =~ m{^[^:]+://(.+)$};
        $backend = Mojo::Pg->new( "postgresql://$connect" );
    }
    my %vars = (
        pg => $backend,
        collections => $collections,
    );
    return $class->SUPER::new( %vars );
}

sub create {
    my ( $self, $coll, $params ) = @_;
    return $self->pg->db->insert( $coll, $params, { returning => '*' } )->hash;
}

sub get {
    my ( $self, $coll, $id ) = @_;
    my $id_field = $self->collections->{ $coll }{ 'x-id-field' } || 'id';
    return $self->pg->db->select( $coll, undef, { $id_field => $id } )->hash;
}

sub list {
    my ( $self, $coll, $params, $opt ) = @_;
    $params ||= {}; $opt ||= {};
    my $pg = $self->pg;
    my ( $query, @params ) = $pg->abstract->select( $coll, undef, $params, $opt->{order_by} );
    my ( $total_query, @total_params ) = $pg->abstract->select( $coll, [ \'COUNT(*) as total' ], $params );
    if ( scalar grep defined, @{ $opt }{qw( limit offset )} ) {
        die "Limit must be number" if $opt->{limit} && !looks_like_number $opt->{limit};
        $query .= ' LIMIT ' . ( $opt->{limit} // 2**32 );
        if ( $opt->{offset} ) {
            die "Offset must be number" if !looks_like_number $opt->{offset};
            $query .= ' OFFSET ' . $opt->{offset};
        }
    }
    #; say $query;
    return {
        rows => $pg->db->query( $query, @params )->hashes,
        total => $pg->db->query( $total_query, @total_params )->hash->{total},
    };

}

sub set {
    my ( $self, $coll, $id, $params ) = @_;
    my $id_field = $self->collections->{ $coll }{ 'x-id-field' } || 'id';
    return $self->pg->db->update( $coll, $params, { $id_field => $id } );
}

sub delete {
    my ( $self, $coll, $id ) = @_;
    my $id_field = $self->collections->{ $coll }{ 'x-id-field' } || 'id';
    return $self->pg->db->delete( $coll, { $id_field => $id } );
}

sub read_schema {
    my ( $self ) = @_;
    my %schema;
    my $tables_q = <<ENDQ;
SELECT * FROM information_schema.tables
WHERE table_schema NOT IN ('information_schema','pg_catalog')
ENDQ

    my $key_q = <<ENDQ;
SELECT * FROM information_schema.table_constraints as tc
JOIN information_schema.constraint_column_usage AS ccu USING (constraint_schema, constraint_name)
WHERE tc.table_name=? AND constraint_type = 'PRIMARY KEY'
ENDQ

    my @tables = @{ $self->pg->db->query( $tables_q )->hashes };
    for my $t ( @tables ) {
        my $table = $t->{table_name};
        my @keys = @{ $self->pg->db->query( $key_q, $table )->hashes };
        # ; use Data::Dumper;
        # ; say Dumper \@keys;
        if ( @keys && $keys[0]{column_name} ne 'id' ) {
            $schema{ $table }{ 'x-id-field' } = $keys[0]{column_name};
        }
    }

    my $columns_q = <<ENDQ;
SELECT * FROM information_schema.columns
WHERE table_schema NOT IN ('information_schema','pg_catalog')
ENDQ

    my @columns = @{ $self->pg->db->query( $columns_q )->hashes };
    for my $c ( @columns ) {
        my $table = $c->{table_name};
        my $column = $c->{column_name};
        #; use Data::Dumper;
        #; say Dumper $c;
        $schema{ $table }{ properties }{ $column } = {
            $self->_map_type( $c ),
        };
        if ( $c->{is_nullable} eq 'NO' && !$c->{column_default} ) {
            push @{ $schema{ $table }{ required } }, $column;
        }
        # The `oid` field is also a primary key, and may be the main key
        # if no other key exists
        if ( $c->{data_type} eq 'oid' && $column ne 'id' ) {
            $schema{ $table }{ 'x-id-field' } ||= $column;
        }
    }

    return \%schema;
}

sub _map_type {
    my ( $self, $column ) = @_;
    my $db_type = $column->{data_type};
    if ( $db_type =~ /^(?:character|text)/ ) {
        return ( type => 'string' );
    }
    elsif ( $db_type =~ /^(?:bool)/ ) {
        return ( type => 'boolean' );
    }
    elsif ( $db_type =~ /^(?:oid|integer|smallint|bigint)/ ) {
        return ( type => 'integer' );
    }
    elsif ( $db_type =~ /^(?:double|float|money|numeric|real)/ ) {
        return ( type => 'number' );
    }
    elsif ( $db_type =~ /^(?:timestamp)/ ) {
        return ( type => 'string', format => 'date-time' );
    }
    elsif ( $db_type eq 'USER-DEFINED' ) {
        my $vals = $self->pg->db->query(
            sprintf 'SELECT unnest(enum_range(NULL::%s))::text', $column->{udt_name},
        );
        return ( type => 'string', enum => [ $vals->arrays->flatten->each ] );
    }
    # Default to string
    return ( type => 'string' );
}

1;

__END__

=pod

=head1 NAME

Yancy::Backend::Pg - A backend for Postgres using Mojo::Pg

=head1 VERSION

version 0.014

=head1 SYNOPSIS

    # yancy.conf
    {
        backend => 'pg://user:pass@localhost/mydb',
        collections => {
            table_name => { ... },
        },
    }

    # Plugin
    use Mojolicious::Lite;
    plugin Yancy => {
        backend => 'pg://user:pass@localhost/mydb',
        collections => {
            table_name => { ... },
        },
    };

=head1 DESCRIPTION

This Yancy backend allows you to connect to a Postgres database to manage
the data inside. This backend uses L<Mojo::Pg> to connect to Postgres.

See L<Yancy::Backend> for the methods this backend has and their return
values.

=head2 Backend URL

The URL for this backend takes the form C<<
pg://<user>:<pass>@<host>:<port>/<db> >>.

Some examples:

    # Just a DB
    pg:///mydb

    # User+DB (server on localhost:5432)
    pg://user@/mydb

    # User+Pass Host and DB
    mysql://user:pass@example.com/mydb

=head2 Collections

The collections for this backend are the names of the tables in the
database.

So, if you have the following schema:

    CREATE TABLE people (
        id SERIAL,
        name VARCHAR NOT NULL,
        email VARCHAR NOT NULL
    );
    CREATE TABLE business (
        id SERIAL,
        name VARCHAR NOT NULL,
        email VARCHAR NULL
    );

You could map that schema to the following collections:

    {
        backend => 'pg://user@/mydb',
        collections => {
            People => {
                required => [ 'name', 'email' ],
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
                required => [ 'name' ],
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

L<Mojo::Pg>, L<Yancy>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
