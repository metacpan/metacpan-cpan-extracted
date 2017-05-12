# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Tk-EntryCheck.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 2 };
use Tk;
use Tk::EntryCheck;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

warn "\nOne window will pop up now...\n";
my $mw = MainWindow->new();
my $okCount = "";
my $textVar = 123;
my $textVar2 = 999;
my $entry = $mw->EntryCheck( -textvariable => \$textVar,
			     -maxlength => 5,
			     -pattern => qr(\d),
			     )
    ->pack(-side => 'top');
my $entry2 = $mw->EntryCheck( -textvariable => \$textVar2 )
   ->pack(-side => 'top');

$mw->after(1000, \&State1);
# Tk::after
MainLoop();

warn "\nResult: $okCount\n\n";
if ($okCount !~ /failed/) {
    &ok(2); # If we made it this far, we're ok.
} # if
else {
    &ok(0);
} # else
# ------------------------------------------------------------
sub State1 {
    warn "\nThe following line will produce a warning...\n";
    $textVar = "100000";  $okCount .= " ok" if $textVar == 123;
    $mw->update();
    $textVar = 400;       $okCount .= " ok" if $textVar == 400;
    $mw->update();

    warn "\nThe following line will produce a warning...\n";
    $textVar = "aaa";
    $okCount .= " ok" if $textVar eq '400';
    $mw->update();

    $textVar = "";        $okCount .= " ok" if $textVar eq '';
    $mw->update();

    $textVar = 30.0;      $okCount .= " ok" if $textVar == 30;
    $mw->update();

    $textVar2 = "";       $okCount .= " ok" if $textVar eq "";
    $mw->update();

    $textVar2 = "abcde";  $okCount .= " ok" if $textVar eq "abcde";

    $mw->after(1000, \&Finish);
} # State1
# ------------------------------------------------------------
sub Finish {
    $mw->destroy();
} # Finish
# ------------------------------------------------------------
