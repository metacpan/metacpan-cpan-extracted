#!/usr/bin/perl
use X11::Xforms;
# /* This demo shows the different types of sliders */

#use  Forms_VAL_OBJS;

$form = "";
$exitobj = "";

  fl_initialize("FormDemo");
  create_the_forms();

  fl_show_form($form,FL_PLACE_CENTER,FL_NOBORDER,"All Sliders");
  while (fl_do_forms() != $exitobj){}
  fl_hide_form($form);
  exit 0;

sub create_form_form
{

  $form = fl_bgn_form(FL_NO_BOX,780,320);
  $obj = fl_add_box(FL_UP_BOX,0,0,780,320,"");
    fl_set_object_color($obj,FL_PALEGREEN,FL_COL1);
  $obj = fl_add_box(FL_SHADOW_BOX,20,30,360,270,"SLIDER");
    fl_set_object_color($obj,FL_SLATEBLUE,47);
    fl_set_object_lalign($obj,FL_ALIGN_TOP);
    fl_set_object_lstyle($obj,FL_BOLD_STYLE);
  $obj = fl_add_box(FL_SHADOW_BOX,390,30,370,270,"VALSLIDER");
    fl_set_object_color($obj,FL_SLATEBLUE,FL_COL1);
    fl_set_object_lalign($obj,FL_ALIGN_TOP);
    fl_set_object_lstyle($obj,FL_BOLD_STYLE);
  $obj = fl_add_slider(FL_VERT_SLIDER,30,50,40,220,"vert");
    fl_set_object_color($obj,FL_INDIANRED,FL_PALEGREEN);
  $obj = fl_add_slider(FL_VERT_FILL_SLIDER,80,50,40,220,"vert_fill");
    fl_set_object_color($obj,FL_INDIANRED,FL_PALEGREEN);
  $obj = fl_add_slider(FL_HOR_SLIDER,180,50,190,40,"hor");
    fl_set_object_color($obj,FL_INDIANRED,FL_PALEGREEN);
  $obj = fl_add_slider(FL_HOR_FILL_SLIDER,180,110,190,40,"hor_fill");
    fl_set_object_color($obj,FL_INDIANRED,FL_PALEGREEN);
  $obj = fl_add_valslider(FL_VERT_NICE_SLIDER,610,50,30,220,"vert_nice");
    fl_set_object_boxtype($obj,FL_FLAT_BOX);
    fl_set_object_color($obj,FL_SLATEBLUE,FL_INDIANRED);
  $obj = fl_add_valslider(FL_VERT_FILL_SLIDER,660,50,40,220,"vert_fill");
    fl_set_object_color($obj,FL_INDIANRED,FL_PALEGREEN);
  $obj = fl_add_valslider(FL_HOR_SLIDER,400,50,190,40,"hor");
    fl_set_object_color($obj,FL_INDIANRED,FL_PALEGREEN);
  $obj = fl_add_valslider(FL_HOR_FILL_SLIDER,400,110,190,40,"hor_fill");
    fl_set_object_color($obj,FL_INDIANRED,FL_PALEGREEN);
  $exitobj = $obj = fl_add_button(FL_NORMAL_BUTTON,450,240,100,30,"Exit");
    fl_set_object_color($obj,FL_INDIANRED,FL_RED);
  $obj = fl_add_slider(FL_VERT_NICE_SLIDER,130,50,30,220,"vert_nice");
    fl_set_object_boxtype($obj,FL_FLAT_BOX);
    fl_set_object_color($obj,FL_SLATEBLUE,FL_INDIANRED);
  $obj = fl_add_slider(FL_HOR_NICE_SLIDER,180,170,190,30,"hor_nice");
    fl_set_object_boxtype($obj,FL_FLAT_BOX);
    fl_set_object_color($obj,FL_SLATEBLUE,FL_INDIANRED);
  $obj = fl_add_valslider(FL_HOR_NICE_SLIDER,400,170,190,30,"hor_nice");
    fl_set_object_boxtype($obj,FL_FLAT_BOX);
    fl_set_object_color($obj,FL_SLATEBLUE,FL_INDIANRED);
  $obj = fl_add_valslider(FL_VERT_SLIDER,710,50,40,220,"vert");
    fl_set_object_color($obj,FL_INDIANRED,FL_PALEGREEN);
  fl_end_form();
}

sub create_the_forms
{
  create_form_form();
}

