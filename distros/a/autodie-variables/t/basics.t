#perl

use strict;
use warnings;

use autodie::variables;
use Test::More;
use Test::Exception;
use POSIX qw/uname/;

use if $^O ne 'MSWin32', POSIX => qw/setlocale LC_ALL/;
setlocale(&LC_ALL, 'C') if $^O ne 'MSWin32';

if ($> == 0) {
	diag("Running tests as root, dropping privileges first");
	my $id = $ENV{TEST_USER_ID} || 1000;
	setuid($id); # Can't use $>/$< here, as the saved user id needs to be set too.
}
SKIP: {
	skip 'Old darwin doesn\'t have usable setr[ug]id', 2 if $^O eq 'darwin' and (uname)[2] lt '9';
	dies_ok { $< = 0 } 'Setting $< dies';
	dies_ok { $( = 0 } 'Setting $( dies';
}
dies_ok { $> = 0 } 'Setting $> dies';
dies_ok { $) = 0 } 'Setting $) dies';

done_testing();
