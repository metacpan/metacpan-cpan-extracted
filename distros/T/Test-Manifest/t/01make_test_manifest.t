use Test::More 0.98;

use File::Spec;
use File::Copy qw(copy);

use Test::Manifest qw(make_test_manifest manifest_name);
use lib './t';
use Test::Manifest::Tempdir qw(prepare_tmp_dir);

my $tmp_dir = prepare_tmp_dir();
chdir $tmp_dir or die "Cannot chdir to $tmp_dir: $!";

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
