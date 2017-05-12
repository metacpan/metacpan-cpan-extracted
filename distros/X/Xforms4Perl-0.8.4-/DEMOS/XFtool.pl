#!/usr/bin/perl
use X11::Xforms;
#
# Example (and test) of the use of Xforms from PERL!!
#
# This PERL script is deliberately incomplete (well thats my excuse anyway!!).
#
# It is also rather messy - it SHOULD use PERL OO style programming, but
# doesn't.
#
# So what does it do? Well, it manages a toolbar in a similar fashion to
# MS Office. You can add tools, move them around, and delete them. 
#
# Enhancements since the first version:
#	Tooltips courtesy of fl_show_oneliner
#	Command Line and Pixmap file browsing when editting tools
#		along with extra buttons on the pixmap browser to
#		allow you to create your own pixmaps or edit existing
#		ones (via xpaint)
# 
# And what is left to do? Well, firstly it puts itself at the top of the
# screen without Window Manager adornment - this is either desirable  
# (in which case leave it) or not - in which case either change the 
# fl_show_forms for $toolform - or be a bit more clever and add an option
# to the Control panel). And there is NO help whatsoever. That should be a
# simple browser loaded with a file.
#
# You might also want to make it save the options you change. I have added
# the PERL code necessary to recognize resources in the name xftoolxxxxx.
# this is an example of how to do the option/resource processing available
# in XForms when you code an application in perl. Add/remove what you will
# to customize as you see fit.
#
# By and large, however, the basics are there.
#
# So why leave it incomplete? Three reasons:
#
# 	1) I promised some people this wonder-package by a certain date
#          and its going to be late already!
#       2) The bits that need adding are definately up to user taste
#       3) It gives you an exercise in using Xforms with PERL.
#
#
# THE PROGRAM USES WHICH TO LOCATE TOOL EXECUTABLES. IF YOUR SYSTEM DOES NOT
# HAVE WHICH, SUBSTITUTE WHAT EVER PROGRAM SEARCHES FOR A BINARY IN YOUR
# PATH STATEMENT - OR BUILD ONE!!
#
$which = "which";
#
# Good luck.
#
#

use X11::Xforms;

$BUTTONSIZE=38;
$PIXEDITOR="xpaint -size '30x30' ";
$executor="Exec:Execute a program:$ENV{'X11HOME'}/include/X11/pixmaps/XFexec.xpm:1";
$controler="Cntl:Configure the Toolbar:$ENV{'X11HOME'}/include/X11/pixmaps/XFcntl.xpm:2";
@inttools = ($executor, $controler);
@internal = (\&run_executor, \&run_controller);
$controlform = 0;
$editform = 0;
$tbrws = 0;
$sel = 0;
$exec_fsel = 1;
$pix_fsel = 0;
@edit_tool_text = (0,0,0);

$SIG{"CHLD"} = "IGNORE";

open(TOOLS, "$ENV{HOME}/.XFtools");
@toolbar = <TOOLS>;
close TOOLS;
@buttons = ();

while($toolbar[0] =~ /^OPTS:/) {
        ($dummy, $opt) = split(/:/, shift(@toolbar));
	eval ($opt) if (!$a);
	push (@options, "OPTS:$opt");
}

chop(@toolbar);
fl_initialize('Toolbar');
$scrw = fl_scrw();
$toolform = "FIRST";
build_toolbar();
fl_do_forms();

sub button_callback {

	my($obj, $parm) = @_;
	my(@exectools) = (@toolbar, @inttools);
	my($name, $longname, $pixpath, $cmdpath) = 
		split(/:/, $exectools[$parm]);

	$button = fl_get_button_numb($obj);

	if ($cmdpath > 0) {
		fl_deactivate_form($toolform);
		&{$internal[$cmdpath-1]}();
		fl_activate_form($toolform);
	} else {
		if (system("$which $cmdpath > /dev/null") != 0 &&
		   ! -f "$cmdpath") {

			fl_show_alert("Program not found", "$cmdpath cannot be found","", 0);
		} else {
			exec ($cmdpath) if (!fork());
		}
	}
}

sub group_callback {
	my($obj, $group) = @_;
	print "in $group\n";
}

sub post
{
	my($ob, $ev, $mx, $my, $key, $xev) = @_;
	if($ev == FL_ENTER)
	{
		my(@exectools) = (@toolbar, @inttools);
		my($name, $longname, $pixpath, $cmdpath) = 
			split(/:/, $exectools[$ob->u_ldata]);
		my($ox, $oy, $ow, $oh, $form) = 
			(fl_get_object_geometry($ob), $ob->form);
		$strs = fl_get_string_width(FL_DEFAULT_SIZE, 
					    FL_NORMAL_STYLE,
					    $longname,
					    length($longname));
		$olx = $ox + $form->x + 2;
		fl_show_oneliner($longname, $olx, 
					    $oy + $form->y + 1 + $oh); 
	}
	elsif($ev == FL_LEAVE){
		fl_hide_oneliner();
	}
	return 0;
}

sub run_controller {
	if (!$controlform) {
		$controlform = fl_bgn_form(FL_NO_BOX, 320, 265);
		fl_add_box(FL_UP_BOX,0,0,320,265,"");
		$tbrws = fl_add_browser(FL_HOLD_BROWSER,10,15,150,240,"");
			fl_set_object_callback($tbrws, "set_selected", 1);
		$cntlok = fl_add_button(FL_NORMAL_BUTTON,220,15,90,30,"OK");
		$cntlcan = fl_add_button(FL_NORMAL_BUTTON,220,50,90,30,"Cancel");
		$obj = fl_add_button(FL_NORMAL_BUTTON,220,85,90,30,"Add tool");
			fl_set_object_callback($obj, "edit_tool", 1);
		$obj = fl_add_button(FL_NORMAL_BUTTON,170,65,40,60,'@8->');
			fl_set_object_lcol($obj,FL_BLUE);
			fl_set_call_back($obj, "move_tool_up", 1);
		$obj = fl_add_button(FL_NORMAL_BUTTON,170,145,40,60,'@8<-');
			fl_set_object_lcol($obj,FL_BLUE);
			fl_set_call_back($obj, "move_tool_down", 1);
		$obj = fl_add_button(FL_NORMAL_BUTTON,220,155,90,30,"Delete Tool");
			fl_set_call_back($obj, "delete_tool", 1);
		$obj = fl_add_button(FL_NORMAL_BUTTON,220,120,90,30,"Edit tool");
			fl_set_call_back($obj, "edit_tool", 0);
		$obj = fl_add_button(FL_NORMAL_BUTTON,220,190,90,30,"Help");
		$obj = fl_add_button(FL_NORMAL_BUTTON,220,225,90,30,"Quit XFtool");
			fl_set_call_back($obj, "exit_xftool", 0);
		fl_end_form();
	}

	fl_clear_browser($tbrws);
	$browser_lines = 0;
	foreach $tool (@toolbar) {
		($name, $longname, $pixpath, $cmdpath) = split(/:/, $tool);
		fl_add_browser_line($tbrws, $longname);
		$browser_lines++;
	}

	$changes = 0;
	@worktoolbar = @toolbar;
	fl_show_form($controlform, 
		     FL_PLACE_POSITION, 
		     FL_FULLBORDER, 
		     "Tool Control");
	if ($cntlok == fl_do_forms() && $changes) {
		@toolbar = @worktoolbar;
		open(TOOLS, ">$ENV{HOME}/.XFtools");
		$" = "\n";
		print TOOLS "$options" if ($options);
		print TOOLS "@toolbar\n";
		close TOOLS;
		build_toolbar();
	}
	fl_hide_form($controlform);
}

sub move_tool_up {
	
	if ($sel > 1) {
		$oldline = fl_get_browser_line($tbrws, $sel-1);
		$selline = fl_get_browser_line($tbrws, $sel);
		fl_replace_browser_line($tbrws, $sel-1, $selline);
		fl_replace_browser_line($tbrws, $sel, $oldline);
		fl_select_browser_line($tbrws, $sel-1);
		$temp = $worktoolbar[$sel-1];
		$worktoolbar[$sel-1] = $worktoolbar[$sel-2];
		$worktoolbar[$sel-2] = $temp;
		$changes = 1;
		--$sel;
	}

}

sub move_tool_down {

	if ($sel < $browser_lines) {
		$oldline = fl_get_browser_line($tbrws, $sel+1);
		$selline = fl_get_browser_line($tbrws, $sel);
		fl_replace_browser_line($tbrws, $sel+1, $selline);
		fl_replace_browser_line($tbrws, $sel, $oldline);
		fl_select_browser_line($tbrws, $sel+1);
		$temp = $worktoolbar[$sel-1];
		$worktoolbar[$sel-1] = $worktoolbar[$sel];
		$worktoolbar[$sel] = $temp;
		$changes = 1;
		++$sel;
	}
}

sub delete_tool {

	if ($sel) {
		fl_delete_browser_line($tbrws, $sel);
		fl_deselect_browser_line($tbrws, $sel);
		splice(@worktoolbar, $sel-1, 1);
		$changes = 1;
		$browser_lines--;
		$sel = 0;
	}
}

sub set_selected {

	$sel = fl_get_browser($tbrws);
}

sub run_executor {

	fl_use_fselector($exec_fsel);
	my($fsel) = fl_get_fselector_fdstruct();
	my($readybut, $fselform) = 
		($fsel->ready(), $fsel->fselect());
	print "$fsel, $readybut, $fselform\n";
	fl_set_form_title($fselform, "Execute a Command");
	fl_set_object_label($readybut, "Execute");
	$cmdpath = fl_show_fselector("Enter the command you want to execute",
				     "$ENV{X11HOME}/bin",
				     "",
				     "");

        if (-f $cmdpath) {
		exec ($cmdpath) if (!fork());
	}
}

sub edit_tool {

	my($obj, $editadd) = @_;

	if (!$editform) {
		@errstring = (
			"Tool name must be non-blank",
			"Short name must be non-blank",
			"Command line is invalid",
			"Pixmap path is invalid");
  		$editform = fl_bgn_form(FL_NO_BOX, 320, 215);
  		fl_add_box(FL_UP_BOX,0,0,320,215,"");
                $edittln = fl_add_input(FL_NORMAL_INPUT,10,25,110,25,"Tool Name");
                        fl_set_input_scroll($edittln, 0);
                        fl_set_object_callback($edittln, "edit_callback", 0);
                        fl_set_object_lalign($edittln,FL_ALIGN_RIGHT);
                $edittls = fl_add_input(FL_NORMAL_INPUT,190,25,40,25,"Short Name");
                        fl_set_input_scroll($edittls, 0);
                        fl_set_object_callback($edittls, "edit_callback", 0);
                        fl_set_object_lalign($edittls,FL_ALIGN_RIGHT);
  		fl_add_text(FL_NORMAL_TEXT,5,55,125,15,"Command Line:");
  		$editcmd = fl_add_input(FL_NORMAL_INPUT,10,70,220,25,"");
			fl_set_object_callback($editcmd, "edit_callback", 0);
   			fl_set_object_lalign($editcmd,FL_ALIGN_RIGHT);
			$edit_tool_text[1] = $editcmd;
  		my($ob) = fl_add_button(FL_NORMAL_BUTTON,235,70,75,25,"Browse");
			fl_set_object_callback($ob, "edit_callback", 1);
  		fl_add_text(FL_NORMAL_TEXT,5,100,125,15,"Pixmap Path:");
  		$editpix = fl_add_input(FL_NORMAL_INPUT,10,115,220,25,"");
			fl_set_object_callback($editpix, "edit_callback", 0);
   			fl_set_object_lalign($editpix,FL_ALIGN_TOP_LEFT);
			$edit_tool_text[2] = $editpix;
  		$ob = fl_add_button(FL_NORMAL_BUTTON,235,115,75,25,"Browse");
			fl_set_object_callback($ob, "edit_callback", 2);
  		$editok = fl_add_button(FL_NORMAL_BUTTON,10,175,80,30,"OK");
  		$editcan = fl_add_button(FL_NORMAL_BUTTON,120,175,80,30,"Cancel");
  		$edithlp = fl_add_button(FL_NORMAL_BUTTON,230,175,80,30,"Help");
  		fl_add_text(FL_NORMAL_TEXT,5,145,125,25,"Enter tool button details");
  		$errtext = fl_add_text(FL_NORMAL_TEXT,140,145,175,25,"");
  			fl_set_object_lcol($errtext,FL_RED);
   			fl_set_object_lalign($errtext,FL_ALIGN_RIGHT);
  		fl_end_form();
	}

	if ($editadd) {
		fl_set_input($edittln, "");
		fl_set_input($edittls, "");
		fl_set_input($editcmd, "");
		fl_set_input($editpix, "");
		$edittitle = "Define new Tool";
	} elsif ($sel) {
		my($short,$long,$pix,$cmd) = 
			@edititem = split(/:/,$worktoolbar[$sel-1]);
		fl_set_input($edittln, "$long");
		fl_set_input($edittls, "$short");
		fl_set_input($editcmd, "$cmd");
		fl_set_input($editpix, "$pix");
		$edittitle = "Edit Tool";
	} else {
		return;
	}
	fl_deactivate_form($controlform);

	fl_show_form($editform, 
		     FL_PLACE_MOUSE, 
		     FL_FULLBORDER, 
		     "$edittitle");
	until (($tempbutton = fl_do_forms()) == $editcan) { 
		$editerror = 0;
		if ($tempbutton == $editok) {
			@edititem = (fl_get_input($edittls),
			             fl_get_input($edittln),
			             fl_get_input($editpix),
			             fl_get_input($editcmd));
			$editerror == 4 if ($edititem[3] =~ /^\s*$/);
			$editerror == 3 if ($edititem[2] =~ /^\s*$/);
			$editerror == 2 if ($edititem[1] =~ /^\s*$/);
			$editerror == 1 if ($edititem[0] =~ /^\s*$/);

			if (!$editerror) {
				$newtool = join(':', @edititem);
				$changes = 1;
				if($editadd) { 
					$placement = $sel ? $sel : 1;
					splice(@worktoolbar,$placement-1,0,$newtool);
					fl_insert_browser_line($tbrws, $placement, $edititem[1]);
					$browser_lines++;
				} else {
					splice(@worktoolbar,$sel-1,1,$newtool);
					fl_replace_browser_line($tbrws, $sel, $edititem[1]);
				}
			last;
			}

		}
		fl_set_object_label($errtext, $errstring[$editerror]);
	}
	fl_hide_form($editform);
	fl_activate_form($controlform);
}

sub edit_callback {

	my($obj, $parm) = @_;

	if($parm) {
		fl_deactivate_form($editform);

		fl_use_fselector($parm);

		if ($parm == 1) {
			$path = fl_show_fselector("Enter the path of the new tool",
						     "$ENV{X11HOME}/bin",
						     "",
						     "");
		} else {
			if (!$pix_fsel) {
				fl_add_fselector_appbutton("Create", "create_pixmap", 0);
				fl_add_fselector_appbutton("Edit", "edit_pixmap", 1);
				$pix_fsel = 2;
			}
			$path = fl_show_fselector("Enter the path of the tool's pixmap",
						     "$ENV{X11HOME}/include/X11/pixmaps",
						     "",
						     "");
		}
		fl_set_input($edit_tool_text[$parm], $path) if ($path);
		fl_activate_form($editform);
	}

}

sub create_pixmap {

	fl_deactivate_form(fl_get_fselector_form());
	`$PIXEDITOR`;
	fl_activate_form(fl_get_fselector_form());
	fl_refresh_fselector();
}

sub edit_pixmap {

	fl_deactivate_form(fl_get_fselector_form());
	my($dir, $file) = (fl_get_directory(), fl_get_filename());
	if($file && -f "$dir/$file"){
		`$PIXEDITOR $dir/$file`;
	}
	fl_activate_form(fl_get_fselector_form());
	fl_refresh_fselector();
}

sub build_toolbar {

	while(defined($button = pop(@buttons))) {
		fl_delete_object($button);
		fl_free_object($button);
	}

	if ($toolform ne "FIRST") {
		fl_hide_form($toolform);
		fl_free_form($toolform);
	}

	$toolbarl = (@toolbar+@inttools)*$BUTTONSIZE;

	$toolform = 
		fl_bgn_form(FL_UP_BOX, $toolbarl, $BUTTONSIZE);
	fl_set_form_position($toolform, $scrw-$toolbarl, 0); 

	$index = $pos = 0;
	foreach $tool (@toolbar, @inttools) {
		($name, $longname, $pixpath, $cmdpath) = split(/:/, $tool);
		if (-f $pixpath) {
			$obj = fl_add_pixmapbutton(FL_NORMAL_BUTTON, 
						   $pos, 0, 
						   $BUTTONSIZE, $BUTTONSIZE, 
						   $name);
			fl_set_pixmapbutton_file($obj, $pixpath);
		} else { 
			$obj = fl_add_button(FL_NORMAL_BUTTON, 
					     $pos, 0, 
					     $BUTTONSIZE, $BUTTONSIZE, 
					     $name);
		}
		fl_set_object_callback($obj, "button_callback", $index);
		fl_set_object_posthandler($obj, "post");
		$obj->u_ldata($index);

		$buttons[$index++] = $obj;
		$pos += $BUTTONSIZE;
	}
	fl_end_form();
	fl_show_form($toolform, 
		FL_PLACE_GEOMETRY, 
		FL_NOBORDER, 
		"Toolbar");
}

sub exit_xftool {
	fl_finish();
	exit(0);
}
