#!/usr/bin/perl
#/* Showing all different charts */

use X11::Xforms;
#use Forms_PLOT_OBJS;

  fl_initialize("FormDemo");

  $form = fl_bgn_form(FL_NO_BOX,940,360);
  $obj = fl_add_box(FL_UP_BOX,0,0,940,360,"");
  $barchart = $obj = fl_add_chart(FL_BAR_CHART,20,20,210,140,"BAR_CHART");
    fl_set_object_boxtype($obj,FL_RSHADOW_BOX);
  $linechart = $obj = fl_add_chart(FL_LINE_CHART,250,20,210,140,"LINE_CHART");
    fl_set_object_boxtype($obj,FL_RSHADOW_BOX);
  $filledchart = $obj = fl_add_chart(FL_FILLED_CHART,250,190,210,140,"FILLED_CHART");
    fl_set_object_boxtype($obj,FL_RSHADOW_BOX);
  $piechart = $obj = fl_add_chart(FL_PIE_CHART,480,190,210,140,"PIE_CHART");
    fl_set_object_boxtype($obj,FL_RSHADOW_BOX);
  $specialpiechart = $obj = fl_add_chart(FL_SPECIALPIE_CHART,710,20,210,140,"SPECIALPIE_CHART");
    fl_set_object_boxtype($obj,FL_RSHADOW_BOX);
  $exitbut = $obj = fl_add_button(FL_NORMAL_BUTTON,750,260,140,30,"Exit");
  $horbarchart = $obj = fl_add_chart(FL_HORBAR_CHART,20,190,210,140,"HORBAR_CHART");
    fl_set_object_boxtype($obj,FL_RSHADOW_BOX);
  $spikechart = $obj = fl_add_chart(FL_SPIKE_CHART,480,20,210,140,"SPIKE_CHART");
    fl_set_object_boxtype($obj,FL_RSHADOW_BOX);
  fl_end_form();

  fill_in($barchart);
  fill_in($horbarchart);
  fill_in($linechart);
  fill_in($filledchart);
  fill_in($spikechart);
  fill_in($piechart);
  fill_in($specialpiechart);
  fl_show_form($form,FL_PLACE_CENTER,FL_FULLBORDER,NULL);
  fl_do_forms();

sub fill_in
{
  my($ob) = @_;
  $c = FL_BLACK;
  fl_add_chart_value($ob,15.0,"item 1",++$c);
  fl_add_chart_value($ob,5.0,"item 2",++$c);
  fl_add_chart_value($ob,0.0,"item 3",++$c);
  fl_add_chart_value($ob,-10.,"item 4",++$c);
  fl_add_chart_value($ob,25.0,"item 5",++$c);
  fl_add_chart_value($ob,12.0,"item 6",++$c);
}

