#   $Id: 51-debug-tests-1.t 101 2014-05-27 14:25:39Z adam $

use Test::More;
use strict;
use XML::RSS::Tools;

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
        plan( tests => 61 );
        use URI::file;
        if ( $URI::VERSION >= 1.32 ) {
            no warnings;
            $URI::file::DEFAULT_AUTHORITY = undef;
        }
    }
}

my $capture    = IO::Capture::Stderr->new();
my $rss_object = XML::RSS::Tools->new;

ok( $rss_object->debug( 1 ),                   ' 01:  Debug is true' );

$capture->start();
ok( !( $rss_object->rss_file( 'foo.bar' ) ),
                                         ' 02:  Load a duff RSS file' );
$capture->stop();
my $line = $capture->read;
like( $line,
      qr/File error: Cannot find foo.bar/,
                                  ' 03:  Did we get the right error?' );
ok( $line =~ $rss_object->as_string( 'error' ),
                                  ' 04:  Did we get the right error?' );

$capture->start();
ok( !( $rss_object->xsl_file( 'foo.bar' ) ),
                                         ' 05:  Load a duff XSL file' );
$capture->stop();
$line = $capture->read;

like( $line,
      qr/File error: Cannot find foo.bar/,
                                  ' 06:  Did we get the right error?' );

ok( $line =~ $rss_object->as_string( 'error' ),
                                  ' 07:  Did we get the right error?' );

$capture->start();
ok( !( $rss_object->rss_file() ),     ' 08:  Load an empty RSS file' );
$capture->stop();
$line = $capture->read;

like( $line,
      qr/File error: No file name supplied/,
                                  ' 09:  Did we get the right error?' );

ok( $line =~ $rss_object->as_string( 'error' ),
                                   '10:  Did we get the right error?' );

$capture->start();
ok( !( $rss_object->xsl_file() ),      '11:  Load an empty XSL file' );
$capture->stop();
$line = $capture->read;

like( $line,
      qr/File error: No file name supplied/,
                                   '12:  Did we get the right error?' );

ok( $line =~ $rss_object->as_string( 'error' ),
                                    '13:  Did we get the right error?' );

$capture->start();
ok( !$rss_object->as_string( 'rss' ),
          '14:  If we ask for an empty stringify do we get an error?' );
$capture->stop();
$line = $capture->read;
like( $line, qr/No RSS File to output/,             '15:  No output' );

$capture->start();
ok( !$rss_object->as_string( 'xsl' ),
          '16:  If we ask for an empty stringify do we get an error?' );
$capture->stop();
$line = $capture->read;
like( $line, qr/No XSL Template to output/,         '17:  No output' );

$capture->start();
ok( !$rss_object->as_string(),
          '18:  If we ask for an empty stringify do we get an error?' );
$capture->stop();
$line = $capture->read;
like( $line, qr/Nothing To Output Yet/,         '19:  No output yet' );

$capture->start();
ok( !( $rss_object->rss_uri ), '20:  If we requrest a blank RSS URI' );
$capture->stop();
$line = $capture->read;
like( $line, qr/No URI provided./,               '21:  no URI error' );

ok( $line =~ $rss_object->as_string( 'error' ),
                                   '22:  Did we get the right error?' );

$capture->start();
ok( !( $rss_object->xsl_uri ), '23:  If we requrest a blank XSL URI' );
$capture->stop();
$line = $capture->read;
like( $line, qr/No URI provided./,                '24:  No URI error' );

ok( $line =~ $rss_object->as_string( 'error' ),
                                   '25:  Did we get the right error?' );

$capture->start();
ok( !( $rss_object->rss_uri( "wibble wobble" ) ),
                                  '26:  If we Request a duff RSS URI' );
$capture->stop();
$line = $capture->read;
like( $line, qr/No URI Scheme in wibble%20wobble./,
                                           '27:  No URI Scheme error' );

ok( $line =~ $rss_object->as_string( 'error' ),
                                   '28:  Did we get the right error?' );

$capture->start();
ok( !( $rss_object->xsl_uri( "wibble wobble" ) ),
                                  '29:  If we Request a duff XSL URI' );
$capture->stop();
$line = $capture->read;
like( $line, qr/No URI Scheme in wibble%20wobble./,
                                           '30:  No URI scheme error' );

ok( $line =~ $rss_object->as_string( 'error' ),
                                   '31:  Did we get the right error?' );

$capture->start();
ok( !( $rss_object->rss_file( './' ) ),
                      '32:  Try and load a RSS file that is a folder' );
$capture->stop();
$line = $capture->read;
like( $line, qr/File error: \.\/ isn\'t a real file/,
                                             '33:  Invalid file type' );

ok( $line =~ $rss_object->as_string( 'error' ),
                                   '34:  Did we get the right error?' );

$capture->start();
ok( !( $rss_object->xsl_file( './' ) ),
                   '35:  Try and load a XSL file that is a directory' );
$capture->stop();
$line = $capture->read;
ok( $line =~ "File error: ./ isn't a real file",
                                         '36:  Not a valid file type' );

ok( $line =~ $rss_object->as_string( 'error' ),
                                   '37:  Did we get the right error?' );

$capture->start();
ok( !( $rss_object->rss_uri( 'mailto:foo@bar' ) ),
                         '38:  If we requrest an unsupported RSS URI' );
$capture->stop();
$line = $capture->read;
ok( $line =~ 'Unsupported URI Scheme \(mailto\)\.',
                                         '39:  Unspoorted URI scheme' );

like( $rss_object->as_string( 'error' ),
      qr/Unsupported URI Scheme \(mailto\)/,
                                   '40:  Did we get the right error?' );

$capture->start();
ok( !( $rss_object->xsl_uri( 'mailto:foo@bar' ) ),
                         '41:  If we requrest an unsupported XSL URI' );
$capture->stop();
$line = $capture->read;
like( $line,
      qr/Unsupported URI Scheme \(mailto\)\./,
                                   '42:  Did we get the right error?' );
like( $rss_object->as_string( 'error' ),
      qr/Unsupported URI Scheme \(mailto\)\./,
                                   '43:  Did we get the right error?' );

$capture->start();
ok( !( $rss_object->rss_file( './t/empty-file' ) ),
                                   '44:  Check for an empty RSS File' );
$capture->stop();
$line = $capture->read;
like( $line, qr/File error: \.\/t\/empty-file is zero bytes long/,
                                              '45:  Empty file error' );

ok( $line =~ $rss_object->as_string( 'error' ),
                                   '46:  Did we get the right error?' );

$capture->start();
ok( !( $rss_object->xsl_file( './t/empty-file' ) ),
                                   '47:  Check for an empty XSL File' );
$capture->stop();
$line = $capture->read;
like( $line, qr/File error: \.\/t\/empty-file is zero bytes long/,
                                              '48:  Empty file error' );
ok( $line =~ $rss_object->as_string( 'error' ),
                                   '49:  Did we get the right error?' );

$capture->start();
ok( !( $rss_object->rss_uri( 'file:./t/empty-file' ) ),
                            '50:  Check for an empty RSS File by URI' );
$capture->stop();
$line = $capture->read;
$line =~ s#\\#/#g;
like( $line, qr/File error: \..t.empty-file is zero bytes long/,
                                              '51:  Empty file error' );

my $error = $rss_object->as_string( 'error' );
$error =~ s#\\#/#g;
like( $line, qr/$error/,           '52:  Did we get the right error?' );

$capture->start();
ok( !( $rss_object->xsl_uri( 'file:./t/empty-file' ) ),
                            '53:  Check for an empty XSL File by URI' );
$capture->stop();
$line = $capture->read;
$line =~ s#\\#/#g;
like( $line, qr/File error: \..t.empty-file is zero bytes long/,
                                              '54:  Empty File error' );

$error = $rss_object->as_string( 'error' );
$error =~ s#\\#/#g;
like( $line, qr/$error/,          '55:  Did we get the right error?' );

$capture->start();
ok( !( $rss_object->set_http_client( "Internet Explorer" ) ),
               '56:  Does setting a duff HTTP client cause an error?' );
$capture->stop();
$line = $capture->read;
like( $line, qr/Not configured for HTTP Client Internet Explorer/,
                                      '57:  Malconfigure http client' );

ok( $line =~ $rss_object->as_string( 'error' ),
                                   '58:  Did we get the right error?' );

$capture->start();
ok( !( $rss_object->set_http_client() ),
               '59:  Does setting a null HTTP client cause an error?' );
$capture->stop();
$line = $capture->read;
like( $line, qr/No HTTP Client requested/, '60:  no http client set' );

ok( $line =~ $rss_object->as_string( 'error' ),
                                   '61:  Did we get the right error?' );

exit;
