#############################################################################
## Name:        lib/Wx/DemoModules/wxFlexGridSizer.pm
## Purpose:     wxPerl demo helper for Wx::FlexGridSizer
## Author:      Mattia Barbon
## Modified by:
## Created:     03/07/2002
## RCS-ID:      $Id: wxFlexGridSizer.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2002, 2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxFlexGridSizer;

use strict;
use base qw(Wx::Frame);
use Wx qw(:sizer wxDefaultPosition wxDefaultSize
          wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);

sub new {
    my( $class, $parent ) = @_;
    my $self = $class->SUPER::new( undef, -1, "Wx::FlexGridSizer",
                                   wxDefaultPosition, wxDefaultSize,
                                   wxDEFAULT_DIALOG_STYLE|wxRESIZE_BORDER );

    # top level sizer
    my $tsz = Wx::FlexGridSizer->new( 5, 5, 1, 1, );

    for my $i ( 1 .. 25 ) {
        $tsz->Add( Wx::Button->new( $self, -1, "Button $i" ),
                   0, wxGROW|wxALL, 2 );
    }

    # add growable rows/columns
    $tsz->AddGrowableCol( 1 );
    $tsz->AddGrowableCol( 3 );
    $tsz->AddGrowableRow( 2 );

    # tell we want automatic layout
    $self->SetAutoLayout( 1 );
    $self->SetSizer( $tsz );
    # size the window optimally and set its minimal size
    $tsz->Fit( $self );
    $tsz->SetSizeHints( $self );

    return $self;
}

sub add_to_tags { qw(sizers) }
sub title { 'wxFlexGridSizer' }

1;
