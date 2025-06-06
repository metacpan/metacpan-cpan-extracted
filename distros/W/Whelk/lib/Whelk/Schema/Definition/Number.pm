package Whelk::Schema::Definition::Number;
$Whelk::Schema::Definition::Number::VERSION = '1.04';
use Whelk::StrictBase 'Whelk::Schema::Definition::_Scalar';
use Scalar::Util qw(looks_like_number);

sub openapi_dump
{
	my ($self, $openapi_obj, %hints) = @_;

	my $res = $self->SUPER::openapi_dump($openapi_obj, %hints);
	$res->{type} = 'number';

	return $res;
}

sub _inhale
{
	my ($self, $value) = @_;

	my $inhaled = $self->SUPER::_inhale($value);
	return $inhaled if defined $inhaled;
	return 'number' unless looks_like_number($value);
	return $self->_inhale_extra_rules($value);
}

sub _exhale
{
	return 0 + pop();
}

1;

