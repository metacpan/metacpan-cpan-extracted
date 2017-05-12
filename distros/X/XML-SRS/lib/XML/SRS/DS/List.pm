package XML::SRS::DS::List;
BEGIN {
  $XML::SRS::DS::List::VERSION = '0.09';
}

use Moose;
use PRANG::Graph;
use XML::SRS::DS;

use Moose::Util::TypeConstraints;

use XML::SRS::Server;
has_element 'ds_list' =>
	is => "rw",
	isa => "ArrayRef[XML::SRS::DS]",
	xml_nodeName => "DS",
	xml_required => 0,
	;

coerce __PACKAGE__
	=> from 'ArrayRef[XML::SRS::DS]'
	=> via {
		__PACKAGE__->new(
			ds_list => $_,
		);
	};

coerce __PACKAGE__
	=> from 'ArrayRef[HashRef]'
	=> via {
	__PACKAGE__->new(
		ds_list => [
			map {
				XML::SRS::DS->new($_);
			} @$_
		],
	);
};

with 'XML::SRS::Node';

1;
