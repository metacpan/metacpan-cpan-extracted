package Whelk::Schema::Definition::String;
$Whelk::Schema::Definition::String::VERSION = '1.00';
use Whelk::StrictBase 'Whelk::Schema::Definition::_Scalar';

sub openapi_dump
{
	my ($self, $openapi_obj, %hints) = @_;

	my $res = {
		%{$self->_openapi_dump_extra_rules},
		type => 'string',
	};

	if (defined $self->description) {
		$res->{description} = $self->description;
	}

	if ($self->has_default) {
		$res->{default} = $self->inhale_exhale;
	}

	if (defined $self->example) {
		$res->{example} = $self->inhale_exhale($self->example);
	}

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

