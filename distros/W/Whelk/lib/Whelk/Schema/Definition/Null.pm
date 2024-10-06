package Whelk::Schema::Definition::Null;
$Whelk::Schema::Definition::Null::VERSION = '1.01';
use Whelk::StrictBase 'Whelk::Schema::Definition';

sub openapi_dump
{
	my ($self, $openapi_obj, %hints) = @_;

	my $res = {
		type => 'null',
	};

	if (defined $self->description) {
		$res->{description} = $self->description;
	}

	return $res;
}

sub inhale
{
	return 'null' unless !defined pop();
	return undef;
}

sub exhale
{
	return undef;
}

1;

