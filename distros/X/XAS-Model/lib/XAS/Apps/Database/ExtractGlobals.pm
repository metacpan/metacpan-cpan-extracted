package XAS::Apps::Database::ExtractGlobals;

our $VERSION = '0.02';

use Try::Tiny;
use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Lib::App',
  accessors => 'file database',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub parse_file {
    my $self = shift;

    my $fh;
    my $database = $self->database;

    open($fh, "<", $self->file);

    while (<$fh>) {

        if ($_ =~ m/^\\connect $database/) {

            print $_;

            while (<$fh>) {

                return if ($_ =~ m/^\\connect/);

                print $_;

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

    $self->{'file'} = '';
    $self->{'database'} = '';

    return {
        'file=s'     => \$self->{'file'},
        'database=s' => \$self->{'database'},
    };

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Apps::Database::ExtractGlobals - This module will extract globals from a PostgreSQL dump file

=head1 SYNOPSIS

 use XAS::Apps::Database::ExtractGlobals;

 my $app = XAS::Apps::Database::ExtractGlobals->new(;
    -throws  => 'xas-pg-extract-global',
 );

 exit $app->run();

=head1 DESCRIPTION

This module will extract the global elements from a PostgreSQL pg_dumpall file.
This is based on the database name. This data is then suitable to populate
an "empty" database that already has a schema defined. This allows 
you to do selective restores.

=head1 OPTIONS

The following options are used to configure the module.

=head2 --file

Defines the dump file to use.

=head2 --database

Defines which database to extract data from.

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
