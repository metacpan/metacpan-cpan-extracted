package XAS::Model;

our $VERSION = '0.02';

1;

__END__
  
=head1 NAME

XAS::Model - Database abstraction layer for the XAS Middleware Suite

=head1 DESCRIPTION

The database abstraction layer is built upon L<DBIx::Class|https://metacpan.org/pod/DBIx::Class> 
which is robust ORM for Perl. The modules provided try to make working with 
databases easier.

=head1 UTILITIES

These utility procedures are provided with this package.

=head2 xas-create-schema

This procedure will create a database schema. by default this is for SQLite. 
Others databases may be defined on the command line.

=over 4

=item B<xas-create-schema --help>

This will display a brief help screen on command options.

=item B<xas-create-schema --manual>

This will display the utilities man page.

=back

=head2 xas-pg-extract-data

This procedure will extract the data from a PostgreSQL dump file. This is done
by table, which can be defined on the command line.

=over 4

=item B<xas-pg-extract-data --help>

This will display a brief help screen on command options.

=item B<xas-pg-extract-data --manual>

This will display the utilities man page.

=back

=head2 xas-pg-extract-global

This procedure will extract global data from a PostgreSQL dump file.

=over 4

=item B<xas-pg-extract-global --help>

This will display a brief help screen on command options.

=item B<xas-pg-extract-global --manual>

This will display the utilities man page.

=back

=head2 xas-pg-remove-data

This procedure will remove the data elements from a PostgreSQL dump file. This
is usefull for recreating a database schema.

=over 4

=item B<xas-pg-remove-data --help>

This will display a brief help screen on command options.

=item B<xas-pg-remove-data --manual>

This will display the utilities man page.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Model::Database|XAS::Model::Database>

=item L<XAS::Model::DBM|XAS::Model::DBM>

=item L<XAS::Model::Schema|XAS::Model::Schema>

=item L<XAS::Apps::Database::ExtractData|XAS::Apps::Database::ExtractData>

=item L<XAS::Apps::Database::ExtractGlobals|XAS::Apps::Database::ExtractGlobals>  

=item L<XAS::Apps::Database::RemoveData|XAS::Apps::Database::RemoveData>

=item L<XAS::Apps::Database::Schema|XAS::Apps::Database::Schema>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
