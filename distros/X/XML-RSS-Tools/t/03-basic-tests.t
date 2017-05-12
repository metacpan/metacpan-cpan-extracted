#   $Id: 03-basic-tests.t 101 2014-05-27 14:25:39Z adam $

use Test::More;
use strict;
use warnings;
use XML::RSS::Tools;

my $test_warn;
BEGIN {
    eval ' require Test::NoWarnings; ';
    if ( $@ ) {
        plan( tests => 9 );
        undef $test_warn;
    }
    else {
        plan( tests => 10 );
        $test_warn = 1;
    }
    use_ok( 'XML::RSS::Tools' );
}

is( $XML::RSS::Tools::VERSION, '0.34',             'Version Check' );

my $rss_object = XML::RSS::Tools->new;

ok( defined $rss_object,                        'Object is defined' );
isa_ok( $rss_object, 'XML::RSS::Tools',          'Oject/Class Check' );
ok( !($rss_object->debug) );
is( $rss_object->get_version, 0.91,              'RSS Version Check' );
is( $rss_object->get_auto_wash, 1,          'Auto Wash Flag Correct' );


$rss_object = XML::RSS::Tools->new( debug => 1 );
is( $rss_object->debug, 1,              'Debug Flag is Correct (on)' );

$rss_object = XML::RSS::Tools->new( auto_wash => 1 );
ok( $rss_object->get_auto_wash );

if ( $test_warn ) {
    Test::NoWarnings::had_no_warnings();
}

exit;
