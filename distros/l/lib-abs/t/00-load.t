#!/usr/bin/env perl -w

use strict;
use Test::More;
BEGIN { my $tests = 6; eval q{ use Test::NoWarnings;1 } and $tests++; plan tests => $tests };
use FindBin;
use Cwd;
use lib "$FindBin::Bin/../lib"; # there is no lib::abs yet ;)

BEGIN {
	use_ok( 'lib::abs','.' );
	{
		local $@;
		eval q{ use lib::abs; };
		ok(!$@, 'lib::abs empty usage allowed');
	}
	{
		local $@;
		eval q{ use lib::abs '../linux/macosx/windows/dos/path-that-never-exists'; }; # ;)
		ok($@, 'lib::abs wrong path failed');
	}
	{
		local $@;
		eval q{ use lib::abs './linux-macosx-windows-dos-path-that-never-exists'; }; # ;)
		ok($@, 'lib::abs wrong 1st level path failed');
	}
	{
		local $@;
		eval q{ use lib::abs -soft => '../linux/macosx/windows/dos/path-that-never-exists'; }; # ;)
		ok(!$@, 'lib::abs wrong path not failed with soft');
	}
	{
		local $@;
		eval q{ use lib::abs -soft => './linux-macosx-windows-dos-path-that-never-exists'; }; # ;)
		ok(!$@, 'lib::abs wrong 1st level path not failed with soft');
	}
}

diag( "Testing lib::abs $lib::abs::VERSION using Cwd $Cwd::VERSION, Perl $], $^X" );
