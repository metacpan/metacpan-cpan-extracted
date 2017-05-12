#   $Id: 04-standard-tests.t 67 2008-06-29 14:17:37Z adam $

use Test::More;
use strict;
use warnings;

my $test_warn;
BEGIN {
    eval ' require Test::NoWarnings; ';
    if ( $@ ) {
        plan( tests => 26 );
        undef $test_warn;
    }
    else {
        plan( tests => 27 );
        $test_warn = 1;
    }
    use_ok( 'XML::RSS::Tools' );
}

my $rss_object = XML::RSS::Tools->new;

ok( defined $rss_object,                      'Object defined okay' );
isa_ok( $rss_object, 'XML::RSS::Tools',          'Object check okay' );

eval { $rss_object->transform; };

like( $@, qr/No XSLT loaded/,                     'No XSLT loaded yet');
ok( !($rss_object->rss_file( 'foo.bar' )),         'Set a sillyfile' );
is( $rss_object->as_string( 'error' ),
      'File error: Cannot find foo.bar',
                                                 'Correct file error' );
ok( !( $rss_object->rss_uri ),                    'No URI oject yet' );
ok( !( $rss_object->rss_uri( "wibble wobble" ) ),   'Impossible uri' );

ok( $rss_object = XML::RSS::Tools->new( version => 0.91 ),
                                             'Created new ojcte okay' );
eval { $rss_object->rss_string( '<rss version="0.91"></rss>' ); };
ok( !( $@ ),                              'Valid XML string is valid' );

eval { $rss_object->rss_file( './t/test.rdf' ); };
ok( !( $@ ),                                'Valid XML file was okay' );

eval { $rss_object->rss_uri( 'file:./t/test.rdf' ); };
ok( !( $@ ),                    'valid XML file via URI handler okay' );

eval { $rss_object->xsl_string( "<xsl></xsl>" ); };
ok( !( $@ ),                                  'Valid XSL string okay' );

eval { $rss_object->xsl_file( './t/test.xsl' ); };
ok( !( $@ ),                                    'Valid XSL file okay' );

eval { $rss_object->xsl_uri( 'file:./t/test.xsl' ); };
ok( !( $@ ),                    'Valid XSL file via URI handler okay' );

eval { $rss_object->transform; };
ok( !( $@ ),                                    'Transformation okay' );

eval { $rss_object->transform; };
like( $@, qr/Can't transform twice without a change/,
                              'Transformation duplication error okay' );

my $output = $rss_object->as_string;
my $length = length $output;
ok( $length,                              'We got a length of sorts' );
ok( ( $length == 1333 ) || ( $length == 1487 ),   'Length was okay' );

$rss_object->set_version( 0 );
eval { $rss_object->rss_file( './t/test.rdf' ); };
$output = $rss_object->as_string( 'rss' );
$length = length $output;
ok( $length,                              'We got a length of sorts' );
ok( ( $length == 3787 ) || ( $length == 3857 ),   'Length was okay' );

$output = $rss_object->as_string( 'xsl' );
$length = length $output;
ok( $length,                              'We got a length of sorts' );
is( $length, 1007,                                  'Length correct' );

is( $rss_object->set_auto_wash( 1 ), 1,           'Autowash is okay' );
is( $rss_object->set_auto_wash(),    1,      'Setting autowash okay' );
is( $rss_object->set_auto_wash( 0 ), 0,  'Setting autowash off okay' );

if ( $test_warn ) {
    Test::NoWarnings::had_no_warnings();
}

exit;
