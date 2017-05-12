package Wrangler::Wx::FileBrowserTreeList;

use strict;
use warnings;

use Wx qw(:everything);				# Lazy way to pull in references
use base qw(Wx::TreeListCtrl);
use Wx::Event qw(:everything);			# List required events
use HTTP::Date ();
use Encode;

sub new {
	my $class  = shift;
	my $parent = shift;
	my $self = $class->SUPER::new( $parent, -1, wxDefaultPosition, wxDefaultSize,
		wxTR_HIDE_ROOT|wxTR_HAS_BUTTONS|wxTR_EDIT_LABELS|wxSUNKEN_BORDER
		| wxTR_HAS_BUTTONS | wxTR_NO_LINES | wxTR_FULL_ROW_HIGHLIGHT | wxTR_MULTIPLE | wxTR_EXTENDED	# | wxWANTS_CHARS has no effect
	);

	# hook-up access to $wrangler
	$self->{wrangler} = $parent->{wrangler};

	# treelist is set-up centrally in Main; link data strctures here
	$self->SetImageList( ${ $parent->{imagelist} } );
	$self->{images} = $parent->{images};

	# hardcoded column-layout for now
	@{ $self->{columns} } = (
		{ label => 'Name',	value_from => 'Filesystem::Filename',	text_align => 'left',	width => 120 },
		{ label => 'Type',	value_from => 'Filesystem::Type',	text_align => 'right',	width => 100 },
		{ label => 'Modified',	value_from => 'Filesystem::Modified',	text_align => 'left',	width => 140 },
		{ label => 'Size',	value_from => 'Filesystem::Size',	text_align => 'right',	width => 70 },
		# no icon => values here; as columns do not know about icon presentation
	);

	# now add the columns (version switch from WxDemo)
	my $first = 1;
	for(reverse @{ $self->{columns} }){
		my $align = $_->{text_align} eq 'right' ? wxALIGN_RIGHT : wxALIGN_LEFT;
		if($first){
			if( $Wx::TreeListCtrl::VERSION > 0.06 ){
				$self->AddColumn( Wx::TreeListColumnInfo->new($_->{label}, $_->{width}, $align) );
			}else{
				$self->AddColumn( $_->{label}, $_->{width}, $align ); #  | wxCOL_SORTABLE
			}
			undef($first);
		}else{
			if( $Wx::TreeListCtrl::VERSION > 0.06 ){
				$self->InsertColumn(0, Wx::TreeListColumnInfo->new($_->{label}, $_->{width}, $align) );
			}else{
				$self->InsertColumn( $_->{label}, $_->{width}, $align );
			}
		}
	#	$self->SetColumnEditable(0,1); # col 0, set true
	#	$self->SetSortColumn(0);
	}

	## to mediate between begin/end routines, we use a small internal stash
	$self->{our_stash} = undef;

	## a hidden root node
	$self->{root} = $self->AddRoot( 'FileBrowser', -1, -1, Wx::TreeItemData->new( 'rootnode' ) );	# using GetRootItem() lead to segmentation faults when root not visible and we entered the tree with arrow up/down...

	$self->Clear();

	(my $richlist,$self->{current_dir}) = $self->{wrangler}->{fs}->richlist( $self->{wrangler}->{fs}->cwd() );
	sort_richlist($richlist);
	$self->Populate(undef,$richlist);

	$self->SetFocus();
	$self->Center();

	## Our custom FileBrowser events
	# To a certain extend, the filebrowser widgets 'know' about what they are
	# displaying and as such, they emit less generic, more meningful events
	# Note that we don't use these events here, alhtough we could, for example
	# for "local action", like what needs to be done when "a directory is activated".
	# That's because these Events are meant for other widgets, to which we send
	# a bit of information, but not things like the TreeEvent which is mostly
	# specific to the local widget and would be send around the app without use.
	Wrangler::PubSub::subscribe('file.selected', sub { Wrangler::debug("OnFileSelected: @_"); },__PACKAGE__);
	Wrangler::PubSub::subscribe('file.activated', sub { Wrangler::debug("OnFileActivated: @_"); },__PACKAGE__);
	Wrangler::PubSub::subscribe('dir.selected', sub { Wrangler::debug("OnDirSelected: @_"); },__PACKAGE__);
	Wrangler::PubSub::subscribe('dir.activated', sub { Wrangler::debug("OnDirActivated: @_"); },__PACKAGE__);
	Wrangler::PubSub::subscribe('zoom.in', sub {
		Wrangler::debug("OnZoomIn: @_");

		my $size = $self->GetFont()->GetPointSize() + 1;
		Wrangler::debug(" SetFont: $size");
		$self->SetFont( Wx::Font->new( $size, wxFONTFAMILY_DEFAULT, wxFONTSTYLE_NORMAL, wxFONTWEIGHT_NORMAL) );
		$self->Update();
	},__PACKAGE__);
	Wrangler::PubSub::subscribe('zoom.out', sub {
		Wrangler::debug("OnZoomOut: @_");

		my $size = $self->GetFont()->GetPointSize() - 1;
		Wrangler::debug(" SetFont: $size"."");
		$self->SetFont( Wx::Font->new( $size, wxFONTFAMILY_DEFAULT, wxFONTSTYLE_NORMAL, wxFONTWEIGHT_NORMAL) );
		$self->Update();
	},__PACKAGE__);
	Wrangler::PubSub::subscribe('zoom.standard', sub {
		Wrangler::debug("OnZoomStandard: @_");

		my $size = 11;
		Wrangler::debug(" SetFont: $size");
		$self->SetFont( Wx::Font->new( $size, wxFONTFAMILY_DEFAULT, wxFONTSTYLE_NORMAL, wxFONTWEIGHT_NORMAL) );
		$self->Update();
	},__PACKAGE__);

	## WxPerl TreeListCtrl (mainly) uses the TreeCtrl EVENT names
	EVT_TREE_SEL_CHANGING($self, $self, sub { Wrangler::debug("OnSelectionChanging");
		$_[1]->Veto() if $_[0]->GetItemText( $_[1]->GetItem() ) eq '..';
	});
	# Selection is changing. This can be prevented by calling Veto(). Processes a wxEVT_COMMAND_TREE_SEL_CHANGING event type.
	EVT_TREE_SEL_CHANGED($self, $self, sub {
		Wrangler::debug("OnSelectionChanged");
		return unless $_[1]->GetItem(); # click off list bounds
	});
	# Process wxEVT_COMMAND_TREELIST_SELECTION_CHANGED event and notifies about the selection change in the control. In the single selection case the item indicated by the event has been selected and previously selected item, if any, was deselected. In multiple selection case, the selection of this item has just changed (it may have been either selected or deselected) but notice that the selection of other items could have changed as well, use wxTreeListCtrl::GetSelections() to retrieve the new selection if necessary.
	EVT_TREE_ITEM_EXPANDING($self, $self, sub {
		Wrangler::debug("OnItemExpanding: ");

		# Note that we don't emit a DIR_ACTIVATION_EVENT here. Even a
		# TreeCtrl has the notion of a "current dir" and expanding a
		# sub-directory does not change that "current dir"

		my $itemId = $_[1]->GetItem();
		my $richlist_item = $_[0]->GetItemData( $itemId )->GetData();

		# hack for zebra-striping (TreeListCtrl doesn't count rows)
		my @zebra_offset;
		unless($richlist_item->{_cnt} % 2){
			# Wrangler::debug("user clicked a light row, start with a shaded row");;
			@zebra_offset = ( 'zebra_offset' => 1 );
		}

		my $richlist = $self->{wrangler}->{fs}->richlist($richlist_item->{'Filesystem::Path'});
		sort_richlist($richlist);
		Wrangler::debug(" Populate($itemId, $richlist)");
		$self->Populate($itemId, $richlist, include_updir => 0, @zebra_offset );
	});
	# Process wxEVT_COMMAND_TREELIST_ITEM_EXPANDING event notifying about the given branch being expanded. This event is sent before the expansion occurs and can be vetoed to prevent it from happening.
	EVT_TREE_ITEM_EXPANDED($self, $self, sub { Wrangler::debug("OnItemExpanded: @_"); });
	# Process wxEVT_COMMAND_TREELIST_ITEM_EXPANDED event notifying about the expansion of the given branch. This event is sent after the expansion occurs and can't be vetoed.
	EVT_TREE_ITEM_COLLAPSING($self, $self, sub {
		Wrangler::debug("OnItemCollapsing");

		my $itemId = $_[1]->GetItem();
		$_[0]->DeleteChildren($itemId); # free some memory (effect?)
		$_[0]->AppendItem( $itemId, '...', 0, 1 ); # a placeholder sub entry, to get the "expand" toggle-icon
	});
	# The item is being collapsed. This can be prevented by calling Veto(). Processes a wxEVT_COMMAND_TREE_ITEM_COLLAPSING event type.
	EVT_TREE_ITEM_COLLAPSED($self, $self, sub { Wrangler::debug("OnItemCollapsed"); });
	# The item has been collapsed. Processes a wxEVT_COMMAND_TREE_ITEM_COLLAPSED event type.
#	EVT_TREE_ITEM_CHECKED($self, $self, sub { Wrangler::debug("OnItemChecked"); });
	# Process wxEVT_COMMAND_TREELIST_ITEM_CHECKED event notifying about the user checking or unchecking the item. You can use wxTreeListCtrl::GetCheckedState() to retrieve the new item state and wxTreeListEvent::GetOldCheckedState() to get the previous one.
	EVT_TREE_ITEM_ACTIVATED($self, $self, sub { OnActivated(@_); });
	# Process wxEVT_COMMAND_TREELIST_ITEM_ACTIVATED event notifying about the user double clicking the item or activating it from keyboard.
	EVT_TREE_ITEM_MIDDLE_CLICK($self, $self, sub { Wrangler::debug("OnItemMiddleClick"); });
	# The user has clicked the item with the middle mouse button. This is only supported by the generic control. Processes a wxEVT_COMMAND_TREE_ITEM_MIDDLE_CLICK event type.
	EVT_TREE_ITEM_RIGHT_CLICK($self, $self, sub { Wrangler::debug("OnRightClick"); OnRightClick(@_) });
	# Process wxEVT_COMMAND_TREELIST_ITEM_CONTEXT_MENU event indicating that the popup menu for the given item should be displayed.
	EVT_RIGHT_UP($self, sub { Wrangler::debug("OnRightClickUp"); });
	# The user has right clicked the control with the right mouse button - but  not on any item
#	EVT_TREE_COLUMN_SORTED($self, $self, sub { Wrangler::debug("OnColumnSorted"); });
#	EVT_TREELIST_COLUMN_SORTED($self, $self, sub { Wrangler::debug("OnColumnSorted"); });
	# Process wxEVT_COMMAND_TREELIST_COLUMN_SORTED event indicating that the control contents has just been resorted using the specified column. The event doesn't carry the sort direction, use GetSortColumn() method if you need to know it.
	EVT_LIST_COL_CLICK($self, $self, sub {
		Wrangler::debug("OnColClick: @_ ");

		# remember sort col
		$self->{sort_column} = $_[1]->GetColumn;

		# toggle sort order
		$self->{sort_order} = $self->{sort_order} && $self->{sort_order} eq 'DESC' ? 'ASC' : 'DESC';

		Wrangler::debug("OnColClick: Sort by Col: ". $self->{sort_column} .' = '. $self->column_key($self->{sort_column}) .' sort '. $self->{sort_order});

		my $richlist = $self->{wrangler}->{fs}->richlist( $self->{wrangler}->{fs}->cwd() );
		sort_richlist($richlist, sort_on => $self->column_key($self->{sort_column}), sort_order => $self->{sort_order});
		$self->Populate(undef,$richlist);
	});
	#A column (m_col) has been left-clicked. Processes a wxEVT_COMMAND_LIST_COL_CLICK event type.
	EVT_LIST_COL_RIGHT_CLICK($self, $self, sub { Wrangler::debug("OnColRightClick: @_"); });
	#A column (m_col) has been right-clicked. Processes a wxEVT_COMMAND_LIST_COL_RIGHT_CLICK event type.
	EVT_LIST_COL_BEGIN_DRAG($self, $self, sub { Wrangler::debug("OnColBeginDrag: @_"); });
	#The user started resizing a column - can be vetoed. Processes a wxEVT_COMMAND_LIST_COL_BEGIN_DRAG event type.
	EVT_LIST_COL_DRAGGING($self, $self, sub { Wrangler::debug("OnColDragging: @_"); });
	#The divider between columns is being dragged. Processes a wxEVT_COMMAND_LIST_COL_DRAGGING event type.
	EVT_LIST_COL_END_DRAG($self, $self, sub { Wrangler::debug("OnColEndDrag: @_"); });
	#A column has been resized by the user. Processes a wxEVT_COMMAND_LIST_COL_END_DRAG event type.

	EVT_TREE_BEGIN_DRAG($self, $self, sub { Wrangler::debug("OnBeginDrag"); });
	# Begin dragging with the left mouse button. If you want to enable left-dragging you need to intercept this event and explicitly call wxTreeEvent::Allow(), as it's vetoed by default. Processes a wxEVT_COMMAND_TREE_BEGIN_DRAG event type.
	EVT_TREE_BEGIN_RDRAG($self, $self, sub { Wrangler::debug("OnBeginRightDrag"); });
	# Begin dragging with the right mouse button. If you want to enable right-dragging you need to intercept this event and explicitly call wxTreeEvent::Allow(), as it's vetoed by default. Processes a wxEVT_COMMAND_TREE_BEGIN_RDRAG event type.
	EVT_TREE_END_DRAG($self, $self, sub { Wrangler::debug("OnEndDrag"); });
	# End dragging with the left or right mouse button. Processes a wxEVT_COMMAND_TREE_END_DRAG event type.

	EVT_TREE_BEGIN_LABEL_EDIT($self, $self, sub { Wrangler::debug("OnBeginLabelEdit"); });
	# Begin editing a label. This can be prevented by calling Veto(). Processes a wxEVT_COMMAND_TREE_BEGIN_LABEL_EDIT event type.
	EVT_TREE_END_LABEL_EDIT($self, $self, sub { Wrangler::debug("OnEndLabelEdit"); OnEndLabelEdit(@_); });
	# Finish editing a label. This can be prevented by calling Veto(). Processes a wxEVT_COMMAND_TREE_END_LABEL_EDIT event type.
	EVT_TREE_DELETE_ITEM($self, $self, sub { Wrangler::debug("OnDeleteItem"); });
	# An item was deleted. Processes a wxEVT_COMMAND_TREE_DELETE_ITEM event type. Also called on window desctruction!
	EVT_TREE_KEY_DOWN($self, $self, sub { Wrangler::debug("OnKeyDown"); OnChar(@_); } );
	# A key has been pressed. Processes a wxEVT_COMMAND_TREE_KEY_DOWN event type.
	# overrides default key-navigation!
#	EVT_TREE_ITEM_GETTOOLTIP($self, $self, sub { Wrangler::debug("OnGetTooltip"); });
	# The opportunity to set the item tooltip is being given to the application (call wxTreeEvent::SetToolTip). Windows only. Processes a wxEVT_COMMAND_TREE_ITEM_GETTOOLTIP event type.
	EVT_TREE_ITEM_MENU($self, $self, sub { Wrangler::debug("OnItemContextMenu"); OnRightClick(@_); });
	# The context menu for the selected item has been requested, either by a right click or by using the menu key. Processes a wxEVT_COMMAND_TREE_ITEM_MENU event type.

#	EVT_TREE_GET_INFO(id, func);
	# Request information from the application. Processes a wxEVT_COMMAND_TREE_GET_INFO event type.
#	EVT_TREE_SET_INFO(id, func);
	# Information is being supplied. Processes a wxEVT_COMMAND_TREE_SET_INFO event type.

#	EVT_TREE_STATE_IMAGE_CLICK(id, func):
	# The state image has been clicked. Windows only. Processes a wxEVT_COMMAND_TREE_STATE_IMAGE_CLICK event type.#

	# has no effect, even with style == wxWANTS_CHARS
#	EVT_CHAR( $self, \&OnChar );
	EVT_PAINT($self, sub {
		# Wrangler::debug("OnPaint: @_");
		$self->OptimiseColumns();
	});
	EVT_SIZE($self, sub {
		Wrangler::debug("OnSize: @_");
		$self->OptimiseColumns(1);
		$_[1]->Skip(1);
	});

 return $self;
}

sub Clear {
	my ($filebrowser) = @_;

	$filebrowser->DeleteChildren( $filebrowser->{root} );
}

sub FinaliseLayout {
	my $filebrowser = shift;
	$filebrowser->OptimiseColumns();
}

sub OptimiseColumns {
	my $filebrowser = shift;
	my $force = shift;
	return if !$force && $filebrowser->{columns_optimised};

	## optimise column width
#	my $width = $filebrowser->GetViewRect()->width; # is completely off
	my $width = $filebrowser->GetClientSize()->width;
	my $width_half = int( ($width + 50) / 2); # +50 to compensate for $width being too small
	$filebrowser->SetColumnWidth (0, $width_half );

	my $colCnt = $filebrowser->GetColumnCount();
	Wrangler::debug("OptimiseColumns: width:$width; width_half:$width_half; colCnt:$colCnt");
	for(1 ..  $colCnt){
		$filebrowser->SetColumnWidth($_, int( $width_half / $colCnt ) );
	}
}


## who should know about sorting, Wx, the vfs, or wrangler? Wx is only presentation,
## so 'No'; the vfs is like fuse or the raw fs: no idea of sorting; and as expected,
## it's wrangler who does the sorting, so this is a helper offered by wrangler that
## can handle richlists, and does sorting like people expect it in a file-listing
my $regex_numeric = qr/^\d+$/;
sub sort_richlist {
	my $richlist = shift;
	my $args = {
		sort_on    => 'Filesystem::Filename',
		sort_order => 'ASC',
		@_
	};

	my $sort_on = $args->{sort_on};

	## separate types ; this is how we currently implement the two-level
	## sorting of 'on types' first, then 'by name'
	## we treat updir separately, so it's always first, sorting is still not perfect, as dotfiles
	## come after files starting with ! for example, should probably be the other way 'round
	my (@devices,@updir,@dirs,@files);
	my $data_type = 'numeric';
	for(@$richlist){
		if($_->{'Filesystem::Type'} eq 'Directory'){
			if(!@updir && $_->{'Filesystem::Filename'} eq '..'){
				push(@updir, $_);
			}else{
				push(@dirs, $_);
			}
		}elsif($_->{'Filesystem::Type'} eq 'File'){
			push(@files, $_);
		}else{
			push(@devices, $_);
		}
		$data_type = 'alphanumeric' unless $_->{ $sort_on } =~ $regex_numeric;
	}
	@$richlist = ();

	Wrangler::debug("sort_richlist: sort_on:$args->{sort_on}, sort_order:$args->{sort_order}, data_type:$data_type");

	if($data_type eq 'numeric'){
		# numeric
		if($args->{sort_order} eq 'DESC'){
			@dirs  = sort { $b->{ $sort_on } <=> $a->{ $sort_on } } @dirs;
			push(@dirs,@updir);
			@files = sort { $b->{ $sort_on } <=> $a->{ $sort_on } } @files;
		}else{
			@dirs  = sort { $a->{ $sort_on } <=> $b->{ $sort_on } } @dirs;
			unshift(@dirs,@updir);
			@files = sort { $a->{ $sort_on } <=> $b->{ $sort_on } } @files;
		}
	}else{
		# alphanumeric
		if($args->{sort_order} eq 'DESC'){
			@dirs  = sort { lc($b->{ $sort_on }) cmp lc($a->{ $sort_on }) } @dirs;
			push(@dirs,@updir);
			@files = sort { lc($b->{ $sort_on }) cmp lc($a->{ $sort_on }) } @files;
		}else{
			@dirs  = sort { lc($a->{ $sort_on }) cmp lc($b->{ $sort_on }) } @dirs;
			unshift(@dirs,@updir);
			@files = sort { lc($a->{ $sort_on }) cmp lc($b->{ $sort_on }) } @files;
		}
	}

	@$richlist = (@devices,@dirs,@files);

	return $richlist;
}

sub column_count {
	return $#{ $_[0]->{columns} };
}
sub column_key {
	return ${ $_[0]->{columns} }[ $_[1] ]->{value_from};
}

sub SelectAll {
	my $filebrowser = shift;

# no luck GetFirst/LastChild returns 0 instead of an ItemId obj

	my $cookie;
#	my $itemId = $filebrowser->GetFirstChild($filebrowser->{root});
	my $itemId = $filebrowser->{root};
	Wrangler::debug("SelectAll: $filebrowser->{root} $itemId");
	my $cnt;
	for(;;){
		$itemId = $filebrowser->GetNextChild($itemId);
		Wrangler::debug(" - $itemId");
		$filebrowser->SelectItem($itemId);
		$cnt++;
		last unless $itemId;
	}

#	my $cookie;
#	my $itemId = $filebrowser->GetFirstChild($filebrowser->{root});
#	Wrangler::debug(" $itemId");
#	for(;;){
#		$itemId = $filebrowser->GetNextItem($itemId,$cookie);
#		Wrangler::debug(" 1 ");
#	}

#	foreach ( 0 .. $filebrowser->GetItemCount - 1 ) {
#		if($_ == 0){
#			next if $filebrowser->GetItemText($_) eq '..';
#		}
#		$filebrowser->SetItemState( $_, wxLIST_STATE_SELECTED, wxLIST_STATE_SELECTED );
#	}

	$filebrowser->{wrangler}->publish('selection.changed', $cnt) if $cnt;
}

sub DeselectAll {
	my $filebrowser = shift;

	$filebrowser->UnselectAll();

	$filebrowser->{wrangler}->publish('selection.changed', 0);
}

sub InvertSelections {
	my $filebrowser = shift;

	my $cnt;
	foreach ( 0 .. $filebrowser->GetItemCount - 1 ) {
		if($_ == 0){
			next if $filebrowser->GetItemText($_) eq '..';
		}

		my $state = $filebrowser->GetItemState( $_, wxLIST_STATE_SELECTED );

		if($state == wxLIST_STATE_SELECTED){
			$filebrowser->SetItemState( $_, 0, wxLIST_STATE_SELECTED );
			$cnt++;
		}else{
			$filebrowser->SetItemState( $_, wxLIST_STATE_SELECTED, wxLIST_STATE_SELECTED );
		}
	}

	$filebrowser->{wrangler}->publish('selection.changed', $cnt) if $cnt;
}

# expects a parent tree-element and a path; optional args can override default behaviour
sub Populate {
	my $filebrowser = shift;
	my $element = shift || $filebrowser->{root};
	my $richlist = shift || [];
	my %args = (
		include_updir	=> $filebrowser->{wrangler}->config()->{'ui.filebrowser.include_updir'} // 1,	# /
		zebra_striping	=> $filebrowser->{wrangler}->config()->{'ui.filebrowser.zebra_striping'} // 1,	# /
		include_hidden	=> $filebrowser->{wrangler}->config()->{'ui.filebrowser.include_hidden'} // 0,	# /
		zebra_offset	=> 0, # TreeCtrl specific
		@_
	);

	## set cursor to 'busy', reverts back when local var gets out of scope
	my $busy = new Wx::BusyCursor;

	$filebrowser->Show( 0 );
	$filebrowser->DeleteChildren($element); # mostly for subdirs, which we populate with "..." to trigger the "expandable" icon

	my $rowCnt = 0;
	for(@$richlist){
		next if $_->{'Filesystem::Filename'} eq '.';
		next if $_->{'Filesystem::Filename'} eq '..' && !$args{include_updir};
		next if $_->{'Filesystem::Hidden'} && !$args{include_hidden};

		# build row
		my $item;
		for my $colCnt ( 0 .. $filebrowser->column_count() ){
			my $column_key = $filebrowser->column_key($colCnt);	# less lookups, easier on the eyes

			# see if the value is already in the richlist, else ask for it (should never happen; unless we fail in telling richlist what to get)
			my $column_value = defined($_->{$column_key}) ? $_->{$column_key} : $filebrowser->{wrangler}->{fs}->ask_vfs();

			# see if there's a renderer for this value-type
			my $renderer = $filebrowser->{wrangler}->{fs}->renderer($column_key);
			if($renderer){
				$column_value = $renderer->($_->{ $column_key });
			}

			# use proper insertion method
			if($colCnt == 0){
				# returns $item = Wx::TreeItemId obj
				$item = $filebrowser->AppendItem( $element,
					$column_value,
					0, 1, Wx::TreeItemData->new( $_ )	 # we store a ref to the richlist_item
				);
			}else{
				$filebrowser->SetItemColumnText( $item, $colCnt, $column_value );
			}
		}

		if( $_->{'Filesystem::Type'} eq 'Directory' ){
			if($_->{'Filesystem::Filename'} eq '..'){
				$filebrowser->SetItemImage( $item, 0, $filebrowser->{images}->{go_up});
			}else{
				$filebrowser->SetItemImage( $item, 0, $filebrowser->{images}->{folder});

				# a placeholder sub entry, to get the "expand" toggle-icon
				my $subtree = $filebrowser->AppendItem( $item, '...', 0, 1 );
			}
		}else{
			$filebrowser->SetItemImage( $item, 0, $filebrowser->{images}->{file});
		}

		# MIME-mediaType highlighting
		my ($col_hi,$col_low) = (235,220);
		if(my $mediaType = $_->{'MIME::mediaType'}){
			if($mediaType eq 'video'){
				$filebrowser->SetItemBackgroundColour($item, Wx::Colour->new($col_hi, $col_low, $col_low));	# Video, light red: 235, 220, 220
			}elsif($mediaType eq 'image'){
				$filebrowser->SetItemBackgroundColour($item, Wx::Colour->new($col_low, $col_hi, $col_low));	# Image, light green: 220, 235, 220
			}elsif($mediaType eq 'audio'){
				$filebrowser->SetItemBackgroundColour($item, Wx::Colour->new($col_low, $col_low, $col_hi));	# Audio, light green: 220, 220, 235
			# }elsif($mediaType eq 'child'){ # unused
			#	$filebrowser->SetItemBackgroundColour($item, Wx::Colour->new(220,220,220));
			}
		}

		# zebra-striping
		if($args{zebra_striping} && (($rowCnt + $args{zebra_offset}) % 2)){
			my @colour;
			if('intelligent'){
				my $colour = $filebrowser->GetItemBackgroundColour($item);
				@colour = ($colour->Red(), $colour->Green(), $colour->Blue());
				for(@colour){ $_ -= 7; }
			}else{ # 'fast'
				@colour = (248,248,248);
			}
			$filebrowser->SetItemBackgroundColour($item, Wx::Colour->new(@colour));
		}

		$rowCnt++;
	}

	$filebrowser->Show( 1 );
}


sub Mkdir {
	my $filebrowser = shift;

	## find last dir in listing
	my @selections;
	my $currId = 0;
	for(;;){
		$currId = $filebrowser->GetNextSibling($currId);
		if($currId == -1){
			last;
		}else{
			push(@selections, $currId);
			Wrangler::debug(" push $currId ");

			my $richlist_item = $filebrowser->GetOurItemData( $filebrowser->GetItem($currId)->GetData() );
			my $path = $richlist_item->{'Filesystem::Path'};
			if($richlist_item->{'Filesystem::Type'} ne 'Directory'){
			#	pop(@selections);
				last;
			}

		}
	}

	my $lastId = $selections[-1];
	# Wrangler::debug("Last dir in listing is $lastId");

	## insert a placeholder item below dirs
	my $itemId = $filebrowser->InsertImageStringItem( $lastId,
		'New directory',
		$filebrowser->{images}->{ 'folder' }
	);
	$filebrowser->SetOurItemData($lastId, { ref_to_ => 'richlist type data' });
	$filebrowser->SetItemData($lastId, $lastId);

	# make sure the listing is scrolled, so the user can see the new item, and start label edit
	$filebrowser->EnsureVisible($itemId);
	$filebrowser->EditLabel($itemId);

	# this is all we can do here, the directory is actually created in OnEndLabelEdit()
	$filebrowser->{our_stash} = { mkdir => $itemId };
}

sub Rename {
	my $filebrowser = shift;

	my $w = $filebrowser->{wrangler};

	my @selections = $filebrowser->GetSelections(); # docs: wxPerl note: In wxPerl this method takes no parameters and returns a list of Wx::TreeItemIds. 
	my $selCnt = @selections;
	Wrangler::debug("FileBrowser: Rename: $selCnt items ");

	for(@selections){
		push(@{ $filebrowser->{our_stash}->{rename} }, {
			id	=> $_,
			file	=> $filebrowser->GetItemText($_),
		});
	}

	if($selCnt == 0){
		return;
	}elsif($selCnt == 1){
		# the actual rename is done in OnEndEditLabel()
		# (use the LabelEdit editor to handle the rename)
		$filebrowser->EditLabel( $selections[0] );
	}elsif($selCnt > 1){
		# use a more sophisticated dialogue for multi-renames
		require Wrangler::Dialog::MultiRename;
		my $dialog = Wrangler::Dialog::MultiRename->new($filebrowser->{our_stash}->{rename});

		if($dialog->ShowModal() == wxID_OK){
			if( $dialog->{pre}->IsModified || $dialog->{ins}->IsModified ){
				Wrangler::debug("Prepend/append-rename was used ");

				my $pre = $dialog->{pre}->GetValue();
				my $ins = $dialog->{ins}->GetValue();

				foreach my $item (@{ $filebrowser->{ourclipboard} }){
					my $oldpath = File::Spec->catfile( $filebrowser->{current_dir}, $item->{file});

					my ($file, $dirs, $suffix) = File::Basename::fileparse($item->{file}, qr/\.[^.]*/);

					my $newpath = File::Spec->catfile( $filebrowser->{current_dir}, $pre.$file.$ins.$suffix);

					next if $oldpath eq $newpath; # prevent that the update-internal-tree gets corrupted, and of course an unnecessary fs IO
					# todo: check this via the OnEditLabel dirty? function

					## do the actual rename
					$filebrowser->{wrangler}->{fs}->rename($oldpath, $newpath);

					## update the internal metadata tree
				#	$self->{tree}->{$newpath} = $self->{tree}->{$oldpath};
				#	delete($self->{tree}->{$oldpath});

					## update GUI
					Wrangler::debug("Wrangler::FileBrowser::rename(multi): rename($oldpath, $newpath) ");
					$filebrowser->SetItemText($item->{id}, $pre.$file.$ins.$suffix);
				}
			}elsif( $dialog->{multi}->IsModified ){
				Wrangler::debug("Pattern-rename was used ");

				my $multi = $dialog->{multi}->GetValue();
					$multi = decode_utf8($multi);	# decode
					Encode::_utf8_off($multi);	# then remove the utf8-flag the hard way
				my $oldlen = $dialog->{length};
				my $newlen = length($multi);
				Wrangler::debug("MULTI: $multi OLDLEN: $oldlen NEWLEN:$newlen");
			}
		}else{
			Wrangler::debug("Multiple rename CANCELd ");
		}

		# clear ourclipboard
		undef($filebrowser->{our_stash});

		# Fire the rename via the Event which are triggered by EditLabel OnBEginEdit / OnEndEdit
		# $filebrowser->EditLabel($selId);
	}
}


sub OurDelete {	# treelistctrl has a Delete() as well!
	my $filebrowser = shift;

	my $w = $filebrowser->{wrangler};

	my @selections = $filebrowser->GetSelections(); # docs: wxPerl note: In wxPerl this method takes no parameters and returns a list of Wx::TreeItemIds. 
	my $selCnt = @selections;
	return if $selCnt == 0;
	Wrangler::debug("FileBrowser: delete: $selCnt items ");

	# create a progress dialog
	my $pd = Wx::ProgressDialog->new("Deleting...", "Deleting...", $selCnt, $filebrowser, wxPD_AUTO_HIDE | wxPD_APP_MODAL | wxPD_REMAINING_TIME );

	my $cnt=1;
	for my $currId (@selections){
		my $richlist_item = $filebrowser->GetItemData( $currId )->GetData();
		my $path = $richlist_item->{'Filesystem::Path'};

		## just to be sure we don't del the 'up-dir'!
		## system's "rm" denies deleting it but rmtree, which we use here, inteprets it as a valid path and deletes it!
		if($path =~ /\.\.$/){
			Wrangler::debug("FileBrowser: skipped delete of the 'up-dir'! ");
			$pd->Update($_);
			next;
		}

		if( $richlist_item->{'Filesystem::Type'} eq 'Directory' ){
			Wrangler::debug("FileBrowser: delete ($cnt of $selCnt): currId:$currId, path:$path");

			## delete dir
	#		$w->{fs}->rmdir($path);
		}else{
			Wrangler::debug("FileBrowser: delete ($cnt of $selCnt): currId:$currId, path:$path");

			## delete file
	#		$w->{fs}->delete($path);
		}

		$filebrowser->DeleteChildren($currId);
		$filebrowser->Delete($currId);

		$pd->Update($cnt);
		$cnt++;
		last if $cnt > $selCnt;
	}

# select the 'next' item after the delete(s)
#	if($_ == $selCnt){
#		my $next_id = $filebrowser->GetNextItem($currId, wxLIST_NEXT_ALL);
#		$filebrowser->SetItemState( $next_id, wxLIST_STATE_SELECTED, wxLIST_STATE_SELECTED );
#	}

	$filebrowser->SetFocus();
}


sub OnEndLabelEdit {
	my( $filebrowser, $event ) = @_;

	if( $filebrowser->{our_stash}->{mkdir} ){
		## mkdir path
		my $path = $filebrowser->GetItemText( $event->GetItem );
			$path = decode_utf8($path);	# decode
			Encode::_utf8_off($path);	# then remove the utf8-flag the hard way

	#	$path = File::Spec->catfile( $filebrowser->{current_dir}, $path );
		Wrangler::debug(" mkdir: $path");
	#	$filebrowser->{wrangler}->{fs}->mkdir($path);

		$filebrowser->{our_stash} = undef;
	}else{
		## oldpath
		my $oldpath = ${ $filebrowser->{our_stash}->{rename} }[0]->{file};
		$filebrowser->{our_stash} = undef;

		## newpath
		my $newpath = $filebrowser->GetItemText( $event->GetItem() );
			$newpath = decode_utf8($newpath);	# decode
			Encode::_utf8_off($newpath);		# then remove the utf8-flag the hard way
		# $newpath = File::Spec->catfile( $filebrowser->{current_dir}, $newpath);

## we've got a BUG here: GetItemText returns the string the item had *before* the edit,
## but we're in OnEndLabelEdit here...

		# check if label has been edited
		return if $oldpath eq $newpath;

#		## do the actual rename on storage
#		$self->{wrangler}->{fs}->rename($oldpath, $newpath);

		Wrangler::debug(" rename($oldpath, $newpath)");
	}
}


sub OnActivated {
	Wrangler::debug("OnActivated: @_ ");
	my( $filebrowser, $event ) = @_;

	# todo: allow multiple files to get activated, but only from one viewer-(file-type)-group
	return if $filebrowser->GetSelectedItemCount() > 1;

	my @selections = $filebrowser->GetSelections();
	my $richlist_item = $filebrowser->GetOurItemData(  $filebrowser->GetItem( shift(@selections) )->GetData()  );
	my $path = $richlist_item->{'Filesystem::Path'};

	Wrangler::debug("OnActivated: path:$path");

	if( $richlist_item->{'Filesystem::Type'} =~ /^Directory$|^Drive$/ ){
		(my $richlist,$path) = $filebrowser->{wrangler}->{fs}->richlist( $richlist_item->{'Filesystem::Path'} );

		Wrangler::debug(" change directory: $path");

		# emit appropriate event
		$filebrowser->{wrangler}->publish('dir.activated', $path);

		sort_richlist($richlist);
		$filebrowser->Populate($richlist);
		$filebrowser->{current_dir} = $path;

		$filebrowser->{wrangler}->publish('directory.focus', $path);
	}else{
		# emit appropriate event
		$filebrowser->{wrangler}->publish('file.activated',$path);

		Wrangler::debug(" is a file");

	#	my $type = Wrangler::Scan::type_from_ext($itemText);
		my $type = 'image';
		if($type eq 'video'){
			if('external video viewer'){
				my $pid = ForkAndExec('/usr/bin/avplay', $richlist_item->{'Filesystem::Path'} );
	#			$self->{statusbar}->SetStatusText("Launched external video-viewer with pid $pid",2)
			}else{
	#			$filebrowser->{viewer} = Wrangler::VideoViewer->new( $self ) if !$filebrowser->{viewer};

	#			$self->Show(0);
	#			$filebrowser->{viewer}->Show(1);

	#			$filebrowser->{viewer}->Load(
	#				File::Spec->catfile( $filebrowser->{current_dir}, $itemText), $itemText
	#			);
			}
		}elsif($type eq 'image'){
			if('external image viewer'){
				# do local action
				Wrangler::debug(" defined OnFileActivated action: ForkAndExec('viewnior', $richlist_item->{'Filesystem::Path'})");
				# maybe we should let this event propagate up to Wrangler, to shoot the viewing app...
				my $pid = ForkAndExec('/usr/local/bin/viewnior', $richlist_item->{'Filesystem::Path'} );
	##			my $pid = ForkAndExec('/usr/bin/eog', $richlist_item->{'Filesystem::Path'} );
	#			$self->{statusbar}->SetStatusText("Launched external image-viewer with pid $pid",2)
			}else{
	#			$filebrowser->{viewer} = Wrangler::ImageViewer->new( $filebrowser ) if !$filebrowser->{viewer};
	#		#	$self->Show(0);
	#		##	$filebrowser->{viewer}->SetFocus();
	#		##	Wrangler::debug("=== Find Focus ". Wx::Window::FindFocus() );

	#			$filebrowser->{viewer}->Load(
	#				File::Spec->catfile( $filebrowser->{current_dir}, $itemText), $itemText
	#			);
			}
		}elsif($type eq 'audio'){
			if('external audio viewer'){
				my $pid = ForkAndExec('/usr/bin/smplayer %s', $richlist_item->{'Filesystem::Path'} );
	#			$self->{statusbar}->SetStatusText("Launched external audio-viewer with pid $pid",2)
			}else{
	#			$filebrowser->{viewer} = Wrangler::SoundViewer->new( $self ) if !$filebrowser->{viewer};

	#			$self->Show(0);
	#			$filebrowser->{viewer}->Show(1);

	#			$filebrowser->{viewer}->Load(
	#				File::Spec->catfile( $filebrowser->{current_dir}, $itemText), $itemText
	#			);
			}
		}elsif($type eq 'playlist'){
			Wrangler::Dialog::PlaylistEditor->new($path);
		}else{
			print 'Is File: we can\'t handle. returning.';
			return;
		}
	}
}


sub OnRightClick {
	my $filebrowser = shift;
	my $event = shift;
	my $w = $filebrowser->{wrangler};

        my $menu = Wx::Menu->new();

	## hardcoded entries
	EVT_MENU( $filebrowser, $menu->Append(-1, "View\tENTER", 'Execute/view with viewer'),	 sub { $filebrowser->OnActivated } );
	$menu->AppendSeparator();
	EVT_MENU( $filebrowser, $menu->Append(-1, "Create directory", 'Create a directory' ),	 sub { $filebrowser->Mkdir(); } );
	EVT_MENU( $filebrowser, $menu->Append(-1, "Delete\tDEL", 'Delete a file or directory' ), sub { $filebrowser->OurDelete(); } ); # treelistctrl has a Delete() as well!
	EVT_MENU( $filebrowser, $menu->Append(-1, "Rename\tF2", 'Rename file' ),		 sub { $filebrowser->Rename(); }  );

	## plugin entries
	if( my $plugins_ref = $w->{plugin_manager}->plugins('context_menu') ){
		$menu->AppendSeparator();

		for my $plugin (@{ $plugins_ref }){
			for my $entry ( @{ $plugin->menu_entries } ){
				EVT_MENU( $filebrowser, $menu->Append(-1, ${$entry}[0], ${$entry}[1] ), ${$entry}[2] );
			}
		}
	}

	$filebrowser->PopupMenu( $menu, wxDefaultPosition ); # alt: $event->GetPosition
}


sub OnChar {
	my( $filebrowser, $event ) = @_;

	my $keycode = $event->GetKeyCode();	# speedup by less calls

	Wrangler::debug("OnChar: $keycode");

	if($keycode == 9){
		Wrangler::debug("SHIFT+CTRL+I: Invert selection");

		$filebrowser->InvertSelections();
	}elsif($keycode == 1){
		Wrangler::debug("CTRL+A: Select all");

		$filebrowser->SelectAll();
	}elsif($keycode == 43){
		Wrangler::debug("CTRL++: View Zoom-In: ");

		# emit appropriate event
		$filebrowser->{wrangler}->publish('zoom.in');
	}elsif($keycode == 45){
		Wrangler::debug("CTRL+-: View Zoom-Out: ");

		# emit appropriate event
		$filebrowser->{wrangler}->publish('zoom.out');
	}elsif($keycode == 48){
		Wrangler::debug("CTRL+0: View Zoom-Standard: ");

		# emit appropriate event
		$filebrowser->{wrangler}->publish('zoom.standard');
	}elsif($keycode == WXK_ESCAPE){
		if($filebrowser->{in_viewmode}){
			Wrangler::debug("ESC: Filebrowser is viewing: so close Viewer.");
		#	$filebrowser->{viewer}->Close();
		#	$filebrowser->Show(1);
		}else{
			Wrangler::debug("ESC: Deselect all");
			$filebrowser->DeselectAll();
		}
	}elsif($keycode == WXK_F2){
		Wrangler::debug("F2: Rename");

		$filebrowser->Rename();
	}elsif($keycode == WXK_DELETE){
		Wrangler::debug("Delete");

		$filebrowser->Delete();
	}

	$event->Skip(1);
}


sub ForkAndExec {
	my @commands = @_;

	my $pid = fork();

	print STDERR "unable to fork: $!" unless defined($pid);
	return undef unless defined($pid);

	# contains no pid when we're in the forked child
	if(!$pid){
		exec(@commands);
		die "unable to exec: $!";
	}

	return $pid if $pid;
}

sub Destroy {
	my $self = shift;

	Wrangler::PubSub::unsubscribe_owner(__PACKAGE__);

	$self->SUPER::Destroy();
}

1;
