package Whelk::Schema::Definition::Array;
$Whelk::Schema::Definition::Array::VERSION = '1.00';
use Whelk::StrictBase 'Whelk::Schema::Definition';

attr '?items' => undef;
attr '?lax' => !!0;

sub openapi_dump
{
	my ($self, $openapi_obj, %hints) = @_;

	my $res = {
		%{$self->_openapi_dump_extra_rules},
		type => 'array',
		($self->items ? (items => $self->items->openapi_schema($openapi_obj)) : ()),
	};

	if (defined $self->description) {
		$res->{description} = $self->description;
	}

	return $res;
}

sub _resolve
{
	my ($self) = @_;

	$self->items($self->_build($self->items))
		if $self->items;
}

sub inhale
{
	my ($self, $value) = @_;

	if (ref $value eq 'ARRAY') {
		my $type = $self->items;
		if ($type) {
			foreach my $index (keys @$value) {
				my $inhaled = $type->inhale($value->[$index]);
				return "array[$index]->$inhaled" if defined $inhaled;
			}
		}

		return $self->_inhale_extra_rules($value);
	}
	elsif ($self->lax) {
		my $type = $self->items;
		if ($type) {
			my $inhaled = $type->inhale($value);
			return "array[0]->$inhaled" if defined $inhaled;
		}

		return $self->_inhale_extra_rules($value);
	}

	return 'array';
}

sub exhale
{
	my ($self, $value) = @_;

	if (ref $value ne 'ARRAY' && $self->lax) {
		$value = [$value];
	}

	my $type = $self->items;
	return $value unless $type;

	@$value = map { $type->exhale($_) } @$value;
	return $value;
}

1;

