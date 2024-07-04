package Whelk::Schema::Definition::String;
$Whelk::Schema::Definition::String::VERSION = '0.02';
use Kelp::Base 'Whelk::Schema::Definition::_Scalar';

sub openapi_dump
{
	my ($self, $openapi_obj, %hints) = @_;

	my $res = {
		type => 'string',
	};

	if (defined $self->description) {
		$res->{description} = $self->description;
	}

	if ($self->has_default) {
		$res->{default} = $self->exhale;
	}

	if (defined $self->example) {
		$res->{example} = $self->example;
	}

	return $res;
}

sub _inhale
{
	my ($self, $value) = @_;

	my $inhaled = $self->SUPER::_inhale($value);
	return $inhaled if defined $inhaled;
	return 'string' if ref $value;
	return undef;
}

sub _exhale
{
	return '' . pop();
}

1;

