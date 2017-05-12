#!/usr/bin/perl
$|=1;
use X11::Xforms;   
use X11::XEvent;   
use Getopt::Long;

#
# A /proc system explorer - complete with tree-view and splitter bar!!!
# To make it a filesystem explorer run with the -fs switch.
#
$opt_fs = 0;

$result=GetOptions('fs');
die("Option Error\n") unless($result);

$procdir = "/proc" if (!$opt_fs);
$procdir = "/"     if ($opt_fs);
$procbrws = undef;
$$dtlsbrws = undef;
@procs     = undef;
@proctree = undef;
@procind  = undef;
$resizing = 0;

fl_initialize('Explorer');
create_form_main();
populate_proc();
fl_show_form($mainform,FL_PLACE_FREE,FL_FULLBORDER,
                       $opt_fs ? "Filesystem Explorer" : "Proc Filesystem Explorer");
while ($quit==0) {
	fl_do_forms();
}

sub populate_proc()
{
	@procs     = undef;
	@proctree = undef;
	@procind  = undef;
	opendir(PROC, $procdir) || die "Can't open $procdir\n";
    @procs = sort { 
			  return ($a <=> $b) if ($a > 0 && $b > 0);
			  return ($a cmp $b) if ($a == 0 && $b == 0);
			  return -1           if ($a == 0);
			  return 1;
			} (grep { !/^\./ } readdir(PROC));
	closedir PROC;

	my($sub) = 0;
	my(@tprocs) = @procs;
	foreach $proc (@procs) {
		if (-d "$procdir/$proc")
        {
			fl_add_browser_line($procbrws,"\@b+$proc");
			$proctree[$sub] = 0;
			$procind[$sub]  = 0;
			++$sub;
		}
		elsif ($opt_fs)
		{
			splice(@tprocs, $sub, 1);
			fl_add_browser_line($dtlsbrws,"$proc");
		}
		else
		{
			fl_add_browser_line($procbrws," $proc");
			$proctree[$sub] = 0;
			$procind[$sub]  = 0;
			++$sub;
		}
	}
	@procs = @tprocs;
}

sub ProcMenu {

	$menuitem = fl_get_menu($Menu);
	$selected = fl_get_browser($procbrws);
	if ($menuitem == $MENU_EXIT) {
		fl_finish();
		exit;
	} elsif ($menuitem == $MENU_REFR) {
		fl_freeze_form($mainform);
		fl_clear_browser($procbrws);
		fl_clear_browser($dtlsbrws);
		populate_proc();
		fl_unfreeze_form($mainform);
	} elsif ($menuitem == $MENU_DTLS && $selected > 0) {
		DblClickProc($procbrws, 0);
	} elsif ($menuitem == $MENU_KILL && $selected > 0) {
		$kill = $procs[$selected - 1];
		kill (9, $kill)  
			if fl_show_question("Are you sure you want to kill process number $kill?", 0);
	}

}

sub SelectProc
{
	fl_freeze_form($mainform);

	my($obj, $parm) = @_;
	my($line) = fl_get_browser($obj);
	my($procfile) = $procs[$line-1];
    my($procsubdir) = "$procdir/$procfile";
	if ($opt_fs)
	{
		fl_clear_browser($dtlsbrws);
		if (opendir(SUBD, $procsubdir))
		{
	    	my(@files) = sort (grep {!(-d "$procsubdir/$_") } readdir(SUBD));
			close SUBD;
			foreach $file (@files)
			{
				fl_add_browser_line($dtlsbrws," $file");
			}
		}
	}
	elsif (-d "$procsubdir")
	{
		fl_clear_browser($dtlsbrws);
        fl_set_menu_item_mode($Menu, $MENU_DTLS, FL_PUP_NONE);
		if ($procfile =~ /^\d\d*$/)
		{
        	fl_set_menu_item_mode($Menu, $MENU_KILL, FL_PUP_NONE);
		}
		else
		{
        	fl_set_menu_item_mode($Menu, $MENU_KILL, FL_PUP_GREY);
		}
	}
	else
	{		
       	fl_set_menu_item_mode($Menu, $MENU_KILL, FL_PUP_GREY);
        fl_set_menu_item_mode($Menu, $MENU_DTLS, FL_PUP_GREY);
		return if ($procfile eq "kcore" || $procfile eq "kmsg");
    	fl_load_browser($dtlsbrws, $procsubdir)
			if (-f $procsubdir);
	}

	fl_unfreeze_form($mainform);
}

sub DblClickProc
{
	fl_freeze_form($mainform);

	my($obj, $parm) = @_;
	my($line) = fl_get_browser($obj);
	my($ix) = $line-1;
	my($linetext) = fl_get_browser_line($obj, $line);
    my($subdir) = $procs[$ix];
    my($tree) =   $proctree[$ix];
    my($ind) = $procind[$ix];
	my($procsubdir) = "$procdir/$subdir";
	if ($tree)
	{
		for ($i =$ix+1 , $len = 0; 
			 $i <= $#procind && $procind[$i] > $ind;
			 $i++, $len++)
		{
			fl_delete_browser_line($procbrws, $line+1);
		}
		if ($len)
		{
			splice(@proctree, $line, $len);
			splice(@procind,  $line, $len);
			splice(@procs,    $line, $len);
    		$proctree[$ix] = 0;
			$linetext =~ s/((\@b)?\s*)\-/\1+/;
			fl_replace_browser_line($procbrws, $line, $linetext);
		}
	}
	elsif (-d $procsubdir && opendir(SUBD, $procsubdir))
	{
		my(@subs) = undef;
		if ($opt_fs)
		{
			@subs = sort (grep {(-d "$procsubdir/$_") && !/^\./} readdir(SUBD));
		}
		else
		{
			@subs = sort (grep { !/^\./ } readdir(SUBD));
		}
		closedir SUBD;

		my($adj) = 0;
		foreach $sub (@subs)
		{
			my($file) = "$procsubdir/$sub";
			splice(@procs,    $line+$adj, 0, "$subdir/$sub");
			splice(@proctree, $line+$adj, 0, 0);
			splice(@procind,  $line+$adj, 0, $ind+1);
			my($text) = "  " x ($ind+1);
			if (-d $file)
				{$text = "\@b" . $text . "+$sub";}
			else
				{$text = $text . " $sub";}
			fl_insert_browser_line($procbrws, $line+$adj+1, $text);
			$adj++;
		}
    	$proctree[$ix] = 1;
		$linetext =~ s/((\@b)?\s*)\+/\1-/;
		fl_replace_browser_line($procbrws, $line, $linetext);
		fl_set_browser_topline($procbrws, $line);
	}
	fl_unfreeze_form($mainform);
}

sub create_form_main {

  $mainform = fl_bgn_form(FL_NO_BOX, 480, 290);
  $obj = fl_add_box(FL_UP_BOX,0,0,480,286,"");
  $procbrws= $obj = fl_add_browser(FL_HOLD_BROWSER,0,30,238,260,"");
      fl_set_browser_fontstyle($obj,FL_FIXED_STYLE);
      fl_set_browser_fontsize($obj, FL_NORMAL_SIZE);
      fl_set_browser_fontstyle($obj, FL_FIXED_STYLE);
      fl_set_object_callback($obj, "SelectProc", 0);
	  fl_set_object_gravity($obj, FL_NorthWest, FL_South);
      fl_set_browser_dblclick_callback($obj, "DblClickProc", 0);
  $dtlsbrws= $obj = fl_add_browser(FL_NORMAL_BROWSER,242,30,238,260,"");
      fl_set_browser_fontstyle($obj,FL_FIXED_STYLE);
      fl_set_browser_fontsize($obj, FL_NORMAL_SIZE);
	  fl_set_object_gravity($obj, FL_NorthWest, FL_SouthEast);
      fl_set_browser_fontstyle($obj, FL_FIXED_STYLE);
	  fl_set_object_gravity($obj, FL_North, FL_SouthEast);
  $splitter= $obj = fl_add_box(FL_FLAT_BOX, 238, 30, 4, 260, "");
	  fl_set_object_resize($obj, FL_RESIZE_Y);
	  fl_set_object_gravity($obj, FL_North, FL_South);
  $obj = fl_add_box(FL_UP_BOX, 0, 0, 480, 30, "");
      fl_set_object_resize($obj,FL_RESIZE_X);
      fl_set_object_gravity($obj, FL_NorthWest, FL_NorthEast);
  $obj = $Menu = fl_add_menu(FL_PULLDOWN_MENU, 4, 4, 40, 22, $opt_fs ? "File" : "Proc");
      fl_set_object_resize($obj,FL_RESIZE_NONE);
      fl_set_object_gravity($obj, FL_NorthWest, FL_NorthWest);
      fl_set_object_shortcut($obj, "P", 1);
      if ($opt_fs)
	  {
      	fl_set_menu($obj, "Details%l|Refresh%l|Exit");
		$MENU_EXIT = 3;
		$MENU_REFR = 2;
		$MENU_DTLS = 1;
	  }
	  else
	  {
      	fl_set_menu($obj, "Details|Kill%l|Refresh%l|Exit");
		$MENU_EXIT = 4;
		$MENU_REFR = 3;
		$MENU_KILL = 2;
		$MENU_DTLS = 1;
        fl_set_menu_item_mode($obj, 2, FL_PUP_GRAY);
	  }
      fl_set_object_callback($obj, "ProcMenu", 0);

  fl_end_form();
  fl_register_raw_callback($mainform, ((1<<2) | (1<<3) | (1<<13) | (1<<6)),
  							"raw_callback");


}
sub raw_callback
{
	my($form, $event) = @_;
    my($window, $mx, $my, $keymask) = fl_get_form_mouse($form);
	my($type) = $event->type;

	if ($resizing && $type == 5)
	{
		$resizing = 0;
        fl_set_object_boxtype($splitter, FL_FLAT_BOX);
	    fl_set_cursor($mainform->window, FL_DEFAULT_CURSOR);
		($sx, $sy, $sw, $sh) = fl_get_object_geometry($splitter);
		return FL_PREEMPT if ($sx == $old_sgeom[0]);

		fl_freeze_form($mainform);
		my($dx) = $sx + $sw;
		fl_set_object_size($procbrws, $sx, $procbrws->h);
		fl_set_object_geometry($dtlsbrws, $dx, 
                                          $dtlsbrws->y, 
                                          $dtlsbrws->w - ($dx - $dtlsbrws->x),
                                          $dtlsbrws->h);
		fl_unfreeze_form($mainform);
		return FL_PREEMPT;
	}
	elsif ($resizing) 
	{
		$newx = $mx - $delta;
		fl_set_object_position($splitter, $newx, $splitter->y) 
        	if ($newx >= $procbrws->x + 10 && $newx <= ($dtlsbrws->x + $dtlsbrws->w) - 10);
		return FL_PREEMPT;
	}
	elsif ($type == 4 && $mx >= $splitter->x && 
                         $mx <= $splitter->x + $splitter->w &&	
	    	             $my >= $splitter->y && 
                         $my <= $splitter->y + $splitter->h)	
	{
	    fl_set_cursor($mainform->window, 108);
        fl_set_object_boxtype($splitter, FL_DOWN_BOX);
		@old_sgeom = fl_get_object_geometry($splitter);
		$delta = $mx - $old_sgeom[0];
		$resizing = 1;
		return FL_PREEMPT;
	}
	return 0;
}

