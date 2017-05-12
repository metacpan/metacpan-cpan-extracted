#
#  Test of adding/removing widgets using the IDElayout methods
#
#   Expected Results
#     After initial window creation (To tabframes visible, Stacked vertically)
#       1) Widget should be added to the left side after two seconds
#       2) Widget addd in step (1) should be deleted after another two seconds.
#
use Tk;
use Tk::IDElayout;
use Tk::IDEtabFrame;
use Tk::Text;
use Tk::IDElayoutDropSite;

# With nothing on the command line, the script will quit after the text completes
my $dontExit = shift @ARGV;

require 'testTextEdit'; # get the syntax highlighting text edit subs

print "1..1\n";

my $TOP = MainWindow->new;
$TOP->geometry('1000x800');
$TOP->update();

#  Create layout structures
my @nodes = (
  {  name => 'P1', 
   dir  => 'V',
   childOrder => ['Tab1', 'Tab2'],
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
###  TabFrame 1 ###
my $dtf = $TOP->IDEtabFrame(
	#-font => 'System 8', 
	-tabclose => 1,
	-tabcolor => 'white',
#	-raisecolor => 'darkseagreen2',
	-raisecolor => 'grey90',
#	-tabcurve => 2,
	-tabpady => 1,
	-tabpadx => 1,
	-padx => 0,
	-pady => 0,
	-bg => 'white',

	# Additional Options added by IDEtabFrame
	-raisedfg => 'black',
	
	-raisedCloseButtonfg => 'black',
	-raisedCloseButtonbg => 'lightgrey',
	-raisedCloseButtonActivefg => 'red',

	-noraisedfg => 'grey60',
	-noraisedActivefg => 'black',
	
	-noraisedCloseButtonfg => 'lightgrey',
	-noraisedCloseButtonbg => 'white',
	-noraisedCloseButtonActivefg => 'red',
		
	);
	
	#$dtf->configure( -raisecmd => sub{ raise_cmd($dtf, shift);});


######### Create and insert Text Widget in Tabs ###############	
#

#
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

my $dtf2 = $TOP->IDEtabFrame(
	#-font => 'System 8', 
	-tabclose => 1,
	-tabcolor => 'white',
#	-raisecolor => 'darkseagreen2',
	-raisecolor => 'grey90',
#	-tabcurve => 2,
	-tabpady => 1,
	-tabpadx => 1,
	-padx => 0,
	-pady => 0,
	-bg => 'white',

	# Additional Options added by IDEtabFrame
	-raisedfg => 'black',
	
	-raisedCloseButtonfg => 'black',
	-raisedCloseButtonbg => 'lightgrey',
	-raisedCloseButtonActivefg => 'red',
	
	-noraisedfg => 'grey60',
	-noraisedActivefg => 'black',
	
	-noraisedCloseButtonfg => 'lightgrey',
	-noraisedCloseButtonbg => 'white',
	-noraisedCloseButtonActivefg => 'red',

	);

	
	#$dtf->configure( -raisecmd => sub{ raise_cmd($dtf, shift);});

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

#$layout->displayStruct();

# Add a widget
my $textFile;
$|= 1;
my $time = 2000;
$layout->after(1000, sub{
        $textFile = createTextWindow($TOP, 'IDElayout.pm');
        print "Adding IDElayout.pm to the left side...\n";
        $layout->addWidgetAtSide($textFile, "IDElayout.pm", 'P1', 'left');
});



# Delete a widget
$layout->after($time+=3000, sub{
        print "Deleting IDElayout.pm from the left side...\n";
        $textFile = $layout->deleteWidget("IDElayout.pm");
        #$layout->displayStruct();
});



# Add the widget again
$layout->after($time+=2000, sub{
        #$textFile = createTextWindow($TOP, 'IDElayout.pm');
        print "Adding IDElayout.pm back to the left side...\n";
        $layout->addWidgetAtSide($textFile, "IDElayout.pm", 'P1', 'left');
        #$layout->displayStruct('After second add');

});

# Delete a widget
$layout->after($time+=2000, sub{
        print "Deleting IDElayout.pm from the left side...\n";
        $textFile = $layout->deleteWidget("IDElayout.pm");
        #$layout->displayStruct();
});

# Add the widget to the right side
$layout->after($time+=2000, sub{
        #$textFile = createTextWindow($TOP, 'IDElayout.pm');
        print "Adding IDElayout.pm back to the right side...\n";
        $layout->addWidgetAtSide($textFile, "IDElayout.pm", 'P1', 'right');
        #$layout->displayStruct('After second add');

});

# Delete a widget
$layout->after($time+=2000, sub{
        print "Deleting IDElayout.pm from the right side...\n";
        $textFile = $layout->deleteWidget("IDElayout.pm");
        #$layout->displayStruct();
});

# Add the widget to the top side
$layout->after($time+=2000, sub{
        #$textFile = createTextWindow($TOP, 'IDElayout.pm');
        print "Adding IDElayout.pm back to the top side...\n";
        $layout->addWidgetAtSide($textFile, "IDElayout.pm", 'P1', 'top');
        #$layout->displayStruct('After second add');

});

# Delete a widget
$layout->after($time+=2000, sub{
        print "Deleting IDElayout.pm from the top side...\n";
        $textFile = $layout->deleteWidget("IDElayout.pm");
        #$layout->displayStruct();
});

# Add the widget to the bot side
$layout->after($time+=2000, sub{
        #$textFile = createTextWindow($TOP, 'IDElayout.pm');
        print "Adding IDElayout.pm back to the bottom side...\n";
        $layout->addWidgetAtSide($textFile, "IDElayout.pm", 'P1', 'bot');
        #$layout->displayStruct('After second add');

});


# Delete a widget
$layout->after($time+=2000, sub{
        print "Deleting IDElayout.pm from the bot side...\n";
        $textFile = $layout->deleteWidget("IDElayout.pm");
        print "Test Completed...\n";
        #$layout->displayStruct();
});

# Quit the test after two seconds
unless( $dontExit){
    $TOP->after($time+=2000,sub{
            print "Test Complete... Exiting\n";
            $TOP->destroy;
    });
}


MainLoop;


print "ok 1\n";
