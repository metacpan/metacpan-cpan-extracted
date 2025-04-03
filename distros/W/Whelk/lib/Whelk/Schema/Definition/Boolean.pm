package Whelk::Schema::Definition::Boolean;
$Whelk::Schema::Definition::Boolean::VERSION = '1.03';
use Whelk::StrictBase 'Whelk::Schema::Definition::_Scalar';
use JSON::PP;
use List::Util qw(none);

sub openapi_dump
{
	my ($self, $openapi_obj, %hints) = @_;

	my $res = {
		type => 'boolean',
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

	if (ref $value) {
		$inhaled = 'boolean'
			if none { $value == $_ } (JSON::PP::true, JSON::PP::false);
	}
	else {
		$inhaled = 'boolean'
			if none { $value eq $_ } (1, 0, !!1, !!0);
	}

	return $inhaled;
}

sub _exhale
{
	return pop() ? JSON::PP::true : JSON::PP::false;
}

1;

