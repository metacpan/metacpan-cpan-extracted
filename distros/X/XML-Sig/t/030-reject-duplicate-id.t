use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Temp qw(tempdir);
use XML::Sig;
use XML::LibXML;

my $dir = tempdir(CLEANUP => 1);
my $key = "$dir/k";
my $crt = "$dir/c";
system("openssl genrsa -out $key 2048 2>/dev/null") == 0 or die;
system("openssl req -new -x509 -key $key -out $crt -days 30 -subj '/CN=T' 2>/dev/null") == 0 or die;

# Create a signed element (ID=dup) whose content is "legit"
my $legit = q{<root xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">
  <saml:Assertion ID="dup"><Subject>legit</Subject></saml:Assertion>
</root>};

my $signer = XML::Sig->new({x509 => 1, key => $key, cert => $crt,
                            no_xml_declaration => 1});
my $signed = $signer->sign($legit);

# Inject a SECOND element with the SAME ID, placed AFTER the signed
# legit one (so _get_node picks the legit one and digest matches).
my $xsw = $signed;
$xsw =~ s|</root>|<saml:Assertion ID="dup"><Subject>ATTACKER</Subject></saml:Assertion></root>|;

my $dom     = XML::LibXML->load_xml( string => $xsw );
my $parser  = XML::LibXML::XPathContext->new($dom);
$parser->registerNs('dsig', 'http://www.w3.org/2000/09/xmldsig#');
$parser->registerNs('ec', 'http://www.w3.org/2001/10/xml-exc-c14n#');
$parser->registerNs('saml', 'urn:oasis:names:tc:SAML:2.0:assertion');
$parser->registerNs('ecdsa', 'http://www.w3.org/2001/04/xmldsig-more#');

my $ref_nodes = $parser->findnodes('//*[@ID=\''. 'dup' . '\']');
ok($ref_nodes->size() == 2, "Duplicate IDs found");

my $v = XML::Sig->new({cert => $crt});
isa_ok($v, 'XML::Sig');

ok($v->verify($xsw) == 0, "Verification fails when dumplicate IDs found");

done_testing();
