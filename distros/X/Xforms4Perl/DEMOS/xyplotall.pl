#!/usr/bin/perl
#/* test screen/world conversion in addition to showing the xyplot styles */

use X11::Xforms;
#use Forms_PLOT_OBJS;
#use Forms_GOODIES;
$| = 1;
@xytype = (
	{	type  => FL_NORMAL_XYPLOT,
		name  => "FL_NORMAL_XYPLOT",
		color => FL_BLACK,
		x     => 20,
		y     => 40
	}, {
		type  => FL_SQUARE_XYPLOT,
		name  => "FL_SQUARE_XYPLOT",
		color => FL_RED,
		x     => 200,
		y     => 40
	}, {
  		type  => FL_CIRCLE_XYPLOT,
  		name  => "FL_CIRCLE_XYPLOT",
		color => FL_GREEN,
		x     => 380,
		y     => 40
	}, {
  		type  => FL_POINTS_XYPLOT,
  		name  => "FL_POINTS_XYPLOT",
		color => FL_BLUE,
		x     => 20,
		y     => 210
	}, {
  		type  => FL_DASHED_XYPLOT,
  		name  => "FL_DASHED_XYPLOT",
		color => FL_INDIANRED,
		x     => 200,
		y     => 210
	}, {
  		type  => FL_FILL_XYPLOT,
  		name  => "FL_FILL_XYPLOT",
		color => FL_SLATEBLUE,
		x     => 380,
		y     => 210
	}, {
 		type  => -1,
		name  => "End",
		color => 0,
		x     => 0,
		y     => 0
	}
);

@xyplot = ();
fl_initialize("FormDemo");
create_form_xyplot();

for ( $i = 0; $i < 6 ; $i++)
{
    for($j = 0; $j < 21; $j++)
    {
       $val =  $j * 3.1415 / 10 ;
       push(@{$xy[$i]}, $val, sin(2*$val) + cos($val));
    }
    fl_set_xyplot_data($xyplot[$i], @{$xy[$i]}, "TestTitle", 
                      "X-axis", "Y-axis");
    fl_add_xyplot_text($xyplot[$i], $xy[$i][14], 1.4,
         "Text Inset", FL_ALIGN_CENTER, FL_BLUE);
   
    fl_set_object_posthandler($xyplot[$i], "post");
}

fl_show_form($fxyplot, FL_PLACE_ASPECT, FL_TRANSIENT, "XYplot");

while ($retobj = fl_do_forms()){}

sub done_xyplot
{
    my($ob, $q) = @_;
    fl_hide_form($ob->form); 
    exit(0);
}

sub post
{
    my($ob, $ev, $mx, $my, $key, $xev) = @_;
    if($ev == FL_PUSH || $ev == FL_MOUSE)
    {
       ($wx, $wy) = fl_xyplot_s2w($ob, $mx, $my);
       $buf = "x=$mx y=$my wx=$wx wy=$wy";
       $form = $ob->form;
#print "Uncomment below to get object returns tested\n";
      fl_show_oneliner($buf, $ob->x + $form->x + 5, 
                            $ob->y + $form->y);
#       fl_show_oneliner($buf, $mx + $form->x, 
#                              $my + $form->y);

       $ob->wantkey(FL_KEY_ALL);
       $ob->input(1);
    }
    elsif($ev == FL_RELEASE){
       fl_hide_oneliner();
    }
    elsif($ev == FL_KEYBOARD) {
       print "key=$key\n";
    }
    return 0;
}

sub create_form_xyplot
{
  $xyi = 0;
  $xy  = $xytype[$xyi];
  $dx = 180; 
  $dy = 160;

  $fxyplot = fl_bgn_form(FL_NO_BOX,570,430);
  $obj = fl_add_box(FL_UP_BOX,0,0,570,430,"");

  until ($xy->{"type"} == -1)
  {

    $xyplot[$xyi] = $obj = fl_add_xyplot($xy->{"type"},
					 $xy->{"x"},
					 $xy->{"y"},
					 $dx,$dy,$xy->{"name"});
    fl_set_object_lsize($obj, FL_TINY_SIZE);
    fl_set_object_color($obj, FL_COL1, $xy->{"color"});
    $xyi++;
    $xy = $xytype[$xyi];
  }

  $obj = fl_add_button(FL_NORMAL_BUTTON,230,390,100,30,"Exit");
  fl_set_object_callback($obj, "done_xyplot", 0);

  $obj = fl_add_text(FL_NORMAL_TEXT,180,20,240,30,"FL_XYPLOT");
  fl_set_object_lcol($obj, FL_SLATEBLUE); 
  fl_set_object_lsize($obj, FL_HUGE_SIZE);
  fl_set_object_lstyle($obj, FL_BOLD_STYLE|FL_EMBOSSED_STYLE);
  fl_set_object_boxtype($obj, FL_FLAT_BOX);

  fl_end_form();
}
