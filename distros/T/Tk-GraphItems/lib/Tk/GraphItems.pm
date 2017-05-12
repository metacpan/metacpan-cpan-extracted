#!/usr/bin/perl



=head1 NAME

Tk::GraphItems - Display relation-graphs on a Tk::Canvas

=head1 DESCRIPTION

Tk::GraphItems provides objects TextBox, Circle and Connector to display nodes and edges of given relation-graph models on a Tk::Canvas widget.
Tk::GraphItems contain a dependency mechanism to ensure, that  edges are updated on changes of position or size of their source- and target-nodes. Edges have view-properties like colour, width, direction(arrows). Nodes support (bg)colour and  text (can be multiline). Nodes can be moved and placed programmatically or with drag/drop. To make integration into existing graph-implementations easier, Tk::GraphItems contains a simple tie-module to tie the nodes coords-  getter-/setter - methods to given Variables in the underlying model. Bindings to Tk-Events can be set so it's easy to implement e.g. context-menus for the objects.




=head1 METHODS

B<Tk::GraphItems> supports the following methods:

=over 4

=item B<TextBox(> canvas=>$can,
	         text=>"new_node",
                 x   =>50,
		 y   =>50 B<)>

Create a new Tk::GraphItems::TextBox instance and  display it on the Canvas.

=item B<Circle(> canvas  => $can,
	        colour  => $a_TkColor,
                size    => $size_pixels,
	        x       => 50,
		y       => 50 B<)>

Create a new Tk::GraphItems::Circle instance and  display it on the Canvas.

=item B<Connector(> source=> $source_node, target=> $target_node B<)>

Create a new Tk::GraphItems::Connector instance.

=back

=head1 SEE ALSO

Documentation of Tk::GraphItems::TextBox, Tk::GraphItems::Connector and
Tk::GraphItems::Circle.

=head2 Examples

Examples can be found in Tk/GraphItems/Examples/

=head3 gi_easy.pl

Demonstrates how to set up mouse bindings to create nodes and edges. Adds a context menu binding to nodes.

=head3 create_and_autolayout.pl

Create a 'Graph' object by clicking/dragging and watch Graph::Layout::Aesthetic arranging the nodes.


=head1 AUTHOR

Christoph Lamprecht, ch.l.ngre@online.de

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Christoph Lamprecht

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
use warnings;
use strict;
package Tk::GraphItems;
our $VERSION = '0.12';
require Tk::GraphItems::TextBox;
require Tk::GraphItems::Circle;
require Tk::GraphItems::Connector;
require Tk::GraphItems::LabeledConnector;

sub TextBox{
    if ($_[0]){
        shift;
        return 'Tk::GraphItems::TextBox'->new(@_);
    }
    return 'Tk::GraphItems::TextBox';
}

sub Connector{
    if ($_[0]){
        shift;
        return 'Tk::GraphItems::Connector'->new(@_);
    }
    return 'Tk::GraphItems::Connector';
}
sub Circle{
    if ($_[0]){
        shift;
        return 'Tk::GraphItems::Circle'->new(@_);
    }
    return 'Tk::GraphItems::Circle';
}
sub LabeledConnector{
    if ($_[0]){
        shift;
        return 'Tk::GraphItems::LabeledConnector'->new(@_);
    }
    return 'Tk::GraphItems::LabeledConnector';
}
1;
