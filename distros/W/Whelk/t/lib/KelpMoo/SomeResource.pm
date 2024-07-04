package KelpMoo::SomeResource;

use Moo;

extends 'KelpMoo::Controller';
with qw(Whelk::Role::Resource);

sub api
{
	my ($self) = @_;

	$self->add_endpoint(
		'/' => sub { return ['moo'] },
		response => {
			type => 'array',
		}
	);
}

1;

