#########################
use strict;
use warnings;
use Test::More 'no_plan';
use Tk;
use Tk::MiniCalendar;
ok(1, "load module"); # If we made it this far, we're ok.

#########################
my $top = MainWindow->new(-title => "configure");
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
)->pack(-pady => 4, -padx => 4);
#-------------
$minical->configure(
  -day => 13,
  -month => 7,
  -year => 2008,
);

my $text = $frm2->Label(
  -text => "
  Click 'Ok' if you see 13 July 2008 in highlight color (blue).
  Otherwise click 'Not Ok'

  Try also '<<', '<', '>' and '>>' buttons.
  Click 'Ok' if all tests are ok.
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
