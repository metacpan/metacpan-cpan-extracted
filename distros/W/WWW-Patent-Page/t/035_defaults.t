# -*- perl -*-

# t/100uspto.t - test documented interface

use Test::More tests => 4;
BEGIN { use_ok('WWW::Patent::Page'); }

my $patent_document = WWW::Patent::Page->new();    # new object
isa_ok( $patent_document, 'WWW::Patent::Page' );

$document2 = $patent_document->get_page(
	'EP1234567',
	'office' => 'ESPACE_EP',
	'country' => 'EP',
	'format' => 'pdf',
	'page'   => 1,
);

is( $document2->get_parameter('country'), 'EP', 'the country is EP when set' );

my $document1 = $patent_document->get_page(
	'4,299,215',                                   #4,299,215
	'office'  => 'USPTO',
	'format'  => 'htm',
	'page'    => '1',                              # typically htm IS "1" page
);
is( $document1->get_parameter('country'), 'US', 'the default country is US using method get_page, not new...' )