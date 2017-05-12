#!/usr/bin/perl -w
################################################################################
#  File : demo_03.pl                                                           #
#  Class driver / testing code                                                 #
#  We create here an WizardMaker with some predefined pages described as       #
#  XML elements.                                                               #
#                                                                              #
#  This demo is identical with demo_03 with exception that we want to control  #
#  pictures for tthe mages more dynamically.                                   #
#                                                                              #
#  When a page is being rendered, 2 callback subs are fired:                   #
#                                                                              #
#    1. pre_display_code                                                       #
#    2. render page                                                            #
#    3. post_display_code                                                      #
#                                                                              #
#  So it seems to be a good idea to place the image setting code in 1. or 3.   #
#  But it can be a place for any code setting display elements. So we set      #
#  the 'Name' to be equal 'Bilbo'. Too simple becourse the user can not        #
#  effecient change it :-). But is must be only a demo. See demo_05 for        #
#  more information on how to handle the default walues.                       #
#                                                                              #
################################################################################

use Tk;
use Tk::XML::WizardMaker;
use Tk::Pane;

# initialize a new WizardMaker instance.
# As template is used the file gui_03.xml in current directory
# This is the only difference from demo_01.pl
my $mw = MainWindow->new();
my $w  = $mw->WizardMaker(-gui_file=>'gui_03a.xml');

# add all generic pages as described in default file "gui.xml" in the same
# directory. The installation procedure self is described in the
# pre_next_button_code of the page labeled as "StartInstallation"
$w->add_all_pages();

# lets go
$w->show();

print "\nStart Main loop ...\n";
MainLoop;
print "\nStop Main loop\n";

