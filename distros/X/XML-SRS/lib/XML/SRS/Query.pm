
package XML::SRS::Query;
BEGIN {
  $XML::SRS::Query::VERSION = '0.09';
}

use Moose::Role;
use PRANG::Graph;
use XML::SRS::Types;
use MooseX::Aliases;
use MooseX::Aliases::Meta::Trait::Attribute;

has_attr 'query_id' =>
	is => "rw",
	isa => "XML::SRS::UID",
	xml_name => 'QryId',
	required => 0,
	traits => [qw(Aliased)],	
	alias => 'unique_id',
	;

with 'XML::SRS::Node', "PRANG::Graph";

1;
