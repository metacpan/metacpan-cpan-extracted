package Wrangler::Wx::Sidebar;

use strict;
use warnings;

use base qw(Wx::TreeCtrl);

use Wx qw(:treectrl wxDefaultPosition wxDefaultSize);
use Wx::Event qw(EVT_TREE_SEL_CHANGING EVT_TREE_ITEM_RIGHT_CLICK EVT_RIGHT_UP EVT_MENU EVT_LEFT_UP);
use Encode;
use File::Basename ();
use File::Spec ();
use Sys::Filesystem ();

sub new {
	my $class  = shift;
	my $parent = shift;
	my $self = $class->SUPER::new( $parent, -1, wxDefaultPosition, wxDefaultSize, wxTR_HIDE_ROOT|wxTR_NO_LINES|wxTR_HAS_BUTTONS );

	# hook-up access to $wrangler
	$self->{wrangler} = $parent->{wrangler};

	# treelist is set-up centrally in Main; link data strctures here
	$self->SetImageList( ${ $parent->{imagelist} } );
	$self->{images} = $parent->{images};

#	## what other Sidebars look like:
#	# Linux: http://upload.wikimedia.org/wikipedia/commons/2/28/Nautilus-3.10.0.png
#	# Linux: http://upload.wikimedia.org/wikipedia/commons/6/64/4.2_Konqueror_Filebrowser.png
#	# Mac: https://web.archive.org/web/20130329080038/http://osxhelp.com/customizing-the-finder-sidebar-in-os-x
#	# Mac: http://upload.wikimedia.org/wikipedia/en/2/23/Finder_Lion.png
#	# WinXP: http://upload.wikimedia.org/wikipedia/en/c/c0/Windows_Explorer_XP.png
#	# Win7: http://upload.wikimedia.org/wikipedia/en/c/cb/Windows_Explorer_Windows_7.png

	$self->SetForegroundColour(Wx::Colour->new(@{ $self->{wrangler}->config()->{'ui.foreground_colour'} })) if $self->{wrangler}->config()->{'ui.foreground_colour'};
	$self->SetBackgroundColour( $parent->GetBackgroundColour() );

	## init TreeCtrl, add a hidden root node
	$self->{root} = $self->AddRoot('Wrangler Sidebar');
	$self->SetIndent(7);

	$self->Populate();

	## hook up events
	EVT_TREE_SEL_CHANGING( $self, $self, sub {
		my $itemData = $_[0]->GetItemData( $_[1]->GetItem() );
		unless($itemData){ # Category headings (Devices, Bookmarks,...) have no data associated
			$_[1]->Veto();
			return;
		}
		my $ref = $itemData->GetData();
		Wrangler::debug("Sidebar::OnSelectionChanged: $ref->{path}");
		# emit appropriate event
		Wrangler::PubSub::publish('dir.activated', $ref->{path}) if $ref->{path};
	});
	EVT_LEFT_UP($self,sub { Wrangler::debug("OnLeftClick"); });
# todo	EVT_TREE_ITEM_RIGHT_CLICK( $self, $self, sub { Wrangler::debug("Sidebar::OnItemRightClick: @_"); $self->PopupMenu( Wrangler::Sidebar::MenuRightClick->new( $self ), wxDefaultPosition ); } );
	EVT_RIGHT_UP($self,sub { \&OnRightClick(@_); });

	return $self;
}

sub Clear {
	my ($sidebar) = @_;

	$sidebar->DeleteChildren($sidebar->{root});
}

sub Populate {
	my ($sidebar,$path) = @_;

	$sidebar->Clear();

	## list mounts
	my $devices_tree = $sidebar->AppendItem( $sidebar->{root}, 'Devices', -1, -1);
	$sidebar->SetItemBold($devices_tree);
	my $sf = Sys::Filesystem->new();
	for( $sf->filesystems(regular => 1) ){
		my $label = $sf->label($_);
		my $mount_point = $sf->mount_point($_);
		next if $mount_point eq '/dev';
		my $id = $sidebar->AppendItem($devices_tree,
			$label ? $label : $mount_point,
			$sidebar->{images}->{device}, $sidebar->{images}->{device},
			Wx::TreeItemData->new({
				path	=> $mount_point,
				label	=> $label ? $label : $mount_point,
			})
		);
	}

	## load .gtk-bookmarks
	my $bookmarks_tree = $sidebar->AppendItem( $sidebar->{root}, 'Bookmarks', -1, -1);
	$sidebar->SetItemBold($bookmarks_tree);
	for ( $sidebar->gtkbookmarks() ){
		my $itemId = $sidebar->AppendItem($bookmarks_tree,
			$_->{label},
			$sidebar->{images}->{folder}, $sidebar->{images}->{folder}, Wx::TreeItemData->new( $_ ) # we store the ref to this branch here
		);
#		$sidebar->SetItemImage( $itemId, 0, $sidebar->{images}->{folder});
	}

	## "places"
	my $places_tree = $sidebar->AppendItem( $sidebar->{root}, 'Places', -1, -1);
	$sidebar->SetItemBold($places_tree);
	my @places = (
		{
			path	=> $ENV{HOME},
			label	=> 'Home',
			icon	=> 'go_home',
		},
		{
			path	=> File::Spec->catfile($ENV{HOME}, '.local/share/Trash/files'),
			label	=> 'Recycler',
			icon	=> 'trash',
		}
	);
	for(@places){
		my $itemId = $sidebar->AppendItem($places_tree,
			$_->{label},
			$sidebar->{images}->{ $_->{icon} }, $sidebar->{images}->{ $_->{icon} },
			Wx::TreeItemData->new($_)
		);
	}

	$sidebar->ExpandAll();
}

sub OnRightClick {
	my $sidebar = shift;
	my $event = shift;

	my $itemId = $sidebar->GetSelection();

        my $menu = Wx::Menu->new();

	if( $itemId && $sidebar->GetItemData($itemId) ){
		my $item = Wx::MenuItem->new($menu, -1, "Rename");
		$menu->Append($item);
		$menu->Enable($item->GetId(),0);
		my $item_del = Wx::MenuItem->new($menu, -1, "Delete");
		$menu->Append($item_del);
		$menu->Enable($item_del->GetId(),0);
		$menu->AppendSeparator();
	}

	EVT_MENU( $sidebar, $menu->Append(-1, "Settings", 'Settings'), sub { Wrangler::PubSub::publish('show.settings', 0, 0); } );

	$sidebar->PopupMenu( $menu, wxDefaultPosition );
}

sub gtkbookmarks {
	my $self = shift;

	my $parent = Wx::wxTheApp->GetTopWindow;

	## for now, simple checks, later we might add the dependency on File::HomeDir
	return unless $ENV{HOME};

	my $path = File::Spec->catfile( $ENV{HOME}, '.config', 'gtk-3.0', 'bookmarks');
	if( $parent->{wrangler}->{fs}->test('e', $path) ){
		Wrangler::debug('Wx::Sidebar: found gtk-bookmarks file in gtk3 location');
	}else{
		$path = File::Spec->catfile($ENV{HOME}, '.gtk-bookmarks');
		return unless $parent->{wrangler}->{fs}->test('e', $path);
		Wrangler::debug('Wx::Sidebar: found gtk-bookmarks in legacy location');
	}

	my @bookmarks;
	open(my $fh, '<', $path) or die "Can't open gtk-bookmarks: $path: $!";
	binmode($fh);
	while(<$fh>) {
		$_ = encode_utf8($_);	# we assume the file to be in utf8
		chomp;

		my ($path, $label) = split(/ /,$_, 2);
		$path =~ s/file:\/\///;

		$path = url_decode($path);

		if(!$label){
			$label = File::Basename::basename($path)
		}

		push(@bookmarks, {
			path	=> $path,
			label	=> $label,
		}) if $path && $parent->{wrangler}->{fs}->test('e', $path);
	}
	close $fh;

	return @bookmarks;
}

## borrowed from CGI_Lite
# sub url_encode {
# 	my $string = shift;
# 
# $string =~ s/([\x00-\x20"#%;<>?{}|\\\\^~`\[\]\x7F-\xFF])/
# 		sprintf ('%%%x', ord ($1))/eg;
# 
# return $string;
# }
sub url_decode {
    my $string = shift;

    $string =~ s/%([\da-fA-F]{2})/chr (hex ($1))/eg;

    return $string;
}


#	package Wrangler::Sidebar::MenuRightClick;
#	 
#	use strict;
#	use base qw(Wx::Menu);
#	 
#	use Wx::Event qw(EVT_MENU);
#	 
#	sub new {
#		my $class  = shift;
#	 	my $parent = shift;
#	 	my $self = $class->SUPER::new();
#	 
#	 	my $add_menu = Wx::Menu->new();
#	 
#	 	## define menu entries
#		EVT_MENU( $parent,	$self->Append(-1, "Add", 'Add place' ), sub { } );
#		EVT_MENU( $parent,	$self->Append(-1, "Delete\tDEL", 'Delete place' ), sub { } );
#	 
#	 	return $self;
#	}

sub Destroy {
	my $self = shift;

	Wrangler::PubSub::unsubscribe_owner(__PACKAGE__);

	$self->SUPER::Destroy();
}

1;
