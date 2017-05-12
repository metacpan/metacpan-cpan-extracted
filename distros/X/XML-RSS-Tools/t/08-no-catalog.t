#   $Id: 08-no-catalog.t 80 2008-07-06 11:43:16Z adam $

use strict;
use Test::More;
use XML::RSS::Tools;

my $test_warn;

BEGIN {
    eval ' use XML::LibXML; ';
    undef $test_warn;
    if ( $@ ) {
        plan( skip_all => 'XML::LibXML not installled.' );
    }
    else {
        if ( $XML::LibXML::VERSION < 1.53 ) {
            eval ' require Test::NoWarnings; ';
            if ( $@ ) {
                plan( tests => 1 );
            }
            else {
                plan( tests => 2 );
                $test_warn = 1;
            }
        }
        else {
            plan( skip_all => 'Your XML::LibXML is up to date.' );
        }
    }
}

my $rss_object = XML::RSS::Tools->new;
eval { $rss_object->set_xml_catalog( './t/catalog.xml' ); };
like( $@,
    qr/XML Catalog Support not enabled in your version of XML::LibXML/,
                                       'Correct Catalog error message' );

if ( $test_warn ) {
    Test::NoWarnings::had_no_warnings();
}

exit;

