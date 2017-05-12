
use Test::More;

eval "use Template";

if ( $@ )
{
    diag "";
    diag "********************************************************************************";
    diag "***                                                                          ***";
    diag "*** Template Toolkit not installed: no documentation pages will be available ***";
    diag "***                                                                          ***";
    diag "********************************************************************************";
    plan skip_all => "Install Template Toolkit in order to run this test.";
    exit;
}

plan tests => 19;

$ENV{DANCER_APPDIR} = '.';
$ENV{WDS_QUIET} = 1;

my ($result, $header, $chunk1, $chunk2);

eval {
    $result = `cd files; $^X bin/dataservice.pl GET /data1.0/`;
};

ok( !$@, 'invocation: main html' ) or diag( "    message was: $@" );

unless ( $result )
{
    BAIL_OUT("the data service failed to run.");
}

$header = substr($result, 0, 250);
$chunk1 = substr($result, 1000, 1000);
$chunk2 = substr($result, 3000, 1000);

like( $header, qr{^HTTP/1.0 200 OK}m, 'http header' );

like( $header, qr{^Content-Type: text/html; charset=utf-8}mi, 'content type html' );

like( $header, qr{^<html><head><title>Example Data Service: Main Documentation</title>}mi, 'main title' );

like( $chunk1, qr{^<h2 class="pod_heading"><a name="OPERATIONS">OPERATIONS</a></h2>}mi, 'main h2' );

like( $chunk1, qr{<a +class="pod_link" +href="/data1.0/single_doc.html">Single +state</a>}mi, 'html node link' );

like( $chunk1, qr{<a +class="pod_link" +href="/data1.0/single.json\?state=wi">/data1.0/single.json\?state=wi</a>}mi, 'html op link' );

like( $chunk2, qr{^<td class="pod_def"><p class="pod_para">The JSON format is intended primarily to support client applications.</p>}mi, 
      'main json format' );

eval {
    $result = `cd files; $^X bin/dataservice.pl GET /data1.0/index.pod`;
};

ok( !$@, 'invocation: main pod' ) or diag( "    message was: $@" );

$header = substr($result, 0, 250);

like( $header, qr{^Content-Type: text/plain; charset=utf-8}m, 'content type pod' );

like( $header, qr{^=head1 Example Data Service: Main Documentation}m, 'pod title' );

like( $result, qr{^=for wds_table_header Format\* \| Suffix \| Documentation \| Description}m, 'pod table descriptor' );

like( $result, qr{^=item L<Single state\|node:single>}m, 'pod node link' );

eval {
    $result = `cd files; $^X bin/dataservice.pl GET /data1.0/single_doc.pod`;
};

ok( !$@, 'invocation: single_doc pod' ) or diag( "    message was: $@" );

like( $result, qr{^=for wds_table_header Field name* | Block | Description}m, 'single_doc response table header' );

like( $result, qr{^=item name \( basic \)}m, 'single_doc basic item' );

like( $result, qr{^The name of the state}m, 'single_doc basic item body' );

like( $result, qr{^=item pop1900 \( hist \)}m, 'single_doc optional item' );

like( $result, qr{^L<Plain text formats\|node:formats/text>}m, 'single_doc format' );
