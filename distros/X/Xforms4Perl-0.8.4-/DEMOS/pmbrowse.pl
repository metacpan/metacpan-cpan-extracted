#!/usr/bin/perl
#/* Form definition file generated with fdesign. */

use X11::Xforms;
#use Forms_GOODIES;

$ttt = 0;
$bm = $pm = 0;

    fl_initialize("FormDemo");
    create_form_ttt();
    fl_show_form($ttt, FL_PLACE_CENTER, FL_TRANSIENT, "PixmapBrowser");
    fl_set_fselector_placement(FL_PLACE_FREE);
    fl_set_fselector_callback(\&load_file, 0);
    fl_show_fselector("Load a Pixmap file", 0, "*.x?m",0);
    fl_do_forms();

sub load_file
{
     my($fname, $data) = @_;
     $ispix = 0;

     if ($fname =~ /\.(\w+)$/) { 
         $ispix = ($1 eq "xpm"); 
     }

     if($ispix) 
     {
        fl_hide_object($bm);
        fl_show_object($pm);
        fl_free_pixmap_pixmap($pm);
        fl_set_pixmap_file($pm, $fname);
     }
     else 
     {
        fl_hide_object($pm);
        fl_show_object($bm);
        fl_set_bitmap_file($bm, $fname);
     }
     return 1;
}


sub done
{
   exit(0);
}


sub reload
{
   my($ob, $q) = @_;
   fl_set_fselector_placement(FL_PLACE_MOUSE);
   fl_set_fselector_callback("load_file", 0);
   fl_show_fselector("Load a Pixmap file", 0, "*.x?m",0);
}


sub create_form_ttt
{

  return if ($ttt);

  $ttt = fl_bgn_form(FL_NO_BOX,330,320);
  $obj = fl_add_box(FL_UP_BOX,0,0,330,320,"");
  $bm = $obj = fl_add_bitmap(FL_NORMAL_BITMAP,30,20,270,240,"");
  fl_set_object_boxtype($obj, FL_FLAT_BOX);
  $pm = $obj = fl_add_pixmap(FL_NORMAL_PIXMAP,30,20,270,240,"");
  fl_set_object_boxtype($obj, FL_FLAT_BOX);
  $obj = fl_add_button(FL_NORMAL_BUTTON,220,280,90,30,"Done");
  fl_set_object_callback($obj, \&done, 0);
  $obj = fl_add_button(FL_NORMAL_BUTTON,20,280,90,30,"Load");
  fl_set_object_callback($obj, \&reload, 0);
  fl_set_object_shortcut($obj,"L",1);
  fl_end_form();
}
