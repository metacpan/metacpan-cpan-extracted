#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::Render::Entry::backends::pod' ) || print "Bail out!
";
}

diag( "Testing Toader::Render::Entry::backends::pod $Toader::Render::Entry::backends::pod::VERSION, Perl $], $^X" );
