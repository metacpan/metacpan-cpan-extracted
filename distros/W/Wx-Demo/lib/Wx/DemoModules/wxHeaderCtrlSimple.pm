#############################################################################
## Name:        lib/Wx/DemoModules/wxHeaderCtrlSimple.pm
## Purpose:     wxPerl demo helper for Wx::HeaderCtrlSimple
## Author:      Mattia Barbon
## Modified by:
## Created:     20/02/2010
## RCS-ID:      $Id: wxHeaderCtrlSimple.pm 2920 2010-04-29 21:11:27Z mbarbon $
## Copyright:   (c) 2010 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxHeaderCtrlSimple;

use strict;
use base qw(Wx::DemoModules::lib::BaseModule Class::Accessor::Fast);

use Wx qw(wxHD_ALLOW_REORDER wxHD_ALLOW_HIDE);
use Wx::Event qw(EVT_HEADER_CLICK EVT_HEADER_DCLICK);

__PACKAGE__->mk_accessors( qw(headerctrl) );

sub styles {
    my( $self ) = @_;

    return ( [ wxHD_ALLOW_REORDER, 'Allow reorder' ],
             [ wxHD_ALLOW_HIDE,    'Allow hide/show' ],
             );
}

sub commands {
    my( $self ) = @_;

    return ( { with_value  => 1,
               label       => 'Append Column',
               action      => sub { my $col = Wx::HeaderColumnSimple->new( $_[0], 100 );
                                    $self->headerctrl->AppendColumn( $col );
                                    $self->GetSizer->Layout; },
               },
               );
}

sub create_control {
    my( $self ) = @_;

    my $headerctrl = Wx::DemoModules::wxHeaderCtrlSimple::Control->new( $self, -1, [-1, -1], [-1, -1], $self->style );
    $headerctrl->AppendColumn( Wx::HeaderColumnSimple->new( 'Column1', 120 ) );
    $headerctrl->AppendColumn( Wx::HeaderColumnSimple->new( 'Column2', 80 ) );
    $headerctrl->AppendColumn( Wx::HeaderColumnSimple->new( 'Column3', 100 ) );

    EVT_HEADER_CLICK( $self, $headerctrl, \&OnClick );
    EVT_HEADER_DCLICK( $self, $headerctrl, \&OnDoubleClick );

    return $self->headerctrl( $headerctrl );
}

sub OnClick {
    my( $self, $event ) = @_;

    Wx::LogMessage( "Column %d clicked",
                    $event->GetColumn );
}

sub OnDoubleClick {
    my( $self, $event ) = @_;

    Wx::LogMessage( "Column %d double clicked",
                    $event->GetColumn );
}

sub add_to_tags { ( Wx::wxVERSION() >= 2.009 ) ? qw(controls new) : () }
sub title { 'wxHeaderCtrlSimple' }

package Wx::DemoModules::wxHeaderCtrlSimple::Control;

use strict;
use base qw(Wx::HeaderCtrlSimple);

# called when the column border is double-clicked to auto-resize
sub GetBestFittingWidth {
    my( $self, $idx ) = @_;

    return 200;
}

1;
