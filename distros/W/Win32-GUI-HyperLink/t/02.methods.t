#!perl -w
# Check that the module has the public methods that we are expecting
use strict;
use warnings;

use Test::More tests => 1;

use Win32::GUI::Hyperlink;

# new, Url, Launch
can_ok('Win32::GUI::HyperLink', qw(new Url Launch) );
