#   $Id: 06-filehandle-tests.t 67 2008-06-29 14:17:37Z adam $

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

my $dummy_fh = FileHandle->new( 'foo.bar' );
ok( !( $rss_object->rss_fh( $dummy_fh ) ),          'Dummy FH okay' );
is( $rss_object->as_string( 'error' ),
    'FileHandle error: No FileHandle Object Passed',
                                             'Check FH error messgae' );
ok( !( $rss_object->xsl_fh( $dummy_fh ) ),          'Dummy FH okay' );
is( $rss_object->as_string( 'error' ),
    'FileHandle error: No FileHandle Object Passed',
                                             'Check FH error message' );

my $rss_fh = FileHandle->new( './t/test.rdf' );
my $xsl_fh = FileHandle->new( './t/test.xsl' );

ok( $rss_object->rss_fh( $rss_fh ),         'Real file via FH okay' );
ok( $rss_object->xsl_fh( $xsl_fh ),         'Real file via FH okay' );

eval { $rss_object->transform; };
ok( !( $@ ),                            'Transform ran without error' );

my $output_html = $rss_object->as_string;
my $length      = length $output_html;
ok( $length,                   'We got a transfored length of sorts' );
ok( ( $length == 1333 ) || ( $length == 1487 ),
                                            'File was the right size' );

if ( $test_warn ) {
    Test::NoWarnings::had_no_warnings();
}

exit;
