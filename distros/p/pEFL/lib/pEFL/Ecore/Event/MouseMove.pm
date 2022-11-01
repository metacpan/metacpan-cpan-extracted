package pEFL::Ecore::Event::MouseMove;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter EcoreEventMouseMovePtr);

require XSLoader;
XSLoader::load('pEFL::Ecore::Event::MouseMove');


package EcoreEventMouseMovePtr;



# Preloaded methods go here.

1;
__END__

=head1 NAME

pEFL::Ecore::Event::MouseMove

=head1 DESCRIPTION

This module is a perl binding to the Ecore_Event_Mouse_Move struct.

=head1 AUTHOR

Maximilian Lika

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
