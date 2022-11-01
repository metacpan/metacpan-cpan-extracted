package pEFL::Evas::Coord::Rectangle;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter EvasCoordRectanglePtr);

require XSLoader;
XSLoader::load('pEFL::Evas::Coord::Rectangle');

# sub add {
#    my ($class,$parent) = @_;
#    my $widget = evas_object_rectangle_add($parent);
#    $widget->smart_callback_add("del", \&pEFL::PLSide::cleanup, $widget);
#    return $widget;
#}

# *new = \&add;

package EvasCoordRectanglePtr;



# Preloaded methods go here.

1;
__END__

=head1 NAME

pEFL::Evas::Coord::Rectangle

=head1 DESCRIPTION

This module is a perl binding to the struct Evas_Coord_Rectangle.

=head1 AUTHOR

Maximilian Lika

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
