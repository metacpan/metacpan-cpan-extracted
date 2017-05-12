package blx::xsdsql::schema_repository::sql::mysql::extra_tables;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7

use base qw(blx::xsdsql::schema_repository::sql::generic::extra_tables);


sub _get_type_catalog_name_size {
	return 255;
}	

sub _get_type_schema_code_size {
	return 255;
}

sub _get_type_xml_name_size {
	return 255;
}

1;


__END__


=head1  NAME

blx::xsdsql::schema_repository::sql::mysql::extra_tables -  class for generate the object  not schema dependent for mysql

=cut

=head1 SYNOPSIS

use blx::xsdsql::schema_repository::sql::mysql::extra tables

=cut


=head1 DESCRIPTION

this package is a class - instance it with the method new


=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
