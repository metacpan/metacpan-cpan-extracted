#
#  Simple test of the Tk::IDElayout. Includes two Tk::IDEtabFrame widgets populated with text widgets.
	
use Tk;
use Tk::IDElayout;
use Tk::IDEtabFrame;
use Tk::Text;

# With nothing on the command line, the script will quit after the text completes
my $dontExit = shift @ARGV;

require 'testTextEdit'; # get the syntax highlighting text edit subs

print "1..1\n";

my $TOP = MainWindow->new;
#$TOP->geometry('600x800');
#$TOP->update();

###  Create layout structures ###
###    This structure has the PaneWindow (P1) at the top level, 
###      and the two IDEtabFrames next lower level.
###     Graphically, this looks like this:
###     +------+     +------+
###     |  P1  | ==> | Tab1 |
###     +------+     +------+
###       H
###       H
###       v
###     +------+
###     | Tab2 |
###     +------+
my @nodes = (
  {  name => 'P1', 
   dir  => 'V',
   childOrder => ['Tab1', 'Tab2'],
   expandfactors => [1,1],
   type => 'panedWindow',
  },  
   {  name => "Tab1", type => 'widget'
   },
   {  name => "Tab2", type => 'widget'
   }
);
my @edges = (
   [ 'P1', 'Tab1'],
   [ 'P1', 'Tab2'],
   );


#################### Create Widgets ##################################
# We will use the same default IDEtabFrame config that the IDElayout widget uses
my $IDEtabFrameConfig = Tk::IDElayout->defaultIDEtabFrameConfig();

###  TabFrame 1 ###
my $dtf = $TOP->IDEtabFrame( @$IDEtabFrameConfig);

######### Create and insert Text Widget in Tabs ###############	
foreach my $filename( qw/ IDEtabFrame.pm CaptureRelease.pm /){
	my $textFileFrame = $dtf->add(
		-caption => $filename,
		-label   => $filename,
	);
	
	my $textFile = createTextWindow($TOP, $filename);
	$textFile->pack( -anchor => 'w', -in => $textFileFrame, -expand => 1, -fill => 'both');
}

$dtf->configure(-height => 400);


###  TabFrame 2 ###

my $dtf2 = $TOP->IDEtabFrame( @$IDEtabFrameConfig);


######### Create and insert Text Widget in Tabs ###############	

foreach my $filename( qw/ TabsDragDemo CaptureReleaseTest /){
	my $textFileFrame = $dtf2->add(
		-caption => $filename,
		-label   => $filename,
	);
	
	my $textFile = createTextWindow($TOP, $filename);
	$textFile->pack( -anchor => 'w', -in => $textFileFrame, -expand => 1, -fill => 'both');
}

######### Populate widgets hash with the two TabFrames created ######
my %widgets = ( 'Tab1' => $dtf,
	        'Tab2' => $dtf2,
		);


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

#$Tk::IDEtabFrame::DEBUG = 1;

# Add a widget
#my $textFile;
#$layout->after(6000, sub{
#       print "Reconfiguring...\n";
#        $dtf2->TabReconfig();
#});

# Quit the test after two seconds
unless( $dontExit){
    $TOP->after(4000,sub{
            print "Test Complete... Exiting\n";
            $TOP->destroy;
    });
}

MainLoop;

print "ok 1\n";
