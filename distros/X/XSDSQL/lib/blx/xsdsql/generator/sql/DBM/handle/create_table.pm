package blx::xsdsql::generator::sql::DBM::handle::create_table;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 6

use blx::xsdsql::ut::ut qw(nvl);

use base qw(blx::xsdsql::generator::sql::generic::handle::create_table);


sub table_header {
	my ($self,$table,%params)=@_;
	unless (defined $table->get_attrs_value(qw(_PK_DUMMY))) {
		my @pk_cols=$table->get_pk_columns;
		if (scalar(@pk_cols) > 1) {
			affirm { defined $params{EXTRA_TABLES} } "param EXTRA_TABLES not set";
			my $extra_tables=$params{EXTRA_TABLES};
			my @cols=$table->reset_columns;
			my $pk_col=$extra_tables->factory_pk_col;
			$table->add_columns($pk_col,@cols);
			$table->set_attrs_value(_PK_DUMMY => 1);
		}
		else {
			$table->set_attrs_value(_PK_DUMMY => 0);
		}
	}
	return $self->SUPER::table_header($table,%params);
}


1;

__END__

=head1 NAME

blx::xsdsql::generator::sql::DBM::handle::create_table  - create table  for DBM

=head1 SYNOPSIS


use blx::xsdsql::generator::sql::DBM::handle::create_table


=head1 DESCRIPTION

this package is a class - instance it with the method new

=cut



=head1 VERSION

0.10.0

=cut

=head1 FUNCTIONS

see the methods of blx::xsdsql::generator::sql::generic::handle

=head1 EXPORT

None by default.


=head1 EXPORT_OK

None

=head1 SEE ALSO


See  blx::xsdsql::generator::sql::generic::handle::create_table  - this class inherit from this


=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut



