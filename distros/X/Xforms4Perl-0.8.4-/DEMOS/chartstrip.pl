#!/usr/bin/perl
use X11::Xforms;

$func = 1;
$x = 0.0;
$step = 0.15;

$form    = undef;

$chartobj= undef;
$sinobj  = undef;
$exitbut = undef;
$stepobj = undef;

sub set_function
{ 
   my($obj, $arg) = @_;

   $func = $arg; 
   fl_clear_chart($chartobj); 
   $x = 0.0;
}

sub set_step
{ 
   my($obj, $arg) = @_;

   $step = fl_get_slider_value($stepobj);
}

#/*************************************************/

sub create_form_form
{
  $form = fl_bgn_form(FL_NO_BOX,490,320);
  $obj = fl_add_box(FL_BORDER_BOX,0,0,490,320,"");
  $chartobj = $obj = fl_add_chart(FL_LINE_CHART,20,160,390,140,"");
  fl_set_object_dblbuffer($obj,1);

  fl_bgn_group();
  $sinobj = $obj = fl_add_lightbutton(FL_RADIO_BUTTON,30,120,170,30,"sin(x)");
    fl_set_object_boxtype($obj,FL_BORDER_BOX);
    fl_set_object_callback($obj,"set_function",1);
  $obj = fl_add_lightbutton(FL_RADIO_BUTTON,30,90,170,30,"sin(2x)*cos(x)");
    fl_set_object_boxtype($obj,FL_BORDER_BOX);
    fl_set_object_callback($obj,"set_function",2);
  $obj = fl_add_lightbutton(FL_RADIO_BUTTON,30,60,170,30,"sin(2x)+cos(x)");
    fl_set_object_boxtype($obj,FL_BORDER_BOX);
    fl_set_object_callback($obj,"set_function",3);
  $obj = fl_add_lightbutton(FL_RADIO_BUTTON,240,120,160,30,"sin(3x)+cos(x)");
    fl_set_object_boxtype($obj,FL_BORDER_BOX);
    fl_set_object_callback($obj,"set_function",4);
  $obj = fl_add_lightbutton(FL_RADIO_BUTTON,240,90,160,30,"sin(x)^2 + cos(x)");
    fl_set_object_boxtype($obj,FL_BORDER_BOX);
    fl_set_object_callback($obj,"set_function",5);
  $obj = fl_add_lightbutton(FL_RADIO_BUTTON,240,60,160,30,"sin(x)^3");
    fl_set_object_boxtype($obj,FL_BORDER_BOX);
    fl_set_object_callback($obj,"set_function",6);
  fl_end_group();

  $exitbut = $obj = fl_add_button(FL_NORMAL_BUTTON,150,20,140,30,"Exit");
    fl_set_object_boxtype($obj,FL_BORDER_BOX);
  $stepobj = $obj = fl_add_valslider(FL_VERT_SLIDER,430,20,40,280,"");
    fl_set_object_boxtype($obj,FL_BORDER_BOX);
    fl_set_object_callback($obj,"set_step",0);
  fl_end_form();
}

sub next_step
{
  $res = 0.0;

  $res = sin($x)                   if($func == 1);
  $res = sin(2*$x)*cos($x)         if($func == 2);
  $res = sin(2*$x)+cos($x)         if($func == 3);
  $res = sin(3*$x)+cos($x)         if($func == 4);
  $res = sin($x)*sin($x) + cos($x) if($func == 5);
  $res = sin($x)*sin($x)*sin($x)   if($func == 6);

  $x += $step;
  return $res;
}

sub idle_cb
{
    my($xev, $d) = @_;

    fl_insert_chart_value($chartobj,1,next_step(),"",1);
    return 0;
}

  fl_initialize("FormDemo");
  create_form_form();
  fl_set_chart_bounds($chartobj,-1.5,1.5);
  fl_set_chart_maxnumb($chartobj,80);
  fl_set_chart_autosize($chartobj,0);
  fl_set_button($sinobj,1);
  fl_set_slider_value($stepobj,0.15);
  fl_set_slider_bounds($stepobj,0.0,0.4);
  fl_show_form($form,FL_PLACE_CENTER,FL_NOBORDER,"StripChart");
  do 
  {
    fl_insert_chart_value($chartobj,1,next_step(),"",1);
    $obj = fl_check_forms();
  } 
  while ($obj != $exitbut);
  exit(0);
