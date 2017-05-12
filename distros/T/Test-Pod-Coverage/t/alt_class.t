#!perl -T

use strict;
use lib "t";
use Test::More tests=>2;
use Test::Builder::Tester;

BEGIN { use_ok( 'Test::Pod::Coverage' ); }

# the follow test checks that PC_Inherits.pm is fully covered, which it is not
# -- unless you count the documentation of its parent, PC_Inherited; we do this
# with the Pod::Coverage::CountParents subclass of Pod::Coverage -- so, if this
# test passes, it means the subclass was, in fact, used
test_out( "ok 1 - Checking PC_Inherits" );
pod_coverage_ok(
  "PC_Inherits",
  { coverage_class => 'Pod::Coverage::CountParents' },
  "Checking PC_Inherits",
);

test_test( "allows alternate Pod::Coverage class" );
