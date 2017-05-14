#!/usr/bin/perl
use X11::Xforms;

$pupform = undef;
$menu = undef;
$button = undef;
$choice = undef;
$status = undef;
$done_cb = undef;
$pupID = -1;

@pup_entries = 
(
     "Popup Item1", "pupitem_cb", "1", FL_PUP_RADIO,
     "Popup Item2", "pupitem_cb", "2", FL_PUP_RADIO,
     "Popup Item3", "pupitem_cb", "3", FL_PUP_RADIO,
     "/Popup Item 4", "pupitem_cb", "", 0,
        "Popup Item 5", pupitem_cb, "", 0, 
        "Popup Item 6", pupitem_cb, "", 0,
        "Popup Item 7", pupitem_cb, "", 0,
        "Popup Item 8", pupitem_cb, "", 0,
    0,
     "Popup Item10", pupitem_cb, "", FL_PUP_GRAY,
     "Popup Item11", pupitem_cb, "", 0,
	0
     
);

@menu_entries = 
(
     "Menu Item1",    undef, "", 0,
     "Menu Item2",    undef, "", 0,
     "_Menu Item3",   undef, "", 0,
     "/_Menu Item 4", undef, "", 0,
        "Menu Item 5",  undef, "", 0,
        "Menu Item 6",  undef, "", 0,
        "Menu Item 7",  undef, "", 0,
        "Menu Item 8",  undef, "", 0,
     0,
     "Menu Item10",   undef, "", 0,
     "menu Item11",   undef, "", 0,
	 0
     
);

   fl_initialize("Popup Demo");
   create_form_pupform();

   init_menu($menu);
   init_choice($choice);

   fl_show_form($pupform,FL_PLACE_CENTER,FL_FULLBORDER,"pupform");
   fl_do_forms();
   exit 0;

#/********* MENU ***********************************************/

sub menu_callback
{
	my($ob, $data) = @_;

    $buf = sprintf("item %d (%s) selected", 
       fl_get_menu($ob), fl_get_menu_text($ob));

    fl_set_object_label($status, $buf);
}

#/** menu initialization entries. No callbacks for the item */
sub menuitem_entercb
{
	  my($item, $menuid) = @_;
      $buf = sprintf("Entered %d (%s)", $item, fl_get_menu_item_text($menuid, $item));
      fl_set_object_label($status, $buf);
}


sub init_menu
{
	my($menu) = @_;
     $n = fl_newpup(0);
     fl_setpup_entries($n, @menu_entries);
     fl_setpup_entercb($n, "menuitem_entercb", $menu);
     fl_setpup_bw($n, -2);
     fl_set_menu_popup($menu, $n);
}

#/*********** End of menu *************************/

#/******* PopUP ***********************************/

sub pupitem_cb(int selected)
{
	my($selected) = @_;

     $buf = sprintf("Item %d (%s) selected",
         $selected, fl_getpup_text($pupID, $selected));
     fl_set_object_label($status, $buf);
     return $selected;
}

sub pup_entercb
{ 

	  my($item, $null) = @_;

      $buf = sprintf("Entered %d (%s)", $item, fl_getpup_text($pupID, $item));
      fl_set_object_label($status, $buf);
}

sub dopup_callback
{
	my($ob, $data) = @_;

    if($pupID < 0)
    {
        $pupID = fl_newpup(0);
        fl_setpup_entries($pupID, @pup_entries);
        fl_setpup_entercb($pupID, "pup_entercb", 0);
    }

    fl_dopup($pupID);
}

#/********* End of pup *****************/ 

sub init_choice
{
	my($ob) = @_;
    fl_addto_choice($ob,"Choice1|Choice2|Choice3");
    fl_addto_choice($ob,"Choice4|Choice5|Choice6");
    fl_addto_choice($ob,"Choice7|Choice8|Choice9");
}

sub choice_callback
{
	my($ob, $data) = @_;

    $buf = sprintf("%d (%s) selected",
      fl_get_choice($ob), fl_get_choice_text($ob));
    fl_set_object_label($status, $buf);
}

#/* Form definition file generated with fdesign. */


sub create_form_pupform
{

  $pupform = fl_bgn_form(FL_NO_BOX, 320, 250);
  $obj = fl_add_box(FL_UP_BOX,0,0,320,250,"");
  $menu = $obj = fl_add_menu(FL_PULLDOWN_MENU,20,95,60,20,"Menu");
    fl_set_object_boxtype($obj,FL_FLAT_BOX);
    fl_set_object_callback($obj, "menu_callback",0);
  $button = $obj = fl_add_button(FL_MENU_BUTTON,100,90,75,30,"Button");
    fl_set_object_callback($obj, "dopup_callback", 0);
    fl_set_object_shortcut($obj, "#BB", 1);
  $choice = $obj = fl_add_choice(FL_NORMAL_CHOICE2,195,90,105,30,"");
    fl_set_object_callback($obj,"choice_callback", 0);
  $status = $obj = fl_add_text(FL_NORMAL_TEXT,25,30,265,30,"");
    fl_set_object_boxtype($obj,FL_FRAME_BOX);
    fl_set_object_lalign($obj,FL_ALIGN_CENTER);
    fl_set_object_dblbuffer($obj, 1);
  $done_cb = $obj = fl_add_button(FL_NORMAL_BUTTON,210,200,85,30,"Done");
  fl_end_form();

  fl_adjust_form_size($pupform);
}

