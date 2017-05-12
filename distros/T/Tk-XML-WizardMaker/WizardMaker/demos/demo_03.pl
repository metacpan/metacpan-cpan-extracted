#!/usr/bin/perl -w
################################################################################
#  File : demo_03.pl                                                           #
#  Class driver / testing code                                                 #
#  We create here an WizardMaker with some predefined pages described as       #
#  XML elements.                                                               #
#                                                                              #
#  In addition we want to set individual images for every page.                #
#  All the magie is still in XML file!                                         #
#                                                                              #
################################################################################

use Tk;
use Tk::XML::WizardMaker;
use Tk::Pane;

# initialize a new WizardMaker instance.
# As template is used the file gui_03.xml in current directory
# This is the only difference from demo_01.pl
my $mw = MainWindow->new();
my $w  = $mw->WizardMaker(-gui_file=>'gui_03.xml');

# add all generic pages as described in default file "gui.xml" in the same
# directory. The installation procedure self is described in the
# pre_next_button_code of the page labeled as "StartInstallation"
$w->add_all_pages();

# lets go
$w->show();

print "\nStart Main loop ...\n";
MainLoop;
print "\nStop Main loop\n";

