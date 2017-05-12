#
#  Simple test of the Tk::IDElayout
	
use Tk;
use Tk::IDElayout;

# With nothing on the command line, the script will quit after the text completes
my $dontExit = shift @ARGV;

print "1..1\n";

my $TOP = MainWindow->new;


#  Create layout structures
my @nodes = (
  {  name => 'P1', 
   dir  => 'H',
   childOrder => ['Frame 1', 'P2'],
   type => 'panedWindow',
  },  
   {  name => "Frame 1", type => 'widget'
   },
   {  name => 'P2',
      dir  => 'V',
    childOrder => ['Frame 2', 'Frame 3'],
    type => 'panedWindow'
   },
   {  name => 'Frame 2', type => 'widget' },
   {  name => 'Frame 3', type => 'widget' },
);
my @edges = (
   [ 'P1', 'Frame 1'],
   [ 'P1', 'P2'],
   [ 'P2', 'Frame 2'],
   [ 'P2', 'Frame 3'],
   );


# Create widgets, just simple labels for this demo
# Create Widgets
my %widgets;
my $frameNum = 1;
my $height = 5;
foreach my $node(@nodes){
	next unless( $node->{type} eq 'widget') ; # Only create widgets
	my $widget = $TOP->Label(-text=> "Frame $frameNum Label", -width => 40, -height => $height, -bg => 'white');
	$widgets{"Frame $frameNum"} = $widget;
	$frameNum++;
	$height+=5; # Make each label widget request a different height
}

# Create simple menubar
my $MenuBar = $TOP->Frame(-class => 'Menubar'); # We don't pack this, it will be packed by IDElayout
# Create Menu Items
my $fileButton = $MenuBar->Menubutton(-text => 'File', -underline => 0)->pack(-side => 'left');
my $toolsButton = $MenuBar->Menubutton(-text => 'Tools', -underline => 0)->pack(-side => 'left');
my $optionsButton = $MenuBar->Menubutton(-text => 'Options', -underline => 0)->pack(-side => 'left');
$fileButton->command(-label => 'Quit', -command => [ $TOP->toplevel, 'destroy']);
$toolsButton->command(-label => 'Sample Entry 1');
$optionsButton->command(-label => 'Sample Entry 2');


# Create simple statusLine
my $statusText = "This is statusLine Text";
my $statusLine = $TOP->Label(-textvariable => \$statusText, -anchor => 'w');


# Structure Created, now buld the Tk::IDElayout

my $layout = $TOP->IDElayout(
	-widgets => \%widgets,
	-frameStructure => { nodes => \@nodes,  edges => \@edges},
	-menu    => $MenuBar,
	-statusLine => $statusLine,
	);


$layout->pack(-side => 'top', -fill => 'both', -expand => 'yes');

# Quit the test after two seconds
unless( $dontExit){
    $TOP->after(2000,sub{
            print "Test Complete... Exiting\n";
            $TOP->destroy;
    });
}

MainLoop;

print "ok 1\n";
