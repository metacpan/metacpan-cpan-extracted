package blx::xsdsql::generator::sql::mysql::handle::insert_dictionary;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 6

use base qw(blx::xsdsql::generator::sql::generic::handle::insert_dictionary);
use blx::xsdsql::ut::ut qw(nvl);

sub _manip_value { #manip values from input data
	my ($self,$col,$value,%params)=@_;
	if (defined $value) {
		my $t=$col->get_attrs_value(qw(TYPE_DUMPER));
		affirm { defined $t } "attribute TYPE_DUMPER not set for column ".nvl($col->get_full_name);
		if ($t->{BASE} eq 'boolean') {
			if ($value eq '1') {
				$value='true' ;
			}
			elsif($value eq '0') {
				$value='false';
			}
			else {
				croak  "'$value': unknow value for type boolean"
			}
			return $value;
		}		
	}
	return $self->SUPER::_manip_value($col,$value,%params);
}


1;

__END__

=head1 NAME

blx::xsdsql::generator::sql::mysql::handle::insert_dictionary  - insert dictionary  for mysql

=head1 SYNOPSIS


use blx::xsdsql::generator::sql::mysql::handle::insert_dictionary


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


See  blx::xsdsql::generator::sql::generic::handle::insert_dictionary  - this class inherit from this


=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut



