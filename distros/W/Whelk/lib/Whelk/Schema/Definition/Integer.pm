package Whelk::Schema::Definition::Integer;
$Whelk::Schema::Definition::Integer::VERSION = '1.04';
use Whelk::StrictBase 'Whelk::Schema::Definition::Number';

sub openapi_dump
{
	my ($self, $openapi_obj, %hints) = @_;

	my $res = $self->SUPER::openapi_dump($openapi_obj, %hints);
	$res->{type} = 'integer';

	return $res;
}

sub _inhale
{
	my ($self, $value) = @_;

	my $inhaled = $self->SUPER::_inhale($value);
	return $inhaled if defined $inhaled;
	return 'integer' unless $value == int($value);
	return $self->_inhale_extra_rules($value);
}

sub _exhale
{
	return int(pop());
}

1;

