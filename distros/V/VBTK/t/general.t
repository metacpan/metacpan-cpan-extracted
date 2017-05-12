# Test script for general VBTK functionality

# Setup the test plan
use Test;
BEGIN { plan tests => 3 };

use VBTK::Common;

# Make sure fork works.
$result = &testFork ||
  warn("Fork test failed, can't run VBTK without 'fork'");
ok($result,1,"Fork test failed");

# Make sure we can use the 'alarm' function.
$result = &testAlarm ||
  warn("Alarm test failed, can't run VBTK without 'alarm'");
ok($result,1);

# Test the logging subroutine
$result = &log("Testing Log") ||
  warn("Log test failed, can't run VBTK::Common::log");
ok($result,1);
