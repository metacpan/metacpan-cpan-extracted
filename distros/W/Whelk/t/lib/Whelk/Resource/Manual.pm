package Whelk::Resource::Manual;

use Kelp::Base 'Whelk::Resource';
use Whelk::Schema;

sub ex_synopsis
{
	my ($self) = @_;

	Whelk::Schema->build(
		language => {
			type => 'object',
			properties => {
				language => {
					type => 'string',
				},
				pangram => {
					type => 'string',
				},
			},
		}
	);

	$self->add_endpoint(
		[GET => '/pangrams'] => 'action_list',
		description => 'Returns a list of language names with a pangram in each language',
		response => {
			type => 'array',
			description => 'List of languages',
			items => \'language',
		}
	);
}

sub ex_params
{
	my ($self) = @_;

	Whelk::Schema->build(
		my_num => {
			type => 'number',
		}
	);

	# extend my_num schema to add default
	Whelk::Schema->build(
		my_num_optional => [
			\'my_num',
			default => 1,
		]
	);

	$self->add_endpoint(
		'/multiply/:number' => {
			name => 'multiply',
			method => 'POST',
			to => sub {
				my ($self, $number) = @_;

				$number = $number
					* ($self->req->header('X-Number') // 1)
					* ($self->req->cookies->{number} // 1)
					* $self->req->query_param('number')
					* $self->request_body->{number};

				return {number => $number};
			},
		},
		parameters => {
			path => {
				number => \'my_num',
			},
			header => {
				'X-Number' => \'my_num_optional',
			},
			cookie => {
				number => \'my_num_optional',
			},
			query => {
				number => \'my_num_optional'
			},
		},
		request => {
			type => 'object',
			properties => {
				number => \'my_num_optional',
			}
		},
		response => {
			type => 'object',
			properties => {
				number => \'my_num'
			}
		}
	);
}

sub api
{
	my ($self) = @_;

	# SYNOPSIS
	$self->ex_synopsis;

	# PARAMS EXAMPLE
	$self->ex_params;
}

sub action_list
{
	return [
		{
			language => 'English',
			pangram => 'a quick brown fox jumped over a lazy dog',
		},
		{
			language => 'Francais',
			pangram => 'voix ambiguë d’un cœur qui au zéphyr préfère les jattes de kiwis',
		},
		{
			language => 'Polski',
			pangram => 'mężny bądź, chroń pułk twój i sześć flag',
		},
	];
}

1;

