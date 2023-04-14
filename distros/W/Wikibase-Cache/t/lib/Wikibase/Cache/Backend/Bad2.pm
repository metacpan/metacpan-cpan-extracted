package Wikibase::Cache::Backend::Bad2;

use strict;
use warnings;

sub new {
	my $class = shift;

	return bless {}, $class;
}

sub _get {
	my ($self, $type, $key) = @_;

	if ($type eq 'label') {
		return 'LABEL';
	} elsif ($type eq 'description') {
		return 'DESCRIPTION';
	}
}

1;
