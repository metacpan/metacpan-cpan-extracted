# This script allows for automatic initialization and cutomization
# of Xforms and Xforms objects!
#
# It MUST contain two subroutines named fl_pre_init and fl_post_init.
#
# Additionally, any callback routine registered MUST be in the namespace
# of the package of the function that causes their invocation. Usually
# this is main::. 
#
# This sample performs some pre-initialization of defaults, and then some
# post initialization of the keymap, pups and certain goodies. It also 
# registers a callback for all avaialbe object classes. Most do nothing
# in particular, but some, such as the browser one, show just how useful
# this facility is. 
#
# To use this script, place it in your home directory.
#

#
# Set up the colors
#

@SelectColor     =    ( 85, 128, 151);      # Gets mapped to FL_FREE_COL1
@BackgroundColor =    (152, 184, 200);      # Gets mapped to FL_COL1
@WorkingBackGround =  (255, 255, 255);		# This is also FL_WHITE

#
# Ratios based on KDEs calculations at contrast = 5
#
@TopLeftShadow   =  (int(($BackgroundColor[0] * 1.2)+0.5), 
                     int(($BackgroundColor[1] * 1.2)+0.5),
                     int(($BackgroundColor[2] * 1.2)+0.5));  

@BottomRightShadow =(int(($BackgroundColor[0] / 3)+0.5), 
                     int(($BackgroundColor[1] / 3)+0.5),
                     int(($BackgroundColor[2] / 3)+0.5));

@ScrollBackGround  =(int(($BackgroundColor[0] * 0.84)+0.5), 
                     int(($BackgroundColor[1] * 0.82)+0.5),
                     int(($BackgroundColor[2] * 0.80)+0.5));


$SelectColor=FL_FREE_COL1;
$BackgroundColor=FL_COL1;
$ScrollBackGround=FL_MCOL;
$Working_bgrnd=FL_WHITE;

#
# An array of initializer callbacks IN CLASS NUMBER ORDER!
#
@init_cbs = (
	0,
	\&main::fl_button_cl, 
	\&main::fl_lightbutton_cl,
	\&main::fl_roundbutton_cl, 
	\&main::fl_round3dbutton_cl,
	\&main::fl_checkbutton_cl,
	\&main::fl_bitmapbutton_cl, 
	\&main::fl_pixmapbutton_cl,
	\&main::fl_bitmap_cl, 
	\&main::fl_pixmap_cl,
	\&main::fl_box_cl, 
	\&main::fl_text_cl,
	\&main::fl_menu_cl, 
	\&main::fl_chart_cl, 
	\&main::fl_choice_cl,
	\&main::fl_counter_cl, 
	\&main::fl_slider_cl, 
	\&main::fl_valslider_cl, 
	\&main::fl_input_cl,
	\&main::fl_browser_cl,
	\&main::fl_dial_cl,
	\&main::fl_timer_cl,
	\&main::fl_clock_cl,
	\&main::fl_positioner_cl,
	\&main::fl_free_cl,
	\&main::fl_xyplot_cl,
	\&main::fl_frame_cl,
	\&main::fl_labelframe_cl,
	\&main::fl_canvas_cl,
	\&main::fl_glcanvas_cl,
	\&main::fl_tabfolder_cl,
	\&main::fl_scrollbar_cl,
	\&main::fl_scrollbutton_cl,
	\&main::fl_menubar_cl
);

sub fl_pre_init {
#
# THIS IS A REQUIRED SUBROUTINE EVEN IF IT IS EMPTY
#
# This routine is called immediately prior to fl_initialize
#
# CAUTION: Only certain things work before fl_initialize. See
#          Xforms documentation for details
#

	my($iopt) = X11::Xforms::FLOpt->new();
	$iopt->scrollbarType(FL_PLAIN_SCROLLBAR);
	fl_set_defaults(FL_PDScrollbarType, $iopt);

#
# Now overwrite the default colors with what we want.
#
    fl_set_icm_color(FL_COL1,        @BackgroundColor );
    fl_set_icm_color(FL_MCOL,        @ScrollBackGround );
    fl_set_icm_color(FL_TOP_BCOL,    @TopLeftShadow );
    fl_set_icm_color(FL_LEFT_BCOL,   @TopLeftShadow );
    fl_set_icm_color(FL_BOTTOM_BCOL, @BottomRightShadow );
    fl_set_icm_color(FL_RIGHT_BCOL,  @BottomRightShadow );

}

sub fl_post_init {
#
# THIS IS A REQUIRED SUBROUTINE EVEN IF IT IS EMPTY
#
# This routine is called immediately after fl_initialize
#
# This is the ideal place to do most global customization and to register
# class callback routines.
#

	my($iopt) = fl_get_defaults();
    if ($iopt->scrollbarType == FL_PLAIN_SCROLLBAR)
	{
		$hscroll = FL_HOR_PLAIN_SCROLLBAR;
		$vscroll = FL_VERT_PLAIN_SCROLLBAR;
	}
	elsif ($iopt->scrollbarType == FL_THIN_SCROLLBAR) 
	{
		$hscroll = FL_HOR_THIN_SCROLLBAR;
		$vscroll = FL_VERT_THIN_SCROLLBAR;
	}
	elsif ($iopt->scrollbarType == FL_NORMAL_SCROLLBAR) 
	{
		$hscroll = FL_HOR_NORMAL_SCROLLBAR;
		$vscroll = FL_VERT_NORMAL_SCROLLBAR;
	}
	elsif ($iopt->scrollbarType == FL_NICE_SCROLLBAR) 
	{
		$hscroll = FL_HOR_NICE_SCROLLBAR;
		$vscroll = FL_VERT_NICE_SCROLLBAR;
	}

	$keymap = X11::Xforms::FLEditKeymap->new();
	$keymap->del_prev_char(8);
	$keymap->del_next_char(127);
	fl_set_input_editkeymap($keymap);

	fl_mapcolor($SelectColor, @SelectColor);
#	fl_mapcolor($Working_bgrnd, @Working_bgrnd); 	  # FL_WHITE
#	fl_mapcolor($BackgroundColor, @BackgroundColor);  # FL_COL1
#	fl_mapcolor($ScrollBackGround, @ScrollBackGround);# FL_MCOL

	#
	# Set the pup defaults
	#
	fl_setpup_fontstyle(FL_NORMAL_STYLE);
	fl_setpup_color($BackgroundColor, FL_BLACK);
	fl_setpup_checkcolor($SelectColor);    
	@libver = fl_library_version();

	$maxcbs = 33 if ($libver[1] > 86);
	$maxcbs = 29 if ($libver[1] > 86);

	#
	# Register the callbacks for each object class
	#
	for ($i = 1; $i <= $maxcbs; $i++)
	{
		fl_set_class_callback($i,$init_cbs[$i]); 
	}

	#
	# Now initialize the command log and fselector goodies
	#
	$strct = fl_get_command_log_fdstruct();
	init_form($strct->form);
	$strct = fl_get_fselector_fdstruct();
	init_form($strct->fselect);
}

sub init_form
{
	#
    # This useful little subroutine initializes ALL objects in a form
    # using the registered initializer routines. This is useful for 
    # initializing goodies such as the Command Log and File Selector
	#
	my($form) = @_;
	my($nxt) = my($obj) = $form->first;
	my($lst) = $form->last;
	do
	{
		$obj = $nxt;
		&{$init_cbs[$obj->objclass]}($obj) if ($obj->objclass <= $#init_cbs);
		$nxt = $obj->next;

	} while ($obj ne $lst);
}

#
# The callbacks
#
sub main::fl_button_cl {
	my($obj) = @_;
}
 
sub main::fl_lightbutton_cl {
	my($obj) = @_;
  	fl_set_object_color($obj, $ScrollBackGround, FL_YELLOW);
}

sub main::fl_roundbutton_cl {
	my($obj) = @_;
}
 
sub main::fl_round3dbutton_cl {
	my($obj) = @_;
}

sub main::fl_checkbutton_cl {
	my($obj) = @_;
}

sub main::fl_bitmapbutton_cl {
	my($obj) = @_;
}
 
sub main::fl_pixmapbutton_cl {
	my($obj) = @_;
}

sub main::fl_bitmap_cl {
	my($obj) = @_;
}
 
sub main::fl_pixmap_cl {
	my($obj) = @_;
}

sub main::fl_box_cl {
	my($obj) = @_;
	fl_set_object_bw($obj, -1) if ($obj->type == FL_UP_BOX);
}
 
sub main::fl_text_cl {
	my($obj) = @_;
}

sub main::fl_menu_cl {
	my($obj) = @_;
	fl_set_object_boxtype($obj, FL_FLAT_BOX);
	fl_set_object_lsize($obj, FL_NORMAL_SIZE);
	fl_set_object_lstyle($obj, FL_NORMAL_STYLE);
}
 
sub main::fl_chart_cl {
	my($obj) = @_;
}
 
sub main::fl_choice_cl {
	my($obj) = @_;
}

sub main::fl_counter_cl {
	my($obj) = @_;
}
 
sub main::fl_slider_cl {
	my($obj) = @_;
}
 
sub main::fl_valslider_cl {
	my($obj) = @_;
}
 
sub main::fl_input_cl {
	my($obj) = @_;
  	fl_set_object_color($obj, $SelectColor, $Working_bgrnd);
}

sub main::fl_browser_cl {
#
# Browsers are composite objects. To change colors, therefore, we must
# get the various sub-objects and change those colors too.
#
	my($obj) = @_;
  	fl_set_object_color($obj, $Working_bgrnd, $SelectColor);

#
# If you want other than default coloros for browsers, this is how
# you can get at the scroll bars and change those too! 0.88 ONLY!
#

	if ($libver[1] > 86)
	{
  		my($scr) = fl_get_object_component($obj, FL_SCROLLBAR, $hscroll, 0);
  		fl_set_object_color($scr, $ScrollBackGround, $BackgroundColor) if (defined($scr));

  		$scr = fl_get_object_component($obj, FL_SCROLLBAR, $vscroll, 0);
  		fl_set_object_color($scr, $ScrollBackGround, $BackgroundColor) if (defined($scr));
	}
}

sub main::fl_dial_cl {
	my($obj) = @_;
}

sub main::fl_timer_cl {
	my($obj) = @_;
}

sub main::fl_clock_cl {
	my($obj) = @_;
}

sub main::fl_positioner_cl {
	my($obj) = @_;
}

sub main::fl_free_cl {
	my($obj) = @_;
}

sub main::fl_xyplot_cl {
	my($obj) = @_;
}

sub main::fl_frame_cl {
	my($obj) = @_;
}

sub main::fl_labelframe_cl {
	my($obj) = @_;
}

sub main::fl_canvas_cl {
	my($obj) = @_;
}

sub main::fl_glcanvas_cl {
	my($obj) = @_;
}

sub main::fl_tabfolder_cl {
	my($obj) = @_;
}

sub main::fl_scrollbar_cl {
	my($obj) = @_;
}

sub main::fl_scrollbutton_cl {
	my($obj) = @_;
}

sub main::fl_menubar_cl {
	my($obj) = @_;
}

#
# Since we are 'required' return 1
#

1;
