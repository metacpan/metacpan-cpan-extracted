# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 37;

BEGIN { use_ok( 'WebService::AngelXML::Auth' ); }

my $ws={};
$ws = WebService::AngelXML::Auth->new();
isa_ok ($ws, 'WebService::AngelXML::Auth');
is($ws->allow, "0", '$ws->allow');
is($ws->deny, "-1", '$ws->deny');
is($ws->mimetype, "application/vnd.angle-xml.xml+xml", '$ws->mimetype');
isa_ok ($ws->cgi, 'CGI');
is($ws->page, "/1000", '$ws->page default');

$ws = WebService::AngelXML::Auth->new(allow=>1);
isa_ok ($ws, 'WebService::AngelXML::Auth');
is(exists($ws->{'allow'}), '', 'not exists $ws->{allow}');
is(exists($ws->{'deny'}), 1, 'exists $ws->{deny}');
is($ws->allow, "-1", '$ws->allow');
is($ws->deny, "0", '$ws->deny');

$ws = WebService::AngelXML::Auth->new(allow=>0);
isa_ok ($ws, 'WebService::AngelXML::Auth');
is(exists($ws->{'allow'}), '', 'not exists $ws->{allow}');
is(exists($ws->{'deny'}), 1, 'exists $ws->{deny}');
is($ws->allow, "0", '$ws->allow');
is($ws->deny, "-1", '$ws->deny');

$ws = WebService::AngelXML::Auth->new(deny=>1);
isa_ok ($ws, 'WebService::AngelXML::Auth');
is($ws->allow, "0", '$ws->allow');
is($ws->deny, "-1", '$ws->deny');

$ws = WebService::AngelXML::Auth->new(deny=>0);
isa_ok ($ws, 'WebService::AngelXML::Auth');
is($ws->allow, "-1", '$ws->allow');
is($ws->deny, "0", '$ws->deny');

$ws = WebService::AngelXML::Auth->new(prompt=>"junk");
isa_ok ($ws, 'WebService::AngelXML::Auth');
is($ws->prompt, "junk", '$ws->prompt');

$ws = WebService::AngelXML::Auth->new(page=>"/333");
isa_ok ($ws, 'WebService::AngelXML::Auth');
is($ws->page, "/333", '$ws->page');

$ws = WebService::AngelXML::Auth->new(mimetype=>"test/junk");
isa_ok ($ws, 'WebService::AngelXML::Auth');
is($ws->mimetype, "test/junk", '$ws->mimetype');

$ws = WebService::AngelXML::Auth->new(cgi=>"bad data");
isa_ok ($ws, 'WebService::AngelXML::Auth');
isa_ok ($ws->cgi, 'CGI', "fix bad CGI object");

$ws = WebService::AngelXML::Auth->new(cgi=>$ws);
isa_ok ($ws, 'WebService::AngelXML::Auth');
isa_ok ($ws->cgi, 'CGI', "fix bad CGI object");

BEGIN { use_ok( 'CGI' ); }
my $cgi=CGI->new('test=junk');
$ws = WebService::AngelXML::Auth->new(cgi=>$cgi);
isa_ok ($ws, 'WebService::AngelXML::Auth');
isa_ok ($ws->cgi, 'CGI');
is($ws->cgi->param(-name=>"test"), "junk", '$ws->cgi->param');
