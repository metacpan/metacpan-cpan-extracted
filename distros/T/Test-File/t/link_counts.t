use strict;

use Test::Builder::Tester;
use Test::More 0.95;
use_ok( 'Test::File' );

require "./t/setup_common";

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Subroutines are defined
subtest defined_subs => sub {
	my @subs = qw( link_count_is_ok link_count_gt_ok link_count_lt_ok );

	foreach my $sub ( @subs ) {
		no strict 'refs';
		ok( defined &{$sub}, "$sub is defined" );
		}
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Stuff that should work (single link)
my $test_name     = "This is my test name";
my $readable      = 'readable';
my $readable_sym  = 'readable_sym';
my $not_there     = 'not_there';
my $dangle_sym    = 'dangle_sym';

subtest should_work => sub {
	test_out( "ok 1 - $test_name" );
        test_out( "ok 2 - readable has a link count of [100]" );
        test_out( "ok 3 - $test_name" );
        test_out( "ok 4 - readable has a link count of [0]" );
        test_out( "ok 5 - $test_name" );
	link_count_lt_ok( $readable, 100, $test_name );
	link_count_lt_ok( $readable, 100 );
	link_count_gt_ok( $readable,   0, $test_name );
	link_count_gt_ok( $readable,   0 );
	link_count_is_ok( $readable,   1, $test_name );
	test_test();

	test_out( "ok 1 - $readable has a link count of [1]" );
	link_count_is_ok( $readable, 1 );
	test_test();
	done_testing();
	};


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Stuff that should work (multipe links)


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Stuff that should fail (missing file)


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

subtest bad_count => sub {
	test_out( "not ok 1 - $test_name" );
	test_diag(
		"File [$readable] points has [1] links: expected [100]!\n" .
		"    #   Failed test '$test_name'\n" .
		"    #   at $0 line " . line_num(+5) . "."
		);
	link_count_is_ok( $readable, 100, $test_name );
	test_test();

	test_out( "not ok 1 - $test_name" );
	test_diag(
		"File [$readable] points has [1] links: expected less than [0]!\n" .
		"    #   Failed test '$test_name'\n" .
		"    #   at $0 line " . line_num(+5) . "."
		);
	link_count_lt_ok( $readable, 0, $test_name );
	test_test();

	test_out( "not ok 1 - $test_name" );
	test_diag(
		"File [readable] points has [1] links: expected more than [100]!\n" .
		"    #   Failed test '$test_name'\n" .
		"    #   at $0 line " . line_num(+5) . "."
		);
	link_count_gt_ok( $readable, 100, $test_name );
	test_test();
	done_testing();
	};

done_testing();
