package Wx::SimplePlotter;

use 5.006;
use strict;
use warnings;

use Wx qw(wxSOLID);
use Wx::Event qw(EVT_PAINT EVT_SIZE);

our @ISA = qw(Wx::Control);

our $VERSION = '0.03';

our $Default_Colours = [[0, 0, 0], [255, 0, 0], [0, 0, 255], [0, 255, 0]];

=head1 NAME

Wx::SimplePlotter - Simple Plotter Control

=head1 SYNOPSIS

  use Wx::SimplePlotter;

  # init app, window etc.

  my $plotter = Wx::SimplePlotter->new();
  
  $plotter->SetColours([0, 0, 0], [255, 0, 0], [0, 0, 255], [0, 255, 0]);
  $plotter->SetPoints(...)
  
  # plot ten sinus functions on a logarithmic x scale
  my (@a);
  for (1..1000) {
     for my $i (0..9) {
         push @{$a[$i]}, [log($_), sin($_ / 10) * $i];
     }
  }
  $plotter->SetPoints(@a);
  
  # add plotter control to sizer, start app etc.

=head1 DESCRIPTION

This wxWidgets control plots points (e.g. function results) with different 
colors. It automatically scales its output according to the control size.

The points are passed as pairs of coordinates. Points are connected by lines 
when drawn.

The control has been tested on Mac OS X, but should work on other operating
systems (including Windows and Linux) as well.

=head1 METHODS

=over 4

=item C<new>

Passes its arguments to the constructor of wxControl.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    
    $self->{POINTS} = [];
    $self->{SCALED} = [];
    $self->{PEN} = Wx::Pen->new(Wx::Colour->new(0, 0, 0), 1, wxSOLID);
    $self->{COLOURS} = $Default_Colours;
    
    EVT_PAINT($self, \&OnPaint);
    EVT_SIZE($self, \&OnSize);
    
    return $self;
}

=item C<SetPoints($ary1, $ary2, ...)>

Sets the point data. The array referenced by each parameter contains pairs
of coordinates (x, y). 

=cut

sub SetPoints {
    my $self = shift;

    $self->{POINTS} = [ @_ ];

    $self->_FindMinMax();
    $self->ScalePoints();
}

=item C<SetColours($col1, $col2, $col3)>

Sets the colours used to draw the data arrays. Each colours is a reference to an
array that contains three colour values (red, green and blue). The default
colours are C< [[0, 0, 0], [255, 0, 0], [0, 0, 255], [0, 255, 0]]>.
Colours are cycled if you use more data sets than colours.

=cut

sub SetColours {
    my $self = shift;
    
    if ($#_ > -1) {
        $self->{COLOURS} = [ @_ ];
     } else {
        $self->{COLOURS} = $Default_Colours;
     }
}

=item C<ScalePoints()>

Scales the point data according to the control size. Is called automatically
whenever the control is resized and when C<SetPoints> is called, so there should
be no need for you to call it directly.

=cut

sub ScalePoints {
    my $self = shift;

    $self->{SCALED} = [];
    return unless defined $self->{POINTS} && (ref($self->{POINTS}) eq 'ARRAY');

    my ($minX, $minY, $maxX, $maxY) =  
        ($self->{MINX}, $self->{MINY}, $self->{MAXX}, $self->{MAXY});

    return unless defined $minX && defined $minY &&
        defined $maxX && defined $maxY;

    my $size = $self->GetClientSize();
    my ($w, $h) = ($size->GetWidth() - 1, $size->GetHeight() - 1);

    my ($scaleX, $scaleY) = (1, 1);
    
    if ($maxX - $minX != 0) {
        $scaleX = $w / ($maxX - $minX);
    } else {
        $scaleX = 1;
    }
    if ($maxY - $minY != 0) {
        $scaleY = $h / ($maxY - $minY);
    } else {
        $scaleY = 1;
    }
    
    foreach my $p (@{$self->{POINTS}}) {
        push @{$self->{SCALED}},
            [ map { Wx::Point->new(
                  ($_->[0] - $minX) * $scaleX,
                  $h - ($_->[1] - $minY) * $scaleY) } @$p ]; 
    }
    
    return $self->{SCALED};
}

# Search for minimum and maximum values in the data. Called automatically by 
# SetPoints

sub _FindMinMax {
    my $self = shift;
    
    my ($minX, $minY, $maxX, $maxY) = 
        ($self->{MINX}, $self->{MINY}, $self->{MAXX}, $self->{MAXY}) =
            (undef, undef, undef, undef);

    foreach my $p (@{$self->{POINTS}}) {
        for (0..$#$p) {
            $minX = $p->[$_]->[0] if (!defined $minX || $minX > $p->[$_]->[0]);
            $maxX = $p->[$_]->[0] if (!defined $maxX || $maxX < $p->[$_]->[0]);
            $minY = $p->[$_]->[1] if (!defined $minY || $minY > $p->[$_]->[1]);
            $maxY = $p->[$_]->[1] if (!defined $maxY || $maxY < $p->[$_]->[1]);
        }
     }

    ($self->{MINX}, $self->{MINY}, $self->{MAXX}, $self->{MAXY}) =
        ($minX, $minY, $maxX, $maxY);
}

=item C<OnPaint>

Paint handler that draws the points.

=cut

sub OnPaint {
    my ($self, $event) = @_;

    my $dc = Wx::PaintDC->new($self);
            
    return unless defined $self->{SCALED} && ref($self->{SCALED});

    my $colidx = 0;

    foreach (@{$self->{SCALED}}) {
        $self->{PEN}->SetColour(@{$self->{COLOURS}->[$colidx]});
        $dc->SetPen($self->{PEN});
         
        $dc->DrawLines($_);

        $colidx++;
        $colidx = 0
            if ($colidx > $#{$self->{COLOURS}});
    }
}

=item C<OnSize>

Resizing handler that re-scales the points.

=cut

sub OnSize {
    my $self = shift;
    
    $self->ScalePoints();
}

1;
__END__

=back

=head1 SEE ALSO

L<Wx>

WxWidgets L<http://wxwidgets.org/>

=head1 AUTHOR

Christian Renz, E<lt>crenz @ web42.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2005 by Christian Renz E<gt>crenz @ web42.comE<lt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
