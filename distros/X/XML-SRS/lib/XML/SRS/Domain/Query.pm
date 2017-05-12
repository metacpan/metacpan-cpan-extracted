
package XML::SRS::Domain::Query;
BEGIN {
  $XML::SRS::Domain::Query::VERSION = '0.09';
}

use Moose;
use PRANG::Graph;
use PRANG::XMLSchema::Types;
use XML::SRS::Types;
use Moose::Util::TypeConstraints;
use PRANG::Coerce;

use XML::SRS::FieldList;
use XML::SRS::Server::Filter::List;
use XML::SRS::Contact::Filter;
use XML::SRS::Date::Range;
use MooseX::Aliases;
use MooseX::Aliases::Meta::Trait::Attribute;


# attributes
has_attr 'status' =>
	is => 'ro',
	isa => 'XML::SRS::RegDomainStatus',
	xml_name => 'Status',
	xml_required => 0,
	;

has_attr 'delegate' =>
	is => 'ro',
	isa => 'XML::SRS::Boolean',
	xml_name => 'Delegate',
	xml_required => 0,
	;

has_attr 'term' =>
	is => 'ro',
	isa => 'XML::SRS::Term',
	xml_name => 'Term',
	xml_required => 0,
	;

has_attr 'registrant_ref' =>
	is => 'ro',
	isa => 'XML::SRS::UID',
	xml_name => 'RegistrantRef',
	xml_required => 0,
	;

has_attr 'max_results' =>
	is => 'rw',
	isa => 'XML::SRS::Number',
	xml_name => 'MaxResults',
	xml_required => 0,
	;

has_attr 'skip_results' =>
	is => 'rw',
	isa => 'XML::SRS::Number',
	xml_name => 'SkipResults',
	xml_required => 0,
	;

has_attr 'count_results' =>
	is => 'ro',
	isa => 'XML::SRS::Boolean',
	xml_name => 'CountResults',
	xml_required => 0,
	;

# elements
has_element 'domain_name_filter' =>
	is => 'ro',
	isa => 'PRANG::Coerce::ArrayRefOfStrs',
	xml_nodeName => 'DomainNameFilter',
	xml_required => 0,
	coerce => 1,
	;

has_element 'name_server_filter' =>
	is => 'ro',
	isa => 'XML::SRS::Server::Filter::List',
	xml_nodeName => 'NameServerFilter',
	xml_required => 0,
	coerce => 1,
	;

has_element 'registrant_contact_filter' =>
	is => 'ro',
	isa => 'XML::SRS::Contact::Filter',
	xml_nodeName => 'RegistrantContactFilter',
	xml_required => 0,
	coerce => 1,
	traits => [qw(Aliased)],	
	alias => 'contact_registrant',
	;

has_element 'admin_contact_filter' =>
	is => 'ro',
	isa => 'XML::SRS::Contact::Filter',
	xml_nodeName => 'AdminContactFilter',
	xml_required => 0,
	coerce => 1,
	traits => [qw(Aliased)],	
	alias => 'contact_admin',
	;

has_element 'technical_contact_filter' =>
	is => 'ro',
	isa => 'XML::SRS::Contact::Filter',
	xml_nodeName => 'TechnicalContactFilter',
	xml_required => 0,
	coerce => 1,
	traits => [qw(Aliased)],	
	alias => 'contact_technical',
	;

has_element 'result_date_range' =>
	is => 'ro',
	isa => 'XML::SRS::Date::Range',
	xml_required => 0,
	xml_nodeName => 'ResultDateRange',
	coerce => 1,
	;

has_element 'search_date_range' =>
	is => 'ro',
	isa => 'XML::SRS::Date::Range',
	xml_required => 0,
	xml_nodeName => 'SearchDateRange',
	coerce => 1,
	;

has_element 'changed_in_date_range' =>
	is => 'ro',
	isa => 'XML::SRS::Date::Range',
	xml_required => 0,
	xml_nodeName => 'ChangedInDateRange',
	coerce => 1,
	;

has_element 'registered_date_range' =>
	is => 'ro',
	isa => 'XML::SRS::Date::Range',
	xml_required => 0,
	xml_nodeName => 'RegisteredDateRange',
	coerce => 1,
	;

has_element 'locked_date_range' =>
	is => 'ro',
	isa => 'XML::SRS::Date::Range',
	xml_required => 0,
	xml_nodeName => 'LockedDateRange',
	coerce => 1,
	;

has_element 'cancelled_date_range' =>
	is => 'ro',
	isa => 'XML::SRS::Date::Range',
	xml_required => 0,
	xml_nodeName => 'CancelledDateRange',
	coerce => 1,
	;

has_element 'billed_until_date_range' =>
	is => 'ro',
	isa => 'XML::SRS::Date::Range',
	xml_required => 0,
	xml_nodeName => 'BilledUntilDateRange',
	coerce => 1,
	;

has_element 'audit_text_filter' =>
	is => 'ro',
	isa => 'Str',
	xml_required => 0,
	xml_nodeName => 'AuditTextFilter'
	;

has_element 'action_id_filter' =>
	is => 'ro',
	isa => 'Str',
	xml_required => 0,
	xml_nodeName => 'ActionIdFilter'
	;

has_element 'field_list' =>
	is => 'ro',
	isa => 'XML::SRS::FieldList',
	xml_required => 0,
	xml_nodeName => 'FieldList',
	coerce => 1,
	;

sub root_element {'DomainDetailsQry'}
with 'XML::SRS::Query';

1;


__END__

=head1 NAME

XML::SRS::Domain::Query - Class representing an SRS DomainDetailsQry transaction

=head1 SYNOPSIS

  my $query = XML::SRS::Domain::Query->new(
      "domain_name_filter" => ["ddq.co.te", "ddq2.co.te"],
      "status" => "Active",
      "delegate" => 1,
      "term" => 1,
      "registrant_ref" => "ref",
      "max_results" => 100,
      "skip_results" => 100,
      "count_results" => 0,
      "name_server_filter" => [
       {
          "fqdn" => "ns1.host.co.nz"
       }
      ],
      "registrant_contact_filter" => {
          "name" => "Name",
          "email" => "email@email.co.nz",
          "postal_address_filter" => {
          	"address1" => "111 My House",
            "address2" => "Burbsville",
            "city" => "Wellington",
            "region" => "Willington",
            "cc" => "NZ",
            "postcode" => "4444"
          },
          "phone" => {
             "cc" => "64",
             "ndc" => "4",
             "subscriber" => "1234567"
          },
          "fax" => {
             "cc" => "64",
             "ndc" => "4",
             "subscriber" => "1234567"
          }
      },
      "admin_contact_filter" => {
          "name" => "Name",
          "email" => "email@email.co.nz",
          "postal_address_filter" => {
          	"address1" => "111 My House",
            "address2" => "Burbsville",
            "city" => "Wellington",
            "region" => "Willington",
            "cc" => "NZ",
            "postcode" => "4444"
          },
          "phone" => {
             "cc" => "64",
             "ndc" => "4",
             "subscriber" => "1234567"
          },
          "fax" => {
             "cc" => "64",
             "ndc" => "4",
             "subscriber" => "1234567"
          }
      },
  	  "search_date_range" => {
  		"begin" => "2000-01-01 00:00:00",
  		"end" => "2020-01-01 00:00:00",
  	  },      
      "audit_text_filter" => "audit text *",
      "action_id_filter" => "ddq setup *",  
  	  "field_list"= > [ 
  		"status", 
  		"name_servers", 
  		"dns_sec", 
  		"registrant_contact",
  		"registered_date",
  		"admin_contact",
  		"technical_contact",
  		"locked_date",
  		"delegate",
  		"registrar_id",
  		"registrar_name",
  		"registrant_ref",
  		"last_action_id",
  		"changed_by_registrar_id",
  		"term",
  		"billed_until",
  		"cancelled_date",
  		"audit_text",
  		"effective_from",
  		"default_contacts"
  	  ],      
  );

=head1 DESCRIPTION

This class represents an SRS DomainDetailsQry request. The root XML element of this
class is 'DomainDetailsQry'.

=head1 ATTRIBUTES

Each attribute of this class has an accessor/mutator of the same name as
the attribute. Additionally, they can be passed as parameters to the
constructor.  

=head2 action_id_filter

Must be of type Str. Maps to the XML element 'ActionIdFilter'

=head2 field_list

Must be of type XML::SRS::FieldList. Maps to the XML element 'FieldList'

=head2 admin_contact_filter

Must be of type XML::SRS::Contact::Filter. Maps to the XML element 'AdminContactFilter'

=head2 status

Must be of type XML::SRS::RegDomainStatus. Maps to the XML attribute 'Status'

=head2 audit_text_filter

Must be of type Str. Maps to the XML element 'AuditTextFilter'

=head2 domain_name_filter

Must be of type PRANG::Coerce::ArrayRefOfStrs. Maps to the XML element 'DomainNameFilter'

=head2 term

Must be of type XML::SRS::Term. Maps to the XML attribute 'Term'

=head2 name_server_filter

Must be of type XML::SRS::Server::Filter::List. Maps to the XML element 'NameServerFilter'

=head2 query_id

Must be of type XML::SRS::UID. Maps to the XML attribute 'QryId'

=head2 changed_in_date_range

Must be of type XML::SRS::Date::Range. Maps to the XML element 'ChangedInDateRange'

=head2 registrant_contact_filter

Must be of type XML::SRS::Contact::Filter. Maps to the XML element 'RegistrantContactFilter'

=head2 billed_until_date_range

Must be of type XML::SRS::Date::Range. Maps to the XML element 'BilledUntilDateRange'

=head2 delegate

Must be of type XML::SRS::Boolean. Maps to the XML attribute 'Delegate'

=head2 locked_date_range

Must be of type XML::SRS::Date::Range. Maps to the XML element 'LockedDateRange'

=head2 registrant_ref

Must be of type XML::SRS::UID. Maps to the XML attribute 'RegistrantRef'

=head2 registered_date_range

Must be of type XML::SRS::Date::Range. Maps to the XML element 'RegisteredDateRange'

=head2 count_results

Must be of type XML::SRS::Boolean. Maps to the XML attribute 'CountResults'

=head2 search_date_range

Must be of type XML::SRS::Date::Range. Maps to the XML element 'SearchDateRange'

=head2 skip_results

Must be of type XML::SRS::Number. Maps to the XML attribute 'SkipResults'

=head2 result_date_range

Must be of type XML::SRS::Date::Range. Maps to the XML element 'ResultDateRange'

=head2 technical_contact_filter

Must be of type XML::SRS::Contact::Filter. Maps to the XML element 'TechnicalContactFilter'

=head2 cancelled_date_range

Must be of type XML::SRS::Date::Range. Maps to the XML element 'CancelledDateRange'

=head2 max_results

Must be of type XML::SRS::Number. Maps to the XML attribute 'MaxResults'

=head1 COMPOSED OF

L<XML::SRS::Query>
