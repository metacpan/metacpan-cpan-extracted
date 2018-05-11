use Test::More 0.98;

use Test::Manifest qw(make_test_manifest manifest_name);

my $test_manifest = manifest_name();
diag( "manifest name is $test_manifest" );

subtest remove_manifest => sub {
	if($^O eq 'VMS') {	# http://perldoc.perl.org/perlvms.html#unlink-LIST
		state $n = 0;
		$n++ while ( $n < 10 && unlink $test_manifest );
		}
	else {
		unlink $test_manifest;
		}

	ok( ! -e $test_manifest, "$test_manifest does not exist" );
	};

subtest make_manifest => sub {
	my $count = make_test_manifest();
	diag( "count of test files is $count" );
	ok( -e $test_manifest, "$test_manifest exists" );
	};

done_testing();
