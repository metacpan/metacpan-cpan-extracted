package Wikibase::Datatype::Print::Statement;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Print::Reference;
use Wikibase::Datatype::Print::Snak;
use Wikibase::Datatype::Print::Utils qw(print_references);

Readonly::Array our @EXPORT_OK => qw(print);

our $VERSION = 0.04;

sub print {
	my ($obj, $opts_hr) = @_;

	if (! $obj->isa('Wikibase::Datatype::Statement')) {
		err "Object isn't 'Wikibase::Datatype::Statement'.";
	}

	my @ret = (
		Wikibase::Datatype::Print::Snak::print($obj->snak, $opts_hr).' ('.$obj->rank.')',
	);
	foreach my $property_snak (@{$obj->property_snaks}) {
		push @ret, ' '.Wikibase::Datatype::Print::Snak::print($property_snak, $opts_hr);
	}

	# References.
	push @ret, print_references($obj, $opts_hr,
		\&Wikibase::Datatype::Print::Reference::print);

	return wantarray ? @ret : (join "\n", @ret);
}

1;

__END__
