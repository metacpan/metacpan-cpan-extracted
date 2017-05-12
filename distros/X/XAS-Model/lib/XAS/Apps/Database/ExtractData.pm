package XAS::Apps::Database::ExtractData;

our $VERSION = '0.02';

use Try::Tiny;
use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Lib::App',
  accessors => 'table schema file'
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub parse_file {
    my $self = shift;

    my $fh;
    my $table = $self->table;
    my $schema = $self->schema;

    open($fh, "<", $self->file);

    while (<$fh>) {

        if ($_ =~ m/^COPY $table \(/ ) {

            printf("SET search_path = %s, pg_catalog;\n", $schema);
            print $_;

            while (<$fh>) {

                print $_;

                return if ($_ =~ m/^\\\./);

            }

        }

    }

}

sub main {
    my $self = shift;

    $self->log->debug('starting main section');

    $self->parse_file();

    $self->log->debug('ending main section');

}

sub options {
    my $self = shift;

    $self->{'file'}   = '';
    $self->{'table'}  = '';
    $self->{'schema'} = '';

    return {
        'file=s'   => \$self->{'file'},
        'table=s'  => \$self->{'table'},
        'schema=s' => \$self->{'schema'},
    };

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Apps::Database::ExtractData - This module will extract data from a PostgreSQL dump file

=head1 SYNOPSIS

 use XAS::Apps::Database::ExtractData;

 my $app = XAS::Apps::Database::ExtractData->new(;
    -throws  => 'xas-pg-extract-data',
 );

 exit $app->run();

=head1 DESCRIPTION

This module will extract the "copy" statements from a PostgreSQL pg_dumpall file.
This is based on the table name. This data is then suitable to populate
an "empty" database that already has a schema defined. This allows 
you to do selective restores.

=head1 OPTIONS

The following options are used to configure the module.

=head2 --file

Defines the dump file to use.

=head2 --table

Defines which table to extract data from.

=head2 --schema

Defines the database schema to use.

=head1 SEE ALSO

=over 4

=item L<XAS::Model|XAS::Model>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2015 by Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
