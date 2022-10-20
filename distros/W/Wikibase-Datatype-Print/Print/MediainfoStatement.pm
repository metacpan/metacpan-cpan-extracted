package Wikibase::Datatype::Print::MediainfoStatement;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Print::MediainfoSnak;

Readonly::Array our @EXPORT_OK => qw(print);

our $VERSION = 0.01;

sub print {
	my ($obj, $opts_hr) = @_;

	if (! $obj->isa('Wikibase::Datatype::MediainfoStatement')) {
		err "Object isn't 'Wikibase::Datatype::MediainfoStatement'.";
	}

	my @ret = (
		Wikibase::Datatype::Print::MediainfoSnak::print($obj->snak, $opts_hr).' ('.$obj->rank.')',
	);
	foreach my $property_snak (@{$obj->property_snaks}) {
		push @ret, ' '.Wikibase::Datatype::Print::MediainfoSnak::print($property_snak, $opts_hr);
	}

	return wantarray ? @ret : (join "\n", @ret);
}

1;

__END__
