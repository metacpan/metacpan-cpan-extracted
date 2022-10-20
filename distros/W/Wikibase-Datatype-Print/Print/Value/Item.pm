package Wikibase::Datatype::Print::Value::Item;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;

Readonly::Array our @EXPORT_OK => qw(print);

our $VERSION = 0.01;

sub print {
	my ($obj, $opts_hr) = @_;

	if (! $obj->isa('Wikibase::Datatype::Value::Item')) {
		err "Object isn't 'Wikibase::Datatype::Value::Item'.";
	}

	if (exists $opts_hr->{'cb'} && ! $opts_hr->{'cb'}->isa('Wikibase::Cache::Backend')) {
		err "Option 'cb' must be a instance of Wikibase::Cache::Backend.";
	}

	my $item;
	if (exists $opts_hr->{'cb'}) {
		$item = $opts_hr->{'cb'}->get('label', $obj->value) || $obj->value;
	} else {
		$item = $obj->value;
	}

	return $item;
}

1;

__END__
