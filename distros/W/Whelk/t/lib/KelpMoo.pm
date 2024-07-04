package KelpMoo;

use Moo;

extends 'Kelp';

sub build
{
	my ($self) = @_;

	$self->whelk->finalize;
}

1;

