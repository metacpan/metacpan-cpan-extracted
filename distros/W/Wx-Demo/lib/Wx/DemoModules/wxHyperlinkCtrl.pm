#############################################################################
## Name:        lib/Wx/DemoModules/wxHyperlinkCtrl.pm
## Purpose:     wxPerl demo helper for Wx::HyperlinkCtrl
## Author:      Mattia Barbon
## Modified by:
## Created:     26/08/2007
## RCS-ID:      $Id: wxHyperlinkCtrl.pm 2812 2010-02-20 10:53:40Z mbarbon $
## Copyright:   (c) 2007 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxHyperlinkCtrl;

use strict;
use base qw(Wx::DemoModules::lib::BaseModule Class::Accessor::Fast);

use Wx qw(:hyperlink);
use Wx::Event qw();

__PACKAGE__->mk_accessors( qw(hyperlink) );

# fixed in wxPerl 0.78
sub EVT_HYPERLINK($$$) { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_COMMAND_HYPERLINK, $_[2] ) }

sub styles {
    my( $self ) = @_;

    return ( [ wxHL_ALIGN_LEFT, 'Left' ],
             [ wxHL_ALIGN_CENTRE, 'Center' ],
             [ wxHL_ALIGN_RIGHT, 'Right' ],
             [ wxHL_CONTEXTMENU, 'Context menu' ],
             );
}

sub commands {
    my( $self ) = @_;

    return ( { label       => 'Set label',
               with_value  => 1,
               action      => sub { $self->hyperlink->SetLabel( $_[0] ) },
               },
             { label       => 'Set URL',
               with_value  => 1,
               action      => sub { $self->hyperlink->SetURL( $_[0] ) },
               },
               );
}

sub create_control {
    my( $self ) = @_;

    my $hl = Wx::HyperlinkCtrl->new( $self, -1, 'Hyperlink',
                                     'http://wxperl.eu/', [-1, -1],
                                     [200, -1], $self->style );

    EVT_HYPERLINK( $self, $hl, sub {
                       Wx::LogMessage( "Clicked URL '%s'", $_[1]->GetURL );
                   } );

    return $self->hyperlink( $hl );
}

sub add_to_tags { qw(controls) }
sub title { 'wxHyperlinkCtrl' }

1;
