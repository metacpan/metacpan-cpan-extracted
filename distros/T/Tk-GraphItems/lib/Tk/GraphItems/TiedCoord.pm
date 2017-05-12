# Copyright (c) 2007 by Christoph Lamprecht. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
# ch.l.ngre@online.de

package Tk::GraphItems::TiedCoord;
use strict;
use warnings;
use Scalar::Util (qw/weaken/);
our $VERSION = '0.11';

sub TIESCALAR{
    my($class,$t_b,$c_in)=@_;
    my $self =  bless{TkGNode      =>$t_b,
                      coord_index  =>$c_in},$class;
    weaken ($self->{TkGNode});
    $self;
}

sub FETCH{
    my $self = shift;
    my $i = $self->{coord_index};
    if ($self->{TkGNode}) {
        return ($self->{TkGNode}->get_coords)[$i];
    }
    return $self->{cached}[$i]||0;
}

sub STORE{
    my ($self,$value) = @_;
    my $i  = $self->{coord_index};
    my $tb = $self->{TkGNode};
    $self->{cached}[$i]= $value;
    return unless $tb;
    my @coords = $tb->get_coords;
    $coords[$i] = $value;
    $tb->set_coords(@coords);
}
1;


__END__




