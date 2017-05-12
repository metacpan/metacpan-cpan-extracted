use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'Vote' }
BEGIN { use_ok 'Vote::Controller::Vote' }

ok( request('/vote')->is_success, 'Request should succeed' );


