#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Text::Password::Pronounceable::RandomCase' );
}

diag( "Testing App::Luser $Text::Password::Pronounceable::RandomCase::VERSION, Perl $], $^X" );
