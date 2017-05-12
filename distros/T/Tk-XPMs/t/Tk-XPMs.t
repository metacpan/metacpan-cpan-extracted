# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Tk-XPMs.t'

#########################

use strict;
use warnings;

#use Test::More tests => 2 + 52;
use Test::More 'no_plan';
BEGIN {
  use Tk::XPMs ":all";
  ok(1, "use");
};

#===================================================================

use Tk;
use Tk::ErrorDialog;

my $top = MainWindow->new();
if (! $top) {
  # there seems to be no x-server available or something else went wrong
  # .. skip all tests
  exit 0;
}


my $VERSION = "1.01";
$top -> configure( -title => "$0   Revision: $VERSION",
);
#

# Menubar
# -------
my $menubar = $top->Frame( -relief => "raised", -borderwidth => 2);

########
# File #
########
my $mb_file = $menubar->Menubutton(
  -text      => "File",
  -underline => 0,
);

$mb_file->separator();
$mb_file->command(
  -label     => "Exit", 
  -command   => sub { 
      ok(1, "exit menu");
      exit 0} ,
  -underline => 0,
);
#-------

# Application window
# ------------------


my $b1 = $top->Button(
  -text     => "click to finish the test ...",
  -command   => sub{
    ok(1, "exit");
    exit;
                },
);

# Status line
# -----------
my $status = "";
my $lb_status_line = $top->Label(
  -textvariable => \$status,
  -relief       => 'sunken',
);

# pack all
# --------
$menubar -> pack(-side => "top", -fill => 'x');
$mb_file -> pack(-side => "left");

$b1 -> pack();
my $frm = $top->Frame();
$frm->pack;

my ($i, $j) = (0, 0);
foreach my $xp ( list_xpms() ) {
foreach my $color ( "", "#ccddee" ) {
  my $p1;
  eval "\$p1 = \$top->Pixmap(-data=>${xp}('$color'));";
  ok(!$@, $xp);
  my $b1 = $frm->Button(
    -image     => $p1,
    -width     => 34,
    -height     => 34,
    -command   => sub{
                    $status = "${xp}('$color')";
                  },
    -state     => "normal",
    ) ;
   
  $b1-> grid(-column => $j, -row => $i, -sticky => "w", -padx => 3, -pady => 3);
  $j = ($j+1)%25;
  $i++ if $j == 0;
} # foreach $color
} # foreach $xp


$lb_status_line -> pack(-side => 'bottom', -expand => 'no', -fill => 'x');

if (! $ENV{INTERACTIVE_MODE}){
$top->after(3000, sub{ ok(1, "Exit 3000"); exit } );
}
# Main Event Loop
# ---------------
MainLoop;

__END__

# vim:ft=perl:foldmethod=marker:foldcolumn=4

