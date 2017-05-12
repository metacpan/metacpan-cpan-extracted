# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 31;

BEGIN { use_ok( 'strict' ); }
BEGIN { use_ok( 'WebService::AngelXML::Auth' ); }
BEGIN { use_ok( 'CGI' ); }

my $cgi;
my $ws;
$cgi=CGI->new('store_id=7861&associate_id=5546&next_page=100');
isa_ok ($cgi, 'CGI');
is($cgi->param(-name=>"store_id"), "7861", '$cgi->param(-name=>"store_id")');
is($cgi->param(-name=>"associate_id"), "5546", '$cgi->param(-name=>"associate_id")');
is($cgi->param(-name=>"next_page"), "100", '$cgi->param(-name=>"next_page")');

$ws = WebService::AngelXML::Auth->new(cgi=>$cgi);
$ws->param_id('store_id');
$ws->param_pin('associate_id');
$ws->param_page('next_page');
isa_ok ($ws, 'WebService::AngelXML::Auth');

is($ws->cgi->param(-name=>"store_id"), "7861", '$ws->cgi->param(-name=>"store_id")');
is($ws->cgi->param(-name=>"associate_id"), "5546", '$ws->cgi->param(-name=>"associate_id")');
is($ws->cgi->param(-name=>"next_page"), "100", '$ws->cgi->param(-name=>"next_page")');

is($ws->id, "7861", '$ws->id');
is($ws->pin, "5546", '$ws->pin');
is($ws->page, "100", '$ws->page');
is($ws->prompt, ".", '$ws->prompt'); #default

is($ws->id(123), "123", '$ws->id');
is($ws->pin(234), "234", '$ws->pin');
is($ws->page(345), "345", '$ws->page');
is($ws->prompt("junk"), "junk", '$ws->prompt');

is($ws->id, "123", '$ws->id');
is($ws->pin, "234", '$ws->pin');
is($ws->page, "345", '$ws->page');
is($ws->prompt, "junk", '$ws->prompt');

#bad data from POST
$cgi=CGI->new('store_id=7861&store_id=7862&associate_id=5546&associate_id=5547&next_page=100&next_page=101');
isa_ok ($cgi, 'CGI');
is($cgi->param(-name=>"store_id"), "7861", '$cgi->param(-name=>"store_id")');
is($cgi->param(-name=>"associate_id"), "5546", '$cgi->param(-name=>"associate_id")');
is($cgi->param(-name=>"next_page"), "100", '$cgi->param(-name=>"next_page")');

$ws = WebService::AngelXML::Auth->new(cgi=>$cgi, param_id=>"store_id", param_pin=>"associate_id", param_page=>"next_page");
isa_ok ($ws, 'WebService::AngelXML::Auth');
is($ws->id, "7861", '$ws->id');
is($ws->pin, "5546", '$ws->pin');
is($ws->page, "100", '$ws->page');
