package KelpCustom;

use Kelp::Base 'Kelp';

attr context_obj => 'CustomContext';

sub build
{
	my ($self) = @_;

	$self->whelk->finalize;
}

1;

