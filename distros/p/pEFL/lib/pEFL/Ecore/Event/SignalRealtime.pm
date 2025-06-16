package pEFL::Ecore::Event::SignalRealtime;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter EvasEventSignalRealtimePtr);

require XSLoader;
XSLoader::load('pEFL::Ecore::Event::SignalRealtime');


package EvasEventSignalRealtimePtr;



# Preloaded methods go here.

1;
__END__

=head1 NAME

pEFL::Ecore::Event::SignalRealtime

=head1 DESCRIPTION

This module is a perl binding to the Ecore_Event_Signal_Realtime struct.

=head1 AUTHOR

Maximilian Lika

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
