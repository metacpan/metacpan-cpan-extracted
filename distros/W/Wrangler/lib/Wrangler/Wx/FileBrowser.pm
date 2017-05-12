package Wrangler::Wx::FileBrowser;

use strict;
use warnings;

use Wx qw(:everything);
use Wx::Event qw(:everything);
use Wx::DND; # offers wxTheClipboard
use base qw(Wx::ListCtrl);
use HTTP::Date ();
use Encode;

sub new {
	my $class  = shift;
	my $parent = shift;
	my $self = $class->SUPER::new( $parent, -1, wxDefaultPosition, wxDefaultSize,
		wxLC_REPORT | wxLC_EDIT_LABELS | wxSUNKEN_BORDER
	);

	# hook-up access to $wrangler
	$self->{wrangler} = $parent->{wrangler};

	# imagelist is set-up centrally in Main; link data structures here
	$self->SetImageList( ${ $parent->{imagelist} }, wxIMAGE_LIST_SMALL );
	$self->{images} = $parent->{images};

	$self->SetForegroundColour(Wx::Colour->new(@{ $self->{wrangler}->config()->{'ui.foreground_colour'} })) if $self->{wrangler}->config()->{'ui.foreground_colour'};

	## to mediate between begin/end routines, we use a small internal stash
	$self->{our_stash} = undef;

	$self->Columns();
	(my $richlist,$self->{current_dir}) = $self->{wrangler}->{fs}->richlist( $self->{wrangler}->{fs}->cwd(), Wrangler::wishlist() );
	$self->sort_richlist($richlist);
	$self->Populate($richlist);

	# anything supplied via CLI?
	my $start_dir = $Wrangler::Config::env{CLI_ChangeDirectory} ? $Wrangler::Config::env{CLI_ChangeDirectory} : $self->{wrangler}->{fs}->cwd();

	# emit appropriate event
	Wrangler::PubSub::publish('dir.activated', $start_dir );
	$self->{wrangler}->{current_dir} = $start_dir;	# a race-condition seems to be preventing global current_dir in Wrangler to be populated right after startup, so we need this hack; with multiple FileBrowser widget, last-wins

#	$self->SetFocus();

	## our custom FileBrowser events
	# To a certain extend, the filebrowser widgets 'know' about what they are
	# displaying and as such, they emit less generic, more meningful events
	# Note that we don't use these events here, although we could, for example
	# for "local action", like what needs to be done when "a directory is activated".
	# That's because these Events are meant for other widgets, to which we send
	# a bit of information, but not things like the TreeEvent which is mostly
	# specific to the local widget and would be send around the app without use.
	Wrangler::PubSub::subscribe('dir.activated', sub { Wrangler::debug("OnDirActivated: @_"); $self->ChangeDirectory($_[0]); },__PACKAGE__);
	Wrangler::PubSub::subscribe('filebrowser.refresh', sub {	# triggered after settings for this widget have changed
		Wrangler::debug("OnRefresh: @_");
		$self->RePopulate();
	},__PACKAGE__);
	Wrangler::PubSub::subscribe('filebrowser.refresh.all', sub {	# triggered after column-settings for this widget have changed
		Wrangler::debug("OnRefreshAll: @_");
		$self->ClearAll(); # delete all items and all columns
		$self->Columns();
		$self->RePopulate();
	},__PACKAGE__);
	Wrangler::PubSub::subscribe('filebrowser.selection_move.up', sub {	# used to remotely move selection; used by FormEditor
		$self->SelectionMoveUp(@_);
	},__PACKAGE__);
	Wrangler::PubSub::subscribe('filebrowser.selection_move.down', sub {	# used to remotely move selection; used by FormEditor
		$self->SelectionMoveDown(@_);
	},__PACKAGE__);
	Wrangler::PubSub::subscribe('zoom.in', sub {
		Wrangler::debug("OnZoomIn: @_");

		my $size = $self->GetFont()->GetPointSize() + 1;
		Wrangler::debug(" SetFont: $size");
		$self->SetFont( Wx::Font->new( $size, wxFONTFAMILY_DEFAULT, wxFONTSTYLE_NORMAL, wxFONTWEIGHT_NORMAL) );
		$self->Update();
		$self->{wrangler}->config()->{'ui.filebrowser.font_size'} = $size;
	},__PACKAGE__);
	Wrangler::PubSub::subscribe('zoom.out', sub {
		Wrangler::debug("OnZoomOut: @_");

		my $size = $self->GetFont()->GetPointSize() - 1;
		Wrangler::debug(" SetFont: $size");
		$self->SetFont( Wx::Font->new( $size, wxFONTFAMILY_DEFAULT, wxFONTSTYLE_NORMAL, wxFONTWEIGHT_NORMAL) );
		$self->Update();
		$self->{wrangler}->config()->{'ui.filebrowser.font_size'} = $size;
	},__PACKAGE__);
	Wrangler::PubSub::subscribe('zoom.standard', sub {
		Wrangler::debug("OnZoomStandard: @_");

		my $size = 9;
		Wrangler::debug(" SetFont: $size");
		$self->SetFont( Wx::Font->new( $size, wxFONTFAMILY_DEFAULT, wxFONTSTYLE_NORMAL, wxFONTWEIGHT_NORMAL) );
		$self->Update();
		$self->{wrangler}->config()->{'ui.filebrowser.font_size'} = $size;
	},__PACKAGE__);

	## WxPerl ListCtrl events
	EVT_LIST_BEGIN_DRAG($self, $self, sub {
		Wrangler::debug("OnBeginDrag: @_");
	#	my $source = Wx::DropSource->new( $self );
	#	# $source->SetData( $self->GetSelections_as_FileDataObject() );
	#	$source->SetData( $self->GetSelections_as_CompositeDataObject() );
	#	$source->DoDragDrop(1);
	});
	#Begin dragging with the left mouse button. Processes a wxEVT_COMMAND_LIST_BEGIN_DRAG event type.
	EVT_LIST_BEGIN_RDRAG($self, $self, sub { Wrangler::debug("OnBeginRDrag: @_"); });
	#Begin dragging with the right mouse button. Processes a wxEVT_COMMAND_LIST_BEGIN_RDRAG event type.
#	EVT_BEGIN_LABEL_EDIT($self, $self, sub { Wrangler::debug("OnBeginLabelEdit: @_"); });
	#Begin editing a label. This can be prevented by calling Veto(). Processes a wxEVT_COMMAND_LIST_BEGIN_LABEL_EDIT event type.
	EVT_LIST_END_LABEL_EDIT($self, $self, sub { Wrangler::debug("OnEndLabelEdit: @_"); OnEndLabelEdit(@_); });
	#Finish editing a label. This can be prevented by calling Veto(). Processes a wxEVT_COMMAND_LIST_END_LABEL_EDIT event type.
	EVT_LIST_DELETE_ITEM($self, $self, sub { Wrangler::debug("OnDeleteItem: @_"); });
	#An item was deleted. Processes a wxEVT_COMMAND_LIST_DELETE_ITEM event type.
	EVT_LIST_DELETE_ALL_ITEMS($self, $self, sub { Wrangler::debug("OnDeleteAllItems: @_"); });
	#All items were deleted. Processes a wxEVT_COMMAND_LIST_DELETE_ALL_ITEMS event type.
	EVT_LIST_ITEM_SELECTED($self, $self, sub {
		# collapse SelectAll into one event, emitted in SelectAll()
		if($self->{our_stash}->{ignore_selected}){
			Wrangler::debug("OnItemSelected: (ignored, SelectAll) @_");
			delete($self->{our_stash}->{ignore_selected});
			return;
		}

		my $selections = $_[0]->GetSelections_as_richlist_items();

		# ignore re-selects of same item
		if(	$self->{current_selection}
			&& scalar(@{$self->{current_selection}}) == 1
			&& scalar(@{$self->{current_selection}}) == scalar(@$selections)
			&& $self->{current_selection}->[0]->{_itemId} == $selections->[0]->{_itemId}
		){
			Wrangler::debug("OnItemSelected: (ignored, is same) @_");
			return;
		}

		Wrangler::debug("OnItemSelected (changed): @_");
		$self->{current_selection} = $selections;
		Wrangler::PubSub::publish('selection.changed', scalar(@$selections), $selections );
	});
#	EVT_LEFT_UP($self, sub { Wrangler::debug("OnLeftUp: @_"); });
#	EVT_KEY_UP($self, sub { Wrangler::debug("OnKeyUp: @_"); });
	# The item has been selected. Means 'is done' thus can't be vetoed. Processes a wxEVT_COMMAND_LIST_ITEM_SELECTED event type.
	EVT_LIST_ITEM_DESELECTED($self, $self, sub { Wrangler::debug("OnItemDeselected: @_"); });
	#The item has been deselected. Processes a wxEVT_COMMAND_LIST_ITEM_DESELECTED event type.
	EVT_LIST_ITEM_ACTIVATED($self, $self, sub { OnActivated(@_); });
	#The item has been activated (ENTER or double click). Processes a wxEVT_COMMAND_LIST_ITEM_ACTIVATED event type.
	EVT_LIST_ITEM_FOCUSED($self, $self, sub { Wrangler::debug("OnItemFocused: @_"); });
	#The currently focused item has changed. Processes a wxEVT_COMMAND_LIST_ITEM_FOCUSED event type.
#	EVT_LIST_ITEM_MIDDLE_CLICK($self, $self, sub { Wrangler::debug("On: @_"); });
	#The middle mouse button has been clicked on an item. This is only supported by the generic control. Processes a wxEVT_COMMAND_LIST_ITEM_MIDDLE_CLICK event type.
	EVT_LIST_ITEM_RIGHT_CLICK($self, $self, sub { Wrangler::debug("OnRightClick: @_"); OnRightClick(@_); });
	#The right mouse button has been clicked on an item. Processes a wxEVT_COMMAND_LIST_ITEM_RIGHT_CLICK event type.
	EVT_LIST_KEY_DOWN($self, $self, sub { Wrangler::debug("OnKeyDown: @_"); });
	#A key has been pressed. Processes a wxEVT_COMMAND_LIST_KEY_DOWN event type.
#silent	EVT_LIST_INSERT_ITEM($self, $self, sub { Wrangler::debug("OnInsertItem: @_"); });
	#An item has been inserted. Processes a wxEVT_COMMAND_LIST_INSERT_ITEM event type.
	EVT_LIST_COL_CLICK($self, $self, sub {
		Wrangler::debug("OnColClick: @_");

		# toggle sort order
		$self->{sort_column} = $_[1]->GetColumn;
		$self->{sort_order} = $self->{sort_order} && $self->{sort_order} eq 'DESC' ? 'ASC' : 'DESC';

		# remember sorting
		my $config = $self->{wrangler}->config();
		my $sort_on = $self->column_key($self->{sort_column});
		if( $config->{'ui.filebrowser.sorting.per_directory'} ){
			$config->{'ui.filebrowser.sort'}->{ $self->{current_dir} } = [$self->{sort_order}, $sort_on];
		}else{
			$config->{'ui.filebrowser.sort'} = [$self->{sort_order}, $sort_on];
		}

		Wrangler::debug("OnColClick: sort_column:". $self->{sort_column} .' = sort_on:'. $sort_on .', sort_order:'. $self->{sort_order} );

		$self->RePopulate();
	});
	#A column (m_col) has been left-clicked. Processes a wxEVT_COMMAND_LIST_COL_CLICK event type.
	EVT_LIST_COL_RIGHT_CLICK($self, $self, sub { Wrangler::debug("OnColRightClick: @_");
		Wrangler::PubSub::publish('show.settings', 1, 2);
	});
	#A column (m_col) has been right-clicked. Processes a wxEVT_COMMAND_LIST_COL_RIGHT_CLICK event type.
	EVT_LIST_COL_BEGIN_DRAG($self, $self, sub { Wrangler::debug("OnColBeginDrag: @_"); });
	#The user started resizing a column - can be vetoed. Processes a wxEVT_COMMAND_LIST_COL_BEGIN_DRAG event type.
	EVT_LIST_COL_DRAGGING($self, $self, sub { Wrangler::debug("OnColDragging: @_"); });
	#The divider between columns is being dragged. Processes a wxEVT_COMMAND_LIST_COL_DRAGGING event type.
	EVT_LIST_COL_END_DRAG($self, $self, sub {
		Wrangler::debug("OnColEndDrag: @_");

		my $col = $_[1]->GetColumn();
		my $newwidth = $_[0]->GetColumnWidth($col);
		$self->{columns}->[$col]->{width} = $newwidth;

		## update our hit->col index, used in GetColumn()
		$self->{columns_widths_index} = [0];
		my $accumulated_width;
		for (0 .. $#{ $self->{columns} }){
			$accumulated_width += ${ $self->{columns} }[$_]->{width};
			push(@{ $self->{columns_widths_index} }, $accumulated_width);
		}

		# Wrangler::debug(" column: $col, width:$newwidth");
	});
	#A column has been resized by the user. Processes a wxEVT_COMMAND_LIST_COL_END_DRAG event type.
	EVT_LIST_CACHE_HINT($self, $self, sub { Wrangler::debug("OnListCacheHint: @_"); });
	#Prepare cache for a virtual list control. Processes a wxEVT_COMMAND_LIST_CACHE_HINT event type.

	EVT_CHAR( $self, \&OnChar );
	EVT_PAINT($self, sub {
		# Wrangler::debug("OnPaint: @_");
		# $self->OptimiseColumns();
	});
	EVT_SIZE($self, sub {
		# Wrangler::debug("OnSize: @_");
		# $self->OptimiseColumns(1);
		$_[1]->Skip(1);
	});

	## until Wx 2.9.1 and its wxFileSystemWatcher arrives, we use our own simple (pull) monitoring
	$self->{timer} = Wx::Timer->new();
	EVT_TIMER($self->{timer}, $self->{timer}, sub {
		my $richprop_dir = $self->{wrangler}->{fs}->richproperties($self->{current_dir}, ['Filesystem::Modified']);

		return if $self->{our_stash}->{rename}; # don't disturb ongoing renames

		if($richprop_dir->{'Filesystem::Modified'} != $self->{current_dir_mtime}){
			Wrangler::debug("Wrangler::Wx::FileBrowser: Timer pull_monitor: $self->{current_dir} $self->{current_dir_mtime} changed");
			$self->{current_dir_mtime} = $richprop_dir->{'Filesystem::Modified'};
			$self->RePopulate();
		}else{
			# Wrangler::debug("Wrangler::Wx::FileBrowser: Timer pull_monitor: $self->{current_dir} $self->{current_dir_mtime}");
		}
	});

	return $self;
}

sub Clear {
	my ($filebrowser) = @_;

	$filebrowser->Show( 0 );
	$filebrowser->DeleteAllItems();
	$filebrowser->Show( 1 );
}

sub OptimiseColumns {
	my $filebrowser = shift;
	my $force = shift;
	return if !$force && $filebrowser->{columns_optimised};

	## optimise column width
#	my $width = $filebrowser->GetViewRect()->width; # is completely off
	my $width = $filebrowser->GetClientSize()->width;
#	my $width_userdefined;
#	for(@{ $filebrowser->{columns} }){
#		$width_userdefined += $_->{width};
#	}
	my $width_half = int( ($width + 50) / 2); # +50 to compensate for $width being too small
	$filebrowser->SetColumnWidth (0, $width_half );

	my $colCnt = $filebrowser->GetColumnCount();
	Wrangler::debug("OptimiseColumns: width:$width; width_half:$width_half; colCnt:$colCnt");
	for(1 ..  $colCnt){
		$filebrowser->SetColumnWidth($_, int( $width_half / $colCnt ) );
	}
	$filebrowser->{columns_optimised} = 1;
}

## who should know about sorting, Wx, the vfs, or wrangler? Wx is only presentation,
## so 'No'; the vfs is like fuse or the raw fs: no idea of sorting; and as expected,
## it's wrangler who does the sorting, so this is a helper offered by wrangler that
## can handle richlists, and does sorting like people expect it in a file-listing
my $regex_numeric = qr/^\d+$/;
sub sort_richlist {
	my $filebrowser = shift;
	my $richlist = shift;

	my %config = %{ $filebrowser->{wrangler}->config() }; # fewer lookups

	## logic: 1. config, 2. default
	my %args = ( sort_on => 'Filesystem::Filename', sort_order => 'ASC' );
	if($config{'ui.filebrowser.sort'}){
		if(ref($config{'ui.filebrowser.sort'}) eq 'HASH'){
			if( my $ref = $config{'ui.filebrowser.sort'}->{ $filebrowser->{current_dir} } ){
				$args{sort_order} = $config{'ui.filebrowser.sort'}->{ $filebrowser->{current_dir} }->[0];
				$args{sort_on}	  = $config{'ui.filebrowser.sort'}->{ $filebrowser->{current_dir} }->[1];
			}
		}elsif(ref($config{'ui.filebrowser.sort'}) eq 'ARRAY'){
			$args{sort_order} = $config{'ui.filebrowser.sort'}->[0];
			$args{sort_on}	  = $config{'ui.filebrowser.sort'}->[1];
		}
		# sort_richlist is called very early, and this logic here, is also used
		# to kind-of init a "current sorting" notion, which is needed for how
		# on col click currently works/ to react correctly on first click
		$filebrowser->{sort_order} = $args{sort_order};
	}
	my ($sort_order,$sort_on) = ($args{sort_order},$args{sort_on});

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

	Wrangler::debug("FileBrowser::sort_richlist: sort_on:$sort_on, sort_order:$sort_order, data_type:$data_type");

	if($data_type eq 'numeric'){
		# numeric
		if($sort_order eq 'DESC'){
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
		if($sort_order eq 'DESC'){
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
	# Wrangler::debug("column_key: $_[0], $_[1]");
	return ${ $_[0]->{columns} }[ $_[1] ]->{value_from};
}

sub SetOurItemData {
	Wrangler::debug("SetOurItemData: warning: not enough arguments passed") unless @_ == 3;
	${ $_[0]->{ItemData} }[ $_[1] ] = $_[2];
}

sub GetOurItemData {
	Wrangler::debug("GetOurItemData: warning: not enough arguments passed") unless @_ == 2;
	Wrangler::debug("GetOurItemData: warning: item $_[1] is not defined!") unless defined(${ $_[0]->{ItemData} }[ $_[1] ]);
	return ${ $_[0]->{ItemData} }[ $_[1] ];
}

sub DeleteAllOurItemData {
	$_[0]->{ItemData} = [];
}

# a helper sub to get more in line with TreeListCtrl
sub GetSelections {
	return () unless $_[0]->GetSelectedItemCount(); # untested optimisation

	my @selections;
	my $currId = -1;
	for(;;){
		$currId = $_[0]->GetNextItem($currId, wxLIST_NEXT_ALL, wxLIST_STATE_SELECTED);
		if($currId == -1){
			last;
		}else{
			push(@selections, $currId);
		}
	}

	return wantarray ? @selections : \@selections;
}

sub GetSelections_as_richlist_items {
	my $selections = $_[0]->GetSelections();

	return wantarray ? () : [] unless ref($selections) && @$selections;

	for (@$selections){
		my $itemId = $_;
		my $richlist_item = $_[0]->GetOurItemData( $_[0]->GetItem($_)->GetData() ); # GetOurItemData returns the actual data, no ->GetData needed
		$_ = $richlist_item;	# $_ = { itemId => $_, richlist_item => $richlist_item };
		$_->{_itemId} = $_; # used to identify if selections are the same, in event _SELECTION_CHANGED
	}

	return wantarray ? @$selections : $selections;
}

sub GetSelections_as_FileDataObject {
	my $filebrowser = shift;

	## create and fill the FileDataObject with full file-path for each selected item
	my $fdo = Wx::FileDataObject->new();
	for my $currId ($filebrowser->GetSelections){
		my $richlist_item = $filebrowser->GetOurItemData( $filebrowser->GetItem($currId)->GetData() ); # GetOurItemData returns the actual data, no ->GetData needed
		# Wrangler::debug("- $richlist_item->{'Filesystem::Path'} ");
		$fdo->AddFile( $richlist_item->{'Filesystem::Path'} );
	}

	return $fdo;
}

sub GetSelections_as_CompositeDataObject {
	my $cdo = Wx::DataObjectComposite->new();
	$cdo->Add( $_[0]->GetSelections_as_FileDataObject() );

	return $cdo;
}

sub SelectAll {
	my $filebrowser = shift;

	my $cnt = $filebrowser->GetItemCount;
	for( 0 .. ($cnt - 1) ){
		if($_ == 0){
			next if $filebrowser->GetItemText($_) eq '..';
		}
		$filebrowser->{our_stash}->{ignore_selected} = 1; # resetted in EVT_ITEM_SELECTED
		$filebrowser->SetItemState( $_, wxLIST_STATE_SELECTED, wxLIST_STATE_SELECTED );
	}

	Wrangler::debug("SelectAll: emitting 'selection.changed' event");
	my $selections = $filebrowser->GetSelections_as_richlist_items();
	Wrangler::PubSub::publish('selection.changed', scalar(@$selections), $selections );
}

sub DeselectAll {
	my $filebrowser = shift;

	my $cnt = $filebrowser->GetItemCount;
	for( 0 .. ($cnt - 1) ){
		$filebrowser->SetItemState( $_, 0, wxLIST_STATE_SELECTED );
	}

	Wrangler::debug("DeselectAll: emitting 'selection.changed' event");
	Wrangler::PubSub::publish('selection.changed', 0 );
}

sub InvertSelections {
	my $filebrowser = shift;

	my $cnt = $filebrowser->GetItemCount;
	for( 0 .. ($cnt - 1) ){
		if($_ == 0){
			next if $filebrowser->GetItemText($_) eq '..';
		}

		my $state = $filebrowser->GetItemState( $_, wxLIST_STATE_SELECTED );

		if($state == wxLIST_STATE_SELECTED){
			$filebrowser->SetItemState( $_, 0, wxLIST_STATE_SELECTED );
		}else{
			$filebrowser->SetItemState( $_, wxLIST_STATE_SELECTED, wxLIST_STATE_SELECTED );
		}
	}

	my $selections = $filebrowser->GetSelections_as_richlist_items();
	Wrangler::PubSub::publish('selection.changed', scalar(@$selections), $selections );
}

sub SelectionMoveUp {
	my $filebrowser = shift;
	my $event = shift;

	Wrangler::debug('FileBrowser::SelectionMoveUp: ');

	if($filebrowser->GetSelectedItemCount() == 0){
		# jump into list on move up (on win32 it would just circle the item with dotted line/no real select)
		$filebrowser->SetItemState( 0, wxLIST_STATE_SELECTED, wxLIST_STATE_SELECTED );
	}else{
		# get position and move down
		my $currSel = $filebrowser->GetNextItem(-1, wxLIST_NEXT_ALL, wxLIST_STATE_SELECTED);
		my $nextSel = ($currSel - 1);
		if($nextSel >= 0){ # limit top
			$filebrowser->SetItemState($currSel, 0, wxLIST_STATE_SELECTED ) if !$event->ShiftDown();
			$filebrowser->SetItemState(
				$nextSel,
				wxLIST_STATE_SELECTED, wxLIST_STATE_SELECTED
			) unless ($event->ShiftDown() && $filebrowser->GetItemText($nextSel) eq '..');
			$filebrowser->EnsureVisible($nextSel);
		}
	}

	my $selections = $filebrowser->GetSelections_as_richlist_items();
	Wrangler::PubSub::publish('selection.changed', scalar(@$selections), $selections );
}

sub SelectionMoveDown {
	my $filebrowser = shift;
	my $event = shift;

	Wrangler::debug('FileBrowser::SelectionMoveDown: ');

	if($filebrowser->GetSelectedItemCount() == 0){
		# jump into list on move down
		$filebrowser->SetItemState( 0, wxLIST_STATE_SELECTED, wxLIST_STATE_SELECTED );
	}else{
		# get position and move down
		my $currSel = $filebrowser->GetNextItem(-1, wxLIST_NEXT_ALL, wxLIST_STATE_SELECTED);
		my $nextSel = $event->ShiftDown() ? ($currSel + $filebrowser->GetSelectedItemCount() ) : ($currSel + 1);
		if($nextSel <= ($filebrowser->GetItemCount() - 1)){ # limit bottom
			$filebrowser->SetItemState($currSel, 0, wxLIST_STATE_SELECTED ) if !$event->ShiftDown();
			$filebrowser->SetItemState(
				$nextSel,
				wxLIST_STATE_SELECTED, wxLIST_STATE_SELECTED
			);
			$filebrowser->EnsureVisible($nextSel);
		}
	}

	my $selections = $filebrowser->GetSelections_as_richlist_items();
	Wrangler::PubSub::publish('selection.changed', scalar(@$selections), $selections );
}

sub Columns {
	my $filebrowser = shift;
	my $config = $filebrowser->{wrangler}->config();
	my $columns = $config->{'ui.filebrowser.columns'};
	$filebrowser->{columns} = $columns;

	## now add the columns
	$filebrowser->{columns_widths_index} = [0];
	my $accumulated_width;
	for (0 .. $#{ $columns }){
		my $align = $columns->[$_]->{text_align} eq 'right' ? wxLIST_FORMAT_RIGHT : wxLIST_FORMAT_LEFT;
		$filebrowser->InsertColumn( $_,  ${ $columns }[$_]->{label}, $align, $columns->[$_]->{width} );

		## update our hit->col index, used in GetColumn()
		$accumulated_width += ${ $columns }[$_]->{width};
		push(@{ $filebrowser->{columns_widths_index} }, $accumulated_width);

		## tell central $wishlist what we are displaying
		$Wrangler::wishlist->{ $columns->[$_]->{value_from} } = 1;
		$Wrangler::wishlist->{ 'MIME' } = 1 if $config->{'ui.filebrowser.highlight_media'};
	}
}

sub GetColumn {
	my $filebrowser = shift;
	my $event = shift;

	my $click_offset = $event->GetPoint()->x();
	my $offset_per_scroll_tick = 15; # educated-guess, until we find the Wx method for that, or something like GetLogicalPosition()
	my $offset = ($filebrowser->GetScrollPos(wxHORIZONTAL) * $offset_per_scroll_tick) + $click_offset;
	# Wrangler::debug("FileBrowser::GetColumn: $click_offset + ".$filebrowser->GetScrollPos(wxHORIZONTAL)." * $offset_per_scroll_tick");
	my $hit_col = 0;
	if(@{ $filebrowser->{columns_widths_index} }){
		for(0 .. $#{ $filebrowser->{columns_widths_index} }){
			last if $filebrowser->{columns_widths_index}->[$_] > $offset;
			$hit_col = $_;
		}
	}

	# Wrangler::debug('FileBrowser::GetColumn: '.$hit_col.' value_from:'.$filebrowser->{columns}->[$hit_col]->{value_from});
	return wantarray ? ($hit_col,$filebrowser->{columns}->[$hit_col]->{value_from}) : $hit_col;
}

# expects only a path, as ListCtrl has no idea about hierarchy;
# optional args can override default behaviour
sub Populate {
	my $filebrowser = shift;
	my $richlist = shift || [];
	my %config = %{ $filebrowser->{wrangler}->config() }; # fewer lookups
	my %args = (
		include_updir	=> $config{'ui.filebrowser.include_updir'} // 1,	# /
		zebra_striping	=> $config{'ui.filebrowser.zebra_striping'} // 1,	# /
		include_hidden	=> $config{'ui.filebrowser.include_hidden'} // 0,	# /
		highlight_media	=> $config{'ui.filebrowser.highlight_media'} // 1,	# /
		highlight_colour_audio	=> $config{'ui.filebrowser.highlight_colour.audio'} // [220, 220, 240],	# /
		highlight_colour_image	=> $config{'ui.filebrowser.highlight_colour.image'} // [220, 240, 220],	# /
		highlight_colour_video	=> $config{'ui.filebrowser.highlight_colour.video'} // [240, 220, 220],	# /
	#	colours			=> $config{'colours'},
	#	colour_labeling		=> $config{'ui.filebrowser.colour_labeling'} // 1,	# /
		@_
	);

	## set cursor to 'busy', reverts back when local var gets out of scope
	my $busy = new Wx::BusyCursor;

	$filebrowser->Show( 0 );
	$filebrowser->DeleteAllItems();
	$filebrowser->DeleteAllOurItemData();

	my $rowCnt = 0;
	for(@$richlist){
		next if $_->{'Filesystem::Filename'} eq '.';
		next if $_->{'Filesystem::Filename'} eq '..' && !$args{include_updir};
		next if $_->{'Filesystem::Hidden'} && !$args{include_hidden};

		# map filesystem info to icons (as icons are purely presentational)
		my $type = $_->{'Filesystem::Type'} eq 'Directory' ? ($_->{'Filesystem::Filename'} eq '..' ? 'go_up' : 'folder') : 'file';
		if($type eq 'file'){
		 if(my $mediaType = $_->{'MIME::mediaType'}){
			if($mediaType eq 'image'){
				$type = 'generic_image';
			}elsif($mediaType eq 'video'){
				$type = 'generic_video';
			}elsif($mediaType eq 'audio'){
				$type = 'generic_audio';
			}
		 }
		}

		# build row
		my $itemId;
		for my $colCnt ( 0 .. $filebrowser->column_count() ){
			my $column_key = $filebrowser->column_key($colCnt);	# less lookups, easier on the eyes

			# see if the value is already in the richlist, else ask for it (should never happen; unless we fail in telling richlist what to get)
			my $column_value = defined($_->{$column_key}) ? $_->{$column_key} : ''; # '' was $filebrowser->{wrangler}->{fs}->ask_vfs()

			# see if there's a renderer for this value-type
			my $renderer = $filebrowser->{wrangler}->{fs}->renderer($column_key);
			if($renderer){
				$column_value = $renderer->($_->{ $column_key });
			}

			# use proper insertion method
			if($colCnt == 0){
				# InsertItem returns a numeric $itemId
				$itemId = $filebrowser->InsertImageStringItem( $rowCnt,	$column_value, $filebrowser->{images}->{ $type } );
			}else{
				$filebrowser->SetItem( $itemId, $colCnt, $column_value );
			}
		}

		# add row data:
		# as it seems, ListCtrl can hold only numeric data in ItemData,
		# so we do our own "$itemId (zerobase, numeric) to data" lookup
		$filebrowser->SetOurItemData($itemId, $_); # we store a ref to our richlist_item
		# further: might be a bug in Wx, or we're not doing it right, but:
		# it's not possible to get the right numeric id of a list item via $event->GetItem->GetId, so we set
		# it as (numeric) data look for string "GetItem()->GetData()" to find code that relies on this workaround
		$filebrowser->SetItemData($itemId, $itemId);

		# MIME-mediaType highlighting
		if($args{highlight_media}){
		 if(my $mediaType = $_->{'MIME::mediaType'}){
			if($mediaType eq 'image'){
				$filebrowser->SetItemBackgroundColour($itemId, Wx::Colour->new(@{$args{highlight_colour_image}}));	# Image, light green
			}elsif($mediaType eq 'video'){
				$filebrowser->SetItemBackgroundColour($itemId, Wx::Colour->new(@{$args{highlight_colour_video}}));	# Video, light red
			}elsif($mediaType eq 'audio'){
				$filebrowser->SetItemBackgroundColour($itemId, Wx::Colour->new(@{$args{highlight_colour_audio}}));	# Audio, light green
			}
		 }
		}

		## plugin directory_listing per-item manipulations
		if( my $plugins_ref = Wrangler::PluginManager::plugins('directory_listing') ){
			for my $plugin (@$plugins_ref){
				$plugin->directory_listing($filebrowser,$itemId,$_);
			}
		}

		# zebra-striping
		if($args{zebra_striping} && ($rowCnt % 2)){
			my @colour;
			my $colour = $filebrowser->GetItem($itemId)->GetBackgroundColour();
			@colour = ($colour->Red(), $colour->Green(), $colour->Blue());
			for(@colour){ $_ -= 7; }
			$filebrowser->SetItemBackgroundColour($itemId, Wx::Colour->new(@colour));
		}

		$rowCnt++;
	}

	$filebrowser->Show( 1 );
	$filebrowser->SetFocus();
}

sub RePopulate {
	my $filebrowser = shift;

	## remember current selection
	# How could this be improved? Currently it uses paths as basis - which might change! In many cases, that's why we do a refresh in the first place...
	my %selection;
	for( $filebrowser->GetSelections() ){
		my $richlist_item = $filebrowser->GetOurItemData( $filebrowser->GetItem($_)->GetData() ); # GetOurItemData returns the actual data, no ->GetData needed
		$selection{ $richlist_item->{'Filesystem::Path'} } = 1;
	}

	## remember ScrollPosition
	my $scroll_pos_vertical = $filebrowser->GetScrollPos(wxVERTICAL);
	my $scroll_pos_horizontal = $filebrowser->GetScrollPos(wxHORIZONTAL);

	## re-populate/update/refresh listing
	my $richlist = $filebrowser->{wrangler}->{fs}->richlist( $filebrowser->{current_dir}, Wrangler::wishlist() );
	$filebrowser->sort_richlist($richlist);
	$filebrowser->Populate($richlist);

	## recreate selection
	foreach ( 0 .. $filebrowser->GetItemCount - 1 ) {
		my $richlist_item = $filebrowser->GetOurItemData( $filebrowser->GetItem($_)->GetData() ); # GetOurItemData returns the actual data, no ->GetData needed
		if( exists($selection{ $richlist_item->{'Filesystem::Path'} }) ){
			$filebrowser->SetItemState( $_, wxLIST_STATE_SELECTED, wxLIST_STATE_SELECTED );
		}
	}

	## recreate ScrollPos (does not work, at least on nix + Wx 2.8.12, native-ctrl -> feature http://trac.wxwidgets.org/ticket/10267)
	$filebrowser->SetScrollPos(wxVERTICAL, $scroll_pos_vertical);
	$filebrowser->SetScrollPos(wxHORIZONTAL, $scroll_pos_horizontal, 'redraw');
}

sub ChangeDirectory {
	my ($filebrowser, $path) = @_;

	Wrangler::PubSub::publish('selection.changed', 0 );

	(my $richlist,$filebrowser->{current_dir}) = $filebrowser->{wrangler}->{fs}->richlist( $path, Wrangler::wishlist() );
	Wrangler::debug("FileBrowser::ChangeDirectory: richlist() returned an error listing!") if ref($richlist) eq 'error';
	$filebrowser->sort_richlist($richlist);
	$filebrowser->Populate($richlist);

	my $richprop_dir = $filebrowser->{wrangler}->{fs}->richproperties($filebrowser->{current_dir}, ['Filesystem::Modified']);
	$filebrowser->{current_dir_mtime} = $richprop_dir->{'Filesystem::Modified'};
	$filebrowser->{timer}->Start($filebrowser->{wrangler}->config()->{'ui.filebrowser.pull_monitor_timeout'} || 7000, wxTIMER_CONTINUOUS); # schedule simple pull monitoring
}

sub Mkdir {
	my $filebrowser = shift;

	## find last dir in listing
	my @selections;
	my $currId = 0;
	for(;;){
		$currId = $filebrowser->GetNextItem($currId, wxLIST_NEXT_ALL, wxLIST_STATE_DONTCARE);
		if($currId == -1){
			last;
		}else{
			push(@selections, $currId);

			my $richlist_item = $filebrowser->GetOurItemData( $filebrowser->GetItem($currId)->GetData() );
			my $path = $richlist_item->{'Filesystem::Path'};
			if($richlist_item->{'Filesystem::Type'} ne 'Directory'){
				last;
			}

		}
	}

	my $lastId = $selections[-1];
	# Wrangler::debug("Last dir in listing is $lastId");

	## insert a placeholder item below dirs
	my $itemId = $filebrowser->InsertImageStringItem( $lastId,
		'New folder',
		$filebrowser->{images}->{ 'folder' }
	);
	$filebrowser->SetOurItemData($lastId, { ref_to_ => 'incomplete richlist type data!' });
	$filebrowser->SetItemData($lastId, $lastId);

	# make sure the listing is scrolled, so the user can see the new item, and start label edit
	$filebrowser->EnsureVisible($itemId);
	$filebrowser->EditLabel($itemId);

	# this is all we can do here, the directory is actually created in OnEndLabelEdit()
	$filebrowser->{our_stash} = { mkdir => $itemId };
}

sub Mknod {
	my $filebrowser = shift;

	## find last dir in listing
	my @selections;
	my $currId = 0;
	for(;;){
		$currId = $filebrowser->GetNextItem($currId, wxLIST_NEXT_ALL, wxLIST_STATE_DONTCARE);
		if($currId == -1){
			last;
		}else{
			push(@selections, $currId);

			my $richlist_item = $filebrowser->GetOurItemData( $filebrowser->GetItem($currId)->GetData() );
			my $path = $richlist_item->{'Filesystem::Path'};
			if($richlist_item->{'Filesystem::Type'} ne 'Directory'){
				last;
			}

		}
	}

	my $lastId = $selections[-1];
	# Wrangler::debug("Last dir in listing is $lastId");

	## insert a placeholder item below dirs
	my $itemId = $filebrowser->InsertImageStringItem( $lastId,
		'New file',
		$filebrowser->{images}->{ 'file' }
	);
	$filebrowser->SetOurItemData($lastId, { ref_to_ => 'richlist type data' });
	$filebrowser->SetItemData($lastId, $lastId);

	# make sure the listing is scrolled, so the user can see the new item, and start label edit
	$filebrowser->EnsureVisible($itemId);
	$filebrowser->EditLabel($itemId);

	# this is all we can do here, the directory is actually created in OnEndLabelEdit()
	$filebrowser->{our_stash} = { mknod => $itemId };
}

sub Rename {
	my $filebrowser = shift;

	my $w = $filebrowser->{wrangler};

	my @selections = $filebrowser->GetSelections(); # docs: wxPerl note: In wxPerl this method takes no parameters and returns a list of Wx::TreeItemIds. 
	my $selCnt = @selections;
	Wrangler::debug("FileBrowser: Rename: $selCnt items ");

	return if $selCnt == 0;

	for(@selections){
		push(@{ $filebrowser->{our_stash}->{rename} }, {
			id	=> $_,
			file	=> $filebrowser->GetItemText($_),
			richlist_item => $filebrowser->GetOurItemData( $filebrowser->GetItem($_)->GetData() ), # GetOurItemData returns the actual data, no ->GetData needed
		});
	}

	if($selCnt == 1){
		# the actual rename is done in OnEndEditLabel()
		# (use the LabelEdit editor to handle the rename)
		if( $filebrowser->{columns}->[0]->{value_from} eq 'Filesystem::Filename' ){
			$filebrowser->EditLabel( $selections[0] );
		# this case handles when the Filename column isn't the first column
		}else{
			## oldpath
			my $oldpath = ${ $filebrowser->{our_stash}->{rename} }[0]->{richlist_item}->{'Filesystem::Path'};
			$filebrowser->{our_stash} = undef;

			my $oldname = $filebrowser->{wrangler}->{fs}->fileparse($oldpath);
			my $dialog = Wx::TextEntryDialog->new( $filebrowser, "Rename", "Rename", $oldname );

			unless( $dialog->ShowModal == wxID_CANCEL ){
				## newpath
				my $newpath = $dialog->GetValue();

				$newpath = $filebrowser->{wrangler}->{fs}->catfile( $filebrowser->{current_dir}, $newpath);

				# check if label has been edited
				return if $oldpath eq $newpath;

				## do the actual rename on storage
				my $ok = $filebrowser->{wrangler}->{fs}->rename($oldpath, $newpath);

				if($ok){
					$filebrowser->RePopulate();
				}else{
					my $dialog = Wx::MessageDialog->new($filebrowser, "Error renaming (Rename, single) \"$oldpath\" to \"$newpath\": $!", "Renaming error", wxOK );
					$dialog->ShowModal();
				}
			}

			$dialog->Destroy();
		}
	}elsif($selCnt > 1){
		# use a more sophisticated dialogue for multi-renames
		require Wrangler::Wx::Dialog::MultiRename;
		my $dialog = Wrangler::Wx::Dialog::MultiRename->new($filebrowser, $filebrowser->{our_stash}->{rename});

		if($dialog->ShowModal() == wxID_OK){
			if( $dialog->{pre}->IsModified || $dialog->{ins}->IsModified ){
				Wrangler::debug("Prepend/append-rename was used ");

				my $pre = $dialog->{pre}->GetValue();
				my $ins = $dialog->{ins}->GetValue();

				my @errors;
				for(@{ $filebrowser->{our_stash}->{rename} }){
					my $oldpath = $_->{richlist_item}->{'Filesystem::Path'};

					my ($file, $dirs, $suffix) = $filebrowser->{wrangler}->{fs}->fileparse($oldpath, qr/\.[^.]*/);

					my $newpath = $filebrowser->{wrangler}->{fs}->catfile( $filebrowser->{current_dir}, $pre.$file.$ins.$suffix);
					Wrangler::debug("Rename: multi: $oldpath -> $newpath");
					next if $oldpath eq $newpath;

					## do the actual rename
					my $ok = $filebrowser->{wrangler}->{fs}->rename($oldpath, $newpath);
					push(@errors, "Error renaming (Rename, multiple) \"$oldpath\" to \"$newpath\": $!\n") unless $ok;
				}
				if(@errors){
					my $dialog = Wx::MessageDialog->new($filebrowser, "@errors", "Renaming error", wxOK );
					$dialog->ShowModal();
				}else{
					$filebrowser->RePopulate();
				}
			}elsif( $dialog->{pattern} && $dialog->{pattern}->IsModified ){
				Wrangler::debug("Pattern-rename was used ");

				my $multi = $dialog->{multi}->GetValue();

				my $oldlen = $dialog->{length};
				my $newlen = length($multi);
				Wrangler::debug("MULTI: $multi OLDLEN: $oldlen NEWLEN:$newlen");

				# todo
			}
		}else{
			Wrangler::debug("Multiple rename CANCELd ");
		}

		# clear ourclipboard
		undef($filebrowser->{our_stash});
	}
}

sub ChangeProperty {
	my $filebrowser = shift;
	my $metakey = shift;

	my $w = $filebrowser->{wrangler};

	my $selections = $filebrowser->GetSelections_as_richlist_items();
	my $selCnt = @$selections;
	Wrangler::debug("FileBrowser: ChangeProperty: $selCnt items ");

	return unless $selCnt;

	my $dialog = Wx::TextEntryDialog->new($filebrowser, "New value for \"$metakey\":", "Change value of \"$metakey\"", $selections->[0]->{$metakey} );
	return unless $dialog->ShowModal() == wxID_OK;

	my $new_value = $dialog->GetValue();
	$dialog->Destroy();

	if($selCnt > 2){
		my $text = "Are you sure you want to change the metadata value on $selCnt items?";
		my $dialog = Wx::MessageDialog->new($filebrowser, "$text\nThis can't be undone!", $text, wxYES_NO | wxNO_DEFAULT | wxICON_EXCLAMATION );
		unless($dialog->ShowModal() == wxID_YES){
			Wrangler::debug("ChangeProperty canceled");
			return;
		}
	}

	my @errors;
	for(@$selections){
		Wrangler::debug("ChangeProperty: set_property($_->{'Filesystem::Path'}, $metakey, $new_value)");
		my $ok = $filebrowser->{wrangler}->{fs}->set_property($_->{'Filesystem::Path'}, $metakey, $new_value);
		push(@errors, "Error on set_property($_->{'Filesystem::Path'}, $metakey, $new_value)") unless $ok;
	}

	$filebrowser->RePopulate();
}

sub Delete {
	my $filebrowser = shift;
	my $really = shift || 0;	# really means we don't move to Trash

	my $w = $filebrowser->{wrangler};

	my @selections = $filebrowser->GetSelections(); # docs: wxPerl note: In wxPerl this method takes no parameters and returns a list of Wx::TreeItemIds. 
	my $selCnt = @selections;
	Wrangler::debug("FileBrowser: Delete(really=".$really."): $selCnt items ");
	return if $selCnt == 0;

	if($really && $filebrowser->{wrangler}->config()->{'ui.filebrowser.confirm.delete'}){
		# confirm dialog
		my $text = "Are you sure to permanently delete the selected $selCnt item(s)?"; # message grows/stretches the dialog horizontally, in caption/title it doesn't, so we use it twice
		my $dialog = Wx::MessageDialog->new($filebrowser, "$text\nThis can't be undone!", $text, wxYES_NO | wxNO_DEFAULT | wxICON_EXCLAMATION );
		unless($dialog->ShowModal() == wxID_YES){
			Wrangler::debug("Delete canceled");
			return;
		}
	}

	# create a progress dialog
	my $pd = Wx::ProgressDialog->new("Deleting...", "Deleting...", $selCnt, $filebrowser, wxPD_AUTO_HIDE | wxPD_APP_MODAL | wxPD_ELAPSED_TIME );

	# remember above/below (whatever applies) (getNextItem + geometry: _ABOVE/_BELOW does not work )
	my $prev_id = $selections[0] > 0 ? $selections[0] - 1 : undef;
	# Wrangler::debug(" prev item above $selections[0] is $prev_id ");
	my $next_id = $selections[-1] < ($filebrowser->GetItemCount() - 1) ? $selections[-1] + 1 : undef;
	# Wrangler::debug(" next item below $selections[-1] (with ".$filebrowser->GetItemCount()." items) is $next_id ");
	$prev_id++ if $next_id;

	my $cnt = 1;
	my @errors;
	for my $currId (reverse @selections){ # http://wiki.wxwidgets.org/WxListCtrl#Deleting_Selected_Rows
		my $richlist_item = $filebrowser->GetOurItemData( $filebrowser->GetItem($currId)->GetData() ); # GetOurItemData returns the actual data, no ->GetData needed

		# caveat: in our current implementation, right after a listitem is created via mkdir/mknod, its
		# richlist_item data is incomplete until the next (Re)populate - this results in an empty $path here
		# and sending an empty string to delete() is probably a bad idea
		unless($richlist_item->{'Filesystem::Path'} && $richlist_item->{'Filesystem::Path'} ne ''){
			Wrangler::debug("FileBrowser: currId:$currId is an incomplete item! delete skipped!");

			$pd->Update($cnt);
			$cnt++;
			next;
		}

		my $path = $richlist_item->{'Filesystem::Path'};

		## just to be sure we don't del the 'up-dir'!
		## system's "rm" denies deleting it but rmdir+recursive (=rmtree), which we use here, interprets it as a valid path and deletes it!
		if($path =~ /\.\.$/){
			Wrangler::debug("FileBrowser: delete ($cnt of $selCnt): currId:$currId, path:$path -- skipped: is 'up-dir'! ");
		}else{
			if($really){
				if( $richlist_item->{'Filesystem::Type'} eq 'Directory' ){
					Wrangler::debug("FileBrowser: rmdir('recursive') ($cnt of $selCnt): currId:$currId, path:$path");

					## delete dir
					my $ok = $w->{fs}->rmdir($path,'recursive');
					push(@errors, "Error removing dir \"$path\": $!") unless $ok;

					$filebrowser->DeleteItem($currId) if $ok;
				}else{
					Wrangler::debug("FileBrowser: delete ($cnt of $selCnt): currId:$currId, path:$path");

					## delete file
					my $ok = $w->{fs}->delete($path);
					push(@errors, "Error really-deleting file \"$path\": $!") unless $ok;

					$filebrowser->DeleteItem($currId) if $ok;
				}
			}else{
					Wrangler::debug("FileBrowser: trash ($cnt of $selCnt): currId:$currId, path:$path");
					my $ok = $w->{fs}->trash($path);
					push(@errors, "Error trashing file \"$path\": $!") unless $ok;

					$filebrowser->DeleteItem($currId) if $ok;
			}
		}

		$pd->Update($cnt);

		$cnt++;
	}

	if(@errors){
		my $dialog = Wx::MessageDialog->new($filebrowser, "Error deleting ".scalar(@errors) ." item(s):\n".join("\n",@errors), "Delete error", wxOK );
		$dialog->ShowModal();
	}else{
	#	$filebrowser->RePopulate();
	}

	# select the "next" item after the delete(s)
	$filebrowser->SetItemState( $prev_id, wxLIST_STATE_SELECTED, wxLIST_STATE_SELECTED );

	# let's cheat here: we modified the listing, removed element(s), and the
	# listing should reflect the current state, so don't annoy the user with
	# another repopulate; todo: remove this once we change monitoring, or when
	# RePopulate() becomes clever enough to update only dirty items
	$filebrowser->{current_dir_mtime} = time();

	$filebrowser->SetFocus();
}

sub OnEndLabelEdit {
	my( $filebrowser, $event ) = @_;

	if( $filebrowser->{our_stash}->{mkdir} ){
		## mkdir path
		my $path = $event->GetItem->GetText;

		$path = $filebrowser->{wrangler}->{fs}->catfile( $filebrowser->{current_dir}, $path );
		my $path_amended;
		if( $filebrowser->{wrangler}->{fs}->test('e', $path) ){
			for(1..10){
				Wrangler::debug("FileBrowser::OnEndLabelEdit: mkdir path $path exists!");
				$path .= '_another';
				$path_amended = 1;
				last if ! $filebrowser->{wrangler}->{fs}->test('e', $path);
			}
		}

		Wrangler::debug("FileBrowser::OnEndLabelEdit: mkdir: $path");
		my $ok = $filebrowser->{wrangler}->{fs}->mkdir($path);

		$filebrowser->{our_stash} = undef;

		if($ok){
			$filebrowser->RePopulate() if $path_amended;
		}else{
			my $dialog = Wx::MessageDialog->new($filebrowser, "Error making directory \"$path\": $!", "Mkdir error", wxOK );
			$dialog->ShowModal();
			$event->Veto();
			# caveat: here, richlist_item data of this newly created item is incomplete! which may lead to errors
			# in routines relying on that data - probably, we should do a Repopulate after all item creations
		}
	}elsif( $filebrowser->{our_stash}->{mknod} ){
		## mknod path
		my $path = $event->GetItem->GetText;

		$path = $filebrowser->{wrangler}->{fs}->catfile( $filebrowser->{current_dir}, $path );
		my $path_amended;
		if( $filebrowser->{wrangler}->{fs}->test('e', $path) ){
			for(1..10){
				Wrangler::debug("FileBrowser::OnEndLabelEdit: mknod path $path exists!");
				$path .= '_another';
				$path_amended = 1;
				last if ! $filebrowser->{wrangler}->{fs}->test('e', $path);
			}
		}

		Wrangler::debug("FileBrowser::OnEndLabelEdit: mknod: $path");
		my $ok = $filebrowser->{wrangler}->{fs}->mknod($path);

		$filebrowser->{our_stash} = undef;

		if($ok){
			$filebrowser->RePopulate() if $path_amended;
		}else{
			my $dialog = Wx::MessageDialog->new($filebrowser, "Error making node \"$path\": $!", "Mknod error", wxOK );
			$dialog->ShowModal();
			$event->Veto();
			# caveat: here, richlist_item data of this newly created item is incomplete! which may lead to errors
			# in routines relying on that data - probably, we should do a Repopulate after all item creations
		}
	}elsif($filebrowser->{our_stash}->{rename}){
		## oldpath
		my $oldpath = $filebrowser->{our_stash}->{rename}->[0]->{richlist_item}->{'Filesystem::Path'};
		$filebrowser->{our_stash} = undef;

		## newpath
		my $newpath = $event->GetItem->GetText;

		$newpath = $filebrowser->{wrangler}->{fs}->catfile( $filebrowser->{current_dir}, $newpath);

		# check if label has been edited
		return if $oldpath eq $newpath;

		## do the actual rename on storage
		my $ok = $filebrowser->{wrangler}->{fs}->rename($oldpath, $newpath);

		if($ok){
			# labelEdits already changed the displayed value
			# no: $filebrowser->RePopulate(); needed
		}else{
			my $dialog = Wx::MessageDialog->new($filebrowser, "Error renaming (OnEndLabelEdit) \"$oldpath\" to \"$newpath\": $!", "Renaming error", wxOK );
			$dialog->ShowModal();
			$event->Veto();
			# caveat: here, richlist_item data of this newly created item is incomplete! which may lead to errors
			# in routines relying on that data - probably, we should do a Repopulate after all item creations
		}

		Wrangler::debug("FileBrowser::OnEndLabelEdit: rename($oldpath, $newpath): $ok $!");

		# let's cheat here: we modified the listing, removed element(s), and the
		# listing should reflect the current state, so don't annoy the user with
		# another repopulate; todo: remove this once we change monitoring, or when
		# RePopulate() becomes clever enough to update only dirty items
		$filebrowser->{current_dir_mtime} = time();
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

	if( $richlist_item->{'Filesystem::Filename'} eq '..' && $richlist_item->{'Filesystem::Type'} =~ /^Directory$|^Drive$/ ){
		my $parent = $filebrowser->{wrangler}->{fs}->parent($richlist_item->{'Filesystem::Path'});

		Wrangler::debug(" change directory: updir/parent: $parent");

		# emit appropriate event
		Wrangler::PubSub::publish('dir.activated', $parent);
	}elsif( $richlist_item->{'Filesystem::Type'} =~ /^Directory$|^Drive$/ ){
		Wrangler::debug(" change directory: $richlist_item->{'Filesystem::Path'}");

		# emit appropriate event
		Wrangler::PubSub::publish('dir.activated', $richlist_item->{'Filesystem::Path'});
	}else{
		# emit appropriate event
		Wrangler::PubSub::publish('file.activated', $path, $richlist_item);
	}
}

sub Cut {
	my $filebrowser = shift;

	$filebrowser->{our_stash} = { cut => 1 };

	wxTheClipboard->Open();
	wxTheClipboard->SetData( $filebrowser->GetSelections_as_FileDataObject() );
	wxTheClipboard->Close();
}

sub Copy {
	my $filebrowser = shift;

	delete($filebrowser->{our_stash}->{cut}); # invalidate any remaining 'cut's

	wxTheClipboard->Open();
	wxTheClipboard->SetData( $filebrowser->GetSelections_as_FileDataObject() );
	wxTheClipboard->Close();
}

sub Paste {
	my $filebrowser = shift;

	wxTheClipboard->Open();
	my $fdo = Wx::FileDataObject->new();
	my $ok = wxTheClipboard->GetData($fdo);
	wxTheClipboard->Close();

	Wrangler::debug("FileBrowser::Paste: ok:$ok");

#	my $focus = Wx::Window::FindFocus();
#	if($focus && ref($focus) ne 'Wrangler::Wx::FileBrowser'){
#		Wrangler::debug(" FOCUS is not on $focus (caller:".caller().")");
#		return;
#	}

	unless($ok){
		my $dialog = Wx::MessageDialog->new($filebrowser, "The Clipboard doesn't hold files to paste.", "Paste", wxOK );
		$dialog->ShowModal();
		return;
	}

	# create a progress dialog
	my $pd = Wx::ProgressDialog->new("File operation in progress...", "File operation...", 1, $filebrowser, wxPD_AUTO_HIDE | wxPD_APP_MODAL | wxPD_REMAINING_TIME );

	my @errors;
	for( $fdo->GetFilenames() ){
		my $filepath = $_;

		next if $filepath =~ /\.\.$/; # don't move/copy the up-dir!! todo: prevent that in UI

		my ($name,$path) = $filebrowser->{wrangler}->{fs}->fileparse($filepath);
		my $newpath = $filebrowser->{wrangler}->{fs}->catfile($filebrowser->{current_dir}, $name);
		if($filebrowser->{our_stash}->{cut}){
			# figure out new name: append "_moved"
			if( $filebrowser->{wrangler}->{fs}->test('e', $newpath) ){
				for(1..10){
					Wrangler::debug(" paste: cut/rename/move: newpath $newpath exists!");
					$newpath .= '_moved';
					last if ! $filebrowser->{wrangler}->{fs}->test('e', $newpath);
				}
			}

			Wrangler::debug(" paste: cut/rename/move: $filepath => $newpath");
			$pd->Pulse("Moving $filepath");

			my $richproperties = $filebrowser->{wrangler}->{fs}->richproperties($filepath, ['Extended Attributes']);

			my $ok = $filebrowser->{wrangler}->{fs}->move($filepath, $newpath);
			unless($ok){
				Wrangler::debug("Error on paste: cut/rename/move: $! ");
				push(@errors, "Error on cut:$filepath -> paste:$newpath: $!");
				next;
			}

			## since we use system 'mv' in move()
			# Preserving xattr on rename/move is not user-settable, as we compensate for "moves across fs boundaries" here,
			# by always using move() instead of rename(). .. All that is mostly opaque to users. A user expects a dwim
			# move/mv, and the system command usually *does* preserve xattr
		}else{
			# figure out new name: append "_copy"
			if( $filebrowser->{wrangler}->{fs}->test('e', $newpath) ){
				for(1..10){
					Wrangler::debug(" paste: copy/insert: newpath $newpath exists!");
					$newpath .= '_copy';
					last if ! $filebrowser->{wrangler}->{fs}->test('e', $newpath);
				}
			}

			Wrangler::debug(" paste: copy/insert: $filepath => $newpath");
			$pd->Pulse("Copying $filepath");

			my $ok = $filebrowser->{wrangler}->{fs}->copy($filepath, $newpath);
			unless($ok){
				Wrangler::debug("Error on paste: cut/rename/move: $! ");
				push(@errors, "Error on copy:$filepath -> paste:$newpath: $!");
				next;
			}

			if($filebrowser->{wrangler}->config()->{'ui.filebrowser.copy.preserve_xattribs'}){
				Wrangler::debug(" preserving xattribs");
				my $richproperties = $filebrowser->{wrangler}->{fs}->richproperties($filepath, ['Extended Attributes']);
				for my $key (keys %$richproperties ){
					# Wrangler::debug(" - $key");
					$filebrowser->{wrangler}->{fs}->set_property($newpath, $key, $richproperties->{$key}) if $key =~ /^Extended Attributes::/;
				}
			}
		}
	}

	$pd->Destroy();

	if(@errors){
		my $dialog = Wx::MessageDialog->new($filebrowser, "Failed to paste ".scalar(@errors) ." item(s):\n".join("\n",@errors), "Paste error", wxOK );
		$dialog->ShowModal();
	}else{
		delete($filebrowser->{our_stash}->{cut});

		$filebrowser->RePopulate();
	}
}

sub PasteSymlinks {
	my $filebrowser = shift;

	wxTheClipboard->Open();
	my $fdo = Wx::FileDataObject->new();
	my $ok = wxTheClipboard->GetData($fdo);
	wxTheClipboard->Close();

	Wrangler::debug("FileBrowser::PasteSymlinks: ok:$ok");

	unless($ok){
		my $dialog = Wx::MessageDialog->new($filebrowser, "The Clipboard doesn't hold files to paste as symlinks.", "Paste ...as symlinks", wxOK );
		$dialog->ShowModal();
		return;
	}

	for( $fdo->GetFilenames() ){
		my $filepath = $_;

		next if $filepath =~ /\.\.$/; # don't handle the up-dir!! todo: prevent that in UI

		my ($name,$path) = $filebrowser->{wrangler}->{fs}->fileparse($filepath);
		my $newpath = $filebrowser->{wrangler}->{fs}->catfile($filebrowser->{current_dir}, $name);

		# figure out new name: append "_copy"
		if( $filebrowser->{wrangler}->{fs}->test('e', $newpath) ){
			for(1..10){
				Wrangler::debug(" paste: copy/insert: newpath $newpath exists!");
				$newpath .= '_copy';
				last if ! $filebrowser->{wrangler}->{fs}->test('e', $newpath);
			}
		}

		Wrangler::debug(" paste as symlink: $filepath -> $newpath");

		my $ok = $filebrowser->{wrangler}->{fs}->symlink($filepath, $newpath);
		Wrangler::debug("Error on paste as symlinks: $! ") unless $ok;
	}
	delete($filebrowser->{our_stash}->{cut}) if $filebrowser->{our_stash}->{cut};

	$filebrowser->RePopulate();
}

sub PasteBitmap {
	my $filebrowser = shift;

	wxTheClipboard->Open();
	my $bdo = Wx::BitmapDataObject->new();
	my $ok = wxTheClipboard->GetData($bdo);
	wxTheClipboard->Close();

	Wrangler::debug("FileBrowser::PasteBitmap: ok:$ok");

	unless($ok){
		my $dialog = Wx::MessageDialog->new($filebrowser, "The Clipboard doesn't hold bitmap data to paste.", "Paste ...as image", wxOK );
		$dialog->ShowModal();
		return;
	}

	my $dialog = Wx::FileDialog->new($filebrowser, "Choose a filename and directory", $filebrowser->{current_dir}, 'clipboard.png', "*.*",  wxFD_SAVE|wxFD_OVERWRITE_PROMPT );

	return unless $dialog->ShowModal() == wxID_OK;

	my $path = $dialog->GetPath();
	my $type = $path =~ /\.jpg$/ ? wxBITMAP_TYPE_JPEG : wxBITMAP_TYPE_PNG;
	$ok = $bdo->GetBitmap()->SaveFile($path, $type);

	unless($ok){
		my $error = "PasteBitmap: can't write clipboard's bitmap-data to file: $!";
		Wrangler::debug($error);
		my $dialog = Wx::MessageDialog->new($filebrowser, $error, "Error on Paste ...as image", wxOK );
		$dialog->ShowModal();
		return;
	}

	$filebrowser->RePopulate();
}

sub Todo {
	my $filebrowser = shift;
	my $dialog = Wx::MessageDialog->new($filebrowser, "Not yet implemented", "Not yet implemented", wxOK );
	$dialog->ShowModal();
}

sub OnRightClick {
	my $filebrowser = shift;
	my $event = shift;

	my $selections = $filebrowser->GetSelections_as_richlist_items();

        my $menu = Wx::Menu->new();

	my ($colId,$col_value_from) = $filebrowser->GetColumn($event);

	if(@$selections){
		## hardcoded file context menu entries
		EVT_MENU( $filebrowser, $menu->Append(-1, "View\tENTER", 'Execute/view with viewer'),	 sub { $filebrowser->OnActivated } );
		EVT_MENU( $filebrowser, $menu->Append(-1, "View/open with...", 'Select default viewer/application/command for this mime-type'),	 sub { Wrangler::PubSub::publish('show.settings', 1, 3); } );
		$menu->AppendSeparator();
		EVT_MENU( $filebrowser, $menu->Append(-1, "Cut\tCTRL+X", 'Cut' ),		 sub { $filebrowser->Cut(); }  );
		EVT_MENU( $filebrowser, $menu->Append(-1, "Copy\tCTRL+C", 'Copy' ),		 sub { $filebrowser->Copy(); } );
			my $itemPaste = Wx::MenuItem->new($menu, -1, "Paste\tCTRL+V", 'Paste');
			$menu->Append($itemPaste);
			if(0){ # todo: check: we have something in the clipboard AND selection is 1 dir -> "integrate into folder"
				$menu->Enable($itemPaste->GetId(),1);
				EVT_MENU( $filebrowser, $itemPaste, sub { $filebrowser->Todo(); } );
			}else{
				$menu->Enable($itemPaste->GetId(),0);
			}
		$menu->AppendSeparator();
		EVT_MENU( $filebrowser, $menu->Append(-1, "Rename\tF2", 'Rename file' ),		 sub { $filebrowser->Rename(); }  );
			unless($col_value_from eq 'Filesystem::Filename'){
				my $itemChange = Wx::MenuItem->new($menu, -1, "Change '$col_value_from'", "Change '$col_value_from'");
				$menu->Append($itemChange);
				if( $filebrowser->{wrangler}->{fs}->can_mod($col_value_from) ){
					$menu->Enable($itemChange->GetId(),1);
					EVT_MENU( $filebrowser, $itemChange, sub { $filebrowser->ChangeProperty($col_value_from); } );
				}else{
					$menu->Enable($itemChange->GetId(),0);
				}
			}
		EVT_MENU( $filebrowser, $menu->Append(-1, "Create directory", 'Create a directory' ),	 sub { $filebrowser->Mkdir(); } );
		$menu->AppendSeparator();
		EVT_MENU( $filebrowser, $menu->Append(-1, "Move to trash\tDEL", 'Move a file to trash' ), sub { $filebrowser->Delete(); } );
		EVT_MENU( $filebrowser, $menu->Append(-1, "Delete\tCTRL+DEL", 'Really delete a file or directory' ), sub { $filebrowser->Delete(1); } ) if $filebrowser->{wrangler}->config()->{'ui.filebrowser.offer.delete'};

		## plugin file context menu entries
		if( my $plugins_ref = Wrangler::PluginManager::plugins('file_context_menu') ){
			for my $plugin (@$plugins_ref){
				if( my $plugin_menu_entries = $plugin->file_context_menu($menu,$selections) ){
					$menu->AppendSeparator();
					for my $entry ( @$plugin_menu_entries ){
						next unless ref($entry) eq 'ARRAY' && ref(${$entry}[0]) eq 'Wx::MenuItem' && ref(${$entry}[1]) eq 'CODE';
						EVT_MENU( $filebrowser, $menu->Append( ${$entry}[0] ), ${$entry}[1] );
						&{ ${$entry}[2] } if ${$entry}[2];
					}
				}
			}
		}

		$menu->AppendSeparator();
		EVT_MENU( $filebrowser, $menu->Append(-1, "Properties", 'Show details about current selection' ), sub {
			require Wrangler::Wx::Dialog::Properties;
			my $selections = $filebrowser->GetSelections_as_richlist_items();
			my $dialog = Wrangler::Wx::Dialog::Properties->new($filebrowser,$selections);
			$dialog->ShowModal();
			$dialog->Destroy();
		});
	}else{
		## hardcoded folder context menu entries
		EVT_MENU( $filebrowser, $menu->Append(-1, "New folder", 'Create a folder' ),	 sub { $filebrowser->Mkdir(); }  );
		EVT_MENU( $filebrowser, $menu->Append(-1, "New file", 'Create a file/node' ),	 sub { $filebrowser->Mknod(); } );
		$menu->AppendSeparator();
			my $itemPaste = Wx::MenuItem->new($menu, -1, "Paste\tCTRL+V", 'Paste');
			my $itemPasteSymlinks = Wx::MenuItem->new($menu, -1, "Paste ...as symlink(s)", 'Paste files on the clipboard as symlinks');
			my $itemPasteBitmap = Wx::MenuItem->new($menu, -1, "Paste ...as image", 'Paste clipboard contents as image file');
			$menu->Append($itemPaste);
			$menu->Append($itemPasteSymlinks);
			$menu->Append($itemPasteBitmap);
			if(1){ # as it seems, it's safe to assume there's always something in the clipboard
				$menu->Enable($itemPaste->GetId(),1);
				EVT_MENU( $filebrowser, $itemPaste, sub { $filebrowser->Paste(); } );
				$menu->Enable($itemPasteSymlinks->GetId(),1);
				EVT_MENU( $filebrowser, $itemPasteSymlinks, sub { $filebrowser->PasteSymlinks(); } );
				$menu->Enable($itemPasteBitmap->GetId(),1);
				EVT_MENU( $filebrowser, $itemPasteBitmap, sub { $filebrowser->PasteBitmap(); } );
			}else{
				$menu->Enable($itemPaste->GetId(),0);
			}
		$menu->AppendSeparator();
		EVT_MENU( $filebrowser, $menu->Append(-1, "Zoom in\tCTRL++", 'Zoom in'),		 sub { Wrangler::PubSub::publish('zoom.in'); } );
		EVT_MENU( $filebrowser, $menu->Append(-1, "Zoom standard\tCTRL+0", 'Zoom standard'),	 sub { Wrangler::PubSub::publish('zoom.standard'); } );
		EVT_MENU( $filebrowser, $menu->Append(-1, "Zoom out\tCTRL+-", 'Zoom out'),		 sub { Wrangler::PubSub::publish('zoom.out'); } );
		$menu->AppendSeparator();
		EVT_MENU( $filebrowser, $menu->Append(-1, "Export listing as text", ''),		 sub {
			require Wrangler::Wx::Dialog::ListingToText;
			Wrangler::Wx::Dialog::ListingToText->new($filebrowser);
		});
		$menu->AppendSeparator();
		EVT_MENU( $filebrowser, $menu->Append(-1, "Settings", 'Settings'),		 sub { Wrangler::PubSub::publish('show.settings', 1, 0); } );
	}

	$filebrowser->PopupMenu( $menu, wxDefaultPosition ); # alt: $event->GetPosition
}

sub OnChar {
	my ($filebrowser, $event) = @_;

	my $keycode = $event->GetKeyCode();	# speedup by less calls

	Wrangler::debug("OnChar: $keycode");

	# more or less ordered by probability
	if($keycode == 22 && $event->ControlDown() ){
		Wrangler::debug("CTRL+V: Paste/Insert");
		$filebrowser->Paste();
	}elsif($keycode == 24 && $event->ControlDown() ){
		Wrangler::debug("CTRL+X: Cut");
		$filebrowser->Cut();
	}elsif($keycode == 3 && $event->ControlDown() ){
		Wrangler::debug("CTRL+C: Copy");
		$filebrowser->Copy();
	}elsif($keycode == WXK_ESCAPE){
#		if($filebrowser->{in_viewmode}){
#			Wrangler::debug("ESC: Filebrowser is viewing: so close Viewer.");
#		#	$filebrowser->{viewer}->Close();
#		#	$filebrowser->Show(1);
#		}else{
			Wrangler::debug("ESC: Deselect all");
			$filebrowser->DeselectAll();
#		}
	}elsif($keycode == WXK_F2){
		Wrangler::debug("F2: Rename");

		$filebrowser->Rename();
	}elsif($keycode == WXK_DELETE){
		Wrangler::debug("Delete");

		$event->ControlDown() ? $filebrowser->Delete('really') : $filebrowser->Delete();
	}elsif($keycode == 1 && $event->ControlDown() ){
		Wrangler::debug("CTRL+A: Select all");

		$filebrowser->SelectAll();
	}elsif($keycode == 9 && $event->ShiftDown() && $event->ControlDown() ){
		Wrangler::debug("SHIFT+CTRL+I: Invert selection");

		$filebrowser->InvertSelections();
	}elsif($keycode == 18 && $event->ControlDown() ){
		Wrangler::debug("CTRL+R: Refresh current view");
		$filebrowser->RePopulate();
	}elsif($keycode == WXK_BACK){
		Wrangler::debug("Backspace: Go one dir up");

		# emit appropriate event
		Wrangler::PubSub::publish('dir.activated', $filebrowser->{wrangler}->{fs}->parent($filebrowser->{current_dir}));
	}elsif($keycode == WXK_F5){
		Wrangler::debug("F5: Refresh current view");
		$filebrowser->RePopulate();
	}elsif($keycode == 43){
		Wrangler::debug("CTRL++: View Zoom-In: ");

		# emit appropriate event
		Wrangler::PubSub::publish('zoom.in');
	}elsif($keycode == 45){
		Wrangler::debug("CTRL+-: View Zoom-Out: ");

		# emit appropriate event
		Wrangler::PubSub::publish('zoom.out');
	}elsif($keycode == 48){
		Wrangler::debug("CTRL+0: View Zoom-Standard: ");

		# emit appropriate event
		Wrangler::PubSub::publish('zoom.standard');
	}

	$event->Skip(1);
}

sub Destroy {
	my $self = shift;

	Wrangler::PubSub::unsubscribe_owner(__PACKAGE__);

	$self->SUPER::Destroy();
}

1;
