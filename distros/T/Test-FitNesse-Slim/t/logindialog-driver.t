use strict;
use warnings;
use Test::More;

use lib 't/lib';

my $class = 'Fitnesse::Slim::Test::LoginDialogDriver';
my $loaded = eval "require $class; 1";
ok($loaded, 'load upstream LoginDialogDriver fixture');
if (!$loaded) {
    diag $@;
    done_testing;
    exit;
}

my $fixture = $class->new('bob', 'xyzz');
is($fixture->number_of_login_attempts, 0, 'attempt count begins at zero');
is($fixture->login_with_username_and_password('bob', 'xyzz'), 'true', 'valid credentials log in');
is($fixture->login_message, 'bob logged in.', 'successful login message matches upstream');
is($fixture->number_of_login_attempts, 1, 'successful login increments attempts');
is($fixture->login_with_username_and_password('bob', 'wrong'), 'false', 'invalid credentials are rejected');
is($fixture->login_message, 'bob not logged in.', 'failed login message matches upstream');
is($fixture->number_of_login_attempts, 2, 'failed login increments attempts');

done_testing;
