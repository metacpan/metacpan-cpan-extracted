#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Video::Flvstreamer' ) || print "Bail out!
";
}

diag( "Testing Video::Flvstreamer $Video::Flvstreamer::VERSION, Perl $], $^X" );
