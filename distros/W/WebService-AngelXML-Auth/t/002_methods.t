# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 13;

BEGIN { use_ok( 'WebService::AngelXML::Auth' ); }

my $ws = WebService::AngelXML::Auth->new();
isa_ok ($ws, 'WebService::AngelXML::Auth');

is($ws->allow, "0", 'default $ws->allow 0');
is($ws->deny, "-1", 'default $ws->deny -1');

$ws->allow(1); #actually sends "0"
is($ws->allow, "-1", '$ws->allow 0');
is($ws->deny, "0", '$ws->deny -1');

$ws->allow(0); #actually sends "-1"
is($ws->allow, "0", '$ws->allow 0');
is($ws->deny, "-1", '$ws->deny -1');

$ws->deny(1); #actually sends "-1"
is($ws->allow, "0", '$ws->allow 0');
is($ws->deny, "-1", '$ws->deny -1');

$ws->deny(0); #actually sends "0"
is($ws->allow, "-1", '$ws->allow 0');
is($ws->deny, "0", '$ws->deny -1');

isa_ok ($ws->cgi, 'CGI');
