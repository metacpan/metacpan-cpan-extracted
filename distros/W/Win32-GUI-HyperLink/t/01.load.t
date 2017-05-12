#!perl -w
# Check that the module loads stand-alone
use strict;
use warnings;

use Test::More tests => 1;

use_ok( 'Win32::GUI::HyperLink' );
diag( "Testing Win32::GUI::HyperLink $Win32::GUI::HyperLink::VERSION" );
