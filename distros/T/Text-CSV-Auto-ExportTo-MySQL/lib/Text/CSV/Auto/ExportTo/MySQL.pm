package Text::CSV::Auto::ExportTo::MySQL;
BEGIN {
  $Text::CSV::Auto::ExportTo::MySQL::VERSION = '0.02';
}
use Moose;

=head1 NAME

Text::CSV::Auto::ExportTo::MySQL - Export a CSV file to MySQL.

=head1 SYNOPSIS

    use Text::CSV::Auto;
    use Text::CSV::Auto::ExportTo::MySQL;
    
    my $auto = Text::CSV::Auto->new('path/to/file.csv');
    my $exporter = Text::CSV::Auto::ExportTo::MySQL(
        auto => $auto,
        connection => $dbh,
    );

Or a simpler interface can be used:

    $auto->export_to_mysql(
        connection => $dbh,
    );

=head1 DESCRIPTION

This module provides the ability to export a CSV file straight in to MySQL
without much fuss.

Note that if the table already exists it will be dropped.

=head1 ATTRIBUTES

=head2 auto

The L<Text::CSV::Auto> instance to copy headers and rows from.  Required.

=cut

with 'Text::CSV::Auto::ExportTo';

=head2 connection

Can be either a L<DBIx::Connector> (recommended) or a DBI handle.  DBIx::Connector
is recommended as it provides a robust connection and transation management layer
on top of DBI.  Required.

=head2 table

The table name to export to.  Defaults to a nicely formatted version of the
CSV's file name.

=head2 method

If using DBIx::Connector for the connection then this states what method to use
such as "run", "txn", or "svp".  Defaults to "svp" which degrades well on
non-transactional databases.

=head2 mode

If using DBIx::Connector for the connection this this dictates what connection
mode to use such as "ping", "fixup", and "no_ping".  The default is "fixup".

=cut

with 'Text::CSV::Auto::ExportToDB';

=head2 create_sql

Returns the SQL that will be used to CREATE the table.

=cut

has 'create_sql' => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);
sub _build_create_sql {
    my ($self) = @_;

    my $columns = $self->auto->analyze();

    my @columns_sql;
    foreach my $column (@$columns) {
        my $sql = $column->{header} . ' ';

        if ($column->{data_type} eq 'string') {
            $sql .= 'VARCHAR(' . ($column->{string_length} || 1) . ') NOT NULL';
        }
        elsif ($column->{data_type} eq 'decimal') {
            $sql .= sprintf(
                'DECIMAL( %d, %d ) NOT NULL',
                $column->{integer_length} + $column->{fractional_length},
                $column->{fractional_length},
            );
        }
        elsif ($column->{data_type} eq 'integer') {
            my $type;
            if ($column->{signed}) {
                $type = 'BIGINT';
                $type = 'INT' if $column->{max} <= 2147483647 and $column->{min} >= -2147483648;
                $type = 'MEDIUMINT' if $column->{max} <= 8388607 and $column->{min} >= -8388608;
                $type = 'SMALLINT' if $column->{max} <= 32767 and $column->{min} >= -32768;
                $type = 'TINYINT' if $column->{max} <= 127 and $column->{min} >= -128;
            }
            else {
                $type = 'BIGINT';
                $type = 'INT' if $column->{max} <= 4294967295;
                $type = 'MEDIUMINT' if $column->{max} <= 16777215;
                $type = 'SMALLINT' if $column->{max} <= 65535;
                $type = 'TINYINT' if $column->{max} <= 255;
            }
            $sql .= sprintf(
                '%s %s NOT NULL',
                $type,
                ($column->{signed} ? 'SIGNED' : 'UNSIGNED'),
            );
        }
        elsif ($column->{data_type} eq 'mdy_date' or $column->{data_type} eq 'ymd_date') {
            $sql .= 'DATE NOT NULL';
        }

        push @columns_sql, $sql;
    }

    return sprintf(
        'CREATE TABLE %s (%s)',
        $self->table(),
        join(', ', @columns_sql),
    );
}

=head1 METHODS

=head2 export

    $exporter->export();

Exports the CSV data to MySQL.

=cut

sub export {
    my ($self) = @_;

    my $create_sql = $self->create_sql();
    my $table      = $self->table();
    my $headers    = $self->auto->headers();
    my $auto       = $self->auto();
    my $columns    = $self->auto->analyze();

    $self->_run(sub{
        my ($dbh) = @_;

        $dbh->do('DROP TABLE IF EXISTS ' . $table );

        $dbh->do( $create_sql );

        my $sth = $dbh->prepare( sprintf(
            'INSERT INTO %s (%s) VALUES (%s)',
            $table,
            join(',', @$headers),
            join(',', map {'?'} @$headers ),
        ) );

        $auto->_raw_process(sub{
            my ($row) = @_;
            my $i = 0;
            foreach my $column (@$columns) {
                if ($column->{data_type} eq 'mdy_date') {
                    $row->[$i] = sprintf('%04d-%02d-%02d', (split(/\//, $row->[$i]))[2,0,1] );
                }
                $i ++;
            }
            $sth->execute( @$row );
        }, 1);
    });
}

__PACKAGE__->meta->make_immutable();
1;
__END__

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

