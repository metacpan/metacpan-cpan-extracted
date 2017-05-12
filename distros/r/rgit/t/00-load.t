#!perl -T

use strict;
use warnings;

use Test::More tests => 13;

BEGIN {
	use_ok( 'App::Rgit' );
	use_ok( 'App::Rgit::Command' );
	use_ok( 'App::Rgit::Command::Each' );
	use_ok( 'App::Rgit::Command::Once' );
	use_ok( 'App::Rgit::Config' );
	use_ok( 'App::Rgit::Config::Default' );
	use_ok( 'App::Rgit::Guard' );
	use_ok( 'App::Rgit::Policy' );
	use_ok( 'App::Rgit::Policy::Default' );
	use_ok( 'App::Rgit::Policy::Interactive' );
	use_ok( 'App::Rgit::Policy::Keep' );
	use_ok( 'App::Rgit::Repository' );
	use_ok( 'App::Rgit::Utils' );
}

diag( "Testing App::Rgit $App::Rgit::VERSION, Perl $], $^X" );
