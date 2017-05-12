#!/usr/bin/perl
use X11::Xforms;
#/* Demo showing the use of xyplot overlay. */

$fff = undef;
$xyplot = undef;

    fl_initialize("Overlay Demo");

    create_form_fff();

    init_xyplot($fff);

    fl_show_form($fff, FL_PLACE_MOUSE, FL_TRANSIENT, "XYPlot Overlay");
    fl_do_forms();
    exit 0;

sub init_xyplot
{
    for ($i = 0, $j = 0; $i <= 10; $i++, $j+=2)
    {
	$xy[$j] = $i;
	$xy[$j+1] = exp(-($xy[$j] - 5) * ($xy[$j] - 5) / 8);
    }


    fl_set_xyplot_data($xyplot, @xy, "", "", "");
    fl_set_xyplot_ybounds($xyplot, 0, 1.1);
    fl_set_xyplot_xbounds($xyplot, 0, 10);
    fl_add_xyplot_overlay($xyplot, 1, @xy, FL_BLUE);
    fl_set_xyplot_overlay_type($xyplot, 1, FL_DOTTED_XYPLOT);
    fl_set_xyplot_interpolate($xyplot, 1, 2, 0.1);

    fl_add_xyplot_text($xyplot, 0.5, 1.0, "Gaussian\nDistribution",
                          FL_ALIGN_RIGHT, FL_BLUE);

    fl_set_xyplot_key($xyplot, 0, "Original");
    fl_set_xyplot_key($xyplot, 1, "Overlay");
    fl_set_xyplot_key_position($xyplot, 9.8, 1.08, FL_ALIGN_BOTTOM_LEFT);
}

sub create_form_fff
{

    $fff = fl_bgn_form(FL_NO_BOX, 370, 310);
    $obj = fl_add_box(FL_UP_BOX, 0, 0, 370, 310, "");
    $xyplot = $obj = fl_add_xyplot(FL_IMPULSE_XYPLOT, 10, 20, 350, 260, "");
      fl_set_object_lalign($obj, FL_ALIGN_BOTTOM | FL_ALIGN_INSIDE);
      fl_set_object_lsize($obj, FL_NORMAL_SIZE);
    $obj = fl_add_button(FL_HIDDEN_BUTTON, 10, 10, 350, 290, "");
      fl_set_button_shortcut($obj,"qQ", 0);
    fl_end_form();
}

