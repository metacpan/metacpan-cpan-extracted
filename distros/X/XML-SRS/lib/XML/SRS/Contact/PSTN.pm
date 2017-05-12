
package XML::SRS::Contact::PSTN;
BEGIN {
  $XML::SRS::Contact::PSTN::VERSION = '0.09';
}

use Moose;
use PRANG::Graph;

has_attr 'cc' =>
	is => "ro",
	isa => "Str",
	xml_name => "CountryCode",
	xml_required => 0,
	;

has_attr 'ndc' =>
	is => "ro",
	isa => "Str",
	xml_name => "AreaCode",
	xml_required => 0,
	;

has_attr 'subscriber' =>
	is => "ro",
	isa => "Str",
	xml_name => "LocalNumber",
	xml_required => 0,
	;

with 'XML::SRS::Node';

use Moose::Util::TypeConstraints;
coerce __PACKAGE__
	=> from "HashRef"
	=> via { __PACKAGE__->new(%$_); };

# a coerce from Str will only handle strings in the format
# defined in the EPP specification ()
coerce __PACKAGE__
	=> from "Str"
	=> via {
	$_ =~ m/^\+(\d{1,3})\.(\d+)$/;
	__PACKAGE__->new(cc=>$1,ndc=>'',subscriber=>$2);
	};

coerce __PACKAGE__
	=> from "Undef"
	=> via { __PACKAGE__->new() };

1;

__END__

=head1 NAME

XML::SRS::Contact::PSTN - Class representing an SRS Phone Number object

=head1 DESCRIPTION

This class represents an SRS Phone number object.

=head1 ATTRIBUTES

Each attribute of this class has an accessor/mutator of the same name as
the attribute. Additionally, they can be passed as parameters to the
constructor.

=head2 subscriber

Must be of type Str. Maps to the XML attribute 'LocalNumber'

=head2 ndc

Must be of type Str. Maps to the XML attribute 'AreaCode'

=head2 cc

Must be of type Str. Maps to the XML attribute 'CountryCode'

=head1 METHODS

=head2 new(%params)

Construct a new XML::SRS::Request object. %params specifies the initial
values of the attributes.

=head1 COMPOSED OF

L<XML::SRS::Node>