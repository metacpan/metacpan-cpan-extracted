package Wikibase::Datatype::Print::Value;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Print::Value::Globecoordinate;
use Wikibase::Datatype::Print::Value::Item;
use Wikibase::Datatype::Print::Value::Monolingual;
use Wikibase::Datatype::Print::Value::Property;
use Wikibase::Datatype::Print::Value::Quantity;
use Wikibase::Datatype::Print::Value::String;
use Wikibase::Datatype::Print::Value::Time;

Readonly::Array our @EXPORT_OK => qw(print);

our $VERSION = 0.04;

sub print {
	my ($obj, $opts_hr) = @_;

	if (! $obj->isa('Wikibase::Datatype::Value')) {
		err "Object isn't 'Wikibase::Datatype::Value'.";
	}

	my $type = $obj->type;
	my $ret;
	if ($type eq 'globecoordinate') {
		$ret = Wikibase::Datatype::Print::Value::Globecoordinate::print($obj, $opts_hr);
	} elsif ($type eq 'item') {
		$ret = Wikibase::Datatype::Print::Value::Item::print($obj, $opts_hr);
	} elsif ($type eq 'monolingualtext') {
		$ret = Wikibase::Datatype::Print::Value::Monolingual::print($obj, $opts_hr);
	} elsif ($type eq 'property') {
		$ret = Wikibase::Datatype::Print::Value::Property::print($obj, $opts_hr);
	} elsif ($type eq 'quantity') {
		$ret = Wikibase::Datatype::Print::Value::Quantity::print($obj, $opts_hr);
	} elsif ($type eq 'string') {
		$ret = Wikibase::Datatype::Print::Value::String::print($obj, $opts_hr);
	} elsif ($type eq 'time') {
		$ret = Wikibase::Datatype::Print::Value::Time::print($obj, $opts_hr);
	} else {
		err "Type '$type' is unsupported.";
	}

	return $ret;
}

1;

__END__
