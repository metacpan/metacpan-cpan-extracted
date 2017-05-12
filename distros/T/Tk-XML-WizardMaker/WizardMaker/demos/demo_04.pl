#!/usr/bin/perl -w
################################################################################
#  File : demo_04.pl                                                           #
#  Class driver / testing code                                                 #
#  We create here an Asisstent with some predefined pages described as       #
#  XML elements.                                                               #
#                                                                              #
#  In addition we want to manual control variables and values in all pages.    #
#                                                                              #
################################################################################
package demo_04;
use English;

use Tk;
use Tk::XML::WizardMaker;
use Tk::Pane;

# initialize a new WizardMaker instance.
# As template is used the file gui_04.xml in current directory
my $mw = MainWindow->new();
my $w  = $mw->WizardMaker(-gui_file=>'gui_04.xml');

# add all generic pages as described in default file "gui_04.xml"
$w->add_all_pages();

# Now we want to set some default values.
# 1. LabeledEntriesPage. We reference LabeledEntry name attribute
#    for each LabeledEntry
# Set some values in Page 'SecondLabaledEntries'
$w->gui_option('Name',    'your Name');
$w->gui_option('Company', 'your Company Name');
$w->gui_option('Host', get_host_name());

# 2. RadioButtonPage. We reference variable attribute for the page
# Set choise in Page 'SetupType' to install
$w->gui_option('SetupType', 'install');

# 3. CheckButtonPage. We reference name attribute for each CheckButton
# Set some values in Page 'SelectComponents'
$w->gui_option('InstallJava'   , '0');
$w->gui_option('InstallPerl'   , '1');
$w->gui_option('InstallDB'     , '1');
$w->gui_option('InstallSpecial', '1');

# lets go
$w->show();

print "\nStart Main loop ...\n";
MainLoop;
print "\nStop Main loop\n";

# print out all settings
print_summary();


###############################################################################
# Proof whether all values where set right in a page.                         #
# Attention! If pre_xxxx_button_code returns with 1, no page switch occures!  #
#            The method show_message  with 'warning' in second parameter      #
#            returns allways 1.                                               #
###############################################################################
sub SecondLabaledEntries_pre_next_button_code{

  return $w->show_message('Name is required!', 'warning')
    unless ($w->gui_option('Name'));

  return $w->show_message('Company is required!', 'warning')
    unless ($w->gui_option('Company'));

  $w->gui_option('Host', get_host_name()) unless ($w->gui_option('Host'));

  return 1;
}

###############################################################################
# an auxilary function to get host name dynamically                           #
###############################################################################
sub get_host_name{
  return $ENV{COMPUTERNAME} if ($OSNAME eq "MSWin32");
  return $ENV{HOSTNAME}     if ($OSNAME eq "linux");
  return "localhost";
} #sub

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
