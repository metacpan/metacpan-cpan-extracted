#############################################################################
## Name:        lib/Wx/DemoModules/wxMediaCtrl.pm
## Purpose:     wxPerl demo helper for Wx::MediaCtrl
## Author:      Mattia Barbon
## Modified by:
## Created:     03/04/2006
## RCS-ID:      $Id: wxMediaCtrl.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxMediaCtrl;

use strict;
use base qw(Wx::Panel Class::Accessor::Fast);

use Wx qw(:sizer);
use Wx::Media;
use Wx::Event qw(EVT_MEDIA_LOADED EVT_BUTTON);

__PACKAGE__->mk_ro_accessors( qw(media) );

sub new {
    my( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent, -1 );

    my $media = Wx::MediaCtrl->new( $self, -1, '', [-1,-1], [-1,-1], 0 );
    $self->{media} = $media;

    my $media_load = Wx::Button->new( $self, -1, 'Load a media file' );

    my $sz = Wx::BoxSizer->new( wxVERTICAL );

    $sz->Add( $media, 1, wxGROW );
    $sz->Add( $media_load, 0, wxALL, 5 );

    $media->Show( 1 );
    $media->ShowPlayerControls;

    $self->SetSizer( $sz );

    EVT_MEDIA_LOADED( $self, $media, \&on_media_loaded );
    EVT_BUTTON( $self, $media_load, \&on_media_load );

    return $self;
}

sub on_media_loaded {
    my( $self, $event ) = @_;

    Wx::LogMessage( 'Media loaded, start playback' );
    $self->media->Play;
}

sub on_media_load {
    my( $self, $event ) = @_;

    my $file = Wx::FileSelector( 'Choose a media file' );
    if( length( $file ) ) {
        $self->media->LoadFile( $file );
    }
}

sub add_to_tags { qw(controls) }
sub title { 'wxMediaCtrl' }

defined &Wx::MediaCtrl::new ? 1 : 0;
