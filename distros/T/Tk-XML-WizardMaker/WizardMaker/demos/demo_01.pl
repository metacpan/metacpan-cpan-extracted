#!/usr/bin/perl -w
################################################################################
#  File : demo_01.pl                                                           #
#  Class driver / testing code                                                 #
#  We create here an WizardMaker with some predefined pages described as       #
#  XML elements                                                                #
################################################################################

use Tk;
use Tk::XML::WizardMaker;

# initialize a new WizardMaker instance.
# As template is used the default file gui.xml in current directory

my $mw = MainWindow->new();
my $w  = $mw->WizardMaker();

# add all generic pages as described in default file "gui.xml" in the same
# directory.
$w->build_all();

# lets go
print "\nStart Main loop ...\n";
MainLoop;
print "\nStop Main loop\n";
