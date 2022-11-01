package pEFL::Evas::Modifier;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter EvasModifierPtr);

require XSLoader;
XSLoader::load('pEFL::Evas::Modifier');

package EvasModifierPtr;

our @ISA = qw();

# Preloaded methods go here.

1;
__END__

=head1 NAME

pEFL::Evas::Modifier

=head1 DESCRIPTION

This module is a perl binding to Evas_Modifier.

Evas_Modifier is an opaque type containing information on whick modifier keys are registered in an Evas canvas.

=head1 SEE ALSO

https://www.enlightenment.org/develop/legacy/api/c/start#group__Evas__Keys.html

=head1 AUTHOR

Maximilian Lika

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
