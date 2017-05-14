#!/usr/bin/perl
# 28.1.2011, Sampo Kellomaki (sampo@zxid.org)
#
# Extract attributes from XACML request
#
# Usage: ./xacml2ldif.pl <xacml.xml >attrs.ldif
#
# The input can be SOAP <e:Envelope> containing <xasp:XACMLAuthzDecisionQuery> or
# just raw <xasp:XACMLAuthzDecisionQuery> or even bare <xac:Request>
#
# BUG: The namespace prefixes MUST be e, xasp, and xac.

use XML::Simple;
use Data::Dumper;

undef $/;
$data = <STDIN>;

#warn "IN($data)";

if (length $data) {
    $rxx = XMLin $data, ForceArray=>['xac:Attribute'], KeepRoot=>0, KeyAttr=>{ 'xac:Attribute'=>'AttributeId' }, GroupTags => { 'xac:Action' => 'xac:Attribute', 'xac:Subject' => 'xac:Attribute', 'xac:Resource' => 'xac:Attribute', 'xac:Environment' => 'xac:Attribute' } ;
    #warn "Request: ".Dumper($rxx);
} else {
    die "No XACML request supplied?!?";
}

if (defined($$rxx{'e:Body'}) && defined($$rxx{'e:Body'}{'xasp:XACMLAuthzDecisionQuery'})) {
    $xac_req = $$rxx{'e:Body'}{'xasp:XACMLAuthzDecisionQuery'}{'xac:Request'};
}
$xac_req = $$rxx{'xac:Request'} if !defined $xac_req;
$xac_req = $rxx if !defined $xac_req;
#warn "xac_req: ".Dumper($xac_req);

$idpnid = $$xac_req{'xac:Subject'}{'urn:oasis:names:tc:xacml:1.0:subject:subject-id'}{'xac:AttributeValue'};
print "dn: idpnid=$idpnid,o=users\nobjectclass: tas3user\nidpnid: $idpnid\n";

#warn "xac_req: ".Dumper($$xac_req{'xac:Subject'});
for $k (sort keys %{$$xac_req{'xac:Subject'}}) {
    print "$k: $$xac_req{'xac:Subject'}{$k}{'xac:AttributeValue'}\n";
    $subjmap .= "subj\$$k\$\$\$;";
}
chop $subjmap;
print "subjmap: $subjmap\n";

for $k (sort keys %{$$xac_req{'xac:Resource'}}) {
    print "$k: $$xac_req{'xac:Resource'}{$k}{'xac:AttributeValue'}\n";
    $rsrcmap .= "rsrc\$$k\$\$\$;";
}
chop $rsrcmap;
print "rsrcmap: $rsrcmap\n";

for $k (sort keys %{$$xac_req{'xac:Action'}}) {
    print "$k: $$xac_req{'xac:Action'}{$k}{'xac:AttributeValue'}\n";
    $actmap .= "act\$$k\$\$\$;";
}
chop $actmap;
print "actmap: $actmap\n";

for $k (sort keys %{$$xac_req{'xac:Environment'}}) {
    print "$k: $$xac_req{'xac:Environment'}{$k}{'xac:AttributeValue'}\n";
    $envmap .= "env\$$k\$\$\$;";
}
chop $envmap;
#print "envmap: $envmap\n";   # env is the default anyway

print "\n";

#$action = $$xac_req{'xac:Action'}{'urn:oasis:names:tc:xacml:1.0:action:action-id'}{'xac:AttributeValue'};
#$resource = $$xac_req{'xac:Resource'}{'urn:oasis:names:tc:xacml:1.0:resource:resource-id'}{'xac:AttributeValue'};
#$role = $$xac_req{'xac:Subject'}{'role'}{'xac:AttributeValue'};
#
#$perm = $$xx{'user'}{$role}{'aspect'}{$resource}{'right'};
#warn "perm($perm) from role($role) resource($resource) action($action)";

__END__

Example (azrq1):

<e:Envelope xmlns:e="http://schemas.xmlsoap.org/soap/envelope/"><e:Body><xasp:XACMLAuthzDecisionQuery xmlns:xasp="urn:oasis:xacml:2.0:saml:protocol:schema:os" ID="RmQtc_SvgPVYANCPrELYfjl59" IssueInstant="2009-12-19T11:33:54Z" Version="2.0"><sa:Issuer xmlns:sa="urn:oasis:names:tc:SAML:2.0:assertion">http://sp.tas3.pt:8080/zxidservlet/sso?o=B</sa:Issuer><ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#"><ds:SignedInfo><ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"></ds:CanonicalizationMethod><ds:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"></ds:SignatureMethod><ds:Reference URI="#RmQtc_SvgPVYANCPrELYfjl59"><ds:Transforms><ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"></ds:Transform><ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"></ds:Transform></ds:Transforms><ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"></ds:DigestMethod><ds:DigestValue>60AyrnQBTal1wgUkU80gWWUAB4Y=</ds:DigestValue></ds:Reference></ds:SignedInfo><ds:SignatureValue>QbXbs9WLovuE0Ft15GRK5n8t9iohQzgPUarSQklRIcvCDFafdewEZTGGYLsprZtarBMUTthmu7iVmxwV+iaW3ZoS5FmgoCta5hakMEIVxC8wAhF6JYi3hY3mYlwc86apYGKh/525KTNIbKXrA5nnQUNX6ORyXK3Vu09qyzMnOTE=</ds:SignatureValue></ds:Signature><xac:Request xmlns:xac="urn:oasis:names:tc:xacml:2.0:context:schema:os"><xac:Subject></xac:Subject><xac:Resource></xac:Resource><xac:Action><xac:Attribute AttributeId="urn:oasis:names:tc:xacml:1.0:action:action-id" DataType="http://www.w3.org/2001/XMLSchema#string"><xac:AttributeValue>Show</xac:AttributeValue></xac:Attribute></xac:Action><xac:Environment></xac:Environment></xac:Request></xasp:XACMLAuthzDecisionQuery></e:Body></e:Envelope>
