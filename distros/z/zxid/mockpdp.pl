#!/usr/bin/perl
# 15.9.2010, Sampo Kellomaki (sampo@zxid.org)
#
# Very simple mock PDP to be run as CGI script
#
# mini_httpd -p 8082 -c '*.pl' &
# PDP_URL=http://idp.tas3.pt:8082/mockpdp.pl
# PEPMAP=subj$eduPersonEntitlement$rename$role$
#
# The $policy points to XML policy in proprietary format (not XACML)
#
#   <authority>
#     <user name="End-User">
#        <aspect name="Competency" right="display"/>
#        <aspect name="Interests" right="display"/>
#        <aspect name="Demographics" right="display"/>
#        <aspect name="Product" right="no"/>
#        <aspect name="Address" right="no"/>
#        <aspect name="Affiliations" right="no"/>
#        <aspect name="ContactInfo" right="no"/>
#     </user>
#     <user name="CareerCoach">
#        <aspect name="Competency" right="display"/>
#        <aspect name="Interests" right="display"/>
#     </user>
#   </authority>
#
# where the <user> element really describes a role and is matched by name against role
# field from the XACML request. <aspect> is matched by name against resource from
# the XACML request and the right is matched against action from XACML request.
# An exact match results Permit, otherwise Deny is issued.
# Special values 'no' and empty string also result Deny.
#
# ./zxcall -a https://idp.tas3.eu/zxididp?o=B bh:betty -az 'eduPersonEntitlement=user1&rs=Interests&Action=display'

use XML::Simple;
use Data::Dumper;

$issuer = 'http://idp.tas3.pt:8082/mockpdp.pl';
$policy = 'ePortfolioDemo-risaris-01.xml';

if ($ENV{SERVER_SOFTWARE}) {
    if ($ENV{SERVER_SOFTWARE} =~ /^mini_httpd/) {
	close STDERR;   # tailf /var/tmp/pdmail.err &
	open STDERR, ">>/var/tmp/mockpdp.err" or die "write log(/var/tmp/mockpdp.err): $!";
	#STDERR->autoflush(1);
    }
}

sub datetime {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($_[0]);
    return sprintf "%04d-%02d-%02dT%02d:%02d:%02dZ", $year+1900, $mon+1, $mday, $hour, $min, $sec;
}

$len = $ENV{CONTENT_LENGTH};
if ($len) {
    my $off = 0;
    while ($off < $len) {
	my $got = sysread STDIN, $data, $len-$off, $off;
	last if $got <= 0;
	$off += $got;
    }
}

#warn "IN($data)";

### Read in policy

undef $/;
open POLICY, "<$policy" or die "Cant read policy from($policy)";
$pol = <POLICY>;
close POLICY;

$xx = XMLin $pol, KeepRoot=>0, ForceArray=>['user','aspect'], KeyAttr=>{ 'user'=>'name', 'aspect'=>'name' }, ValueAttr=>{'aspect'=>'right'}, GroupTags => { 'aspect' => 'right' } ;
# , ForceArray=>['user']
#warn "Policy: ".Dumper($xx);

### Parse request

if (length $data) {
    $rxx = XMLin $data, ForceArray=>['xac:Attribute'], KeepRoot=>0, KeyAttr=>{ 'xac:Attribute'=>'AttributeId' }, GroupTags => { 'xac:Action' => 'xac:Attribute', 'xac:Subject' => 'xac:Attribute', 'xac:Resource' => 'xac:Attribute', 'xac:Environment' => 'xac:Attribute' } ;
    #warn "Request: ".Dumper($rxx);
} else {
    warn "No XACML request supplied?!?";
}

$xac_req = $$rxx{'e:Body'}{'xasp:XACMLAuthzDecisionQuery'}{'xac:Request'};
#warn "xac_req: ".Dumper($xac_req);

$action = $$xac_req{'xac:Action'}{'urn:oasis:names:tc:xacml:1.0:action:action-id'}{'xac:AttributeValue'};
$resource = $$xac_req{'xac:Resource'}{'urn:oasis:names:tc:xacml:1.0:resource:resource-id'}{'xac:AttributeValue'};
$role = $$xac_req{'xac:Subject'}{'role'}{'xac:AttributeValue'};

### Actual policy evaluation

$perm = $$xx{'user'}{$role}{'aspect'}{$resource}{'right'};
warn "perm($perm) from role($role) resource($resource) action($action)";

if ($perm eq 'no' || !length $perm) {
    $decision = 'Deny';
} elsif ($action eq $perm) {
    $decision = 'Permit';
} else {
    $decision = 'Deny';
}

### Response

$instant  = datetime(time);
$notafter = datetime(time+3*3600);
$id = rand(10000);

print <<SOAP;
Content-type: text/plain

<e:Envelope xmlns:e="http://schemas.xmlsoap.org/soap/envelope/">
<e:Header></e:Header>
<e:Body>
<sp:Response xmlns:sp="urn:oasis:names:tc:SAML:2.0:protocol"
    ID="R$id" IssueInstant="$instant" Version="2.0">
<sa:Issuer xmlns:sa="urn:oasis:names:tc:SAML:2.0:assertion">$issuer</sa:Issuer>

<sp:Status>
<sp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"></sp:StatusCode>
</sp:Status>

<sa:Assertion xmlns:sa="urn:oasis:names:tc:SAML:2.0:assertion"
    ID="A$id" IssueInstant="$instant" Version="2.0">
<sa:Issuer>$issuer</sa:Issuer>
<sa:Conditions NotBefore="$instant" NotOnOrAfter="$notafter"></sa:Conditions>
<xasa:XACMLAuthzDecisionStatement xmlns:xasa="urn:oasis:xacml:2.0:saml:assertion:schema:os">
<xac:Response xmlns:xac="urn:oasis:names:tc:xacml:2.0:context:schema:os">
<xac:Result>
<xac:Decision>$decision</xac:Decision>
<xac:Status>
<xac:StatusCode Value="urn:oasis:names:tc:xacml:1.0:status:ok"></xac:StatusCode>
</xac:Status>
</xac:Result>
</xac:Response>
</xasa:XACMLAuthzDecisionStatement>
</sa:Assertion>

</sp:Response>
</e:Body>
</e:Envelope>
SOAP
    ;

__END__

Example (azrq1):

<e:Envelope xmlns:e="http://schemas.xmlsoap.org/soap/envelope/"><e:Body><xasp:XACMLAuthzDecisionQuery xmlns:xasp="urn:oasis:xacml:2.0:saml:protocol:schema:os" ID="RmQtc_SvgPVYANCPrELYfjl59" IssueInstant="2009-12-19T11:33:54Z" Version="2.0"><sa:Issuer xmlns:sa="urn:oasis:names:tc:SAML:2.0:assertion">http://sp.tas3.pt:8080/zxidservlet/sso?o=B</sa:Issuer><ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#"><ds:SignedInfo><ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"></ds:CanonicalizationMethod><ds:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"></ds:SignatureMethod><ds:Reference URI="#RmQtc_SvgPVYANCPrELYfjl59"><ds:Transforms><ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"></ds:Transform><ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"></ds:Transform></ds:Transforms><ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"></ds:DigestMethod><ds:DigestValue>60AyrnQBTal1wgUkU80gWWUAB4Y=</ds:DigestValue></ds:Reference></ds:SignedInfo><ds:SignatureValue>QbXbs9WLovuE0Ft15GRK5n8t9iohQzgPUarSQklRIcvCDFafdewEZTGGYLsprZtarBMUTthmu7iVmxwV+iaW3ZoS5FmgoCta5hakMEIVxC8wAhF6JYi3hY3mYlwc86apYGKh/525KTNIbKXrA5nnQUNX6ORyXK3Vu09qyzMnOTE=</ds:SignatureValue></ds:Signature><xac:Request xmlns:xac="urn:oasis:names:tc:xacml:2.0:context:schema:os"><xac:Subject></xac:Subject><xac:Resource></xac:Resource><xac:Action><xac:Attribute AttributeId="urn:oasis:names:tc:xacml:1.0:action:action-id" DataType="http://www.w3.org/2001/XMLSchema#string"><xac:AttributeValue>Show</xac:AttributeValue></xac:Attribute></xac:Action><xac:Environment></xac:Environment></xac:Request></xasp:XACMLAuthzDecisionQuery></e:Body></e:Envelope>

Example (azrs1):

<e:Envelope xmlns:e="http://schemas.xmlsoap.org/soap/envelope/">
<e:Header></e:Header>
<e:Body>
<sp:Response xmlns:sp="urn:oasis:names:tc:SAML:2.0:protocol" ID="R3yhGlzrJ_DCeoYj_apS773FQ" IssueInstant="2009-12-19T11:33:55Z" Version="2.0">
<sa:Issuer xmlns:sa="urn:oasis:names:tc:SAML:2.0:assertion">http://idp.tas3.pt:8081/zxididp?o=B</sa:Issuer>
<ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
<ds:SignedInfo>
<ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"></ds:CanonicalizationMethod>
<ds:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"></ds:SignatureMethod>
<ds:Reference URI="#R3yhGlzrJ_DCeoYj_apS773FQ">
<ds:Transforms>
<ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"></ds:Transform>
<ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"></ds:Transform>
</ds:Transforms>
<ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"></ds:DigestMethod>
<ds:DigestValue>B+Mu8P4wXvV8EjW64gzpMN2vFio=</ds:DigestValue>
</ds:Reference>
</ds:SignedInfo>
<ds:SignatureValue>iZJxULLrSbdVmcRg5cqwBfNDs0bpWkRNYyJqFsfeq9TB3styJW2YpdajbFX/GF996ERN1RiQam7T+mkGaa10eBCRaPrf4RWdEPgk6toiwjObWxQxLoN1VPbiOoaeCXKqkYklC25cwnVzmp9PzE4cNvOpowWHc/px+JN4P7OxVpw=</ds:SignatureValue>
</ds:Signature>
<sp:Status>
<sp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"></sp:StatusCode>
</sp:Status>

<sa:Assertion xmlns:sa="urn:oasis:names:tc:SAML:2.0:assertion" ID="A1aRci5gH7kAiQB9xFFRhwwhf" IssueInstant="2009-12-19T11:33:55Z" Version="2.0">
<sa:Issuer>http://idp.tas3.pt:8081/zxididp?o=B</sa:Issuer>
<sa:Conditions NotBefore="2009-12-19T11:33:55Z" NotOnOrAfter="2009-12-19T12:33:55Z"></sa:Conditions>
<xasa:XACMLAuthzDecisionStatement xmlns:xasa="urn:oasis:xacml:2.0:saml:assertion:schema:os">
<xac:Response xmlns:xac="urn:oasis:names:tc:xacml:2.0:context:schema:os">
<xac:Result>
<xac:Decision>Permit</xac:Decision>
<xac:Status>
<xac:StatusCode Value="urn:oasis:names:tc:xacml:1.0:status:ok"></xac:StatusCode>
</xac:Status>
</xac:Result>
</xac:Response>
</xasa:XACMLAuthzDecisionStatement>
</sa:Assertion>

</sp:Response>
</e:Body>
</e:Envelope>


<e:Envelope xmlns:e="http://schemas.xmlsoap.org/soap/envelope/"><e:Header></e:Header><e:Body><sp:Response xmlns:sp="urn:oasis:names:tc:SAML:2.0:protocol" ID="R3yhGlzrJ_DCeoYj_apS773FQ" IssueInstant="2009-12-19T11:33:55Z" Version="2.0"><sa:Issuer xmlns:sa="urn:oasis:names:tc:SAML:2.0:assertion">http://idp.tas3.pt:8081/zxididp?o=B</sa:Issuer><ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#"><ds:SignedInfo><ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"></ds:CanonicalizationMethod><ds:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"></ds:SignatureMethod><ds:Reference URI="#R3yhGlzrJ_DCeoYj_apS773FQ"><ds:Transforms><ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"></ds:Transform><ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"></ds:Transform></ds:Transforms><ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"></ds:DigestMethod><ds:DigestValue>B+Mu8P4wXvV8EjW64gzpMN2vFio=</ds:DigestValue></ds:Reference></ds:SignedInfo><ds:SignatureValue>iZJxULLrSbdVmcRg5cqwBfNDs0bpWkRNYyJqFsfeq9TB3styJW2YpdajbFX/GF996ERN1RiQam7T+mkGaa10eBCRaPrf4RWdEPgk6toiwjObWxQxLoN1VPbiOoaeCXKqkYklC25cwnVzmp9PzE4cNvOpowWHc/px+JN4P7OxVpw=</ds:SignatureValue></ds:Signature><sp:Status><sp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"></sp:StatusCode></sp:Status><sa:Assertion xmlns:sa="urn:oasis:names:tc:SAML:2.0:assertion" ID="A1aRci5gH7kAiQB9xFFRhwwhf" IssueInstant="2009-12-19T11:33:55Z" Version="2.0"><sa:Issuer>http://idp.tas3.pt:8081/zxididp?o=B</sa:Issuer><sa:Conditions NotBefore="2009-12-19T11:33:55Z" NotOnOrAfter="2009-12-19T12:33:55Z"></sa:Conditions><xasa:XACMLAuthzDecisionStatement xmlns:xasa="urn:oasis:xacml:2.0:saml:assertion:schema:os"><xac:Response xmlns:xac="urn:oasis:names:tc:xacml:2.0:context:schema:os"><xac:Result><xac:Decision>Permit</xac:Decision><xac:Status><xac:StatusCode Value="urn:oasis:names:tc:xacml:1.0:status:ok"></xac:StatusCode></xac:Status></xac:Result></xac:Response></xasa:XACMLAuthzDecisionStatement></sa:Assertion></sp:Response></e:Body></e:Envelope>

<authority>
<user name="user1">
<aspect name="Competency" right="display"/>
<aspect name="Interests" right="display"/>
<aspect name="Demographics" right="display"/>
<aspect name="Product" right="no"/>
<aspect name="Address" right="no"/>
<aspect name="Affiliations" right="no"/>
<aspect name="ContactInfo" right="no"/>
</user>
<user name="user2">
<aspect name="Competency" right="display"/>
<aspect name="Interests" right="display"/>
</user>
</authority>
