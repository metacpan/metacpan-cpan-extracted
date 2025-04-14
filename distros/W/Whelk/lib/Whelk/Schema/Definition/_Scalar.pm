package Whelk::Schema::Definition::_Scalar;
$Whelk::Schema::Definition::_Scalar::VERSION = '1.04';
use Whelk::StrictBase 'Whelk::Schema::Definition';
use Data::Dumper;

attr '?required' => sub { !$_[0]->has_default };
attr '?default' => sub { Whelk::Schema::NO_DEFAULT };
attr '?example' => undef;

sub has_default
{
	my $default = $_[0]->default;
	return !ref $default || $default != Whelk::Schema::NO_DEFAULT;
}

sub openapi_dump
{
	my ($self, $openapi_obj, %hints) = @_;

	local $Data::Dumper::Sortkeys = 1;

	# incomplete, must be complimented in child classes
	my $res = $self->SUPER::openapi_dump($openapi_obj, %hints);

	if ($self->has_default) {
		$res->{default} = $self->inhale_exhale(
			undef,
			sub {
				die "incorrect default value: " . Dumper({schema => $self, hint => $_[0]});
			}
		);
	}

	if (defined $self->example) {
		$res->{example} = $self->inhale_exhale(
			$self->example,
			sub {
				die "incorrect example: " . Dumper({schema => $self, hint => $_[0]});
			}
		);
	}

	return $res;
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

