#############################################################################
## Name:        lib/Wx/DemoModules/wxDocView.pm
## Purpose:     Document/View demo
## Author:      Simon Flack
## Modified by:
## Created:     28/08/2002
## RCS-ID:      $Id: wxDocView.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2002, 2005-2007 Simon Flack and Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

use Wx 0.70;
use Wx::DocView;
use Wx::MDI;

package Wx::DemoModules::wxDocView;

use strict;
use base qw(Wx::DocMDIParentFrame Class::Accessor::Fast);

use Wx qw(:docview :frame :misc :toolbar :bitmap :id);

__PACKAGE__->mk_accessors( qw(manager) );

our $THE_FRAME;

sub _bitmap($) {
    my $file = shift;

    my $rel_path = File::Spec->catfile( 'docview', "$file.xpm" );
    my $abs_path = Wx::Demo->get_data_file( $rel_path );
    return Wx::Bitmap->new( $abs_path, wxBITMAP_TYPE_XPM );
}

sub new {
    my( $class, $parent ) = @_;

    # Create a document manager and load a document template
    my $manager = Wx::DemoModules::wxDocView::DocManager->new( wxDOC_MDI );
    Wx::DocTemplate->new( $manager, "Text Files",
                          "*.txt", "", "txt", "Text Document",
                          "Text View",
                          "Wx::DemoModules::wxDocView::Document",
                          "Wx::DemoModules::wxDocView::View",
                          1 );

    # Create the parent frame. For this app, we'll use MDI
    # We get a "Window" menu for free under MSW.
    # You can turn that off with
    # wxFRAME_NO_WINDOW_MENU flag
    my $self = $class->SUPER::new( $manager, undef, -1, 'Doc/View demo' );
    $self->manager( $manager );

    $self->SetIcon( Wx::GetWxPerlIcon() );

    my $file_menu = Wx::Menu->new;
    my $edit_menu = Wx::Menu->new;

    # Using these special contants will automatically use the doc/view
    $file_menu->Append( wxID_NEW, "&New\tCtrl+N" );
    $file_menu->Append( wxID_OPEN, "&Open\tCtrl+O" );
    $file_menu->Append( wxID_SAVE, "&Save\tCtrl+S" );
    $file_menu->Append( wxID_SAVEAS, "Save &As" );
    $file_menu->Append( wxID_CLOSE, "&Close\tCtrl+W" );
    $file_menu->AppendSeparator;
    $file_menu->Append( wxID_PRINT, "&Print\tCtrl+P" );
    $file_menu->Append( wxID_PRINT_SETUP, "Print Set&up" );
    $file_menu->Append( wxID_PREVIEW, "Print Pre&view" );
    $file_menu->Append( wxID_EXIT, "E&xit" );

    $self->manager->FileHistoryUseMenu( $file_menu );

    $edit_menu->Append( wxID_UNDO, "&Undo\tCtrl+Z" );
    $edit_menu->Append( wxID_REDO, "&Redo\tCtrl+R" );
    $edit_menu->AppendSeparator;

    my $menu_bar = Wx::MenuBar->new;
    $menu_bar->Append( $file_menu, "&File" );
    $menu_bar->Append( $edit_menu, "&Edit" );

    $self->SetMenuBar( $menu_bar );

    my $toolbar = $self->CreateToolBar( wxTB_HORIZONTAL | wxNO_BORDER |
                                        wxTB_FLAT | wxTB_DOCKABLE, 5050 );
    $toolbar->AddTool( wxID_NEW, '', _bitmap('new'), 'New File' );
    $toolbar->AddTool( wxID_OPEN, '', _bitmap('open'), 'Open File' );
    $toolbar->AddTool( wxID_CLOSE, '', _bitmap('help'), 'Close File' );
    $toolbar->AddTool( wxID_SAVE, '', _bitmap('save'), 'Toggle button 1' );
    $toolbar->AddTool( wxID_COPY, '', _bitmap('copy'), 'Toggle button 1' );
    $toolbar->AddTool( wxID_CUT, '', _bitmap('cut'), 'Toggle button 1' );
#    $toolbar->AddTool( wxID_PASTE, '', _bitmap('paste'), 'Toggle button 1' );
    $toolbar->AddTool( wxID_PRINT, '', _bitmap('print'), 'Toggle button 1' );

    $toolbar->AddSeparator;
    $toolbar->Realize;

    $THE_FRAME = $self;

    return $self;
}

sub CreateChildFrame {
    my( $self, $doc, $view, $flags ) = @_;

    # Get the filename for the window title
    my $filename = $doc->GetFilename;

    my $child_frame = new Wx::DocMDIChildFrame
      ( $doc, $view, $self, -1, $filename, [10,10], [300,300],
        wxDEFAULT_FRAME_STYLE | wxMAXIMIZE );
    $child_frame->Show;

    return $child_frame;
}

sub add_to_tags { qw(misc) }
sub title { 'Document/View' }

package Wx::DemoModules::wxDocView::DocManager;

use strict;
use base qw(Wx::DocManager);

# The default wxWidgets untitled name is "unnamedN"
# (where N is a number)
# It's a bit ugly, and you can customise it...
my $unnamed_doc_count = 0;

sub MakeDefaultName {
    my( $docmgr, $name ) = @_;

    return "Untitled" . ++$unnamed_doc_count;
}

package Wx::DemoModules::wxDocView::Document;

use strict;
use base qw(Wx::Document);

sub OnSaveDocument {
    my( $doc, $filename ) = @_;
    my $view = $doc->GetFirstView;
    $view->Activate( 0 );

    return unless $view->{editor}->SaveFile( $filename );

    $doc->Modify( 0 );
    $view->Activate( 1 );

    return 1;
}

sub OnOpenDocument {
    my( $doc, $filename ) = @_;
    my $view = $doc->GetFirstView;

    return 0 unless $view->{editor}->LoadFile( $filename );

    $doc->UpdateAllViews;
    $doc->Modify( 0 );

    return 1;
}

# This is called internally to see if the document has been modified
# since it was last saved.
sub IsModified {
    my( $doc ) = @_;

    my $view = $doc->GetFirstView;

    if( defined $view->{editor} ) {
        return $view->{editor}->IsModified;
    }

    return;
}

package Wx::DemoModules::wxDocView::View;

use strict;
use base qw(Wx::View);

use Wx qw(wxTE_MULTILINE wxDefaultPosition wxDefaultSize);

sub OnCreate {
    my( $view, $doc, $flags )  = @_;

    my $child_frame = $Wx::DemoModules::wxDocView::THE_FRAME
                        ->CreateChildFrame( $doc, $view );
    $view->{editor} = new Wx::TextCtrl( $child_frame, -1, "", [0,0],
                                        [200,300], wxTE_MULTILINE );
    $child_frame->Show;
    $view->Activate( 1 );

    return 1;
}

sub OnClose {
    my( $view, $deletewindow ) = @_;

    if( $deletewindow ) {
        $view->{editor}->Hide;
        delete $view->{editor};
        $view->GetFrame->Destroy;
    } else {
        $view->GetDocument->Close;
    }

    $view->Activate( 0 );

    return 1;
}

1;

