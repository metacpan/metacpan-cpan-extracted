#############################################################################
## Name:        lib/Wx/DemoModules/wxScrollBar.pm
## Purpose:     wxPerl demo helper for Wx::ScrollBar
## Author:      Mattia Barbon
## Modified by:
## Created:     27/05/2003
## RCS-ID:      $Id: wxScrollBar.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2003, 2005-2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxScrollBar;

use strict;
use base qw(Wx::DemoModules::lib::BaseModule Class::Accessor::Fast);
use Wx qw(:sizer :scrollbar wxWHITE wxHORIZONTAL wxVERTICAL);
use Wx::Event qw(/EVT_SCROLL_*/ EVT_BUTTON);

__PACKAGE__->mk_accessors( qw(scrollbar) );

sub log_scroll_event {
    my( $event, $type ) = @_;

    Wx::LogMessage( 'Scroll %s event: orientation = %s, position = %d', $type,
                    ( $event->GetOrientation == wxHORIZONTAL ) ? 'horizontal' :
                                                                 'vertical',
                    $event->GetPosition );

    # important! skip event for default processing to happen
    $event->Skip;
}

sub styles {
    my( $self ) = @_;

    return ( [ wxSB_HORIZONTAL, 'Horizontal' ],
             [ wxSB_VERTICAL, 'Vertical' ],
             );
}

sub commands { 1 }

sub add_commands {
    my( $self, $sizer ) = @_;

    my $szpos = Wx::BoxSizer->new( wxHORIZONTAL );
    my $szthumb = Wx::BoxSizer->new( wxHORIZONTAL );
    my $szrange = Wx::BoxSizer->new( wxHORIZONTAL );
    my $szpagesz = Wx::BoxSizer->new( wxHORIZONTAL );

    my $vpos = Wx::TextCtrl->new( $self, -1, '0' );
    my $vthumb = Wx::TextCtrl->new( $self, -1, '15' );
    my $vrange = Wx::TextCtrl->new( $self, -1, '100' );
    my $vpagesz = Wx::TextCtrl->new( $self, -1, '10' );

    $szpos->Add( Wx::StaticText->new( $self, -1, 'Position' ),
                 1, wxALL, 3 );
    $szpos->Add( $vpos, 1, wxALL, 3 );
    $szthumb->Add( Wx::StaticText->new( $self, -1, 'Thumb size' ),
                   1, wxALL, 3 );
    $szthumb->Add( $vthumb, 1, wxALL, 3 );
    $szrange->Add( Wx::StaticText->new( $self, -1, 'Range' ),
                   1, wxALL, 3 );
    $szrange->Add( $vrange, 1, wxALL, 3 );
    $szpagesz->Add( Wx::StaticText->new( $self, -1, 'Page size' ),
                    1, wxALL, 3 );
    $szpagesz->Add( $vpagesz, 1, wxALL, 3 );

    my $doit = Wx::Button->new( $self, -1, 'Set values' );
    EVT_BUTTON( $self, $doit, sub {
                    $self->scrollbar->SetScrollbar( $vpos->GetValue,
                                                    $vthumb->GetValue,
                                                    $vrange->GetValue,
                                                    $vpagesz->GetValue );
                } );

    $sizer->Add( $szpos, 0, wxGROW );
    $sizer->Add( $szthumb, 0, wxGROW );
    $sizer->Add( $szrange, 0, wxGROW );
    $sizer->Add( $szpagesz, 0, wxGROW );
    $sizer->Add( $doit, 0, wxGROW );
}

sub create_control {
    my( $self ) = @_;

    my $size = [ ( $self->style & wxSB_HORIZONTAL ) ? 200 : -1,
                 ( $self->style & wxSB_VERTICAL ) ? 200 : -1 ];
    my $scrollbar = Wx::ScrollBar->new
      ( $self, -1, [ -1, -1 ], $size,
        $self->style );

    $scrollbar->SetScrollbar( 0, 15, 100, 10 );

    EVT_SCROLL_TOP( $scrollbar,
                    sub { log_scroll_event( $_[1], 'to top' ) } );
    EVT_SCROLL_BOTTOM( $scrollbar,
                       sub { log_scroll_event( $_[1], 'to bottom' ) } );
    EVT_SCROLL_LINEUP( $scrollbar,
                       sub { log_scroll_event( $_[1], 'a line up' ) } );
    EVT_SCROLL_LINEDOWN( $scrollbar,
                         sub { log_scroll_event( $_[1], 'a line down' ) } );
    EVT_SCROLL_PAGEUP( $scrollbar,
                       sub { log_scroll_event( $_[1], 'a page up' ) } );
    EVT_SCROLL_PAGEDOWN( $scrollbar,
                         sub { log_scroll_event( $_[1], 'a page down' ) } );
#    EVT_SCROLL_THUMBTRACK( $scrollbar,
#                           sub { log_scroll_event( $_[1], 'thumbtrack' ) } );
    EVT_SCROLL_THUMBRELEASE( $scrollbar,
                             sub { log_scroll_event( $_[1], 'thumbrelease' ) } );

    return $self->scrollbar( $scrollbar );
}

sub add_to_tags { qw(controls) }
sub title { 'wxScrollBar' }

1;
