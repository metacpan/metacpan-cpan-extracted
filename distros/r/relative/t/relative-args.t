#!perl -Tw
package BigApp::Report;
use strict;
use Test::More;
use lib "t";

plan tests => 7;

use_ok( "relative" );

# load modules with empty import lists
my @loaded = import relative Create => [], "::Tools", Publish => [], "::Utils";
is_deeply( 
    \@loaded, 
    [qw(BigApp::Report::Create  BigApp::Tools  BigApp::Report::Publish  BigApp::Utils)], 
    "check that the modules were correctly loaded"
);
ok( !exists $BigApp::Report::{new_report}, 
    "check that the function 'new_report' was not imported" );
ok( !exists $BigApp::Report::{render}, 
    "check that the function 'render' was not imported" );

# load modules with non-empty import lists
@loaded = import relative Create => ["new_report"], "::Tools", Publish => ["render"], "::Utils";
is_deeply( 
    \@loaded, 
    [qw(BigApp::Report::Create  BigApp::Tools  BigApp::Report::Publish  BigApp::Utils)], 
    "check that the modules were correctly loaded"
);
can_ok( __PACKAGE__, "new_report" );
can_ok( __PACKAGE__, "render" );
