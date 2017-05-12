#############################################################################
## Name:        lib/Wx/DemoModules/wxBoxSizer.pm
## Purpose:     wxPerl demo helper for Wx::BoxSizer and Wx::StaticBoxSizer
## Author:      Mattia Barbon
## Modified by:
## Created:     03/07/2002
## RCS-ID:      $Id: wxBoxSizer.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2002, 2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxBoxSizer;

use strict;
use base qw(Wx::Frame);
use Wx qw(:sizer wxDefaultPosition wxDefaultSize
          wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);

sub new {
    my( $class, $parent ) = @_;
    my $self = $class->SUPER::new( undef, -1, "Wx::BoxSizer",
                                   wxDefaultPosition, wxDefaultSize,
                                   wxDEFAULT_DIALOG_STYLE|wxRESIZE_BORDER );

    # top level sizer
    my $tsz = Wx::BoxSizer->new( wxVERTICAL );

    my $fr = Wx::BoxSizer->new( wxHORIZONTAL );
    # this button is fixed size, with some border
    $fr->Add( Wx::Button->new( $self, -1, 'Button 1' ),
              0, wxALL, 10 );
    # this button has no border
    $fr->Add( Wx::Button->new( $self, -1, 'Button 2' ), 0, 0 );
    # this one has borders just on the top and bottom
    $fr->Add( Wx::Button->new( $self, -1, 'Button 3' ), 0, wxTOP|wxBOTTOM, 5 );

    # first row can grow vertically, and horizontally
    $tsz->Add( $fr, 1, wxGROW );
    # second row is just some space
    $tsz->Add( 10, 10, 0, wxGROW );

    my $sr = Wx::BoxSizer->new( wxHORIZONTAL );
    # these elements compete for the available horizontal space
    $sr->Add( Wx::Button->new( $self, -1, 'Button 1' ), 1, wxALL, 5 );
    $sr->Add( Wx::Button->new( $self, -1, 'Button 2' ), 1, wxGROW|wxALL, 5 );
    # sizers can be arbitrarily nested
    my $nsz = Wx::StaticBoxSizer->new( Wx::StaticBox->new
                                       ( $self, -1, 'Wx::StaticBoxSizer' ),
                                       wxVERTICAL );
    $nsz->Add( Wx::Button->new( $self, -1, 'Button 3' ), 1, wxGROW|wxALL, 5 );
    $nsz->Add( Wx::Button->new( $self, -1, 'Button 4' ), 1, wxGROW|wxALL, 5 );
    $sr->Add( $nsz, 2, wxGROW );

    # add third row
    $tsz->Add( $sr, 1, wxGROW );

    # tell we want automatic layout
    $self->SetAutoLayout( 1 );
    $self->SetSizer( $tsz );
    # size the window optimally and set its minimal size
    $tsz->Fit( $self );
    $tsz->SetSizeHints( $self );

    return $self;
}

sub add_to_tags { qw(sizers) }
sub title { 'wxBoxSizer' }

1;
