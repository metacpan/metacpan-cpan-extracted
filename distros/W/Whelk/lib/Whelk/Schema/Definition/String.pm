package Whelk::Schema::Definition::String;
$Whelk::Schema::Definition::String::VERSION = '1.04';
use Whelk::StrictBase 'Whelk::Schema::Definition::_Scalar';

sub openapi_dump
{
	my ($self, $openapi_obj, %hints) = @_;

	my $res = $self->SUPER::openapi_dump($openapi_obj, %hints);
	$res->{type} = 'string';

	return $res;
}

sub _inhale
{
	my ($self, $value) = @_;

	my $inhaled = $self->SUPER::_inhale($value);
	return $inhaled if defined $inhaled;
	return 'string' if ref $value;
	return $self->_inhale_extra_rules($value);
}

sub _exhale
{
	return '' . pop();
}

1;

