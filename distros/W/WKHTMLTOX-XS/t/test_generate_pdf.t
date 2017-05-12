use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN { use_ok( 'WKHTMLTOX::XS' ); }
require_ok( 'WKHTMLTOX::XS' );

can_ok('WKHTMLTOX::XS', qw(generate_pdf));

dies_ok { WKHTMLTOX::XS::generate_pdf({},[]); } 'Expecting die';
dies_ok { WKHTMLTOX::XS::generate_pdf([],{}); } 'Expecting die';
dies_ok { WKHTMLTOX::XS::generate_pdf([],[]); } 'Expecting die';
dies_ok { WKHTMLTOX::XS::generate_pdf('',{}); } 'Expecting die';
dies_ok { WKHTMLTOX::XS::generate_pdf({},''); } 'Expecting die';
dies_ok { WKHTMLTOX::XS::generate_pdf(@{[]},{}); } 'Expecting die';
dies_ok { WKHTMLTOX::XS::generate_pdf({},@{[]}); } 'Expecting die';

#lives_ok { generate_pdf({out => 't/test_a.pdf'},{page => "http://www.google.com"}) } 'Expecting to live';
lives_ok { generate_pdf({out => 't/test_b.pdf'},{page => "t/test.html"}) } 'Expecting to live';

done_testing();