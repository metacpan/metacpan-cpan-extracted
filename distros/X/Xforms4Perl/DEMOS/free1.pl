#!/usr/bin/perl
#/* This demo is meant to demonstrate the use of a free
#   object in a form. It also demonstrates the use of the
#   u_ldata field in the FL_OBJECT structure (and, thus, the
#   u_vdata fields in the FL_FORM and FL_OBJECT structures)
#*/
use X11::Xforms;
#use Forms_DRAW;

  $dcol = $on = 1;
 
  fl_initialize("FormDemo");

  $form = fl_bgn_form(FL_UP_BOX,400.0,400.0);
  $obj = fl_add_button(FL_NORMAL_BUTTON,320.0,20.0,40.0,30.0,"Exit");
  fl_set_object_callback($obj, "done", 0);
  $obj = fl_add_free(FL_CONTINUOUS_FREE,40.0,80.0,320.0,280.0,"","handle_it");
  fl_end_form();
  $depth  = fl_get_visual_depth();
#  /* can't do it if less than 4 bit deep */
   die("This Demo requires a depth of at least 4 bits\n") if($depth < 4);

  $cole = ((1 << $depth)-1);
  $cole = 64 if ($cole > 64);

  $obj->u_ldata($col = FL_FREE_COL1);
  $cole += $col;

  for ( $i = $col; $i <= $cole; $i++)
  {
     $j = 255.0 * ($i - $col) / ($cole  - $col);
     fl_mapcolor($i, $j, $j, $j);
  }

  fl_show_form($form,FL_PLACE_CENTER,FL_NOBORDER,"Free Object");
  fl_do_forms();

#/* The call back routine */
sub handle_it {

  	my($obj, $event, $mx, $my, $key, $ev) = @_;

	if ($event == FL_DRAW) {
		fl_roundrectf($obj->x,$obj->y,$obj->w,$obj->h, $obj->u_ldata);
	} elsif ($event == FL_RELEASE) {
		$on = !$on;
	} elsif ($event == FL_STEP) {
		if ($on)
		{ 
			$u_ldata = $obj->u_ldata;
			$dcol = -1 if ($u_ldata == $cole); 
			$dcol = 1  if ($u_ldata == FL_FREE_COL1); 
			$u_ldata += $dcol;
			$obj->u_ldata($u_ldata);
			fl_redraw_object($obj);
		}
	}
	return 0;
}

sub done { exit(0);}
