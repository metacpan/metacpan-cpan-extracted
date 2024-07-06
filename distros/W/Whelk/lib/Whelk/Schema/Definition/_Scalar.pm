package Whelk::Schema::Definition::_Scalar;
$Whelk::Schema::Definition::_Scalar::VERSION = '0.04';
use Whelk::StrictBase 'Whelk::Schema::Definition';

attr required => sub { !defined $_[0]->default };
attr default => undef;
attr example => undef;

sub has_default
{
	return defined $_[0]->default;
}

sub _inhale
{
	return 'defined' unless defined pop();
	return undef;
}

sub inhale
{
	my ($self, $value) = @_;

	return $self->_inhale($value // $self->default);
}

sub _exhale
{
	return pop();
}

sub exhale
{
	my ($self, $value) = @_;

	return $self->_exhale($value // $self->default);
}

1;

