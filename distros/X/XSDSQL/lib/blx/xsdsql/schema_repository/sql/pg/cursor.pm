package blx::xsdsql::schema_repository::sql::pg::cursor;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7

use blx::xsdsql::ut::ut qw(nvl);
use base qw(blx::xsdsql::schema_repository::sql::generic::cursor);

sub _manip_value {
	my ($self,$col,$value,%params)=@_;
	if (defined $value) {
		my $t=$col->get_attrs_value(qw(TYPE_DUMPER));
		affirm { defined $t } "attribute TYPE_DUMPER not set for column ".nvl($col->get_full_name);
		if ($t->{BASE} eq 'decimal') {
			$value=~s/0+$// if $value=~/\./;
			$value=~s/\.$//;
		}
	}
	return $value;
}



1;

__END__

=head1  NAME

blx::xsdsql::schema_repository::sql::pg::cursor -  wrapper to DBI cursor

=cut

=head1 SYNOPSIS

blx::xsdsql::schema_repository::sql::pg::cursor

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
