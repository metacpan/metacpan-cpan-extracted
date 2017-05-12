##----------------------------------------------------------------------------
## :mode=perl:indentSize=2:tabSize=2:noTabs=true:
##----------------------------------------------------------------------------
##        File: release-kwalitee.t
## Description: Run the kwalitee tests
##----------------------------------------------------------------------------
## NOTE:
##    Originally was allowing Dist::Zilla automatically generate this but
##    found it would not work on one of my Windows 7 64-bit system, but worked
##    fine in linux.
##    Added ability to skip the test if SKIP_KWALITEE environment variable
##    is defined.
##----------------------------------------------------------------------------
use strict;
use warnings;
use Test::More 0.88;
## See if the Test::Kwalitee module is installed
eval "use Test::Kwalitee 1.21 'kwalitee_ok'";
## Skip if the module is non installed
plan skip_all => "Test::Kwalitee 1.21 required for testing kwalitee" if $@;

BEGIN {
  require Test::More;
  
  if ($ENV{SKIP_KWALITEE})
  {
    Test::More::plan(skip_all => 'SKIP_KWALITEE defined, skipping Kwalitee tests.');
  }
  
  unless ($ENV{RELEASE_TESTING}) {
    
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

kwalitee_ok();

done_testing;
