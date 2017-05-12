package XML::SRS::Domain::Update;
BEGIN {
  $XML::SRS::Domain::Update::VERSION = '0.09';
}

use Moose;
use PRANG::Graph;
use PRANG::XMLSchema::Types;
use XML::SRS::Types;
use Moose::Util::TypeConstraints;
use PRANG::Coerce;
use XML::SRS::Server::List;
use XML::SRS::DS::List;
use MooseX::Aliases;
use MooseX::Aliases::Meta::Trait::Attribute;


# attributes
has_attr 'udai' =>
	is => 'ro',
	isa => 'XML::SRS::UDAI',
	xml_name => 'UDAI',
	xml_required => 0;

has_attr 'new_udai' =>
	is => 'rw',
	isa => 'XML::SRS::Boolean',
	xml_name => 'NewUDAI',
	xml_required => 0;

has_attr 'registrant_ref' =>
	is => 'ro',
	isa => 'XML::SRS::UID',
	xml_name => 'RegistrantRef',
	xml_required => 0,
	;

has_attr 'term' =>
	is => 'ro',
	isa => 'XML::SRS::Term',
	xml_name => 'Term',
	xml_required => 0,
	;

has_attr 'delegate' =>
	is => 'rw',
	isa => 'XML::SRS::Boolean',
	xml_name => 'Delegate',
	xml_required => 0,
	;

has_attr 'renew' =>
	is => 'ro',
	isa => 'XML::SRS::Boolean',
	xml_name => 'Renew',
	xml_required => 0,
	;

has_attr 'no_auto_renew' =>
	is => 'ro',
	isa => 'XML::SRS::Boolean',
	xml_name => 'NoAutoRenew',
	xml_required => 0,
	;

has_attr 'lock' =>
	is => 'ro',
	isa => 'XML::SRS::Boolean',
	xml_name => 'Lock',
	xml_required => 0,
	;

has_attr 'cancel' =>
	is => 'ro',
	isa => 'XML::SRS::Boolean',
	xml_name => 'Cancel',
	xml_required => 0,
	;

has_attr 'release' =>
	is => 'ro',
	isa => 'XML::SRS::Boolean',
	xml_name => 'Release',
	xml_required => 0,
	;

has_attr 'full_result' =>
	is => 'ro',
	isa => 'XML::SRS::Boolean',
	xml_name => 'FullResult',
	xml_required => 0,
	;

has_attr 'convert_contacts_to_handles' =>
	is => 'ro',
	isa => 'XML::SRS::Boolean',
	xml_name => 'ConvertContactsToHandles',
	xml_required => 0,
	;

# elements
has_element 'domain_name_filter' =>
	is => 'ro',
	isa => 'PRANG::Coerce::ArrayRefOfStrs',
	xml_nodeName => 'DomainNameFilter',
	xml_required => 1,
    coerce => 1,
	traits => [qw(Aliased)],	
	alias => 'filter',
	;

has_element 'contact_registrant' =>
	is => 'ro',
	isa => 'XML::SRS::Contact',
	xml_nodeName => 'RegistrantContact',
	xml_required => 0,
    coerce => 1,
	;

has_element 'contact_admin' =>
	is => 'ro',
	isa => 'XML::SRS::Contact',
	xml_nodeName => 'AdminContact',
	xml_required => 0,
    coerce => 1,
	;

has_element 'contact_technical' =>
	is => 'ro',
	isa => 'XML::SRS::Contact',
	xml_nodeName => 'TechnicalContact',
	xml_required => 0,
    coerce => 1,
	;

has_element 'nameservers' =>
	is => 'ro',
	isa => 'XML::SRS::Server::List',
	xml_nodeName => 'NameServers',
	xml_required => 0,
    coerce => 1,
	;

has_element "dns_sec" =>
	is => "rw",
	isa => "XML::SRS::DS::List",
	xml_nodeName => "DNSSEC",
	xml_required => 0,
	coerce => 1,
	;

with 'XML::SRS::Audit';

sub root_element {'DomainUpdate'}
with 'XML::SRS::Action';

1;

__END__

=head1 NAME

XML::SRS::Domain::Update - Class representing an SRS DomainUpdate transaction

=head1 SYNOPSIS

  my $update = XML::SRS::DomainUpdate->new(
        domain_name_filter => 'foo.co.nz',
        term => 1,
        action_id => "1234",
        contact_registrant => {
            name => "Joe Bloggs",
            email => "blah@foo.co.nz",
            phone => {
                subscriber => "444 4444",
                ndc => 4,
                cc => 64,
            },
            address => {
                address1 => "555 My Street",
                address2 => "Burbsville",
                city => "Lala Land",
                postcode => "12345",
                cc => "NZ",
            },
        },
        nameservers => [
           {
              fqdn => "ns1.foo.net.nz",
              ipv6_addr => "2404:130:0:10::34:0",
              ipv4_addr => "202.78.240.34",
           },
           {
              fqdn => "ns2.foo.net.nz",
              ipv6_addr => "2404:130:2000:1::1",
              ipv4_addr => "202.78.244.33",
           },
       ],
	   dns_sec => [
           {
              algorithm => 5,
              key_tag => 555,
              digest => "3FC2FB591B6089F454B90A529C760E3F92F28399",
              digest_type => 1,
           },
           {
              algorithm => 5,
              key_tag => 444,
              digest => "3A54F693DA1D3FC6073B3D065FEDFAC000610CE83C7D2A084DF883E0B308DCA6",
              digest_type => 2,
           }
        ],        
  );

=head1 DESCRIPTION

This class represents an SRS DomainUpdate request. The root XML element of this
class is 'DomainUpdate'.

=head1 ATTRIBUTES

Each attribute of this class has an accessor/mutator of the same name as
the attribute. Additionally, they can be passed as parameters to the
constructor.

=head2 contact_technical

Must be of type XML::SRS::Contact. Maps to the XML element 'TechnicalContact'

=head2 no_auto_renew

Must be of type XML::SRS::Boolean. Maps to the XML attribute 'NoAutoRenew'

=head2 dns_sec

Must be of type XML::SRS::DS::List. Maps to the XML element 'DNSSEC'

=head2 lock

Must be of type XML::SRS::Boolean. Maps to the XML attribute 'Lock'

=head2 new_udai

Must be of type XML::SRS::Boolean. Maps to the XML attribute 'NewUDAI'

=head2 renew

Must be of type XML::SRS::Boolean. Maps to the XML attribute 'Renew'

=head2 term

Must be of type XML::SRS::Term. Maps to the XML attribute 'Term'

=head2 delegate

Must be of type XML::SRS::Boolean. Maps to the XML attribute 'Delegate'

=head2 registrant_ref

Must be of type XML::SRS::UID. Maps to the XML attribute 'RegistrantRef'

=head2 contact_admin

Must be of type XML::SRS::Contact. Maps to the XML element 'AdminContact'

=head2 contact_registrant

Must be of type XML::SRS::Contact. Maps to the XML element 'RegistrantContact'

=head2 domain_name_filter

Must be of type ArrayRef[Str]. Maps to the XML element 'DomainNameFilter'

=head2 action_id

Required. Must be of type XML::SRS::UID. Maps to the XML attribute 'ActionId'

=head2 nameservers

Must be of type XML::SRS::Server::List. Maps to the XML element 'NameServers'

=head2 release

Must be of type XML::SRS::Boolean. Maps to the XML attribute 'Release'

=head2 full_result

Must be of type XML::SRS::Boolean. Maps to the XML attribute 'FullResult'

=head2 udai

Must be of type XML::SRS::UDAI. Maps to the XML attribute 'UDAI'

=head2 audit

Must be of type Str. Maps to the XML element 'AuditText'

=head2 convert_contacts_to_handles

Must be of type XML::SRS::Boolean. Maps to the XML attribute 'ConvertContactsToHandles'

=head2 cancel

Must be of type XML::SRS::Boolean. Maps to the XML attribute 'Cancel'

=head1 METHODS

=head2 new(%params)

Construct a new XML::SRS::Request object. %params specifies the initial
values of the attributes.

=head1 COMPOSED OF

L<XML::SRS::Action>

