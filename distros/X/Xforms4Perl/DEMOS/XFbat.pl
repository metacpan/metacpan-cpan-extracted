#!/usr/bin/perl
#
# Battery level from /proc
#

$XFbat = undef;
$pos = undef;
$tim = undef;
$batlevel = undef;
$last_stat = 0;
use X11::Xforms;

   fl_initialize("Battery");

   create_form_XFbat();

   fl_show_form($XFbat,FL_PLACE_FREE,FL_FULLBORDER,"Battery");
   set_positioner();
   fl_do_forms();
   exit 0;

sub set_positioner
{
	open(APM, "/proc/apm");
	$apm = <APM>;
	close APM;

	($drv_ver,
	 $apm_ver,
	 $apm_flag,
	 $ac_stat,
	 $batstat,
	 $batflag,
	 $percent,
	 $time,
	 $units) = split(' ',$apm);
	$percent =~ /(.*)%/;
	$batlevel = $1;
	$batflag = eval($batflag);
	$ac_stat = eval($ac_stat);

	if ($batflag & 0x08) {
		$timeleft = "Charging";
	} elsif ($time == -1) {
		if ($ac_stat & 0x01) {
			$timeleft = "AC adapter";
		} else {
			$timeleft = "Time left: ...";
		}
	} else {
		$timeleft = "Time left: $time $units";
	}
		
	if ($batflag & 0x01) {
		$last_stat = 0;
		$col2 = FL_PALEGREEN;
		$col1 = FL_SLIDER_COL1;
	} elsif ($batflag & 0x02) {
		if ($last_stat < 1) {
			fl_ringbell(100);
			$last_stat = 1;
		}
		$col2 = FL_DARKORANGE;
		$col1 = FL_SLIDER_COL1;
	} else {
		if ($last_stat < 4) {
			fl_ringbell(100);
			$last_stat += 1;
		}
		fl_ringbell(100);
		$col2 = FL_RED;
		$col1 = FL_RED;
	}
	fl_set_slider_value($pos, $batlevel);	
	fl_set_object_color($pos, $col1, $col2);
	fl_set_object_label($tim, $timeleft);
	fl_add_timeout(10000, "set_positioner", 0);
	return;
}
  
sub slider_filter {

	my($obj, $value, $int) = @_;
	$str = "$batlevel";
	return $str;
}

sub create_form_XFbat
{
  $XFbat = fl_bgn_form(FL_NO_BOX, 125, 37);
  $obj = fl_add_box(FL_FLAT_BOX,0,0,125,37,"");
  $tim = $obj = fl_add_text(FL_NORMAL_TEXT,2,0,108,19,"");
    fl_set_object_lsize($obj,FL_NORMAL_SIZE);
    fl_set_object_lalign($obj,FL_ALIGN_CENTER);
    fl_set_object_lstyle($obj,FL_TIMESBOLD_STYLE);
  $pos = $obj = fl_add_valslider(FL_HOR_FILL_SLIDER,2,19,108,16,"");
    fl_set_object_lsize($obj,FL_SMALL_SIZE);
    fl_set_object_lstyle($obj,FL_NORMAL_STYLE);
    fl_set_slider_bounds($obj, 0, 100);
    fl_set_slider_filter($obj, "slider_filter");
    fl_set_slider_step($obj, 1);
    fl_deactivate_object($obj);
  $obj = fl_add_button(FL_NORMAL_BUTTON,111,1,12,34,"X");
  fl_end_form();

  return;
}

