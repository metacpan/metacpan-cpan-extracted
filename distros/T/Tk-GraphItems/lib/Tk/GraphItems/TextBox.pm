package Tk::GraphItems::TextBox;


=head1 NAME

Tk::GraphItems::TextBox - Display nodes of relation-graphs on a Tk::Canvas

=head1 SYNOPSIS


  require Tk::GraphItems::TextBox;
  require Tk::GraphItems::Connector;
  ...
  my $node = Tk::GraphItems::TextBox->new( canvas=> $can,
                                           text  => "new_node",
                                           font  => ['Courier',8],
                                           x   => 50,
                                                  y   => 50 );
  $node->move( 10, 0 );
  $node->set_coords( 50, 50 );
  $node->text( $node->text()."\nanother_line" );
  $node->colour( 'red' );






=head1 DESCRIPTION

Tk::GraphItems::TextBox provides objects to display nodes of relation-graphs on a Tk::Canvas widget.

=head1 METHODS

B<Tk::GraphItems::TextBox> supports the following methods:

=over 4

=item B<new(> canvas=> $a_canvas,
             x     => $x_coord,
             y     => $y_coord,
             text  => $textB,
             font  => $aTkFont B<)>

Return a new TextBox instance and display it on the given 'Canvas'. The canvas-items will be destroyed with the TextBox-instance when it goes out of scope.

=item B<set_coords(> $x, $y B<)>

Set the (center)coordinates of this node.
If two references are given as argumnents, the referenced Scalar-variables will get tied to the coordinates properties of the node.

=item B<get_coords>

Return the (center)coordinates of this node.

=item B<move(> $d_x, $d_y B<)>

Move the node by ( $d_x, $d_y ) points.

=item B<text(> [$a_string] B<)>

Sets the displayed text to $a_string, if the argument is given. Returns the current text, if called without an argument.

=item B<colour(> [$a_Tk_colour] B<)>

Sets the background to $a_Tk_colour, if the argument is given. Returns the current colour, if called without an argument.

=item B<bind_class(> 'event', $coderef B<)>

Binds the given 'event' sequence to $coderef. This binding will exist for all TextBox instances on the Canvas displaying the invoking object. The binding will not exist for TextBox items that are displayed on other Canvas instances. The TextBox instance which is the 'current' one at the time the event is triggered will be passed to $coderef as an argument. If $coderef contains an empty string, the binding for 'event' is deleted.

=item B<was_dragged>

Returns a true value in case a <B1-Motion> occured after the last <B1>. You may want to check this when binding to <B1-Release>, to make sure the action was a 'click' and not a 'drag'.

=back

=head1 SEE ALSO

Documentation of Tk::GraphItems::Connector.
Examples in Tk/GraphItems/Examples.

=head1 AUTHOR

Christoph Lamprecht, ch.l.ngre@online.de

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Christoph Lamprecht

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.




=cut

use 5.008;
our $VERSION = '0.11';

#use Data::Dumper;
use Carp;
use warnings;
use strict;
require Tk::GraphItems::Node;
require Tk::GraphItems::TiedCoord;
our @ISA = ('Tk::GraphItems::Node');


sub initialize{
    my $self = shift;

    if (@_%2) {
        croak "wrong number of args! ";
    }
    
    my %args = @_;
    my ($can,$x,$y,$text,$font,$colour)
        = @args{qw/canvas x y text font colour/};
    eval {$can->isa('Tk::Canvas')};
    croak "this is not a 'Canvas':<$can> $@" if $@;
    unless ($can->Exists){croak "This Canvas does not Exist:<$can>"};
    my $text_id;
    my @coords;
    @coords= map {ref($_)?$$_:$_} ($x,$y);
    my @font = (-font=>$font) if $font;

    eval{$text_id = $can->createText(@coords,
                                     -text => $text,
                                     @font,
                                     -tags =>['TextBoxText',
                                              'TextBox',
                                              'TextBoxBind']);
     };
    croak "could not create TextBox at coords <$x>,<$y>: $@" if $@;

    my $p = 3;
    my @bbox =  $can->bbox($text_id);
    @bbox = ($bbox[0] -$p,$bbox[1]-$p,$bbox[2]+$p,$bbox[3]+$p);
    my $box_id  = $can->createRectangle(
                                        @bbox,
                                        -fill  => 'white',
                                        -tags  =>['TextBoxBox',
                                                  'TextBox',
                                                  'TextBoxBind']);
    $self->{text_id}    = $text_id;
    $self->{box_id}     = $box_id;
    $self->{dependents} = {};
    $self->{canvas}     = $can;
    
    $self->SUPER::initialize;

    $self->_create_canvas_layers;
    $self->_set_layer(2); 
    $self->_set_canvas_bindings;
    if (ref $x and ref $y) {
        $self->_tie_coords($x,$y);
    }
    $self->colour($colour) if $colour;
    return $self;

}


sub _set_canvas_bindings{
    my ($self) = @_;
    my $can = $self->{canvas};
    return if $can->{TextBoxBindings_done};

    $self->_set_canvas_bindings_for_tag('TextBox');

    $can->{TextBoxBindings_done}= 1;
}


sub bind_class{
    my ($self,$event,$code) = @_;
    my $can = $self->{canvas};
    $self->_bind_this_class($event,'TextBoxBind',$code);
}

sub canvas_items{
    my $self = shift;
    return (@$self{qw/ box_id text_id/});
}

sub connector_coords{
    my ($self,$dependent) = @_;
    my ($x,$y) = $self->get_coords;
    if (!defined $dependent){
        return($x,$y);
    }
    my $where = $dependent->{master}{$self};
    my $other = $where eq 'source'? 'target':'source';
    my $c_c = $dependent->get_coords($other);
    my @bbox = ($self->{canvas})->coords($self->{box_id});
    my $height = $bbox[3]-$bbox[1];
    my $width  = $bbox[2]-$bbox[0];
    my $b_r = $height / $width;
    my $c_r= ($c_c->[1]-$y)/(($c_c->[0]-$x)||0.01);
    if (abs ($b_r) > abs ($c_r)) { #r or l
        if ($c_c->[0] > $x) {        #right
            #print "right\n";
            $x = $bbox[2];
            $y = $y+($c_r * $width /2);
        } else {                #left
            #print "left\n";
            $x = $bbox[0];
            $y = $y-($c_r * $width /2);
        }
    } else {                        # b or t
        if ($c_c->[1] < $y) {        #top
            #print "top\n";
            $y = $bbox[1];
            $x = $x-((1/($c_r||0.01))*$height /2);
        } else {                #bottom
            #print "bottom\n";
            $y = $bbox[3];
            $x = $x+((1/($c_r||0.01))*$height /2);
        }
    }
    return($x,$y);

}

sub _set_coords{
    my ($self,$x,$y)=@_;
    my ($can,$t_id,$b_id) = @$self{qw/canvas text_id box_id/};
    my $p = 3;
    $can->coords($t_id,$x,$y);
    my @bbox =  $can->bbox($t_id);
    @bbox = ($bbox[0] -$p,$bbox[1]-$p,$bbox[2]+$p,$bbox[3]+$p);
    $can->coords($b_id,@bbox);

    for ($self->dependents) {
        $_->position_changed($self);
    }
}

sub text{
    my $self = shift;
    my $can = $self->get_canvas;
    if (@_) {
        $can->itemconfigure($self->{text_id},-text=>$_[0]);
        #call _set_coords to resize TextBox
        $self->_set_coords($self->get_coords);
        return $self;
    } else {
        return $can->itemcget($self->{text_id},'-text');
    }
}

sub colour{
    my $self = shift;
    my $can = $self->get_canvas;
    if (@_) {
        eval{$can->itemconfigure($self->{box_id},-fill=>$_[0]);};
        croak " setting colour to <$_[0]> not possible: $@" if $@;
        return $self;
    } else {
        return $can->itemcget($self->{box_id},'-fill');
    }
}
sub get_coords{
    my$self = shift;
    my $can = $self->get_canvas;
    my @coords = $can->coords($self->{text_id});
    return wantarray ? @coords:\@coords;
}


1;

__END__




