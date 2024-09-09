package Whelk::Schema::Definition::Object;
$Whelk::Schema::Definition::Object::VERSION = '1.00';
use Whelk::StrictBase 'Whelk::Schema::Definition';

attr '?properties' => undef;
attr '?strict' => !!0;

sub openapi_dump
{
	my ($self, $openapi_obj, %hints) = @_;

	if ($hints{parameters}) {
		return $self->_dump_parameters($openapi_obj, %hints);
	}

	my $res = {
		%{$self->_openapi_dump_extra_rules},
		type => 'object',
	};

	my @required;
	my %items;
	my $properties = $self->properties // {};
	foreach my $key (sort keys %{$properties}) {
		$items{$key} = $properties->{$key}->openapi_schema($openapi_obj);
		push @required, $key
			if $properties->{$key}->required;
	}

	if (%items) {
		$res->{properties} = \%items;
		$res->{required} = \@required
			if @required;
	}

	if (defined $self->description) {
		$res->{description} = $self->description;
	}

	return $res;
}

sub _dump_parameters
{
	my ($self, $openapi_obj, %hints) = @_;

	# dump an object schema which was used for parameters. This is not actually
	# a schema but an openapi parameters object
	my @res;
	my $properties = $self->properties;
	foreach my $key (sort keys %{$properties}) {
		my $item = $properties->{$key};
		push @res, {
			name => $key,
			in => $hints{parameters},
			($item->description ? (description => $item->description) : ()),
			required => $self->_bool($item->required),
			schema => $item->openapi_schema($openapi_obj),
		};
	}

	return \@res;
}

sub _resolve
{
	my ($self) = @_;

	my $properties = $self->properties;
	if ($properties) {
		foreach my $key (keys %{$properties}) {
			$properties->{$key} = $self->_build($properties->{$key});
		}
	}
}

sub inhale
{
	my ($self, $value) = @_;

	if (ref $value eq 'HASH') {
		my $properties = $self->properties;
		if ($properties) {
			foreach my $key (keys %$properties) {
				if (!exists $value->{$key}) {
					return "object[$key]->required"
						if $properties->{$key}->required;

					next;
				}

				my $inhaled = $properties->{$key}->inhale($value->{$key});
				return "object[$key]->$inhaled" if defined $inhaled;
			}

			if ($self->strict && keys %$value > keys %$properties) {
				foreach my $key (keys %$value) {
					next if exists $properties->{$key};
					return "object[$key]->redundant";
				}
			}
		}

		return $self->_inhale_extra_rules($value);
	}

	return 'object';
}

sub exhale
{
	my ($self, $value) = @_;

	my $properties = $self->properties;
	return $value unless $properties;

	foreach my $key (keys %$properties) {
		next if !exists $value->{$key} && !$properties->{$key}->has_default;

		$value->{$key} = $properties->{$key}->exhale($value->{$key});
	}

	return $value;
}

1;

