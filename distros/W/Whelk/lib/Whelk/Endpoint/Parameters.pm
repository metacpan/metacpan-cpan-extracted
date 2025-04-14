package Whelk::Endpoint::Parameters;
$Whelk::Endpoint::Parameters::VERSION = '1.04';
use Whelk::StrictBase;

use Carp;
use Whelk::Schema;

our @CARP_NOT = qw(Kelp::Base Whelk::Endpoint);

attr '?-path' => sub { {} };
attr '?-query' => sub { {} };
attr '?-header' => sub { {} };
attr '?-cookie' => sub { {} };

attr -path_schema => sub { $_[0]->build_schema($_[0]->path, required => 1) };
attr -query_schema => sub { $_[0]->build_schema($_[0]->query, array => 1) };
attr -header_schema => sub { $_[0]->build_schema($_[0]->header, array => 1) };
attr -cookie_schema => sub { $_[0]->build_schema($_[0]->cookie) };

sub build_schema
{
	my ($self, $hashref, %hints) = @_;
	return undef if !%$hashref;

	my $built = Whelk::Schema->build(
		{
			type => 'object',
			properties => $hashref,
		}
	);

	foreach my $key (keys %{$built->properties}) {
		my $item = $built->properties->{$key};
		my $is_scalar = $item->isa('Whelk::Schema::Definition::_Scalar');
		my $is_array = $item->isa('Whelk::Schema::Definition::Array');

		if ($is_array) {
			croak 'Whelk only supports array types in header and query parameters'
				unless $hints{array};
		}
		elsif (!$is_scalar) {
			croak 'Whelk only supports string, integer, number, boolean and array types in parameters';
		}

		croak 'Whelk path parameters must be required'
			if $hints{required} && !$item->required;
	}

	return $built;
}

1;

