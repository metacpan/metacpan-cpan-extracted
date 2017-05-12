package Tk::GraphItems::Node;


# Copyright (C) 2007 by Christoph Lamprecht

# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.8.7 or,
# at your option, any later version of Perl 5 you may have available.



use 5.008;
our $VERSION = '0.11';

#use Data::Dumper;
use Carp;
use warnings;
use strict;
use Scalar::Util (qw/looks_like_number/);
require Tk::GraphItems::GraphItem;
require Tk::GraphItems::TiedCoord;
our @ISA = qw/ Tk::GraphItems::GraphItem /;


{
my %iinfo = (-text=>1);                # item information hash

sub _set_canvas_bindings_for_tag{
    my ($self,$tag) = @_;
    my $can = $self->{canvas};

    $can->bind($tag,'<1>' => sub {
                   my($can) = @_;
                   my $e    = $can->XEvent;
                   _items_start_drag ($can, $e->x, $e->y, \%iinfo);
               }
           );
    $can->bind($tag,'<B1-Motion>' =>sub {
                   _items_drag ($can,
                                $Tk::event->x,
                                $Tk::event->y,
                                \%iinfo);
               }
           );
}
} #end scope of iinfo

sub _items_drag {
    my($can, $x, $y, $iinfo) = @_;

    my $id= ($can->find(withtag => 'current'))[0];
    my $self = _get_inst_by_id($can,$id);
    my ($d_x,$d_y) = ($x-$iinfo->{lastX},$y-$iinfo->{lastY});
    $self->_move($d_x ,$d_y);
    $self->{was_dragged}=1;

    $iinfo->{lastX} = $x;
    $iinfo->{lastY} = $y;

} # end items_drag

sub _items_start_drag {

    my($can, $x, $y, $iinfo) = @_;
    $iinfo->{lastX} = $x;
    $iinfo->{lastY} = $y;
    my $id= ($can->find(withtag => 'current'))[0];
    my $self = _get_inst_by_id($can,$id);
    $self->{was_dragged}=0;

} # end items_start_drag



sub move{
    my $self = shift;
    looks_like_number($_)||
        croak "method 'move' failed: args <$_[0]>,<$_[1]> have to be numbers!"
            for (@_[0,1]);
    $self->_move(@_);
}

sub _move{
    my ($self,$d_x,$d_y) = @_;
    my ($x,$y) = $self->get_coords;
    $self->_set_coords($x+$d_x,$y+$d_y);
}
sub set_coords{
    my $self = shift;
    if (ref $_[0]&& ref$_[1]) {
        $self->_tie_coords(@_);
        return;
    }
    for ( @_[0,1] ) {
        looks_like_number($_)||
            croak "method 'set_coords' failed:\n"
                 ."args <$_[0]>,<$_[1]> have to be numbers!";
    }
    $self->_set_coords(@_);
}

sub _tie_coords{
    my $self = shift;
    $self ->_untie_coords;
    tie ${$_[0]}, 'Tk::GraphItems::TiedCoord',$self,0 if ref $_[0];
    tie ${$_[1]}, 'Tk::GraphItems::TiedCoord',$self,1 if ref $_[1];
    @$self{qw/tiedx tiedy/}= @_[0,1];
}
sub _untie_coords{
    my $self = shift;
    for (@$self{qw/tiedx tiedy/}) {
        untie ${$_} ;                #if tied $$_
    }
}

sub was_dragged{
    my $self = shift;
    return $self->{was_dragged} ||0;
}

sub _get_inst_by_id{
    my ($can,$id) = @_;
    my $obj_map = $can->{GraphItemsMap};
    return $obj_map->{$id}||undef;
}




1;

__END__




