package pEFL::Evas::Event::MouseDown;

use strict;
use warnings;

use pEFL::Evas::Modifier;
use pEFL::Evas::Lock;

require Exporter;

our @ISA = qw(Exporter EvasEventMouseDownPtr);

require XSLoader;
XSLoader::load('pEFL::Evas::Event::MouseDown');

# sub add {
#    my ($class,$parent) = @_;
#    my $widget = evas_object_rectangle_add($parent);
#    $widget->smart_callback_add("del", \&pEFL::PLSide::cleanup, $widget);
#    return $widget;
#}

# *new = \&add;

package EvasEventMouseDownPtr;



# Preloaded methods go here.

1;
__END__

=head1 NAME

pEFL::Evas::Event::MouseDown

=head1 DESCRIPTION

This module is a perl binding to the struct Evas_Event_Mouse_Down.

=head1 AUTHOR

Maximilian Lika

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
