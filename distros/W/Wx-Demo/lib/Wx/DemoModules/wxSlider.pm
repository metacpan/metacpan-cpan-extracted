#############################################################################
## Name:        lib/Wx/DemoModules/wxSlider.pm
## Purpose:     wxPerl demo helper for Wx::Slider
## Author:      Mattia Barbon
## Modified by:
## Created:     13/08/2006
## RCS-ID:      $Id: wxSlider.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2000, 2003, 2005-2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxSlider;

use strict;
use base qw(Wx::DemoModules::lib::BaseModule Class::Accessor::Fast);

use Wx qw(:slider :font wxNOT_FOUND);
use Wx::Event qw(EVT_SLIDER);

__PACKAGE__->mk_accessors( qw(slider) );

sub styles {
    my( $self ) = @_;

    return ( [ wxSL_HORIZONTAL, 'Horizontal' ],
             [ wxSL_VERTICAL, 'Vertical' ],
             [ wxSL_AUTOTICKS, 'Show ticks' ],
             [ wxSL_LABELS, 'Show labels' ],
             );
}

sub commands {
    my( $self ) = @_;

    return ( { with_value  => 1,
               label       => 'Set Value',
               action      => sub { $self->slider->SetValue( $_[0] ) },
               },
             { with_value  => 2,
               label       => 'Set Range',
               action      => sub { $self->slider->SetRange( $_[0], $_[1] ) },
               },
               );
}

sub create_control {
    my( $self ) = @_;

    my $size = [ ( $self->style & wxSL_HORIZONTAL ) ? 200 : -1,
                 ( $self->style & wxSL_VERTICAL ) ? 200 : -1 ];
    my $slider = Wx::Slider->new( $self, -1, 0, 0, 200,
                                  [-1, -1], $size,
                                  $self->style );

    EVT_SLIDER( $self, $slider, \&OnSlider );

    return $self->slider( $slider );
}

sub OnSlider {
    my( $self, $event ) = @_;
    my( $slider ) = $self->slider;

    Wx::LogMessage( join '', 'Event position: ', $event->GetInt );
    Wx::LogMessage( join '', 'Slider position: ', $slider->GetValue );
}

sub add_to_tags { qw(controls) }
sub title { 'wxSlider' }

1;
