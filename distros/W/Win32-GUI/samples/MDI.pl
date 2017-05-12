#! perl -w
#
#  MDI sample
#
use strict;
use warnings;
use Win32::GUI();

# My child counter for unique name.
my $ChildCount = 0;

my $Window;

# Create Main menu.
my $Menu = Win32::GUI::MakeMenu(
    "&File"                       => "File",
    "   > &New"                   => { -name => "File_New",  -onClick => \&NewChild },
    "   > -"                      => 0,
    "   > E&xit"                  => { -name => "File_Exit", -onClick => sub { -1; } },
    "&Window"                     => "Window",
    "   > &Next"                  => { -name => "Next",    -onClick => sub { $Window->{Client}->Next;     } },
    "   > &Previous"              => { -name => "Prev",    -onClick => sub { $Window->{Client}->Previous; } },
    "   > -"                      => 0,
    "   > &Cascade"               => { -name => "Cascade", -onClick => sub { $Window->{Client}->Cascade(); 0; } },
    "   > Tile &Horizontally"     => { -name => "TileH",   -onClick => sub { $Window->{Client}->Tile(1);  } },
    "   > Tile &Vertically"       => { -name => "TileV",   -onClick => sub { $Window->{Client}->Tile(0);  } },
    "&Help"                       => "Help",
    "   > &About "                => { -name => "About", -onClick => sub { 1; } },
);

# First we create an MDIFrame window.
$Window = new Win32::GUI::MDIFrame (
    -title  => "Win32::GUI MDI Sample",
    -left   => 100,
    -top    => 100,
    -width  => 280,
    -height => 280,
    -name   => "Window",
    -menu   => $Menu,
) or die "Window";

# We add an MDIClient window, This window manage Child Window.
$Window->AddMDIClient(
      -name       => "Client",
      -firstchild => 100,                         # Define Child ID for menu item
      -windowmenu => $Menu->{Window}->{-handle},  # Define Menu Handle where Add Window Child name
  ) or die "Client";

# Show main window and go to event loop
$Window->Show;
Win32::GUI::Dialog();

# This function create a new child window.
sub NewChild {
    
    # Create a child window.
    my $Child = $Window->{Client}->AddMDIChild (
      -name         => "Child".$ChildCount++,
      -onActivate   => sub { print "Activate\n"; },
      -onDeactivate => sub { print "Deactivate\n"; },
      -onTerminate  => sub { print "Terminate\n";},
      -onResize => \&ChildSize, 
    ) or die "Child";

    # Add a text filed into child window.
    $Child->AddTextfield (
        -name => "Edit",
        -multiline => 1,
        -pos => [0,0],
        -size => [100,100],      
    );

    # Force a resize.
    ChildSize($Child);
}

# This function manage child window resize.
sub ChildSize { 
     my $self = shift; 
     my ($width, $height) = ($self->GetClientRect())[2..3];
     # TextField take all client aera
     $self->{Edit}->Resize($width, $height) if exists $self->{Edit};
}
