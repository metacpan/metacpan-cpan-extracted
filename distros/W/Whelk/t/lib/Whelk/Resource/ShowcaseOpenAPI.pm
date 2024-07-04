package Whelk::Resource::ShowcaseOpenAPI;

use Kelp::Base 'Whelk::Resource';
use Whelk::Schema;

sub api
{
	my ($self) = @_;

	Whelk::Schema->build(
		some_entity_id => {
			type => 'integer',
			description => 'Internal ID',
			example => 1337,
		}
	);

	Whelk::Schema->build(
		some_entity => {
			type => 'object',
			properties => {
				id => \'some_entity_id',
				name => {
					type => 'string',
					description => 'Name of the entity',
					example => "John's entity",
				},
			}
		}
	);

	$self->add_endpoint(
		[GET => '/item/:id'] => sub { },
		description => 'Get item by ID',
		parameters => {
			path => {
				id => \'some_entity_id',
			},
		},
		response => {
			type => 'array',
			items => \'some_entity',
		},
	);
}

1;

