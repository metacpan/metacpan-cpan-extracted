#########################
use strict;
use warnings;
use Test::More 'no_plan';
use Tk;
use Tk::MiniCalendar;
ok(1, "load module"); # If we made it this far, we're ok.

#########################
my $top = MainWindow->new(-title => "englisch");
if (! $top) {
  # there seems to be no x-server available or something else went wrong
  # .. skip all tests
  exit 0;
}

my $frm1=$top->Frame->pack;
my $frm2=$top->Frame->pack;
my $frm3=$top->Frame->pack;
#------------- use MiniCalendar widget:
# use english day and month names

my @daynames = qw( Mon Tue Wed Thu Fri Sat Sun);
my @monnames = qw(
  January Ferburary March April May June July August September October November December
);
my $minical=$frm1->MiniCalendar(
  -day => 31,
  -month => 8,
  -year => 2003,
  -month_names => \@monnames,
  -day_names => \@daynames,
)->pack(-pady => 4, -padx => 4);
#-------------

my $text = $frm2->Label(
  -text => "
  Click 'Ok' if all day and month names are in English.
  The selected date should be 31 August 2003.

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
    s_nox();
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
