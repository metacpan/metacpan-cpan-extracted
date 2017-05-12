#!/usr/bin/perl
use X11::Xforms;
#
# scrollbar functionality checkout
#

   fl_initialize("Scrollbar");
   $fd_scb = create_form_scb();

   fl_show_form($fd_scb->{"scb"},FL_PLACE_CENTERFREE,FL_FULLBORDER,"form0");
   fl_do_forms();
   return 0;

sub hide_cb
{
	my($ob, $data) = @_;
    $fdui = $ob->form->fdui;

    if($fdui->{"hor_thin"}->visible)
    {
        fl_set_object_label($fdui->{"hide"},"Show");
        fl_hide_object($fdui->{"hor_thin"});
    }
    else
    {
        fl_set_object_label($fdui->{"hide"},"Hide");
        fl_show_object($fdui->{"hor_thin"});
    }

}

sub deactivate_cb
{
	my($ob, $data) = @_;
    $fdui = $ob->form->fdui;

    if($fdui->{"hor_thin"}->active == 1)
    {
        fl_set_object_label($fdui->{"deactivate"},"Activate");
        fl_deactivate_object($fdui->{"hor_thin"});
    }
    else
    {
        fl_set_object_label($fdui->{"deactivate"},"Deactivate");
        fl_activate_object($fdui->{"hor_thin"});
    }
}

sub done_cb
{
	my($ob, $data) = @_;
    exit(0);
}

sub create_form_scb
{

  %fdui = {
	scb => undef,
	hor => undef,
	hor_thin => undef,
	hor_nice => undef,
	vert => undef,
	vert_thin => undef,
	hide => undef,
	deactivate => undef,
	vert_nice => undef
  };

  $fdui->{"scb"} = fl_bgn_form(FL_NO_BOX, 420, 210);
  $obj = fl_add_box(FL_UP_BOX,0,0,420,210,"");
  $fdui->{"hor"} = $obj = fl_add_scrollbar(FL_HOR_BASIC_SCROLLBAR,30,20,230,17,"");
  $fdui->{"hor_thin"} = $obj = fl_add_scrollbar(FL_HOR_THIN_SCROLLBAR,30,60,230,18,"");
    fl_set_object_boxtype($obj,FL_DOWN_BOX);
    fl_set_scrollbar_value($obj, 0.11);
  $fdui->{"hor_nice"} = $obj = fl_add_scrollbar(FL_HOR_NICE_SCROLLBAR,30,100,230,18,"");
    fl_set_object_boxtype($obj,FL_FRAME_BOX);
  $fdui->{"vert"} = $obj = fl_add_scrollbar(FL_VERT_BASIC_SCROLLBAR,300,10,17,185,"");
  $fdui->{"vert_thin"} = $obj = fl_add_scrollbar(FL_VERT_THIN_SCROLLBAR,338,10,17,185,"");
    fl_set_object_boxtype($obj,FL_DOWN_BOX);
  $fdui->{"hide"} = $obj = fl_add_button(FL_NORMAL_BUTTON,20,160,80,25,"Hide");
    fl_set_object_callback($obj,"hide_cb",0);
  $fdui->{"deactivate"} = $obj = fl_add_button(FL_NORMAL_BUTTON,100,160,80,25,"Deactivate");
    fl_set_object_callback($obj,"deactivate_cb",0);
  $obj = fl_add_button(FL_NORMAL_BUTTON,200,160,80,25,"Done");
    fl_set_object_callback($obj,"done_cb",0);
  $fdui->{"vert_nice"} = $obj = fl_add_scrollbar(FL_VERT_NICE_SCROLLBAR,370,10,17,185,"");
    fl_set_object_boxtype($obj,FL_FRAME_BOX);
    fl_set_scrollbar_value($obj, 1.00);
  fl_end_form();

  $fdui->{"scb"}->fdui($fdui);

  return $fdui;
}

