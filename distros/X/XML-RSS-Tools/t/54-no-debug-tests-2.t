#   $Id: 54-no-debug-tests-2.t 67 2008-06-29 14:17:37Z adam $

use Test::More;
use strict;
use warnings;

my $test_warn;
BEGIN {
    eval ' require Test::NoWarnings; ';
    if ( $@ ) {
        plan( skip_all => 'Test::NoWarnings not installled.' );
        undef $test_warn;
    }
    else {
        plan( tests => 24 );
        $test_warn = 1;
    }
    use URI::file;
    if ( $URI::VERSION >= 1.32 ) {
        no warnings;
        $URI::file::DEFAULT_AUTHORITY = undef;
    }
    use_ok( 'XML::RSS::Tools' );
}

my $rss_object = XML::RSS::Tools->new;

ok( !$rss_object->debug,                          'Debugging is off' );
ok( !( $rss_object->rss_file( 'foo.bar' ) ),  'Load a duff RSS file' );
ok( !( $rss_object->xsl_file( 'foo.bar' ) ),  'Load a duff XSL file' );
ok( !( $rss_object->rss_file() ),           'Load an empty RSS file' );
ok( !( $rss_object->xsl_file() ),           'Load an empty XSL file' );
ok( !$rss_object->as_string( 'rss' ),
               'If we ask for an empty stringify do we get an error?' );
ok( !$rss_object->as_string( 'xsl' ),
               'If we ask for an empty stringify do we get an error?' );
ok( !$rss_object->as_string(),
               'If we ask for an empty stringify do we get an error?' );
ok( !( $rss_object->rss_uri ),      'If we requrest a blank RSS URI' );
ok( !( $rss_object->xsl_uri ),      'If we requrest a blank XSL URI' );
ok( !( $rss_object->rss_uri( "wibble wobble" ) ),
                                       'If we Request a duff RSS URI' );
ok( !( $rss_object->xsl_uri( "wibble wobble" ) ),
                                       'If we Request a duff XSL URI' );
ok( !( $rss_object->rss_file( './' ) ),
                        'Try and load a RSS file that is a directory' );
ok( !( $rss_object->xsl_file( './' ) ),
                        'Try and load a XSL file that is a directory' );
ok( !( $rss_object->rss_uri( 'mailto:foo@bar' ) ),
                              'If we requrest an unsupported RSS URI' );
ok( !( $rss_object->xsl_uri( 'mailto:foo@bar' ) ),
                              'If we requrest an unsupported XSL URI' );
ok( !( $rss_object->rss_file( './t/empty-file' ) ),
                                        'Check for an empty RSS File' );
ok( !( $rss_object->xsl_file( './t/empty-file' ) ),
                                        'Check for an empty XSL File' );
ok( !( $rss_object->rss_uri( 'file:./t/empty-file' ) ),
                                 'Check for an empty RSS File by URI' );
ok( !( $rss_object->xsl_uri( 'file:./t/empty-file' ) ),
                                 'Check for an empty XSL File by URI' );
ok( !( $rss_object->set_http_client( "Internet Explorer" ) ),
                    'Does setting a duff HTTP client cause an error?' );
ok( !( $rss_object->set_http_client() ),
                    'Does setting a null HTTP client cause an error?' );
if ( $test_warn ) { Test::NoWarnings::had_no_warnings(); }
exit;
