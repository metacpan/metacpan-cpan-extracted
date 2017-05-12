###############################################################################
# Before `make install' is performed this script should be runnable with      #
# `make test'. After `make install' it should work as `perl 1.t'              #
###############################################################################

use strict;
use English;

use Test;
BEGIN {  plan tests => 8, };

# tests for depending packages
ok('use 5.0');
ok('use Tk');
ok('use XML::Simple');
ok('use Storable');
ok('use Tk::XML::WizardMaker');

skip($OSNAME ne "MSWin32", 'use Win32');
skip($OSNAME ne "MSWin32", 'require Win32API::File');

ok( sub {
      use Tk;
      use Tk::XML::WizardMaker;

      # tests for buil assistent and configure some options
      my $page = {
	name              =>'PageOne',
	type              =>'TextPage',
	status            =>'valid',
	title             =>"MyTestPage",
	subtitle          =>"xxx",
	text              =>"xxx",
	help_text         =>"No Help",
      };

      my $wizard_desc = {
	title => 'Test',
	page => [ $page ],
      };

      my $mw = MainWindow->new();
      my $w  = $mw->WizardMaker(-gui=>$wizard_desc);

      $w->build_all();

      my $x = $w->get_page_element('PageOne', 'summary_text');
      $w->configure_tk_element($x, (-bg=>'blue', -fg=>'red', -state=>'normal'));
      $x->insert('end', 'Hallo');
      return 0 unless ($w->cget_tk_element($x, '-fg') eq 'red');

      # no main loop - we do not want interaction here
      #MainLoop;
      # destroy object
      $w = {};
      return 1;
    }, 1
   );


