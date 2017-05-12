
package XML::SRS::GetMessages::TypeFilter;
BEGIN {
  $XML::SRS::GetMessages::TypeFilter::VERSION = '0.09';
}

use Moose;
use PRANG::Graph;

use Moose::Util::TypeConstraints;

enum "XML::SRS::GetMessagesTypes" =>
	qw(third-party server-generated-data);

has_attr "Type" =>
	is => "ro",
	isa => "XML::SRS::GetMessagesTypes",
	;

with 'XML::SRS::Node';

1;
