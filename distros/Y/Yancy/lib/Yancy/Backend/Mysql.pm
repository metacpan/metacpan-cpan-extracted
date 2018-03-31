package Yancy::Backend::Mysql;
our $VERSION = '1.003';
# ABSTRACT: A backend for MySQL using Mojo::mysql

#pod =head1 SYNOPSIS
#pod
#pod     ### URL string
#pod     use Mojolicious::Lite;
#pod     plugin Yancy => {
#pod         backend => 'mysql:///mydb',
#pod         read_schema => 1,
#pod     };
#pod
#pod     ### Mojo::mysql object
#pod     use Mojolicious::Lite;
#pod     use Mojo::mysql;
#pod     plugin Yancy => {
#pod         backend => { Mysql => Mojo::mysql->new( 'mysql:///mydb' ) },
#pod         read_schema => 1,
#pod     };
#pod
#pod =head1 DESCRIPTION
#pod
#pod This Yancy backend allows you to connect to a MySQL database to manage
#pod the data inside. This backend uses L<Mojo::mysql> to connect to MySQL.
#pod
#pod See L<Yancy::Backend> for the methods this backend has and their return
#pod values.
#pod
#pod =head2 Backend URL
#pod
#pod The URL for this backend takes the form C<<
#pod mysql://<user>:<pass>@<host>:<port>/<db> >>.
#pod
#pod Some examples:
#pod
#pod     # Just a DB
#pod     mysql:///mydb
#pod
#pod     # User+DB (server on localhost:3306)
#pod     mysql://user@/mydb
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
#pod         id INTEGER AUTO_INCREMENT PRIMARY KEY,
#pod         name VARCHAR(255) NOT NULL,
#pod         email VARCHAR(255) NOT NULL
#pod     );
#pod     CREATE TABLE business (
#pod         id INTEGER AUTO_INCREMENT PRIMARY KEY,
#pod         name VARCHAR(255) NOT NULL,
#pod         email VARCHAR(255) NULL
#pod     );
#pod
#pod You could map that schema to the following collections:
#pod
#pod     {
#pod         backend => 'mysql://user@/mydb',
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
#pod L<Mojo::mysql>, L<Yancy>
#pod
#pod =cut

use Mojo::Base '-base';
use Scalar::Util qw( looks_like_number );
BEGIN {
    eval { require Mojo::mysql; Mojo::mysql->VERSION( 1 ); 1 }
        or die "Could not load Mysql backend: Mojo::mysql version 1 or higher required\n";
}

has mysql =>;
has collections =>;

sub new {
    my ( $class, $backend, $collections ) = @_;
    if ( !ref $backend ) {
        my ( $connect ) = $backend =~ m{^[^:]+://(.+)$};
        $backend = Mojo::mysql->new( "mysql://$connect" );
    }
    my %vars = (
        mysql => $backend,
        collections => $collections,
    );
    return $class->SUPER::new( %vars );
}

sub create {
    my ( $self, $coll, $params ) = @_;
    my $id_field = $self->collections->{ $coll }{ 'x-id-field' } || 'id';
    my $id = $self->mysql->db->insert( $coll, $params )->last_insert_id;
    # Assume the id field is correct in case we're using a different
    # unique ID (not the auto-increment column).
    return $params->{ $id_field } || $id;
}

sub get {
    my ( $self, $coll, $id ) = @_;
    my $id_field = $self->collections->{ $coll }{ 'x-id-field' } || 'id';
    return $self->mysql->db->select( $coll, undef, { $id_field => $id } )->hash;
}

sub list {
    my ( $self, $coll, $params, $opt ) = @_;
    $params ||= {}; $opt ||= {};
    my $mysql = $self->mysql;
    my ( $query, @params ) = $mysql->abstract->select( $coll, undef, $params, $opt->{order_by} );
    my ( $total_query, @total_params ) = $mysql->abstract->select( $coll, [ \'COUNT(*) as total' ], $params );
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
        items => $mysql->db->query( $query, @params )->hashes,
        total => $mysql->db->query( $total_query, @total_params )->hash->{total},
    };
}

sub set {
    my ( $self, $coll, $id, $params ) = @_;
    my $id_field = $self->collections->{ $coll }{ 'x-id-field' } || 'id';
    return !!$self->mysql->db->update( $coll, $params, { $id_field => $id } )->rows;
}

sub delete {
    my ( $self, $coll, $id ) = @_;
    my $id_field = $self->collections->{ $coll }{ 'x-id-field' } || 'id';
    return !!$self->mysql->db->delete( $coll, { $id_field => $id } )->rows;
}

sub read_schema {
    my ( $self ) = @_;
    my $database = $self->mysql->db->query( 'SELECT DATABASE()' )->array->[0];

    my %schema;
    my $tables_q = <<ENDQ;
SELECT * FROM INFORMATION_SCHEMA.TABLES
WHERE table_schema=?
ENDQ

    my $key_q = <<ENDQ;
SELECT * FROM information_schema.table_constraints as tc
JOIN information_schema.key_column_usage AS ccu USING ( table_name, table_schema )
WHERE tc.table_schema=? AND tc.table_name=? AND ( constraint_type = 'PRIMARY KEY' OR constraint_type = 'UNIQUE' )
    AND tc.table_schema NOT IN ('information_schema','performance_schema','mysql','sys')
ENDQ

    my @tables = @{ $self->mysql->db->query( $tables_q, $database )->hashes };
    for my $t ( @tables ) {
        my $table = $t->{TABLE_NAME};
        # ; say "Got table $table";
        my @keys = @{ $self->mysql->db->query( $key_q, $database, $table )->hashes };
        # ; say "Got keys";
        # ; use Data::Dumper;
        # ; say Dumper \@keys;
        if ( @keys && $keys[0]{COLUMN_NAME} ne 'id' ) {
            $schema{ $table }{ 'x-id-field' } = $keys[0]{COLUMN_NAME};
        }
    }

    my $columns_q = <<ENDQ;
SELECT * FROM information_schema.columns
WHERE table_schema=?
ENDQ

    my @columns = @{ $self->mysql->db->query( $columns_q, $database )->hashes };
    for my $c ( @columns ) {
        my $table = $c->{TABLE_NAME};
        my $column = $c->{COLUMN_NAME};
        # ; use Data::Dumper;
        # ; say Dumper $c;
        $schema{ $table }{ properties }{ $column } = {
            $self->_map_type( $c ),
            'x-order' => $c->{ORDINAL_POSITION},
        };
        # Auto_increment columns are allowed to be null
        if ( $c->{IS_NULLABLE} eq 'NO' && !$c->{COLUMN_DEFAULT} && $c->{EXTRA} !~ /auto_increment/ ) {
            push @{ $schema{ $table }{ required } }, $column;
        }
    }

    return \%schema;
}

sub _map_type {
    my ( $self, $column ) = @_;
    my %conf;
    my $db_type = $column->{DATA_TYPE};
    if ( $db_type =~ /^(?:character|text|varchar)/i ) {
        %conf = ( type => 'string' );
    }
    elsif ( $db_type =~ /^(?:int|integer|smallint|bigint|tinyint)/i ) {
        %conf = ( type => 'integer' );
    }
    elsif ( $db_type =~ /^(?:double|float|money|numeric|real)/i ) {
        %conf = ( type => 'number' );
    }
    elsif ( $db_type =~ /^(?:timestamp|datetime)/i ) {
        %conf = ( type => 'string', format => 'date-time' );
    }
    elsif ( $db_type =~ /^(?:enum)/i ) {
        my @values = $column->{COLUMN_TYPE} =~ /'([^']+)'/g;
        %conf = ( type => 'string', enum => \@values );
    }
    else {
        # Default to string
        %conf = ( type => 'string' );
    }

    if ( $column->{IS_NULLABLE} eq 'YES' ) {
        $conf{ type } = [ $conf{ type }, 'null' ];
    }

    return %conf;
}

1;

__END__

=pod

=head1 NAME

Yancy::Backend::Mysql - A backend for MySQL using Mojo::mysql

=head1 VERSION

version 1.003

=head1 SYNOPSIS

    ### URL string
    use Mojolicious::Lite;
    plugin Yancy => {
        backend => 'mysql:///mydb',
        read_schema => 1,
    };

    ### Mojo::mysql object
    use Mojolicious::Lite;
    use Mojo::mysql;
    plugin Yancy => {
        backend => { Mysql => Mojo::mysql->new( 'mysql:///mydb' ) },
        read_schema => 1,
    };

=head1 DESCRIPTION

This Yancy backend allows you to connect to a MySQL database to manage
the data inside. This backend uses L<Mojo::mysql> to connect to MySQL.

See L<Yancy::Backend> for the methods this backend has and their return
values.

=head2 Backend URL

The URL for this backend takes the form C<<
mysql://<user>:<pass>@<host>:<port>/<db> >>.

Some examples:

    # Just a DB
    mysql:///mydb

    # User+DB (server on localhost:3306)
    mysql://user@/mydb

    # User+Pass Host and DB
    mysql://user:pass@example.com/mydb

=head2 Collections

The collections for this backend are the names of the tables in the
database.

So, if you have the following schema:

    CREATE TABLE people (
        id INTEGER AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        email VARCHAR(255) NOT NULL
    );
    CREATE TABLE business (
        id INTEGER AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        email VARCHAR(255) NULL
    );

You could map that schema to the following collections:

    {
        backend => 'mysql://user@/mydb',
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

L<Mojo::mysql>, L<Yancy>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
