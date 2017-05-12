package oEdtk::C7Doc;

use strict;
use warnings;

our $VERSION = '0.04';

use base 'oEdtk::Doc';

use oEdtk::C7Tag;

sub append_table {
	# appending table by element
	# each element name based on the table name with elem number 
	# exemple $name = ADDRESS => ADDRES00 to ADDRES99
	my ($self, $name, @tValues) = @_;

	for (my $i = 0; $i <= $#tValues; $i++) {
		my $elem = sprintf("%.6s%0.2d", $name, $i);
		$self->append($elem, $tValues[$i]);
	}
}

sub mktag {
	my ($self, $name, $value) = @_;

	return oEdtk::C7Tag->new($name, $value);
}

sub line_break {
	return "\n";
}

1;
