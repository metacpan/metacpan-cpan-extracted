#########################
use strict;
use warnings;
use Test::More 'no_plan';
use Tk;
use Tk::MiniCalendar;
use Date::Calc qw(Add_Delta_YM Today);
ok(1, "load module"); # If we made it this far, we're ok.

#########################
my $top = MainWindow->new(-title => "select");
if (! $top) {
  # there seems to be no x-server available or something else went wrong
  # .. skip all tests
  exit 0;
}

my $frm1=$top->Frame->pack;
my $frm2=$top->Frame->pack;
my $frm4=$top->Frame->pack;
my $frm3=$top->Frame->pack;
#------------- use MiniCalendar widget:
# use default values

my ($y, $m, $d) = Today;

my $minical=$frm1->MiniCalendar(
)->pack(-pady => 4, -padx => 4);
#-------------

my $text = $frm2->Label(
  -text => "
  The selected date should be today.

  Try also selecting other days. Scrolling back
  and forth must not alter the selected day.
  Check the selected date with the 'Check' button.

  Click 'Ok' if all seems to work correctly.
  Otherwise click 'Not Ok'
  ",
)->pack;



my $l_check;
my $b_check = $frm4->Button(
  -text      => "Check",
  -width     => 7,
  -command   => sub{
    my ($y, $m, $d) = $minical->date;
    my $text = "$d.$m.$y";
    $l_check->configure(-text => $text);
   },
)->pack(-side => "left", -padx => 2, -pady => 2);
$l_check = $frm4->Label(
  -text => "",
  -width => 14,
  -relief => "sunken",
)->pack(-side => "left", -padx => 2, -pady => 2);

#-------
my $b_ok = $frm3->Button(
  -text      => "Ok",
  -width     => 4,
  -command   => sub{
    s_ok();
   },
)->pack(-side => "left", -padx => 2, -pady => 2);

my $b_nok = $frm3->Button(
  -text      => "Not Ok",
  -width     => 8,
  -command   => sub{
    s_nok();
   },
)->pack(-side => "left", -padx => 2, -pady => 2);

$top->after(100, sub{check_today()});
if (! $ENV{INTERACTIVE_MODE}){
  $top->after(500, sub{s_ok()});
}
MainLoop;

sub check_today {
  my ($cal_y, $cal_m, $cal_d) = $minical->date;
  is($cal_y + 0, $y + 0, "curret year");
  is($cal_m + 0, $m + 0, "curret month");
  is($cal_d + 0, $d + 0, "curret day");

  # switch to next months and check month display label
  my @MM = $minical->_get_month_names;
  for (my $k=1; $k<13; $k++) {
    my ($ny, $nm, $nd) = Add_Delta_YM($y, $m, $d, 0, $k);
    $minical->display_month($ny, $nm);
    my $mm = $minical->_get_month_label();
    my $index = ($k + $m - 1) % 12;
    is($mm, $MM[$index], "month label $MM[$index]");
  }
  # switch back to current month
  $minical->display_month($y, $m);
}

sub s_ok {
  ok(1, "ok button");
  exit;
}
sub s_nok {
  ok(0, "not ok button");
  exit;
}
__END__

 vim:foldmethod=marker:foldcolumn=4:ft=perl
