#! perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Errno qw/ENOENT ENOTDIR/;

use FindBin;
use File::Spec::Functions 'catfile';
use File::Temp;
use lib "$FindBin::Bin/lib";
use TestUtils;

subtest enotdir => sub {
	use autocroak allow => { -e => ENOENT };

	my ($tfh, $tpath) = File::Temp::tempfile( CLEANUP => 1 );

	my $path = catfile($tpath, 'notthere');
	my $err = exception { -e $path };

	SKIP: {
		skip 'Windows is special', 1 if $^O eq 'MSWin32';
		like($err, error_for("-e '\Q$path\E'", ENOTDIR));
	}
};

subtest no_error => sub {
	use autocroak allow => { -e => ENOENT };

	my $tdir = File::Temp::tempdir( CLEANUP => 1 );

	is(exception { ok( (-e $tdir), 'exists == success' ) }, undef);

	is(exception { ok( !(-e "$tdir/notthere"), 'nonexistence isn’t an error' ) }, undef);
};

done_testing;
