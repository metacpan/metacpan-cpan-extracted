#!perl -wT
# Win32::GUI::SplashScreen dependancies check
use strict;
use warnings;

use Test::More tests => 3;

eval { use Win32::GUI 1.02 (); };
eval { use Win32::GUI::BitmapInline 0.02 (); };
eval { use Win32::GUI::DIBitmap (); };

if (ok($Win32::GUI::VERSION, "Win32::GUI v1.02 or higher" )) {
  diag("Win32::GUI version $Win32::GUI::VERSION found");
} else {
  # If we don't have Win32::GUI 1.0 or higher, no point in continuing
  print "Bail out! Win32::GUI v1.02 or higher required\n";
  exit(1);
}

if (ok($Win32::GUI::BitmapInline::VERSION, "Win32::GUI::BitmapInline v0.02 or higher" )) {
  diag("Win32::GUI::BitmapInline version $Win32::GUI::BitmapInline::VERSION found");
} else {
  # If we don't have Win32::GUI::BitmapInline 0.02 or higher, no point in continuing
  print "Bail out! Win32::GUI::BitmapInline v0.02 or higher required\n";
  exit(1);
}

# Win32::DIBitmap not required
SKIP: {

    skip "Win32::GUI::DIBitmap not installed. See documentation for details", 1 if not defined $Win32::GUI::DIBitmap::VERSION;

    pass("Win32::GUI::DIBitmap") and
      diag("Win32::GUI::DIBitmap version $Win32::GUI::DIBitmap::VERSION found");
}
