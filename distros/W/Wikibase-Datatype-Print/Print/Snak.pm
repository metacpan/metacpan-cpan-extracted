package Wikibase::Datatype::Print::Snak;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Print::Value;

Readonly::Array our @EXPORT_OK => qw(print);

our $VERSION = 0.01;

sub print {
	my ($obj, $opts_hr) = @_;

	if (! $obj->isa('Wikibase::Datatype::Snak')) {
		err "Object isn't 'Wikibase::Datatype::Snak'.";
	}

	my $property_name = '';
	if (exists $opts_hr->{'cache'}) {
		$property_name = $opts_hr->{'cache'}->get('label', $obj->property);
		if (defined $property_name) {
			$property_name = " ($property_name)";
		} else {
			$property_name = '';
		}
	}

	my $ret = $obj->property.$property_name.': ';
	if ($obj->snaktype eq 'value') {
		$ret .= Wikibase::Datatype::Print::Value::print($obj->datavalue, $opts_hr);
	} elsif ($obj->snaktype eq 'novalue') {
		$ret .= 'no value';
	} elsif ($obj->snaktype eq 'somevalue') {
		$ret .= 'unknown value';
	}
	return $ret;
}

1;

__END__
