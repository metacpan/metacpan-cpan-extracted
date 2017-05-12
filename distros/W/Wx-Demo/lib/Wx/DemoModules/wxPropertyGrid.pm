#############################################################################
## Name:        lib/Wx/DemoModules/wxPropertyGrid.pm
## Purpose:     wxPerl demo helper for Wx::PropertyGrid
## Author:      Mark Dootson
## Modified by:
## Created:     03/03/2012
## SVN-ID:      $Id: wxPropertyGrid.pm 3201 2012-03-16 19:05:37Z mdootson $
## Copyright:   (c) 2012 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################
#
# based on wxWidgets   samples/propgrid/propgrid.cpp
# (c) Jaakko Salli
#
#############################################################################

use Wx;
use Wx::PropertyGrid;
package Wx::DemoModules::wxPropertyGrid;
use strict;

use Wx qw( :propgrid :misc wxTheApp :id :colour :sizer :window :panel
           :bitmap :font :datepicker :pen :frame :menu wxYES_NO wxNO);
use base qw( Wx::Panel );
use Wx::DateTime;
use Wx::ArtProvider qw( wxART_FOLDER );
use Math::BigInt;
use Wx::Event qw(
	EVT_PG_SELECTED EVT_PG_CHANGED EVT_PG_CHANGING EVT_PG_HIGHLIGHTED
	EVT_PG_RIGHT_CLICK EVT_PG_DOUBLE_CLICK 
	EVT_PG_LABEL_EDIT_BEGIN EVT_PG_LABEL_EDIT_ENDING EVT_BUTTON
	EVT_PG_ITEM_COLLAPSED EVT_PG_ITEM_EXPANDED EVT_PG_COL_BEGIN_DRAG
	EVT_PG_COL_DRAGGING EVT_PG_COL_END_DRAG
	EVT_PG_PAGE_CHANGED EVT_MENU
);

# we don't need to use an id enum in Perl but we use it here as it is simpler to translate the C++
# code from the wxWidgets propgrid sample

use constant {
    PGID 				=> 1,
    TCID 				=> 2,
    ID_ABOUT 			=> 3,
    ID_QUIT 			=> 4,
    ID_APPENDPROP 		=> 5,
    ID_APPENDCAT 		=> 6,
    ID_INSERTPROP 		=> 7,
    ID_INSERTCAT 		=> 8,
    ID_ENABLE 			=> 9,
    ID_SETREADONLY 		=> 10,
    ID_HIDE 			=> 11,
    ID_DELETE 			=> 12,
    ID_DELETER 			=> 13,
    ID_DELETEALL 		=> 14,
    ID_UNSPECIFY 		=> 15,
    ID_ITERATE1 		=> 16,
    ID_ITERATE2 		=> 17,
    ID_ITERATE3 		=> 18,
    ID_ITERATE4 		=> 19,
    ID_CLEARMODIF 		=> 20,
    ID_FREEZE 			=> 21,
    ID_DUMPLIST 		=> 22,
    ID_COLOURSCHEME1 	=> 23,
    ID_COLOURSCHEME2 	=> 24,
    ID_COLOURSCHEME3 	=> 25,
    ID_CATCOLOURS 		=> 26,
    ID_SETBGCOLOUR 		=> 27,
    ID_SETBGCOLOURRECUR => 28,
    ID_STATICLAYOUT 	=> 29,
    ID_POPULATE1 		=> 30,
    ID_POPULATE2 		=> 31,
    ID_COLLAPSE 		=> 32,
    ID_COLLAPSEALL 		=> 33,
    ID_GETVALUES 		=> 34,
    ID_SETVALUES 		=> 35,
    ID_SETVALUES2 		=> 36,
    ID_RUNTESTFULL 		=> 37,
    ID_RUNTESTPARTIAL 	=> 38,
    ID_FITCOLUMNS 		=> 39,
    ID_CHANGEFLAGSITEMS => 40,
    ID_TESTINSERTCHOICE => 41,
    ID_TESTDELETECHOICE => 42,
    ID_INSERTPAGE 		=> 43,
    ID_REMOVEPAGE 		=> 44,
    ID_SETSPINCTRLEDITOR => 45,
    ID_SETPROPERTYVALUE => 46,
    ID_TESTREPLACE 		=> 47,
    ID_SETCOLUMNS 		=> 48,
    ID_TESTXRC 			=> 49,
    ID_ENABLECOMMONVALUES => 50,
    ID_SELECTSTYLE 		=> 51,
    ID_SAVESTATE 		=> 52,
    ID_RESTORESTATE 	=> 53,
    ID_RUNMINIMAL 		=> 54,
    ID_ENABLELABELEDITING => 55,
    ID_VETOCOLDRAG 		=> 56,
    ID_SHOWHEADER 		=> 57,
    ID_ONEXTENDEDKEYNAV => 58,
	ID_COLOURSCHEME4 	=> 59,
};
	
sub new {
    my $class = shift;
    my $self = $class->SUPER::new($_[0], -1);
	$self->create_property_grid;
	$self->connect_events;
	$self->create_menu;
    return $self;
}

#sub tags { [ 'controls/propertygrid', 'wxPropertyGrid' ], [ 'new/propertygrid', 'wxPropertyGrid' ] }

sub add_to_tags { qw(controls new ) }
sub title { 'wxPropertyGrid' }

sub create_property_grid {
	my ($self, $style, $extrastyle ) = @_;
	if ( !defined($style) || $style == -1 ) {
        $style = wxPG_BOLD_MODIFIED | wxPG_SPLITTER_AUTO_CENTER |
                wxPG_AUTO_SORT | wxPG_TOOLBAR | wxPG_DESCRIPTION;
	}

    if ( !defined($extrastyle) || $extrastyle == -1 ) {
        $extrastyle = wxPG_EX_MODE_BUTTONS | wxPG_EX_MULTIPLE_SELECTION;
	}

	my $wascreated = ( $self->{panel} ) ? 0 : 1;
    $self->init_panel;

	# create the manager - note bug causes failure if wxDefaultSize passed
	# so we pass an actual size [100,100]
	
	my $pgman = $self->{manager} = Wx::PropertyGridManager->new(
		$self->{panel}, PGID, wxDefaultPosition, wxDefaultSize, $style);
	
    $self->{propgrid} = $pgman->GetGrid();

    $pgman->SetExtraStyle($extrastyle);

    # This is the default validation failure behaviour
    $pgman->SetValidationFailureBehavior( wxPG_VFB_MARK_CELL |  wxPG_VFB_SHOW_MESSAGEBOX );

    $self->{propgrid}->SetVerticalSpacing( 2 );

    ## Set somewhat different unspecified value appearance
	{
		my $cell = Wx::PGCell->new();
		$cell->SetText("Unspecified");
		$cell->SetFgCol( wxLIGHT_GREY );
		$self->{propgrid}->SetUnspecifiedValueAppearance($cell);
	}

    $self->populate_grid;

    # Change some attributes in all properties
    $pgman->SetPropertyAttributeAll(wxPG_BOOL_USE_DOUBLE_CLICK_CYCLING, 1 );
	
    $self->{topsizer}->Add($pgman, 1, wxEXPAND );

    $self->finalise_panel( $wascreated );
	
}

sub connect_events {
	my $self = shift;
	
	EVT_PG_SELECTED($self,  PGID, sub { shift->OnPropertyGridSelect( @_ ); } );
    # // This occurs when a property value changes
	EVT_PG_CHANGED($self,  PGID, sub { shift->OnPropertyGridChange( @_ ); } );
    # // This occurs just prior a property value is changed
	EVT_PG_CHANGING($self,  PGID, sub { shift->OnPropertyGridChanging( @_ ); } );
    # This occurs when a mouse moves over another property
	EVT_PG_HIGHLIGHTED($self,  PGID, sub { shift->OnPropertyGridHighlight( @_ ); } );
    # This occurs when mouse is right-clicked.
	EVT_PG_RIGHT_CLICK($self,  PGID, sub { shift->OnPropertyGridItemRightClick( @_ ); } );
    # This occurs when mouse is double-clicked.
	EVT_PG_DOUBLE_CLICK($self,  PGID, sub { shift->OnPropertyGridItemDoubleClick( @_ ); } );
    # This occurs when propgridmanager's page changes.
	EVT_PG_PAGE_CHANGED($self,  PGID, sub { shift->OnPropertyGridPageChange( @_ ); } );
    # This occurs when user starts editing a property label
	EVT_PG_LABEL_EDIT_BEGIN($self,  PGID, sub { shift->OnPropertyGridLabelEditBegin( @_ ); } );
    # This occurs when user stops editing a property label
	EVT_PG_LABEL_EDIT_ENDING($self,  PGID, sub { shift->OnPropertyGridLabelEditEnding( @_ ); } );
    # This occurs when property's editor button (if any) is clicked.
	EVT_BUTTON($self,  PGID, sub { shift->OnPropertyGridButtonClick( @_ ); } );
	EVT_PG_ITEM_COLLAPSED($self,  PGID, sub { shift->OnPropertyGridItemCollapse( @_ ); } );
	EVT_PG_ITEM_EXPANDED($self,  PGID, sub { shift->OnPropertyGridItemExpand( @_ ); } );
	EVT_PG_COL_BEGIN_DRAG($self,  PGID, sub { shift->OnPropertyGridColBeginDrag( @_ ); } );
	EVT_PG_COL_DRAGGING($self,  PGID, sub { shift->OnPropertyGridColDragging( @_ ); } );
	EVT_PG_COL_END_DRAG($self,  PGID, sub { shift->OnPropertyGridColEndDrag( @_ ); } );
	
	my $frame = Wx::GetTopLevelParent( $self );
	
	EVT_MENU($frame, ID_APPENDPROP, sub { $self->OnAppendPropClick( $_[1] ); } );
    EVT_MENU($frame, ID_APPENDCAT, sub { $self->OnAppendCatClick( $_[1] ); } );
    EVT_MENU($frame, ID_INSERTPROP, sub { $self->OnInsertPropClick( $_[1] ); } );
    EVT_MENU($frame, ID_INSERTCAT, sub { $self->OnInsertCatClick( $_[1] ); } );
    EVT_MENU($frame, ID_DELETE, sub { $self->OnDelPropClick( $_[1] ); } );
    EVT_MENU($frame, ID_DELETER, sub { $self->OnDelPropRClick( $_[1] ); } );
    EVT_MENU($frame, ID_UNSPECIFY, sub { $self->OnMisc( $_[1] ); } );
    EVT_MENU($frame, ID_DELETEALL, sub { $self->OnClearClick( $_[1] ); } );
    EVT_MENU($frame, ID_ENABLE, sub { $self->OnEnableDisable( $_[1] ); } );
    EVT_MENU($frame, ID_SETREADONLY, sub { $self->OnSetReadOnly( $_[1] ); } );
    EVT_MENU($frame,ID_HIDE, sub { $self->OnHide( $_[1] ); } );

    EVT_MENU($frame, ID_ITERATE1, sub { $self->OnIterate1Click( $_[1] ); } );
    EVT_MENU($frame, ID_ITERATE2, sub { $self->OnIterate2Click( $_[1] ); } );
    EVT_MENU($frame, ID_ITERATE3, sub { $self->OnIterate3Click( $_[1] ); } );
    EVT_MENU($frame, ID_ITERATE4, sub { $self->OnIterate4Click( $_[1] ); } );
    EVT_MENU($frame, ID_SETBGCOLOUR, sub { $self->OnSetBackgroundColour( $_[1] ); } );
    EVT_MENU($frame, ID_SETBGCOLOURRECUR, sub { $self->OnSetBackgroundColour( $_[1] ); } );
    EVT_MENU($frame, ID_CLEARMODIF, sub { $self->OnClearModifyStatusClick( $_[1] ); } );
    EVT_MENU($frame, ID_FREEZE, sub { $self->OnFreezeClick( $_[1] ); } );
    EVT_MENU($frame, ID_ENABLELABELEDITING, sub { $self->OnEnableLabelEditing( $_[1] ); } );
    EVT_MENU($frame, ID_SHOWHEADER, sub { $self->OnShowHeader( $_[1] ); } );
    EVT_MENU($frame, ID_DUMPLIST, sub { $self->OnDumpList( $_[1] ); } );

    EVT_MENU($frame, ID_COLOURSCHEME1, sub { $self->OnColourScheme( $_[1] ); } );
    EVT_MENU($frame, ID_COLOURSCHEME2, sub { $self->OnColourScheme( $_[1] ); } );
    EVT_MENU($frame, ID_COLOURSCHEME3, sub { $self->OnColourScheme( $_[1] ); } );
    EVT_MENU($frame, ID_COLOURSCHEME4, sub { $self->OnColourScheme( $_[1] ); } );

    EVT_MENU($frame, ID_CATCOLOURS, sub { $self->OnCatColours( $_[1] ); } );
    EVT_MENU($frame, ID_SETCOLUMNS, sub { $self->OnSetColumns( $_[1] ); } );
    EVT_MENU($frame, ID_ENABLECOMMONVALUES, sub { $self->OnEnableCommonValues( $_[1] ); } );
    EVT_MENU($frame, ID_SELECTSTYLE, sub { $self->OnSelectStyle( $_[1] ); } );

    EVT_MENU($frame, ID_STATICLAYOUT, sub { $self->OnMisc( $_[1] ); } );
    EVT_MENU($frame, ID_COLLAPSE, sub { $self->OnMisc( $_[1] ); } );
    EVT_MENU($frame, ID_COLLAPSEALL, sub { $self->OnMisc( $_[1] ); } );

    EVT_MENU($frame, ID_POPULATE1, sub { $self->OnPopulateClick( $_[1] ); } );
    EVT_MENU($frame, ID_POPULATE2, sub { $self->OnPopulateClick( $_[1] ); } );

    EVT_MENU($frame, ID_GETVALUES, sub { $self->OnMisc( $_[1] ); } );
    EVT_MENU($frame, ID_SETVALUES, sub { $self->OnMisc( $_[1] ); } );
    EVT_MENU($frame, ID_SETVALUES2, sub { $self->OnMisc( $_[1] ); } );

    EVT_MENU($frame, ID_FITCOLUMNS, sub { $self->OnFitColumnsClick( $_[1] ); } );

    EVT_MENU($frame, ID_CHANGEFLAGSITEMS, sub { $self->OnChangeFlagsPropItemsClick( $_[1] ); } );

    EVT_MENU($frame, ID_RUNTESTFULL, sub { $self->OnMisc( $_[1] ); } );
    EVT_MENU($frame, ID_RUNTESTPARTIAL, sub { $self->OnMisc( $_[1] ); } );

    EVT_MENU($frame, ID_TESTINSERTCHOICE, sub { $self->OnInsertChoice( $_[1] ); } );
    EVT_MENU($frame, ID_TESTDELETECHOICE, sub { $self->OnDeleteChoice( $_[1] ); } );

    EVT_MENU($frame, ID_INSERTPAGE, sub { $self->OnInsertPage( $_[1] ); } );
    EVT_MENU($frame, ID_REMOVEPAGE, sub { $self->OnRemovePage( $_[1] ); } );

    EVT_MENU($frame, ID_SAVESTATE, sub { $self->OnSaveState( $_[1] ); } );
    EVT_MENU($frame, ID_RESTORESTATE, sub { $self->OnRestoreState( $_[1] ); } );

    EVT_MENU($frame, ID_SETSPINCTRLEDITOR, sub { $self->OnSetSpinCtrlEditorClick( $_[1] ); } );
    EVT_MENU($frame, ID_TESTREPLACE, sub { $self->OnTestReplaceClick( $_[1] ); } );
    EVT_MENU($frame, ID_SETPROPERTYVALUE, sub { $self->OnSetPropertyValue( $_[1] ); } );
	
}

sub create_menu {
	my $self = shift;
	
	my $menuFile = Wx::Menu->new('', wxMENU_TEAROFF );
	my $menuTry =  Wx::Menu->new();
	my $menuTools1 =  Wx::Menu->new();
	my $menuTools2 =  Wx::Menu->new();

    $menuTools1->Append(ID_APPENDPROP, 'Append New Property' );
    $menuTools1->Append(ID_APPENDCAT, "Append New Category\tCtrl-S" );
    $menuTools1->AppendSeparator();
    $menuTools1->Append(ID_INSERTPROP, "Insert New Property\tCtrl-Q" );
    $menuTools1->Append(ID_INSERTCAT, "Insert New Category\tCtrl-W" );
    $menuTools1->AppendSeparator();
    $menuTools1->Append(ID_DELETE, "Delete Selected" );
    $menuTools1->Append(ID_DELETER, "Delete Random" );
    $menuTools1->Append(ID_DELETEALL, "Delete All" );
    $menuTools1->AppendSeparator();
    $menuTools1->Append(ID_SETBGCOLOUR, "Set Bg Colour" );
    $menuTools1->Append(ID_SETBGCOLOURRECUR, "Set Bg Colour (Recursively)" );
    $menuTools1->Append(ID_UNSPECIFY, "Set Value to Unspecified");
    $menuTools1->AppendSeparator();
    my $m_itemEnable = $menuTools1->Append(ID_ENABLE, "Enable",
        "Toggles item's enabled state." );
    $m_itemEnable->Enable( 0 );
	$self->{m_itemEnable} = $m_itemEnable;
    $menuTools1->Append(ID_HIDE, "Hide", "Hides a property" );
    $menuTools1->Append(ID_SETREADONLY, "Set as Read-Only",
                       "Set property as read-only" );

    $menuTools2->Append(ID_ITERATE1, "Iterate Over Properties" );
    $menuTools2->Append(ID_ITERATE2, "Iterate Over Visible Items" );
    $menuTools2->Append(ID_ITERATE3, "Reverse Iterate Over Properties" );
    $menuTools2->Append(ID_ITERATE4, "Iterate Over Categories" );
    $menuTools2->AppendSeparator();
    $menuTools2->Append(ID_ONEXTENDEDKEYNAV, "Extend Keyboard Navigation",
                       "This will set Enter to navigate to next property, " .
                       "and allows arrow keys to navigate even when in " .
                       "editor control.");
    $menuTools2->AppendSeparator();
    $menuTools2->Append(ID_SETPROPERTYVALUE, "Set Property Value" );
    $menuTools2->Append(ID_CLEARMODIF, "Clear Modified Status", "Clears wxPG_MODIFIED flag from all properties." );
    $menuTools2->AppendSeparator();
    my $m_itemFreeze = $menuTools2->AppendCheckItem(ID_FREEZE, "Freeze",
        "Disables painting, auto-sorting, etc." );
    $menuTools2->AppendSeparator();
    $menuTools2->Append(ID_DUMPLIST, "Display Values as wxVariant List", "Tests GetAllValues method and wxVariant conversion." );
    $menuTools2->AppendSeparator();
    $menuTools2->Append(ID_GETVALUES, "Get Property Values", "Stores all property values." );
    $menuTools2->Append(ID_SETVALUES, "Set Property Values", "Reverts property values to those last stored." );
    $menuTools2->Append(ID_SETVALUES2, "Set Property Values 2", "Adds property values that should not initially be as items (so new items are created)." );
    $menuTools2->AppendSeparator();
    $menuTools2->Append(ID_SAVESTATE, "Save Editable State" );
    $menuTools2->Append(ID_RESTORESTATE, "Restore Editable State" );
    $menuTools2->AppendSeparator();
    $menuTools2->Append(ID_ENABLECOMMONVALUES, "Enable Common Value",
        "Enable values that are common to all properties, for selected property.");
    $menuTools2->AppendSeparator();
    $menuTools2->Append(ID_COLLAPSE, "Collapse Selected" );
    $menuTools2->Append(ID_COLLAPSEALL,"Collapse All" );
    $menuTools2->AppendSeparator();
    $menuTools2->Append(ID_INSERTPAGE, "Add Page" );
    $menuTools2->Append(ID_REMOVEPAGE, "Remove Page" );
    $menuTools2->AppendSeparator();
    $menuTools2->Append(ID_FITCOLUMNS, "Fit Columns" );
    my $m_itemVetoDragging =
        $menuTools2->AppendCheckItem(ID_VETOCOLDRAG,
                                    "Veto Column Dragging");
    $menuTools2->AppendSeparator();
    $menuTools2->Append(ID_CHANGEFLAGSITEMS, "Change Children of FlagsProp" );
    $menuTools2->AppendSeparator();
    $menuTools2->Append(ID_TESTINSERTCHOICE, "Test InsertPropertyChoice" );
    $menuTools2->Append(ID_TESTDELETECHOICE, "Test DeletePropertyChoice" );
    $menuTools2->AppendSeparator();
    $menuTools2->Append(ID_SETSPINCTRLEDITOR, "Use SpinCtrl Editor" );
    $menuTools2->Append(ID_TESTREPLACE, "Test ReplaceProperty" );

    $menuTry->Append(ID_SELECTSTYLE, "Set Window Style",
        "Select window style flags used by the grid.");
    $menuTry->Append(ID_ENABLELABELEDITING, "Enable label editing",
        "This calls wxPropertyGrid::MakeColumnEditable(0)");
    $menuTry->AppendCheckItem(ID_SHOWHEADER,
        "Enable header",
        "This calls wxPropertyGridManager::ShowHeader()");
    $menuTry->AppendSeparator();
    $menuTry->AppendRadioItem( ID_COLOURSCHEME1, "Standard Colour Scheme" );
    $menuTry->AppendRadioItem( ID_COLOURSCHEME2, "White Colour Scheme" );
    $menuTry->AppendRadioItem( ID_COLOURSCHEME3, ".NET Colour Scheme" );
    $menuTry->AppendRadioItem( ID_COLOURSCHEME4, "Cream Colour Scheme" );
    $menuTry->AppendSeparator();
    my $m_itemCatColours = $menuTry->AppendCheckItem(ID_CATCOLOURS, "Category Specific Colours",
        "Switches between category-specific cell colours and default scheme (actually done using SetPropertyTextColour and SetPropertyBackgroundColour)." );
    $menuTry->AppendSeparator();
    $menuTry->AppendCheckItem(ID_STATICLAYOUT, "Static Layout",
        "Switches between user-modifiedable and static layouts." );
    $menuTry->Append(ID_SETCOLUMNS, "Set Number of Columns" );
    $menuTry->AppendSeparator();
    $menuTry->Append(ID_TESTXRC, "Display XRC sample" );
    $menuTry->AppendSeparator();
    $menuTry->Append(ID_RUNTESTFULL, "Run Tests (full)" );
    $menuTry->Append(ID_RUNTESTPARTIAL, "Run Tests (fast)" );

    $menuFile->Append(ID_RUNMINIMAL, "Run Minimal Sample" );
    $menuFile->AppendSeparator();

	my $topmenu = Wx::Menu->new;
	$topmenu->AppendSubMenu($menuFile, 'PropertyGrid &File');
	$topmenu->AppendSubMenu($menuTry, '&Try These');
	$topmenu->AppendSubMenu($menuTools1, '&Basic');
	$topmenu->AppendSubMenu($menuTools2, '&Advanced');
	
	$self->{menu} = [ '&PropertyGrid', $topmenu ];
}

sub menu { @{$_[0]->{menu}} }

sub init_panel {
	my ($self) = @_;
    $self->{panel}->Destroy if $self->{panel};
    $self->{panel} = Wx::Panel->new($self, wxID_ANY, [0, 0], [400, 400], wxTAB_TRAVERSAL);
    $self->{topsizer} = Wx::BoxSizer->new( wxVERTICAL );
}

sub populate_grid {
	my $self = shift;
	my $pgman = $self->{manager};
    
	$pgman->AddPage('Standard Items');

    $self->populate_standard_items();

    #my $page = Wx::DemoModules::wxPropertyGrid::Page->new();
	
	# wxPerl method for using a default bitmap as passing wxNullBitmap
	# doesn't quite work
	#$pgman->AddPage( 'Examples', wxNullBitmap, $page);
    #$pgman->AddPageDefaultBitmap( 'Examples', $page);
	
	$pgman->AddPage('Examples');

    $self->populate_with_examples;
}

sub populate_standard_items {
	my $self = shift;
	
	my $pgman = $self->{manager};
	
	my $pg = $pgman->GetPage('Standard Items');
	
	$pg->Append( Wx::PropertyCategory->new('Appearance') );
    
	$pg->Append( Wx::StringProperty->new('Label', 'Label', 'My Frame Title') );
	
    my $fprop = $pg->Append( Wx::FontProperty->new('Font', 'Font', wxNullFont ) );
    
	$pg->SetPropertyHelpString ( 'Font', 'Editing this will change font used in the property grid.' );
	
	#$fprop->SetHelpString( 'Editing this will change font used in the property grid.' );
	
	#$fprop->SetPlValue( Wx::Font->new( 'Arial' ), 0 );
    
    $pg->Append( Wx::ColourProperty->new('Margin Colour','Margin Colour', $pgman->GetGrid()->GetMarginColour()) );
   
    $pg->Append( Wx::SystemColourProperty->new('Cell Colour', 'Cell Colour',
					Wx::ColourPropertyValue->new( $pgman->GetGrid()->GetCellBackgroundColour()) ) );
       
    $pg->Append( Wx::ColourProperty->new('Cell Text Colour','Cell Text Colour', $pgman->GetGrid()->GetCellTextColour()) );
	
	$pg->Append( Wx::ColourProperty->new('Line Colour','Line Colour', $pgman->GetGrid()->GetLineColour()) );
    
	$pg->Append( Wx::FlagsProperty->new('Some Flags', 'Some Flags',
		[ 'wxFLAG_DEFAULT', 'wxFLAG_FIRST', 'wxFLAG_SECOND', 'wxFLAG_THIRD', 'wxFLAG_FIFTH', 'wxFLAG_SIXTH', ],
		[ 0, 1, 2, 4, 8, 16, 32 ] , 10 ) );
	
	
    $pg->SetPropertyAttribute( 'Some Flags' , wxPG_BOOL_USE_CHECKBOX, 1 , wxPG_RECURSE);
	
	
	$pg->Append( Wx::CursorProperty->new('Cursor','Cursor') );
										 
    $pg->Append( Wx::PropertyCategory->new('Position', 'PositionCategory') );
    
	$pg->SetPropertyHelpString( 'PositionCategory', 'Change in items in this category will cause respective changes in Demo Frame.' );

    #// Let's demonstrate 'Units' attribute here
    
    #// Note that we use many attribute constants instead of strings here
    #// (for instance, wxPG_ATTR_MIN, instead of "min".
    
    
    $pg->Append( Wx::IntProperty->new('Height','Height',480) );
    $pg->SetPropertyAttribute('Height', wxPG_ATTR_MIN,   10 );
    $pg->SetPropertyAttribute('Height', wxPG_ATTR_MAX,   2048  );
    $pg->SetPropertyAttribute('Height', wxPG_ATTR_UNITS, 'Pixels');
    
    #// Set value to unspecified so that Hint attribute will be demonstrated
	$pg->SetPropertyValueUnspecified("Height");
    $pg->SetPropertyAttribute("Height", wxPG_ATTR_HINT,  "Enter new height for window");
    #
    #// Difference between hint and help string is that the hint is shown in
    #// an empty value cell, while help string is shown either in the
    #// description text box, as a tool tip, or on the status bar.
	
    $pg->SetPropertyHelpString("Height", "This property uses attributes \"Units\" and \"Hint\"." );

    $pg->Append( Wx::IntProperty->new('Width', 'Width', 640 ) );
    $pg->SetPropertyAttribute('Width', wxPG_ATTR_MIN, Wx::Variant->new(10) );
	
    $pg->SetPropertyAttribute('Width', wxPG_ATTR_MAX, Wx::Variant->new(2048) );
    $pg->SetPropertyAttribute('Width', wxPG_ATTR_UNITS, Wx::Variant->new('Pixels') );
    
    $pg->SetPropertyValueUnspecified('Width');
    $pg->SetPropertyAttribute('Width', wxPG_ATTR_HINT, "Enter new width for window" );
    $pg->SetPropertyHelpString("Width", "This property uses attributes \"Units\" and \"Hint\"." );
    
    $pg->Append( Wx::IntProperty->new('X','X', 10 ));
    $pg->SetPropertyAttribute('X', wxPG_ATTR_UNITS, '"Pixels"' );
    $pg->SetPropertyHelpString('X', "This property uses \"Units\" attribute." );
    
    $pg->Append( Wx::IntProperty->new( 'Y','Y',10 ));
    $pg->SetPropertyAttribute('Y', wxPG_ATTR_UNITS, 'Pixels');
    $pg->SetPropertyHelpString('Y', "This property uses \"Units\" attribute." );
    
    my $disabledHelpString = qq(This property is simply disabled. In order to have label disabled as well, \n);
	$disabledHelpString .= qq(you need to set wxPG_EX_GREY_LABEL_WHEN_DISABLED using SetExtraStyle.);
    
    $pg->Append( Wx::PropertyCategory->new('Environment','Environment') );
    $pg->Append( Wx::StringProperty->new('Operating System','Operating System',Wx::GetOsDescription()) );
    
	$pg->Append( Wx::StringProperty->new('User Name','User Name',
				( Wx::wxMSW() ) ? getlogin : (getpwuid($<))[0] ) );
	$pg->Append( Wx::DirProperty->new('User Local Data Directory','UserLocalDataDir',
				Wx::StandardPaths::Get()->GetUserLocalDataDir ) );
	
    #// Disable some of them
    $pg->DisableProperty( 'Operating System' );
    $pg->DisableProperty( 'User Name' );
    
    $pg->SetPropertyHelpString( 'Operating System', $disabledHelpString );
    $pg->SetPropertyHelpString( 'User Name', $disabledHelpString );
    
    # $pg->Append( Wx::PropertyCategory->new('More Examples','More Examples') );
    
    # Custom Property Classes ??
	
}

sub populate_with_examples {
	my $self = shift;
	my $pgman = $self->{manager};
    my $pg = $pgman->GetPage('Examples');



	my $spinprop = $pg->Append( Wx::IntProperty->new('SpinCtrl', 'SpinCtrl', 0 ) );
	
	# The second param below is the 'class name' you can use to apply any of the
	# builtin editors
	# Available class builtin names are:
	#  TextCtrl, Choice, ComboBox, TextCtrlAndButton,
	#  CheckBox, ChoiceAndButton, SpinCtrl, DatePickerCtrl
	
	$pg->SetPropertyEditor('SpinCtrl', 'SpinCtrl' );
	
    $pg->SetPropertyAttribute( 'SpinCtrl', wxPG_ATTR_MIN, -10 ); 
	$pg->SetPropertyAttribute( 'SpinCtrl', wxPG_ATTR_MAX, 16384 );
	$pg->SetPropertyAttribute( 'SpinCtrl', 'Step', 2 );
    $pg->SetPropertyAttribute( 'SpinCtrl', 'MotionSpin', 1 );
	$pg->SetPropertyAttribute( 'SpinCtrl', 'Wrap', 1 );

	
     ## Add bool property
	$pg->Append( Wx::BoolProperty->new( 'BoolProperty', 'BoolProperty', 0 ) );
	## Add bool property with check box
	{
		#use the returned value from append to access property directly
		my $prop = $pg->Append( Wx::BoolProperty->new( 'BoolProperty with CheckBox', 'BoolProperty with CheckBox', 0 ) );
		$prop->SetAttribute( wxPG_BOOL_USE_CHECKBOX, 1 );
		$prop->SetHelpString( 'Property attribute wxPG_BOOL_USE_CHECKBOX has been set to true.' );
	}

   
	{
		my $prop = $pg->Append( Wx::FloatProperty->new('FloatProperty','FloatProperty', 1234500.23) );
		$prop->SetAttribute("Min", -100.12);
	}
	
	# A string property that can be edited in a separate editor dialog.

	$pg->Append( Wx::LongStringProperty->new( 'LongStringProperty', 'LongStringProp',
		'This is a much longer string than the first one. Edit it by clicking the button.') );
	
	## A property that edits a wxArrayString.
	
	$pg->Append( Wx::ArrayStringProperty->new('ArrayStringProperty', 'ArrayStringProperty',
                  ['String 1', 'String 2', 'String 3'] ) );

	## A file selector property. Note that argument between name
	## and initial value is wildcard (format same as in wxFileDialog).
	{
		my $prop = $pg->Append(Wx::FileProperty->new('FileProperty', 'TextFile') );
		$prop->SetAttribute(wxPG_FILE_WILDCARD,'Text Files (*.txt)|*.txt');
		$prop->SetAttribute(wxPG_FILE_DIALOG_TITLE,'Custom File Dialog Title');
		$prop->SetAttribute(wxPG_FILE_SHOW_FULL_PATH,0);
	}

	# An image file property. Arguments are just like for FileProperty, but
	# wildcard is missing (it is autogenerated from supported image formats).
	# If you really need to override it, create property separately, and call
	# its SetWildcard method.
	
	$pg->Append( Wx::ImageFileProperty->new( 'ImageFile', 'ImageFile' ) );

	my $fp = $pg->Append( Wx::FontProperty->new('Font X', 'Font X', wxNullFont ) );
	
	# use Perl helper to set a different font
	$fp->SetPlValue( wxNORMAL_FONT );
	
	
	$pg->Append( Wx::ColourProperty->new('ColourProperty','ColourProperty', wxRED) );
	$pg->SetPropertyEditor( 'ColourProperty', 'ComboBox' );
	$pg->GetProperty('ColourProperty')->SetAutoUnspecified(1);
	$pg->SetPropertyHelpString( 'ColourProperty',
	 'Wx::PropertyGrid->SetPropertyEditor method has been used to change editor of this property to "ComboBox"');

	$pg->Append( Wx::ColourProperty->new('ColourPropertyWithAlpha',
                                         'ColourPropertyWithAlpha',
                                           Wx::Colour->new(15, 200, 95, 128)) );
	$pg->SetPropertyAttribute('ColourPropertyWithAlpha', 'HasAlpha', 1);
	$pg->SetPropertyHelpString("ColourPropertyWithAlpha",
        'Attribute "HasAlpha" is set to true for this property.');
	
	# This demonstrates using alternative editor for colour property
	# to trigger colour dialog directly from button.
	
    $pg->Append( Wx::ColourProperty->new('ColourPropertyX','ColourPropertyX', wxGREEN) );

	# note that the initial value (the last argument) is the actual value,
	# not index or anything like that. Thus, our value selects "Another Item".
	
    $pg->Append( Wx::EnumProperty->new('EnumProperty', 'EnumProperty',
        [ 'One Item', 'Another Item', 'One More', 'This is the last' ],
		[ 40, 80, 120, 180 ],
		80 ));

	my $soc = Wx::PGChoices->new();
	
    $soc->Set( [ 'One Item', 'Another Item', 'One More', 'This is the last' ],
			  [ 40, 80, 120, 180 ] );
	# add extra items
	$soc->Add( 'Look, it continues', 200 );
    $soc->Add( 'Even More', 240 );
	$soc->Add( 'And More', 280 );
	$soc->Add( '', 300 );
	$soc->Add( 'True End of the List', 320 );
    
	# Test custom colours 
	$soc->Item(1)->SetFgCol(wxRED);
	$soc->Item(1)->SetBgCol(wxLIGHT_GREY);
	$soc->Item(2)->SetFgCol(wxGREEN);
	$soc->Item(2)->SetBgCol(wxLIGHT_GREY);
	$soc->Item(3)->SetFgCol(wxBLUE);
	$soc->Item(3)->SetBgCol(wxLIGHT_GREY);
	$soc->Item(4)->SetBitmap( Wx::ArtProvider::GetBitmap( wxART_FOLDER ) );
	
	$pg->Append( Wx::EnumProperty->new('EnumProperty 2',
									   'EnumProperty 2',
                                   	   $soc, 180 ) );

	$pg->GetProperty('EnumProperty 2')->AddChoice('Testing Extra', 360);
	
	# Here we only display the original 'soc' choices
	$pg->Append( Wx::EnumProperty->new('EnumProperty 3','EnumProperty 3',
        $soc, 240 ) );

	# Test Hint attribute in EnumProperty
	$pg->GetProperty("EnumProperty 3")->SetAttribute("Hint", "Dummy Hint");
	$pg->SetPropertyHelpString("EnumProperty 3",
	'This property uses "Hint" attribute.');
	
	# 'soc' plus one exclusive extra choice "4th only"
	
	$pg->Append( Wx::EnumProperty->new('EnumProperty 4','EnumProperty 4',
		$soc, 240 ) );
	
	$pg->GetProperty('EnumProperty 4')->AddChoice('4th only', 360);
	$pg->SetPropertyHelpString('EnumProperty 4',
			'Should have one extra item when compared to EnumProperty 3');
	
	# Password Property
	$pg->Append( Wx::StringProperty->new('Password','Password', 'password') );
	$pg->SetPropertyAttribute('Password', wxPG_STRING_PASSWORD, 1 );
	$pg->SetPropertyHelpString('Password',
		'Has attribute wxPG_STRING_PASSWORD set to true');

	# String editor with dir selector button.
	$pg->Append( Wx::DirProperty->new( 'DirProperty', 'DirProperty', Wx::StandardPaths::Get()->GetUserLocalDataDir ) );
	$pg->SetPropertyAttribute( 'DirProperty',
                              wxPG_DIR_DIALOG_MESSAGE,
                              'This is a custom dir dialog message');

	 # Add string property - first arg is label, second name
	$pg->Append( Wx::StringProperty->new('StringProperty', 'StringProperty' ) );
	$pg->SetPropertyMaxLength( 'StringProperty', 6 );
	$pg->SetPropertyHelpString( 'StringProperty',
			'Max length of this text has been limited to 6, using Wx::PropertyGrid->SetPropertyMaxLength.' );
	
	$pg->SetPropertyValueAsString('StringProperty', 'some text' );
    
		
	# Demonstrate "AutoComplete" attribute
	$pg->Append(Wx::StringProperty->new('StringProperty AutoComplete',
                                        'StringProperty AutoComplete') );
	
    $pg->SetPropertyAttribute( "StringProperty AutoComplete", 'AutoComplete', ['another one', 'other one', 'yet again' ] );
	
	$pg->SetPropertyHelpString( "StringProperty AutoComplete",
		'AutoComplete attribute has been set for this property (try writing something beginning with "a", "o" or "y").');
	
	# Add string property with arbitrarily wide bitmap in front of it. We
	# intentionally lower-than-typical row height here so that the ugly
	# scaling code won't be run.
	
	$pg->Append( Wx::StringProperty->new('StringPropertyWithBitmap',
                'StringPropertyWithBitmap',
                'Test Text') );
    
	my $TestBitmap = Wx::Bitmap->new(60, 15, 32);
    my $mdc = Wx::MemoryDC->new;
	$mdc->SelectObject($TestBitmap);
	$mdc->Clear();
	$mdc->SetPen( wxBLACK_PEN );
	$mdc->DrawLine(0, 0, 60, 15);
	$mdc->SelectObject(wxNullBitmap);
	$pg->SetPropertyImage('StringPropertyWithBitmap', $TestBitmap );

	my $multichoices = [ qw( Cabbage Carrot Onion Potato Strawberry ) ];
	my $multivalues = [ qw( Carrot Potato ) ];
	
	my $frame = Wx::GetTopLevelParent( $self );
	

	$pg->Append(Wx::EnumProperty->new('EnumProperty X','EnumProperty X', $multichoices ) );
	
	my $multiprop = $pg->Append(Wx::MultiChoiceProperty->new('MultiChoiceProperty', 'MultiChoiceProperty',
                                          $multichoices, $multivalues ) );
	
	# test use of SetPlValue
	$multiprop->SetPlValue([ qw( Onion Strawberry ) ] );

    $pg->SetPropertyAttribute('MultiChoiceProperty', 'UserStringMode', 1 );
	

     #UInt samples
	#$pg->Append( Wx::UIntProperty( 'UIntProperty', 'UIntProperty', 0xFEEEFEEEFEEE );
	my $bigx = Math::BigInt->new('0xFEEEFEEEFEEE');
	$pg->Append( Wx::UIntProperty->new( 'UIntProperty', 'UIntProperty', $bigx ));
    $pg->SetPropertyAttribute( 'UIntProperty', wxPG_UINT_PREFIX, wxPG_PREFIX_NONE );
    $pg->SetPropertyAttribute( 'UIntProperty', wxPG_UINT_BASE, wxPG_BASE_HEX );

	# wxEditEnumProperty
	my $eech = Wx::PGChoices->new();
    $eech->Add("Choice 1");
    $eech->Add("Choice 2");
    $eech->Add("Choice 3");
	$pg->Append( Wx::EditEnumProperty->new('EditEnumProperty', 'EditEnumProperty',
                    $eech, 'Choice not in the list' ));
	
	#  Test Hint attribute in EditEnumProperty
	$pg->GetProperty("EditEnumProperty")->SetAttribute("Hint", "Dummy Hint");

   	$pg->Append( Wx::DateProperty->new('DateProperty', 'DateProperty', Wx::DateTime::Now() ) );
	$pg->SetPropertyAttribute( 'DateProperty', wxPG_DATE_PICKER_STYLE, wxDP_DROPDOWN | wxDP_SHOWCENTURY | wxDP_ALLOWNONE );

	$pg->SetPropertyHelpString( 'DateProperty',
        'Attribute wxPG_DATE_PICKER_STYLE has been set to wxDP_DROPDOWN|wxDP_SHOWCENTURY|wxDP_ALLOWNONE');

	# A generic parent property (using wxStringProperty).
	#
	my $topId = $pg->Append( Wx::StringProperty->new('3D Object', '3D Object', '<composed>') );

	$pg->AppendIn( $topId, Wx::StringProperty->new('Triangle 1', 'Triangle 1', '1') );
    $pg->AppendIn( $topId, Wx::StringProperty->new('Triangle 2', 'Triangle 2', '2') );
	$pg->AppendIn( $topId, Wx::StringProperty->new('Triangle 3', 'Triangle 3', '3') );

	
	my $carProp = $pg->Append(Wx::StringProperty->new('Car','Car','<composed>'));
	$carProp->AppendChild(Wx::StringProperty->new('Model','Model','Lamborghini Diablo SV'));
	$carProp->AppendChild(Wx::IntProperty->new('Engine Size (cc)','Engine Size (cc)', 5707));
	
	my $speedsProp = $pg->AppendIn($carProp, Wx::StringProperty->new('Speeds','Speeds',
                                              '<composed>'));
	$pg->AppendIn( $speedsProp, Wx::IntProperty->new('Max. Speed (mph)','Max. Speed (mph)', 290) );
	$pg->AppendIn( $speedsProp, Wx::FloatProperty->new('0-100 mph (sec)','0-100 mph (sec)', 3.9) );
	$pg->AppendIn( $speedsProp, Wx::FloatProperty->new('1/4 mile (sec)','1/4 mile (sec)', 8.6) );

	
	# This is how child property can be referred to indirectly by a concatenated name
	$pg->SetPropertyValue( 'Car.Speeds.Max. Speed (mph)', 300 );

	$pg->AppendIn($carProp, Wx::IntProperty->new('Price ($)','Price ($)', 300000 ));
	$pg->AppendIn($carProp, Wx::BoolProperty->new('Convertible','Convertible', 0));

	# Displayed value of "Car" property is now very close to this:
	# "Lamborghini Diablo SV; 5707 [300; 3.9; 8.6] 300000"
	
	
	#    // Test wxSampleMultiButtonEditor
	#    pg->Append( new wxLongStringProperty(wxT("MultipleButtons"), wxPG_LABEL) );
	#    pg->SetPropertyEditor(wxT("MultipleButtons"), m_pSampleMultiButtonEditor );

	
	#    // Test adding variable height bitmaps in wxPGChoices
	my $bc = Wx::PGChoices->new();

	$bc->Add('Wee', Wx::Bitmap->new(16, 16) );
	$bc->Add('Not so wee', Wx::Bitmap->new(32, 32));
	$bc->Add('Really huge', Wx::Bitmap->new(64, 64));

	$pg->Append( Wx::EnumProperty->new('Variable Height Bitmaps','Variable Height Bitmaps',
						$bc, 0));

	#   // Test how non-editable composite strings appear
	my $nprop = Wx::StringProperty->new('wxWidgets Traits', 'wxWidgets Traits', '<composed>');
    $pg->SetPropertyReadOnly($nprop);

	#    //
	#    // For testing purposes, combine two methods of adding children
	#    //

	$nprop->AppendChild( Wx::StringProperty->new('Latest Release','Latest Release','2.9.3'));
	$nprop->AppendChild( Wx::BoolProperty->new('Win API','Win API', 1));
	$pg->Append( $nprop );
	$pg->AppendIn($nprop, Wx::BoolProperty->new('QT', 'QT', 0) );
	$pg->AppendIn($nprop, Wx::BoolProperty->new('Cocoa', 'Cocoa', 1) );
	$pg->AppendIn($nprop, Wx::BoolProperty->new('BeOS', 'BeOS', 0) );
	$pg->AppendIn($nprop, Wx::StringProperty->new('SVN Trunk Version', 'SVN Trunk Version', '2.9.4') );
	$pg->AppendIn($nprop, Wx::BoolProperty->new('GTK+', 'GTK+', 1) );
	$pg->AppendIn($nprop, Wx::BoolProperty->new('Sky OS', 'Sky OS', 0) );

#    AddTestProperties(pg);
}

sub finalise_panel {
	my ( $self, $wascreated ) = @_;
	
	$self->{topsizer}->Add( Wx::Button->new($self->{panel}, wxID_ANY,
                     'Should be able to move here with Tab'),
                     0, wxEXPAND );

    $self->{panel}->SetSizer( $self->{topsizer} );
    $self->{topsizer}->SetSizeHints( $self->{panel} );

    my $mainsizer = Wx::BoxSizer->new( wxVERTICAL );
    $mainsizer->Add( $self->{panel}, 1, wxEXPAND|wxFIXED_MINSIZE );

    $self->SetSizer( $mainsizer );
    $mainsizer->SetSizeHints( $self );

    if ( $wascreated ) {
        # nothing to do in this implementation
	}
	
}

# PG Event Subs

sub OnPropertyGridSelect {
	my ( $self, $event ) = @_;
	my $property = $event->GetProperty();
    if ( $property ) {
        $self->{m_itemEnable}->Enable(1);
        if ( $property->IsEnabled() ) {
            $self->{m_itemEnable}->SetItemLabel( 'Disable' );
		} else {
            $self->{m_itemEnable}->SetItemLabel( 'Enable' );
		}
    } else {
		$self->{m_itemEnable}->Enable( 0 );
    }
}

sub OnPropertyGridChange {
	my ( $self, $event ) = @_;
	my $property = $event->GetProperty();
    my $name = $property->GetName();
	
    #-------------------------------------------------------------------------------------
	#
    # Properties store values internally as wxVariants
	# In most code you'll know what to expect back but
	# you can figure it out for most cases
	#
	# wxPerl provides a couple of convenience methods for
	# Properties that use standard Perl types
	#
	# $property->SetPlValue( $var, [ $flags ] )
	# my $var = $property->GetPlValue( [ $flags ] )
	#
	# The optional '$flags' param has the same meaning as in the SetValue / GetValue methods
	# of each Wx::PGProperty derived control
	#
	# numeric Properties use scalar string values for SetPlValue and GetPLValue for simplified
	# use with Math::BigInt etc on large values.
	#
	# Property types naturaly using string values for GetPlValue and SetPlValue
	#
	#        Wx::DirProperty
	#        Wx::FileProperty
	#        Wx::LongStringProperty
	#        Wx::ImageFileProperty
	#        Wx::PropertyCategory
	#        Wx::StringProperty
	#
	# Numeric Property types using string values for GetPlValue and SetPlValue
	#
	#        Wx::FloatProperty
	#        Wx::IntProperty
	#        Wx::UIntProperty
	#
	# Enumeration and flag types use long integer values for GetPlValue and SetPlValue
	#
	#        Wx::EditEnumProperty
	#        Wx::EnumProperty
	#        Wx::FlagsProperty
	#        Wx::CursorProperty	
	#
	# A couple of property types have array values, These accept an array reference
	# as a param to SetPlValue, and return an array of values from GetPlValue
	#
	#        Wx::ArrayStringProperty
	#        Wx::MultiChoiceProperty
	#
	# The following types use appropriate objects for SetPlValue and GetPlValue
	# ( Wx::Colour, Wx::ColourPropertyValue, Wx::Font, Wx::DateTime )
	#
	#        Wx::ColourProperty
	#        Wx::SystemColourProperty
	#        Wx::FontProperty
	#        Wx::DateProperty	
	#
	# Wx::BoolProperty accepts and returns 1 or 0 as you would expect 
	#
	#        Wx::BoolProperty
	#
	#----------------------------------------------------------------------------------
	
	my $var = $property->GetValue();
	my $vtype = $var->GetType;
	
	my $sclv; # simple
	my $objv; # object
	my @arrv; # array
	
	return if $var->IsNull;
	
	if( $vtype =~ /^(bool|char|double|long|longlong|string|ulonglong)$/) {
		$sclv = $property->GetPlValue;
	} elsif( $vtype =~ /^(datetime|wxColour|wxFont)/) {
		$objv = $property->GetPlValue;
	} elsif( $vtype =~ /^(arrstring|list|wxArrayString|wxArrayInt)/) {
		@arrv = $property->GetPlValue;
	}
		
	my $strval = $property->ValueToString($var);
	
	Wx::LogMessage('Change event triggered for property : %s, type : %s : new value : %s', $name, $vtype, $strval);
	
	if( @arrv ) {
		my $valstr = join( ';', @arrv );
		Wx::LogMessage('GetPlValue array values: %s', $valstr);
	} elsif( $objv ) {
		if( $objv->isa('Wx::DateTime') ) {
			Wx::LogMessage('GetPlValue date string: %s', $objv->FormatDate );
		} elsif( $objv->isa('Wx::Colour') ) {
			Wx::LogMessage('GetPlValue colour string: %s', $objv->GetAsString( wxC2S_HTML_SYNTAX ));
		} elsif( $objv->isa('Wx::ColourPropertyValue') ) {
			Wx::LogMessage('GetPlValue colour value string: %s', $objv->GetColour->GetAsString( wxC2S_HTML_SYNTAX ));
		} elsif( $objv->isa('Wx::Font') ) {
			Wx::LogMessage('GetPlValue Font string: %s', $objv->GetNativeFontInfoDesc );
		}
	} elsif( defined($sclv) ) {
		Wx::LogMessage('GetPlValue value string: %s', $sclv );
	}
	
    if ( $name eq 'Font' ) {
		$self->{manager}->SetFont( $objv );
	} elsif ( $name eq 'Margin Colour' ) {
		$self->{manager}->GetGrid->SetMarginColour( $objv );
	} elsif ( $name eq 'Cell Colour' ) {
		# this is a Wx::SystemColourProperty so the object value
		# is a Wx::ColourPropertyValue
		$self->{manager}->GetGrid->SetCellBackgroundColour( $objv->GetColour );
    } elsif ( $name eq 'Line Colour' ) {
		$self->{manager}->GetGrid->SetLineColour( $objv );
	} elsif ( $name eq 'Cell Text Colour' ) {
		$self->{manager}->GetGrid->SetCellTextColour( $objv );
    }

}

sub OnPropertyGridChanging {
	my ( $self, $event ) = @_;
	my $p = $event->GetProperty();
    if ( $p->GetName eq 'Font' ) {
		my $res = Wx::MessageBox(
			sprintf(qq(%s is about to change to %s. \n\nAllow Change?), $p->GetName, $p->GetValueAsString),
			'Testing wxEVT_PG_CHANGING and Veto',
			wxYES_NO,
			$self
		);
        if ( $res == wxNO  && $event->CanVeto ) {
            $event->Veto;
            # Since we ask a question, it is better if we omit any validation
            # failure behaviour.
            $event->SetValidationFailureBehavior(0);
        }
    }
}

sub OnPropertyGridHighlight {
	my ( $self, $event ) = @_;
	
}

sub OnPropertyGridItemRightClick {
	my ( $self, $event ) = @_;
	my $prop = $event->GetProperty();
    if ( $prop ) {
		# Wx::FlagsProperty uses GetLabel( $n ) where $n is the index of the subitem label required
		my $label = ( $prop->isa('Wx::FlagsProperty') ) ? $prop->GetName : $prop->GetLabel;
		Wx::LogMessage('Property Labelled "%s" ( %s ) was right clicked', $label, $prop->GetName );
    }
}

sub OnPropertyGridItemDoubleClick {
	my ( $self, $event ) = @_;
	my $prop = $event->GetProperty();
    if ( $prop ) {
		# Wx::FlagsProperty uses GetLabel( $n ) where $n is the index of the subitem label required
		my $label = ( $prop->isa('Wx::FlagsProperty') ) ? $prop->GetName : $prop->GetLabel;
		Wx::LogMessage('Property Labelled "%s" ( %s ) was double clicked', $label, $prop->GetName );
    }
	
}

sub OnPropertyGridPageChange {
	my ( $self, $event ) = @_;
	
}

sub OnPropertyGridLabelEditBegin {
	my ( $self, $event ) = @_;
    Wx::LogMessage('wxPG_EVT_LABEL_EDIT_BEGIN( %s )', $event->GetProperty->GetLabel);
}

sub OnPropertyGridLabelEditEnding {
	my ( $self, $event ) = @_;
    Wx::LogMessage('wxPG_EVT_LABEL_EDIT_ENDING( %s )', $event->GetProperty->GetLabel);	
}

sub OnPropertyGridButtonClick {
	my ( $self, $event ) = @_;
	
}

sub OnPropertyGridItemCollapse {
	my ( $self, $event ) = @_;
	
}

sub OnPropertyGridItemExpand {
	my ( $self, $event ) = @_;
	
}

sub OnPropertyGridColBeginDrag {
	my ( $self, $event ) = @_;
	
}

sub OnPropertyGridColDragging {
	my ( $self, $event ) = @_;
	
}

sub OnPropertyGridColEndDrag {
	my ( $self, $event ) = @_;
	
}


# ************** Menu Event Subs

sub OnAppendPropClick {
	my( $self, $event ) = @_;
	
}

sub OnAppendCatClick {
	my( $self, $event ) = @_;
	
}

sub OnInsertPropClick {
	my( $self, $event ) = @_;
	
}

sub OnInsertCatClick {
	my( $self, $event ) = @_;
	
}

sub OnDelPropClick {
	my( $self, $event ) = @_;
	
}

sub OnDelPropRClick {
	my( $self, $event ) = @_;
	
}

sub OnMisc {
	my( $self, $event ) = @_;
	
}

sub OnClearClick {
	my( $self, $event ) = @_;
	
}

sub OnEnableDisable {
	my( $self, $event ) = @_;
	
}

sub OnSetReadOnly {
	my( $self, $event ) = @_;
	
}

sub OnHide {
	my( $self, $event ) = @_;
	
}

sub OnIterate1Click {
	my( $self, $event ) = @_;
	
}

sub OnIterate2Click {
	my( $self, $event ) = @_;
	
}

sub OnIterate3Click {
	my( $self, $event ) = @_;
	
}

sub OnIterate4Click {
	my( $self, $event ) = @_;
	
}

sub OnSetBackgroundColour {
	my( $self, $event ) = @_;
	
}

sub OnClearModifyStatusClick {
	my( $self, $event ) = @_;
	
}

sub OnFreezeClick {
	my( $self, $event ) = @_;
	
}

sub OnEnableLabelEditing {
	my( $self, $event ) = @_;
	
}

sub OnShowHeader {
	my( $self, $event ) = @_;
	
}

sub OnDumpList {
	my( $self, $event ) = @_;
	
}

sub OnColourScheme {
	my( $self, $event ) = @_;
	
}

sub OnSetColours {
	my( $self, $event ) = @_;
	
}

sub OnEnableCommonValues {
	my( $self, $event ) = @_;
	
}

sub OnSelectStyle {
	my( $self, $event ) = @_;
	
}

sub OnPopulateClick {
	my( $self, $event ) = @_;
	
}

sub OnFitColumnsClick {
	my( $self, $event ) = @_;
	
}

sub OnChangeFlagsPropItemsClick {
	my( $self, $event ) = @_;
	
}

sub OnInsertChoice {
	my( $self, $event ) = @_;
	
}

sub OnDeleteChoice {
	my( $self, $event ) = @_;
	
}

sub OnInsertPage {
	my( $self, $event ) = @_;
	
}

sub OnRemovePage {
	my( $self, $event ) = @_;
	
}

sub OnSaveState {
	my( $self, $event ) = @_;
	
}

sub OnRestoreState {
	my( $self, $event ) = @_;
	
}

sub OnSetSpinCtrlEditorClick {
	my( $self, $event ) = @_;
	
}

sub OnTestReplaceClick {
	my( $self, $event ) = @_;
	
}

sub OnSetPropertyValue {
	my( $self, $event ) = @_;
	
}


######################################################


eval { return Wx::_wx_optmod_propgrid(); };
