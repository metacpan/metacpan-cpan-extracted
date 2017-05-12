# -*- perl -*-

# t/015_uspto_pdf.t 

use Test::More tests => 21;    

BEGIN { use_ok('WWW::Patent::Page'); } #1

my $patent_document = WWW::Patent::Page->new();    # new object

isa_ok( $patent_document, 'WWW::Patent::Page' );

my $document2 = $patent_document->get_page(
	'US6123456',
	'office' => 'USPTO',
	'format' => 'pdf',
	'page'   => 1,
);


like( $document2->content , qr/58135/,   # get_parameter is a private method, may go away later
	'US 6,123,456 page 1, CCITTFaxDecode 58,135 bytes ' );


$document2 = $patent_document->get_page(
	'US6123456',
	'office' => 'USPTO',
	'format' => 'pdf',
	'page'   => 2
);

like( $document2->content, qr/23679/,
	'US 6,123,456 page 2, CCITTFaxDecode 23,679 bytes ' );

my $office_used = $document2->get_parameter('office');    # ep

is( $office_used, 'USPTO', 'Office is USPTO' );

my $country_used = $document2->get_parameter('country');    #US
is( $country_used, 'US', 'country US' );

my $number = $document2->get_parameter('number');           # 6654321
is( $number, 6123456, 'patent number is 6123456' );

my $doc_id_used = $document2->get_parameter('doc_id');          # 2
is( $doc_id_used, 'US6123456', 'doc_id is US6123456' );

my $page_used = $document2->get_parameter('page');          # 2
is( $page_used, 2, 'page retrieved is 2' );

my $format_used = $document2->get_parameter('format');      #tif
is( $format_used, 'pdf', 'format is correct' );

my $pages_total = $document2->get_parameter('pages');       # 101
is( $pages_total, 8, 'pages (total) is correct' );

$document2 = $patent_document->get_page(page  => 3);

$office_used = $document2->get_parameter('office');    # ep

is( $office_used, 'USPTO', 'Office is USPTO' );

$country_used = $document2->get_parameter('country');    #US
is( $country_used, 'US', 'country US' );

$number = $document2->get_parameter('number');           # 6654321
is( $number, 6123456, 'patent number is 6123456' );

$page_used = $document2->get_parameter('page');          # 2
is( $page_used, 3, 'page retrieved is 3' );

$doc_id_used = $document2->get_parameter('doc_id');          # 2
is( $doc_id_used, 'US6123456', 'doc_id is US6123456' );

$format_used = $document2->get_parameter('format');      #tif
is( $format_used, 'pdf', 'format is correct' );

$pages_total = $document2->get_parameter('pages');       # 101
is( $pages_total, 8, 'pages (total) is correct' );


# 28272
like( $document2->content, qr/28272/,
	'US 6,123,456 page 3, CCITTFaxDecode 28,272 bytes ' );
	
my $document3 = $patent_document->get_page(page  => undef);

cmp_ok( length($document3->content), '>=', 620000,'US 6,123,456 all pages, is 631086 or 84 or 83 or so... bytes.' );
cmp_ok( length($document3->content), '<=', 633000,'US 6,123,456 all pages, is 631086 or 84 or 83 or so... bytes.' );
	
