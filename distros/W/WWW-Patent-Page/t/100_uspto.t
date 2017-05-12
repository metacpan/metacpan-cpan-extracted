# -*- perl -*-

# t/100uspto.t - test documented interface

use Test::More tests => 33;
BEGIN { use_ok('WWW::Patent::Page'); }

my $patent_document = WWW::Patent::Page->new();    # new object
isa_ok( $patent_document, 'WWW::Patent::Page' );

my $document1 = $patent_document->get_page(
	'4,299,215',                                   #4,299,215
	'office'  => 'USPTO',
	'country' => 'US',
	'format'  => 'htm',
	'page'    => '1',                              # typically htm IS "1" page
);
like( $document1->content, qr/Anon/, ' 3 utility patent by Ramon L. Anon' );

is( $document1->get_parameter('number'), 4299215, ' 4 the patent document number' );
is( $document1->get_parameter('doc_id'), '4,299,215',
	' 5 the patent document identifier supplied' );

my $document_id = $document1->get_parameter('doc_id');

# US6,654,321(B2)issued_2_Okada
is( $document_id, '4,299,215', ' 6 doc_id = 4,299,215' );

my $office_used = $document1->get_parameter('office');
is( $office_used, 'USPTO', ' 7 Office is USPTO' );

my $country_used = $document1->get_parameter('country');
is( $country_used, 'US', ' 8 country US' );

my $format_used = $document1->get_parameter('format');
is( $format_used, 'htm', ' 9 format is htm/html' );

like($patent_document->terms , qr/general public/ , '10 terms of service reflected') ;

$terms_and_conditions = $patent_document->terms;             # and conditions

#print "hello! \n\n\n\n", $terms_and_conditions;
like( $terms_and_conditions, qr/www.USPTO.gov/,
	'11 terms at http://www.USPTO.gov' );

my $document = $patent_document->get_page();                 # the loot
like( $document->content, qr/Anon/, '12 utility patent by Ramon L. Anon' );

my $document2 = $patent_document->get_page(
	'US_6_123_456',
	'office' => 'USPTO',
	'format' => 'tif',
	'page'   => 2,
);

$pages_known = $document2->get_parameter('pages');

is( $pages_known, 8, '13 US 6,123,456, 8 pages long' );

$document2 = $patent_document->get_page(
	'US_6_123_456',
	'office' => 'USPTO',
	'format' => 'htm'
);

is($document2->get_parameter('doc_id_standardized') , 'US6123456' , 'document id should be US6123456' );

like( $document2->content, qr/Catalytic hydrogenation to remove gas/, 'US_6_123_456' );

$document1 = $patent_document->get_page('USD339,456');
is($document1->get_parameter('doc_id') , 'USD339,456' , 'document id should be USD339,456' );
is($document1->get_parameter('number') , '339456' , 'number should be 339456' );
is($document1->get_parameter('doc_type') , 'D' , 'type should be D' );
like(  #19
	$document1->content,
	qr/ornamental design for a shoe sole/,
	'D339,456: retrieve the sole of Kayano of Asics'
);
$document2 = $patent_document->get_page('USPP08,901');
is($document2->get_parameter('doc_id') , 'USPP08,901' , 'document id should be USPP08,901' );
like(
	$document2->content,
	qr/Parentage: Unknown; selected from among several/,
	'PP08,901: Enkianthus perulatus'
);
$document1 = $patent_document->get_page('USRE35,312');
is($document1->get_parameter('doc_id') , 'USRE35,312' , 'document id should be USRE35,312' );
like( $document1->content , qr/endospongestick probe/, 'RE35,312' );
$document1 = $patent_document->get_page('USH001,523');
is($document1->get_parameter('doc_id') , 'USH001,523' , 'document id should be USH001,523' );
like( $document1->content ,
	qr/olymer film having a conductivity gradient across its thickness/,
	'H001,523' );
$document1 = $patent_document->get_page('UST109,201');
is($document1->get_parameter('doc_id') , 'UST109,201' , 'document id should be UST109201' );
like($document1->content , qr/optical alignment tool and method is described for setting a datum line/,
	'T109,201');
$document1 = $patent_document->get_page('2001_0000044');
is($document1->get_parameter('doc_id') , '2001_0000044' , 'document id should be 2001_0000044' );
like(
	$document1->content,
	qr/Methods For Transacting Business/,
	'retrieve 20010000044 by Wayne W. Lin'
);
$document1 = $patent_document->get_page('USD339,456');
is($document1->get_parameter('doc_id') , 'USD339,456' , 'document id should be USD339,456' );
like(
	$document1->content,
	qr/ornamental design for a shoe sole/,
	'D339,456: retrieve the sole of Kayano of Asics'
);

$document1 = $patent_document->get_page(
	'doc_id' => '',
	'country'=> 'US',
	'number' => '9999999',
	'office' => 'USPTO',
	'format' => 'htm',
	'page'   => 1,
);

ok( !$document1->is_success, 'correctly failed due to patent not found');
like( $document1->message, qr/No patents/ , 'correct failure message about patent not found.'." Message: '".$document1->message. "'" );

#print $document1->content;

# TO DO
# Utility --   	5,146,634 6923014 0000001
# Design -- 	D339,456 D321987 D000152
# Plant -- 	PP08,901 PP07514 PP00003
# Reissue -- 	RE35,312 RE12345 RE00007
# Defensive Publication -- 	T109,201 T855019 T100001
# Statutory Invention Registration -- 	H001,523 H001234 H000001
# Re-examination -- 	RX29,194 RE29183 RE00125
# Additional Improvement -- 	AI00,002 AI000318 AI00007

#US
#All patent numbers must be seven characters in length, excluding commas, which
#are optional. Examples:

#PP07514 not PP7514
#RE35,312 reissue
#H001,523 SIR
#T109,201



