#!/usr/bin/perl
#/* This demo shows the use of choice objects.  */

use X11::Xforms;
#use Forms_CHOICE_OBJS;

$form = "";
$sexobj = "";
$childobj = ""; 
$licenceobj = ""; 
$marriedobj = ""; 
$readyobj = "";

  fl_initialize("FormDemo");
  create_form();
  fl_addto_choice($sexobj,"Male");
  fl_addto_choice($sexobj,"Female");
  fl_addto_choice($childobj,"Zero|One|Two|Three|Many");
  fl_addto_choice($licenceobj,"Yes");
  fl_addto_choice($licenceobj,"No");
  fl_addto_choice($marriedobj,"Yes");
  fl_addto_choice($marriedobj,"No");
  fl_show_form($form,FL_PLACE_CENTER,FL_NOBORDER,NULL);
  do {$obj = fl_do_forms();} while ($obj != $readyobj);
  fl_hide_form($form);

sub create_form
{
  $form = fl_bgn_form(FL_NO_BOX,420,360);
  fl_add_box(FL_UP_BOX,0,0,420,360,"");
  fl_add_input(FL_NORMAL_INPUT,70,300,320,30,"Name");
  fl_add_input(FL_NORMAL_INPUT,70,260,320,30,"Address");
  fl_add_input(FL_NORMAL_INPUT,70,220,320,30,"City");
  fl_add_input(FL_NORMAL_INPUT,70,180,320,30,"Country");
  $sexobj = fl_add_choice(FL_NORMAL_CHOICE,70,130,110,30,"Sex");
  $childobj = fl_add_choice(FL_NORMAL_CHOICE,280,130,110,30,"Children");
  $licenceobj = fl_add_choice(FL_NORMAL_CHOICE,280,80,110,30,"Licence");
  $marriedobj = fl_add_choice(FL_DROPLIST_CHOICE,70,80,110,30,"Married");
  $readyobj = fl_add_button(FL_NORMAL_BUTTON,150,20,140,30,"Ready");
  fl_end_form();
}

