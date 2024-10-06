package Whelk::Schema::Definition::_Scalar;
$Whelk::Schema::Definition::_Scalar::VERSION = '1.01';
use Whelk::StrictBase 'Whelk::Schema::Definition';

attr '?required' => sub { !$_[0]->has_default };
attr '?default' => sub { Whelk::Schema::NO_DEFAULT };
attr '?example' => undef;

sub has_default
{
	my $default = $_[0]->default;
	return !ref $default || $default != Whelk::Schema::NO_DEFAULT;
}

sub _inhale
{
	return 'defined' unless defined pop();
	return undef;
}

sub inhale
{
	my ($self, $value) = @_;
	if (!defined $value && $self->has_default) {
		$value = $self->default;
	}

	return undef if $self->_valid_nullable($value);

	return $self->_inhale($value);
}

sub _exhale
{
	return pop();
}

sub exhale
{
	my ($self, $value) = @_;
	if (!defined $value && $self->has_default) {
		$value = $self->default;
	}

	return undef if $self->_valid_nullable($value);

	return $self->_exhale($value);
}

1;

