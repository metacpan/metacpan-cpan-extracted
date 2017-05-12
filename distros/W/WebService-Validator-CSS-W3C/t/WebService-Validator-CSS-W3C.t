# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WebService-Validator-CSS-W3C.t'

#########################

# change 'tests => 3' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 3 };
use WebService::Validator::CSS::W3C;
ok(1); # If we made it this far, we're ok.
 my $val = WebService::Validator::CSS::W3C->new;
ok(2);
my $success = $val->validate(uri => 'http://www.w3.org/');
printf "  * %s\n", $_->{message}
        foreach $val->errors;
ok(3);
my $som = $val->som;
print $som;
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

