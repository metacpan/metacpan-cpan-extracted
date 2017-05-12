use strict;
use warnings;
use Test::PAUSE::Permissions;

local $ENV{RELEASE_TESTING} = 1;

all_permissions_ok('ISHIGAKI');
