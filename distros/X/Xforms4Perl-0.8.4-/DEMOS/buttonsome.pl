#!/usr/bin/perl
#/* 
# * All buttons
# */

use X11::Xforms; 
#use Forms; 

$buttonform = "";
$readyobj = "";
    fl_initialize("FormDemo");
    create_form_buttons();
    fl_show_form($buttonform, FL_PLACE_CENTER, FL_TRANSIENT, "Some Buttons");
    fl_set_cursor_color(60, FL_RED, FL_WHITE);
    $win = $buttonform->window;
    fl_set_cursor($win, 60);
    while (fl_do_forms() != $readyobj){}


sub bitmapbutton
{
   my($ob, $q) = @_;
   if (fl_get_button($ob)) {
	$file = "nomail.xbm";
   }
   else {
	$file = "newmail.xbm";
   }
  fl_set_bitmapbutton_file($ob, $file);
}

sub pixmapbutton
{
   my($ob, $q) = @_;
   if (fl_get_button($ob)) {
	$file = "crab45.xpm";
   }
   else {
	$file = "crab.xpm";
   }
   fl_set_pixmapbutton_file($ob, $file);
}


sub create_form_buttons
{

  return if ($buttonform);

  $buttonform = fl_bgn_form(FL_NO_BOX,320,380);
  $obj = fl_add_box(FL_UP_BOX,0,0,320,380,"");

  $readyobj = $obj = fl_add_button(FL_NORMAL_BUTTON,190,335,110,30,"READY");

  $obj = fl_add_button(FL_NORMAL_BUTTON,125,30,150,35,"Button");
  fl_set_object_boxtype($obj,FL_SHADOW_BOX);
  fl_set_object_color($obj,FL_GREEN,FL_RED);

  $obj = fl_add_bitmapbutton(FL_PUSH_BUTTON,180,210,80,70,"");
  fl_set_object_boxtype($obj,FL_NO_BOX);
  fl_set_object_callback($obj, "bitmapbutton",0);
  fl_set_bitmapbutton_file($obj,"newmail.xbm");

  $obj = fl_add_pixmapbutton(FL_PUSH_BUTTON,200,280,45,40,"");
  fl_set_object_callback($obj, "pixmapbutton",0);
  fl_set_pixmapbutton_file($obj,"crab.xpm");

  fl_bgn_group();
  $obj = fl_add_roundbutton(FL_RADIO_BUTTON,25,30,45,50,"");
  fl_set_object_boxtype($obj,FL_BORDER_BOX);
  fl_set_object_color($obj,FL_MCOL,FL_RED);

  $obj = fl_add_roundbutton(FL_RADIO_BUTTON,25,75,45,50,"");
  fl_set_object_boxtype($obj,FL_BORDER_BOX);
  fl_set_object_color($obj,FL_MCOL,FL_GREEN);

  $obj = fl_add_roundbutton(FL_RADIO_BUTTON,25,125,45,50,"");
  fl_set_object_boxtype($obj,FL_BORDER_BOX);
  fl_set_object_color($obj,FL_MCOL,FL_BLUE);
  fl_end_group();

  fl_bgn_group();
  $obj = fl_add_frame(FL_ENGRAVED_FRAME,115,80,75,95,""); 
  $obj = fl_add_box(FL_FLAT_BOX,125,75,50,10,"CheckB");
  $obj = fl_add_checkbutton(FL_RADIO_BUTTON,120,85,55,30,"Red");
    fl_set_object_color($obj,FL_MCOL,FL_RED);
  $obj = fl_add_checkbutton(FL_RADIO_BUTTON,120,115,55,30,"Green");
    fl_set_object_color($obj,FL_MCOL,FL_GREEN);
  $obj = fl_add_checkbutton(FL_RADIO_BUTTON,120,145,55,30,"Blue");
    fl_set_object_color($obj,FL_MCOL,FL_BLUE);
  fl_end_group();

  fl_bgn_group();
  $obj = fl_add_lightbutton(FL_RADIO_BUTTON,20,215,125,35," Red");
    fl_set_object_color($obj,FL_COL1,FL_RED);
  $obj = fl_add_lightbutton(FL_RADIO_BUTTON,20,250,125,35," Green");
    fl_set_object_color($obj,FL_COL1,FL_GREEN);
  $obj = fl_add_lightbutton(FL_RADIO_BUTTON,20,285,125,35," Blue");
    fl_set_object_color($obj,FL_COL1,FL_BLUE);
  fl_end_group();

  fl_bgn_group();
  $obj = fl_add_roundbutton(FL_RADIO_BUTTON,230,85,55,30,"Red");
     fl_set_object_color($obj,FL_MCOL,FL_RED);

  $obj = fl_add_frame(FL_SHADOW_FRAME,225,80,75,95,"");
  $obj = fl_add_roundbutton(FL_RADIO_BUTTON,230,145,55,30,"Blue");
     fl_set_object_color($obj,FL_MCOL,FL_BLUE);
  $obj = fl_add_roundbutton(FL_RADIO_BUTTON,230,115,55,30,"Green");
     fl_set_object_color($obj,FL_MCOL,FL_GREEN);
  $obj = fl_add_roundbutton(FL_RADIO_BUTTON,230,85,55,30,"Red");
    fl_set_object_color($obj,FL_MCOL,FL_RED);
  fl_end_group();
  fl_end_form();
}
