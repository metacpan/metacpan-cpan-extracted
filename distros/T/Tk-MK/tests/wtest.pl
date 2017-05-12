#!/home/opcdev/local/bin/perl -w

##############################################
### Use
##############################################
use strict;

# graphical stuff
use Tk;
use Tk::widgets qw/LabFrame TList Optionmenu Tree NoteBook ROText Adjuster DialogBox BrowseEntry Text ProgressBar/;
use Tk qw(Ev);

# Personal Add-On Classes
use Tk::Checkbox;
use Tk::Statusbox;

##############################################
# Common Variables
##############################################
our (%widgets, %settings, %xpms, %all_objects,
	@object_filters,
	);
########################################################################

# Create a new TopLevelWidget
my $mw = MainWindow::->new;

	#-------------------------------------
	my $upangle_data = <<'upangle_EOP';
	/* XPM */
	static char *cbxarrow[] = {
	"14 9 2 1",
	". c none",
	"X c black",
	"..............",
	"......XX......",
	".....XXXX.....",
	"....XXXXXX....",
	"...XXXXXXXX...",
	"..XXXXXXXXXX..",
	".XXXXXXXXXXXX.",
	"..............",
	"..............",
	};
upangle_EOP
	$xpms{upangle} = $mw->Pixmap( -data => $upangle_data);

	#-------------------------------------
	my $downangle_data = <<'downangle_EOP';
	/* XPM */
	static char *cbxarrow[] = {
	"14 9 2 1",
	". c none",
	"X c black",
	"..............",
	"..............",
	".XXXXXXXXXXXX.",
	"..XXXXXXXXXX..",
	"...XXXXXXXX...",
	"....XXXXXX....",
	".....XXXX.....",
	"......XX......",
	"..............",
	};
downangle_EOP
	$xpms{downangle} = $mw->Pixmap( -data => $downangle_data);

	#-------------------------------------
	my $check_data = <<'check_EOP';
	/* XPM */
	static char *checkdt[] = {
	"16 16 2 1",
	". c none",
	"X c black",
	"...............X",
	"..............X.",
	".............XX.",
	"............XX..",
	"...........XX...",
	"...........XX...",
	"..........XX....",
	".........XX.....",
	"X.......XX......",
	"XXX....XX.......",
	"XXXX..XXX......X",
	"XXX.XXXX.......X",
	"..XXXXX........X",
	"...XXXX........X",
	"....XX.........X",
	"....X...XXXXXXXX",
	
	};
check_EOP
	$xpms{check} = $mw->Pixmap( -data => $check_data);

#$mw->configure ( -bg => 'yellow');
##########################################################
# Creation procedures
##########################################################
my $var = 0;
my $var2 = 0;
my $mycolor = 'red';
$mw->title("Test");
	my $bt1 = $mw->Button(
		-text => 'Enable',
		-command => \&bttn_pressed_cb1,
	)->pack;
	my $bt2 = $mw->Button(
		-text => 'Disable',
		-command => \&bttn_pressed_cb2,
	)->pack;
	my $bt3 = $mw->Statusbox(
#		-command => \&bttn_pressed_cb3,
		-bg => 'blue',	
		-flashintervall => '100',
		#-relief => 'sunken',
		-height => '30',
		-width => '50',
		-variable => \$mycolor,
	)->pack;

	my ($statusline) = $mw->Label (
		-borderwidth => '2',
		-relief => 'sunken',
		-font => '-*-helvetica-Medium-R-Normal-*-*-120-*-*-*-*-*-*',
		-height => '1',
		-width => '25',
		-text => 'Ready.',
		-anchor => 'sw',
	)->pack(
		-side => 'bottom',
		-expand => '1',
		-fill => 'both',
		-anchor => 'w',
	);
	my($frame) = $mw->Frame (
		-borderwidth => '2',
		-relief => 'groove',
	)->pack(
		-expand => '1',
		-fill => 'x',
	);
	
#	my $order_button = $frame->Checkbutton (
#		-font => '-*-helvetica-Medium-R-Normal-*-*-100-*-*-*-*-*-*',
#		#-image => $xpms{downangle},
#		#-selectimage => $xpms{check},
#		-selectcolor => $mw->cget(-bg),
#		-indicatoron => '0',
#		-command => \&test_cb,
#		-relief => 'flat',
#		-borderwidth => '0',
#		-highlightthickness => '0',
#		-onvalue => 'Up',
#		-offvalue => 'Down',		
#	)->pack(
#		-side => 'left',
#	);
my %tests =();

	my $cb1 = $frame->Checkbox (
#		-variable => \$var,
		-variable => \$tests{xxx},
		-command => \&test_cb,
#		-state => 'disabled',
		-bg => 'yellow',	

	)->pack(
		-side => 'left',
	);
	$var2 = 'Up';
	my $cb2 = $frame->Checkbox (
		-variable => \$var2,
		-command => \&test_cb2,
		-onvalue => 'Up',
		-offvalue => 'Down',
		-bg => 'blue',	
		-fg => 'yellow',	

	)->pack(
		-side => 'right',
	);

$cb1->configure( -state => 'disabled');
$cb1->configure( -bg => 'red');

#	
MainLoop();

sub test_cb
{
	print "test_cb: hallo: [@_], \$var = >$var<\n";
	$var2 = $var;
	#$bt3->color('green');
	$mycolor = 'orange';
	
}

sub test_cb2
{
	print "test_cb2: hallo: [@_], \$var2 = >$var2<\n";
	$var = $var2;
	#$bt3->color('red');
	$bt3->clear();
}

sub bttn_pressed_cb1
{
	print "bttn_pressed_cb1: hallo: [@_], \$var = >$var< \$var2 = >$var2<\n";
	$cb1->configure( -state => 'normal');
	#$cb2->configure( -state => 'normal');
	$bt3->flash('END');
	
}
sub bttn_pressed_cb2
{
	print "bttn_pressed_cb2: hallo: [@_], \$var = >$var< \$var2 = >$var2<\n";
	$cb1->configure( -state => 'disabled');
	#$cb2->configure( -state => 'disabled');
	$bt3->flash('START');
}
sub bttn_pressed_cb3
{
	print "bttn_pressed_cb3 reached.\n";
}
