use Test::More tests => 2;

use Test::Manifest qw(make_test_manifest);

my $test_manifest = File::Spec->catfile( qw(t test_manifest) );

if($^O eq 'VMS') 	# http://perldoc.perl.org/perlvms.html#unlink-LIST
	{
	1 while ( unlink $test_manifest );
	}
else
	{
	unlink $test_manifest;
	}

ok( ! -e $test_manifest, 'test_manifest does not exit' );

make_test_manifest();

ok( -e $test_manifest, 'test_manifest exists' );
