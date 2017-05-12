#!/usr/bin/perl
#/* This is a demo that shows the different types of browsers.  */

use X11::Xforms;

$form = "";
@br[4] = ("", "", "", "");
@bnames = ( "NORMAL_BROWSER", 
            "SELECT_BROWSER", 
            "HOLD_BROWSER", 
            "MULTI_BROWSER" );

$exitobj = "";
$readout = "";

  fl_initialize("FormDemo");
  create_form();
  fill_browsers();
  fl_show_form($form,FL_PLACE_CENTER,FL_NOBORDER,NULL);
  fl_do_forms();
  fl_hide_form($form);


sub deselect {
  my($obj, $arg) = @_;
  for ($i=0; $i<4; $i++) {
     fl_deselect_browser($br[$i]);
  }
}

sub set_size {
  my($obj, $arg) = @_;
  for ($i=0; $i<4; $i++) {
     fl_set_browser_fontsize($br[$i],$arg);
  }
}

sub set_style {
  my($obj, $arg) = @_;
  for ($i=0; $i<4; $i++) {
     fl_set_browser_fontstyle($br[$i], $arg);
  }
}

sub br_callback {
  my($obj, $arg) = @_;
    $i = fl_get_browser($obj);
    $buf = "In $bnames[$arg]";
    $buf1 = fl_get_browser_line($obj, ($i >0 ? $i :-$i));
    $buf2 = ($i > 0 ?  " was selected":" was deselected.");
    fl_set_object_label($readout,"$buf $buf1 $buf2");
}

sub create_form {

  $form = fl_bgn_form(FL_UP_BOX,700,570);
  $readout = fl_add_box(FL_UP_BOX,50,30,600,50,"");
  fl_set_object_lsize($readout,FL_LARGE_SIZE);
  fl_set_object_lstyle($readout,FL_BOLD_STYLE);

  fl_set_object_color($readout,FL_MAGENTA,FL_MAGENTA);

  $br[0] = $obj = fl_add_browser(FL_NORMAL_BROWSER,20,120,150,290,$bnames[0]);
    fl_set_object_callback($obj, "br_callback", 0);
  $br[1] = $obj = fl_add_browser(FL_SELECT_BROWSER,190,120,150,290,$bnames[1]);
    fl_set_object_callback($obj, "br_callback", 1);
  $br[2] = $obj = fl_add_browser(FL_HOLD_BROWSER,360,120,150,290,$bnames[2]);
    fl_set_object_color($obj,$obj->col1,FL_GREEN);
    fl_set_object_callback($obj, "br_callback", 2);
  $br[3] = $obj = fl_add_browser(FL_MULTI_BROWSER,530,120,150,290,$bnames[3]);
    fl_set_object_color($br[3],$obj->col1,FL_CYAN);
    fl_set_object_callback($obj, "br_callback", 3);

  $exitobj = $obj = fl_add_button(FL_NORMAL_BUTTON,560,510,120,30,"Exit");
  $obj = fl_add_button(FL_NORMAL_BUTTON,560,460,120,30,"Deselect");
    fl_set_object_callback($obj,"deselect",0);

  fl_bgn_group();
  $obj = fl_add_lightbutton(FL_RADIO_BUTTON,20,500,100,30,"Tiny");
    fl_set_object_lsize($obj,FL_TINY_SIZE);
    fl_set_object_callback($obj,"set_size",FL_TINY_SIZE);
  $obj = fl_add_lightbutton(FL_RADIO_BUTTON,130,500,100,30,"Small");
    fl_set_object_lsize($obj,FL_SMALL_SIZE);
    fl_set_object_callback($obj,"set_size",FL_SMALL_SIZE);
    fl_set_button($obj,1);
  $obj = fl_add_lightbutton(FL_RADIO_BUTTON,240,500,100,30,"Normal");
    fl_set_object_lsize($obj,FL_NORMAL_SIZE);
    fl_set_object_callback($obj,"set_size",FL_NORMAL_SIZE);
  $obj = fl_add_lightbutton(FL_RADIO_BUTTON,350,500,100,30,"Large");
    fl_set_object_lsize($obj,FL_LARGE_SIZE);
    fl_set_object_callback($obj,"set_size",FL_LARGE_SIZE);
  fl_end_group();

  fl_bgn_group();
  $obj = fl_add_lightbutton(FL_RADIO_BUTTON,20,450,100,30,"Normal");
    fl_set_object_callback($obj,"set_style",FL_NORMAL_STYLE);
    fl_set_button($obj,1);
  $obj = fl_add_lightbutton(FL_RADIO_BUTTON,120,450,100,30,"Bold");
    fl_set_object_callback($obj,"set_style",FL_BOLD_STYLE);
  $obj = fl_add_lightbutton(FL_RADIO_BUTTON,220,450,100,30,"Italic");
    fl_set_object_callback($obj,"set_style",FL_ITALIC_STYLE);
  $obj = fl_add_lightbutton(FL_RADIO_BUTTON,320,450,100,30,"BoldItalic");
    fl_set_object_callback($obj,"set_style",FL_BOLDITALIC_STYLE);
  $obj = fl_add_lightbutton(FL_RADIO_BUTTON,420,450,100,30,"Fixed");
    fl_set_object_callback($obj,"set_style",FL_FIXED_STYLE);
  fl_end_group();
  fl_end_form();
}


sub fill_browsers {

  for ($i=0; $i<4; $i++) {
    for ($j=1; $j<=100; $j++) {
      if ( $j == 5) {
        $buf = "\@NLine with qb $j";
      } elsif ( $j == 10) {
        $buf = "\@-";
      } else {
        $buf = "Line with qb $j";
      }
      fl_add_browser_line($br[$i],$buf);
    }
  }
}
