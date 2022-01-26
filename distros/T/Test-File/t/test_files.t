use strict;

use Test::Builder::Tester;
use Test::More 1;
use Test::File;

=pod

max_file       non_zero_file  not_readable   readable       zero_file
executable     min_file       not_executable not_writable   writable

=cut

require "./t/setup_common";

diag "Warnings about file_writeable_ok are fine. It's a deprecated name that still works.";

subtest readable => sub {
	my $label = 'file <readable> exists';

	test_out( 'ok 1 - readable exists' );
	file_exists_ok( 'readable' );
	test_out( "ok 2 - $label" );
	file_exists_ok( 'readable', $label );
	test_test();
	done_testing();
	};

subtest exists_fails => sub {
	test_out( 'not ok 1 - fooey exists' );
	test_diag( 'file [fooey] does not exist');
	test_diag( "  Failed test 'fooey exists'");
	test_diag( "  at " . __FILE__ . " line " . (__LINE__+1) . ".");
	file_exists_ok( 'fooey' );
	test_test();
	done_testing();
	};

subtest not_exists => sub {
	my $label = 'file <readable> exists';

	test_out( 'ok 1 - fooey does not exist' );
	file_not_exists_ok( 'fooey' );
	test_out( "ok 2 - $label" );
	file_not_exists_ok( 'fooey', $label );
	test_test();
	done_testing();
	};

subtest not_exists_fails => sub {
	test_out( 'not ok 1 - readable does not exist' );
	test_diag( 'file [readable] exists');
	test_diag( "  Failed test 'readable does not exist'");
	test_diag( "  at " . __FILE__ . " line " . (__LINE__+1) . ".");
	file_not_exists_ok( 'readable' );
	test_test();
	done_testing();
	};

subtest readable => sub {
	test_out( 'ok 1 - readable is readable' );
	file_readable_ok( 'readable' );
	test_out( 'ok 2 - readable really is readable' );
	file_readable_ok( 'readable', 'readable really is readable' );
	test_test();
	done_testing();
	};

subtest readable_fails => sub { SKIP: {
	skip "Superuser has special privileges", 2, is_unix_superuser();
	test_out( 'not ok 1 - writeable is readable' );
	test_diag("file [writeable] is not readable");
	test_diag("  Failed test 'writeable is readable'");
	test_diag( "  at " . __FILE__ . " line " . (__LINE__+1) . ".");
	file_readable_ok( 'writeable' );
	test_test();
	done_testing();
	}};


subtest not_readable_fails => sub { SKIP: {
	skip "Superuser has special privileges", 3, if is_unix_superuser();
	skip "Not possible to make file unreadable on MSYS" if is_msys();
	test_out( 'ok 1 - writeable is not readable' );
	file_not_readable_ok( 'writeable' );
	test_out( 'ok 2 - writeable really is not readable' );
	file_not_readable_ok( 'writeable', 'writeable really is not readable' );
	test_out( 'not ok 3 - readable is not readable' );
	test_diag('file [readable] is readable');
	test_diag("  Failed test 'readable is not readable'");
	test_diag( "  at " . __FILE__ . " line " . (__LINE__+1) . ".");
	file_not_readable_ok( 'readable' );
	test_test();
	done_testing();
	}};

subtest writable_fails => sub {
	my $label = 'writable has custom label';
	test_out( 'ok 1 - writable is writable' );
	file_writable_ok( 'writable' );
	test_out( "ok 2 - $label" );
	file_writable_ok( 'writable', $label );
	if( is_msys() or is_unix_superuser() ) {
		test_out( 'ok 3 - readable is writable' );
		}
	else {
		test_out( 'not ok 3 - readable is writable' );
		test_diag('file [readable] is not writable');
		test_diag("  Failed test 'readable is writable'");
		test_diag( "  at " . __FILE__ . " line " . (__LINE__+2) . ".");
		}
	file_writable_ok( 'readable' );
	test_test();
	done_testing();
	};

subtest not_writable => sub { SKIP: {
	skip "Superuser has special privileges", 1, if is_unix_superuser();
	skip "Not possible to make file unreadable on MSYS" if is_msys();
	test_out( 'ok 1 - readable is not writable' );
	test_out( 'not ok 2 - writable is not writable' );
	test_diag('file [writable] is writable');
	test_diag("  Failed test 'writable is not writable'");
	test_diag( "  at " . __FILE__ . " line " . (__LINE__+2) . ".");
	file_not_writable_ok( 'readable' );
	file_not_writable_ok( 'writable' );
	test_test();
	done_testing();
	}};

subtest executable => sub {
	if (Test::File::_win32()) {
		test_out("ok 1 # skip file_executable_ok doesn't work on Windows");
		test_out("ok 2 # skip file_executable_ok doesn't work on Windows");
		test_out("ok 3 # skip file_executable_ok doesn't work on Windows");
		}
	else {
		test_out("ok 1 - executable is executable");
		test_out("ok 2 - executable really is executable");
		test_out("not ok 3 - not_executable is executable");
		test_diag("file [not_executable] is not executable");
		test_diag("  Failed test 'not_executable is executable'");
		test_diag("  at " . __FILE__ . " line " . (__LINE__+4) . ".");
		}
	file_executable_ok( 'executable' );
	file_executable_ok( 'executable', 'executable really is executable' );
	file_executable_ok( 'not_executable' );
	test_test();
	done_testing();
	};

subtest not_executable => sub {
	if (Test::File::_win32()) {
		test_out("ok 1 # skip file_not_executable_ok doesn't work on Windows");
		test_out("ok 2 # skip file_not_executable_ok doesn't work on Windows");
		test_out("ok 3 # skip file_not_executable_ok doesn't work on Windows");
		}
	else {
		test_out("ok 1 - not_executable is not executable");
		test_out("ok 2 - not_executable really is not executable");
		test_out("not ok 3 - executable is not executable");
		test_diag("file [executable] is executable");
		test_diag("  Failed test 'executable is not executable'");
		test_diag("  at " . __FILE__ . " line " . (__LINE__+4) . ".");
		}
	file_not_executable_ok( 'not_executable' );
	file_not_executable_ok( 'not_executable', 'not_executable really is not executable' );
	file_not_executable_ok( 'executable' );
	test_test();
	done_testing();
	};

subtest mode_is => sub {
	if (Test::File::_win32()) {
		test_out("ok 1 # skip file_mode_is doesn't work on Windows");
		test_out("ok 2 # skip file_mode_is doesn't work on Windows");
		test_out("ok 3 # skip file_mode_is doesn't work on Windows");
		}
	else {
		test_out("ok 1 - executable mode is 0100");
		test_out("ok 2 - executable mode really is 0100");
		test_out("not ok 3 - executable mode is 0200");
		test_diag("file [executable] mode is not 0200");
		test_diag("  Failed test 'executable mode is 0200'");
		test_diag("  at " . __FILE__ . " line " . (__LINE__+4) . ".");
		}
	file_mode_is( 'executable', 0100 );
	file_mode_is( 'executable', 0100, 'executable mode really is 0100' );
	file_mode_is( 'executable', 0200 );
	test_test();
	done_testing();
	};

subtest mode_has => sub {
	if (Test::File::_win32()) {
		test_out("ok 1 # skip file_mode_has doesn't work on Windows");
		test_out("ok 2 # skip file_mode_has doesn't work on Windows");
		test_out("ok 3 # skip file_mode_has doesn't work on Windows");
		test_out("ok 4 # skip file_mode_has doesn't work on Windows" );
		}
	else {
		test_out("ok 1 - executable mode has all bits of 0100");
		test_out("ok 2 - executable mode really has all bits of 0100");
		test_out("not ok 3 - executable mode has all bits of 0200");
		test_diag("file [executable] mode is missing component 0200");
		test_diag("  Failed test 'executable mode has all bits of 0200'");
		test_diag("  at " . __FILE__ . " line " . (__LINE__+8) . ".");
		test_out( "not ok 4 - executable mode has all bits of 0111" );
		test_diag("file [executable] mode is missing component 0011");
		test_diag("  Failed test 'executable mode has all bits of 0111'");
		test_diag("  at " . __FILE__ . " line " . (__LINE__+5) . ".");
		}
	file_mode_has( 'executable', 0100 );
	file_mode_has( 'executable', 0100, 'executable mode really has all bits of 0100');
	file_mode_has( 'executable', 0200 );
	file_mode_has( 'executable', 0111 );
	test_test();
	done_testing();
	};

subtest mode_isnt => sub {
	if (Test::File::_win32) {
		test_out( "ok 1 # skip file_mode_isnt doesn't work on Windows" );
		test_out( "ok 2 # skip file_mode_isnt doesn't work on Windows" );
		test_out( "ok 3 # skip file_mode_isnt doesn't work on Windows" );
		}
	else {
		test_out( "ok 1 - executable mode is not 0200" );
		test_out( "ok 2 - executable mode really is not 0200" );
		test_out( "not ok 3 - executable mode is not 0100" );
		test_diag("file [executable] mode is 0100");
		test_diag("  Failed test 'executable mode is not 0100'");
		test_diag("  at " . __FILE__ . " line " . (__LINE__+4) . ".");
		}
	file_mode_isnt( 'executable', 0200 );
	file_mode_isnt( 'executable', 0200, 'executable mode really is not 0200' );
	file_mode_isnt( 'executable', 0100 );
	test_test();
	done_testing();
	};

subtest mode_hasnt => sub {
	if (Test::File::_win32()) {
		test_out( "ok 1 # skip file_mode_hasnt doesn't work on Windows" );
		test_out( "ok 2 # skip file_mode_hasnt doesn't work on Windows" );
		test_out( "ok 3 # skip file_mode_hasnt doesn't work on Windows" );
		}
	else {
		test_out( "ok 1 - executable mode has no bits of 0200" );
		test_out( "ok 2 - executable mode really has no bits of 0200" );
		test_out( "not ok 3 - executable mode has no bits of 0111" );
		test_diag("file [executable] mode has forbidden component 0100");
		test_diag("  Failed test 'executable mode has no bits of 0111'");
		test_diag("  at " . __FILE__ . " line " . (__LINE__+5) . ".");
		}

	file_mode_hasnt( 'executable', 0200 );
	file_mode_hasnt( 'executable', 0200, 'executable mode really has no bits of 0200' );
	file_mode_hasnt( 'executable', 0111 );
	test_test();
	done_testing();
	};

subtest mode => sub	{
	my $s = Test::File::_win32()
		? "# skip file_mode_is doesn't work on Windows"
		: "- readable mode is 0400";
	test_out( "ok 1 $s" );
	file_mode_is( 'readable', 0400 );
	test_test();
	done_testing();
	};

subtest mode_isnt => sub {
	my $s = Test::File::_win32()
		? "# skip file_mode_isnt doesn't work on Windows"
		: "- readable mode is not 0200";
	test_out( "ok 1 $s" );
	file_mode_isnt( 'readable', 0200 );
	test_test();
	done_testing();
	};

subtest mode_writable => sub {
	my $s = Test::File::_win32()
		? "# skip file_mode_is doesn't work on Windows"
		: "- writable mode is 0200";
	test_out( "ok 1 $s" );
	file_mode_is( 'writable', 0200 );
	test_test();
	done_testing();
	};

subtest mode => sub	{
	my $s = Test::File::_win32()
		? "# skip file_mode_isnt doesn't work on Windows"
		: "- writable mode is not 0100";
	test_out( "ok 1 $s" );
	file_mode_isnt( 'writable', 0100 );
	test_test();
	done_testing();
	};

done_testing();
