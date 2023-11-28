package WebService::Kramerius::API4::PDF;

use strict;
use warnings;

use base qw(WebService::Kramerius::API4::Base);

our $VERSION = 0.02;

sub parent {
	my ($self, $parent_uuid, $number_of_items) = @_;

	my $opts_hr = {
		'pid' => 'uuid:'.$parent_uuid,
		'number' => $number_of_items,
	};

	return $self->_get_data($self->{'library_url'}.'search/api/v5.0/pdf/parent'.
		$self->_construct_opts($opts_hr));
}

sub selection {
	my ($self, $opts_hr) = @_;

	$self->_validate_opts($opts_hr, ['firstPageType', 'language', 'pids']);

	return $self->_get_data($self->{'library_url'}.'search/api/v5.0/pdf/selection'.
		$self->_construct_opts($opts_hr));
}

1;
