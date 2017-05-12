#!/usr/bin/perl -w
################################################################################
#  File : demo_06.pl                                                           #
#  Class driver / testing code                                                 #
#  We create here an WizardMaker with some predefined pages described as       #
#  XML elements                                                                #
#                                                                              #
#  This demo is just like demo_01, but we want to demonstrate how to use       #
#  some API methods, like get_page_element and configure_tk_element.           #
#  (we use them in gui_06.xml - in page 'FirstText')                           #
#                                                                              #
################################################################################

use Tk;
use Tk::XML::WizardMaker;

# initialize a new WizardMaker instance.
# As template is used the default file gui.xml in current directory

my $mw = MainWindow->new();
my $w  = $mw->WizardMaker(-gui_file=>'gui_06.xml');

# add all generic pages as described in default file "gui.xml" in the same
# directory. The installation procedure self is described in the
# pre_next_button_code of the page labeled as "StartInstallation"

$w->add_all_pages();
$w->show();

# lets go
print "\nStart Main loop ...\n";
MainLoop;
print "\nStop Main loop\n";
