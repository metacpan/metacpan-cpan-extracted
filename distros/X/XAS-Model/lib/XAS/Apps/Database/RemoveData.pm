package XAS::Apps::Database::RemoveData;

our $VERSION = '0.02';

use Try::Tiny;
use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Lib::App',
  accessors => 'file',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub parse_file {
    my $self = shift;

    my $fh;

    open($fh, "<", $self->file);

    LOOP:
    while (<$fh>) {

        if ($_ =~ m/^COPY \w+ \(/) {

            while (<$fh>) {

                next LOOP if ($_ =~ m/^\\\./);

            }

        }

        print $_;

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

    $self->{file} = '';

    return {
        'file=s' => \$self->{file},
    };

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Apps::Database::RemoveData - This module will remove data from a PostgreSQL dump file

=head1 SYNOPSIS

 use XAS::Apps::Database::RemoveData;

 my $app = XAS::Database::Base::RemoveData->new(;
    -throws  => 'xas-pg-remove-data',
 );

 exit $app->run();

=head1 DESCRIPTION

This module will strip the "copy" statements from a PostgreSQL pg_dumpall file.
Thus producing a schema that is suitable to rebuild an "empty" database.
It inherits from L<XAS::Lib::App|XAS::Lib::App>. Please see that module for 
additional documentation.

=head1 OPTIONS

This modules provides these additional cli options.

=head2 --file

Defines the dump file to use.

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
