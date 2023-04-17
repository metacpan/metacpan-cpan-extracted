package Wikibase::Datatype::Print::Reference;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Print::Snak;

Readonly::Array our @EXPORT_OK => qw(print);

our $VERSION = 0.07;

sub print {
	my ($obj, $opts_hr) = @_;

	if (! $obj->isa('Wikibase::Datatype::Reference')) {
		err "Object isn't 'Wikibase::Datatype::Reference'.";
	}

	my @ret = '{';
	foreach my $snak (@{$obj->snaks}) {
		push @ret, map { '  '.$_ } Wikibase::Datatype::Print::Snak::print($snak, $opts_hr);
	}
	push @ret, '}';

	return wantarray ? @ret : (join "\n", @ret);
}

1;

__END__
