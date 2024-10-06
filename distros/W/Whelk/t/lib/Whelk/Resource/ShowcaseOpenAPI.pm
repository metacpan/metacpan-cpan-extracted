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
			rules => [
				{
					openapi => {
						minimum => 1,
					},
					hint => '(>=1)',
					code => sub { shift() >= 1 },
				},
			],
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
				value => {
					type => 'integer',
					nullable => !!1,
					default => undef,
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

