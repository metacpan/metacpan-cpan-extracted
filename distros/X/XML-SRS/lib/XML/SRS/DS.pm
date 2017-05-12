package XML::SRS::DS;
BEGIN {
  $XML::SRS::DS::VERSION = '0.09';
}

use Moose;
use PRANG::Graph;
use XML::SRS::Types;

has_attr 'key_tag' =>
	is => "ro",
	isa => "Int",
	xml_name => "KeyTag",
	;

has_attr 'algorithm' =>
	is => "ro",
	isa => "Int",
	xml_name => "Algorithm",
	;

has_attr 'digest_type' =>
	is => "ro",
	isa => "Int",
	xml_name => "DigestType",
	;
	
has_element 'digest' =>
	is => "rw",
	isa => "Str",
	xml_nodeName => "Digest",
	;	

with 'XML::SRS::Node';

# Compare against another DS object, and 
#  return true if we decide it's equal
sub is_equal {
	my $self = shift;
	my $other = shift;
	
	confess "Can only compare against another XML::SRS::DS"
		unless blessed $other && $other->isa('XML::SRS::DS');
	
	return 1 if $self->key_tag eq $other->key_tag &&
				$self->algorithm eq $other->algorithm &&
				$self->digest_type eq $other->digest_type &&
				$self->digest eq $other->digest;
				
	return 0;
}

1;
