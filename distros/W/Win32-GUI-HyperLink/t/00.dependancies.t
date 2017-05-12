#!perl -w
# Win32::GUI::HyperLink dependancies check
use strict;
use warnings;

use Test::More tests => 1;

if (eval "use Win32::GUI 1.02 (); 1;") {
    pass("Win32::GUI v1.02 or higher available");
} else {
  # If we don't have Win32::GUI 1.02 or higher, no point in continuing
  print "Bail out! Win32::GUI v1.02 or higher required\n";
}
