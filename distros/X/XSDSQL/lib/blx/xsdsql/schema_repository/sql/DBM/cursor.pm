package blx::xsdsql::schema_repository::sql::DBM::cursor;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7

use blx::xsdsql::ut::ut qw(nvl);
use base qw(blx::xsdsql::schema_repository::sql::generic::cursor);

sub _manip_value {
	my ($self,$col,$value,%params)=@_;
	my $t=$col->get_attrs_value(qw(TYPE_DUMPER));
	affirm { defined $t } "attribute TYPE_DUMPER not set for column ".nvl($col->get_full_name);
	if (defined $value) {
		if ($t->{BASE} eq 'boolean') {
			if ($value eq 'Y') {
				$value='1'
			}
			elsif ($value eq 'N') {
				$value='0';
			}
			else {
				croak "'$value': invalid value for boolean type";
			}
		}
	}
	return $value;
}


1;

__END__


=head1  NAME

blx::xsdsql::schema_repository::sql::DBI::cursor -  wrapper to DBI cursor

=cut

=head1 SYNOPSIS

blx::xsdsql::schema_repository::sql::DBI::cursor

=cut


=head1 DESCRIPTION

this class is istantiated by class 'binding'



=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
