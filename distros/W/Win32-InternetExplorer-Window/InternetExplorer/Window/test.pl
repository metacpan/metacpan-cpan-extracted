# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 4 };
use Win32::InternetExplorer::Window;
ok(1); # Loaded

# New invisable window
my $test = Win32::InternetExplorer::Window->new(start_hidden => 1);
ok($test);

# Navigate to Site
$test->display('http://www.cpan.org');
ok($test->is_busy);

$test->refresh_wait('http://www.cpan.org');
if ($test->is_closed()) {
    ok(undef);
} else {
    ok(1);
}



