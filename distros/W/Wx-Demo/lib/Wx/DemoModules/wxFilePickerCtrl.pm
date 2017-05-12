#############################################################################
## Name:        lib/Wx/DemoModules/wxFilePickerCtrl.pm
## Purpose:     wxPerl demo helper for Wx::FilePickerCtrl
## Author:      Mattia Barbon
## Modified by:
## Created:     01/11/2006
## RCS-ID:      $Id: wxFilePickerCtrl.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxFilePickerCtrl;

use strict;
use base qw(Wx::DemoModules::lib::BaseModule Class::Accessor::Fast);

use Wx::Event qw(EVT_FILEPICKER_CHANGED);

__PACKAGE__->mk_accessors( qw(picker) );

=pod

sub commands {
    my( $self ) = @_;

    return ( { label       => 'Set italic font',
               action      => sub { $self->picker->SetFile( wxITALIC_FONT ) },
               },
               );
}

=cut

sub create_control {
    my( $self ) = @_;

    my $fp = Wx::FilePickerCtrl->new( $self, -1, "", "Choose a File",
                 "BMP and GIF files (*.bmp;*.gif)|*.bmp;*.gif|All files|*.*",
                                      [-1, -1], [-1, -1], $self->style );
    EVT_FILEPICKER_CHANGED( $self, $fp, \&on_change );

    return $self->picker( $fp );
}

sub on_change {
    my( $self, $event ) = @_;

    Wx::LogMessage( "File changed (%s)", $event->GetPath );
}

sub tags { [ 'controls/picker' => 'Picker controls' ] }
sub add_to_tags { qw(controls/picker) }
sub title { 'wxFilePickerCtrl' }

defined &Wx::FilePickerCtrl::new ? 1 : 0;
