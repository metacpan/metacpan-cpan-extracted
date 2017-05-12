#!/usr/bin/perl
package VOMS::Lite::SAMLHelper;

use 5.004;
use strict;
use XML::Parser;
use Data::Dumper;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);
%EXPORT_TAGS = ( );
@EXPORT_OK = qw(  );
@EXPORT = ( );
$VERSION = '0.20';

####
# %knownns
# namespaces known about and corresponding local naming shorthand
#
my %knownns=( 'urn:oasis:names:tc:SAML:1.0:assertion' => 'saml1',
              'urn:oasis:names:tc:SAML:1.0:protocol' => 'saml1p',
              'http://www.w3.org/2000/09/xmldsig#' => 'ds',
              'urn:oasis:names:tc:SAML:2.0:assertion' => 'saml2',
              'urn:oasis:names:tc:SAML:2.0:protocol' => 'saml2p',
              'http://www.w3.org/2001/04/xmlenc#' => 'xenc'
            );

####
# %attributes
# local friendlynames for attributes that might appear in a SAML Assertion
#
my %attributes = ( 
# eduPerson Attributes
qw|
  urn:oid:1.3.6.1.4.1.5923.1.1.2                        eduPerson
  urn:mace:dir:attribute-def:eduPerson                  eduPerson
  urn:oid:1.3.6.1.4.1.5923.1.1.1.1                      eduPersonAffiliation
  urn:mace:dir:attribute-def:eduPersonAffiliation       eduPersonAffiliation
  urn:oid:1.3.6.1.4.1.5923.1.1.1.7                      eduPersonEntitlement
  urn:mace:dir:attribute-def:eduPersonEntitlement       eduPersonEntitlement
  urn:oid:1.3.6.1.4.1.5923.1.1.1.2                      eduPersonNickname
  urn:mace:dir:attribute-def:eduPersonNickname          eduPersonNickname
  urn:oid:1.3.6.1.4.1.5923.1.1.1.3                     	eduPersonOrgDN
  urn:mace:dir:attribute-def:eduPersonOrgDN            	eduPersonOrgDN
  urn:oid:1.3.6.1.4.1.5923.1.1.1.4                      eduPersonOrgUnitDN
  urn:mace:dir:attribute-def:eduPersonOrgUnitDN         eduPersonOrgUnitDN
  urn:oid:1.3.6.1.4.1.5923.1.1.1.5                      eduPersonPrimaryAffiliation
  urn:mace:dir:attribute-def:eduPersonPrimaryAffiliation eduPersonPrimaryAffiliation
  urn:oid:1.3.6.1.4.1.5923.1.1.1.8                      eduPersonPrimaryOrgUnitDN
  urn:mace:dir:attribute-def:eduPersonPrimaryOrgUnitDN  eduPersonPrimaryOrgUnitDN
  urn:oid:1.3.6.1.4.1.5923.1.1.1.6                      eduPersonPrincipalName
  urn:mace:dir:attribute-def:eduPersonPrincipalName     eduPersonPrincipalName
  urn:oid:1.3.6.1.4.1.5923.1.1.1.9                      eduPersonScopedAffiliation
  urn:mace:dir:attribute-def:eduPersonScopedAffiliation eduPersonScopedAffiliation
  urn:oid:1.3.6.1.4.1.5923.1.1.1.10                     eduPersonTargetedID
  urn:mace:dir:attribute-def:eduPersonTargetedID        eduPersonTargetedID
|,
# eduOrg Attributes
qw|
  urn:oid:1.3.6.1.4.1.5923.1.2.2                        eduOrg
  urn:mace:dir:attribute-def:eduOrg                     eduOrg
  urn:oid:1.3.6.1.4.1.5923.1.2.1.2                      eduOrgHomePageURI
  urn:mace:dir:attribute-def:eduOrgHomePageURI          eduOrgHomePageURI
  urn:oid:1.3.6.1.4.1.5923.1.2.1.3                      eduOrgIdentityAuthNPolicyURI
  urn:mace:dir:attribute-def:eduOrgIdentityAuthNPolicyURI eduOrgIdentityAuthNPolicyURI
  urn:oid:1.3.6.1.4.1.5923.1.2.1.4                      eduOrgLegalName
  urn:mace:dir:attribute-def:eduOrgLegalName            eduOrgLegalName
  urn:oid:1.3.6.1.4.1.5923.1.2.1.5                      eduOrgSuperiorURI
  urn:mace:dir:attribute-def:eduOrgSuperiorURI          eduOrgSuperiorURI
  urn:oid:1.3.6.1.4.1.5923.1.2.1.6                      eduOrgWhitePagesURI
  urn:mace:dir:attribute-def:eduOrgWhitePagesURI        eduOrgWhitePagesURI
|,
# VOMS Attributes
qw|
  http://dci-sec.org/saml/attribute/virtual-organization VOMSVO
  http://authz-interop.org/xacml/subject/voms-fqan      VOMSFQAN
  http://dci-sec.org/saml/attribute/group               VOMSGroup
  http://dci-sec.org/saml/attribute/group/primary       VOMSPrimaryGroup
  http://dci-sec.org/saml/attribute/role                VOMSRole
|, 
# Others
qw|
  urn:mace:dir:attribute-def:eduCourseOffering          eduCourseOffering
  urn:oid:1.3.6.1.4.1.5923.1.6.1.1                      eduCourseOffering
  urn:mace:dir:attribute-def:eduCourseMember            eduCourseMember
  urn:oid:1.3.6.1.4.1.5923.1.6.1.2                      eduCourseMember
  urn:mace:dir:attribute-def:cn                         cn
  urn:oid:2.5.4.3                                       cn
  urn:mace:dir:attribute-def:sn                         sn
  urn:oid:2.5.4.4                                       sn
  urn:mace:dir:attribute-def:givenName                  givenName
  urn:oid:2.5.4.42                                      givenName
  urn:mace:dir:attribute-def:mail                       mail
  urn:oid:0.9.2342.19200300.100.1.3                     mail
  urn:mace:dir:attribute-def:telephoneNumber            telephoneNumber
  urn:oid:2.5.4.20                                      telephoneNumber
  urn:mace:dir:attribute-def:title                      title
  urn:oid:2.5.4.12                                      title
  urn:mace:dir:attribute-def:initials                   initials
  urn:oid:2.5.4.43                                      initials
  urn:mace:dir:attribute-def:description                description
  urn:oid:2.5.4.13                                      description
  urn:mace:dir:attribute-def:carLicense                 carLicense
  urn:oid:2.16.840.1.113730.3.1.1                       carLicense
  urn:mace:dir:attribute-def:departmentNumber           departmentNumber
  urn:oid:2.16.840.1.113730.3.1.2                       departmentNumber
  urn:mace:dir:attribute-def:displayName                displayName
  urn:oid:2.16.840.1.113730.3.1.3                       employeeNumber
  urn:mace:dir:attribute-def:employeeNumber             employeeNumber
  urn:oid:2.16.840.1.113730.3.1.4                       employeeType
  urn:mace:dir:attribute-def:employeeType               employeeType
  urn:oid:2.16.840.1.113730.3.1.39                      preferredLanguage
  urn:mace:dir:attribute-def:preferredLanguage          preferredLanguage
  urn:oid:2.16.840.1.113730.3.1.241                     displayName
  urn:mace:dir:attribute-def:manager                    manager
  urn:oid:0.9.2342.19200300.100.1.10                    manager
  urn:mace:dir:attribute-def:seeAlso                    seeAlso
  urn:oid:2.5.4.34                                      seeAlso
  urn:mace:dir:attribute-def:facsimileTelephoneNumber   facsimileTelephoneNumber
  urn:oid:2.5.4.23                                      facsimileTelephoneNumber
  urn:mace:dir:attribute-def:street                     street
  urn:oid:2.5.4.9                                       street
  urn:mace:dir:attribute-def:postOfficeBox              postOfficeBox
  urn:oid:2.5.4.18                                      postOfficeBox
  urn:mace:dir:attribute-def:postalCode                 postalCode
  urn:oid:2.5.4.17                                      postalCode
  urn:mace:dir:attribute-def:st                         st
  urn:oid:2.5.4.8                                       st
  urn:mace:dir:attribute-def:l                          l
  urn:oid:2.5.4.7                                       l
  urn:mace:dir:attribute-def:o                          o
  urn:oid:2.5.4.10                                      o
  urn:mace:dir:attribute-def:ou                         ou
  urn:oid:2.5.4.11                                      ou
  urn:mace:dir:attribute-def:businessCategory           businessCategory
  urn:oid:2.5.4.15                                      businessCategory
  urn:mace:dir:attribute-def:physicalDeliveryOfficeName physicalDeliveryOfficeName
  urn:oid:2.5.4.19                                      physicalDeliveryOfficeName
|
);

######
# %elements 
# Hash of how to parse XML
# ( 
#   NameSpace1 => 
#     {
#       ElementInNamespace1 =>
#         { 
#           "Elements"   => { ChildElement => /parse|try|dump|text/, ... },
#           "Attributes" => { AttributeName => /required|optional/, ... },
#           "RE" => 'RegularExpression for elements (think DTD) NB Namespaces from knownns are expected'
#         }, 
#       ...
#     }, 
#   ...
# )
#
# ideally we'd parse the xsd and create this hash table; for now defined inline below
#
my %elements = (
  "urn:oasis:names:tc:SAML:1.0:protocol" => {
    "Response" =>
      { Elements => { qw/Status parse Assertion parse Signature dump/ }, 
        Attributes => { qw/MajorVersion required MinorVersion required ResponseID required Recipient optional InResponseTo optional IssueInstant required/ }, 
        RE => '((ds:Signature )?(saml1p:Status )(saml1:Assertion )*|(saml1p:Status )(saml1:Assertion )*(ds:Signature )?)'
      },
    "Status" =>
      { Elements   => { qw/StatusCode parse StatusMessage parse StatusDetail parse/ }, 
        RE => '(saml1p:StatusCode )(saml1p:StatusMessage )?(saml1p:StatusDetail )?' 
      },
    "StatusDetail" => 
      { Elements => { qw/* dump/ }, 
        RE=>'*'
      },
    "StatusCode" => { Attributes => { qw/Value required/ } },
    "StatusMessage" => { Elements => { '' => 'text' } }
  },
  'urn:oasis:names:tc:SAML:1.0:assertion' => {
    "Assertion" => 
      { Elements => { qw/Conditions parse Advice parse Subject parse AuthenticationStatement parse AuthorisationDecisionStatement parse AttributeStatement parse Signature dump/ }, 
        Attributes => { qw/MajorVersion required MinorVersion required AssertionID required Issuer required IssueInstant required/ }, 
        RE=>'(saml1:Conditions )?(saml1:Advice )?(saml1:Subject |saml1:AuthenticationStatement |saml1:AuthorisationDecisionStatement |saml1:AttributeStatement )+(ds:Signature )?'
      },
    "Conditions" => 
      { Elements => { qw/AudienceRestrictionCondition parse DoNotCacheCondition parse * dump/ }, 
        Attributes => { qw/NotBefore required NotOnOrAfter required/ },
        RE=>'(saml1:AudienceRestrictionCondition |saml1:DoNotCacheCondition |[\w:]+ | )'
      },
    'DoNotCacheCondition' => { },  #Well it's just ziz node you know
    'AudienceRestrictionCondition' => 
      { Elements => { qw/Audience parse/ },
        RE=>'(saml1:Audience )+'
      },
    "Subject" =>
      { Elements => { qw/NameIdentifier parse SubjectConfirmation parse/ },
        RE=>'(saml1:NameIdentifier |saml1:NameIdentifier saml1:SubjectConfirmation |saml1:SubjectConfirmation )'
      },
    'SubjectConfirmation' =>
      { Elements => { qw/ConfirmationMethod parse SubjectConfirmationData parse KeyInfo dump/ },
        RE=>'(saml1:ConfirmationMethod )+(saml1:SubjectConfirmationData )?(ds:KeyInfo )?'
      },
    'AuthenticationStatement' =>
      { Elements => { qw/Subject parse SubjectLocality parse AuthorityBinding parse/ },
        Attributes => { qw/AuthenticationMethod required AuthenticationInstant required/ },
        RE=>'((saml1:Subject )(saml1:SubjectLocality )?(saml1:AuthorityBinding )*|(saml1:SubjectLocality )?(saml1:AuthorityBinding )*(saml1:Subject ))'
      },
    'AuthorisationDecisionStatement' =>
      { Elements => { qw/Subject parse Action parse Evidence parse/ },
        Attributes => { qw/Resource required Decision required/ },
        RE=>'((saml1:Subject )(saml1:Action )*(saml1:Evidence )?|(saml1:Action )*(saml1:Evidence )?(saml1:Subject ))'
      },
    'Evidence' =>
      { Elements => { qw/Assertion parse AssertionIDReference parse/ }, 
        RE=>'(saml1:Assertion |saml1:AssertionIDReference )+'
      },
    'AssertionIDReference' => { Elements => { '' => 'text' } },
    'AttributeStatement' =>
      { Elements => { qw/Subject parse Attribute parse/ },
        RE=>'((saml1:Subject )(saml1:Attribute )+|(saml1:Attribute )+|(saml1:Subject ))'
      },
    'Attribute' =>
      { Elements => { qw/AttributeValue parse/ },
        Attributes => { qw/AttributeName required AttributeNamespace required/ },
        RE=>'(saml1:AttributeValue )+'
      },
    'Audience' => { Elements => { '' => 'text' } },
    'NameIdentifier' =>
      { Elements => { '' => 'text' }, 
        Attributes => { qw/NameQualifier optional Format optional/ }
      },
    'ConfirmationMethod' => { Elements => { '' => 'text' } },
    'AttributeValue' =>
      { Elements => { qw/* try/ },
        Attributes => { qw/* optional/ },
        RE=>'*'
      },
    'SubjectLocality' => { Attributes => { qw/IPAddress optional DNSAddress optional/ } }
  },
  'urn:oasis:names:tc:SAML:2.0:protocol' => {
    "Response" => 
      { Elements => { qw/Issuer parse Signature dump Extension dump Status parse Assertion parse EncryptedAssertion parse/ } ,
        Attributes => { qw/ID required InResponseTo optional Version required IssueInstant required Destination optional Consent optional/ },
        RE => '((saml2:Issuer )?(ds:Signature )?(saml2p:Extension )?(saml2p:Status )(saml2:Assertion |saml2:EncryptedAssertion )*'.
              '|(saml2:Assertion |saml2:EncryptedAssertion )*(saml2:Issuer )?(ds:Signature )?(saml2:Extension )?(saml2:Status ))'
      },
    "Status" => 
      { Elements => { qw/StatusCode parse StatusMessage parse StatusDetail parse/}, 
        RE => '(saml2p:StatusCode )(saml2p:StatusMessage )?(saml2p:StatusDetail )?' 
      },
    "StatusDetail" =>
      { Elements => { qw/* dump/ }, 
        RE => '*' 
      },
    "StatusCode" => 
      { Elements => { qw/StatusCode parse/ }, 
        Attributes => {qw/Value required/}, 
        RE=>'(saml2p:StatusCode | )' 
      },
    "StatusMessage" => { Elements => { '' => 'text' } }
  },
  'urn:oasis:names:tc:SAML:2.0:assertion' => {
    'EncryptedAssertion' =>
      { Elements => { qw/EncryptedData dump EncryptedKey dump/ }, 
        RE=>'(xenc:EncryptedData )(xenc:EncryptedKey )*'
      },
    'Assertion' =>
      { Elements => { qw/Issuer parse Signature dump Subject parse Conditions parse Advice parse AuthnStatement parse AuthzDecisionStatement parse AttributeStatement parse/ }, 
        Attributes => { qw/Version required ID required IssueInstant required/}, 
        RE=>'(saml2:Issuer )(ds:Signature )?(saml2:Subject )?(saml2:Conditions )?(saml2:Advice )?(saml2:AuthnStatement |saml2:AuthzDecisionStatement |saml2:AttributeStatement )*' 
      },
    'Issuer' =>
      { Elements => { '' => 'text' },
        Attributes => { qw/Format optional SPProvidedID optional NameQualifier optional SPNameQualifier optional/}
      },
    'Subject' =>
      { Elements => { qw/BaseID parse NameID parse EncryptedID parse SubjectConfirmation parse/ },
        RE=>'(((saml2:BaseID |saml2:NameID |saml2:EncryptedID )(saml2:SubjectConfirmation )*?)(saml2:SubjectConfirmation )+'.
            '|(saml2:SubjectConfirmation )+((saml2:BaseID |saml2:NameID |saml2:EncryptedID )(saml2:SubjectConfirmation )*))' 
      },
    'BaseID' => { Attributes => { qw/NameQualifier optional SPNameQualifier optional/ } },
    'NameID' =>
      { Elements => { '' => 'text' },
        Attributes => { qw/Format optional SPProvidedID optional NameQualifier optional SPNameQualifier optional/ }
      },
    'EncryptedID' => 
      { Elements => { qw/EncryptedData dump EncryptedKey dump/ },
        RE=>'(xenc:EncryptedData )(xenc:EncryptedKey )*' 
      },
    'SubjectConfirmation' => 
      { Attributes => { qw/Method required/ },
        Elements => { qw/BaseID parse NameID parse EncryptedID parse SubjectConfirmationData parse/ },
        RE=>'(saml2:BaseID |saml2:NameID |saml2:EncryptedID )?(saml2:SubjectConfirmationData )?'
      },
    'SubjectConfirmationData' => 
      { Attributes => { qw/* optional/ },
        Elements => { qw/* dump/ },
        RE=>'*'
      },
    'Conditions' =>
      { Attributes => { qw/NotBefore optional NotOnOrAfter optional/ },
        Elements => { qw/AudienceRestriction parse OneTimeUse parse ProxyRestriction parse/ },
        RE=>'(saml2:Condition |saml2:AudienceRestriction |saml2:OneTimeUse |saml2:ProxyRestriction | )*'
      },
    'AudienceRestriction' =>
      { Elements => { qw/Audience parse/ },
        RE=>'(saml2:Audience )+'
      },
    'Audience' => { Elements => { '' => 'text' } },
    'OneTimeUse' => { RE=>' ' },
    'ProxyRestriction' =>
      { Elements => { qw/Audience parse/ },
        Attributes => { qw/Count optional/ },
        RE=>'(saml2:Audience )*'
      },
    'Advice' =>
      { Elements => { qw/AssertionIDRef parse AssertionURIRef parse Assertion parse EncryptedAssertion parse * dump/ },
        RE=>'(saml2:AssertionIDRef |saml2:AssertionURIRef |saml2:Assertion |saml2:EncryptedAssertion |[\w:]* )*'
      },
    'AssertionIDRef' => { Elements => { '' => 'text' } },
    'AssertionURIRef' => { Elements => { '' => 'text' } },
    'AuthnStatement' =>
      { Elements => { qw/SubjectLocality parse AuthnContext parse/ },
        Attributes => { qw/AuthnInstant required SessionIndex optional SessionNotOnOrAfter optional/ },
        RE=>'(saml2:SubjectLocality )?(saml2:AuthnContext )'
      },
    'SubjectLocality' => { Attributes => { qw/Address optional DNSName optional/ } },
    'AuthnContext' =>
      { Elements => { qw/AuthnContextClassRef parse AuthnContextDecl parse AuthnContextDeclRef parse AuthenticatingAuthority parse/ },
        RE=>'((saml2:AuthnContextClassRef )(saml2:AuthnContextDecl |saml2:AuthnContextDeclRef )?|(saml2:AuthnContextDecl |saml2:AuthnContextDeclRef ))(saml2:AuthnticatingAuthority )*'
      },
    'AuthnContextClassRef' => { Elements => { '' => 'text' } },
    'AuthnContextDecl' => { Elements => { qw/* dump/ } },
    'AuthnContextDeclRef' => { Elements => { '' => 'text' } },
    'AuthenticatingAuthority' => { Elements => { '' => 'text' } },
    'AuthzDecisionStatement' =>
      { Attributes => { qw/Resource required Decision required/ },
        Elements => { qw/Action parse Evidence parse/ },
        RE=>'(saml2:Action )+(saml2:Evidence )?'
      },
    'Action' => { Attributes => { qw/Namespace required/ } },
    'Evidence' =>
      { Elements => { qw/AssertionIDRef parse AssertionURIRef parse Assertion parse EncryptedAssertion parse/ },
        RE=>'(saml2:AssertionIDRef |saml2:AssertionURIRef |saml2:Assertion |saml2:EncryptedAssertion )+'
      },
    'AttributeStatement' =>
      { Elements => { qw/Attribute parse EncryptedAttribute parse/ },
        RE=>'(saml2:Attribute |saml2:EncryptedAttribute )+'
      },
    'Attribute' =>
      { Attributes => { qw/Name required NameFormat optional FriendlyName optional * optional/ },
        Elements => { qw/AttributeValue parse/ },
        RE=>'(saml2:AttributeValue | )*'
      },
    'AttributeValue' =>
      { Attributes => { qw/* optional/ },
        Elements => { qw/* try/ },
        RE=>'*'
      },
    'EncryptedAttribute' =>
      { Elements => { qw/EncryptedData dump EncryptedKey dump/ },
        RE=>'(xenc:EncryptedData )(xenc:EncryptedKey )*'
      }
  }
);

##################################################
# parseSAML
#
# Expects serialised xml on in $_[0].
# Called in scalar context returns 1 if successfully parsed 0 otherwise.
# Called in array context returns a copy of the parsed object array.
# If $_[1] is set to an array reference this is used to prime 
# and pass the parsed object array back.
#
# Creates new XML::Parser
# Uses getNode to abstractly parse root node
# Uses parseElement to parse this abstract root node
#
# Parsed object is represented as an array of XPath-like data stings
# (one array element per data value i.e. may contain \n).
#
# e.g.
# /path/to/node (namespace)
# /path/to/node{attribute} (attribute.namespace.if.any) = attributevalue
# ...
# /path/to/node TextContentIfAny
# /path/to/node/subnode (namesapce)
# /path/to/node/subnode{attribute} (attribute.namespace.if.any) = attributevalue
# ...
# /path/to/node/subnode TextContentIfAny
# /path/to/node/subnode/subsubnode...
# /path/to/node2 (namespace)
# ...
#
# namespaces will be consumed and returned only in parenthases 
#

sub parseSAML {
  my $data = shift;
  my @elements;
  my $elements=\@elements;
  if ( $_[0] && ref($_[0]) eq "ARRAY" ) { $elements = shift; }
  my $parser = new XML::Parser( Style => 'Tree' );
  my $tree=$parser->parse($data);
  my $rootref=getNode($tree);
  my $ret=parseElement($rootref,$elements);
  return wantarray ? @$elements : $ret;
}

###################
# Try to normalise the responces from SAML 1 and SAML2 worlds
#
sub getSAMLAttributes {
  my $data = shift;
  my ($start,$type)=(0,0);
  my @a;
  my @b;
  my $scope="";
  my @Warnings=();

  my ($ResponseID,$StatusCodeValue,$NotOnOrAfter,$NotBefore,$NameIdentifier);

  foreach ( parseSAML($data) ) {
    if ( m|/Response{ID} \(\) = (.*)| )                                          {$ResponseID=$1;}
    elsif ( m|/Response{ResponseID} \(\) = (.*)| )                               {$ResponseID=$1;}
    elsif ( m|/Response/Status/StatusCode\{Value\} \(\) = .*?([^:]*)$| )         {$StatusCodeValue=$1;}
    elsif ( m|(?:/Response)?/Assertion/Conditions\{NotOnOrAfter\} \(\) = (.*)| ) {$NotOnOrAfter=$1;}
    elsif ( m|(?:/Response)?/Assertion/Conditions\{NotBefore\} \(\) = (.*)| )    {$NotBefore=$1;}
    elsif ( m|(?:/Response)?/Assertion/Subject/NameID = (.*)| )                  {$NameIdentifier=$1;}
    elsif ( m|(?:/Response)?/Assertion/(?:AttributeStatement\|AuthenticationStatement)/Subject/NameIdentifier = (.*)| ) 
                                                                                 {$NameIdentifier=$1;}

    if ( m|^\S+ \*\* Error\: | ) {push @Warnings, $1;}

    elsif ( m|/Assertion/AttributeStatement/Attribute| ) {
      if ( m|/Assertion/AttributeStatement/Attribute \(urn:oasis:names:tc:SAML:1.0:assertion\)| )             { $type=1; push @a,{};        }
      elsif ( m|/Assertion/AttributeStatement/Attribute \(urn:oasis:names:tc:SAML:2.0:assertion\)| )          { $type=2; push @a,{};        }

      elsif ( $type==2 && m|/Assertion/AttributeStatement/Attribute{Name} \([^)]*\) = (.*)| )                 { 
        $a[-1]->{Name}=$1;
        $a[-1]->{FriendlyName}=(defined $attributes{$a[-1]->{Name}})?"$attributes{$a[-1]->{Name}}":"$a[-1]->{Name}";
        @{$a[-1]->{Value}}=();
      }
      elsif ( $type==2 && m|/Assertion/AttributeStatement/Attribute/AttributeValue \([^)]*\)| )               { push @{$a[-1]->{Value}},undef; }
      elsif ( $type==2 && m|/Assertion/AttributeStatement/Attribute/AttributeValue = (.*)| )                  { 
        ${$a[-1]->{Value}}[-1]=$1;
        push @b,((defined $attributes{$a[-1]->{Name}})?"$attributes{$a[-1]->{Name}}":"$a[-1]->{Name}")." = $1"; }

      elsif ( $type==1 && m|/Assertion/AttributeStatement/Attribute{AttributeName} \([^)]*\) = (.*)| )        { 
        $a[-1]->{Name}=$1;
        $a[-1]->{FriendlyName}=(defined $attributes{$a[-1]->{Name}})?"$attributes{$a[-1]->{Name}}":"$a[-1]->{Name}";
        @{$a[-1]->{Value}}=();
      }
      elsif ( $type==1 && m|/Assertion/AttributeStatement/Attribute/AttributeValue \([^)]*\)| )               { push @{$a[-1]->{Value}},undef; }
      elsif ( $type==1 && m|/Assertion/AttributeStatement/Attribute/AttributeValue{Scope} \([^)]*\) = (.*)| ) { $scope="\@$1"; }
      elsif ( $type==1 && m|/Assertion/AttributeStatement/Attribute/AttributeValue = (.*)| )                  { 
        $a[-1]->{Value}->[-1]="$1$scope"; 
        push @b,((defined $attributes{$a[-1]->{Name}})?"$attributes{$a[-1]->{Name}}":"$a[-1]->{Name}")." = $1$scope"; 
        $scope="";
      }
    }
  }

  my %a;
  foreach (@a) { push @{ $a{$_->{'FriendlyName'}} },@{ $_->{'Value'} }; }

  return {
      Attributes=>\%a,
      ResponseID=>$ResponseID,
      Status=>$StatusCodeValue,
      NotOnOrAfter=>$NotOnOrAfter,
      NotBefore=>$NotBefore,
      Subject=>$NameIdentifier,
      Warnings=>\@Warnings
    };

#  return @b;
}

###################################################

sub getNode {
  my $in=shift;                       #Reference to Array
  my $inns=shift;                     #Reference to Namespace Array #################
  my @array=@{$in};                   #copy array
  my $qname=shift(@array);            #1st element is the name
  my $contentsref=shift(@array);      #2nd element is the Contents Array in the form: $ref = [ \%Attributes , ($Name, @Contents)* ] -- as per tree parsing of XML
  my @contents=@$contentsref;
# shift the attributes off the array 
  my $attributesref=shift(@contents); #Get the Attributes
  my %attributes=($attributesref)?%$attributesref:();
# Reconstruct Namespase Hierarchy
  my %NameSpaces=(defined $inns)?%{$inns}:();  # inherit namespaces
  foreach ( keys %attributes ) { if ( /^xmlns()$/ or /^xmlns:([\w-]+)/ ) {$NameSpaces{$1}=$attributes{$&}; } }
  my ($NSToken,$name,$namespace) = ("","","");
  if ( ! $qname ) { $qname = ""; } # just a text node
  elsif ( $qname =~ /^(?:([\w-]+):)(\w+)$/ ) { ($NSToken,$name) = ($1,$2);}
  else { ($NSToken,$name) = ("",$qname);}
# Infer Namespace for this element
  $namespace=$NameSpaces{$NSToken};
  return { Name           => $name, 
           QName          => $qname, 
           Attributes     => \%attributes, 
           Contents       => \@contents, 
           NameSpaces     => \%NameSpaces, 
           NameSpaceToken => $NSToken, 
           NameSpace      => $namespace 
         };
}

sub getChildNodes {
  my $in=shift;                          # Hash as returned by getNode
  my %hash=%{$in};                       # copy hash
  my @Contents=@{$hash{Contents}};       #
  my %NameSpaces = %{$hash{NameSpaces}};
  my @Children;
  for ( my $i=0;$i<@Contents;$i+=2 ) {
    if ( $Contents[$i] ) { 
      my @tmp = ( $Contents[$i], $Contents[$i+1] );
      my $ref = getNode(\@tmp,\%NameSpaces);
      push @Children,$ref;
    } else {
      push @Children, { TextNode => 1, Contents => $Contents[$i+1] }; 
    }
  }
  return @Children;
}

#########################################################
# CheckNodes
#
# Given a node $_[0], checks a string constructed from its children element names and namespace tokens against a regular experssion $_[1]
# namespace tokens and element names are converted into NameSpaceURI:elementName via lookup in %knownns
#

sub CheckNodes {
  my $ref=shift;
  my $RE=shift;
  my $name=$knownns{$ref->{NameSpace}}.":".$ref->{Name};
  my $Children=join(' ', grep { !/^$/ } map { (($_->{Name})?$knownns{$_->{NameSpace}}.":".$_->{Name}:"") } getChildNodes($ref))." ";
  if ( $Children !~ /^$RE$/ ) { return 0; }
  return 1;
}

#########################################################
# parseElement
#
# Expects reference to an element hash in $_[0] (as returned by getNode) 
# Expects reference to an array $_[1] for output.
# Returns 1 if tree parsing was succesful 0 otherwise.
#
# Consults %elements using the element's $_[0]->{NameSpace} and $_[0]->{Name} values for
#   A regular expression $RE to be used in CheckNodes subroutine
#   A hash %Elements to be used in defining how to parse child nodes in subsequent calls to parseElement
#   A hash %Attributes to be used in getAttributes subroutine
#
# Checks child elements
# Appends statement about namespace to output array 
# gets/checks attributes of element via call to getChildNodes subrouting
# parses child elements via subsequent calls to parseElement
# parses text nodes appending details to the output array
#

sub parseElement {
  my $ref=shift;
  my $elements = shift;
  my $ret=1;

  my $RE         = ($elements{$ref->{NameSpace}}->{$ref->{Name}}->{RE})         ? $elements{$ref->{NameSpace}}->{$ref->{Name}}->{RE} : " ";
  my %Elements   = ($elements{$ref->{NameSpace}}->{$ref->{Name}}->{Elements})   ? %{$elements{$ref->{NameSpace}}->{$ref->{Name}}->{Elements}}   : ();
  my %Attributes = ($elements{$ref->{NameSpace}}->{$ref->{Name}}->{Attributes}) ? %{$elements{$ref->{NameSpace}}->{$ref->{Name}}->{Attributes}} : ();

  my @elements = (" ($ref->{NameSpace})");

  unless ( $RE eq '*' || CheckNodes($ref,$RE) ) { push @elements, " ** Error: Unexpected Nodes in $ref->{Name}"; $ret=0; }

#Parse Atrributes
  unless ( getAttributes(\@elements, $ref, %Attributes ) ) { push @elements, " ** Error: Attribute parsing failed in $ref->{Name}"; $ret=0;}

#Parse Child Nodes
  foreach my $cref ( getChildNodes($ref) ) { 
    if    ( defined $cref->{TextNode} && defined $Elements{''} && $Elements{''} eq "text" && $cref->{Contents} =~ /^\s*(.*?)\s*$/s )   { push @elements, " = $1";}
    elsif ( defined $cref->{TextNode} && defined $Elements{'*'} && $Elements{'*'} eq "dump" && $cref->{Contents} =~ /^\s*(\S.*?)\s*$/s ) { push @elements, " = $1";}
    elsif ( defined $cref->{TextNode} && defined $Elements{'*'} && $Elements{'*'} eq "try"  && $cref->{Contents} =~ /^\s*(\S.*?)\s*$/s ) { push @elements, " = $1";}
    elsif ( defined $cref->{TextNode} && $cref->{Contents} =~ /^\s*$/s )                                       { next; }
    elsif ( ( defined $Elements{$cref->{Name}} && $Elements{$cref->{Name}} eq "parse" ) || 
            ( defined $Elements{'*'} && $Elements{'*'} eq "parse" ) )                      { unless ( parseElement($cref,\@elements) ) { $ret=0;} }
    elsif ( ( defined $Elements{$cref->{Name}} && $Elements{$cref->{Name}} eq "try" ) || 
            ( defined $Elements{'*'} && $Elements{'*'} eq "try" ) )                        { parseElement($cref,\@elements) or push @elements, getNodeAsText($cref); }
    elsif ( ( defined $Elements{$cref->{Name}} && $Elements{$cref->{Name}} eq "dump" ) || 
            ( defined $Elements{'*'} && $Elements{'*'} eq "dump" ) )                       { push @elements, getNodeAsText($cref); } 
    else { push @elements, " ** Error: $ref->{QName} has Unexpected Child Element $cref->{QName} - $Elements{$cref->{QName}}"; }
  }

  push @$elements, map { "/$ref->{Name}$_" } @elements;

  return $ret;
}

#########################################################
# getAttributes
# passed "elements" array by reference for appending to and returning $_[0]
# passed node details by reference (not altered) $_[1]
# passed hash of parsing rules for node attributes, via list $_[2 .. ]
# returns "elements" array with additional elements describing node's arrtibutes
#

sub getAttributes {
  my $elements=shift; # elements array to append to
  my $ref=shift;      # reference to element
  my %req=@_;         # hash of all required/optional XML attributes for this element
  my $ret=1;          

# Search for each required element
  foreach ( keys %req ) { if ( $_ eq "required"   && ! $ref->{Attributes}->{$_} ) { $ret=0; } }

# Handle Attribute Namespace declarations
  my %NameSpaces=%{ $ref->{NameSpaces} };  # inherit namespaces
  foreach ( keys %{ $ref->{Attributes} } ) { if ( /^xmlns()$/ or /^xmlns:([\w-]+)/ ) {$NameSpaces{$1}=$ref->{Attributes}->{$&}; } }
  delete $NameSpaces{""};                  # Attributes default namespace is implicite in element context not inherited

  foreach ( keys %{ $ref->{Attributes} } ) {
    if ( /^(?:([\w-]+):|)(\w+)$/ && ( ! defined $1 || $1 ne "xmlns" ) && $_ ne "xmlns" ) { # seperate out attributes' namespaces and bypass namespace setting attributes (already handled)
      my $name;
      if ( ! $1 ) { $name = "\{$2\} ()"; }
      elsif ( $NameSpaces{$1} ) { $name = "\{$2\} ($NameSpaces{$1})"; }
      else { $name = "\{$2\} (Error Undefined Namespace $1)"; }

      if ( defined $req{$_} && $req{$_} eq "prohibited" )      { push @$elements, " ** Error: Prohibited Attribute $_"; $ret=0; }
      elsif ( defined $req{'*'} && $req{'*'} eq "optional" )   { push @$elements, "$name = $ref->{Attributes}->{$_}"; }
      elsif ( defined $req{$_} && $req{$_} eq "optional" )     { push @$elements, "$name = $ref->{Attributes}->{$_}"; }
      elsif ( defined $req{$_} && $req{$_} eq "required" )     { push @$elements, "$name = $ref->{Attributes}->{$_}"; }
      else                                                     { push @$elements, " ** Error: Unexpected Attribute $_"; $ret=0; }
    }
  }
  return $ret;
}

#####################################
# getNodeAsText
#
# Given a node returns it in a single element of an array as an XML node  i.e. ( 'blah = <node attribute1="..." attribute2="...">[InnerXML]</node>' )
#

sub getNodeAsText {
  my $ref=shift;
  my %ns=();
  my @element = ( "/$ref->{Name} = ".getNodeContentsAsText($ref->{QName}, [ $ref->{Attributes} , @{$ref->{Contents}} ],\%ns) );
  return @element;
}

#####################################
# getNodeContentsAsText
#
# reconstructs (serialises) and returns node given:  name [ {} , () ] as per tree parsed from XML::Parser
#
# *** could perhaps use this to canonicalize node for digest purposes?
#

sub getNodeContentsAsText {
  my $name       = shift; #must
  my $ref        = shift; #must
  my $nsref      = shift; #may
  my %ns         = %{$nsref};
  my @array      = @{$ref};
  my %attributes = (%{ shift @array },%ns);
  my $str        = "<$name";
  if ( %attributes ) { foreach (sort keys %attributes) { $str.=" $_=\"$attributes{$_}\""; } }
  if (@array) {
    $str.=">";
    for(my $i=0;$i<@array;$i+=2) {
      if ($array[$i]) { $str.=getNodeContentsAsText($array[$i],$array[$i+1],$nsref); }
      else { $str.=$array[$i+1]; }
    }
    $str.="</$name>";
  }
  else { $str .= "/>"}
  return $str;
}

__END__


=head1 NAME

VOMS::Lite::SAMLHelper - Perl extension for SAML

=head1 SYNOPSIS

  use VOMS::Lite::SAMLHelper;
  %DATA = %{ VOMS::Lite::SAMLHelper::parseSAML($saml) };
  
=head1 DESCRIPTION

VOMS::Lite::SAMLHelper is designed to parse SAML 1 and 2 assertion and protocol statements for SARoNGS.
The library exposes two functions which may be of use. 

parseSAML

  Expects serialised xml (saml) on in $_[0].
  Called in scalar context returns 1 if successfully parsed 0 otherwise.
  Called in array context returns a copy of the parsed object array.
  If $_[1] is set to an array reference this is used to prime 
  and pass the parsed object array back.

  Creates new XML::Parser
  Uses getNode to abstractly parse root node
  Uses parseElement to parse this abstract root node

  Parsed object is represented as an array of XPath-like data stings
  (one array element per data value i.e. may contain \n).

  e.g.
  /path/to/node (namespace)
  /path/to/node{attribute} (attribute.namespace.if.any) = attributevalue
  ...
  /path/to/node TextContentIfAny
  /path/to/node/subnode (namesapce)
  /path/to/node/subnode{attribute} (attribute.namespace.if.any) = attributevalue
  ...
  /path/to/node/subnode TextContentIfAny
  /path/to/node/subnode/subsubnode...
  /path/to/node2 (namespace)
  ...

  namespaces will be consumed and returned only in parenthase

getSAMLAttributes

  Expects serialised xml (saml) on in $_[0].

  return {
      Attributes=>{ (FriendlyName|Name)=Value, ...},
      ResponseID=>$ResponseID,
      Status=>$StatusCodeValue,
      NotOnOrAfter=>$NotOnOrAfter,
      NotBefore=>$NotBefore,
      Subject=>$NameIdentifier,
      Warnings=> [Anonymous array of warnings]
    };

=head2 EXPORT

None by default;  

=head1 SEE ALSO

http://saml.xml.org/saml-specifications

This module was originally designed for the SARoNGS service
Hosted by the The University of Manchester on behalf of the UK NGS. 

Mailing list, voms-lite@listserv.manchester.ac.uk

=head1 AUTHOR

Mike Jones <mike.jones@manchester.ac.uk>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Mike Jones

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut


