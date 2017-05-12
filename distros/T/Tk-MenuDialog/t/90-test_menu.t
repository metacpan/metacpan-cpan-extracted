##----------------------------------------------------------------------------
## :mode=perl:indentSize=2:tabSize=2:noTabs=true:
##----------------------------------------------------------------------------
##        File: 90-test_menu.t
## Description: Test the Tk::MenuDialog module
##----------------------------------------------------------------------------
use Test::More;
use Tk;
use Tk::MenuDialog;
use Readonly;

## From http://wiki.cpantesters.org/wiki/CPANAuthorNotes the 
## "Why are you testing (and failing) my Tk-ish module without an X server?"
## Tk now will load without an X Server, so we need to check that we
## have a server before running any tests

my $mw = eval { MainWindow->new };
if ($mw)
{
  ## MainWindow successfully created, 
  ## Destory the window, and continue with tests
  $mw->destroy;
  diag(qq{Successfully created a Tk MainWindow, we must have an X-Server});
}
else
{
  ## Could not create MainWindow, skip the tests 
  plan(skip_all => 'No X Server detected');
}

##---------------------------------------
## Hash used to initialize the menu
##---------------------------------------
Readonly::Scalar my $TEST_MENU => {
  title => qq{Tk::MenuDialog TEST},
  can_cancel => 0,
  button_spacing => 20,
  items => [
    {
      label => qq{Button &1},
    },
    {
      label => qq{Button &2},
    },
    {
      label => qq{Button &3},
    },
  ],
};

##----------------------------------------------------------------------------
## Main code
##----------------------------------------------------------------------------
my $button;
my $menu = Tk::MenuDialog->new->initialize($TEST_MENU);

## Stop testing if we didn't create the menu
BAIL_OUT('Could not create menu') unless ($menu);

## Check menu cancel
my $result = $menu->show(qq{TEST: -1});
ok(!defined($result), 'Menu cancel detected');

## Check menu selection
$button = 0;
$result = $menu->show(qq{TEST: $button});
ok(eq_hash($result, $TEST_MENU->{items}->[$button]), 'Menu selection detected');

done_testing();