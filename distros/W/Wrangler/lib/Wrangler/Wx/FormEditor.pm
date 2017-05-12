package Wrangler::Wx::FormEditor;

use strict;
use warnings;

use base 'Wx::Panel';
use Wx ':everything';
use Wx::Event qw(EVT_BUTTON EVT_TEXT EVT_CHAR EVT_RIGHT_UP EVT_MENU EVT_COMBOBOX EVT_TEXT_ENTER);
use JSON::XS ();
use Path::Tiny;

sub new {
	my $class  = shift;
	my $parent = shift;
	my $self = $class->SUPER::new( $parent, -1, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL);

	bless $self, $class;

	# hook-up access to $wrangler
	$self->{wrangler} = $parent->{wrangler};

	$self->SetForegroundColour(Wx::Colour->new(@{ $self->{wrangler}->config()->{'ui.foreground_colour'} })) if $self->{wrangler}->config()->{'ui.foreground_colour'};

	## pull-in valueshortcuts for this session
	$self->{valueshortcuts} = $self->{wrangler}->config()->{'valueshortcuts'};

	## get the editor/layout
	if($self->{wrangler}->config()->{'ui.formeditor'}){
		if($self->{wrangler}->config()->{'ui.formeditor.selected'}){
			$self->{selected_editor} = $self->{wrangler}->config()->{'ui.formeditor.selected'};
		}else{
			($self->{selected_editor}) =  keys %{ $self->{wrangler}->config()->{'ui.formeditor'} };
			$self->{wrangler}->config()->{'ui.formeditor.selected'} = $self->{selected_editor} if $self->{selected_editor};
		}
		$self->{editors} = $self->{wrangler}->config()->{'ui.formeditor'};
		if( $self->{selected_editor} && $self->{editors}->{ $self->{selected_editor} } ){
			$self->{layout} = $self->{editors}->{ $self->{selected_editor} };
			$self->{field_count} = @{ $self->{layout} };
		}
	}

	## add a selector element
			my $label = Wx::StaticText->new($self, -1, 'Editor: ', wxDefaultPosition, wxDefaultSize);
			my @editors_hashkeys = keys %{ $self->{editors} };
			$self->{editor_selector} = Wx::ComboBox->new($self, -1,	($self->{selected_editor} || ''), wxDefaultPosition, wxDefaultSize, \@editors_hashkeys, wxCB_DROPDOWN); # |wxCB_READONLY
			for(0 .. $#editors_hashkeys){
				$self->{editor_selector}->SetSelection($_) if $editors_hashkeys[$_] eq $self->{selected_editor};
			}

		my $select_sizer = Wx::BoxSizer->new(wxHORIZONTAL);
		$select_sizer->Add( $label, 0, wxTOP, 7 );
		$select_sizer->Add( $self->{editor_selector}, 0);

	my $sizer = Wx::BoxSizer->new(wxVERTICAL);
	$sizer->Add($select_sizer);


	## build the form/dialog
	my $form_sizer = Wx::FlexGridSizer->new( ($self->{field_count} ? ($self->{field_count} + 1) : 2), 2);
	$form_sizer->AddGrowableCol(1); # zerobased

	if($self->{selected_editor}){
		if($self->{field_count}){
			## add field rows
			my $ns;
			foreach my $line (@{$self->{layout}}){
				my ($namespace,$key) = split('::',$line);
				unless($ns && $ns eq $namespace){
					$form_sizer->Add( Wx::StaticText->new($self, -1, $namespace, wxDefaultPosition, wxDefaultSize), 0, wxTOP|wxEXPAND, 10 );
					$form_sizer->Add( Wx::Panel->new( $self, -1, ) );
					$ns = $namespace;
				}

				## tell central $wishlist what we are displaying
				$Wrangler::wishlist->{ $line } = 1;

				my $node_label = Wx::StaticText->new($self, -1, ($key || '(empty)'), wxDefaultPosition, wxDefaultSize, wxALIGN_LEFT, $line); # we use/abuse 'window name' as Data store, for the full key, used by RemoveField()
				$form_sizer->Add($node_label, 0, wxTOP|wxLEFT, 5 );
				## todo: lookup needed ctrl "renderer" against a wrangler built-in db of metadata fields and how to render them (similar to valuecb)
				my $node_ctrl = Wx::TextCtrl->new( $self, -1, '', wxDefaultPosition, wxDefaultSize );
				$node_ctrl->SetEditable(0);
				$node_ctrl->SetBackgroundColour( Wx::Colour->new( 222, 222, 222 ) );
				$form_sizer->Add($node_ctrl, 0, wxEXPAND);

				$self->{ctrl_lookup}->{$line} = $node_ctrl;

				EVT_TEXT($self, $node_ctrl, \&OnChange );
				EVT_CHAR($node_ctrl, \&OnChar );
				EVT_RIGHT_UP($node_label, sub { \&OnRightClick(@_,'on_label'); });
			}

			## add ok/cancel buttons
			$form_sizer->AddSpacer(5);
				my $btn_sizer = Wx::BoxSizer->new(wxHORIZONTAL);
					my $btn_save = Wx::Button->new($self, wxID_OK, 'Save');
					my $btn_cancel = Wx::Button->new($self, -1, 'Cancel');
					$self->{changed_indicator} = Wx::StaticText->new($self, -1, '', wxDefaultPosition, [80,-1], wxALIGN_RIGHT|wxST_NO_AUTORESIZE|wxSUNKEN_BORDER);
				$btn_sizer->Add($self->{changed_indicator}, 0, wxTOP|wxRIGHT, 5);
				$btn_sizer->Add($btn_save, 0, wxRIGHT, 2);
				$btn_sizer->Add($btn_cancel);
			$form_sizer->Add($btn_sizer, 0, wxTOP|wxALIGN_RIGHT, 10);

			EVT_BUTTON($self, $btn_save, \&OnSave );
			EVT_BUTTON($self, $btn_cancel, sub { $self->RePopulate(@_) } );
		}else{
			my $note = Wx::StaticText->new($self, -1, "No field layout defined.\n\n(Right-click to add fields to this editor)", wxDefaultPosition, wxDefaultSize);
			$form_sizer->Add($note , 0, wxALL|wxEXPAND, 30 );
			EVT_RIGHT_UP($note, sub { \&OnRightClick(@_); });
		}
	}else{
		my $note = Wx::StaticText->new($self, -1, "No editor defined.\n\n(Right-click to create a new editor)", wxDefaultPosition, wxDefaultSize);
		$form_sizer->Add($note, 0, wxALL|wxEXPAND, 30 );
		EVT_RIGHT_UP($note, sub { \&OnRightClick(@_); });
	}
	$sizer->Add( $form_sizer, 0, wxGROW);

	$self->SetSizer($sizer);

	## hook up events
	Wrangler::PubSub::subscribe('selection.changed', sub {
		if($_[0] && $_[0] > 1){
		#	Wrangler::debug("FormEditor: $_[0] files selected: event ignored.");
			return;
		}

		$self->Populate(@_);
	}, __PACKAGE__);

	## hook up events
	EVT_COMBOBOX($self, $self->{editor_selector}, sub { $self->SelectEditor($_[0]->{editor_selector}->GetValue()); });
	EVT_TEXT_ENTER($self, $self->{editor_selector}, sub { $self->Rename($_[0]->{editor_selector}->GetValue()); });
	EVT_CHAR($label, \&OnChar );
	EVT_RIGHT_UP($label, sub { \&OnRightClick(@_); });
	EVT_CHAR($self, \&OnChar );
	EVT_RIGHT_UP($self, sub { \&OnRightClick(@_); });

	return $self;
}

sub needed_values {
	my $self = shift;

	$self->{needed_values} = [
		{
			ns	=> 'Filesystem',
			label	=> 'mtime',
		},
	];

	return (@{$self->{needed_values}});
}

sub Populate {
	my ($editor,$selection_count,$richlist_items,$only_untouched,$no_poll) = @_;
	Wrangler::debug("FormEditor::Populate: $selection_count, " . ($richlist_items ? "$richlist_items" : '') );

	$editor->Poll() unless $no_poll;

	$editor->{current_richlist_item} = $richlist_items->[0];
	$editor->{current_path} = $richlist_items->[0] ? $richlist_items->[0]->{'Filesystem::Path'} : undef;

	foreach my $line (@{$editor->{layout}}){
		my $value = $editor->{current_richlist_item}->{$line};
		if($only_untouched){
			$editor->{ctrl_lookup}->{$line}->ChangeValue($value || '') unless $editor->{ctrl_lookup}->{$line}->IsModified();
		}else{
			$editor->{ctrl_lookup}->{$line}->ChangeValue($value || '');
		}

		if( $selection_count && $editor->{wrangler}->{fs}->can_mod($line) ){
			$editor->{ctrl_lookup}->{$line}->SetEditable(1);
			$editor->{ctrl_lookup}->{$line}->SetBackgroundColour( wxNullColour );
		}else{
			$editor->{ctrl_lookup}->{$line}->SetEditable(0);
			$editor->{ctrl_lookup}->{$line}->SetBackgroundColour( Wx::Colour->new( 222, 222, 222 ) );
		}
	}

	if( $editor->{changed_indicator} ){
		$editor->{changed_indicator}->SetLabel('');
		$editor->{changed_indicator}->Update();
		$editor->{changed} = 0;
	}
	$editor->Refresh();
}

sub RePopulate {
	my $editor = shift;
	Wrangler::debug("FormEditor::RePopulate: ");
	$editor->Populate(1, [$editor->{current_richlist_item}], undef, 'no_poll');
}

sub Poll {
	my $editor = shift;

	my @modified;
	foreach my $line (@{$editor->{layout}}){
		push(@modified, {
			key	=> $line,
			value	=> $editor->{ctrl_lookup}->{$line}->GetValue(),
		}) if $editor->{ctrl_lookup}->{$line}->IsModified();
	}

	if(@modified){
		Wrangler::debug('FormEditor::Poll: editor has been modified:');
		foreach my $mod (@modified){
			if( $mod->{value} eq '' ){ ## FormEditor removes on empty
				Wrangler::debug(" deleting '$mod->{key}': '$mod->{value}' on $editor->{current_path}");
				my $ok = $editor->{wrangler}->{fs}->del_property($editor->{current_path}, $mod->{key});
				delete($editor->{current_richlist_item}->{ $mod->{key} }); # update internal data structure as well
			}else{
				Wrangler::debug(" setting '$mod->{key}': '$mod->{value}' on $editor->{current_path}");
				my $ok = $editor->{wrangler}->{fs}->set_property($editor->{current_path}, $mod->{key}, $mod->{value});
				$editor->{current_richlist_item}->{ $mod->{key} } = $mod->{value}; # update internal data structure as well
			}
		}
	}
}

sub OnChange {
	my $self = shift;

	unless($self->{changed}){	# not every keystroke should trigger SetLabel
		$self->{changed_indicator}->SetLabel('Changed...');
		$self->{changed} = 1;
	}
}

sub OnSave {
	$_[0]->Populate(1, [$_[0]->{current_richlist_item}]);
}

sub OnDeselected {
	shift->Poll();
}

sub get_field {
	my ($layout, $ns, $key) = @_;

	## the downside of having an array for fields...
	foreach my $field (@$layout){
		if($field->{ns} eq $ns && $field->{key} eq $key){
			return $field;
		}
	}

	return {};
}

sub Create {
	my $editor = shift;

	my $dialog = Wx::TextEntryDialog->new( $editor, "New editor layout name", "New editor layout name", "");

	unless( $dialog->ShowModal == wxID_CANCEL ){
		my $new_editor = $dialog->GetValue();
		if( $new_editor ne '' && !defined($editor->{editors}->{ $new_editor }) ){
			Wrangler::debug("FormEditor::Create: adding new editor layout '$new_editor' ");
			# $editor->{editors}->{ $new_editor } = [];
			$editor->{wrangler}->config()->{'ui.formeditor'}->{ $new_editor } = [];
			$editor->{wrangler}->config()->{'ui.formeditor.selected'} = $new_editor;

			Wrangler::PubSub::publish('main.formeditor.recreate');
		}
	}

	$dialog->Destroy();
}

sub Rename {
	my $editor = shift;
	my $editor_name = $editor->{wrangler}->config()->{'ui.formeditor.selected'};
	my $new_editor_name = shift;

	unless(defined($new_editor_name)){
		my $dialog = Wx::TextEntryDialog->new( $editor, "Rename editor", "Rename editor", $editor_name);
		return if $dialog->ShowModal == wxID_CANCEL;

		$new_editor_name = $dialog->GetValue();
		$dialog->Destroy();
	}

	if( $new_editor_name eq ''){
		my $dialog = Wx::MessageDialog->new($editor, "Nothing. That's not a very helpful name", "Oops...", wxOK );
		$dialog->ShowModal();
	}elsif($editor_name eq $new_editor_name){
		# nothing
	}elsif(defined($editor->{editors}->{ $new_editor_name }) ){
		my $dialog = Wx::MessageDialog->new($editor, "Editor names have to be unique", "Oops...", wxOK );
		$dialog->ShowModal();
	}else{
		Wrangler::debug("FormEditor::Rename: editor layout '$editor_name' to '$new_editor_name' ");
		$editor->{wrangler}->config()->{'ui.formeditor'}->{ $new_editor_name } = $editor->{wrangler}->config()->{'ui.formeditor'}->{ $editor_name };
		delete($editor->{wrangler}->config()->{'ui.formeditor'}->{ $editor_name });
		$editor->{wrangler}->config()->{'ui.formeditor.selected'} = $new_editor_name;

		Wrangler::PubSub::publish('main.formeditor.recreate');
	}
}

sub Delete {
	my $editor = shift;
	my $editor_name = $editor->{wrangler}->config()->{'ui.formeditor.selected'};

	my $dialog = Wx::MessageDialog->new($editor, "Really delete editor '$editor_name'?", "Confirm", wxYES_NO | wxNO_DEFAULT | wxICON_EXCLAMATION );

	if($dialog->ShowModal() == wxID_YES){
		Wrangler::debug("FormEditor::Delete: editor layout '$editor_name' ");
		delete($editor->{wrangler}->config()->{'ui.formeditor'}->{ $editor_name });
	#	delete($editor->{editors}->{ $editor_name });
		$editor->{wrangler}->config()->{'ui.formeditor.selected'} = undef;

		Wrangler::PubSub::publish('main.formeditor.recreate');
	}

	$dialog->Destroy();
}

# compare Add() in Wrangler::Wx::Dialog::Settings::FileBrowser
sub AddField {
	my $editor = shift;
	my $field_name = shift;
	my $editor_name = $editor->{wrangler}->config()->{'ui.formeditor.selected'};

	# Wrangler::debug("FormEditor::AddField: $editor, ".($field_name||'(no field name)').", $editor_name");
	if($field_name){
		if($field_name ~~ @{ $editor->{wrangler}->config()->{'ui.formeditor'}->{ $editor_name } }){ # never happens, is prevented in submenu
			my $dialog = Wx::MessageDialog->new($editor, "Field '$field_name' is already in this layout.", "Oops...", wxOK );
			$dialog->ShowModal();

			return;
		}
	}else{
		my $dialog = Wx::TextEntryDialog->new( $editor, "Add this field to editor", "Add this field to editor", "");

		$field_name = $editor->AddField($dialog->GetValue()) if $dialog->ShowModal == wxID_OK;

		$dialog->Destroy();

		return unless $field_name;
	}

	Wrangler::debug("FormEditor::AddField: '$field_name' to editor layout '$editor_name' ");
	push(@{ $editor->{wrangler}->config()->{'ui.formeditor'}->{ $editor_name } }, $field_name);

	# update $wishlist
	$Wrangler::wishlist->{ $field_name } = 1;

	Wrangler::PubSub::publish('main.formeditor.recreate');
}

sub RemoveField {
	my $editor = shift;
	my $field_name = shift;
	my $editor_name = $editor->{wrangler}->config()->{'ui.formeditor.selected'};

	my $i=0;
	for(@{ $editor->{wrangler}->config()->{'ui.formeditor'}->{ $editor_name } }){
		last if $_ eq $field_name;
		$i++;
	}
	Wrangler::debug("FormEditor::RemoveField: '$field_name' from editor layout '$editor_name' (pos:$i) ");

	splice(@{ $editor->{wrangler}->config()->{'ui.formeditor'}->{ $editor_name } },$i,1); # remove pos from array
	Wrangler::PubSub::publish('main.formeditor.recreate');
}

sub SelectEditor {
	my $editor = shift;
	my $editor_name = shift;

	Wrangler::debug("FormEditor::SelectEditor: editor layout '$editor_name' ");
	$editor->{wrangler}->config()->{'ui.formeditor.selected'} = $editor_name;

	Wrangler::PubSub::publish('main.formeditor.recreate');
}

sub SaveFieldLayout {
	my $editor = shift;
	my $editor_name = $editor->{wrangler}->config()->{'ui.formeditor.selected'};

	Wrangler::debug("FormEditor::SaveFieldLayout");
	my $file_dialog = Wx::FileDialog->new($editor, "Save field layout", '', $editor_name.'.wfl', "Wrangler Field Layout (*.wfl)|*.wfl;All files (*.*)|*.*", wxFD_SAVE);

	return if $file_dialog->ShowModal == wxID_CANCEL;

	my $path = $file_dialog->GetPath;
	$file_dialog->Destroy;

	my $json = eval { JSON::XS->new->utf8->pretty->encode( { $editor_name => $editor->{editors}->{ $editor_name } } ) };
	Wrangler::debug("Wrangler::Wx::FormEditor::SaveFieldLayout: error encoding fields: $@") if $@;

	path($path)->spew_raw($json) or Wrangler::debug("Wrangler::Wx::FormEditor::SaveFieldLayout: error writing layout file: $path: $!")
}

sub LoadFieldLayout {
	my $editor = shift;
	my $editor_name = $editor->{wrangler}->config()->{'ui.formeditor.selected'};

	Wrangler::debug("FormEditor::LoadFieldLayout");
	my $file_dialog = Wx::FileDialog->new($editor, "Load field layout", '', '', "Wrangler Field Layout (*.wfl)|*.wfl;|All files (*.*)|*.*", wxFD_OPEN);

	return if $file_dialog->ShowModal == wxID_CANCEL;

	my $path = $file_dialog->GetPath;
	$file_dialog->Destroy;

	my $json = path($path)->slurp_raw or Wrangler::debug("Wrangler::Wx::FormEditor::LoadFieldLayout: error reading layout file: $!");
	my $ref = eval { JSON::XS::decode_json( $json ) };
	Wrangler::debug("Wrangler::Wx::FormEditor::LoadFieldLayout: error decoding layout file: $@") if $@;

	my $last;
	for(keys %$ref){
		unless(defined($editor->{editors}->{ $_ })){
			Wrangler::debug("FormEditor::LoadFieldLayout: adding layout $_");
			$editor->{editors}->{ $_ } = $ref->{$_} ;
			$last = $_;
		}
	}

	$editor->{wrangler}->config()->{'ui.formeditor.selected'} = $last;

	Wrangler::PubSub::publish('main.formeditor.recreate');
}

sub OnChar {
	my( $editor, $event ) = @_;
	# OnChar usually happens in TextCtrls
	my $element;
	unless($editor->isa('Wrangler::Wx::FormEditor')){
		$element = $editor;
		$editor = $element->GetParent();
	}

	my $mod  = $event->GetModifiers || 0;
	my $keycode = $event->GetKeyCode();

	# Wrangler::debug('FormEditor::OnChar: mod:'.$mod .', code:'. $keycode);

	if($keycode == WXK_UP){
		Wrangler::debug('FormEditor::OnChar: Arrow Up');

		# emit appropriate event
		Wrangler::PubSub::publish('filebrowser.selection_move.up',$event);
#		$editor->SetFocus();
	}elsif($keycode == WXK_DOWN){
		Wrangler::debug('FormEditor::OnChar: Arrow Down');

		# emit appropriate event
		Wrangler::PubSub::publish('filebrowser.selection_move.down',$event);
#		$editor->SetFocus();
	}else{
		if($editor->{valueshortcuts}){
			if(my $shortcut = $editor->{valueshortcuts}->{$mod.'-'.$keycode}){
				Wrangler::debug("FormEditor::OnChar: ValueShortcut for $shortcut->{name}");
				if( $editor->{ctrl_lookup}->{ $shortcut->{key} } ){
					Wrangler::debug(" inser into $shortcut->{key}");
					$editor->{ctrl_lookup}->{ $shortcut->{key} }->ChangeValue( $shortcut->{value} );
					$editor->{ctrl_lookup}->{ $shortcut->{key} }->MarkDirty();
				}else{
					if($element && ref($element) =~ /::TextCtrl/){
						Wrangler::debug(" inser into current element $element");
						$element->ChangeValue( $shortcut->{value} );
						$element->MarkDirty();
					}
				}
			}
		}
	}
	$event->Skip(1);
}

sub OnRightClick {
	my( $editor, $event ) = @_;
	# clicks may be on StaticText elements
	my $click_element;
	unless($editor->isa('Wrangler::Wx::FormEditor')){
		$click_element = shift;
		$editor = $click_element->GetParent();
	}

	my $menu = Wx::Menu->new();

	if($click_element){
		EVT_MENU( $editor, $menu->Append(-1, "Remove field", 'Remove/hide this metadata key/value pair' ), sub { $editor->RemoveField($click_element->GetName()); }  );
		$menu->AppendSeparator();
	}

	## "Add fields..."
	if($editor->{selected_editor}){
	#	if($editor->{field_count}){
			my $submenu = Wx::Menu->new();
			for( sort @{ $editor->{wrangler}->{fs}->available_properties($editor->{wrangler}->{current_dir}) } ){
				my $item = $submenu->Append(-1, $_);
				$submenu->Enable($item->GetId(),0) if $editor->{ctrl_lookup}->{$_};
				EVT_MENU( $editor, $item, sub { $editor->AddField($item->GetText()); } ); # deprecated: use GetItemLabel text soon
			}
			$submenu->AppendSeparator();
			my $item = $submenu->Append(-1, 'Other...');
			EVT_MENU( $editor, $item, sub { $editor->AddField(); } );
	#	}
		$menu->Append(-1, "Add fields...", $submenu, 'Add a metadata key/value pair' );
		$menu->AppendSeparator();
	}

	## "Add editor...", "Switch...", etc. if multiple editors
	EVT_MENU( $editor, $menu->Append(-1, "Add editor...", 'Create a new editor layout'), sub { $editor->Create(); } );
	if(ref($editor->{editors})){
		if(keys(%{$editor->{editors}}) > 1){
			my $submenu = Wx::Menu->new();
			for( sort keys %{ $editor->{editors} } ){
				my $item = $submenu->Append(-1, $_);
				$submenu->Enable($item->GetId(),0) if $_ eq $editor->{selected_editor};
				EVT_MENU( $editor, $item, sub { $editor->SelectEditor($item->GetText()); } ); # deprecated: use GetItemLabel text soon
			}
			$menu->Append(-1, "Switch editor...", $submenu, 'Change displayed editor');
		}
		EVT_MENU( $editor, $menu->Append(-1, "Rename editor", 'Rename this editor layout'), sub { $editor->Rename(); } );
		EVT_MENU( $editor, $menu->Append(-1, "Delete editor", 'Delete this editor layout'), sub { $editor->Delete(); } );
	}
	$menu->AppendSeparator();

	## load/save field layout(s)
	EVT_MENU( $editor, $menu->Append(-1, "Load field layout", 'Load a field layout from a file'), sub { $editor->LoadFieldLayout(); } );
	my $itemSave = Wx::MenuItem->new($menu, -1, "Save field layout", "Save this field layout to a file");
	$menu->Append($itemSave);

	if($editor->{field_count} > 1){
		$menu->Enable($itemSave->GetId(),1);
		EVT_MENU( $editor, $itemSave, sub { $editor->SaveFieldLayout(); } );
	}else{
		$menu->Enable($itemSave->GetId(),0);
	}
	$menu->AppendSeparator();

	## shortcut settings
	EVT_MENU( $editor, $menu->Append(-1, "Settings", 'Settings'), sub { Wrangler::PubSub::publish('show.settings', 0, 1); } ); # send to "Value Shortcuts" until FormEditor has its own Settings

	$editor->PopupMenu( $menu, wxDefaultPosition );
}

sub Destroy {
	my $self = shift;

	Wrangler::PubSub::unsubscribe_owner(__PACKAGE__);

#	$self->SUPER::Destroy(); # crash
}

1;

__END__

=pod

=head1 NAME

Wrangler::Wx::FormEditor - A form-based metadata editor widget

=head1 DESCRIPTION

FormEditor is able to manage multiple "views", called editors, where each editor
can be configured by the user to show arbitrary metadata fields. With this, a user
can create customised data-entry masks or an alternative metadata display. FormEditor
presents metadata in tabular form, with the metadata-key on the left and a TextCtrl
displaying the current metadata-value on the right, for possible modification.
Metadata-fields are populated once a selection is made in FileBrowser. In case
the user has changed any data, this change is committed when selection moves to
another file.

To configure form fields, right-click on the editor.

=head1 COPYRIGHT & LICENSE

This module is part of L<Wrangler>. Please refer to the main module for further
information and licensing / usage terms.
