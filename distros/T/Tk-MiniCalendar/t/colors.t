#########################
use strict;
use warnings;
use Test::More 'no_plan';
use Tk;
use Tk::MiniCalendar;
ok(1, "load module"); # If we made it this far, we're ok.

#########################
my $top = MainWindow->new(-title => "colors");
if (! $top) {
  # there seems to be no x-server available or something else went wrong
  # .. skip all tests
  exit 0;
}

my $frm1=$top->Frame->pack;
my $frm2=$top->Frame->pack;
my $frm3=$top->Frame->pack;
#------------- use MiniCalendar widget:
my $minical=$frm1->MiniCalendar(
  -fg_color => "#bef271",
  -bg_color => "#004000",
  -bg_label_color => "#009b00",
  -fg_label_color => "#dddddd",
  -bg_sel_color => "#FFFFFF",
  -fg_sel_color => "#7b112c",

)->pack(-pady => 4, -padx => 4);
#-------------
$minical->configure(
  -day => 13,
  -month => 7,
  -year => 2008,
);

my $text = $frm2->Label(
  -text => "
  Click 'Ok' if MiniCalendar shows up in different green colors
  Otherwise click 'Not Ok'
  ",
)->pack;

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
    s_noc();
   },
)->pack(-side => "left", -padx => 2, -pady => 2);

if (! $ENV{INTERACTIVE_MODE}){
  $top->after(500, sub{s_ok()});
}
MainLoop;

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
