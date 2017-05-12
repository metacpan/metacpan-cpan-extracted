#   $Id: 52-debug-tests-2.t 101 2014-05-27 14:25:39Z adam $

use Test::More;
use strict;

my $test_warn;
BEGIN {
    eval ' use Test::Warn; ';

    if ( $@ ) {
        plan( skip_all => 'Test::Warn not installled.' );
    }
    else {
        eval ' require Test::NoWarnings; ';
        if ( $@ ) {
            plan( tests => 60 );
            undef $test_warn;
        }
        else {
            plan( tests => 61 );
            $test_warn = 1;
        }
        use URI::file;
        if ( $URI::VERSION >= 1.32 ) {
            no warnings;
            $URI::file::DEFAULT_AUTHORITY = undef;
        }
        use_ok( 'XML::RSS::Tools' );
    }
}

my $rss_object = XML::RSS::Tools->new;

ok( $rss_object->debug( 1 ),                   ' 02:  Debug is true' );

warning_like {
    ok( !( $rss_object->rss_file( 'foo.bar' ) ),
                                         ' 03:  Load a duff RSS file' );
}
qr/File error: Cannot find foo.bar/, ' 04:  Did we get the right error?';

like( $rss_object->as_string( 'error' ),
      qr/File error: Cannot find foo.bar/,
                                  ' 05:  Did we get the right error?' );

warning_like {
    ok( !( $rss_object->xsl_file( 'foo.bar' ) ),
                                         ' 06:  Load a duff XSL file' );
}
qr/File error: Cannot find foo.bar/, ' 07:  Did we get the right error?';

like( $rss_object->as_string( 'error' ),
      qr/File error: Cannot find foo.bar/,
                                  ' 08:  Did we get the right error?' );

warning_like {
    ok( !( $rss_object->rss_file() ), ' 09:  Load an empty RSS file' );
}
qr/File error: No file name supplied/, '10:  Did we get the right error?';

like( $rss_object->as_string( 'error' ),
      qr/File error: No file name supplied/,
                                   '11:  Did we get the right error?' );

warning_like {
    ok( !( $rss_object->xsl_file() ),  '12:  Load an empty XSL file' );
}
qr/File error: No file name supplied/, '13:  Did we get the right error?';

like( $rss_object->as_string( 'error' ),
      qr/File error: No file name supplied/,
                                   '14:  Did we get the right error?' );

warning_like {
    ok( !$rss_object->as_string( 'rss' ),
          '15:  If we ask for an empty stringify do we get an error?' );
}
qr/No RSS File to output/,            '16:  Correct No RSS File error?';

warning_like {
    ok( !$rss_object->as_string( 'xsl' ),
          '17:  If we ask for an empty stringify do we get an error?' );
}
qr/No XSL Template to output/,            '18:  No XSL Template error?';

warning_like {
    ok( !$rss_object->as_string(),
          '19:  If we ask for an empty stringify do we get an error?' );
}
qr/Nothing To Output Yet/,              '20:  Nothing to Output error?';

warning_like {
    ok( !( $rss_object->rss_uri ),
                                '21:  If we requrest a blank RSS URI' );
}
qr/No URI provided/,                           '22:  No RSS URI error?';

like( $rss_object->as_string( 'error' ),
      qr/No URI provided/,
                                   '23:  Did we get the right error?' );

warning_like {
    ok( !( $rss_object->xsl_uri ),
                                '24:  If we requrest a blank XSL URI' );
}
qr/No URI provided/,                           '25:  No XSL URI error?';

like( $rss_object->as_string( 'error' ),
      qr/No URI provided/,
                                   '26:  Did we get the right error?' );

warning_like {
    ok( !( $rss_object->rss_uri( "wibble wobble" ) ),
                                  '27:  If we Request a duff RSS URI' );
}
qr/No URI Scheme in wibble%20wobble/,  '28:  Invalid URI Scheme error?';

like( $rss_object->as_string( 'error' ),
      qr/No URI Scheme in wibble%20wobble/,
                                   '29:  Did we get the right error?' );

warning_like {
    ok( !( $rss_object->xsl_uri( "wibble wobble" ) ),
                                  '30:  If we Request a duff XSL URI' );
}
qr/No URI Scheme in wibble%20wobble/,  '31:  Invalid URI Scheme error?';

like( $rss_object->as_string( 'error' ),
      qr/No URI Scheme in wibble%20wobble/,
                                   '32:  Did we get the right error?' );

warning_like {
    ok( !( $rss_object->rss_file( './' ) ),
                   '33:  Try and load a RSS file that is a directory' );
}
qr/File error: \.\/ isn\'t a real file/,
                                 '34:  A directory is not a file error';

like( $rss_object->as_string( 'error' ),
      qr/File error: \.\/ isn\'t a real file/,
                                   '35:  Did we get the right error?' );

warning_is {
    ok( !( $rss_object->xsl_file( './' ) ),
                   '36:  Try and load a XSL file that is a directory' );
}
"File error: ./ isn't a real file",       '37:  Load a directory error';

is( $rss_object->as_string( 'error' ),
    "File error: ./ isn't a real file",
                                   '38:  Did we get the right error?' );

warning_like {
    ok( !( $rss_object->rss_uri( 'mailto:foo@bar' ) ),
                         '39:  If we requrest an unsupported RSS URI' );
}
qr/Unsupported URI Scheme \(mailto\)\./,
                                   '40:  Unsupported URI scheme error?';

like( $rss_object->as_string( 'error' ),
      qr/Unsupported URI Scheme \(mailto\)/,
                                   '41:  Did we get the right error?' );

warning_like {
    ok( !( $rss_object->xsl_uri( 'mailto:foo@bar' ) ),
                         '42:  If we requrest an unsupported XSL URI' );
}
qr/Unsupported URI Scheme \(mailto\)\./,
                                     '43:  Did we get the right error?';

like( $rss_object->as_string( 'error' ),
      qr/Unsupported URI Scheme \(mailto\)\./,
                                   '44:  Did we get the right error?' );

warning_like {
    ok( !( $rss_object->rss_file( './t/empty-file' ) ),
                                   '45:  Check for an empty RSS File' );
}
qr/File error: \.\/t\/empty-file is zero bytes long/,
                                           '46:  Empty File RSS Error?';

like( $rss_object->as_string( 'error' ),
      qr/File error: \.\/t\/empty-file is zero bytes long/,
                                   '47:  Did we get the right error?' );

warning_like {
    ok( !( $rss_object->xsl_file( './t/empty-file' ) ),
                                   '48:  Check for an empty XSL File' );
}
qr/File error: \.\/t\/empty-file is zero bytes long/,
                                           '49:  Empty XSL File Error?';

like( $rss_object->as_string( 'error' ),
      qr/File error: \.\/t\/empty-file is zero bytes long/,
                                   '50:  Did we get the right error?' );

warning_like {
    ok( !( $rss_object->rss_uri( 'file:./t/empty-file' ) ),
                            '51:  Check for an empty RSS File by URI' );
}
qr/File error: \..t.empty-file is zero bytes long/,
                                   '52:  Empty RSS File via URI error?';

warning_like {
    ok( !( $rss_object->xsl_uri( 'file:./t/empty-file' ) ),
                            '53:  Check for an empty XSL File by URI' );
}
qr/File error: \..t.empty-file is zero bytes long/,
                                   '54:  Empty XSL File via URI error?';

warning_like {
    ok( !( $rss_object->set_http_client( "Internet Explorer" ) ),
               '55:  Does setting a duff HTTP client cause an error?' );
}
qr/Not configured for HTTP Client Internet Explorer/,
                                      '56:  Invalid HTTP client error?';

like( $rss_object->as_string( 'error' ),
      qr/Not configured for HTTP Client Internet Explorer/,
                                   '57:  Did we get the right error?' );

warning_like {
    ok( !( $rss_object->set_http_client() ),
               '58:  Does setting a null HTTP client cause an error?' );
}
qr/No HTTP Client requested/,    '59:  No HTTP Client requested error?';

like( $rss_object->as_string( 'error' ),
      qr/No HTTP Client requested/,
                                   '60:  Did we get the right error?' );

if ( $test_warn ) {
    Test::NoWarnings::had_no_warnings();
}

exit;
