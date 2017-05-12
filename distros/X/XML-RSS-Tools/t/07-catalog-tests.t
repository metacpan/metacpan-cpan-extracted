#   $Id: 07-catalog-tests.t 67 2008-06-29 14:17:37Z adam $

use strict;
use Test::More;

my $test_warn;

BEGIN {
    eval ' use XML::LibXML; ';
    undef $test_warn;
    if ( $@ ) {
        plan( skip_all => 'XML::LibXML not installled.' );
    }
    else {
        if ( $XML::LibXML::VERSION >= 1.53 ) {
            eval ' require Test::NoWarnings; ';
            if ( $@ ) {
                plan( tests => 12 );
            }
            else {
                plan( tests => 13 );
                $test_warn = 1;
            }
        }
        else {
            plan( skip_all => 'Your XML::LibXML is too old.' );
        }
    }
    use_ok( 'XML::RSS::Tools' );
}

my $rss_object = XML::RSS::Tools->new;

eval {
    $rss_object = XML::RSS::Tools->new( xml_catalog => './t/catalog.xml' );
};
ok( !( $@ ),                                    'Read a catalog okay' );

$rss_object->set_version( 0 );
$rss_object->set_auto_wash( 0 );

ok( !$rss_object->set_xml_catalog( 'duff' ),     'Did not like duff' );
is( $rss_object->as_string( "error" ),
    'File error: Cannot find duff',
                                                 'Correct File error' );

eval { $rss_object->set_xml_catalog( './t/catalog.xml' ); };
ok( !( $@ ),                                       'Set catalog okay' );

is( $rss_object->get_xml_catalog,
    './t/catalog.xml',
                                               'Correct catalog file' );

ok( !$rss_object->set_xml_catalog( './t/no-catalog.xml' ),
                                'Refuses to set non-existent catalog' );

eval { $rss_object->rss_file( './t/test-0.91.rdf' ); };
ok( !( $@ ),                                   'Parses rss file okay' );

eval { $rss_object->xsl_file( './t/test.xsl' ); };
ok( !( $@ ),                                   'parses xsl file okay' );

eval { $rss_object->transform; };
ok( !( $@ ),                                    'transformation okay' );

my $output_html = $rss_object->as_string;
ok( $output_html,                     'we got a file of some length' );
my $length = length $output_html;
ok( ( $length >= 850 ) || ( $length <= 1500 ),
                                 'Transformed length was within range' );

if ( $test_warn ) {
    Test::NoWarnings::had_no_warnings();
}

exit;

