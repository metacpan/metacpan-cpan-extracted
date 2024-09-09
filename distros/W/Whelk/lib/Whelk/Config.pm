package Whelk::Config;
$Whelk::Config::VERSION = '1.00';
use Kelp::Base 'Kelp::Module::Config';

attr data => sub {
	my $self = shift;
	return $self->merge(
		$self->SUPER::data,
		{
			modules => [qw(JSON YAML Whelk)],
			modules_init => {
				Routes => {
					base => 'Whelk::Resource',
					rebless => 1,
					fatal => 1,
				},

				JSON => {
					utf8 => 0,    # will not encode wide characters
				},

				YAML => {
					kelp_extensions => 1,
					boolean => 'perl,JSON::PP',
				},
			},

			persistent_controllers => 1,

			encoders => {
				json => {
					openapi => {
						pretty => 1,
						canonical => 1,
					},
				},
			},
		}
	);
};

sub process_mode
{
	my ($self, $mode) = @_;

	return $self->SUPER::process_mode("whelk_$mode");
}

1;

