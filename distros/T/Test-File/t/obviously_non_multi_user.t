use Test::More 0.95;

BEGIN {
	our $getpwuid_should_die = 0;
	our $getgrgid_should_die = 0;
	};

BEGIN{
	no warnings;

	*CORE::GLOBAL::getpwuid = sub ($) { die "Fred"   if $getpwuid_should_die };
	*CORE::GLOBAL::getgrgid = sub ($) { die "Barney" if $getgrgid_should_die };
	}

use_ok( 'Test::File' );

ok( defined &{ "Test::File::_obviously_non_multi_user" }, "_win32 defined" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# The ones that we know aren't multi-user
subtest macos_single_user => sub {
	local $^O = 'MacOS';
	ok( Test::File::_obviously_non_multi_user(), "Returns false for MacOS" );
	};

subtest dos_single_user => sub {
	local $^O = 'dos';
	ok( Test::File::_obviously_non_multi_user(), "Returns true for Win32" );
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# The ones that use get*, but die
subtest getpwuid_should_die => sub {
	local $^O = 'Fooey';
	$getpwuid_should_die = 1;
	$getgrgid_should_die = 0;
	ok( Test::File::_obviously_non_multi_user(), 'getpwuid dying returns true' );
	};

subtest getgrgid_should_die => sub {
	local $^O = 'Fooey';
	$getpwuid_should_die = 0;
	$getgrgid_should_die = 1;
	ok( Test::File::_obviously_non_multi_user(), 'getgrgid dying returns true' );
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# The ones that use get*, but don't die
subtest nothing_dies => sub {
	local $^O = 'Fooey';
	$getpwuid_should_die = 0;
	$getgrgid_should_die = 0;
	ok( ! Test::File::_obviously_non_multi_user(), 'getpwuid dying returns true' );
	};

done_testing();
