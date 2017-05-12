package blx::xsdsql::xsd_parser::type::base;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 6

use base qw(blx::xsdsql::ios::debuglogger blx::xsdsql::ut::common_interfaces);

our %_ATTRS_W:Constant(());
our %_ATTRS_R:Constant(());

sub _get_attrs_w { return \%_ATTRS_W; }
sub _get_attrs_r { return \%_ATTRS_R; }



1;


__END__

=head1  NAME

blx::xsdsql::xsd_parser::type::base - base class for blx::xsdsql::xsd_parser::type classes

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
