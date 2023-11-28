package WebService::Kramerius::API4::Search;

use strict;
use warnings;

use base qw(WebService::Kramerius::API4::Base);

our $VERSION = 0.02;

# Example: https://kramerius.mzk.cz/search/api/v5.0/search?q=(fedora.model:monograph%20OR%20fedora.model:periodical%20OR%20fedora.model:soundrecording%20OR%20fedora.model:map%20OR%20fedora.model:graphic%20OR%20fedora.model:sheetmusic%20OR%20fedora.model:archive%20OR%20fedora.model:manuscript)&facet=true&facet.field=fedora.model&facet.mincount=1&facet.sort=count&facet.limit=100&facet.offset=0&rows=0&json.facet=%7Bx:%22unique(fedora.model)%22%7D
sub search {
	my ($self, $opts_hr) = @_;

	$self->_validate_opts($opts_hr, ['q']);

	return $self->_get_data($self->{'library_url'}.'search/api/v5.0/pdf/search'.
		$self->_construct_opts($opts_hr));
}

1;
