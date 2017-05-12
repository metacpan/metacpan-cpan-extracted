## Script to test/demonstrate the Tk::IDEtabFrame widget and the WmCapture/Release Functions
##

####### 
# Expected Results:
#    1) Tk::IDEtabFrame widget should be displayed with two tabs
#    2) After 2 seconds, the IDEtabFrame.pm tab should be released to a toplevel window
#    3) After 2 more seconds, the IDEtabFrame.pm window will be captured back to a IDEtabFrame tab
#
use strict;

use Tk;
use Tk::IDEtabFrame;
use Tk::IDElayout;
use Tk::Text;

# With nothing on the command line, the script will quit after the text completes
my $dontExit = shift @ARGV;

require 'testTextEdit'; # get the syntax highlighting text edit subs

print "1..1\n";

my $TOP = MainWindow->new;
$TOP->geometry('800x600');


# We will use the same default IDEtabFrame config that the IDElayout widget uses
my $IDEtabFrameConfig = Tk::IDElayout->defaultIDEtabFrameConfig();

###  TabFrame 1 ###
my $dtf = $TOP->IDEtabFrame( @$IDEtabFrameConfig);

my @textWidgets;
######### Create and insert Text Widget in Tabs ###############	
foreach my $filename( qw/ IDEtabFrame.pm CaptureRelease.pm /){
	my $textFileFrame = $dtf->add(
		-caption => $filename,
		-label   => $filename,
	);
	
	my $textFile = createTextWindow($TOP, $filename);
	$textFile->pack( -anchor => 'w', -in => $textFileFrame, -expand => 1, -fill => 'both');
        
        push @textWidgets, $textFile;
}
##############################################################

$dtf->pack(-expand => 1, -fill => 'both');

# After 2 seconds, delete the tab and make a toplevel.
$TOP->after(2000, sub{
                my $contents = $textWidgets[0];
                $dtf->delete("IDEtabFrame.pm");
                
                print "Releasing IDEtabFrame.pm tab to a toplevel...\n";
                
                $contents->wmRelease;
 
                # MainWindow needed here because wmReleased widget don't properly inherit from
                #   Tk::Toplevel
                $contents->MainWindow::attributes(-toolwindow => 1) if( $^O =~ /mswin32/i);
                $contents->MainWindow::title("IDEtabFrame.pm");
                $contents->MainWindow::deiconify;
                $contents->raise;
});
          


# After 2 seconds, put back as a tab
$TOP->after(4000, sub{
                
                print "Capturing IDEtabFrame.pm back as a tab...\n";
                
                my $newFrame = $dtf->add(
                        -caption => 'IDEtabFrame.pm',
                        -label =>   'IDEtabFrame.pm',
                        );
                
                
                # If the source is a toolwindow, capture the window (i.e. make it a non-toplevel again)
                my $contents = $textWidgets[0];

                $contents->wmCapture;
                
                $contents->pack( -anchor => 'w', -in => $newFrame, -expand => 1, -fill => 'both');
                $contents->raise();

});
                

# Quit the test after two seconds
unless( $dontExit){
    $TOP->after(6000,sub{
            print "Test Complete... Exiting\n";
            $TOP->destroy;
    });
}



Tk::MainLoop();


print "ok 1\n";
