#!/usr/local/bin/perl -w
######################################## SOH ###########################################
## Function : Enhancement for Tk:Button (flexible handling of TEXT AND IMAGE)
##
## Copyright (c) 2002-2009 Michael Krause. All rights reserved.
## This program is free software; you can redistribute it and/or modify it
## under the same terms as Perl itself.
######################################## SOH ###########################################

##############################################
### Use
##############################################
use strict;
use FindBin;
# graphical stuff
use Tk;
use Tk::CompoundButton;

##########################################################
# setup some resources to see their influence
Tk::CmdLine::LoadResources(-file => $FindBin::Bin . '/test.xrdb', -priority => 'userDefault');


##########################################################
# Create a new TopLevelWidget
my $mw = MainWindow::->new;
$mw->optionClear;
$mw->optionReadfile('./xresource.xrdb', 'userDefault');
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

my $downangle = $mw->Pixmap( -data => $downangle_data);


##########################################################
# Creation procedures
##########################################################
	my $var = "bttn-text - lx1\nline 2\nline 3";
	my $bt3 = $mw->Button(
		-text => 'Change_Text_Ref',
		-command => sub { $var = 'hello world now'},
	)->pack;

$mw->title("Test");
	my $bt1 = $mw->CompoundButton(
		#-padx => '45m',
		#-padx => -1,
		-text => 'Enable',
		-image => $downangle,
        #-bitmap => 'error',
		-command => \&bttn_pressed_cb1,
		#-borderwidth => '12',
		#-relief => 'ridge',
 		-bg => 'orange',
		-fg => 'green',
 		-textvariable => \$var,
 		-side => 'bottom',
# 		-side => 'bottom',
#		-side => 'top',
#		-side => 'left',
# 		-activebackground => 'red',
# 		-activeforeground => 'blue',
		-width => 200,
		#-height => 200,
#-anchor => 'sw',
#-anchor => 'e',
#-justify => 'right',
		-gap => 20,
		-textjustify => 'right',
	)->pack(-padx => 50, -pady => 50);
	my $bt2 = $mw->Button(
		-text => 'Disable',
		-command => [\&bttn_pressed_cb2, $bt1],
		#-image => $downangle,
	)->pack;


#	
MainLoop();


sub bttn_pressed_cb1
{
	print "bttn_pressed_cb1: hello world 1: [@_]\n";
	
}
sub bttn_pressed_cb2
{
	print "bttn_pressed_cb2: hello world 2: [@_]\n";
	my $new_state = $_[0]->cget('-state');
	$_[0]->configure(-state => $new_state eq 'normal' ? 'disabled' : 'normal');
	# just for demo purposes use the global var instead of a more complicated deref'ing
	$new_state =~ s/d$//; 
	$bt2->configure(-text => ucfirst($new_state) );
}


###
### EOF
###

