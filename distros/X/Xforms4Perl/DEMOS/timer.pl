#!/usr/bin/perl
#/* A demo showing the use of timer objects.
# * note there is only one fl_do_form().
# */

use X11::Xforms;

$form1 = "";
$form2 = "";
$tim = "";
$tim2 = "";

$TIME=5;

  fl_initialize("FormDemo");
  makeforms();
  fl_show_form($form1,FL_PLACE_CENTER,FL_NOBORDER,"Timer");
  fl_set_timer($tim,$TIME);
  fl_do_forms();
  exit 0;



sub timer1_expired
{
   fl_deactivate_form($form1);
   fl_set_timer($tim2,10);
   fl_show_form($form2,FL_PLACE_MOUSE,0,"Q");
}

sub nothing
{
}

sub continue_cb
{
   fl_hide_form($form2);
   fl_activate_form($form1);
   fl_set_timer($tim,$TIME);
   fl_set_object_callback($tim,"nothing",0);
}

sub done_cb
{
   exit 0;
}


sub makeforms
{

  $form1 = fl_bgn_form(FL_UP_BOX,400,400);
    $obj = fl_add_button(FL_NORMAL_BUTTON,140,160,120,80,"Push Me");
      fl_set_object_callback($obj, "done_cb", 0);
    $tim = fl_add_timer(FL_VALUE_TIMER,200,40,90,50,"Time Left");
      fl_set_object_callback($tim, "timer1_expired",0);
    fl_set_object_lcol($tim, FL_BLACK);
  fl_end_form();

  $form2 = fl_bgn_form(FL_UP_BOX,320,120);
    fl_add_box(FL_NO_BOX,160,40,0,0,"You were too late");
    $obj = fl_add_button(FL_NORMAL_BUTTON,100,70,120,30,"Try Again");
    fl_set_object_callback($obj, "continue_cb", 0);
    $tim2 = fl_add_timer(FL_HIDDEN_TIMER,0,0,1,2,"");
    fl_set_object_callback($tim2, "continue_cb", 0);
  fl_end_form();
}

