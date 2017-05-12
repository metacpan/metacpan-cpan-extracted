package blx::xsdsql::ut::posix;

use strict;  # use strict is for PBP
use POSIX;

sub  get_int_max {  return INT_MAX; }

1;

__END__

=head1  NAME

blx::xsdsql::ut::posix  - static method for posix constants

=head1 SYNOPSIS


use blx::xsdsql::ut::posix


=head1 DESCRIPTION

this package is a collection of static methods on the POSIX package
this package exist for a conflict from package Carp::Assert

=cut



=head1 VERSION

0.10.0

=cut

=head1 FUNCTIONS

get_int_max  - return the value of the constant INT_MAX;


=head1 EXPORT

None by default.


=head1 EXPORT_OK

None

=head1 SEE ALSO


See  the POSIX package


=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

