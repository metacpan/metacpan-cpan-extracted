package blx::xsdsql::schema_repository::sql::generic::relation_table;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7

my @ATTRIBUTE_KEYS:Constant(
							qw(
								PARENT_TABLE_NAME
								CHILD_SEQUENCE
								CHILD_TABLE_NAME
								CATALOG_NAME			
							)
);

use blx::xsdsql::ut::ut qw(nvl ev);
use base qw(blx::xsdsql::ut::common_interfaces);

our %_ATTRS_R:Constant(());
our %_ATTRS_W:Constant(());

sub _get_attrs_w { return \%_ATTRS_W; }
sub _get_attrs_r { return \%_ATTRS_R; }

sub new {
	my ($class,%params)=@_;
	return bless \%params,$class;
}

sub factory_from_dictionary_data {
	my ($data,%params)=@_;
	affirm { ref($data) eq 'ARRAY' } "the 1^ param must be array";
	affirm { defined $params{EXTRA_TABLES} } " the param EXTRA_TABLES must be set";
	affirm { scalar(@$data) == scalar(@ATTRIBUTE_KEYS) }  "the attributes number is not equal to keys number"; 
	my %data=map {  ($ATTRIBUTE_KEYS[$_],$data->[$_])  } (0..scalar(@$data) - 1);
	my $t=__PACKAGE__->new(%data);
	return $t;
}


1;

__END__

=head1  NAME

blx::xsdsql::schema_repository::sql::generic::relation_table -  mapping class to table  RELATION_TABLE_DICTIONARY

=cut

=head1 SYNOPSIS

use blx::xsdsql::schema_repository::sql::generic::relation_table

=cut


=head1 DESCRIPTION

this package is a class - instance it with the method new


=head1 VERSION

0.10.0

=cut



=head1 BUGS

Please report any bugs or feature requests to https://rt.cpan.org/Public/Bug/Report.html?Queue=XSDSQL

=cut



=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>


=cut


=head1 COPYRIGHT

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
