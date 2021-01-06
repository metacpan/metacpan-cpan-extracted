use strict;
use warnings;

use Test::Builder::Tester;
use Test::More 0.95;

subtest load => sub {
	use_ok( 'Test::File' );
	ok( defined &{ "Test::File::_win32" }, "_win32 defined" );
	};

subtest darwin => sub {
	local $^O = 'darwin';
	ok( ! Test::File::_win32(), "Returns false for darwin" );
	};

subtest win32 => sub {
	local $^O = 'Win32';
	ok( Test::File::_win32(), "Returns true for Win32" );
	};

subtest linux_pretend_win32 => sub {
	local %ENV;
	$ENV{PRETEND_TO_BE_WIN32} = 1;
	local $^O = 'linux';
	ok( Test::File::_win32(), "Returns true for linux when ENV{PRETEND_TO_BE_WIN32} is defined" );
	};

subtest file_modes => sub {
	local $^O = 'Win32';

	my @subs = qw(
		file_mode_is file_mode_isnt
		file_executable_ok file_not_executable_ok
		);

	foreach my $sub ( @subs ) {
		no strict 'refs';

		test_out("ok 1 # skip $sub doesn't work on Windows!");
		&{$sub}();
		test_test();
		}
	done_testing();
	};

done_testing();
