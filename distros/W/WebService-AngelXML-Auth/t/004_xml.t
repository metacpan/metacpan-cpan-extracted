# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More;
use Test::XML tests => 14;

BEGIN { use_ok( 'WebService::AngelXML::Auth' ); }
BEGIN { use_ok( 'CGI' ); }

my $cgi=CGI->new('id=7861&pin=5546&page=100');
isa_ok ($cgi, 'CGI');

my $ws = WebService::AngelXML::Auth->new(cgi=>$cgi);
isa_ok ($ws, 'WebService::AngelXML::Auth');
is_well_formed_xml(output(0,"100"));
is_well_formed_xml(output(-1,"100"));

$ws->allow(1); #actually sends "0"
is_well_formed_xml($ws->response);
is_xml($ws->response, output(0,"100"), '$ws->response');

$ws->allow(0); #actually sends "-1"
is_well_formed_xml($ws->response);
is_xml($ws->response, output(-1,"100"), '$ws->response');

$ws->deny(1); #actually sends "-1"
is_well_formed_xml($ws->response);
is_xml($ws->response, output(-1,"100"), '$ws->response');

$ws->deny(0); #actually sends "0"
is_well_formed_xml($ws->response);
is_xml($ws->response, output(0,"100"), '$ws->response');
#is($ws->response, output(0,"100"), '$ws->response');

sub output {
  my $value=shift;
  my $page=shift;
  return qq{<ANGELXML>
  <MESSAGE>
    <PLAY>
      <PROMPT type="text">.</PROMPT>
    </PLAY>
    <GOTO destination="$page" />
  </MESSAGE>
  <VARIABLES>
    <VAR name="status_code" value="$value" />
  </VARIABLES>
</ANGELXML>
};

}
