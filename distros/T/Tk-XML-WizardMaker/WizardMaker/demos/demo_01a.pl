#!/usr/bin/perl -w
################################################################################
#  File : demo_01a.pl                                                           #
#  Class driver / testing code                                                 #
#  We create here an WizardMaker with some predefined pages described as        #
#  XML elements.                                                               #
#                                                                              #
#  In addition we want to manual control variables and values in all pages.    #
#                                                                              #
################################################################################
package demo_01a;
use English;

use Tk;
use Tk::XML::WizardMaker;
use Tk::Pane;

# initialize a new WizardMaker instance.
# As template is used the file gui_01a.xml in current directory
my $mw = MainWindow->new();
my $w  = $mw->WizardMaker(-gui_file=>'gui_01a.xml', -opt_file=>'opt_01a.xml');

# add all generic pages as described in file "gui_01a.xml"
$w->add_all_pages();

# lets go
$w->show();

print "\nStart Main loop ...\n";
MainLoop;
print "\nStop Main loop\n";

# print out all settings
print_summary();


###############################################################################
# Print a summary of selected options at the end                              #
###############################################################################
sub print_summary{

  return if $w->get_common_element('status') eq 'CANCELED';

  my $outstring =
    "\n  Installation Settings:" .
    "\n  ======================" .
    "\n  Name      : " . $w->gui_option('Name') .
    "\n  Company   : " . $w->gui_option('Company') .
    "\n  Host      : " . $w->gui_option('Host') ;

  if ( defined $w->gui_option(FindDir)){
    $outstring .= "\n  Directory : " . $w->gui_option('FindDir');
  }

  if ( defined $w->gui_option(FindFile)){
    $outstring .= "\n  File      : " . $w->gui_option('FindFile');
  }

  $outstring .=
    "\n  Setup Type: " . $w->gui_option('SetupType') .
    "\n\n  Software Components to install: ";

  if ( defined $w->gui_option(InstallJava) and $w->gui_option(InstallJava) ){
    $outstring .= "\n    Java JRE/SDK";
  }
  if ( defined $w->gui_option(InstallPerl) and $w->gui_option(InstallPerl) ){
    $outstring .= "\n    Perl";
  }
  if ( defined $w->gui_option(InstallOffice) and $w->gui_option(InstallOffice) ){
    $outstring .= "\n    Office Suite";
  }
  if ( defined $w->gui_option(InstallDings) and $w->gui_option(InstallDings) ){
    $outstring .= "\n    Dings da Application Service";
  }
  if ( defined $w->gui_option(InstallDB) and $w->gui_option(InstallDB) ){
    $outstring .= "\n    Oracle Database";
  }
  if ( defined $w->gui_option(InstallSpecial) and $w->gui_option(InstallSpecial) ){
    $outstring .= "\n    Special Options";
  }

  print  "\n", $outstring, "\n";
}
