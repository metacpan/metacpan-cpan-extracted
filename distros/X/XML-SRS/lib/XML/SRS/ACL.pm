
package XML::SRS::ACL;
BEGIN {
  $XML::SRS::ACL::VERSION = '0.09';
}

use Moose;
use PRANG::Graph;
use XML::SRS::Types;

has_attr 'Resource' =>
	is => "ro",
	isa => "Str",
	required => 1,
	;

has_attr 'List' =>
	is => "ro",
	isa => "Str",
	required => 1,
	;

has_attr 'Size' =>
	is => "ro",
	isa => "XML::SRS::Number",
	xml_required => 0,
	;

has_attr 'SizeChange' =>
	is => "ro",
	isa => "XML::SRS::Number",
	xml_required => 0,
	;

sub BUILD {
	my $self = shift;
	defined($self->Size//$self->SizeChange)
		or die "Must specify either Size or SizeChange";
}

has_attr 'Type' =>
	is => "ro",
	isa => "Str",
	xml_required => 0,
	;

use XML::SRS::ACL::Entry;
has_element 'entries' =>
	is => "ro",
	isa => "ArrayRef[XML::SRS::ACL::Entry]",
	xml_nodeName => "AccessControlListEntry",
	xml_required => 0,
	;

sub root_element {
	"AccessControlList";
}

with 'XML::SRS::ActionResponse';

1;
