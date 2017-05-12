package Wrangler::Wx::Menu;

use strict;
use warnings;

use base qw( Wx::MenuBar );
use Wx qw(wxID_CLOSE);
use Wx::Event qw(EVT_MENU);
# use Wrangler::Wx::Menu::Help;

sub new {
	my $class  = shift;
	my $parent = shift;
	my $self   = $class->SUPER::new( $parent);

	bless $self, $class;

		# menu File
		my $menu_file = Wx::Menu->new();
		$menu_file->Append( my $settings = Wx::NewId, "&Settings", 'Configure Wrangler' );
		$menu_file->AppendSeparator();
		$menu_file->Append(	my $exit = Wx::NewId, "E&xit",	"Quit Wrangler");

		EVT_MENU( $parent, $settings, sub { Wrangler::PubSub::publish('show.settings', 0); } );
		EVT_MENU( $parent, $exit, sub { $parent->Close(); });

		# menu Tools
		my $menu_tools = Wx::Menu->new();
		$menu_tools->Append( my $keywording = Wx::NewId, "&Keywording Tool", 'Keywording Tool' );

		EVT_MENU( $parent, $keywording, sub { require Wrangler::Wx::Dialog::KeywordingTool; Wrangler::Wx::Dialog::KeywordingTool->new($parent) } );

		# menu Help
		my $menu_help = Wx::Menu->new();
		$menu_help->Append( my $about	= Wx::NewId, "&About Wrangler", 'About Wrangler' );
		$menu_help->Append( my $purchase = Wx::NewId, "Purchasing Information", 'Purchasing Information' );
		$menu_help->Append( my $licence	= Wx::NewId, "Licence and User Agreement", 'Licence and User Agreement' );
		$menu_help->Append( my $changes	= Wx::NewId, "Changelog", 'Changelog' );

		EVT_MENU( $parent, $about,	sub { Wrangler::PubSub::publish('show.about', 0); } );
		EVT_MENU( $parent, $purchase,	sub { Wrangler::PubSub::publish('show.about', 1); } );
		EVT_MENU( $parent, $licence,	sub { Wrangler::PubSub::publish('show.about', 2); } );
		EVT_MENU( $parent, $changes,	sub { Wrangler::PubSub::publish('show.about', 3); } );


	# this is essentially a part of the Wx::Menu found in FileBrowser, hardcoded
	# we'd like to have this more modular, loaded like a Plugin or similar; todo

#+ NOTE that we don't have the tab-separated accelerator hint here, which is auto-watched by
#+ Wx, and this would overide our OnChar routines in FormEditor, FileBrowser, etc. as this
#+ here is on the main frame

	my $menu = Wx::Menu->new();
		## hardcoded folder context menu entries
		EVT_MENU( $parent, $menu->Append(-1, "New folder", 'Create a folder' ),	 sub { $parent->{filebrowser}->Mkdir(); }  );
		EVT_MENU( $parent, $menu->Append(-1, "New file", 'Create a file/node' ),	 sub { $parent->{filebrowser}->Mknod(); } );
		$menu->AppendSeparator();
			my $itemPaste = Wx::MenuItem->new($menu, -1, "Paste  (CTRL+V)", 'Paste');
			my $itemPasteSymlinks = Wx::MenuItem->new($menu, -1, "Paste ...as symlink(s)", 'Paste files on the clipboard as symlinks');
			my $itemPasteBitmap = Wx::MenuItem->new($menu, -1, "Paste ...as image", 'Paste clipboard contents as image file');
			$menu->Append($itemPaste);
			$menu->Append($itemPasteSymlinks);
			$menu->Append($itemPasteBitmap);
			if(1){ # as it seems, it's safe to assume there's always something in the clipboard
				$menu->Enable($itemPaste->GetId(),1);
				EVT_MENU( $parent, $itemPaste, sub { $parent->{filebrowser}->Paste(); } );
				$menu->Enable($itemPasteSymlinks->GetId(),1);
				EVT_MENU( $parent, $itemPasteSymlinks, sub { $parent->{filebrowser}->PasteSymlinks(); } );
				$menu->Enable($itemPasteBitmap->GetId(),1);
				EVT_MENU( $parent, $itemPasteBitmap, sub { $parent->{filebrowser}->PasteBitmap(); } );
			}else{
				$menu->Enable($itemPaste->GetId(),0);
			}
		$menu->AppendSeparator();
		EVT_MENU( $parent, $menu->Append(-1, "Select all  (CTRL+A)", 'Select all'),	 sub { $parent->{filebrowser}->SelectAll(); } );
		EVT_MENU( $parent, $menu->Append(-1, "Deselect all  (ESC)", 'Select none'),	 sub { $parent->{filebrowser}->DeselectAll(); } );
		EVT_MENU( $parent, $menu->Append(-1, "Invert selections  (SHIFT+CTRL+I)", 'Invert selections'),		 sub { $parent->{filebrowser}->InvertSelections(); } );
		$menu->AppendSeparator();
		EVT_MENU( $parent, $menu->Append(-1, "Zoom in  (CTRL++)", 'Zoom in'),		 sub { Wrangler::PubSub::publish('zoom.in'); } );
		EVT_MENU( $parent, $menu->Append(-1, "Zoom standard  (CTRL+0)", 'Zoom standard'),	 sub { Wrangler::PubSub::publish('zoom.standard'); } );
		EVT_MENU( $parent, $menu->Append(-1, "Zoom out  (CTRL+-)", 'Zoom out'),		 sub { Wrangler::PubSub::publish('zoom.out'); } );
		$menu->AppendSeparator();
		EVT_MENU( $parent, $menu->Append(-1, "Export listing as text", ''),		 sub {
			require Wrangler::Wx::Dialog::ListingToText;
			Wrangler::Wx::Dialog::ListingToText->new($parent);
		});
		$menu->AppendSeparator();
		EVT_MENU( $parent, $menu->Append(-1, "Settings", 'Settings'),		 sub { Wrangler::PubSub::publish('show.settings', 1, 0); } );


	$self->Append( $menu_file, '&File' );
	$self->Append( $menu, '&FileBrowser' );
	$self->Append( $menu_tools, '&Tools' );
	$self->Append( $menu_help, '&Help' ); # Wrangler::Wx::Menu::Help->new($parent)

	return $self;
}

1;
