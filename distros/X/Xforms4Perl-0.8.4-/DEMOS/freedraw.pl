#!/usr/bin/perl
#/* Demo showing the use of a free obejct */

use X11::Xforms;
#use Forms_DRAW;
#use Forms_VAL_OBJS;


$drawfree = "";
$freeobj = "";
$figgrp = "";
$colgrp = "";
$colorobj = "";
$rsli = "";
$gsli = "";
$bsli = "";
$miscgrp = "";
$sizegrp = "";
$hsli = "";
$wsli = "";
@drobj = ("", "", "");

$cur_fig = $saved_figure[0] = alloc_figure(0);
$cur_fign = 0;
@drawfunc = (\&fl_oval, \&fl_rectangle, \&draw_triangle);
$max_w = $max_h = 150;

$dpy = fl_initialize("FormDemo");
create_form_drawfree();
fl_set_object_color($colorobj,FL_FREE_COL1, FL_FREE_COL1);
draw_initialize();
fl_show_form($drawfree, FL_PLACE_CENTER|FL_FREE_SIZE, 
             FL_FULLBORDER, "FreeObject");
fl_do_forms();

sub draw_triangle
{
     my($fill, $x, $y, $w, $h, $col) = @_;

     if($fill) {
       fl_polyf($x, $y+$h-1, $x+$w/2, $y, $x+$w-1, $y+$h-1, $col);
     } else {
       fl_polyl($x, $y+$h-1, 
                     $x+$w/2, $y, $x+$w-1, 
                     $y+$h-1, $x, $y+$h-1, $col);
     }
}  

sub draw_initialize
{
    fl_set_form_minsize($drawfree, 530, 490);
    fl_set_object_gravity($colgrp, WestGravity, WestGravity);
    fl_set_object_gravity($sizegrp, SouthWestGravity, SouthWestGravity);
    fl_set_object_gravity($figgrp, NorthWestGravity, NorthWestGravity);
    fl_set_object_gravity($miscgrp, SouthGravity, SouthGravity);
    fl_set_object_resize($miscgrp, FL_RESIZE_NONE);

    $cur_fig = $saved_figure[0];
    @{$cur_fig->{"c"}} = (127, 127, 127); 
    $cur_fig->{"w"} = $cur_fig->{"h"} = 30;
    $cur_fig->{"drawit"} = \&fl_oval;
    $cur_fig->{"fill"} = 1;
    $cur_fig->{"col"} = FL_FREE_COL1 + 1;

    fl_mapcolor(FL_FREE_COL1, @{$cur_fig->{"c"}}); 
    fl_mapcolor($cur_fig->{"col"}, @{$cur_fig->{"c"}}); 

    fl_set_slider_bounds($wsli, 1, $max_w);
    fl_set_slider_bounds($hsli, 1, $max_h);
    fl_set_slider_precision($wsli, 0);
    fl_set_slider_precision($hsli, 0);
    fl_set_slider_value($wsli, $cur_fig->{"w"});
    fl_set_slider_value($hsli, $cur_fig->{"h"});

#    /* color sliders */
    fl_set_slider_bounds($rsli, 1.0, 0);
    fl_set_slider_bounds($gsli, 1.0, 0);
    fl_set_slider_bounds($bsli, 1.0, 0);

#    /* intial drawing function */
    fl_set_button($drobj[0], 1);

}


sub switch_object
{
    my($ob, $which) = @_;
    $cur_fig->{"drawit"} = $drawfunc[$which];
}

sub change_color
{
    my($ob, $which) = @_;
    ${$cur_fig->{"c"}}[$which] = fl_get_slider_value($ob) * 255;
    fl_mapcolor($cur_fig->{"col"}, @{$cur_fig->{"c"}});
    fl_mapcolor(FL_FREE_COL1, @{$cur_fig->{"c"}});
    fl_redraw_object($colorobj);
}

sub fill_cb
{
    my($ob, $notused) = @_;
    $cur_fig->{"fill"} = !fl_get_button($ob);
}

sub change_size
{
    my($ob, $which) = @_;
    if ($which == 0) {
	$cur_fig->{"w"} = fl_get_slider_value($ob);
    } else {
	$cur_fig->{"h"} = fl_get_slider_value($ob);
    }
}

sub refresh_cb
{
    fl_redraw_object($freeobj);
}

sub clear_cb
{
    my($ob, $notused) = @_;
    @saved_figure = (alloc_figure($cur_fig));
    $cur_fig = $saved_figure[0];
    $cur_fign = 0;
    fl_redraw_object($freeobj);
}

#/*  The routine that does drawing */
sub freeobject_handler
{
    my($ob, $event, $mx, $my, $key, $xev) = @_;

    if ($event == FL_DRAW) {
        if ($cur_fig->{"newfig"} == 1)
        {
	    &{$cur_fig->{"drawit"}}($cur_fig->{"fill"}, 
	                    $cur_fig->{"x"} + $ob->x,
	                    $cur_fig->{"y"} + $ob->y, 
	                    $cur_fig->{"w"}, $cur_fig->{"h"}, 
			    $cur_fig->{"col"}); 
        }
        else
	{
           fl_drw_box($ob->boxtype, $ob->x,    $ob->y,   $ob->w, 
                      $ob->h,       $ob->col1, $ob->bw);

           for ($dr = 0; $dr < $cur_fign; $dr++)
	   {
              $ptr = $saved_figure[$dr];
	      &{$ptr->{"drawit"}}($ptr->{"fill"}, $ptr->{"x"} + $ob->x,
	                            $ptr->{"y"} + $ob->y, 
	                            $ptr->{"w"}, $ptr->{"h"}, $ptr->{"col"});
	   }
	}
	$cur_fig->{"newfig"} = 0;
    } elsif ($event == FL_PUSH) {
	if ($key != 2)
	{
	    $cur_fig->{"x"} = $mx - $cur_fig->{"w"}/2;
	    $cur_fig->{"y"} = $my - $cur_fig->{"h"}/2;

#            /* convert position to relative to the free object */
	    $cur_fig->{"x"} -= $ob->x;
	    $cur_fig->{"y"} -= $ob->y;

	    $cur_fig->{"newfig"} = 1;
	    fl_redraw_object($ob);
	    $saved_figure[$cur_fign+1] = alloc_figure($cur_fig);
	    fl_mapcolor($cur_fig->{"col"}+1, @{$cur_fig->{"c"}});
	    $cur_fig = $saved_figure[++$cur_fign];
	    $cur_fig->{"col"} = $cur_fig->{"col"}+1;
	}
    }
    return 0;
}

sub create_form_drawfree
{

  $drawfree = fl_bgn_form(FL_NO_BOX, 530, 490);
  fl_add_box(FL_UP_BOX,0,0,530,490,"");
  $obj = fl_add_frame(FL_DOWN_FRAME,145,30,370,405,"");
    fl_set_object_gravity($obj, FL_NorthWest, FL_SouthEast);
  $freeobj = $obj = fl_add_free(FL_NORMAL_FREE,145,30,370,405,"",
       "freeobject_handler");
    fl_set_object_gravity($obj, FL_NorthWest, FL_SouthEast);
  $obj = fl_add_checkbutton(FL_PUSH_BUTTON,15,25,100,35,"Outline");
    fl_set_object_color($obj,FL_MCOL,FL_BLUE);
    fl_set_object_gravity($obj, FL_NorthWest, FL_NorthWest);
    fl_set_object_callback($obj,"fill_cb",0);

  $figgrp = fl_bgn_group();
  $drobj[0] = $obj = fl_add_button(FL_RADIO_BUTTON,10,60,40,40,"@#circle");
    fl_set_object_lcol($obj,FL_YELLOW);
    fl_set_object_callback($obj,"switch_object",0);
  $drobj[1] = $obj = fl_add_button(FL_RADIO_BUTTON,50,60,40,40,"@#square");
    fl_set_object_lcol($obj,FL_YELLOW);
    fl_set_object_callback($obj,"switch_object",1);
  $drobj[2] = $obj = fl_add_button(FL_RADIO_BUTTON,90,60,40,40,"@#8>");
    fl_set_object_lcol($obj,FL_YELLOW);
    fl_set_object_callback($obj,"switch_object",2);
  fl_end_group();


  $colgrp = fl_bgn_group();
  $colorobj = $obj = fl_add_box(FL_BORDER_BOX,25,140,90,25,"");
  $rsli = $obj = fl_add_slider(FL_VERT_FILL_SLIDER,25,170,30,125,"");
    fl_set_object_color($obj,FL_COL1,FL_RED);
    fl_set_object_callback($obj,"change_color",0);
    fl_set_slider_return($obj, FL_RETURN_CHANGED);
  $gsli = $obj = fl_add_slider(FL_VERT_FILL_SLIDER,55,170,30,125,"");
    fl_set_object_color($obj,FL_COL1,FL_GREEN);
    fl_set_object_callback($obj,"change_color",1);
    fl_set_slider_return($obj, FL_RETURN_CHANGED);
  $bsli = $obj = fl_add_slider(FL_VERT_FILL_SLIDER,85,170,30,125,"");
    fl_set_object_color($obj,FL_COL1,FL_BLUE);
    fl_set_object_callback($obj,"change_color",2);
    fl_set_slider_return($obj, FL_RETURN_CHANGED);
  fl_end_group();


  $miscgrp = fl_bgn_group();
  $obj = fl_add_button(FL_NORMAL_BUTTON,395,445,105,30,"Quit");
    fl_set_button_shortcut($obj,"Qq#q",1);
  $obj = fl_add_button(FL_NORMAL_BUTTON,280,445,105,30,"Refresh");
    fl_set_object_callback($obj,"refresh_cb",0);
  $obj = fl_add_button(FL_NORMAL_BUTTON,165,445,105,30,"Clear");
    fl_set_object_callback($obj,"clear_cb",0);
  fl_end_group();


  $sizegrp = fl_bgn_group();
  $hsli = $obj = fl_add_valslider(FL_HOR_SLIDER,15,410,120,25,"Height");
    fl_set_object_lalign($obj,FL_ALIGN_TOP);
    fl_set_object_callback($obj,"change_size",1);
     fl_set_slider_return($obj, FL_RETURN_CHANGED);
  $wsli = $obj = fl_add_valslider(FL_HOR_SLIDER,15,370,120,25,"Width");
    fl_set_object_lalign($obj,FL_ALIGN_TOP);
    fl_set_object_callback($obj,"change_size",0);
     fl_set_slider_return($obj, FL_RETURN_CHANGED);
  fl_end_group();
fl_end_form();

}

sub alloc_figure {

	my($copy) = @_;
	if ($copy) {
		return {
		    drawit => $copy->{"drawit"},
		    x => $copy->{"x"},
		    y => $copy->{"y"}, 
		    w => $copy->{"w"}, 
		    h => $copy->{"h"}, 
		    fill => $copy->{"fill"},
		    c => $copy->{"c"},
		    col => $copy->{"col"},
		    newfig => $copy->{"newfig"},
		};
	} else {
		return {
		    drawit => 0,
		    x => 0,
		    y => 0, 
		    w => 0, 
		    h => 0, 
		    fill => 0,
		    c => [0, 0, 0],
		    col => 0,
		    newfig => 0,
		};
	}
}

