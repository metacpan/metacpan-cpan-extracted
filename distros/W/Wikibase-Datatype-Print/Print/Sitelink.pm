package Wikibase::Datatype::Print::Sitelink;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Print::Value::Item;
use Wikibase::Datatype::Sitelink;
use Wikibase::Datatype::Value::Item;

Readonly::Array our @EXPORT_OK => qw(print);

our $VERSION = 0.04;

sub print {
	my ($obj, $opts_hr) = @_;

	if (! $obj->isa('Wikibase::Datatype::Sitelink')) {
		err "Object isn't 'Wikibase::Datatype::Sitelink'.";
	}

	my $ret = '';
	if (defined $obj->title) {
		$ret .= $obj->title;
	}
	if (defined $obj->site) {
		$ret .= ' ('.$obj->site.')';
	}
	if (@{$obj->badges}) {
		my @print = map { Wikibase::Datatype::Print::Value::Item::print($_, $opts_hr) } @{$obj->badges};
		$ret .= ' ['.(join ' ', @print).']';
	}

	return $ret;
}

1;

__END__
