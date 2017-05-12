#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'Test::Run::Plugin::ColorSummary' );
    use_ok( 'Test::Run::CmdLine::Plugin::ColorSummary' );
}
