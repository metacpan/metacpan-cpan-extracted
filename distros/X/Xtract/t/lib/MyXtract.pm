package t::lib::MyXtract;

use strict;
use Xtract ();

our $VERSION = '0.16';
our @ISA     = 'Xtract';

sub add {
	my $self = shift;

	# Create a table from an arbitrary SQL query
	$self->add_select(
		'my_table',
		'select * from table_one',
	);

	return 1;
}

1;
