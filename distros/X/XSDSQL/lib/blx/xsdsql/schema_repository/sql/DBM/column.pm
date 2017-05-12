package blx::xsdsql::schema_repository::sql::DBM::column;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 6

use base qw(blx::xsdsql::schema_repository::sql::DBM::catalog blx::xsdsql::schema_repository::sql::generic::column);
use blx::xsdsql::ut::ut qw(nvl);


sub new {
	my ($class,%params)=@_;
	return $class->blx::xsdsql::schema_repository::sql::generic::column::_new(%params);
}


sub get_dictionary_data {
	my ($self,$dictionary_type,%params)=@_;
	my %data=$self->blx::xsdsql::schema_repository::sql::generic::column::get_dictionary_data($dictionary_type,%params);
	$data{pk_autosequence}=$self->get_attrs_value(qw(PK_AUTOSEQUENCE));
	return wantarray ? %data : \%data;
}

sub get_attrs_key {
	my ($self,%params)=@_;
	my @attrs_key=$self->blx::xsdsql::schema_repository::sql::generic::column::get_attrs_key;
	push @attrs_key,'PK_AUTOSEQUENCE';
	return wantarray ? @attrs_key : \@attrs_key;
}

sub factory_from_dictionary_data {
	my ($data,%params)=@_;
	affirm { ref($data) eq 'ARRAY' } "the 1^ param must be array";
	my $pk_autosequence=pop @$data;
	my $c=blx::xsdsql::schema_repository::sql::generic::column::factory_from_dictionary_data($data,%params);
	$c->{PK_AUTOSEQUENCE}=$pk_autosequence;	
	return $c;
}

	
1;


__END__

=head1  NAME

blx::xsdsql::schema_repository::sql::DBM::column -  a column class for DBM

=cut

=head1 SYNOPSIS

  use blx::xsdsql::schema_repository::sql::DBM::column

=cut


=head1 DESCRIPTION

this package is a class - instance it with the method new



=head1 VERSION

0.10.0

=cut

=head1 FUNCTIONS

see the methods of blx::xsdsql::schema_repository::sql::generic::column and blx::xsdsql::schema_repository::sql::DBM::catalog


=head1 EXPORT

None by default.


=head1 EXPORT_OK

none

=head1 SEE ALSO

See blx::xsdsql::schema_repository::sql::generic::column and blx::xsdsql::schema_repository::sql::DBM::catalog  - this class inerith for it

See blx:.xsdsql::generator for generate the schema of the database and blx::xsdsql::parser  for parse a xsd file (schema file)

=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut




