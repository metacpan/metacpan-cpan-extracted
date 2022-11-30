package pEFL::Edje::Message::String;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter EdjeMessageStringPtr);

require XSLoader;
XSLoader::load('pEFL::Edje::Message::String');


package EdjeMessageStringPtr;



# Preloaded methods go here.

1;
__END__

=head1 NAME

pEFL::Edje::Message::String

=head1 DESCRIPTION

This module is a perl binding to the Edje_Message_String struct.

=head1 AUTHOR

Maximilian Lika

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
