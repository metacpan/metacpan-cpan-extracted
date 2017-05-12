#############################################################################
## Name:        lib/Wx/DemoModules/wxToolBar.pm
## Purpose:     wxPerl demo helper for Wx::ToolBar
## Author:      Mattia Barbon
## Modified by:
## Created:     29/10/2000
## RCS-ID:      $Id: wxToolBar.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2000, 2003, 2005-2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxToolBar;

use strict;
use base qw(Wx::Frame Class::Accessor::Fast);

use Wx qw(:id :textctrl :bitmap :toolbar wxNullBitmap wxDefaultPosition
          wxDefaultSize);
use Wx::Event qw(EVT_SIZE EVT_MENU EVT_COMBOBOX EVT_UPDATE_UI
                 EVT_TOOL_ENTER);

__PACKAGE__->mk_accessors( qw(textctrl small_toolbar horizontal_toolbar) );

my( $ID_TOOLBAR, $ID_COMBO, $ID_QUOTES ) = ( 1 .. 100 );

sub BITMAP($) {
    my( $name ) = @_;
    my $file = Wx::Demo->get_data_file( "xrc/$name.gif" );

    return Wx::Bitmap->new( $file, wxBITMAP_TYPE_GIF );
}

sub new {
    my( $class, $parent ) = @_;
    my $this = $class->SUPER::new( $parent, -1, 'wxToolBar demo' );

    $this->SetIcon( Wx::GetWxPerlIcon );
    my $textctrl = Wx::TextCtrl->new( $this, -1, '', [0, 0], [-1, -1],
                                      wxTE_MULTILINE );
    $this->textctrl( $textctrl );
    $this->small_toolbar( 1 );
    $this->horizontal_toolbar( 1 );

    $this->CreateStatusBar;

    EVT_MENU( $this, -1, \&OnToolLeftClick ); # must be the first bound event

    my $tmenu = Wx::Menu->new;
    EVT_MENU( $this,  $tmenu->AppendCheckItem( -1, "Toggle toolbar" ),
              \&OnToggleToolbar );
    EVT_MENU( $this, $tmenu->AppendCheckItem( -1, "Toggle icon size" ),
              \&OnToggleToolbarSize );
    EVT_MENU( $this, $tmenu->AppendCheckItem( -1, "Toggle orientation" ),
              \&OnToggleToolbarOrient );
    $tmenu->AppendSeparator;
    EVT_MENU( $this, $tmenu->Append( -1, "Insert open button" ),
              \&OnInsertOpen );
    EVT_MENU( $this, $tmenu->Append( -1, "Enable open button" ),
              sub { $_[0]->DoEnableOpen } );
    EVT_MENU( $this, $tmenu->Append( -1, "Delete open button" ),
              sub { $_[0]->DoDeleteOpen } );
    EVT_MENU( $this, $tmenu->Append( -1,  "Toggle quotes button" ),
              sub { $_[0]->DoToggleQuotes } );

    my $menu = Wx::MenuBar->new;
    $menu->Append( $tmenu, 'Toolbar' );
    $this->SetMenuBar( $menu );

    $this->RecreateToolbar;

    EVT_COMBOBOX( $this, $ID_COMBO, \&OnCombo );
    EVT_TOOL_ENTER( $this, $ID_TOOLBAR, \&OnToolEnter );

    return $this;
}

sub OnToggleToolbar {
    my( $this, $event ) = @_;
    my $t = $this->GetToolBar;
    if( $t ) {
        $t->Destroy;
        $this->SetToolBar( undef );
        $this->LayoutChildren;
    } else {
        $this->RecreateToolbar;
    }
}

sub LayoutChildren {
    my( $this ) = @_;
    my $size = $this->GetClientSize;

    $this->textctrl->SetSize( 0, 0, $size->x, $size->y );
}

sub OnToggleToolbarSize {
    my( $this, $event ) = @_;

    $this->small_toolbar( $this->small_toolbar ? 0 : 1 );
    $this->RecreateToolbar;
}

sub OnToggleToolbarOrient {
    my( $this, $event ) = @_;

    $this->horizontal_toolbar( $this->horizontal_toolbar ? 0 : 1 );
    $this->RecreateToolbar;
}

sub OnToolLeftClick {
    my( $this, $event ) = @_;

    $this->textctrl->WriteText( sprintf "Clicked on tool %d\n",
                                $event->GetId );
    if( $event->GetId == $ID_QUOTES ) {
        if( $event->GetExtraLong != 0 ) {
            $this->textctrl->WriteText( "Quotes button down now\n" );
        } else {
            $this->textctrl->WriteText( "Quotes button up now\n" );
        }
    }

    if( $event->GetId == wxID_OPEN ) {
        $this->DoDeleteOpen;
    }
}

sub DoEnableOpen {
    my( $this ) = @_;
    my $t = $this->GetToolBar;
    unless( $t->FindById( wxID_OPEN ) ) {
        $this->textctrl->WriteText( "No tool\n" );
        return;
    }
    $t->EnableTool( wxID_OPEN, !$t->GetToolEnabled( wxID_OPEN ) );
}

sub DoDeleteOpen {
    my( $this ) = @_;
    my $t = $this->GetToolBar;
    unless( $t->FindById( wxID_OPEN ) ) {
        $this->textctrl->WriteText( "No tool\n" );
        return;
    }
    $t->DeleteTool( wxID_OPEN );
}

sub DoToggleQuotes {
    my( $this ) = @_;
    my $t = $this->GetToolBar;

    $t->ToggleTool( $ID_QUOTES, !$t->GetToolState( $ID_QUOTES ) );
}

sub OnInsertOpen {
    my( $this, $event ) = @_;
    my $t = $this->GetToolBar;
    my $bmp = BITMAP( 'fileopen' );
    $t->InsertTool( 0, wxID_OPEN, $bmp, wxNullBitmap,
                    0, undef, 'Delete this tool',
                    'This button was inserted into the toolbar'
                    );
    $t->Realize;
}

sub RecreateToolbar {
    my( $this ) = @_;
    my $t = $this->GetToolBar;
    $t->Destroy if $t;
    $this->SetToolBar( undef );

    my( $style ) =
      ( $this->horizontal_toolbar ? wxTB_HORIZONTAL : wxTB_VERTICAL ) |
        wxNO_BORDER | wxTB_FLAT | wxTB_DOCKABLE;
    $t = $this->CreateToolBar( $style, $ID_TOOLBAR );
    $t->SetMargins( 4, 4 );

    my( @bitmaps ) = map { BITMAP( $_ ) } qw(fileopen filesave fuzzy quotes);
    if( !$this->small_toolbar ) {
        my( $w, $h ) = ( $bitmaps[0]->GetWidth * 2,
                         $bitmaps[0]->GetHeight * 2 );
        @bitmaps =
            map { Wx::Bitmap->new( Wx::Image->new( $_ )->Scale( $w, $h ) ) }
                @bitmaps;
        $t->SetToolBitmapSize( [ $w, $h ] );
    }

    my $width = ( Wx::wxMSW() ) ? 24 : 16;
    $t->AddTool( wxID_SAVE, $bitmaps[1], wxNullBitmap, 0, undef, 'Open File' );
    if( $this->horizontal_toolbar ) {
        my $c = Wx::ComboBox->new
            ( $t, $ID_COMBO, '', wxDefaultPosition, wxDefaultSize,
              [ 'This', 'is a', 'combobox', 'in a', 'toolbar' ] );
        $t->AddControl( $c );
    }
    $t->AddTool( -1, $bitmaps[2], wxNullBitmap, 1, undef,
                     'Toggle button 1' );
    $t->AddSeparator;
    $t->AddTool( $ID_QUOTES, $bitmaps[3], wxNullBitmap, 1, undef,
                 'Toggle button 1' );

    $t->Realize;
}

sub OnCombo {
    my( $this, $event ) = @_;

    Wx::LogStatus( "ComboBox string '%s' selected", $event->GetString );
}

sub OnToolEnter {
    my( $this, $event ) = @_;

    if( $event->GetSelection > -1 ) {
        $this->SetStatusText( sprintf 'This is tool number %d',
                              $event->GetSelection );
    } else {
        $this->SetStatusText( '' );
    }
}

sub add_to_tags { qw(controls) }
sub title { 'wxToolBar' }

1;
