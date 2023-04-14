package Wikibase::Cache::Backend::Foo;

use base qw(Wikibase::Cache::Backend);
use strict;
use warnings;

sub _get {
	my ($self, $type, $key) = @_;

	if ($type eq 'label') {
		return 'LABEL';
	} elsif ($type eq 'description') {
		return 'DESCRIPTION';
	}
}

1;
