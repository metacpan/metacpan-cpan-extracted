#!perl -Tw
package BigApp::Report;
use strict;
use Test::More;
use lib "t";

plan tests => 2;

use_ok( "relative" );

# check that loading a non-existing module results in failure
my $module = "NoSuchModule";
eval { import relative $module };
like( $@, "/Can't locate BigApp/Report/$module.pm in \@INC/", "checking error" );
