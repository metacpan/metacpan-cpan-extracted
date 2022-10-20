package Wikibase::Datatype::Print::Value::Property;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;

Readonly::Array our @EXPORT_OK => qw(print);

our $VERSION = 0.01;

sub print {
	my ($obj, $opts_hr) = @_;

	if (! $obj->isa('Wikibase::Datatype::Value::Property')) {
		err "Object isn't 'Wikibase::Datatype::Value::Property'.";
	}

	if (exists $opts_hr->{'cb'} && ! $opts_hr->{'cb'}->isa('Wikibase::Cache::Backend')) {
		err "Option 'cb' must be a instance of Wikibase::Cache::Backend.";
	}

	my $property;
	if (exists $opts_hr->{'cb'}) {
		$property = $opts_hr->{'cb'}->get('label', $obj->value) || $obj->value;
	} else {
		$property = $obj->value;
	}

	return $property;
}

1;

__END__
