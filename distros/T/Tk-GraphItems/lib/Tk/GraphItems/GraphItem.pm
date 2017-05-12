# Copyright (c) 2007 by Christoph Lamprecht. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
# ch.l.ngre@online.de
package Tk::GraphItems::GraphItem;
use Scalar::Util qw(weaken);

use strict;
use warnings;
use Carp;

use 5.008;
our $VERSION = '0.12';

sub new{
    my $class = shift;
    if (ref $class) {
        croak "new has to be called on a class-name!";
    }
    if (@_%2) {
        croak "wrong number of args! ";
    }
    my $self = {};
    bless $self, $class;
    $self->initialize(@_);
    return $self;
}
sub initialize{
    my $self = shift;
    $self->_register_instance;
    return $self;
}


sub add_dependent{
    my ($self,$dependent) = @_;
    $self->{dependents}{$dependent} = $dependent;
}
sub add_dependent_weak{
    my ($self,$dependent) = @_;
    $self->add_dependent($dependent);
    weaken($self->{dependents}{$dependent});
}
sub remove_dependent{
    my ($self,$dependent) = @_;
    delete $self->{dependents}{$dependent};
}

sub dependents{
    my $self = shift;
    return values %{$self->{dependents}};
}

sub _set_layer{
    my ($self,$layer)=@_;
    my $can = $self->get_canvas;

    my $l_id = $can->{GraphItem_layers}[$layer];
    unless ($can->type($l_id)){
        croak "could not _set_layer.
Canvas-item with id <$l_id> has been deleted by user.
Be careful not to manipulate or delete Tk::GraphItems directly!" ;}
    $can->lower($_,$l_id)for $self->canvas_items;
}

sub _create_canvas_layers{
    my $self = shift;
    return if ($self->get_canvas)->{GraphItem_layers};
    my $can = $self->get_canvas;
    my @layers;
    $layers[$_]= $can->createLine(10,10,10,10) for (0..2);
    $can->{GraphItem_layers} = \@layers;
}

sub get_canvas{
    my $self = shift;
    $self->{canvas};
}

sub _register_instance{
    my $self = shift;
    my $can = $self->get_canvas;
    my $obj_map = $can->{GraphItemsMap}||={};
    for ($self->canvas_items) {
        $obj_map->{$_} = $self;
        weaken ($obj_map->{$_});
    }
}

sub _bind_this_class{
    my ($self,$event,$tag,$code) = @_;
    my $can = $self->{canvas};
    if ($code) {
        $can->bind($tag,$event => sub {
                       my($can) = @_;
                       my $id= ($can->find(withtag => 'current'))[0];
                       my $self = _get_inst_by_id($can,$id);
                       $code->($self);
                   });
    } else {
        $can->bind( $tag,$event,'');
    }
}

sub _get_inst_by_id{
    my ($can,$id) = @_;
    my $obj_map = $can->{GraphItemsMap};
    return $obj_map->{$id}||undef;
}



sub DESTROY{
    my $self = shift;
    my $can = $self->{canvas};
    my $obj_map = $can->{GraphItemsMap};
    #my $text = $self->text()||'a GraphItem';

    for ($self->canvas_items) {
        eval{$can->delete($_)};        #if UNIVERSAL::isa($can,'Tk::Canvas');
        delete $obj_map->{$_};
    }
    # destroy dependents...?
    for ($self->dependents) {
        eval{$_->destroy_myself}
    }
    #print "destroying $text\n";
}


1;
