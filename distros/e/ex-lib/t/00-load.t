#!/usr/bin/perl -w

use strict;
use Test::More tests => 6;
use FindBin;
use Cwd;
use lib "$FindBin::Bin/../lib";

BEGIN {
	use_ok( 'ex::lib','.' );
	use_ok( 'lib::abs','.' );
    {
        local $@;
        eval q{ use ex::lib; };
        ok(!$@, 'ex::lib empty usage allowed');
    }
    {
        local $@;
        eval q{ use ex::lib '../linux/macosx/windows/dos/path-that-never-exists'; }; # ;)
        ok($@, 'ex::lib wrong path failed');
    }
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
}

diag( "Testing ex::lib/lib::abs $ex::lib::VERSION using Cwd $Cwd::VERSION, Perl $], $^X" );
