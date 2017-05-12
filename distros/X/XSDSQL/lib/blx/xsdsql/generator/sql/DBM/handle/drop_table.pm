package blx::xsdsql::generator::sql::DBM::handle::drop_table;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 6
use base qw(blx::xsdsql::generator::sql::generic::handle::drop_table);

sub _get_drop_prefix {
	my ($self,%params)=@_;
	return "drop table if exists";
}

sub _get_drop_suffix {
	my ($self,%params)=@_;
	return "cascade";
}

1;


__END__

=head1 NAME

blx::xsdsql::generator::sql::DBM::handle::drop_table  - drop table  for DBM

=head1 SYNOPSIS


use blx::xsdsql::generator::sql::DBM::handle::drop_table


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


See  blx::xsdsql::generator::sql::generic::handle::drop_table  - this class inherit from this


=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut



