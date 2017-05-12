package Wrangler::Wx::Dialog::Settings;

use strict;
use warnings;

use Wx qw(:listctrl wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER wxCLOSE_BOX wxLB_LEFT wxCLIP_CHILDREN wxHORIZONTAL wxID_OK wxALL wxGROW wxALIGN_RIGHT);
use Wx::Event qw(EVT_BUTTON EVT_LIST_ITEM_ACTIVATED EVT_LIST_ITEM_SELECTED);
use base 'Wx::Dialog';

sub new {
	my $class = shift;
	my $parent = shift;
	my $preselect = shift;
	my $preselect_sub = shift;

	# Set up the dialog
	my $self = $class->SUPER::new($parent, -1, "Settings", wxDefaultPosition, [600,550], wxDEFAULT_DIALOG_STYLE | wxRESIZE_BORDER);

	my $sizer = Wx::FlexGridSizer->new(3, 1, 0, 0);	# rows,cols,vgap,hgap
	$sizer->AddGrowableCol(0); # zerobased
	$sizer->AddGrowableRow(0); # zerobased
	$self->SetSizer($sizer);

	# do a listbook
	my $nb = Wx::Listbook->new( $self, -1, wxDefaultPosition, wxDefaultSize, wxLB_LEFT | wxCLIP_CHILDREN );
	$nb->{wrangler} = $parent->{wrangler}; # hook-up access to $wrangler
	my %page;
	$page{0} = Wrangler::Wx::Dialog::Settings::Wrangler->new($nb);
	$page{1} = Wrangler::Wx::Dialog::Settings::FileBrowser->new($nb);
	$page{2} = Wrangler::Wx::Dialog::Settings::Previewer->new($nb);
	$page{3} = Wrangler::Wx::Dialog::Settings::Plugins->new($nb);
	$nb->AddPage( $page{0}, "General", 0);
	$nb->AddPage( $page{1}, "FileBrowser", 0);
	$nb->AddPage( $page{2}, "Previewer", 0);
	$nb->AddPage( $page{3}, "Plugins", 0);
	$sizer->Add($nb, 0, wxALL|wxGROW, 5);

	## allow caller to preselect a page/subpage
	$nb->ChangeSelection($preselect) if defined($preselect); # zerobased
	$page{$preselect}->ChangeSelection($preselect_sub) if defined($preselect) && defined($preselect_sub) && defined($page{$preselect_sub}); # zerobased

	## button
	my $btn_sizer = new Wx::BoxSizer(wxHORIZONTAL);
	$btn_sizer->Add(Wx::Button->new($self, wxID_OK, 'OK'), 0, wxALL, 2);
	$sizer->Add($btn_sizer, 0, wxALL|wxALIGN_RIGHT, 5);

	EVT_BUTTON($self, wxID_OK, sub {
		# print "Settings: OK\n";
		$_[1]->Skip(1);
	});

	$self->Centre();
	$self->Show();

	return $self;
}


package Wrangler::Wx::Dialog::Settings::Wrangler;

use strict;
use warnings;

use Wx qw(wxVERTICAL wxDefaultPosition wxDefaultSize wxEXPAND wxCB_DROPDOWN wxCB_READONLY wxBOTTOM wxALL wxLC_REPORT wxLIST_FORMAT_LEFT wxGROW wxLIST_STATE_SELECTED wxLIST_NEXT_ALL wxID_OK);
use Wx::Event qw(EVT_MENU EVT_CHECKBOX EVT_LIST_ITEM_RIGHT_CLICK);
use base 'Wx::Notebook';

sub new {
	my $class = shift;
	my $parent = shift;

	my $self = $class->SUPER::new($parent, -1, wxDefaultPosition, wxDefaultSize, wxEXPAND);

	# hook-up access to $wrangler
	$self->{wrangler} = $parent->{wrangler};
	my $config = $self->{wrangler}->config();


	## Panel 1
	my $panel_1 = Wx::Panel->new($self);
	$self->AddPage( $panel_1, "Appearance", 0);

	# language
			my $combo_language	= Wx::ComboBox->new($panel_1, -1, 'English (default)', wxDefaultPosition, wxDefaultSize,
				[
					'English (default)',
					'Deutsch',
				], wxCB_DROPDOWN|wxCB_READONLY
			);
			my @LangSel = ('en','de');
			my %LangSel = ( en => 0, de => 1 );
			$combo_language->SetClientData(0, $LangSel[0]);
			$combo_language->SetClientData(1, $LangSel[1]);
#			$combo_language->SetSelection($LangSel{ $Wrangler::U{Language} });

		my $language_sizer = Wx::FlexGridSizer->new(1,1); # rows,cols,vgap,hgap
		$language_sizer->Add($combo_language, 1, wxALL, 5);
	my $language_boxsizer = Wx::StaticBoxSizer->new( Wx::StaticBox->new($panel_1, -1, "Language"), wxVERTICAL);
	$language_boxsizer->Add($language_sizer, 1, wxALL, 10);

	# widgets
			my $check_show_menubar = Wx::CheckBox->new($panel_1, -1, 'Show MenuBar on top');
			$check_show_menubar->SetToolTip("Show a traditional 'File', 'Help' etc. menu below the window's title-bar");
			$check_show_menubar->SetValue( $config->{'ui.layout.menubar'} || 0);
			my $check_show_navbar = Wx::CheckBox->new($panel_1, -1, 'Show Navbar');
			$check_show_navbar->SetToolTip("Show a widget that displays current folder/path");
			$check_show_navbar->SetValue( $config->{'ui.layout.navbar'} || 0);
			my $check_show_sidebar = Wx::CheckBox->new($panel_1, -1, 'Show Sidebar');
			$check_show_sidebar->SetToolTip("Show a Sidebar with quick-links to Devices, Bookmarks");
			$check_show_sidebar->SetValue( $config->{'ui.layout.sidebar'} || 0);
			my $check_show_statusbar = Wx::CheckBox->new($panel_1, -1, 'Show Statusbar on bottom');
			$check_show_statusbar->SetToolTip("Show a StatusBar on the bottom of the window");
			$check_show_statusbar->SetValue( $config->{'ui.layout.statusbar'} || 0);

		my $widgets_sizer = Wx::FlexGridSizer->new(4,1); # rows,cols,vgap,hgap
		$widgets_sizer->Add($check_show_menubar, 1, wxALL, 5);
		$widgets_sizer->Add($check_show_navbar, 1, wxALL, 5);		
		$widgets_sizer->Add($check_show_sidebar, 1, wxALL, 5);
		$widgets_sizer->Add($check_show_statusbar, 1, wxALL, 5);

	my $widgets_boxsizer = Wx::StaticBoxSizer->new( Wx::StaticBox->new($panel_1, -1, "Widgets"), wxVERTICAL);
	$widgets_boxsizer->Add($widgets_sizer, 1, wxALL, 10);


	# panel 1 sizer
		my $panel_1_sizer = Wx::FlexGridSizer->new(2,1,10); # rows,cols,vgap,hgap
		$panel_1_sizer->AddGrowableCol(0); # zerobased
		$panel_1_sizer->Add($language_boxsizer, 1, wxGROW);
		$panel_1_sizer->Add($widgets_boxsizer, 1, wxGROW);

	$panel_1->SetSizer($panel_1_sizer);

	# panel 1 events
	EVT_CHECKBOX($self, $check_show_menubar, sub {
		$self->{wrangler}->config()->{'ui.layout.menubar'} = $_[1]->IsChecked() || 0;
		Wrangler::PubSub::publish('main.menubar.toggle', $_[1]->IsChecked() || 0 );
	});
	EVT_CHECKBOX($self, $check_show_navbar, sub {
		$self->{wrangler}->config()->{'ui.layout.navbar'} = $_[1]->IsChecked() || 0;
		Wrangler::PubSub::publish('main.navbar.toggle');
	});
	EVT_CHECKBOX($self, $check_show_sidebar, sub {
		$self->{wrangler}->config()->{'ui.layout.sidebar'} = $_[1]->IsChecked() || 0;
		Wrangler::PubSub::publish('main.sidebar.toggle');
	});
	EVT_CHECKBOX($self, $check_show_statusbar, sub {
		$self->{wrangler}->config()->{'ui.layout.statusbar'} = $_[1]->IsChecked() || 0;
		Wrangler::PubSub::publish('main.statusbar.toggle', $_[1]->IsChecked() || 0 );
	});


	## Panel 2: General(Wrangler): ValueShortcuts
	my $panel_2 = Wx::Panel->new($self);
	$self->AddPage( $panel_2, "Value Shortcuts", 0);


	# columns
	$self->{listctrl} = Wx::ListCtrl->new($panel_2, -1, wxDefaultPosition, wxDefaultSize, wxLC_REPORT);
	$self->{listctrl}->InsertColumn( 1, 'Keyboard Shortcut', wxLIST_FORMAT_LEFT, 100 );
	$self->{listctrl}->InsertColumn( 2, 'Insert into... (key)', wxLIST_FORMAT_LEFT, 250 );
	$self->{listctrl}->InsertColumn( 3, 'Data value', wxLIST_FORMAT_LEFT, 100 );

	my $sizer = Wx::FlexGridSizer->new(2, 1, 20, 0); # rows,cols,vgap,hgap
	$sizer->AddGrowableCol(0); # zerobased
	$sizer->AddGrowableRow(1); # zerobased
	$sizer->Add( Wx::StaticText->new($panel_2, -1, 'Wrangler offers a facility where users can define their own "Value Shortcuts". These are keyboard-shortcuts that trigger pre-defined user strings to be entered into data fields.'."\n\n".'Associating a metadata-key with a shortcut will insert the pre-defined string into this field without having to jump into the respective form-field; leaving the metadata-key blank means the data-string will be pasted at cursor position.', wxDefaultPosition, wxDefaultSize), 0, wxEXPAND|wxALL, 10 );
	$sizer->Add($self->{listctrl}, 0, wxALL|wxGROW, 5);

	$panel_2->SetSizer($sizer);

	## Panel 2 events
	EVT_LIST_ITEM_RIGHT_CLICK($self, $self->{listctrl}, sub { OnRightClick(@_); });

	$self->Populate();

	return $self;
}

sub GetSelections {
	return () unless $_[0]->{listctrl}->GetSelectedItemCount(); # untested optimisation

	my @selections;
	my $currId = -1;
	for(;;){
		$currId = $_[0]->{listctrl}->GetNextItem($currId, wxLIST_NEXT_ALL, wxLIST_STATE_SELECTED);
		if($currId == -1){
			last;
		}else{
			push(@selections, $currId);
		}
	}

	return wantarray ? @selections : \@selections;
}

sub Populate {
	my $settings = shift;
	my $shortcuts =  $settings->{wrangler}->config()->{'valueshortcuts'} || {};

	$settings->{listctrl}->DeleteAllItems();

	my $prop_ref = $settings->{wrangler}->{fs}->available_properties($settings->{wrangler}->{current_dir});

	my $rowCnt = 0;
	for(keys %$shortcuts){
		$settings->{lookup}->[$rowCnt] = $_;

		# InsertItem returns a numeric $itemId
		my $itemId = $settings->{listctrl}->InsertStringItem( $rowCnt, $shortcuts->{$_}->{name});
		$settings->{listctrl}->SetItem( $itemId, 1, $shortcuts->{$_}->{key} );
		$settings->{listctrl}->SetItem( $itemId, 2, $shortcuts->{$_}->{value} );
		$rowCnt++;
	}
}

sub Add {
	my $settings = shift;

	require Wrangler::Wx::Dialog::ShortcutCollector;
	my $dialog = Wrangler::Wx::Dialog::ShortcutCollector->new($settings);

	return unless $dialog->ShowModal() == wxID_OK;

	my $shortcuts = $settings->{wrangler}->config()->{'valueshortcuts'};
	$shortcuts->{ $dialog->{result_keycodes} } = {
		name	=> $dialog->{result_human},
		key	=> '',
		value	=> '',
	};

	$settings->Populate();
}

sub ChangeShortcut {
	my $settings = shift;

	require Wrangler::Wx::Dialog::ShortcutCollector;
	my $dialog = Wrangler::Wx::Dialog::ShortcutCollector->new($settings);

	return unless $dialog->ShowModal() == wxID_OK;

	my @selections = $settings->GetSelections();
	my $id = $settings->{listctrl}->GetItem($selections[0]);
	my $pos = $id->GetId;

	my $shortcuts = $settings->{wrangler}->config()->{'valueshortcuts'};
	my $shortcut = $shortcuts->{ $settings->{lookup}->[$pos] };

	$shortcuts->{ $dialog->{result_keycodes} } = {
		name	=> $dialog->{result_human},
		key	=> $shortcut->{key},
		value	=> $shortcut->{value},
	};
	delete($shortcuts->{ $settings->{lookup}->[$pos] });

	$settings->Populate();
}

sub ChangeValue {
	my $settings = shift;

	my @selections = $settings->GetSelections();
	my $id = $settings->{listctrl}->GetItem($selections[0]);
	my $pos = $id->GetId;

	my $shortcuts = $settings->{wrangler}->config()->{'valueshortcuts'};
	my $shortcut = $shortcuts->{ $settings->{lookup}->[$pos] };

	my $dialog = Wx::TextEntryDialog->new($settings, "Change data value", "Change data value", $shortcut->{value} );

	return unless $dialog->ShowModal() == wxID_OK;

	$shortcut->{value} = $dialog->GetValue();

	$dialog->Destroy();

	$settings->Populate();
}

sub ChangeField {
	my $settings = shift;
	my $field_name = shift;

	my @selections = $settings->GetSelections();
	my $id = $settings->{listctrl}->GetItem($selections[0]);
	my $pos = $id->GetId;

	my $shortcuts = $settings->{wrangler}->config()->{'valueshortcuts'};
	my $shortcut = $shortcuts->{ $settings->{lookup}->[$pos] };

	if($field_name eq '[none]'){
		$shortcut->{key} = undef;
	}elsif($field_name){
		$shortcut->{key} = $field_name;
	}else{
		my $dialog = Wx::TextEntryDialog->new($settings, "Change associated field", "Change associated field", $shortcut->{key});

		return unless $dialog->ShowModal() == wxID_OK;

		$field_name = $dialog->GetValue();
		$shortcut->{key} = $field_name;

		$dialog->Destroy();
	}

	$settings->Populate();
}

sub Remove {
	my $settings = shift;

	my @selections = $settings->GetSelections();

	my $id = $settings->{listctrl}->GetItem($selections[0]);
	my $pos = $id->GetId;

	my $shortcuts = $settings->{wrangler}->config()->{'valueshortcuts'};

	delete($shortcuts->{ $settings->{lookup}->[$pos] });

	$settings->Populate();
}

sub OnRightClick {
	my $settings = shift;
	my $event = shift;

        my $menu = Wx::Menu->new();

	my @selections = $settings->GetSelections();

	EVT_MENU( $settings, $menu->Append(-1, "Add a new Shortcut", 'Add a new Value Shortcut' ),	sub { $settings->Add(); } );
	if( defined($selections[0]) ){
		$menu->AppendSeparator();
		EVT_MENU( $settings, $menu->Append(-1, "Change Shortcut", 'Change selected Value Shortcut' ),	sub { $settings->ChangeShortcut(); } );
			my $submenu = Wx::Menu->new();
			for( @{ $settings->{wrangler}->{fs}->available_properties($settings->{wrangler}->{current_dir}) } ){
				my $item = $submenu->Append(-1, $_);
				$submenu->Enable($item->GetId(),0) unless $settings->{wrangler}->{fs}->can_mod($_);
				EVT_MENU( $settings, $item, sub { $settings->ChangeField($item->GetText()); } ); # deprecated: use GetItemLabel text soon
			}
			$submenu->AppendSeparator();
			my $itemOther = $submenu->Append(-1, 'Other...');
			EVT_MENU( $settings, $itemOther, sub { $settings->ChangeField(); } );
			$submenu->AppendSeparator();
			my $itemNone = $submenu->Append(-1, '[none]');
			EVT_MENU( $settings, $itemNone, sub { $settings->ChangeField('[none]'); } );
		$menu->Append(-1, "Associate field...", $submenu, 'Associate this shortcut with a metadata-key/field' );
		EVT_MENU( $settings, $menu->Append(-1, "Change value", 'Change data value' ),	sub { $settings->ChangeValue(); } );
		$menu->AppendSeparator();
		EVT_MENU( $settings, $menu->Append(-1, "Delete selected Shortcut", 'Delete this Value Shortcut' ),	sub { $settings->Remove(); } );
	}

	$settings->PopupMenu( $menu, wxDefaultPosition );
}


package Wrangler::Wx::Dialog::Settings::FileBrowser;

use strict;
use warnings;

use Wx qw(:listctrl wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxEXPAND wxVERTICAL wxLEFT wxTOP wxBOTTOM wxRIGHT wxRESIZE_BORDER wxHORIZONTAL wxID_CANCEL wxID_OK wxALL wxGROW wxALIGN_RIGHT wxFD_SAVE wxFD_OPEN);
use Wx::Event qw(EVT_CHECKBOX EVT_TEXT EVT_COLOURPICKER_CHANGED EVT_LIST_ITEM_ACTIVATED EVT_LIST_ITEM_SELECTED EVT_LIST_ITEM_RIGHT_CLICK EVT_MENU EVT_LIST_BEGIN_DRAG);
use base 'Wx::Notebook';
use JSON::XS ();
use Path::Tiny;

sub new {
	my $class = shift;
	my $parent = shift;

	my $self = $class->SUPER::new($parent, -1);

	# hook-up access to $wrangler
	$self->{wrangler} = $parent->{wrangler};
	my $config = $self->{wrangler}->config();


	## Panel 1
	my $panel_1 = Wx::Panel->new($self);
	$self->AddPage( $panel_1, "Appearance", 0);

	# listing
			my $check_include_hidden = Wx::CheckBox->new($panel_1, -1, 'Show hidden files (dotfiles)');
			$check_include_hidden->SetToolTip("Check to enable this");
			$check_include_hidden->SetValue( $config->{'ui.filebrowser.include_hidden'} || 0);
			my $check_include_updir = Wx::CheckBox->new($panel_1, -1, 'Include up-dir (..)');
			$check_include_updir->SetToolTip('If you use the Navbar, you may want to omit the "go up" entry in file-listings');
			$check_include_updir->SetValue( $config->{'ui.filebrowser.include_updir'} || 0);
			my $check_zebra_striping = Wx::CheckBox->new($panel_1, -1, 'Use "Zebra-Striping"');
			$check_zebra_striping->SetToolTip("Check to enable this");
			$check_zebra_striping->SetValue( $config->{'ui.filebrowser.zebra_striping'} || 0);

		my $listing_sizer = Wx::FlexGridSizer->new(4,1); # rows,cols,vgap,hgap
		$listing_sizer->Add($check_include_hidden, 1, wxALL, 5);
		$listing_sizer->Add($check_include_updir, 1, wxALL, 5);
		$listing_sizer->Add($check_zebra_striping, 1, wxALL, 5);
	my $listing_boxsizer = Wx::StaticBoxSizer->new( Wx::StaticBox->new($panel_1, -1, "Listing"), wxVERTICAL);
	$listing_boxsizer->Add($listing_sizer, 1, wxALL, 10);

	# highlighting
				my $check_highlight_media = Wx::CheckBox->new($panel_1, -1, 'Highlight media files');
				$check_highlight_media->SetToolTip("Check to enable this");
				$check_highlight_media->SetValue( $config->{'ui.filebrowser.highlight_media'} || 0);

				my $highlight_audio_label	= Wx::StaticText->new($panel_1, -1, "Audio files");
				my $highlight_audio	= Wx::ColourPickerCtrl->new($panel_1, -1, Wx::Colour->new(@{$config->{'ui.filebrowser.highlight_colour.audio'}}) );
				my $highlight_image_label	= Wx::StaticText->new($panel_1, -1, "Image files");
				my $highlight_image	= Wx::ColourPickerCtrl->new($panel_1, -1, Wx::Colour->new(@{$config->{'ui.filebrowser.highlight_colour.image'}}) );
				my $highlight_video_label	= Wx::StaticText->new($panel_1, -1, "Video files");
				my $highlight_video	= Wx::ColourPickerCtrl->new($panel_1, -1, Wx::Colour->new(@{$config->{'ui.filebrowser.highlight_colour.video'}}) );

			my $highlighting_sizer = Wx::FlexGridSizer->new(3,2); # rows,cols,vgap,hgap
			$highlighting_sizer->Add($highlight_audio_label, 1, wxTOP, 5);
			$highlighting_sizer->Add($highlight_audio, 1);
			$highlighting_sizer->Add($highlight_image_label, 1, wxTOP, 5);
			$highlighting_sizer->Add($highlight_image, 1);
			$highlighting_sizer->Add($highlight_video_label, 1, wxTOP, 5);
			$highlighting_sizer->Add($highlight_video, 1);

		my $highlighting_subsizer = Wx::FlexGridSizer->new(2, 1, 10);	# rows,cols,vgap,hgap
		$highlighting_subsizer->AddGrowableRow(1); # zerobased
		$highlighting_subsizer->Add($check_highlight_media);		
		$highlighting_subsizer->Add($highlighting_sizer);

	my $highlighting_boxsizer = Wx::StaticBoxSizer->new( Wx::StaticBox->new($panel_1, -1, "File Highlighting"), wxVERTICAL);
	$highlighting_boxsizer->Add($highlighting_subsizer, 1, wxALL, 10);

	# panel 1 sizer
		my $panel_1_sizer = Wx::FlexGridSizer->new(3,1,10); # rows,cols,vgap,hgap
		$panel_1_sizer->AddGrowableCol(0); # zerobased
		$panel_1_sizer->Add($listing_boxsizer, 1, wxGROW);
		$panel_1_sizer->Add($highlighting_boxsizer, 1, wxGROW);

	$panel_1->SetSizer($panel_1_sizer);

	# panel 1 events
	EVT_CHECKBOX($self, $check_include_hidden, sub {
		# print "check_include_hidden: ".$_[1]->IsChecked()."->".$self->{wrangler}->config('ui.filebrowser.include_hidden')."\n";
		$self->{wrangler}->config()->{'ui.filebrowser.include_hidden'} = $_[1]->IsChecked() || 0;
		Wrangler::PubSub::publish('filebrowser.refresh');
	});
	EVT_CHECKBOX($self, $check_include_updir, sub {
		# print "check_include_updir: ".$_[1]->IsChecked()."->".$self->{wrangler}->config('ui.filebrowser.include_updir')."\n";
		$self->{wrangler}->config()->{'ui.filebrowser.include_updir'} = $_[1]->IsChecked() || 0;
		Wrangler::PubSub::publish('filebrowser.refresh');
	});
	EVT_CHECKBOX($self, $check_zebra_striping, sub {
		# print "check_zebra_striping: ".$_[1]->IsChecked()."->".$self->{wrangler}->config('ui.filebrowser.zebra_striping')."\n";
		$self->{wrangler}->config()->{'ui.filebrowser.zebra_striping'} = $_[1]->IsChecked() || 0;
		Wrangler::PubSub::publish('filebrowser.refresh');
	});
	EVT_CHECKBOX($self, $check_highlight_media, sub {
		# print "check_highlight_media: ".$_[1]->IsChecked()."->".$self->{wrangler}->config('ui.filebrowser.highlight_media')."\n";
		$self->{wrangler}->config()->{'ui.filebrowser.highlight_media'} = $_[1]->IsChecked() || 0;
		Wrangler::PubSub::publish('filebrowser.refresh.all'); # refresh.all, as we need to update $wishlist registration
	});
	EVT_COLOURPICKER_CHANGED($self, $highlight_audio, sub {
		$self->{wrangler}->config()->{'ui.filebrowser.highlight_colour.audio'} = [ $_[1]->GetColour()->Red(), $_[1]->GetColour()->Green(), $_[1]->GetColour()->Blue() ];
		Wrangler::PubSub::publish('filebrowser.refresh');
	});
	EVT_COLOURPICKER_CHANGED($self, $highlight_image, sub {
		$self->{wrangler}->config()->{'ui.filebrowser.highlight_colour.image'} = [ $_[1]->GetColour()->Red(), $_[1]->GetColour()->Green(), $_[1]->GetColour()->Blue() ];
		Wrangler::PubSub::publish('filebrowser.refresh');
	});
	EVT_COLOURPICKER_CHANGED($self, $highlight_video, sub {
		$self->{wrangler}->config()->{'ui.filebrowser.highlight_colour.video'} = [ $_[1]->GetColour()->Red(), $_[1]->GetColour()->Green(), $_[1]->GetColour()->Blue() ];
		Wrangler::PubSub::publish('filebrowser.refresh');
	});


	## Panel 2
	my $panel_2 = Wx::Panel->new($self);
	$self->AddPage( $panel_2, "Behaviour", 0);

	# Behaviour: Operations
			my $check_offer_delete = Wx::CheckBox->new($panel_2, -1, "Offer a 'delete' in addition to trash");
			$check_offer_delete->SetToolTip("Check to enable this");
			$check_offer_delete->SetValue( $config->{'ui.filebrowser.offer.delete'} || 0);
			my $check_confirm_delete = Wx::CheckBox->new($panel_2, -1, "Ask user to confirm real 'delete's");
			$check_confirm_delete->SetToolTip("Check to enable this");
			$check_confirm_delete->SetValue( $config->{'ui.filebrowser.confirm.delete'} || 0);
			my $check_copy_preserves = Wx::CheckBox->new($panel_2, -1, "'copy' preserves xattribs");
			$check_copy_preserves->SetToolTip("Normally extended attributes are not copied. This here enables preservation of xattr on copy.");
			$check_copy_preserves->SetValue( $config->{'ui.filebrowser.copy.preserve_xattribs'} || 0);

		my $behaviour_sizer = Wx::FlexGridSizer->new(2,1); # rows,cols,vgap,hgap
		$behaviour_sizer->Add($check_offer_delete, 1, wxALL, 5);
		$behaviour_sizer->Add($check_confirm_delete, 1, wxALL, 5);
		$behaviour_sizer->Add($check_copy_preserves, 1, wxALL, 5);
	my $behaviour_boxsizer = Wx::StaticBoxSizer->new( Wx::StaticBox->new($panel_2, -1, "Operations"), wxVERTICAL);
	$behaviour_boxsizer->Add($behaviour_sizer, 1, wxALL, 10);

	# Behaviour: Sorting
			my $check_per_directory_sorting = Wx::CheckBox->new($panel_2, -1, "Remember sorting 'per directory'");
			$check_per_directory_sorting->SetToolTip("Check to enable this");
			$check_per_directory_sorting->SetValue( $config->{'ui.filebrowser.sorting.per_directory'} || 0);

		my $sorting_flexsizer = Wx::FlexGridSizer->new(2,1); # rows,cols,vgap,hgap
		$sorting_flexsizer->Add( Wx::StaticText->new($panel_2, -1, "By default, FileBrowser will remember sorting globally. Checking\nthis here will tell Wrangler to remember sorting per directory.", wxDefaultPosition, wxDefaultSize), 1, wxALL, 5);
		$sorting_flexsizer->Add($check_per_directory_sorting, 1, wxALL, 5);

	my $sorting_boxsizer = Wx::StaticBoxSizer->new( Wx::StaticBox->new($panel_2, -1, "Sorting"), wxVERTICAL);
	$sorting_boxsizer->Add( $sorting_flexsizer, 0, wxALL, 10 );

	# Behaviour: Change Monitoring
				my $monitoring_pull_timeout = Wx::TextCtrl->new($panel_2, -1, $self->{wrangler}->config()->{'ui.filebrowser.pull_monitor_timeout'} ? ($self->{wrangler}->config()->{'ui.filebrowser.pull_monitor_timeout'} / 1000) : 7);

			my $input_sizer = Wx::BoxSizer->new(wxHORIZONTAL);
			$input_sizer->Add( $monitoring_pull_timeout, 0, wxRIGHT, 5 );
			$input_sizer->Add( Wx::StaticText->new($panel_2, -1, 'seconds', wxDefaultPosition, wxDefaultSize), 1, wxTOP, 7);

		my $monitoring_sizer = Wx::FlexGridSizer->new(2,1); # rows,cols,vgap,hgap
		$monitoring_sizer->Add( Wx::StaticText->new($panel_2, -1, "FileBrowser is currently only able to track directory changes\nin simple 'pull'-mode. This here sets the poll intervall\nbetween mtime checks.", wxDefaultPosition, wxDefaultSize), 1, wxALL, 5);
		$monitoring_sizer->Add($input_sizer, 1, wxALL, 5);

	my $monitoring_boxsizer = Wx::StaticBoxSizer->new( Wx::StaticBox->new($panel_2, -1, "Change monitoring"), wxVERTICAL);
	$monitoring_boxsizer->Add( $monitoring_sizer, 0, wxALL, 10 );

	# panel 2 sizer
		my $panel_2_sizer = Wx::FlexGridSizer->new(3,1,10); # rows,cols,vgap,hgap
		$panel_2_sizer->AddGrowableCol(0); # zerobased
		$panel_2_sizer->Add($behaviour_boxsizer, 1, wxGROW);
		$panel_2_sizer->Add($sorting_boxsizer, 1, wxGROW);
		$panel_2_sizer->Add($monitoring_boxsizer, 1, wxGROW);

	$panel_2->SetSizer($panel_2_sizer);

	# panel 2 events
	EVT_CHECKBOX($self, $check_offer_delete, sub {
		$self->{wrangler}->config()->{'ui.filebrowser.offer.delete'} = $_[1]->IsChecked() || 0;
	});
	EVT_CHECKBOX($self, $check_confirm_delete, sub {
		$self->{wrangler}->config()->{'ui.filebrowser.confirm.delete'} = $_[1]->IsChecked() || 0;
	});
	EVT_CHECKBOX($self, $check_copy_preserves, sub {
		$self->{wrangler}->config()->{'ui.filebrowser.copy.preserve_xattribs'} = $_[1]->IsChecked() || 0;
	});
	EVT_CHECKBOX($self, $check_per_directory_sorting, sub {
		$self->{wrangler}->config()->{'ui.filebrowser.sorting.per_directory'} = $_[1]->IsChecked() || 0;
		$self->{wrangler}->config()->{'ui.filebrowser.sort'} = {} if ref($self->{wrangler}->config()->{'ui.filebrowser.sort'}) eq 'ARRAY';
	});
	EVT_TEXT($self, $monitoring_pull_timeout, sub {
		my $value = int($monitoring_pull_timeout->GetValue());
		if($value && $value != 7){
			Wrangler::debug("Settings::FileBrowser: pull_monitor_timeout $value");
			$_[0]->{wrangler}->config()->{'ui.filebrowser.pull_monitor_timeout'} = ($value * 1000);
		}else{
			Wrangler::debug("Settings::FileBrowser: remove custom pull_monitor_timeout");
			my $config = $_[0]->{wrangler}->config();
			delete($config->{'ui.filebrowser.pull_monitor_timeout'});
		}
	});

	## Panel 3
	my $panel_3 = Wx::Panel->new($self);
	$self->AddPage( $panel_3, "Columns", 0);

	# columns
	$self->{listctrl} = Wx::ListCtrl->new($panel_3, -1, wxDefaultPosition, wxDefaultSize, wxLC_REPORT | wxLC_EDIT_LABELS);
	$self->{listctrl}->InsertColumn( 1, 'Column label', wxLIST_FORMAT_LEFT, 120 );
	$self->{listctrl}->InsertColumn( 2, 'Source metadata', wxLIST_FORMAT_LEFT, 170 );
	$self->{listctrl}->InsertColumn( 3, 'Width', wxLIST_FORMAT_LEFT, 80 );
	$self->{listctrl}->InsertColumn( 3, 'Align', wxLIST_FORMAT_LEFT, 80 );

	my $sizer = Wx::FlexGridSizer->new(3, 1, 0, 0);	# rows,cols,vgap,hgap
	$sizer->AddGrowableCol(0); # zerobased
	$sizer->AddGrowableRow(0); # zerobased
	$sizer->Add($self->{listctrl}, 0, wxALL|wxGROW, 5);

	$panel_3->SetSizer($sizer);

	EVT_LIST_ITEM_ACTIVATED($self, $self->{listctrl}, sub {
		Wrangler::debug("Settings::FileBrowser: columns row activated:");

		$self->Rename();
	});
	EVT_LIST_ITEM_SELECTED($self, $self->{listctrl}, sub {
		print "Settings: Row selected:\n";
		$_[1]->Skip(1);
	});
	EVT_LIST_ITEM_RIGHT_CLICK($self, $self->{listctrl}, sub { print "OnRightClick: @_\n"; OnRightClick(@_); });
	EVT_LIST_BEGIN_DRAG($self, $self->{listctrl}, sub {
		print "OnBeginDrag: @_\n";
	});

	$self->Populate();


	## Panel 4 default viewers/applications/commands
	$self->AddPage( Wrangler::Wx::Dialog::Settings::FileBrowser::Viewers->new($self), "View/open with", 0);

	return $self;
}

sub Populate {
	my $settings = shift;
	my $columns = $settings->{wrangler}->config()->{'ui.filebrowser.columns'} || [];

	$settings->{listctrl}->DeleteAllItems();

	$settings->{prop_list} = $settings->{wrangler}->{fs}->available_properties($settings->{wrangler}->{current_dir});
	@{ $settings->{prop_list} } = sort @{ $settings->{prop_list} };

	my %used;
	my $rowCnt = 0;
	for(@$columns){
		$used{ $_->{value_from} } = $_;

		# InsertItem returns a numeric $itemId
		my $itemId = $settings->{listctrl}->InsertStringItem( $rowCnt, $_->{label});
		$settings->{listctrl}->SetItem( $itemId, 1, $_->{value_from} );
		$settings->{listctrl}->SetItem( $itemId, 2, $_->{width} );
		$settings->{listctrl}->SetItem( $itemId, 3, $_->{text_align} );
		$rowCnt++;
	}

	for(0..$#{ $settings->{prop_list} }){
		unless($used{ $settings->{prop_list}->[$_] }){
			my $itemId = $settings->{listctrl}->InsertStringItem( $rowCnt, '' );
			$settings->{listctrl}->SetItem( $itemId, 1, $settings->{prop_list}->[$_] );
			$settings->{listctrl}->SetItemTextColour($itemId, Wx::Colour->new(128,128,128));
			$settings->{listctrl}->SetItemData($itemId, $_); # data is pos in prop_list array
		}
		$rowCnt++;
	}
}

sub GetSelections {
	return () unless $_[0]->{listctrl}->GetSelectedItemCount(); # untested optimisation

	my @selections;
	my $currId = -1;
	for(;;){
		$currId = $_[0]->{listctrl}->GetNextItem($currId, wxLIST_NEXT_ALL, wxLIST_STATE_SELECTED);
		if($currId == -1){
			last;
		}else{
			push(@selections, $currId);
		}
	}

	return wantarray ? @selections : \@selections;
}

# compare AddField() in Wrangler::Wx::FormEditor
sub Add {
	my $settings = shift;
	my $field_name = shift;

	unless($field_name){
		my $dialog = Wx::TextEntryDialog->new($settings, "Add this field to columns", "Add this field to columns", "");
		return if $dialog->ShowModal == wxID_CANCEL;

		$field_name = $dialog->GetValue() ;

		$dialog->Destroy();
	}

	return if $field_name eq '';

	my $columns = $settings->{wrangler}->config()->{'ui.filebrowser.columns'};

	push(@$columns,	{
		label	=> $field_name,
		value_from => $field_name,
		text_align => 'left',
		width	=> 50
	});

	$settings->Populate();
	Wrangler::PubSub::publish('filebrowser.refresh.all');
}

sub AddFromList {
	my $settings = shift;

	my @selections = $settings->GetSelections();
	my $pos = $settings->{listctrl}->GetItemData($selections[0]);

	my $columns = $settings->{wrangler}->config()->{'ui.filebrowser.columns'};
	# Wrangler::debug("Settings::AddFromList: pos:$pos -> prop_list value:$settings->{prop_list}->[$pos]");

	my $metakey = $settings->{prop_list}->[$pos];
	my $label = $metakey;

	push(@$columns,	{
		label	=> $metakey,
		value_from => $metakey,
		text_align => 'left',
		width	=> 50
	});

	$settings->Populate();
	Wrangler::PubSub::publish('filebrowser.refresh.all');
}

sub Move {
	my $settings = shift;
	my $direction = shift;

	my @selections = $settings->GetSelections();

	my $id = $settings->{listctrl}->GetItem($selections[0]);
	my $pos = $id->GetId;
	my $new_pos = $direction eq 'up'
		? $pos == 0 ? $pos : ($pos -1)
		: $settings->{listctrl}->GetItemCount == $pos + 1 ? $pos : ($pos + 1);

	my $columns = $settings->{wrangler}->config()->{'ui.filebrowser.columns'};

	# print "MOVE: '$direction': $id, $pos -> $new_pos\n";
	my $ref = ${ $columns }[$pos];
	splice(@$columns,$pos,1); # remove pos from array
	splice(@$columns,$new_pos, 0, $ref); # ...and insert at new_pos

	$settings->Populate();
	Wrangler::PubSub::publish('filebrowser.refresh.all');
}

sub Rename {
	my $settings = shift;

	my @selections = $settings->GetSelections();
	my $id = $settings->{listctrl}->GetItem($selections[0]);
	my $pos = $id->GetId;

	my $columns = $settings->{wrangler}->config()->{'ui.filebrowser.columns'};

	my $dialog = Wx::TextEntryDialog->new( $settings, "Rename column", "Rename column", $columns->[$pos]->{label} );

	unless( $dialog->ShowModal == wxID_CANCEL ){
		my $newlabel = $dialog->GetValue();

		$columns->[$pos]->{label} = $newlabel;

		$settings->Populate();
		Wrangler::PubSub::publish('filebrowser.refresh.all');
	}

	$dialog->Destroy();
}

sub ResetWidth {
	my $settings = shift;

	my @selections = $settings->GetSelections();
	my $id = $settings->{listctrl}->GetItem($selections[0]);
	my $pos = $id->GetId;

	my $columns = $settings->{wrangler}->config()->{'ui.filebrowser.columns'};

	 $columns->[$pos]->{width} = undef;

	$settings->Populate();
	Wrangler::PubSub::publish('filebrowser.refresh.all');
}

sub ToggleAlign {
	my $settings = shift;

	my @selections = $settings->GetSelections();
	my $id = $settings->{listctrl}->GetItem($selections[0]);
	my $pos = $id->GetId;

	my $columns = $settings->{wrangler}->config()->{'ui.filebrowser.columns'};

	 $columns->[$pos]->{text_align} = $columns->[$pos]->{text_align} && $columns->[$pos]->{text_align} eq 'right' ? 'left' : 'right';

	$settings->Populate();
	Wrangler::PubSub::publish('filebrowser.refresh.all');
}

sub Remove {
	my $settings = shift;

	my @selections = $settings->GetSelections();

	my $id = $settings->{listctrl}->GetItem($selections[0]);
	my $pos = $id->GetId;

	my $columns = $settings->{wrangler}->config()->{'ui.filebrowser.columns'};

	my $ref = ${ $columns }[$pos];
	splice(@$columns,$pos,1); # remove pos from array

	$settings->Populate();
	Wrangler::PubSub::publish('filebrowser.refresh.all');
}

# compare FormEditor::SaveFieldLayout
sub SaveColumnLayout {
	my $settings = shift;
#	my $editor_name = $editor->{wrangler}->config()->{'ui.formeditor.selected'};
	my $column_layout = 'current-column-layout';

	Wrangler::debug("Settings::FileBrowser::SaveColumnLayout");
	my $file_dialog = Wx::FileDialog->new($settings, "Save columns layout", '', $column_layout.'.wcl', "Wrangler Column Layout (*.wcl)|*.wcl;All files (*.*)|*.*", wxFD_SAVE);

	return if $file_dialog->ShowModal == wxID_CANCEL;

	my $path = $file_dialog->GetPath;
	$file_dialog->Destroy;

	my $json = eval { JSON::XS->new->utf8->pretty->encode( { $column_layout => $settings->{wrangler}->config()->{'ui.filebrowser.columns'} } ) };
	Wrangler::debug("Settings::FileBrowser::SaveColumnLayout: error encoding fields: $@") if $@;

	path($path)->spew_raw($json) or Wrangler::debug("Settings::FileBrowser::SaveColumnLayout: error writing column file: $path: $!")
}

# compare FormEditor::LoadFieldLayout
sub LoadColumnLayout {
	my $settings = shift;
#	my $editor_name = $editor->{wrangler}->config()->{'ui.formeditor.selected'};
	my $column_layout = 'current-column-layout';

	Wrangler::debug("Settings::FileBrowser::LoadColumnLayout");
	my $file_dialog = Wx::FileDialog->new($settings, "Load columns layout", '', '', "Wrangler Column Layout (*.wcl)|*.wcl;|All files (*.*)|*.*", wxFD_OPEN);

	return if $file_dialog->ShowModal == wxID_CANCEL;

	my $path = $file_dialog->GetPath;
	$file_dialog->Destroy;

	my $json = path($path)->slurp_raw or Wrangler::debug("Settings::FileBrowser::LoadColumnLayout: error reading layout file: $!");
	my $ref = eval { JSON::XS::decode_json( $json ) };
	Wrangler::debug("Settings::FileBrowser::LoadColumnLayout: error decoding layout file: $@") if $@;

#	my $last;
#	for(keys %$ref){
#		unless(defined($editor->{editors}->{ $_ })){
#			Wrangler::debug("Settings::FileBrowser::LoadColumnLayout: adding layout $_");
#			$editor->{editors}->{ $_ } = $ref->{$_} ;
#			$last = $_;
#		}
#	}
#
#	$editor->{wrangler}->config()->{'ui.formeditor.selected'} = $last;

#	my $columns = $settings->{wrangler}->config()->{'ui.filebrowser.columns'};

	unless($ref->{'current-column-layout'}){ # hardcoded for now; todo: multiple layouts management
		Wrangler::debug("Settings::FileBrowser::LoadColumnLayout: for now, column layout files must provide columns for a layout named 'current-column-layout' ") if $@;
		return;
	}

	$settings->{wrangler}->config()->{'ui.filebrowser.columns'} = $ref->{'current-column-layout'};

	$settings->Populate();
	Wrangler::PubSub::publish('filebrowser.refresh.all');
}

sub OnRightClick {
	my $settings = shift;
	my $event = shift;

        my $menu = Wx::Menu->new();

	my @selections = $settings->GetSelections();

	if( defined($selections[0]) && $settings->{listctrl}->GetItem( $selections[0], 0 )->GetText() eq '' ){ # hidden props/columns have empty data in column-0/"label"
		EVT_MENU( $settings, $menu->Append(-1, "Show this column", 'Show this column' ),	sub { $settings->AddFromList(); } );
	}else{
		EVT_MENU( $settings, $menu->Append(-1, "Move up", 'Move column up' ),		sub { $settings->Move('up'); } );
		EVT_MENU( $settings, $menu->Append(-1, "Move down", 'Move column down' ),	sub { $settings->Move('down'); } );
		$menu->AppendSeparator();
		EVT_MENU( $settings, $menu->Append(-1, "Change label", 'Rename this column' ),	sub { $settings->Rename(); } );
	#	EVT_MENU( $settings, $menu->Append(-1, "Reset width", 'Reset width of this column' ),	sub { $settings->ResetWidth(); } );
		EVT_MENU( $settings, $menu->Append(-1, "Toggle align", 'Change between text align left and right' ),	sub { $settings->ToggleAlign(); } );
		$menu->AppendSeparator();
		EVT_MENU( $settings, $menu->Append(-1, "Hide this column", 'Remove this column' ),	sub { $settings->Remove(); } );
	}
	$menu->AppendSeparator();
	EVT_MENU( $settings, $menu->Append(-1, "Add column not on list...", 'Add a metadata key which is not on the list' ),	sub { $settings->Add(); } );

	$menu->AppendSeparator();
	EVT_MENU( $settings, $menu->Append(-1, "Load columns layout", 'Load a column layout from a file' ), sub { $settings->LoadColumnLayout(); } );
	EVT_MENU( $settings, $menu->Append(-1, "Save columns layout", 'Save a column layout to a file' ), sub { $settings->SaveColumnLayout(); } );

	$settings->PopupMenu( $menu, wxDefaultPosition ); # alt: $event->GetPosition
}


package Wrangler::Wx::Dialog::Settings::FileBrowser::Viewers;

use strict;
use warnings;

use Wx qw(wxDefaultPosition wxDefaultSize wxLIST_FORMAT_LEFT wxALL wxGROW wxLC_EDIT_LABELS wxLC_REPORT wxLIST_NEXT_ALL wxLIST_STATE_SELECTED wxID_OK);
use Wx::Event qw(EVT_LIST_ITEM_ACTIVATED EVT_LIST_ITEM_RIGHT_CLICK EVT_MENU);
use base 'Wx::Panel';

sub new {
	my $class = shift;
	my $parent = shift;

	my $self = $class->SUPER::new($parent, -1, wxDefaultPosition, wxDefaultSize);

	# hook up $wrangler for config
	$self->{wrangler} = $parent->{wrangler};

	# columns
	$self->{listctrl} = Wx::ListCtrl->new($self, -1, wxDefaultPosition, wxDefaultSize, wxLC_REPORT);
	$self->{listctrl}->InsertColumn( 1, 'MIME-Type', wxLIST_FORMAT_LEFT, 250 );
	$self->{listctrl}->InsertColumn( 2, 'Command', wxLIST_FORMAT_LEFT, 250 );

	my $sizer = Wx::FlexGridSizer->new(3, 1, 0, 0);	# rows,cols,vgap,hgap
	$sizer->AddGrowableCol(0); # zerobased
	$sizer->AddGrowableRow(0); # zerobased
	$sizer->Add($self->{listctrl}, 0, wxALL|wxGROW, 5);

	$self->SetSizer($sizer);

	EVT_LIST_ITEM_ACTIVATED($self, $self->{listctrl}, sub {
		Wrangler::debug("Settings::FileBrowser: columns row activated:");

		$self->Edit();
	});
	EVT_LIST_ITEM_RIGHT_CLICK($self, $self->{listctrl}, sub { print "OnRightClick: @_\n"; OnRightClick(@_); });

	$self->Populate();

	return $self;
}

sub Populate {
	my $settings = shift;
	my $viewers = $settings->{wrangler}->config()->{'openwith'} || [];

	$settings->{listctrl}->DeleteAllItems();

	my %used;
	my $rowCnt = 0;
	for(keys %$viewers){
		my $itemId = $settings->{listctrl}->InsertStringItem( $rowCnt, $_);
		$settings->{listctrl}->SetItem( $itemId, 1, $viewers->{$_} );
		$rowCnt++;
	}
}

sub GetSelections {
	return () unless $_[0]->{listctrl}->GetSelectedItemCount(); # untested optimisation

	my @selections;
	my $currId = -1;
	for(;;){
		$currId = $_[0]->{listctrl}->GetNextItem($currId, wxLIST_NEXT_ALL, wxLIST_STATE_SELECTED);
		if($currId == -1){
			last;
		}else{
			push(@selections, $currId);
		}
	}

	return wantarray ? @selections : \@selections;
}

sub Edit {
	my $settings = shift;

	# Edit() works as Add() when nothing is selected
	my $mime;
	my @selections = $settings->GetSelections();
	if(@selections){
		my $id = $settings->{listctrl}->GetItem($selections[0]);
		$mime = $id->GetText;
	}

	my $viewers = $settings->{wrangler}->config()->{'openwith'};

	my $dialog = Wx::TextEntryDialog->new($settings, "Enter a MIME-Type for this viewer", "Enter MIME-Type to associate", $mime );
	return unless $dialog->ShowModal() == wxID_OK;
	my $newmime = $dialog->GetValue();
	$dialog->Destroy();

	# it's a change of MIME-Type
	if($mime && $mime ne $newmime){
		$viewers->{$newmime} = $viewers->{$mime};
		delete($viewers->{$mime});
	}
	$mime = $newmime;

	$dialog = Wx::TextEntryDialog->new($settings, "Path to a binary/command to execute", "Enter application to launch for $mime", $viewers->{$mime} );
	return unless $dialog->ShowModal() == wxID_OK;
	$viewers->{$mime} = $dialog->GetValue();
	$dialog->Destroy();

	$settings->Populate();
}

sub Delete {
	my $settings = shift;

	my @selections = $settings->GetSelections();

	my $id = $settings->{listctrl}->GetItem($selections[0]);
	my $mime = $id->GetText;

	my $viewers = $settings->{wrangler}->config()->{'openwith'};
	delete($viewers->{$mime});

	$settings->Populate();
}

sub OnRightClick {
	my $settings = shift;
	my $event = shift;

        my $menu = Wx::Menu->new();

	my @selections = $settings->GetSelections();

	my $itemAdd = Wx::MenuItem->new($menu, -1, "Add MIME/viewer command", 'Add MIME/viewer command');
	my $itemEdit = Wx::MenuItem->new($menu, -1, "Edit this entry", 'Edit this entry');
	my $itemDelete = Wx::MenuItem->new($menu, -1, "Delete this entry", 'Delete this entry');
	$menu->Append($itemAdd);
	$menu->AppendSeparator();
	$menu->Append($itemEdit);
	$menu->AppendSeparator();
	$menu->Append($itemDelete);

	if( defined($selections[0]) ){
		$menu->Enable($itemAdd->GetId(),0);
		EVT_MENU( $settings, $itemEdit, sub { $settings->Edit(); } );
		EVT_MENU( $settings, $itemDelete, sub { $settings->Delete(); } );
	}else{
		EVT_MENU( $settings, $itemAdd, sub { $settings->Edit(); } );
		$menu->Enable($itemEdit->GetId(),0);
		$menu->Enable($itemDelete->GetId(),0);
	}

	$settings->PopupMenu( $menu, wxDefaultPosition ); # alt: $event->GetPosition
}


package Wrangler::Wx::Dialog::Settings::Previewer;

use strict;
use warnings;

use Wx qw(wxVERTICAL wxHORIZONTAL wxDefaultPosition wxDefaultSize wxEXPAND wxBOTTOM wxALL wxRIGHT wxTOP);
use Wx::Event qw(EVT_TEXT);
use base 'Wx::Notebook';

sub new {
	my $class = shift;
	my $parent = shift;

	my $self = $class->SUPER::new($parent, -1, wxDefaultPosition, wxDefaultSize, wxEXPAND);

	# hook up $wrangler for config
	$self->{wrangler} = $parent->{wrangler};

	## Panel 1
	my $panel_1 = Wx::Panel->new($self);
	$self->AddPage( $panel_1, "Previewer", 0);

	# preview settings
				my $use_original_image_as_preview = Wx::TextCtrl->new($panel_1, -1, $self->{wrangler}->config()->{'ui.previewer.image.original_as_preview_max_size'} || 300);

			my $input_sizer = Wx::BoxSizer->new(wxHORIZONTAL);
			$input_sizer->Add( $use_original_image_as_preview, 0, wxRIGHT, 5 );
			$input_sizer->Add( Wx::StaticText->new($panel_1, -1, 'KB', wxDefaultPosition, wxDefaultSize), 1, wxTOP, 7);

				my $load_original_timeout = Wx::TextCtrl->new($panel_1, -1, $self->{wrangler}->config()->{'ui.previewer.image.load_original_timeout'} || 800);

			my $input2_sizer = Wx::BoxSizer->new(wxHORIZONTAL);
			$input2_sizer->Add( $load_original_timeout, 0, wxRIGHT, 5 );
			$input2_sizer->Add( Wx::StaticText->new($panel_1, -1, 'ms', wxDefaultPosition, wxDefaultSize), 1, wxTOP, 7);

		my $preview_sizer = Wx::FlexGridSizer->new(2,1); # rows,cols,vgap,hgap
		$preview_sizer->Add( Wx::StaticText->new($panel_1, -1, "First, Previewer tries to extract embedded preview thumbnails\nfrom images. If that fails, Previewer falls back to using the actual\nfile as preview, which might slow down with large images. This\nvalue here caps this behaviour, by providing a size value for when\nPreviewer will not use the image on the first preview pass.", wxDefaultPosition, wxDefaultSize), 1, wxALL, 5);
		$preview_sizer->Add($input_sizer, 1, wxALL, 5);
		$preview_sizer->Add( Wx::StaticText->new($panel_1, -1, "Previewer will load the original/actual file after this amount\nof milliseconds, unless the user moves selection away.", wxDefaultPosition, wxDefaultSize), 1, wxALL, 5);
		$preview_sizer->Add($input2_sizer, 1, wxALL, 5);

	my $image_boxsizer = Wx::StaticBoxSizer->new( Wx::StaticBox->new($panel_1, -1, "Image previewing"), wxVERTICAL);
	$image_boxsizer->Add( $preview_sizer, 0, wxALL, 10 );

				my $video_thumbpos = Wx::TextCtrl->new($panel_1, -1, $self->{wrangler}->config()->{'ui.previewer.video.default_thumbnail_position'} || 2);

			my $input3_sizer = Wx::BoxSizer->new(wxHORIZONTAL);
			$input3_sizer->Add( $video_thumbpos, 0, wxRIGHT, 5 );
			$input3_sizer->Add( Wx::StaticText->new($panel_1, -1, 'seconds', wxDefaultPosition, wxDefaultSize), 1, wxTOP, 7);

		my $preview2_sizer = Wx::FlexGridSizer->new(2,1); # rows,cols,vgap,hgap
		$preview2_sizer->Add( Wx::StaticText->new($panel_1, -1, "By default, Previewer extracts a frame from videos at 2 seconds\ninto the video. This may be inappropriate for very short or\nlong videos, so you can provide a different value here.", wxDefaultPosition, wxDefaultSize), 1, wxALL, 5);
		$preview2_sizer->Add($input3_sizer, 1, wxALL, 5);

	my $preview_boxsizer = Wx::StaticBoxSizer->new( Wx::StaticBox->new($panel_1, -1, "Video previewing"), wxVERTICAL);
	$preview_boxsizer->Add( $preview2_sizer, 0, wxALL, 10 );

	# panel 1 sizer
		my $panel_1_sizer = Wx::FlexGridSizer->new(1,1,10); # rows,cols,vgap,hgap
		$panel_1_sizer->AddGrowableCol(0); # zerobased
		$panel_1_sizer->Add($image_boxsizer, 1);
		$panel_1_sizer->Add($preview_boxsizer, 1);

	$panel_1->SetSizer($panel_1_sizer);

	EVT_TEXT($self, $use_original_image_as_preview, sub {
		my $value = int($use_original_image_as_preview->GetValue());
		if($value && $value != 300){
			Wrangler::debug("Settings::Previewer: original_as_preview cap $value");
			$_[0]->{wrangler}->config()->{'ui.previewer.image.original_as_preview_max_size'} = $value;
		}else{
			Wrangler::debug("Settings::Previewer: remove custom original_as_preview cap");
			my $config = $_[0]->{wrangler}->config();
			delete($config->{'ui.previewer.image.original_as_preview_max_size'});
		}
	});
	EVT_TEXT($self, $load_original_timeout, sub {
		my $value = int($load_original_timeout->GetValue());
		if($value && $value != 800){
			Wrangler::debug("Settings::Previewer: load_original_timeout $value");
			$_[0]->{wrangler}->config()->{'ui.previewer.image.load_original_timeout'} = $value;
		}else{
			Wrangler::debug("Settings::Previewer: remove custom load_original_timeout");
			my $config = $_[0]->{wrangler}->config();
			delete($config->{'ui.previewer.image.load_original_timeout'});
		}
	});
	EVT_TEXT($self, $video_thumbpos, sub {
		my $value = int($video_thumbpos->GetValue());
		if($value && $value != 2){
			Wrangler::debug("Settings::Previewer: thumbpos at $value");
			$_[0]->{wrangler}->config()->{'ui.previewer.video.default_thumbnail_position'} = $value;
		}else{
			Wrangler::debug("Settings::Previewer: remove custom thumbpos");
			my $config = $_[0]->{wrangler}->config();
			delete($config->{'ui.previewer.video.default_thumbnail_position'});
		}
	});

	return $self;
}


package Wrangler::Wx::Dialog::Settings::Plugins;

use strict;
use warnings;

use Wx qw(wxVERTICAL wxID_OK wxCLOSE_BOX wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER wxDefaultPosition wxDefaultSize wxEXPAND wxBOTTOM wxALL wxLIST_FORMAT_LEFT wxLC_REPORT wxGROW wxLIST_NEXT_ALL wxLIST_STATE_SELECTED);
use Wx::Event qw(EVT_BUTTON EVT_MENU EVT_LIST_ITEM_ACTIVATED EVT_LIST_ITEM_SELECTED EVT_LIST_ITEM_RIGHT_CLICK);
use base 'Wx::Notebook';

sub new {
	my $class = shift;
	my $parent = shift;

	my $self = $class->SUPER::new($parent, -1, wxDefaultPosition, wxDefaultSize, wxEXPAND);

	# hook up $wrangler for config
	$self->{wrangler} = $parent->{wrangler};

	## Panel 1
	my $panel_1 = Wx::Panel->new($self);
	$self->AddPage( $panel_1, "Plugins", 0);

	# columns
	$self->{listctrl} = Wx::ListCtrl->new($panel_1, -1, wxDefaultPosition, wxDefaultSize, wxLC_REPORT);
	$self->{listctrl}->InsertColumn( 1, 'Plugin name', wxLIST_FORMAT_LEFT, 200 );
	$self->{listctrl}->InsertColumn( 2, 'Scope', wxLIST_FORMAT_LEFT, 200 );

	my $sizer = Wx::FlexGridSizer->new(2, 1, 20, 0); # rows,cols,vgap,hgap
	$sizer->AddGrowableCol(0); # zerobased
	$sizer->AddGrowableRow(0); # zerobased
	$sizer->Add($self->{listctrl}, 0, wxALL|wxGROW, 5);

	$panel_1->SetSizer($sizer);

	## Panel 2 events
	EVT_LIST_ITEM_ACTIVATED($self, $self->{listctrl}, sub { $self->ShowPluginSettings(@_); });
	EVT_LIST_ITEM_RIGHT_CLICK($self, $self->{listctrl}, sub { OnRightClick(@_); });

	$self->Populate();

	return $self;
}

sub GetSelections {
	return () unless $_[0]->{listctrl}->GetSelectedItemCount(); # untested optimisation

	my @selections;
	my $currId = -1;
	for(;;){
		$currId = $_[0]->{listctrl}->GetNextItem($currId, wxLIST_NEXT_ALL, wxLIST_STATE_SELECTED);
		if($currId == -1){
			last;
		}else{
			push(@selections, $currId);
		}
	}

	return wantarray ? @selections : \@selections;
}

sub Populate {
	my $settings = shift;
	my $plugins =  Wrangler::PluginManager::plugins();

	$settings->{listctrl}->DeleteAllItems();

	my $rowCnt = 0;
	for(@$plugins){
		my $itemId = $settings->{listctrl}->InsertStringItem( $rowCnt, $_->plugin_name() );
		$settings->{listctrl}->SetItem( $itemId, 1, join(', ', keys %{ $_->plugin_phases() }) );
		$settings->{listctrl}->SetItemTextColour($itemId, Wx::Colour->new(128,128,128)) unless Wrangler::PluginManager::is_enabled($_->plugin_name());
		$rowCnt++;
	}
}

sub ShowInfo {
	my $settings = shift;

	my @selections = $settings->GetSelections();
	my $id = $settings->{listctrl}->GetItem($selections[0]);
	my $pos = $id->GetId;

	my $plugins =  Wrangler::PluginManager::plugins();
	my $plugin = $plugins->[$pos];

	my $dialog = Wx::Dialog->new($settings, -1, $plugin->plugin_name()." Plugin Info",  wxDefaultPosition, wxDefaultSize,  wxDEFAULT_DIALOG_STYLE|wxCLOSE_BOX  );
		my $sizer = Wx::FlexGridSizer->new(3, 1, 0, 0);	# rows,cols,vgap,hgap
		$sizer->AddGrowableCol(0); # zerobased
		$sizer->AddGrowableRow(0); # zerobased
		$sizer->Add( Wx::StaticText->new($dialog, -1, $plugin->plugin_info(), wxDefaultPosition, wxDefaultSize), 0, wxEXPAND|wxALL, 10 );
		$sizer->Add(Wx::Button->new($dialog, wxID_OK, 'OK'), 0, wxALL, 2);
	$dialog->SetSizer($sizer);

	return unless $dialog->ShowModal() == wxID_OK;
}

sub ShowPluginSettings {
	my $settings = shift;

	my @selections = $settings->GetSelections();
	my $id = $settings->{listctrl}->GetItem($selections[0]);
	my $pos = $id->GetId;

	my $plugins =  Wrangler::PluginManager::plugins();
	my $plugin = $plugins->[$pos];

	my $dialog = Wx::Dialog->new($settings, -1, $plugin->plugin_name()." Plugin Settings",  wxDefaultPosition, wxDefaultSize,  wxDEFAULT_DIALOG_STYLE | wxCLOSE_BOX | wxRESIZE_BORDER  );

	# plugins must return a $sizer via plugin_settings()
	$dialog->SetSizer( $plugin->plugin_settings($dialog) );

	return unless $dialog->ShowModal() == wxID_OK;
}

sub Enable {
	my $settings = shift;

	my @selections = $settings->GetSelections();
	my $id = $settings->{listctrl}->GetItem($selections[0]);
#	my $pos = $id->GetId;
	my $plugin_name = $id->GetText;

	Wrangler::PluginManager::enable_plugin($plugin_name);

	$settings->Populate();
}

sub Disable {
	my $settings = shift;

	my @selections = $settings->GetSelections();
	my $id = $settings->{listctrl}->GetItem($selections[0]);
#	my $pos = $id->GetId;
	my $plugin_name = $id->GetText;

	Wrangler::PluginManager::disable_plugin($plugin_name);

	$settings->Populate();
}

sub OnRightClick {
	my $settings = shift;
	my $event = shift;

        my $menu = Wx::Menu->new();

	my @selections = $settings->GetSelections();

	my $itemInfo = Wx::MenuItem->new($menu, -1, "Show info");
	my $itemPluginSettings = Wx::MenuItem->new($menu, -1, "Show settings");
	my $itemEnable = Wx::MenuItem->new($menu, -1, "Enable this Plugin");
	my $itemDisable = Wx::MenuItem->new($menu, -1, "Disable this Plugin");
	$menu->Append($itemInfo);
	$menu->Append($itemPluginSettings);
	$menu->AppendSeparator();
	$menu->Append($itemEnable);
	$menu->Append($itemDisable);

	if( defined($selections[0]) ){
		my $id = $settings->{listctrl}->GetItem($selections[0]);
		my $plugin_name = $id->GetText;

#		my $plugins =  Wrangler::PluginManager::plugins();
#		my $plugin = $plugins->[$pos];

		$menu->Enable($itemInfo->GetId(),1);
		EVT_MENU( $settings, $itemInfo, sub { $settings->ShowInfo(); } );
		EVT_MENU( $settings, $itemPluginSettings, sub { $settings->ShowPluginSettings(); } );
#		unless( Wrangler::PluginManager::is_enabled($pos) ){
		unless( Wrangler::PluginManager::is_enabled($plugin_name) ){
			$menu->Enable($itemEnable->GetId(),1);
			$menu->Enable($itemDisable->GetId(),0);
			EVT_MENU( $settings, $itemEnable, sub { $settings->Enable(); } );
		}else{
			$menu->Enable($itemEnable->GetId(),0);
			$menu->Enable($itemDisable->GetId(),1);
			EVT_MENU( $settings, $itemDisable, sub { $settings->Disable(); } );
		}
	}else{
		$menu->Enable($itemInfo->GetId(),0);
		$menu->Enable($itemEnable->GetId(),0);
		$menu->Enable($itemDisable->GetId(),0);
	}

	$settings->PopupMenu( $menu, wxDefaultPosition ); # alt: $event->GetPosition
}

1;
