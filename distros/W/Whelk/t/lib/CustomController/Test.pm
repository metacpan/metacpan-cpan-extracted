package CustomController::Test;

use Kelp::Base 'CustomController';
use Role::Tiny::With;

with qw(Whelk::Role::Resource);

sub api
{
	my ($self) = @_;

	$self->add_endpoint(
		'/test' => 'test_action',
		response => {
			type => 'array',
		}
	);
}

sub test_action
{
	return [qw(three two one)];
}

1;

