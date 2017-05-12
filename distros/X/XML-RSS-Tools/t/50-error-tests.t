#   $Id: 50-error-tests.t 67 2008-06-29 14:17:37Z adam $

use Test::More;
use strict;
use warnings;

my $test_warn;

BEGIN {
    eval ' require Test::NoWarnings; ';
    if ( $@ ) {
        plan( tests => 46 );
        undef $test_warn;
    }
    else {
        plan( tests => 47 );
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

ok( !$rss_object->as_string( 'error' ),              'No errors yet' );

#   3   Try and transform with nothing
eval { $rss_object->transform; };
like( $@, qr/No XSLT loaded/,              'No XSLT Loaded yet error' );

#   4   Load a good XSLT file and re-transform
eval { $rss_object->xsl_file( './t/test.xsl' ); };
ok( !( $@ ),                           'No error from valid xsl file' );

eval { $rss_object->transform; };
like( $@, qr/No RSS loaded/,                    'No RSS loaded error' );

#   6   Load a duff RSS file
ok( !( $rss_object->rss_file( 'foo.bar' ) ),   'Duff RSS file error' );

#   7   Did we get the right error?
is( $rss_object->as_string( 'error' ),
    'File error: Cannot find foo.bar',
                                                 'File error correct?');

#   8   Load a duff XSL file
ok( !( $rss_object->xsl_file( 'foo.bar' ) ),   'Duff xsl file error' );

#   9   Did we get the right error?
is( $rss_object->as_string( 'error' ),
    'File error: Cannot find foo.bar',
                                             'XSL File error correct?' );

#   10  Load an empty RSS file
ok( !( $rss_object->rss_file() ),              'Empty file correct?' );

#   11  Did we get the right error?
is( $rss_object->as_string( 'error' ),
    'File error: No file name supplied',
                                       'No file name supplied error?' );

#   12  Load an empty XSL file
ok( !( $rss_object->xsl_file() ),              'Empty file correct?' );

#   13  Did we get the right error?
is( $rss_object->as_string( 'error' ),
    'File error: No file name supplied',
                                        'No file name supplied error?' );

#   14  If we ask for a silly stringify do we get an error?
eval { $rss_object->as_string( 'fake call' ) };
like( $@, qr/Unknown mode: fake call/,              'Fake Call error' );

#   15  If we requrest a blank RSS URI
ok( !( $rss_object->rss_uri ),                      'Blank rss uri?' );

#   16  Did we get the right error?
is( $rss_object->as_string( 'error' ),
    'No URI provided.',
                                                  'No rss URI error?' );

#   17  If we requrest a blank XSL URI
ok( !( $rss_object->xsl_uri ),                      'Blank xsl uri?' );

#   18  Did we get the right error?
is( $rss_object->as_string( 'error' ),
    'No URI provided.',
                                                  'No xsl URI error?' );

#   19  If we Request a duff RSS URI
ok( !( $rss_object->rss_uri( "wibble wobble" ) ),     'Duff rss URI' );

#   20  Did we get the right error?
is( $rss_object->as_string( 'error' ),
    'No URI Scheme in wibble%20wobble.',
                                            'Absurd URI scheme error' );

#   21  If we Request a duff XSL URI
ok( !( $rss_object->xsl_uri( "wibble wobble" ) ),     'Duff xsl URI' );

#   22  Did we get the right error?
is( $rss_object->as_string( 'error' ),
    'No URI Scheme in wibble%20wobble.',
                                         'Absurd xsl URI scheme error' );

#   23 Try and load a RSS file that's a directory
ok( !( $rss_object->rss_file( './' ) ),          'Directory not file');

#   24  Did we get the right error?
is( $rss_object->as_string( 'error' ),
    q{File error: ./ isn't a real file},
                                            'Directory as file error' );

#   25 Try and load a XSL file that's a directory
ok( !( $rss_object->xsl_file( './' ) ),         'Directory not file' );

#   26  Did we get the right error?
is( $rss_object->as_string( 'error' ),
    q{File error: ./ isn't a real file},
                                            'Directory as file error' );

#   27  If we requrest an unsupported RSS URI
ok( !( $rss_object->rss_uri( 'mailto:foo@bar' ) ),
                                             'Unsupported URI scheme' );

#   28  Did we get the right error?
is( $rss_object->as_string( 'error' ),
    'Unsupported URI Scheme (mailto).',
                                'Correct usupported URI Scheme error' );

#   29  If we requrest an unsupported XSL URI
ok( !( $rss_object->xsl_uri( 'mailto:foo@bar' ) ),
                                             'Unsupported URI scheme' );

#   30  Did we get the right error?
is( $rss_object->as_string( 'error' ),
    'Unsupported URI Scheme (mailto).',
                               'Correct unsupported URI Scheme error' );

#   31  Check for an empty RSS File
ok( !( $rss_object->rss_file( './t/empty-file' ) ),     'Empty file' );

#   32  Did we get the right error?
my $error = $rss_object->as_string( 'error' );
$error =~ s#\\#/#g;
is( $error, 'File error: ./t/empty-file is zero bytes long',
                                                   'Empty File error' );

#   33  Check for an empty XSL File
ok( !( $rss_object->xsl_file( './t/empty-file' ) ),     'Empty File' );

#   34  Did we get the right error?
$error = $rss_object->as_string( 'error' );
is( $error, 'File error: ./t/empty-file is zero bytes long',
                                                   'Empty File error' );

#   35  Check for an empty RSS File by URI
ok( !( $rss_object->rss_uri( 'file:./t/empty-file' ) ), 'Empty file' );

#   36  Did we get the right error?
$error = $rss_object->as_string( 'error' );
$error =~ s#\\#/#g;
is( $error, 'File error: ./t/empty-file is zero bytes long',
                                                   'Empty file error' );

#   37  Check for an empty XSL File by URI
ok( !( $rss_object->xsl_uri( 'file:./t/empty-file' ) ), 'Empty file' );

#   38  Did we get the right error?
$error = $rss_object->as_string( 'error' );
$error =~ s#\\#/#g;
is( $error, 'File error: ./t/empty-file is zero bytes long',
                                                   'Empty file error' );

#   39  Does setting a duff HTTP client cause an error?
ok( !( $rss_object->set_http_client( "Internet Explorer" ) ),
                                                  'Silly http client' );

#   40  Did we get the right error?
is( $rss_object->as_string( 'error' ),
    'Not configured for HTTP Client Internet Explorer',
                                          'Correct http client error' );

#   41  Does setting a null HTTP client cause an error?
ok( !( $rss_object->set_http_client() ),   'No client defined error' );

#   42  Did we get the right error?
is( $rss_object->as_string( 'error' ), 'No HTTP Client requested',
                                       'No http client defined error' );

#   43  Test a duff constructor, bad HTTP client
eval {
    $rss_object = XML::RSS::Tools->new(
        http_client => "Internet Explorer" );
};

like( $@, qr/Not configured for HTTP Client Internet Explorer/,
                                                  'http client error' );

#   44  Test a duff constructor,
eval {
    $rss_object = XML::RSS::Tools->new(
    version => 51 );
};
like( $@, qr/No such version of RSS 51/,   'Absurd rss version error' );

eval {
    $rss_object = XML::RSS::Tools->new(
        xml_catalog => './foo-bar.xml' );
};
if ( $XML::LibXML::VERSION < 1.53 ) {
    like( $@,
          qr/XML Catalog Support not enabled in your version of XML::LibXML/,
                                            'No catalog error message' );
}
else {
    like( $@, qr/Unable to read XML catalog/, 'Defective catalg error');
}

#   46 Test bad XML/RSS strings
eval {
    $rss_object->rss_string( "<rss</rss>" );
};
like( $@,
      qr/not well-formed \(invalid token\) at line 1, column 4, byte 4/,
                                                'Malformed XML error' );

if ( $test_warn ) {
    Test::NoWarnings::had_no_warnings();
}

exit;
