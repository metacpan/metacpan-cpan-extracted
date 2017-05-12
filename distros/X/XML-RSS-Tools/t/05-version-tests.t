#   $Id: 05-version-tests.t 66 2008-06-29 13:07:56Z adam $

use Test::More;
use strict;
use warnings;

my $test_warn;
BEGIN {
    eval ' require Test::NoWarnings; ';
    if ( $@ ) {
        plan( tests => 10 );
        undef $test_warn;
    }
    else {
        plan( tests => 11 );
        $test_warn = 1;
    }

    use_ok( 'XML::RSS::Tools' );
}

my $rss_object = XML::RSS::Tools->new;

#   By default the initial version is 0.91
is( $rss_object->get_version, 0.91,       'Default RSS version okay' );

#   There is no version 5 so it should fail
ok( !( $rss_object->set_version( 567 ) ),       'Silly version okay' );

#   As the last set fail it should still be 0.91
is( $rss_object->get_version, 0.91,    'Default version still okay?' );

#   There is an RSS version of 2.0
ok( $rss_object->set_version( 2.0 ), 'Change to a valid version okay' );

#   As the last set should work it should be 2.0
is( $rss_object->get_version, 2.0,             'Change was accepted' );

#   Trying to set nothing should do nothing, but not raise an error
ok( !( $rss_object->set_version() ),   'Did not set a blank version' );

#   As the last set did nothing it should still be 2.0
is( $rss_object->get_version, 2.0,              'Version still 2.0?' );

#   Turn off normalisation by setting to 0
ok( $rss_object->set_version( 0 ),     'Turned off versioning okay?' );

#   As the last set it to 0 it should be 0
my $version = $rss_object->get_version;
ok( (defined( $version ) && not $version),      'Version is now 0?' );

if ($test_warn) {
    Test::NoWarnings::had_no_warnings();
}


exit;
