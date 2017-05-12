package XAS::Model::DBM;

our $VERSION = '0.01';

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  mixins  => 'create find search search_like find_or_create update_or_create
              update_or_new count populate read_record create_record 
              delete_record update_record load_records delete_records',
;

# ---------------------------------------------------------------------
# Database usability mixin functions
# ---------------------------------------------------------------------

sub create {
    my $class  = shift;
    my $schema = shift;

    return $schema->resultset( $class->table_name )->create( @_ );

}

sub find {
    my $class  = shift;
    my $schema = shift;

    return $schema->resultset( $class->table_name )->find( @_ );

}

sub search {
    my $class  = shift;
    my $schema = shift;

    return $schema->resultset( $class->table_name )->search( @_ );

}

sub search_like {
    my $class  = shift;
    my $schema = shift;

    return $schema->resultset( $class->table_name )->search_like( @_ );

}

sub find_or_create {
    my $class  = shift;
    my $schema = shift;

    return $schema->resultset( $class->table_name )->find_or_create( @_ );

}

sub update_or_create {
    my $class  = shift;
    my $schema = shift;

    return $schema->resultset( $class->table_name )->update_or_create( @_ );

}

sub update_or_new {
    my $class  = shift;
    my $schema = shift;

    return $schema->resultset( $class->table_name )->update_or_new( @_ );

}

sub count {
    my $class  = shift;
    my $schema = shift;

    return $schema->resultset( $class->table_name )->count( @_ );

}

sub populate {
    my $class  = shift;
    my $schema = shift;

    return $schema->resultset( $class->table_name )->populate( @_ );

}

sub load_records {
    my $class    = shift;
    my $schema   = shift;

    my @datum;
    my @columns = $class->columns;

    # find the records

    if (my $rs = $class->search($schema, @_ )) {

        # transfer the data

        while (my $row = $rs->next) {

            my $data;

            foreach my $column (@columns) {

                my $info = $class->column_info($column);

                if ($info->{data_type} =~ m/^(datetime | timestamp)/x ) {

                    my $dt = '';

                    if ($row->$column) {

                        $dt = sprintf("%s", $row->$column);
                        $dt =~ s/T/ /;

                    }

                    $data->{$column} = $dt;

                } else {

                    $data->{$column} = $row->$column;

                }

            }

            push(@datum, $data);

        }

    }

    return \@datum;

}

sub delete_records {
    my $class  = shift;
    my $schema = shift;

    $schema->txn_do(sub { 

        $schema->resultset( $class->table_name )->search( @_ )->delete_all;

    });

}

sub read_record {
    my $class    = shift;
    my $schema   = shift;

    my $data = undef;
    my @columns = $class->columns;

    # find the record

    if (my $row = $class->find($schema, @_ )) {

        # transfer the data

        foreach my $column (@columns) {

            my $info = $class->column_info($column);

            if ($info->{data_type} =~ m/^(datetime | timestamp)/x ) {

                my $dt = '';

                if ($row->$column) {

                    $dt = sprintf("%s", $row->$column);
                    $dt =~ s/T/ /;

                }

                $data->{$column} = $dt;

            } else {

                $data->{$column} = $row->$column;

            }

        }

    }

    return $data;

}

sub create_record {
    my $class  = shift;
    my $schema = shift;
    my $record = shift;

    my $rec = undef;
    my $data = undef;
    my @columns = $class->columns;

    # transfer and filter the data

    $schema->txn_do(sub {

        foreach my $column (@columns) {

            my $info = $class->column_info($column);

            if (defined($record->{$column})) {

                next if ((defined($info->{auto_nextval}) ||
                         (defined($info->{is_auto_increment}))));

                $data->{$column} = $record->{$column};

            }

        }

        # create the record

        $class->create($schema, $data);

        while (my ($key, $value) = each(%$record)) {

            $rec->{$key} = $value;

        }

    });

    return $rec;

}

sub delete_record {
    my $class  = shift;
    my $schema = shift;
    my $record = shift;

    my $data = undef;
    my $criteria = {
        id => $record->{id}
    };

    $schema->txn_do(sub { 

        if (my $row = $class->find($schema, $criteria)) {

            $row->delete();

            while (my ($key, $value) = each(%$record)) {

                $data->{$key} = $value;

            }

        }

    });

    return $data;

}

sub update_record {
    my $class  = shift;
    my $schema = shift;
    my $record = shift;

    my $data = undef;
    my @columns = $class->columns;
    my $criteria = {
        id => $record->{id}
    };

    # retrieve the record

    $schema->txn_do(sub {

        if (my $row = $class->find($schema, $criteria)) {

            # transfer the data

            foreach my $column (@columns) {

                my $info = $class->column_info($column);

                if (defined($record->{$column})) {

                    next if ((defined($info->{auto_nextval}) ||
                             (defined($info->{is_auto_increment}))));

                    $row->$column($record->{$column});

                }

            }

            # update the record

            $row->update();

            while (my ($key, $value) = each(%$record)) {

                $data->{$key} = $value;

            }

        }

    });

    return $data;

}

1;

__END__

=head1 NAME

XAS::Model::DBM - Defines helper functions to DBIx::Class methods

=head1 SYNOPSIS

  use XAS::Model::DBM;

=head1 DESCRIPTION

This module is not usually included directly by user level code. It's 
primiary purpose is to be used as a mixin to a model. This module 
provides several shortcut methods that make database queries easier. To 
learn how they work, please consult the DBIx::Class documentation.

You can use this methods in the following fashion.

 use XAS::Model::Database 'Tablename';

 my $schema = XAS::Model::Database->opendb();

 ... DBIx::Class version

 my @rows = $schema->resultset('Tablename')->search();

 ... as compared to

 my @rows = Tablename->search($schema);

The shortcut require less typing and is slightly more intuitive. Neither 
approach is "more correct" then the other and sometimes they can be
intermixed, especially when searching in related tables.

=head1 METHODS

=head2 create($class, $schema, ...)

This method is a shortcut for creating records. It takes two or more
parameters:

=over 4

=item B<$class>

The DBIx::Class model name. Usually a constant defined within XAS::Model::Database.

=item B<$schema> 

The DBIx::Class schema handle returned from opendb() in XAS::Model::Database.

=item B<...>

Other parameters that are passed directly to the DBIx::Class create() method.

=back

=head2 find($class, $schema, ...)

This method is a shortcut for finding a single record. It takes two or more
parameters:

=over 4

=item B<$class>

The DBIx::Class model name. Usually a constant defined within XAS::Model::Database.

=item B<$schema> 

The DBIx::Class schema handle returned from opendb() in XAS::Model::Database.

=item B<...>

Other parameters that are passed directly to the DBIx::Class find() method.

=back

=head2 search($class, $schena, ...)

This method is a shortcut for record searches. It takes two or more
parameters:

=over 4

=item B<$class>

The DBIx::Class model name. Usually a constant defined within XAS::Model::Database.

=item B<$schema> 

The DBIx::Class schema handle returned from opendb() in XAS::Model::Database.

=item B<...>

Other parameters that are passed directly to the DBIx::Class search() method.

=back

=head2 search_like($class, $schema, ...)

This method is a shortcut for record searches. It takes two or more
parameters:

=over 4

=item B<$class>

The DBIx::Class model name. Usually a constant defined within XAS::Model::Database.

=item B<$schema> 

The DBIx::Class schema handle returned from opendb() in XAS::Model::Database.

=item B<...>

Other parameters that are passed directly to the DBIx::Class search_like() method.

=back

=head2 count($class, $schema)

This method is returns count of the record in a table. It takes two parameters:

=over 4

=item B<$class>

The DBIx::Class model name. Usually a constant defined within XAS::Model::Database.

=item B<$schema> 

The DBIx::Class schema handle returned from opendb() in XAS::Model::Database.

=back

=head2 find_or_create($class, $schema, ...)

This method is a shortcut to find or create a record. It takes two or more
parameters:

=over 4

=item B<$class>

The DBIx::Class model name. Usually a constant defined within XAS::Model::Database.

=item B<$schema> 

The DBIx::Class schema handle returned from opendb() in XAS::Model::Database.

=item B<...>

Other parameters that are passed directly to the DBIx::Class find_or_create() 
method.

=back

=head2 update_or_create($class, $schema, ...)

This method is a shortcut for updating or creating a new record. It takes 
two or more parameters:

=over 4

=item B<$class>

The DBIx::Class model name. Usually a constant defined within XAS::Model::Database.

=item B<$schema> 

The DBIx::Class schema handle returned from opendb() in XAS::Model::Database.

=item B<...>

Other parameters that are passed directly to the DBIx::Class update_or_create() 
method.

=back

=head2 populate($class, $schena, ...)

This method will load a hash of records into a table. It takes two or more
parameters:

=over 4

=item B<$class>

The DBIx::Class model name. Usually a constant defined within XAS::Model::Database.

=item B<$schema> 

The DBIx::Class schema handle returned from opendb() in XAS::Model::Database.

=item B<...>

Other parameters that are passed directly to the DBIx::Class populate() method.

=back

=head2 load_records($class, $schema, ...)

This method will load records into an array of hashes based on passed 
criteria. Any data conversion is done automatically. It takes two or 
more parameters:

=over 4

=item B<$class>

The DBIx::Class model name. Usually a constant defined within XAS::Model::Database.

=item B<$schema> 

The DBIx::Class schema handle returned from opendb() in XAS::Model::Database.

=item B<...>

Other parameters that are passed directly to the search() method.

=back

=head2 delete_records($class, $schema, ...)

This method will delete records based on the passed criteria. 
It takes two or more parameters:

=over 4

=item B<$class>

The DBIx::Class model name. Usually a constant defined within XAS::Model::Database.

=item B<$schema> 

The DBIx::Class schema handle returned from opendb() in XAS::Model::Database.

=item B<...>

Other parameters that are passed directly to the search() method.

=back

=head2 read_record($class, $schema, ...)

This method will find a single record which is returned as a hash with 
any data conversion already done. It takes two or more parameters:

=over 4

=item B<$class>

The DBIx::Class model name. Usually a constant defined within XAS::Model::Database.

=item B<$schema> 

The DBIx::Class schema handle returned from opendb() in XAS::Model::Database.

=item B<...>

Other parameters that are passed directly to the find() method.

=back

=head2 create_record($class, $schema, $record)

This method will create a single record from a hash. This is done within 
a transaction and any data conversion is done automatically. Only hash 
items that match actual fields within the table are stored. It returns a hash
of the inserted fields. It takes three parameters:

=over 4

=item B<$class>

The DBIx::Class model name. Usually a constant defined within XAS::Model::Database.

=item B<$schema> 

The DBIx::Class schema handle returned from opendb() in XAS::Model::Database.

=item B<$record>

The record used to create the table entry.

=back

=head2 delete_record($class, $schema, $record)

This method will delete a single record from the database. This is done 
within a transaction. It returns a hash of the record deleted. It takes 
three parameters:

=over 4

=item B<$class>

The DBIx::Class model name. Usually a constant defined within XAS::Model::Database.

=item B<$schema> 

The DBIx::Class schema handle returned from opendb() in XAS::Model::Database.

=item B<$record>

The record used to delete the table entry.

=back

=head2 update_record($class, $schema, $record)

This method will update a single record in the database. This is done within a 
transaction. Only hash items that match actual fields within the table are 
updated. It returns a hash of the updated fields. It takes three parameters:

=over 4

=item B<$class>

The DBIx::Class model name. Usually a constant defined within XAS::Model::Database.

=item B<$schema> 

The DBIx::Class schema handle returned from opendb() in XAS::Model::Database.

=item B<$record>

The record used to update the table entry. 

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Model|XAS::Model>

=item L<XAS|XAS>

=item <https://metacpan.org/pod/DBIx::Class|DBIx::Class>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
