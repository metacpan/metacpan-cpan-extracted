use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN { use_ok( 'WKHTMLTOX::XS' ); }
require_ok( 'WKHTMLTOX::XS' );

can_ok('WKHTMLTOX::XS', qw(generate_image));

dies_ok { WKHTMLTOX::XS::generate_image(@{[]}); } 'Expecting die';
dies_ok { WKHTMLTOX::XS::generate_image([]); } 'Expecting die';

#lives_ok { generate_image({out => 't/test_a.jpg', in => "http://www.google.com", fmt => "jpeg"}) } 'Expecting to live';
lives_ok { generate_image({out => 't/test_b.jpg', in => "t/test.html", fmt => "jpeg"}) } 'Expecting to live';

done_testing();