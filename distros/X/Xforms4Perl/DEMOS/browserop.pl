#!/usr/bin/perl
#/* This demo shows the different routines on browsers */

use X11::Xforms;

$form = "";
$browserobj = "";
$inputobj = "";
$exitobj = "";

  fl_initialize("FormDemo");
  create_form();
  fl_show_form($form,FL_PLACE_CENTER,FL_NOBORDER,"Browser Op");
  do {
	$obj = fl_do_forms(); 
  } while ($obj != $exitobj);
  fl_hide_form($form);

sub addit
{
  fl_addto_browser($browserobj,fl_get_input($inputobj));
}

sub insertit
{
  return if (! fl_get_browser($browserobj));
  fl_insert_browser_line($browserobj,
  	fl_get_browser($browserobj),
  	fl_get_input($inputobj));
}

sub replaceit
{
  return if (! fl_get_browser($browserobj));
  fl_replace_browser_line($browserobj,
	fl_get_browser($browserobj),
	fl_get_input($inputobj));
}

sub deleteit
{
  return if (! fl_get_browser($browserobj));
  fl_delete_browser_line($browserobj,
	fl_get_browser($browserobj));
}

sub clearit
{
  fl_clear_browser($browserobj);
}

sub create_form
{

  $form = fl_bgn_form(FL_UP_BOX,390,420);
  $browserobj = fl_add_browser(FL_HOLD_BROWSER,20,20,210,330,"");
    fl_set_object_dblbuffer($browserobj, 1);
  $inputobj = $obj = fl_add_input(FL_NORMAL_INPUT,20,370,210,30,"");
    fl_set_object_callback($obj,"addit",0);
  $obj = fl_add_button(FL_NORMAL_BUTTON,250,20,120,30,"Add");
    fl_set_object_callback($obj,"addit",0);
  $obj = fl_add_button(FL_NORMAL_BUTTON,250,60,120,30,"Insert");
    fl_set_object_callback($obj,"insertit",0);
  $obj = fl_add_button(FL_NORMAL_BUTTON,250,100,120,30,"Replace");
    fl_set_object_callback($obj,"replaceit",0);
  $obj = fl_add_button(FL_NORMAL_BUTTON,250,160,120,30,"Delete");
    fl_set_object_callback($obj,"deleteit",0);
  $obj = fl_add_button(FL_NORMAL_BUTTON,250,200,120,30,"Clear");
    fl_set_object_callback($obj,"clearit",0);
  $exitobj = fl_add_button(FL_NORMAL_BUTTON,250,370,120,30,"Exit");
  fl_end_form();
}

