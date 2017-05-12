package Wrangler::Wx::Main;

use strict;
use warnings;

use Wx qw(:everything);
use base qw(Wx::Frame);
use Wx::Event qw(EVT_MOVE EVT_CLOSE EVT_SPLITTER_SASH_POS_CHANGED);
use Wrangler::Images;

sub new {
	my ($self,$parent) = @_;

	$self = $self->SUPER::new(undef, wxID_ANY, 'Wrangler', wxDefaultPosition, [$parent->config('ui.main.width'),$parent->config('ui.main.height')],
		wxDEFAULT_FRAME_STYLE | wxNO_FULL_REPAINT_ON_RESIZE | wxCLIP_CHILDREN
	);

	$self->{wrangler} = $parent;

	Wx::InitAllImageHandlers(); # is this still leaking memory?

	# load icons (at least on linux, scaling doesn't work, so we skip most versions)
	my $iconbundle = Wx::IconBundle->new();
#	$iconbundle->AddIcon('sources/logo/logo_2.x_icon256.png', wxBITMAP_TYPE_PNG);
#	$iconbundle->AddIcon('sources/logo/logo_2.x_icon128.png', wxBITMAP_TYPE_PNG);
	$iconbundle->AddIcon( Wx::Icon->newFromXPM($Wrangler::Images::image{'logo_2.x_icon64'}) );
#	$iconbundle->AddIcon('sources/logo/logo_2.x_icon48.png', wxBITMAP_TYPE_PNG);
#	$iconbundle->AddIcon('sources/logo/logo_2.x_icon32.png', wxBITMAP_TYPE_PNG);
#	$iconbundle->AddIcon('sources/logo/logo_2.x_icon24.png', wxBITMAP_TYPE_PNG);
#	$iconbundle->AddIcon('sources/logo/logo_2.x_icon16.png', wxBITMAP_TYPE_PNG);
	$self->SetIcons( $iconbundle );

	# Prepare images into a lookup-hash (as in Padre::Wx::Outline)
	my $imagelist = Wx::ImageList->new( 16, 16 );
	my $images = {
		folder => $imagelist->Add(
			Wx::ArtProvider::GetBitmap( 'wxART_FOLDER', 'wxART_OTHER_C', [ 16, 16 ], ),
		),
		file => $imagelist->Add(
			Wx::ArtProvider::GetBitmap( 'wxART_NORMAL_FILE', 'wxART_OTHER_C', [ 16, 16 ], ),
		),
		go_up => $imagelist->Add(
			Wx::ArtProvider::GetBitmap( 'wxART_GO_TO_PARENT', 'wxART_OTHER_C', [ 16, 16 ], ),
		),
		missing_image => $imagelist->Add(
			Wx::ArtProvider::GetBitmap( 'wxART_MISSING_IMAGE', 'wxART_OTHER_C', [ 16, 16 ], ),
		),
		go_home => $imagelist->Add(
			Wx::ArtProvider::GetBitmap( 'wxART_GO_HOME', 'wxART_OTHER_C', [ 16, 16 ], ),
		),
		generic_image => $imagelist->Add(
			Wx::ArtProvider::GetBitmap( 'wxART_MISSING_IMAGE', 'wxART_OTHER_C', [ 16, 16 ], ),
		),
		generic_audio => $imagelist->AddWithColourMask(
			Wx::Bitmap->newFromXPM($Wrangler::Images::image{'audio-x-generic'}),
			Wx::Colour->new(255,255,255)
		),
		generic_video => $imagelist->AddWithColourMask(
			Wx::Bitmap->newFromXPM($Wrangler::Images::image{'video-x-generic'}),
			Wx::Colour->new(0,0,0)
		),
		brick => $imagelist->AddWithColourMask(
			Wx::Bitmap->newFromXPM($Wrangler::Images::image{'brick'}),
			Wx::Colour->new(255,255,255)
		),
		device => $imagelist->Add(
			Wx::ArtProvider::GetBitmap( 'wxART_HARDDISK', 'wxART_OTHER_C', [ 16, 16 ], ),
		),
		trash => $imagelist->AddWithColourMask(
			Wx::Bitmap->newFromXPM($Wrangler::Images::image{'user-trash'}),
			Wx::Colour->new(0,0,0)
		),
	#	cdrom => $imagelist->Add(
	#		Wx::ArtProvider::GetBitmap( 'gtk-cdrom', 'wxART_OTHER_C', [ 16, 16 ], ), # only works on Linux+GTK
	#	),
	};

	if( $parent->config('ui.main.centered') ){
		$self->Centre( wxBOTH );
		$self->Centred(1);
	}else{
		$self->Move(	# instead of 'on construction'
			$parent->config('ui.main.posX') || -1,
			$parent->config('ui.main.posY') || -1,
		);
	}

	Wrangler::PubSub::freeze(); ## <<

	## create and associate a MenuBar
	if( $parent->config('ui.layout.menubar') ){
		$self->OnToggleMenuBar(1);
	}

	## create and associate a Status Bar
	if( $parent->config('ui.layout.statusbar') ){
		$self->OnToggleStatusBar(1);
	}

	$self->{splitter1} = Wx::SplitterWindow->new( $self, -1, wxDefaultPosition, [780,1000], wxNO_FULL_REPAINT_ON_RESIZE|wxCLIP_CHILDREN|wxSP_NOBORDER|wxSP_LIVE_UPDATE );
	$self->{splitter1}->SetMinimumPaneSize( 30 );	# As per rt#84591
	$self->{splitter1}->{imagelist} = \$imagelist;
	$self->{splitter1}->{images} = $images;
	$self->{splitter1}->{wrangler} = $parent;

		$self->{splitter2} = Wx::SplitterWindow->new( $self->{splitter1}, -1, wxDefaultPosition, [740,1000], wxNO_FULL_REPAINT_ON_RESIZE|wxCLIP_CHILDREN|wxSP_NOBORDER|wxSP_LIVE_UPDATE );
		$self->{splitter2}->SetMinimumPaneSize( 30 );	# As per rt#84591
		$self->{splitter2}->{imagelist} = \$imagelist;
		$self->{splitter2}->{images} = $images;
		$self->{splitter2}->{wrangler} = $parent;

	#	require Wrangler::Wx::Sidebar;
	#	$self->{sidebar} = Wrangler::Wx::Sidebar->new($self->{splitter2});
	#	$self->{widgets}->{sidebar} = 'splitter2';

			$self->{splitter3} = Wx::SplitterWindow->new( $self->{splitter2}, -1, wxDefaultPosition, [740,870], wxNO_FULL_REPAINT_ON_RESIZE|wxCLIP_CHILDREN|wxSP_NOBORDER|wxSP_LIVE_UPDATE );
			$self->{splitter3}->SetMinimumPaneSize( 30 );	# As per rt#84591
			$self->{splitter3}->{imagelist} = \$imagelist;	
			$self->{splitter3}->{images} = $images;
			$self->{splitter3}->{wrangler} = $parent;

	#		require Wrangler::Wx::FileBrowserTreeList;
	#		$self->{filebrowser} = Wrangler::Wx::FileBrowserTreeList->new($self->{splitter3});
			require Wrangler::Wx::FileBrowser;
			$self->{filebrowser} = Wrangler::Wx::FileBrowser->new($self->{splitter3});
			$self->{widgets}->{filebrowser} = 'splitter2'; #  $self->{widgets} keeps track of where widgets are/were positioned

				$self->{splitter4} = Wx::SplitterWindow->new( $self->{splitter3}, -1, wxDefaultPosition, [740,250], wxNO_FULL_REPAINT_ON_RESIZE|wxCLIP_CHILDREN|wxSP_NOBORDER|wxSP_LIVE_UPDATE );
				$self->{splitter4}->SetMinimumPaneSize( 30 );	# As per rt#84591
				$self->{splitter4}->{imagelist} = \$imagelist;	
				$self->{splitter4}->{images} = $images;
				$self->{splitter4}->{wrangler} = $parent;

				require Wrangler::Wx::Previewer;
				$self->{previewer} = Wrangler::Wx::Previewer->new($self->{splitter4});
				$self->{widgets}->{previewer} = 'splitter3';

	$self->{splitter1}->Initialize($self->{splitter2});
	$self->{widgets}->{navbar} = 'splitter1'; #  $self->{widgets} keeps track of where widgets are/were positioned
	if( $parent->config('ui.layout.navbar') ){
		$self->OnToggleNavbar(1);
	}

#		$self->{splitter2}->SplitVertically(
#			$self->{sidebar},
#			$self->{splitter3},
#			130
#		);
		$self->{splitter2}->Initialize($self->{splitter3});
		$self->{widgets}->{sidebar} = 'splitter2'; #  $self->{widgets} keeps track of where widgets are/were positioned
		if( $parent->config('ui.layout.sidebar') ){
			$self->OnToggleSidebar(1);
		}

			$self->{splitter3}->SplitVertically(
				$self->{filebrowser},
				$self->{splitter4},
				600 # doesn't react, thus enforced with MinimumPaneSize
			);

				$self->{widgets}->{formeditor} = 'splitter4';
			#-	$self->{widgets}->{treeeditor} = 'splitter4';

			#	$self->{splitter4}->SplitHorizontally(
			#		$self->{previewer},
			#		$self->{formeditor},
			#		300
			#	);
				$self->{splitter4}->Initialize($self->{previewer});
				$self->OnReCreateFormEditor();
			#-	$self->OnReCreateTreeEditor();

	Wrangler::PubSub::thaw(); ## <<

	$self->SetMinSize( Wx::Size->new(150,100) );

	$self->Show(1);

	## register our event listeners
	Wrangler::PubSub::subscribe('dir.activated', sub {
		return unless $_[0];
		Wrangler::debug("Main: OnDirActivated: @_");
		$self->SetTitle($_[0]);
		$parent->{current_dir} = $_[0]; # keep track of a "current directory scope" globally, used by available_properties() calls
		$0 = 'wrangler '.$_[0]; # set program_name, for ps
	},__PACKAGE__);
	Wrangler::PubSub::subscribe('show.settings', sub {
		require Wrangler::Wx::Dialog::Settings;
		Wrangler::Wx::Dialog::Settings->new($self, @_);
	},__PACKAGE__);
	Wrangler::PubSub::subscribe('show.about', sub {
		require Wrangler::Wx::Dialog::About;
		Wrangler::Wx::Dialog::About->new($self, @_);
	},__PACKAGE__);

	## Wx events
	EVT_CLOSE($self, \&OnClose);
	EVT_SPLITTER_SASH_POS_CHANGED( $self, $self->{splitter}, \&OnSashPosChanged );

	return $self;
}

sub OnToggleMenuBar {
	my $self = shift;
	my $force = shift; # force toggle into associating a MenuBar

	if( !$force && $self->GetMenuBar() ){
		$self->SetMenuBar( undef );
		delete($self->{menu});
	}else{
		require Wrangler::Wx::Menu;
		$self->{menu} = Wrangler::Wx::Menu->new($self);
		$self->SetMenuBar( $self->{menu} );
	}
}

sub OnToggleStatusBar {
	my $self = shift;
	my $force = shift; # force toggle into associating a StatusBar

	if( !$force && $self->GetStatusBar() ){
		# StatusBar behaves differently from MenuBar; $self->SetStatusBar( undef ) has no effect
		$self->{statusbar}->Destroy();
		delete($self->{statusbar});
	}else{
		require Wrangler::Wx::StatusBar;
		$self->{statusbar} = Wrangler::Wx::StatusBar->new($self);
		$self->SetStatusBar($self->{statusbar});
	}
}

sub OnToggleNavbar {
	my $self = shift;
	my $force = shift; # force toggle into associating a Navbar

	if( !$force && $self->{navbar} ){
		$self->{ $self->{widgets}->{navbar} }->Unsplit($self->{navbar});
		$self->{navbar}->Destroy();
		delete($self->{navbar});
	}else{
		require Wrangler::Wx::Navbar;
		$self->{navbar} = Wrangler::Wx::Navbar->new($self->{ $self->{widgets}->{navbar} }, -1, wxDefaultPosition, wxDefaultSize);
		my $window1 = $self->{ $self->{widgets}->{navbar} }->GetWindow1();
		$self->{ $self->{widgets}->{navbar} }->SplitHorizontally($self->{navbar},$window1,40);
	}
}

sub OnToggleSidebar {
	my $self = shift;
	my $force = shift; # force toggle into associating a Navbar

	if( !$force && $self->{sidebar} ){
		$self->{ $self->{widgets}->{sidebar} }->Unsplit($self->{sidebar});
		$self->{sidebar}->Destroy();
		delete($self->{sidebar});
	}else{
		require Wrangler::Wx::Sidebar;
		$self->{sidebar} = Wrangler::Wx::Sidebar->new($self->{ $self->{widgets}->{sidebar} }, -1, wxDefaultPosition, wxDefaultSize);
		my $window1 = $self->{ $self->{widgets}->{sidebar} }->GetWindow1();
		$self->{ $self->{widgets}->{sidebar} }->SplitVertically($self->{sidebar},$window1,180);
	}
}

sub OnReCreateFormEditor {
	my $self = shift;
	my $force = shift; # force toggle into associating a FormEditor

	if( $self->{formeditor} ){
		$self->{ $self->{widgets}->{formeditor} }->Unsplit($self->{formeditor});
		$self->{formeditor}->Destroy();
		delete($self->{formeditor});
	}

	require Wrangler::Wx::FormEditor;
	$self->{formeditor} = Wrangler::Wx::FormEditor->new($self->{ $self->{widgets}->{formeditor} });

	unless($self->{ $self->{widgets}->{formeditor} }->IsSplit() ){
		my $window1 = $self->{ $self->{widgets}->{formeditor} }->GetWindow1();
		$self->{ $self->{widgets}->{formeditor} }->SplitHorizontally($window1,$self->{formeditor},300);
	}
}

sub OnReCreateTreeEditor {
	my $self = shift;
	my $force = shift; # force toggle into associating a TreeEditor

	if( $self->{treeeditor} ){
		$self->{ $self->{widgets}->{treeeditor} }->Unsplit($self->{treeeditor});
		$self->{treeeditor}->Destroy();
		delete($self->{treeeditor});
	}

	require Wrangler::Wx::TreeEditor;
	$self->{treeeditor} = Wrangler::Wx::TreeEditor->new($self->{ $self->{widgets}->{treeeditor} });

	unless($self->{ $self->{widgets}->{treeeditor} }->IsSplit() ){
		my $window1 = $self->{ $self->{widgets}->{treeeditor} }->GetWindow1();
		$self->{ $self->{widgets}->{treeeditor} }->SplitHorizontally($window1,$self->{treeeditor},300);
	}
}

sub OnSashPosChanged {
	my( $self, $event ) = @_;

	print "Final sash position = ". $event->GetSashPosition ."\n";
}

sub Centred {
	if($_[1]){
		# pin position+size (don't check if frame is actually centred)
		@{ $_[0]->{CenteredPos} } = $_[0]->GetPositionXY();
		@{ $_[0]->{CenteredSize} } = $_[0]->GetSizeWH();
		return;
	}
	delete($_[0]->{CenteredPos});
}
sub IsCentred {
	my @pos = $_[0]->GetPositionXY();
	my @size = $_[0]->GetSizeWH();

	if(${ $_[0]->{CenteredPos} }[0] && ${ $_[0]->{CenteredPos} }[1]){
		if($pos[0] == ${ $_[0]->{CenteredPos} }[0] && $pos[1] == ${ $_[0]->{CenteredPos} }[1]){
			if( ${ $_[0]->{CenteredSize} }[0] && ${ $_[0]->{CenteredSize} }[1]){
				return 1 if $size[0] == ${ $_[0]->{CenteredSize} }[0] && $size[1] == ${ $_[0]->{CenteredSize} }[1];
			}
		}
	}
	return 0;
}

sub OnMove {
	my ($self,$event) = @_;
	my $p = $event->GetPosition();
	print "Wrangler::Main::OnMove ". $p->x ."\n";

	$self->IsCentered(0);
}

sub OnClose {
	my ($self,$event) = @_;

	my $maximized = $self->IsMaximized();
	my $centered = $self->IsCentred();
	my ($posX,$posY) = $self->GetPositionXY(); # ok to use instead of GetScreenPosition()
	my ($width,$height) = $self->GetSizeWH();
	Wrangler::debug("Wrangler::Wx::Main::OnClose: Window: maximized:$maximized,centred:$centered, posX:$posX,posY:$posY, width:$width,height:$height");

	## store ui. config-values
	my $config = $self->{wrangler}->config();
	$config->{'ui.main.maximized'} = $maximized;
	$config->{'ui.main.width'} = $width;
	$config->{'ui.main.height'} = $height;
	if($centered){
		delete($config->{'ui.main.posX'});
		delete($config->{'ui.main.posY'});
		$config->{'ui.main.centered'} = 1;
	}else{
		$config->{'ui.main.posX'} = $posX;
		$config->{'ui.main.posY'} = $posY;
		delete($config->{'ui.main.centered'});
	}

	$event->Skip(); # keep on propagating
}

1;
