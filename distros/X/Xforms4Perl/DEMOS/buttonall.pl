#!/usr/bin/perl
#
# Demo all types of buttons
#

use X11::Xforms;

$buttform = undef;
$backface = undef;
$done = undef;
$objsgroup = undef;
$bbutt = undef;
$pbutt = undef;
$bw_obj = undef;
$ret_obj = undef;

 fl_initialize("Buttform");
 create_form_buttform();

# fill-in form initialization code */
 fl_set_pixmapbutton_file($pbutt,"crab45.xpm");
 fl_set_bitmapbutton_file($bbutt,"bm1.xbm");
 fl_addto_choice($bw_obj," -4 | -3 | -2 | -1 |  1|  2|  3|  4");
 fl_set_choice($bw_obj,7);

# show the first form */
 fl_show_form($buttform,FL_PLACE_CENTER,FL_FULLBORDER,"buttform");
 while ($done != fl_do_forms()){}


# callbacks for form buttform */

sub done_cb
{
   exit(0);
}

sub bw_cb
{

	my($ob, $data) = @_;

    @bws = (-4,-3,-2,-1,1,2,3,4);
    $n = fl_get_choice($ob)-1;

    fl_set_object_bw($backface, $bws[$n]);
    fl_set_object_bw($objsgroup, $bws[$n]);

# redrawing the backface wipes out the done button. Redraw it*/
    fl_redraw_object($done);
}


sub create_form_buttform
{
  $buttform = fl_bgn_form(FL_NO_BOX, 290, 260);
  $backface = $obj = fl_add_box(FL_UP_BOX,0,0,290,260,"");
  $done = $obj = fl_add_button(FL_NORMAL_BUTTON,185,215,90,30,"Done");
    fl_set_object_callback($obj,"done_cb",0);

  $objsgroup = fl_bgn_group();
  $obj = fl_add_box(FL_FRAME_BOX,190,27,90,98,"");
  $obj = fl_add_box(FL_FRAME_BOX,90,25,90,100,"");
  $obj = fl_add_frame(FL_ENGRAVED_FRAME,175,170,100,30,"");
    fl_set_object_color($obj,FL_COL1,FL_GREEN);
  $obj = fl_add_round3dbutton(FL_PUSH_BUTTON,210,170,30,30,"");
    fl_set_object_color($obj,FL_COL1,FL_GREEN);
  $bbutt = $obj = fl_add_bitmapbutton(FL_NORMAL_BUTTON,25,85,40,40,"bitmapbutton");
    fl_set_object_color($obj,FL_COL1,FL_BLACK);
  $pbutt = $obj = fl_add_pixmapbutton(FL_NORMAL_BUTTON,25,25,40,40,"pixmapbutton");
  $obj = fl_add_text(FL_NORMAL_TEXT,100,15,70,20,"CheckButton");
    fl_set_object_lalign($obj,FL_ALIGN_LEFT|FL_ALIGN_INSIDE);
  $obj = fl_add_checkbutton(FL_RADIO_BUTTON,100,37,70,32,"Red");
    fl_set_object_color($obj,FL_COL1,FL_RED);
  $obj = fl_add_checkbutton(FL_RADIO_BUTTON,100,63,70,32,"Green");
    fl_set_object_color($obj,FL_COL1,FL_GREEN);
  $obj = fl_add_checkbutton(FL_RADIO_BUTTON,100,90,70,32,"Blue");
    fl_set_object_color($obj,FL_COL1,FL_BLUE);
  $obj = fl_add_lightbutton(FL_PUSH_BUTTON,20,170,92,30,"LightButton");
    fl_set_button($obj, 1);
  $obj = fl_add_text(FL_NORMAL_TEXT,200,15,70,24,"RoundButton");
    fl_set_object_lalign($obj,FL_ALIGN_LEFT|FL_ALIGN_INSIDE);
  $obj = fl_add_roundbutton(FL_PUSH_BUTTON,200,35,75,25,"Red");
    fl_set_object_color($obj,FL_COL1,FL_RED);
  $obj = fl_add_roundbutton(FL_PUSH_BUTTON,200,65,75,25,"Green");
    fl_set_object_color($obj,FL_COL1,FL_GREEN);
  $obj = fl_add_roundbutton(FL_PUSH_BUTTON,200,90,75,25,"Blue");
    fl_set_object_color($obj,FL_COL1,FL_BLUE);
  $obj = fl_add_round3dbutton(FL_PUSH_BUTTON,180,170,30,30,"");
    fl_set_object_color($obj,FL_COL1,FL_RED);
  $obj = fl_add_round3dbutton(FL_PUSH_BUTTON,240,170,30,30,"");
    fl_set_object_color($obj,FL_COL1,FL_BLUE);
  $obj = fl_add_button(FL_PUSH_BUTTON,130,210,30,30,"go");
    fl_set_object_boxtype($obj,FL_OVAL3D_UPBOX);
    fl_set_object_lstyle($obj,FL_BOLD_STYLE);
  $obj = fl_add_button(FL_NORMAL_BUTTON,20,210,90,30,"Button");
    fl_set_object_boxtype($obj,FL_ROUNDED3D_UPBOX);
  $bw_obj = $obj = fl_add_choice(FL_NORMAL_CHOICE2,105,135,80,30,"BW");
    fl_set_object_callback($obj,"bw_cb",0);
  fl_end_group();

  fl_end_form();

  fl_adjust_form_size($buttform);

}

