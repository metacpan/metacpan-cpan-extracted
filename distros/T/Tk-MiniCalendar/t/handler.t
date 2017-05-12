#! d:/perl587/bin/perl.exe
#########################
use strict;
use warnings;
use Test::More 'no_plan';
use Tk;
use Tk::MiniCalendar;
ok(1, "load module"); # If we made it this far, we're ok.

#########################
my $top = MainWindow->new(-title => "handler");
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
my $minical=$frm1->MiniCalendar(
  -day => 16,
  -month => 5,
  -year => 2006,
)->pack(-pady => 4, -padx => 4);
#-------------

# try to use handlers:
my $ctext;
$minical->register('<Button-1>', sub{
  $ctext->configure(-text => "Button-1  on $_[2].$_[1].$_[0]");
});
$minical->register('<Button-2>', sub{
  $ctext->configure(-text => "Button-2  on $_[2].$_[1].$_[0]");
});
$minical->register('<Button-3>', sub{
  $ctext->configure(-text => "Button-3  on $_[2].$_[1].$_[0]");
});


$minical->register('<Double-1>', sub{
  $ctext->configure(-text => "Double-1  on $_[2].$_[1].$_[0]");
});
$minical->register('<Double-2>', sub{
  $ctext->configure(-text => "Double-2  on $_[2].$_[1].$_[0]");
});
$minical->register('<Double-3>', sub{
  $ctext->configure(-text => "Double-3  on $_[2].$_[1].$_[0]");
});







my $text = $frm2->Label(
  -text => "
  Start date should be 16. Mai 2006.

  Try to use Button-1, Button-2, Button-3
  and Double-1, Double-2 and Double-3
  on different days.

  Click 'Ok' if all tests are ok.
  ",
)->pack;

$ctext = $frm2->Label(
  -text => "",
  -width => 20,
  -relief => "sunken",
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


#check start date:
my ($sy, $sm, $sd) = $minical->date;
is($sy, 2006, "start date: year");
is($sm, "05", "start date: month");
is($sd, 16, "start date: day");

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
