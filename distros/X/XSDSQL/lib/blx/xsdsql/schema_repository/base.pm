package blx::xsdsql::schema_repository::base;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7

use base qw(blx::xsdsql::ut::common_interfaces);

our %_ATTRS_R:Constant(());

our %_ATTRS_W:Constant(());


sub _get_attrs_w { return \%_ATTRS_W; }
sub _get_attrs_r { return \%_ATTRS_R; }


sub _new  { 
	my ($class,%params)=@_;
	return bless \%params,$class;
}



1;



__END__



=head1  NAME

blx::xsdsql::schema_repository::base -  base of blx::xsdsql::schema_repository::* classes

=cut

=head1 SYNOPSIS

use blx::xsdsql::schema_repository::base

=cut

=head1 SEE ALSO

See blx::xsdsql::schema_repository

=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
