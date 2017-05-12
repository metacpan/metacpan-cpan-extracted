# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WWW-CheckPad.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN {
    use_ok('WWW::CheckPad');
};


#########################

WWW::CheckPad->connect(
    email => 'your email address here',
    password => 'your passowrd here',
);

ok ($WWW::CheckPad::connection->has_logged_in(), 'has logged in');



