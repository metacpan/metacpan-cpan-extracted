#########################
use strict;
use warnings;
use Test::More 'no_plan';
use Tk;
use Tk::MiniCalendar;
ok(1, "load module"); # If we made it this far, we're ok.

#########################
my $top = MainWindow->new(-title => "date_error");
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

eval {
 my $minical=$frm1->MiniCalendar(
  -day => 32,  # Error in date
  -month => 8,
  -year => 2003,
 )->pack(-pady => 4, -padx => 4);
};
print "expected: $@\n";
ok($@, "Error in date");
#-------------

#MainLoop;  # do not start GUI ...

__END__

 vim:foldmethod=marker:foldcolumn=4:ft=perl
