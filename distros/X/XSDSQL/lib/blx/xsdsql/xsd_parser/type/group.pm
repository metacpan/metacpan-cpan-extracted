package blx::xsdsql::xsd_parser::type::group;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 6
use blx::xsdsql::ut::ut qw(nvl);

use base qw(blx::xsdsql::xsd_parser::type::base);


sub link_to_column {
	my ($self,$c,%params)=@_;
	my $ty=$self->get_attrs_value(qw(NAME));
	my $table=$ty->get_attrs_value(qw(TABLE));
	my $schema=$self->get_attrs_value(qw(SCHEMA));
	$c->set_attrs_value(
		TYPE 					=> $schema->get_attrs_value(qw(ID_SQL_TYPE))
		,INTERNAL_REFERENCE		=> 0
		,PATH_REFERENCE 		=> $table->get_path
		,TABLE_REFERENCE 		=> $table
	); 
	return $self;
}

1;


__END__


=head1  NAME

blx::xsdsql::xsd_parser::type::group - internal class for parsing schema

=cut

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
