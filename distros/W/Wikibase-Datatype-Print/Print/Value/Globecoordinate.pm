package Wikibase::Datatype::Print::Value::Globecoordinate;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;

Readonly::Array our @EXPORT_OK => qw(print);

our $VERSION = 0.01;

sub print {
	my ($obj, $opts_hr) = @_;

	if (! $obj->isa('Wikibase::Datatype::Value::Globecoordinate')) {
		err "Object isn't 'Wikibase::Datatype::Value::Globecoordinate'.";
	}

	my $ret = '('.$obj->latitude.', '.$obj->longitude.')';

	return $ret;
}

1;

__END__
