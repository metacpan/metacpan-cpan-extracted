use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'Vote' }
BEGIN { use_ok 'Vote::Controller::Newpoll' }

ok( request('/newpoll')->is_success, 'Request should succeed' );


