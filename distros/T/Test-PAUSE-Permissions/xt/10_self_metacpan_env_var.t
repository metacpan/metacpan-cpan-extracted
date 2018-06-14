use strict;
use warnings;
use Test::PAUSE::Permissions;

local $ENV{RELEASE_TESTING} = 1;
local $ENV{TEST_PAUSE_PERMISSIONS_METACPAN} = 1;

all_permissions_ok();
