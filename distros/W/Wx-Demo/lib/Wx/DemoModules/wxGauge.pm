#############################################################################
## Name:        lib/Wx/DemoModules/wxGauge.pm
## Purpose:     wxPerl demo helper for Wx::Gauge
## Author:      Mattia Barbon
## Modified by:
## Created:     13/08/2006
## RCS-ID:      $Id: wxGauge.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2000, 2003, 2005-2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxGauge;

use strict;
use base qw(Wx::DemoModules::lib::BaseModule Class::Accessor::Fast);

use Wx qw(:gauge :font wxNOT_FOUND);
use Wx::Event qw();

__PACKAGE__->mk_accessors( qw(gauge timer) );

sub create_control {
    my( $self ) = @_;

    my $size = [ ( $self->style & wxGA_HORIZONTAL ) ? 200 : -1,
                 ( $self->style & wxGA_VERTICAL ) ? 200 : -1 ];
    my $gauge = Wx::Gauge->new
      ( $self, -1, 200, [-1, -1], $size, $self->style );
    $self->gauge( $gauge );
}

sub styles {
    my( $self ) = @_;

    return ( [ wxGA_HORIZONTAL, 'Horizontal' ],
             [ wxGA_VERTICAL, 'Vertical' ],
             [ wxGA_SMOOTH, 'Smooth' ],
             );
}

sub commands {
    my( $self ) = @_;

    return ( { with_value  => 1,
               label       => 'Set Value',
               action      => sub { $self->gauge->SetValue( $_[0] ) },
               },
             { with_value  => 1,
               label       => 'Set Range',
               action      => sub { $self->gauge->SetRange( $_[0] ) },
               },
               );
}

sub add_to_tags { qw(controls) }
sub title { 'wxGauge' }

1;
