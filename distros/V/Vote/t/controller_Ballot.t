use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'Vote' }
BEGIN { use_ok 'Vote::Controller::Ballot' }

ok( request('/ballot')->is_success, 'Request should succeed' );


