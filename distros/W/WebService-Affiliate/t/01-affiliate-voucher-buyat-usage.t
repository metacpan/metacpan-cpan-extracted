use strict;
use warnings;

use Test::More;
use Test::Exception;

use WebService::Affiliate::Voucher::BuyAt;

my $voucher;

lives_ok { $voucher = WebService::Affiliate::Voucher::BuyAt->new } "instantiated empty voucher ok";

ok( $voucher->code eq '', "empty code" );
ok( $voucher->_starts eq '', "empty _starts" );
ok( ! defined $voucher->starts, "undefined starts" );
ok( $voucher->_expires eq '', "empty _expires" );
ok( ! defined $voucher->expires, "undefined expires" );
ok( $voucher->description eq '', "empty description" );
ok( $voucher->_url eq '', "empty _url" );
ok( ! defined $voucher->url, "undefined url" );


lives_ok { $voucher = WebService::Affiliate::Voucher::BuyAt->new(  code => 'ABC123',
                                                           _starts => '2008-05-07 13:24:55',
                                                            description => 'save 20p',
                                                           _url => 'http://www.mowdirect.co.uk/sale',
                                                         ) } "instantiated half full voucher ok";

ok( $voucher->code eq 'ABC123', "code is ABC123" );
ok( $voucher->_starts eq '2008-05-07 13:24:55', "_start date is correct" );
ok( $voucher->starts->year == 2008, "start year is 2008" );
ok( $voucher->starts->month == 5, "start month is 5" );
ok( $voucher->starts->day == 7, "start day is 7" );
ok( $voucher->starts->hour == 13, "start hour is 13" );
ok( $voucher->starts->minute == 24, "start minute is 24" );
ok( $voucher->starts->second == 55, "start second is 55" );

ok( $voucher->_expires eq '', "empty _expires" );
ok( ! defined $voucher->expires, "undefined expires" );

ok( $voucher->description eq 'save 20p', "description ok" );

ok( $voucher->_url eq 'http://www.mowdirect.co.uk/sale', "_url is ok" );

ok( $voucher->url->scheme eq 'http', "url scheme is ok" );
ok( $voucher->url->host eq 'www.mowdirect.co.uk', "url host is ok" );
ok( $voucher->url->path eq '/sale', "url path is ok" );







done_testing();
