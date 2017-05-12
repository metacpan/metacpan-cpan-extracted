#   $Id: 53-no-debug-tests-1.t 74 2008-06-30 20:25:25Z adam $

use Test::More;
use strict;
use warnings;

BEGIN {
    eval 'use IO::Capture::Stderr';

    if ( $@ ) {
        plan( skip_all => 'IO::Capture::Stderr not installled.' );
    }
    elsif ( $] < 5.008 ) {
        plan( skip_all =>
                'IO::Capture::Stderr does work reliably on your Perl version.'
        );
    }
    else {
        plan tests => 44;
        use URI::file;
        if ( $URI::VERSION >= 1.32 ) {
            no warnings;
            $URI::file::DEFAULT_AUTHORITY = undef;
        }
    }
}

use XML::RSS::Tools;
ok( 1 );    # If we made it this far, we're ok.

my $capture    = IO::Capture::Stderr->new();
my $rss_object = XML::RSS::Tools->new;

#   2
ok( !$rss_object->debug );

#   3   Load a duff RSS file
$capture->start();
ok( !( $rss_object->rss_file( 'foo.bar' ) ) );
$capture->stop();
ok( !$capture->read );

#   5   Load a duff XSL file
$capture->start();
ok( !( $rss_object->xsl_file( 'foo.bar' ) ) );
$capture->stop();
ok( !$capture->read );

#   7   Load an empty RSS file
$capture->start();
ok( !( $rss_object->rss_file() ) );
$capture->stop();
ok( !$capture->read );

#   9   Load an empty XSL file
$capture->start();
ok( !( $rss_object->xsl_file() ) );
$capture->stop();
ok( !$capture->read );

#   11  If we ask for an empty stringify do we get an error?
$capture->start();
ok( !$rss_object->as_string( 'rss' ) );
$capture->stop();
ok( !$capture->read );

#   13  If we ask for an empty stringify do we get an error?
$capture->start();
ok( !$rss_object->as_string( 'xsl' ) );
$capture->stop();
ok( !$capture->read );

#   15  If we ask for an empty stringify do we get an error?
$capture->start();
ok( !$rss_object->as_string() );
$capture->stop();
ok( !$capture->read );

#   17  If we requrest a blank RSS URI
$capture->start();
ok( !( $rss_object->rss_uri ) );
$capture->stop();
ok( !$capture->read );

#   19  If we requrest a blank XSL URI
$capture->start();
ok( !( $rss_object->xsl_uri ) );
$capture->stop();
ok( !$capture->read );

#   21  If we Request a duff RSS URI
$capture->start();
ok( !( $rss_object->rss_uri( "wibble wobble" ) ) );
$capture->stop();
ok( !$capture->read );

#   23  If we Request a duff XSL URI
$capture->start();
ok( !( $rss_object->xsl_uri( "wibble wobble" ) ) );
$capture->stop();
ok( !$capture->read );

#   25 Try and load a RSS file that's a folder
$capture->start();
ok( !( $rss_object->rss_file( './' ) ) );
$capture->stop();
ok( !$capture->read );

#   27 Try and load a XSL file that's a folder
$capture->start();
ok( !( $rss_object->xsl_file( './' ) ) );
$capture->stop();
ok( !$capture->read );

#   29  If we requrest an unsupported RSS URI
$capture->start();
ok( !( $rss_object->rss_uri( 'mailto:foo@bar' ) ) );
$capture->stop();
ok( !$capture->read );

#   31  If we requrest an unsupported XSL URI
$capture->start();
ok( !( $rss_object->xsl_uri( 'mailto:foo@bar' ) ) );
$capture->stop();
ok( !$capture->read );

#   33  Check for an empty RSS File
$capture->start();
ok( !( $rss_object->rss_file( './t/empty-file' ) ) );
$capture->stop();
ok( !$capture->read );

#   35  Check for an empty XSL File
$capture->start();
ok( !( $rss_object->xsl_file( './t/empty-file' ) ) );
$capture->stop();
ok( !$capture->read );

#   37  Check for an empty RSS File by URI
$capture->start();
ok( !( $rss_object->rss_uri( 'file:./t/empty-file' ) ) );
$capture->stop();
ok( !$capture->read );

#   39  Check for an empty XSL File by URI
$capture->start();
ok( !( $rss_object->xsl_uri( 'file:./t/empty-file' ) ) );
$capture->stop();
ok( !$capture->read );

#   41  Does setting a duff HTTP client cause an error?
$capture->start();
ok( !( $rss_object->set_http_client( "Internet Explorer" ) ) );
$capture->stop();
ok( !$capture->read );

#   43  Does setting a null HTTP client cause an error?
$capture->start();
ok( !( $rss_object->set_http_client() ) );
$capture->stop();
ok( !$capture->read );

exit;
