# Test script for VBTK server functionality

# Setup the test plan
use Test;
BEGIN { plan tests => 1 };

use VBTK::Server;
use Cwd;

my $cwd = cwd;

# Initialize a server object.
$server = new VBTK::Server (
     ObjectPrefix	  => 'test',
     HousekeepingInterval => 60,
     ObjectDir            => "$cwd/vbobj",
     DocRoot              => "$cwd/web" );

# Start the server listening and handling requests.
$server->run(1);

ok(1);

