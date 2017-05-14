#!/usr/bin/perl
use X11::Xforms;

$test_interp = 0;	# Set to 1 to test fl_get_xyplot_data and fl_interpolate

$axypform = undef;
$xyplot = undef;
$status = undef;


   fl_initialize("FormDemo");
   create_form_axypform();

   fl_set_object_dblbuffer($status, 1);
   for ($i  = 0, $j = 0; $i <= 10; $i++, $j+=2)
   {
      $xy[$j] = $xy[$j+1] = $i; 
   }
   fl_set_xyplot_data($xyplot, @xy, "","","");
   fl_set_xyplot_linewidth($xyplot, 0, 2);
   fl_set_xyplot_xgrid($xyplot,FL_GRID_MINOR);

   fl_show_form($axypform,FL_PLACE_MOUSE,FL_TRANSIENT,"axypform");
   fl_do_forms();
   exit 0;

#/* callbacks for form axypform */
sub xyplot_cb
{
	my($ob, $data) = @_;

    ($x, $y, $i) = fl_get_xyplot($ob);
    return if(i < 0);
    $buf = sprintf("X=%f  Y=%f",$x,$y);
    fl_set_object_label($status, $buf);
}

sub alwaysreturn_cb
{
	my($ob, $data) = @_;

   fl_set_xyplot_return($xyplot, fl_get_button($ob));
}

sub interpolate_cb
{
	my($ob, $data) = @_;
	my($degree) = fl_get_button($ob) ? 3:0;
	if ($test_interp)
	{
   		@nowxy = fl_get_xyplot_data($xyplot);
		print "xyplot has @nowxy\n";
   		@interp = fl_interpolate(@nowxy, 0.2, $degree);
		print "interpolated xyplot has @interp\n";
	}

   fl_set_xyplot_interpolate($xyplot, 0, fl_get_button($ob) ? 3:0, 0.2);
}

sub inspect_cb
{
	my($ob, $data) = @_;

   fl_set_xyplot_inspect($xyplot, fl_get_button($ob));
}

sub notic_cb
{
	my($ob, $data) = @_;

   $notic = fl_get_button($ob);

   if($notic)
   {
      fl_set_xyplot_xtics($xyplot, -1, -1);
      fl_set_xyplot_ytics($xyplot, -1, -1);
   }
   else
   {
      fl_set_xyplot_xtics($xyplot, 0, 0);
      fl_set_xyplot_ytics($xyplot, 0, 0);
   }
}

sub create_form_axypform
{

  $axypform = fl_bgn_form(FL_NO_BOX, 431, 301);
  $obj = fl_add_box(FL_UP_BOX,0,0,431,301,"");
  $xyplot = $obj = fl_add_xyplot(FL_ACTIVE_XYPLOT,20,50,285,235,"");
    fl_set_object_boxtype($obj,FL_DOWN_BOX);
    fl_set_object_color($obj,FL_BLACK,FL_GREEN);
    fl_set_object_lalign($obj,FL_ALIGN_BOTTOM|FL_ALIGN_INSIDE);
    fl_set_object_callback($obj,"xyplot_cb",0);
  $obj = fl_add_checkbutton(FL_PUSH_BUTTON,315,40,80,25,"AlwaysReturn");
    fl_set_object_color($obj,FL_COL1,FL_BLUE);
    fl_set_object_callback($obj,"alwaysreturn_cb",0);
  $obj = fl_add_checkbutton(FL_PUSH_BUTTON,315,65,80,25,"Interpolate");
    fl_set_object_color($obj,FL_COL1,FL_BLUE);
    fl_set_object_callback($obj,"interpolate_cb",0);
  $obj = fl_add_checkbutton(FL_PUSH_BUTTON,315,90,85,25,"InspectOnly");
    fl_set_object_color($obj,FL_COL1,FL_BLUE);
    fl_set_object_callback($obj,"inspect_cb",0);
  $status = $obj = fl_add_box(FL_BORDER_BOX,45,15,170,25,"");
    fl_set_object_boxtype($obj,FL_DOWN_BOX);
  $obj = fl_add_button(FL_NORMAL_BUTTON,325,250,90,30,"Done");
  $obj = fl_add_checkbutton(FL_PUSH_BUTTON,315,120,85,25,"NoTics");
    fl_set_object_color($obj,FL_COL1,FL_BLUE);
    fl_set_object_callback($obj,"notic_cb",0);
  fl_end_form();

}
