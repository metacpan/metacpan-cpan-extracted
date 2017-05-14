#!/usr/bin/perl
#/* Demo showing the use of canvas object.   V0.75
#
# It also shows the use of XEvent objects and XEvent callbacks
#
# */

#use Forms;
use X11::Xforms;
#use Forms_DRAW;
#use Forms_CANVAS;
#use Forms_CHOICE_OBJS;
#use Forms_WIN;
#use Forms_XEVENT;
use X11::XEvent;

$canvasform = "";
$canvas = "";
$br = "";
$keyboard = "";
$mouse = "";
$done = "";
$misc = "";
$menu = "";
$vdata = "";
$ldata = "";
$canvasGC = "";

   fl_initialize("FormDemo");
   create_form_canvasform();

   fl_set_object_dblbuffer($br, 1);
   init_canvas();

   fl_addto_menu($menu,"Item1|Item2|Item3|Item4");

   fl_show_form($canvasform,
                FL_PLACE_FREE,FL_FULLBORDER,"canvasform");

   while (($o =fl_do_forms()) != $done){} 

sub canvas_expose
{
    my($ob, $win, $w, $h, $ev, $d) = @_;
    fl_rectf($ob->x, $ob->y, $w, $h, FL_BLACK);
    fl_addto_browser($br, "Expose");
    return 0;
}

sub canvas_key
{
    my($ob, $win, $w, $h, $ev, $d) = @_;
    $code = XKeycodeToKeysym(fl_get_display,$ev->keycode, 0);
    $buf = "KeyPress: keysym=$code";  
    fl_addto_browser($br, $buf);
    return 0;
}

sub canvas_but
{
    my($ob, $win, $w, $h, $ev, $d) = @_;
    $buf = "ButtonPress: " . $ev->button;
    fl_addto_browser($br, $buf);
    return 0;
}

sub canvas_misc
{
    my($ob, $win, $w, $h, $ev, $d) = @_;
    if ($ev->type == EnterNotify) {
	$str = "Enter canvas";
    } else {
	$str = "Leave canvas";
    }
    fl_addto_browser($br, $str);
    return 0;
}


sub init_canvas
{
   fl_add_canvas_handler($canvas, 12, "canvas_expose", 0);
   fl_add_canvas_handler($canvas,  2, "canvas_key",    0);
   fl_add_canvas_handler($canvas,  4, "canvas_but",    0);
   fl_set_button($mouse, 1);
   fl_set_button($keyboard, 1);
   $canvasGC = fl_create_GC();
   fl_set_foreground($canvasGC, FL_BLACK);
}

sub sensitive_setting
{
    my($ob, $event) = @_;

    if ($event == KeyPress) {
       $hc = "canvas_key"; 
    } else { 
       $hc = "canvas_but";
    }

    if(fl_get_button($ob)) {
       fl_add_canvas_handler($canvas, $event, $hc, 0);
    } else {
       fl_remove_canvas_handler($canvas, $event);
    }
}

sub hide_it
{
      my($ob, $all) = @_;

      if($all)
      {
         fl_hide_form($canvasform);
         fl_show_form($canvasform,
                      FL_PLACE_CENTER, FL_TRANSIENT, "canvas");
      }
      else
      {
         if($canvas->visible)
         {
            fl_hide_object($canvas);
            fl_set_object_label($ob,"ShowCanvas");
         }
         else
         {
            fl_show_object($canvas);
            fl_set_object_label($ob,"HideCanvas");
         }
      }
}

sub misc_cb
{ 
    my($ob, $parm) = @_;

    if(fl_get_button($ob))
    {
       fl_add_canvas_handler($canvas, EnterNotify, 
                             "canvas_misc", 0);
       fl_add_canvas_handler($canvas, LeaveNotify,
                             "canvas_misc", 0);
    }
    else
    {
       fl_remove_canvas_handler($canvas, 
                                EnterNotify);
       fl_remove_canvas_handler($canvas, 
                                LeaveNotify);
    }
}

sub create_form_canvasform
{
  $old_bw = fl_get_border_width();

  fl_set_border_width(-2);
  $canvasform = fl_bgn_form(FL_NO_BOX, 450, 280);
  $obj = fl_add_box(FL_UP_BOX,0,0,450,280,"");
  $canvas = $obj = fl_add_canvas(FL_NORMAL_CANVAS,20,40,155,187,"");
  $br = $obj = fl_add_browser(FL_NORMAL_BROWSER,188,40,152,187,"");
  $obj = fl_add_button(FL_NORMAL_BUTTON,80,236,90,27,"HideCanvas");
    fl_set_object_callback($obj, "hide_it", 0);
  $obj = fl_add_button(FL_NORMAL_BUTTON,170,236,90,27,"HideForm");
    fl_set_object_callback($obj, "hide_it", 1);
  $done = $obj = fl_add_button(FL_NORMAL_BUTTON,260,236,90,27,"Done");
  $obj = fl_add_text(FL_NORMAL_TEXT,130,10,120,20,"Canvas");
    fl_set_object_lsize( $obj,FL_MEDIUM_SIZE);
    fl_set_object_lalign($obj,FL_ALIGN_CENTER);
    fl_set_object_lstyle($obj,FL_BOLD_STYLE);
  $menu = $obj = fl_add_menu(FL_PULLDOWN_MENU, 20,10, 40,20,"Menu");
    fl_set_object_shortcut($obj,"#m", 1);
  $keyboard = $obj = fl_add_checkbutton(FL_PUSH_BUTTON,345,40,76,26,"Keyboard");
    fl_set_object_color($obj,FL_COL1,FL_BLUE);
    fl_set_object_callback($obj,"sensitive_setting",2);
  $mouse = $obj = fl_add_checkbutton(FL_PUSH_BUTTON,345,70,76,26,"Mouse");
    fl_set_object_color($obj,FL_COL1,FL_BLUE);
    fl_set_object_callback($obj,"sensitive_setting",4);
  $misc = $obj = fl_add_checkbutton(FL_PUSH_BUTTON,345,100,74,26,"Enter/Leave");
    fl_set_object_color($obj,FL_COL1,FL_BLUE);
    fl_set_object_callback($obj,"misc_cb",4);
  fl_end_form();
  fl_set_border_width($old_bw);

}
