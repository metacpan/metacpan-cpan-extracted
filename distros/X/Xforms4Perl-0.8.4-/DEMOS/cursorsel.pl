#!/usr/bin/perl
use X11::Xforms;

# Display a popup with all cursors - return the selected one

fl_initialize("CursorChooser");

open(XC, "/usr/X11/include/X11/cursorfont.h");
@lines = <XC>;
close XC;

while ($line = shift(@lines))
{
	if ($line =~ /#define\s*(XC_\w*)\s*(\d*)\s*$/)
	{
		if ($1 ne "XC_num_glyphs")
		{
			$cname[$i]   = $1;
			$wdth = $cname[$i] if ($wdth < length($cname[$i]));
			$cnmbr[$i++] = $2;
		}
	}
}

exit(-1) if ($#cname < 1); 

$form = fl_bgn_form(FL_NO_BOX, 200, 400);
$browser = fl_add_browser(FL_HOLD_BROWSER,0,0,200,400,"");
    fl_set_object_dblbuffer($browser, 1);
	fl_set_object_callback($browser, "set_cursor", 0);
	fl_set_browser_dblclick_callback($browser, "rtrn_cursor", 0);
fl_end_form;

while ($line = shift(@cname))
{
	fl_add_browser_line($browser,$line)
}


fl_show_form($form,FL_PLACE_MOUSE,FL_FULLBORDER,"Select a Cursor");

fl_do_forms();

exit -1;

sub set_cursor
{
	my($obj, $data) = @_;
	fl_set_cursor($obj->window, $cnmbr[$item-1]) 
		if (($item = fl_get_browser($obj)) > 0);

}

sub rtrn_cursor
{
	my($obj, $data) = @_;
	$item = fl_get_browser($obj);
	if ($item > 0) 
	{
		exit($cnmbr[$item-1]);
	}
	else
	{
		exit(-1);
	}
}

