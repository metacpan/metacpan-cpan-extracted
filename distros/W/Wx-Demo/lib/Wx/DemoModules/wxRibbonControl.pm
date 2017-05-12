#############################################################################
## Name:        lib/Wx/DemoModules/wxRibbonControl.pm
## Purpose:     wxPerl demo helper for Wx::Ribbon
## Author:      Mark Dootson
## Modified by:
## Created:     03/03/2012
## SVN-ID:      $Id: wxRibbonControl.pm 3341 2012-09-14 09:18:34Z mdootson $
## Copyright:   (c) 2012 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################
#
# based on the wxWidgets ribbon sample (C) Copyright 2009, Peter Cawley
#
# wrapped for wxWidgets ge 2.9.3
#
#############################################################################

package Wx::DemoModules::wxRibbonControl;
use strict;
use Wx;
use Wx::Ribbon;
use Wx qw( :ribbon :ribbonart :sizer :id :misc :colour );
use base qw( Wx::Panel );
use Wx::Event qw( EVT_TOGGLEBUTTON EVT_MENU );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new($_[0], -1);
    
    $self->{menuids} = {
        position_left_labels => Wx::NewId(),
        position_left_both => Wx::NewId(),
        position_top_icons => Wx::NewId(),
        position_top_both => Wx::NewId(),
    };
    
    $self->{ribbonbar} = Wx::DemoModules::wxRibbonControl::RibbonBar->new($self);
    
    my $togglepanels =  Wx::ToggleButton->new($self, wxID_ANY, "&Toggle panels");
    $togglepanels->SetValue(1);
    $self->{togglepanels} = $togglepanels;
    
    
    EVT_TOGGLEBUTTON($self, $togglepanels, sub { shift->OnTogglePanels( @_ ) } );
    
    EVT_MENU($self, $self->{menuids}->{position_left}, sub { shift->OnPositionLeftIcons( @_ ) } );
    EVT_MENU($self, $self->{menuids}->{position_top}, sub { shift->OnPositionTopLabels( @_ ) } );
    EVT_MENU($self, $self->{menuids}->{position_left_labels}, sub { shift->OnPositionLeftLabels( @_ ) } );
    EVT_MENU($self, $self->{menuids}->{position_left_both}, sub { shift->OnPositionLeftBoth( @_ ) } );
    EVT_MENU($self, $self->{menuids}->{position_top_icons}, sub { shift->OnPositionTopIcons( @_ ) } );
    EVT_MENU($self, $self->{menuids}->{position_top_both}, sub { shift->OnPositionTopBoth( @_ ) } );
    
    my $mainsizer = Wx::BoxSizer->new(wxVERTICAL);
    $mainsizer->Add($self->{ribbonbar}, 0, wxEXPAND);
    $mainsizer->Add($togglepanels, 0);
    $self->SetSizer($mainsizer);
    return $self;
}

sub add_to_tags { qw(controls new ) }
sub title { 'wxRibbonControl' }

sub SetBarStyle {
    my ($self, $style) = @_;
    my $ribbon = $self->{ribbonbar};
    $ribbon->Freeze();
    $ribbon->SetWindowStyleFlag($style);
    my $toolbar = $ribbon->{maintoolbar};
    
    my $topsizer = $self->GetSizer;
    
    if($style & wxRIBBON_BAR_FLOW_VERTICAL)
    {
        $ribbon->SetTabCtrlMargins(10, 10);
        $topsizer->SetOrientation(wxHORIZONTAL);
        $toolbar->SetRows(3, 5) if $toolbar;
    }
    else
    {
        $ribbon->SetTabCtrlMargins(50, 20);
        $topsizer->SetOrientation(wxVERTICAL);
        $toolbar->SetRows(2, 3);
    }
    $ribbon->Realize();
    $self->Layout();
    $ribbon->Thaw();
    $self->Refresh();
}

sub OnHoveredColourChange {
    my ($self, $event) = @_;
    
    ## Set the background of the gallery to the hovered colour, or back to the
    ## default if there is no longer a hovered item.
    
    my $ribbon = $self->{ribbonbar};
    my $gallery = $event->GetGallery;
    my $provider = $gallery->GetArtProvider();
    
    if( my $gitem = $event->GetGalleryItem() ) {
        if( $provider == $ribbon->GetArtProvider() )
        {
            $provider = $provider->Clone();
            $gallery->SetArtProvider($provider);
        }
        my $clientdata = $ribbon->GetGalleryColour( $gallery, $gitem );
        $provider->SetColour(wxRIBBON_ART_GALLERY_HOVER_BACKGROUND_COLOUR, $clientdata->{colour});
            
    } else {
        if( $provider != $ribbon->GetArtProvider())
        {
            $gallery->SetArtProvider( $ribbon->GetArtProvider() );
        }
    }
}

sub OnPrimaryColourSelect {
    my ($self, $event) = @_;
    my $ribbon = $self->{ribbonbar};
    my $clientdata = $ribbon->GetGalleryColour($event->GetGallery(), $event->GetGalleryItem());
    Wx::LogMessage('Colour "%s" selected as primary', $clientdata->{name});
    my( $primary, $secondary, $tertiary ) = $ribbon->GetArtProvider->GetColourScheme();
    $ribbon->GetArtProvider->SetColourScheme( $clientdata->{colour}, $secondary, $tertiary );
    $self->ResetGalleryArtProviders();
    $ribbon->Refresh();
}

sub OnSecondaryColourSelect {
    my ($self, $event) = @_;
    my $ribbon = $self->{ribbonbar};
    my $clientdata = $ribbon->GetGalleryColour($event->GetGallery(), $event->GetGalleryItem());
    Wx::LogMessage('Colour "%s" selected as secondary', $clientdata->{name});
    my( $primary, $secondary, $tertiary ) = $ribbon->GetArtProvider->GetColourScheme();
    $ribbon->GetArtProvider->SetColourScheme($primary, $clientdata->{colour}, $tertiary );
    $self->ResetGalleryArtProviders();
    $ribbon->Refresh();
}

sub ResetGalleryArtProviders {
    my ( $self ) = @_;
    my $ribbon = $self->{ribbonbar};
    my $primaryartprovider = $ribbon->{primary_gallery}->GetArtProvider();
    my $secondaryartprovider = $ribbon->{secondary_gallery}->GetArtProvider();
    
    if( $primaryartprovider != $ribbon->GetArtProvider()) {
        Wx::LogMessage('Resetting primary gallery art provider');
        $ribbon->{primary_gallery}->SetArtProvider($ribbon->GetArtProvider());
    }
    
    if( $secondaryartprovider != $ribbon->GetArtProvider()) {
        Wx::LogMessage('Resetting secondary gallery art provider');
        $ribbon->{secondary_gallery}->SetArtProvider($ribbon->GetArtProvider());
    }
}

sub OnSelectionExpandHButton {
	my ( $self, $event ) = @_;
    Wx::LogMessage('Expand selection horizontally button clicked.');
}

sub OnSelectionExpandVButton {
	my ( $self, $event ) = @_;
    Wx::LogMessage('Expand selection vertically button clicked.');
}

sub OnSelectionContractButton {
	my ( $self, $event ) = @_;
    Wx::LogMessage('Contract selection button clicked.');
}

sub OnCircleButton {
	my ( $self, $event ) = @_;
    Wx::LogMessage('Circle button clicked.');
}

sub OnCrossButton {
	my ( $self, $event ) = @_;
    Wx::LogMessage('Cross button clicked.');
}

sub OnTriangleButton {
	my ( $self, $event ) = @_;
    Wx::LogMessage('Triangle button clicked.');
}

sub OnSquareButton {
	my ( $self, $event ) = @_;
    Wx::LogMessage('Square button clicked.');
}

sub OnTriangleDropdown {
	my ( $self, $event ) = @_;
	my $menu = Wx::Menu->new();
    $menu->Append(wxID_ANY, "Equilateral");
    $menu->Append(wxID_ANY, "Isosceles");
    $menu->Append(wxID_ANY, "Scalene");
    $event->PopupMenu($menu);
}

sub OnPolygonDropdown {
    my ( $self, $event ) = @_;
    my $menu = Wx::Menu->new();
    $menu->Append(wxID_ANY, "Pentagon (5 sided)");
    $menu->Append(wxID_ANY, "Hexagon (6 sided)");
    $menu->Append(wxID_ANY, "Heptagon (7 sided)");
    $menu->Append(wxID_ANY, "Octagon (8 sided)");
    $menu->Append(wxID_ANY, "Nonagon (9 sided)");
    $menu->Append(wxID_ANY, "Decagon (10 sided)");
    $event->PopupMenu($menu);
}

sub OnNew {
	my ( $self, $event ) = @_;
    Wx::LogMessage('New button clicked.');
}

sub OnNewDropdown {
    my ( $self, $event ) = @_;
    my $menu = Wx::Menu->new();
    $menu->Append(wxID_ANY, "New Document");
    $menu->Append(wxID_ANY, "New Template");
    $menu->Append(wxID_ANY, "New Mail");
    $event->PopupMenu($menu);
}

sub OnPrint {
	my ( $self, $event ) = @_;
    Wx::LogMessage('Print button clicked.');
}

sub OnPrintDropdown {
    my ( $self, $event ) = @_;
	my $menu = Wx::Menu->new();
    $menu->Append(wxID_ANY, "Print");
    $menu->Append(wxID_ANY, "Preview");
    $menu->Append(wxID_ANY, "Options");
    $event->PopupMenu($menu);
}

sub OnRedoDropdown {
    my ( $self, $event ) = @_;
	my $menu = Wx::Menu->new();
    $menu->Append(wxID_ANY, "Redo E");
    $menu->Append(wxID_ANY, "Redo F");
    $menu->Append(wxID_ANY, "Redo G");
    $event->PopupMenu($menu);
}

sub OnUndoDropdown {
    my ( $self, $event ) = @_;
	my $menu = Wx::Menu->new();
    $menu->Append(wxID_ANY, "Undo E");
    $menu->Append(wxID_ANY, "Undo F");
    $menu->Append(wxID_ANY, "Undo G");
    $event->PopupMenu($menu);
}


sub OnPositionTopLabels {
	my ( $self, $event ) = @_;
    $self->SetBarStyle(wxRIBBON_BAR_DEFAULT_STYLE);
}

sub OnPositionTopIcons {
	my ( $self, $event ) = @_;
	my $style = wxRIBBON_BAR_SHOW_PAGE_ICONS | ( wxRIBBON_BAR_DEFAULT_STYLE() & ~wxRIBBON_BAR_SHOW_PAGE_LABELS );
    $self->SetBarStyle( $style );
}

sub OnPositionTopBoth {
	my ( $self, $event ) = @_;
    $self->SetBarStyle(wxRIBBON_BAR_DEFAULT_STYLE | wxRIBBON_BAR_SHOW_PAGE_ICONS);
}

sub OnPositionLeftLabels {
	my ( $self, $event ) = @_;
    $self->SetBarStyle(wxRIBBON_BAR_DEFAULT_STYLE | wxRIBBON_BAR_FLOW_VERTICAL);
}

sub OnPositionLeftIcons {
	my ( $self, $event ) = @_;
    $self->SetBarStyle((wxRIBBON_BAR_DEFAULT_STYLE() & ~wxRIBBON_BAR_SHOW_PAGE_LABELS) |
        wxRIBBON_BAR_SHOW_PAGE_ICONS | wxRIBBON_BAR_FLOW_VERTICAL);
}

sub OnPositionLeftBoth {
	my ( $self, $event ) = @_;
    $self->SetBarStyle(wxRIBBON_BAR_DEFAULT_STYLE | wxRIBBON_BAR_SHOW_PAGE_ICONS |
        wxRIBBON_BAR_FLOW_VERTICAL);
}

sub OnPositionTop { $_[0]->OnPositionTopLabels( $_[1] ) }

sub OnPositionTopDropdown {
    my ( $self, $event ) = @_;
	my $menu = Wx::Menu->new();
    $menu->Append($self->{menuids}->{position_top}, "Top with Labels");
    $menu->Append($self->{menuids}->{position_top_icons}, "Top with Icons");
    $menu->Append($self->{menuids}->{position_top_both}, "Top with Both");
    $event->PopupMenu($menu);
}

sub OnPositionLeft { $_[0]->OnPositionLeftIcons( $_[1] ) }

sub OnPositionLeftDropdown {
    my ( $self, $event ) = @_;
	my $menu = Wx::Menu->new();
    $menu->Append($self->{menuids}->{position_left}, "Left with Icons");
    $menu->Append($self->{menuids}->{position_left_labels}, "Left with Labels");
    $menu->Append($self->{menuids}->{position_left_both}, "Left with Both");
    $event->PopupMenu($menu);
}

sub OnTogglePanels {
    my ( $self, $event ) = @_;
    $self->{ribbonbar}->ShowPanels($self->{togglepanels}->GetValue());
}

sub OnColourGalleryButton {
    my ( $self, $event ) = @_;
	my $gallery = $event->GetEventObject;
	return if !$gallery;
    
	my $ribbon = $self->{ribbonbar};
	
    $ribbon->DismissExpandedPanel();
	my $colourinfo;
    if( my $selection = $gallery->GetSelection() ) {
		$colourinfo = $ribbon->GetGalleryColour( $gallery, $selection );
	}
	
	my $colourdata = Wx::ColourData->new;
    $colourdata->SetChooseFull( 1 );
	$colourdata->SetColour( $colourinfo->{colour} ) if $colourinfo;

	my $dialog = Wx::ColourDialog->new( $self, $colourdata );

    if( $dialog->ShowModal == wxID_OK ) {
	
        $colourdata = $dialog->GetColourData();
        my $newcolour = $colourdata->GetColour();

        ## Try to find colour in gallery
		my $item;
        for ( my $i = 0; $i < $gallery->GetCount; $i++ )        {
            $item = $gallery->GetItem($i);
			my $cinfo = $ribbon->GetGalleryColour($gallery, $item);
            if( $cinfo->{colour} == $newcolour ) {
				last;
			} else {
				$item = undef;
			}
        }

        ## Colour not in gallery - add it
        if( !$item ) {
            $item = $ribbon->AddColourToGallery($gallery, $newcolour->GetAsString(wxC2S_HTML_SYNTAX), $ribbon->{bitmapcreation_dc}, $newcolour);
            $gallery->Realize();
        }

        ## Set selection
        $gallery->EnsureVisible($item);
        $gallery->SetSelection($item);

        ## Send an event to respond to the selection change
		my $dummy = Wx::RibbonGalleryEvent->new( wxEVT_COMMAND_RIBBONGALLERY_SELECTED, $gallery->GetId );
        $dummy->SetEventObject($gallery);
        $dummy->SetGallery($gallery);
        $dummy->SetGalleryItem($item);
        $gallery->ProcessEvent($dummy);
    }
	
	$dialog->Destroy;
}

sub OnDefaultProvider {
	my ( $self, $event ) = @_;
    Wx::LogMessage('OnDefaultProvider Called');
    $self->{ribbonbar}->DismissExpandedPanel();
	
    $self->set_main_artprovider( Wx::RibbonDefaultArtProvider->new() );
}

sub OnAUIProvider {
	my ( $self, $event ) = @_;
    Wx::LogMessage('OnAUIProvider Called');
	$self->{ribbonbar}->DismissExpandedPanel();
    $self->set_main_artprovider( Wx::RibbonAUIArtProvider->new() );
}

sub OnMSWProvider {
	my ( $self, $event ) = @_;
    Wx::LogMessage('OnMSWProvider Called');
	$self->{ribbonbar}->DismissExpandedPanel();
    $self->set_main_artprovider( Wx::RibbonMSWArtProvider->new() );
}

sub set_main_artprovider {
	my ( $self, $provider ) = @_;
	my $ribbon = $self->{ribbonbar};
    
	#$ribbon->Freeze();
	
    $ribbon->SetArtProvider( $provider->Clone );
	
	$self->ResetGalleryArtProviders;

    my($primary, $secondary, $tertiary) = $provider->GetColourScheme();

    $ribbon->PopulateColoursPanel($ribbon->{primary_panel},   $primary,   $ribbon->{primary_id} );
    $ribbon->PopulateColoursPanel($ribbon->{secondary_panel}, $secondary, $ribbon->{secondary_id} );

    $ribbon->Realize();
    #$ribbon->Thaw();
    $self->GetSizer->Layout;
	$self->Refresh;
}

#-------------------------------------------------------------------------------------

package Wx::DemoModules::wxRibbonControl::RibbonBar;

#-------------------------------------------------------------------------------------

use strict;
use Wx::Ribbon;
use Wx qw( :ribbon :ribbonart :id :bitmap :misc :combobox :sizer :font :pen :colour :brush);
use base qw( Wx::RibbonBar );
use Wx::ArtProvider qw( :clientid :artid );
use Wx::Event qw(
    EVT_RIBBONBUTTONBAR_CLICKED EVT_RIBBONBUTTONBAR_DROPDOWN_CLICKED EVT_RIBBONGALLERY_HOVER_CHANGED
	EVT_RIBBONGALLERY_SELECTED EVT_RIBBONTOOLBAR_CLICKED EVT_RIBBONTOOLBAR_DROPDOWN_CLICKED
	EVT_BUTTON EVT_TOGGLEBUTTON EVT_MENU
	);

sub new {
	my ($class, $parent) = @_;
	my $self = $class->SUPER::new($parent, wxID_ANY);
		
	$self->{bitmapcreation_dc} = Wx::MemoryDC->new;
		
	my $page = Wx::RibbonPage->new($self, wxID_ANY, 'Examples', _loadxpm('ribbon' ) );
	
	my $tbpanel = Wx::RibbonPanel->new( $page, wxID_ANY, 'Toolbar', wxNullBitmap,
			wxDefaultPosition, wxDefaultSize, wxRIBBON_PANEL_NO_AUTO_MINIMISE);
	
	my $toolbar = Wx::RibbonToolBar->new($tbpanel, wxID_ANY);
	$self->{maintoolbar} = $toolbar;
	
	$toolbar->AddTool(wxID_ANY, _loadxpm( 'align_left' ));
	$toolbar->AddTool(wxID_ANY, _loadxpm( 'align_center' ));
	$toolbar->AddTool(wxID_ANY, _loadxpm( 'align_right' ));
	$toolbar->AddSeparator();
	$toolbar->AddHybridTool(wxID_NEW, _ap_bmp(wxART_NEW, wxART_OTHER, Wx::Size->new(16, 15)));
	$toolbar->AddTool(wxID_ANY, _ap_bmp(wxART_FILE_OPEN, wxART_OTHER, Wx::Size->new(16, 15)));
	$toolbar->AddTool(wxID_ANY, _ap_bmp(wxART_FILE_SAVE, wxART_OTHER, Wx::Size->new(16, 15)));
	$toolbar->AddTool(wxID_ANY, _ap_bmp(wxART_FILE_SAVE_AS, wxART_OTHER, Wx::Size->new(16, 15)));
	$toolbar->AddSeparator();
	$toolbar->AddDropdownTool(wxID_UNDO, _ap_bmp(wxART_UNDO, wxART_OTHER, Wx::Size->new(16, 15)));
	$toolbar->AddDropdownTool(wxID_REDO, _ap_bmp(wxART_REDO, wxART_OTHER, Wx::Size->new(16, 15)));
	$toolbar->AddSeparator();
	$toolbar->AddTool(wxID_ANY, _ap_bmp(wxART_REPORT_VIEW, wxART_OTHER, Wx::Size->new(16, 15)));
	$toolbar->AddTool(wxID_ANY, _ap_bmp(wxART_LIST_VIEW, wxART_OTHER, Wx::Size->new(16, 15)));
	$toolbar->AddSeparator();
	my $tool_position_left = $toolbar->AddHybridTool(wxID_ANY, _loadxpm( 'position_left_small' ), 
								"Align ribbonbar vertically\non the left\nfor demonstration purposes");
	my $tool_position_top  = $toolbar->AddHybridTool(wxID_ANY, _loadxpm( 'position_top_small' ),
								"Align the ribbonbar horizontally\nat the top\nfor demonstration purposes");
	$toolbar->AddSeparator();
	$toolbar->AddHybridTool(wxID_PRINT, _ap_bmp(wxART_PRINT, wxART_OTHER, Wx::Size->new(16, 15)),
								"This is the Print button tooltip\ndemonstrating a tooltip");
	$toolbar->SetRows(2, 3);
	
	my $selectionpanel = Wx::RibbonPanel->new($page, wxID_ANY, 'Selection', _loadxpm( 'selection_panel' ));
	
	my $selectionbar = Wx::RibbonButtonBar->new($selectionpanel);
		
	my $tool_selection_expand_v = $selectionbar->AddButton(wxID_ANY, 'Expand Vertically',
								_loadxpm( 'expand_selection_v' ),
								"This is a tooltip for Expand Vertically\ndemonstrating a tooltip");
								
	my $tool_selection_expand_h = $selectionbar->AddButton(wxID_ANY, 'Expand Horizontally',
								_loadxpm( 'expand_selection_h' ), '');
	
	my $tool_selection_contract = $selectionbar->AddButton(wxID_ANY, 'Contract',
								_loadxpm( 'auto_crop_selection' ),
								_loadxpm( 'auto_crop_selection_small' ) );
	
	
	my $shapes_panel = Wx::RibbonPanel->new($page, wxID_ANY, 'Shapes',
									   _loadxpm( 'circle_small' ));
	
	my $shapes = Wx::RibbonButtonBar->new($shapes_panel);
	my $tool_circle = $shapes->AddButton(wxID_ANY, 'Circle', _loadxpm( 'circle' ),
							_loadxpm( 'circle_small' ), wxNullBitmap,
							wxNullBitmap, wxRIBBON_BUTTON_NORMAL,
							"This is a tooltip for the circle button\ndemonstrating another tooltip");
	my $tool_cross = $shapes->AddButton(wxID_ANY, 'Cross', _loadxpm( 'cross' ), '');
	my $tool_triangle = $shapes->AddHybridButton(wxID_ANY, 'Triangle', _loadxpm( 'triangle' ));
	my $tool_square = $shapes->AddButton(wxID_ANY, 'Square', _loadxpm( 'square' ), '');
	my $tool_polygon = $shapes->AddDropdownButton(wxID_ANY, 'Other Polygon', _loadxpm( 'hexagon' ), '');
	
	my $sizer_panel = Wx::RibbonPanel->new($page, wxID_ANY, 'Panel with Sizer', 
									wxNullBitmap, wxDefaultPosition, wxDefaultSize, 
									wxRIBBON_PANEL_DEFAULT_STYLE);
	
	my $sizer_panelcombo = Wx::ComboBox->new($sizer_panel, wxID_ANY, '', wxDefaultPosition, wxDefaultSize,
							[ 'Item 1 using a box sizer now', 'Item 2 using a box sizer now'],
							wxCB_READONLY);
	
	my $sizer_panelcombo2 = Wx::ComboBox->new($sizer_panel, wxID_ANY, '', wxDefaultPosition, wxDefaultSize,
							[ 'Item 1 using a box sizer now', 'Item 2 using a box sizer now'],
							wxCB_READONLY);
	
	$sizer_panelcombo->Select(0);
	$sizer_panelcombo2->Select(1);
	$sizer_panelcombo->SetMinSize(Wx::Size->new(150, -1));
	$sizer_panelcombo2->SetMinSize(Wx::Size->new(150, -1));
	
	my $sizer_panelsizer = Wx::BoxSizer->new(wxVERTICAL);   
	$sizer_panelsizer->AddStretchSpacer(1);
	$sizer_panelsizer->Add($sizer_panelcombo, 0, wxALL|wxEXPAND, 2);
	$sizer_panelsizer->Add($sizer_panelcombo2, 0, wxALL|wxEXPAND, 2);
	$sizer_panelsizer->AddStretchSpacer(1);
	$sizer_panel->SetSizer($sizer_panelsizer);
	
	my $label_font = Wx::Font->new(8, wxFONTFAMILY_DEFAULT, wxFONTSTYLE_NORMAL, wxFONTWEIGHT_LIGHT);
	
	$self->{bitmapcreation_dc}->SetFont($label_font);
	
	my $scheme = Wx::RibbonPage->new($self, wxID_ANY, 'Appearance', _loadxpm( 'eye' ));
	
	my ( $default_primary, $default_secondary, $default_tertiary ) =
		$self->GetArtProvider()->GetColourScheme();
		
	my $provider_panel = Wx::RibbonPanel->new($scheme, wxID_ANY,
			'Art', wxNullBitmap, wxDefaultPosition, wxDefaultSize, wxRIBBON_PANEL_NO_AUTO_MINIMISE);
	
	my $provider_bar = Wx::RibbonButtonBar->new($provider_panel, wxID_ANY);
	my $tool_default_provider = $provider_bar->AddButton(wxID_ANY, 'Default Provider',
			_ap_bmp(wxART_QUESTION, wxART_OTHER, Wx::Size->new(32, 32)));
	
	my $tool_aui_provider = $provider_bar->AddButton(wxID_ANY, 'AUI Provider', _loadxpm( 'aui_style' ));
	my $tool_msw_provider = $provider_bar->AddButton(wxID_ANY, 'MSW Provider', _loadxpm( 'msw_style' ));
		
	my $primary_panel = Wx::RibbonPanel->new($scheme, wxID_ANY, 'Primary Colour', _loadxpm( 'colours' ));
	
	my $id_primary_colour = Wx::NewId();
	
	my $primary_gallery = $self->PopulateColoursPanel($primary_panel, $default_primary, $id_primary_colour);
	$self->{primary_gallery} = $primary_gallery;
	$self->{primary_panel} = $primary_panel;
	$self->{primary_id} = $id_primary_colour;
	
	my $secondary_panel = Wx::RibbonPanel->new($scheme, wxID_ANY, 'Secondary Colour', _loadxpm( 'colours' ));
	
	my $id_secondary_colour = Wx::NewId();
	
	my $secondary_gallery = $self->PopulateColoursPanel($secondary_panel, $default_secondary, $id_secondary_colour);
	$self->{secondary_gallery} = $secondary_gallery;
	$self->{secondary_panel} = $secondary_panel;
	$self->{secondary_id} = $id_secondary_colour;
	
	Wx::RibbonPage->new($self, wxID_ANY, 'Empty Page', _loadxpm( 'empty' ));
	Wx::RibbonPage->new($self, wxID_ANY, 'Another Page', _loadxpm( 'empty' ));
	
	$self->Realize();
	
	# connect events to parent panel
	
	EVT_RIBBONBUTTONBAR_CLICKED($parent, $tool_default_provider->GetId, sub { shift->OnDefaultProvider( @_ ) } );
	EVT_RIBBONBUTTONBAR_CLICKED($parent, $tool_aui_provider->GetId, sub { shift->OnAUIProvider( @_ ) } );
	EVT_RIBBONBUTTONBAR_CLICKED($parent, $tool_msw_provider->GetId, sub { shift->OnMSWProvider( @_ ) } );
	EVT_RIBBONBUTTONBAR_CLICKED($parent, $tool_selection_expand_h->GetId, sub { shift->OnSelectionExpandHButton( @_ ) } );
	EVT_RIBBONBUTTONBAR_CLICKED($parent, $tool_selection_expand_v->GetId, sub { shift->OnSelectionExpandVButton( @_ ) } );
	EVT_RIBBONBUTTONBAR_CLICKED($parent, $tool_selection_contract->GetId, sub { shift->OnSelectionContractButton( @_ ) } );
	EVT_RIBBONBUTTONBAR_CLICKED($parent, $tool_circle->GetId, sub { shift->OnCircleButton( @_ ) } );
	EVT_RIBBONBUTTONBAR_CLICKED($parent, $tool_cross->GetId, sub { shift->OnCrossButton( @_ ) } );
	EVT_RIBBONBUTTONBAR_CLICKED($parent, $tool_triangle->GetId, sub { shift->OnTriangleButton( @_ ) } );
	EVT_RIBBONBUTTONBAR_CLICKED($parent, $tool_square->GetId, sub { shift->OnSquareButton( @_ ) } );
	EVT_RIBBONBUTTONBAR_DROPDOWN_CLICKED($parent, $tool_triangle->GetId, sub { shift->OnTriangleDropdown( @_ ) } );
	EVT_RIBBONBUTTONBAR_DROPDOWN_CLICKED($parent, $tool_polygon->GetId, sub { shift->OnPolygonDropdown( @_ ) } );
	EVT_RIBBONGALLERY_HOVER_CHANGED($parent, $id_primary_colour, sub { shift->OnHoveredColourChange( @_ ) } );
	EVT_RIBBONGALLERY_HOVER_CHANGED($parent, $id_secondary_colour, sub { shift->OnHoveredColourChange( @_ ) } );
	EVT_RIBBONGALLERY_SELECTED($parent, $id_primary_colour, sub { shift->OnPrimaryColourSelect( @_ ) } );
	EVT_RIBBONGALLERY_SELECTED($parent, $id_secondary_colour, sub { shift->OnSecondaryColourSelect( @_ ) } );
	EVT_RIBBONTOOLBAR_CLICKED($parent, wxID_NEW, sub { shift->OnNew( @_ ) } );
	EVT_RIBBONTOOLBAR_DROPDOWN_CLICKED($parent, wxID_NEW, sub { shift->OnNewDropdown( @_ ) } );
	EVT_RIBBONTOOLBAR_CLICKED($parent, wxID_PRINT, sub { shift->OnPrint( @_ ) } );
	EVT_RIBBONTOOLBAR_DROPDOWN_CLICKED($parent, wxID_PRINT, sub { shift->OnPrintDropdown( @_ ) } );
	EVT_RIBBONTOOLBAR_DROPDOWN_CLICKED($parent, wxID_REDO, sub { shift->OnRedoDropdown( @_ ) } );
	EVT_RIBBONTOOLBAR_DROPDOWN_CLICKED($parent, wxID_UNDO, sub { shift->OnUndoDropdown( @_ ) } );
	EVT_RIBBONTOOLBAR_CLICKED($parent, $tool_position_left, sub { shift->OnPositionLeft( @_ ) } );
	EVT_RIBBONTOOLBAR_DROPDOWN_CLICKED($parent, $tool_position_left->GetId, sub { shift->OnPositionLeftDropdown( @_ ) } );
	EVT_RIBBONTOOLBAR_CLICKED($parent, $tool_position_top->GetId, sub { shift->OnPositionTop( @_ ) } );
	EVT_RIBBONTOOLBAR_DROPDOWN_CLICKED($parent, $tool_position_top->GetId, sub { shift->OnPositionTopDropdown( @_ ) } );
	EVT_BUTTON($parent, $id_primary_colour, sub { shift->OnColourGalleryButton( @_ ) } );
	EVT_BUTTON($parent, $id_primary_colour, sub { shift->OnColourGalleryButton( @_ ) } );
	
	$parent->{menuids}->{position_left} = $tool_position_left->GetId;
	$parent->{menuids}->{position_top}  = $tool_position_top->GetId;
	
	return $self;
}

sub _loadxpm {
	return Wx::Bitmap->new( Wx::Demo->get_data_file( qq(ribbon/$_[0].xpm) ), wxBITMAP_TYPE_XPM );
}

sub _ap_bmp {
	Wx::ArtProvider::GetBitmap( @_ );
}

sub PopulateColoursPanel {
	my( $self, $panel, $colour, $gallery_id) = @_;
    
	my $gallery = Wx::Window::FindWindowById($gallery_id);
	
    if($gallery) {
        $gallery->Clear();
	} else {
        $gallery = Wx::RibbonGallery->new($panel, $gallery_id);
	}
	
    my $dc = $self->{bitmapcreation_dc};
    my $def_item = $self->AddColourToGallery($gallery, 'Default', $dc, $colour);
    $gallery->SetSelection($def_item);
	$self->AddColourToGallery($gallery, 'BLUE', $dc);
	$self->AddColourToGallery($gallery, 'BLUE VIOLET', $dc);
	$self->AddColourToGallery($gallery, 'BROWN', $dc);
	$self->AddColourToGallery($gallery, 'CADET BLUE', $dc);
	$self->AddColourToGallery($gallery, 'CORAL', $dc);
	$self->AddColourToGallery($gallery, 'CYAN', $dc);
	$self->AddColourToGallery($gallery, 'DARK GREEN', $dc);
	$self->AddColourToGallery($gallery, 'DARK ORCHID', $dc);
	$self->AddColourToGallery($gallery, 'FIREBRICK', $dc);
	$self->AddColourToGallery($gallery, 'GOLD', $dc);
	$self->AddColourToGallery($gallery, 'GOLDENROD', $dc);
	$self->AddColourToGallery($gallery, 'GREEN', $dc);
	$self->AddColourToGallery($gallery, 'INDIAN RED', $dc);
	$self->AddColourToGallery($gallery, 'KHAKI', $dc);
	$self->AddColourToGallery($gallery, 'LIGHT BLUE', $dc);
	$self->AddColourToGallery($gallery, 'LIME GREEN', $dc);
	$self->AddColourToGallery($gallery, 'MAGENTA', $dc);
	$self->AddColourToGallery($gallery, 'MAROON', $dc);
	$self->AddColourToGallery($gallery, 'NAVY', $dc);
	$self->AddColourToGallery($gallery, 'ORANGE', $dc);
	$self->AddColourToGallery($gallery, 'ORCHID', $dc);
	$self->AddColourToGallery($gallery, 'PINK', $dc);
	$self->AddColourToGallery($gallery, 'PLUM', $dc);
	$self->AddColourToGallery($gallery, 'PURPLE', $dc);
	$self->AddColourToGallery($gallery, 'RED', $dc);
	$self->AddColourToGallery($gallery, 'SALMON', $dc);
	$self->AddColourToGallery($gallery, 'SEA GREEN', $dc);
	$self->AddColourToGallery($gallery, 'SIENNA', $dc);
	$self->AddColourToGallery($gallery, 'SKY BLUE', $dc);
	$self->AddColourToGallery($gallery, 'TAN', $dc);
	$self->AddColourToGallery($gallery, 'THISTLE', $dc);
	$self->AddColourToGallery($gallery, 'TURQUOISE', $dc);
	$self->AddColourToGallery($gallery, 'VIOLET', $dc);
	$self->AddColourToGallery($gallery, 'VIOLET RED', $dc);
	$self->AddColourToGallery($gallery, 'WHEAT', $dc);
	$self->AddColourToGallery($gallery, 'WHITE', $dc);
	$self->AddColourToGallery($gallery, 'YELLOW', $dc);

    return $gallery;
}

sub AddColourToGallery {
	my ($self, $gallery, $colourname, $dc, $colour) = @_;
	
	$colour ||= Wx::Colour->new($colourname);
    my $g_item;
    if($colour->IsOk) {
        my $iWidth = 64;
        my $iHeight = 40;
		my $bitmap = Wx::Bitmap->new($iWidth, $iHeight, -1);
        $dc->SelectObject($bitmap);
		my $brush = Wx::Brush->new($colour, wxSOLID);
        $dc->SetPen(wxBLACK_PEN);
        $dc->SetBrush($brush);
        $dc->DrawRectangle(0, 0, $iWidth, $iHeight);

        $colourname = lc($colourname);
		my ($text_x, $text_y, $text_descent, $text_externalLeading) = $dc->GetTextExtent($colourname);
		
        my $foreground = Wx::Colour->new(~$colour->Red(), ~$colour->Green(), ~$colour->Blue());
        if(abs($foreground->Red() - $colour->Red()) + abs($foreground->Blue() - $colour->Blue())
            + abs($foreground->Green() - $colour->Green()) < 64)
        {
            ## Foreground too similar to background - use a different
            ## strategy to find a contrasting colour
            $foreground = Wx::Colour->new(($colour->Red() + 64) % 256, 255 - $colour->Green(),
                ($colour->Blue() + 192) % 256);
        }
        $dc->SetTextForeground($foreground);
        $dc->DrawText($colourname, ($iWidth - $text_x + 1) / 2, ($iHeight - $text_y) / 2);
        $dc->SelectObjectAsSource(wxNullBitmap);

        $g_item = $gallery->Append($bitmap, wxID_ANY);
        $gallery->SetItemClientData($g_item, { name => $colourname, colour => $colour } );
    }
    return $g_item;
}

sub GetGalleryColour {
	my( $self, $gallery, $item) = @_;
	my $data = $gallery->GetItemClientData($item);
    return $data;
}

# return 1 or 0
eval { return Wx::_wx_optmod_ribbon(); };
