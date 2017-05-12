package WebService::Edgecast::auto::Administration::Type::CustomerOriginInfo;
BEGIN {
  $WebService::Edgecast::auto::Administration::Type::CustomerOriginInfo::VERSION = '0.01.00';
}
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'EC:WebServices' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}

use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %Id_of :ATTR(:get<Id>);
my %MediaTypeId_of :ATTR(:get<MediaTypeId>);
my %DirectoryName_of :ATTR(:get<DirectoryName>);
my %HostHeader_of :ATTR(:get<HostHeader>);
my %UseOriginShield_of :ATTR(:get<UseOriginShield>);
my %HttpFullUrl_of :ATTR(:get<HttpFullUrl>);
my %HttpsFullUrl_of :ATTR(:get<HttpsFullUrl>);
my %HttpLoadBalancing_of :ATTR(:get<HttpLoadBalancing>);
my %HttpsLoadBalancing_of :ATTR(:get<HttpsLoadBalancing>);
my %HttpHostnames_of :ATTR(:get<HttpHostnames>);
my %HttpsHostnames_of :ATTR(:get<HttpsHostnames>);
my %ShieldPOPs_of :ATTR(:get<ShieldPOPs>);

__PACKAGE__->_factory(
    [ qw(        Id
        MediaTypeId
        DirectoryName
        HostHeader
        UseOriginShield
        HttpFullUrl
        HttpsFullUrl
        HttpLoadBalancing
        HttpsLoadBalancing
        HttpHostnames
        HttpsHostnames
        ShieldPOPs

    ) ],
    {
        'Id' => \%Id_of,
        'MediaTypeId' => \%MediaTypeId_of,
        'DirectoryName' => \%DirectoryName_of,
        'HostHeader' => \%HostHeader_of,
        'UseOriginShield' => \%UseOriginShield_of,
        'HttpFullUrl' => \%HttpFullUrl_of,
        'HttpsFullUrl' => \%HttpsFullUrl_of,
        'HttpLoadBalancing' => \%HttpLoadBalancing_of,
        'HttpsLoadBalancing' => \%HttpsLoadBalancing_of,
        'HttpHostnames' => \%HttpHostnames_of,
        'HttpsHostnames' => \%HttpsHostnames_of,
        'ShieldPOPs' => \%ShieldPOPs_of,
    },
    {
        'Id' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
        'MediaTypeId' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
        'DirectoryName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'HostHeader' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'UseOriginShield' => 'SOAP::WSDL::XSD::Typelib::Builtin::boolean',
        'HttpFullUrl' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'HttpsFullUrl' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'HttpLoadBalancing' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'HttpsLoadBalancing' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'HttpHostnames' => 'WebService::Edgecast::auto::Administration::Type::ArrayOfHostname',
        'HttpsHostnames' => 'WebService::Edgecast::auto::Administration::Type::ArrayOfHostname',
        'ShieldPOPs' => 'WebService::Edgecast::auto::Administration::Type::ArrayOfShieldPOP',
    },
    {

        'Id' => 'Id',
        'MediaTypeId' => 'MediaTypeId',
        'DirectoryName' => 'DirectoryName',
        'HostHeader' => 'HostHeader',
        'UseOriginShield' => 'UseOriginShield',
        'HttpFullUrl' => 'HttpFullUrl',
        'HttpsFullUrl' => 'HttpsFullUrl',
        'HttpLoadBalancing' => 'HttpLoadBalancing',
        'HttpsLoadBalancing' => 'HttpsLoadBalancing',
        'HttpHostnames' => 'HttpHostnames',
        'HttpsHostnames' => 'HttpsHostnames',
        'ShieldPOPs' => 'ShieldPOPs',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

WebService::Edgecast::auto::Administration::Type::CustomerOriginInfo

=head1 VERSION

version 0.01.00

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
CustomerOriginInfo from the namespace EC:WebServices.






=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * Id


=item * MediaTypeId


=item * DirectoryName


=item * HostHeader


=item * UseOriginShield


=item * HttpFullUrl


=item * HttpsFullUrl


=item * HttpLoadBalancing


=item * HttpsLoadBalancing


=item * HttpHostnames


=item * HttpsHostnames


=item * ShieldPOPs




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # WebService::Edgecast::auto::Administration::Type::CustomerOriginInfo
   Id =>  $some_value, # int
   MediaTypeId =>  $some_value, # int
   DirectoryName =>  $some_value, # string
   HostHeader =>  $some_value, # string
   UseOriginShield =>  $some_value, # boolean
   HttpFullUrl =>  $some_value, # string
   HttpsFullUrl =>  $some_value, # string
   HttpLoadBalancing =>  $some_value, # string
   HttpsLoadBalancing =>  $some_value, # string
   HttpHostnames =>  { # WebService::Edgecast::auto::Administration::Type::ArrayOfHostname
     Hostname =>  { # WebService::Edgecast::auto::Administration::Type::Hostname
       Name =>  $some_value, # string
       IsPrimary =>  $some_value, # boolean
       Ordinal =>  $some_value, # int
     },
   },
   HttpsHostnames =>  { # WebService::Edgecast::auto::Administration::Type::ArrayOfHostname
     Hostname =>  { # WebService::Edgecast::auto::Administration::Type::Hostname
       Name =>  $some_value, # string
       IsPrimary =>  $some_value, # boolean
       Ordinal =>  $some_value, # int
     },
   },
   ShieldPOPs =>  { # WebService::Edgecast::auto::Administration::Type::ArrayOfShieldPOP
     ShieldPOP =>  { # WebService::Edgecast::auto::Administration::Type::ShieldPOP
       Name =>  $some_value, # string
       POPCode =>  $some_value, # string
       Region =>  $some_value, # string
     },
   },
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut