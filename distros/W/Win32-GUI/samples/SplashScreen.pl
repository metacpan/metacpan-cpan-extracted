#!perl -w

# Demonstrate how to do a Splash Screen for your application
# Original code by Jeremy White, modified by Robert May
# Note that the package Win32::GUI::SplashScreen, available
# from CPAN and from http://www.robmay.me.uk/win32gui/ can
# do all this and more for you

use strict;
use warnings;
use FindBin();
use Win32::GUI qw( WS_POPUP WS_CAPTION WS_THICKFRAME WS_EX_TOPMOST );

#try to load the splash bitmap from the exe that is running
my $splashimage= new Win32::GUI::Bitmap('SPLASH');

unless ($splashimage) {
    #bitmap is not in exe, load from file
    $splashimage= new Win32::GUI::Bitmap("$FindBin::Dir/SPLASH.bmp");
}

die 'could not find splash bitmap' unless $splashimage;
#get the dimensions of the bitmap
my ($width,$height)       = $splashimage->Info();
  
#create the splash window
my $splash     = new Win32::GUI::Window (
   -name       => "Splash",
   -text       => "Splash",
   -height     => $height, 
   -width      => $width,
   -left       => 100, 
   -top        => 100,
   -addstyle   => WS_POPUP,
   -popstyle   => WS_CAPTION | WS_THICKFRAME,
   -addexstyle => WS_EX_TOPMOST
);

#create a label in which the bitmap will be placed
my $bitmap    = $splash->AddLabel(
    -name     => "Bitmap",
    -left     => 0,
    -top      => 0,
    -width    => $width,
    -height   => $height,
    -bitmap   => $splashimage,
);  

#center the splash and show it
$splash->Center();
$splash->Show();
#call do events - not Dialog - this will display the window and let us 
#build the rest of the application.
Win32::GUI::DoEvents();

#In this case, we'll create the main window and
#sleep to simulate doing some work.
my $mainwin = new Win32::GUI::Window (
    -name   => "Main",
    -text   => "Main window",
    -height => 400, 
    -width  => 500,
); 
$mainwin->Center();

sleep(2);

#Show the main window ...
$mainwin->Show();
Win32::GUI::DoEvents();

sleep(1);

# ... hide the splash and enter the Dialog phase
$splash->Hide;
Win32::GUI::Dialog();
