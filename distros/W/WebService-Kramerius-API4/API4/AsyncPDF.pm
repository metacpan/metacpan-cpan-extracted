package WebService::Kramerius::API4::AsyncPDF;

use strict;
use warnings;

use base qw(WebService::Kramerius::API4::Base);

our $VERSION = 0.02;

sub handle {
	my ($self, $opts_hr) = @_;

	$self->_validate_opts($opts_hr, ['handle']);

	return $self->_get_data($self->{'library_url'}.'search/api/v5.0/asyncpdf/handle'.
		$self->_construct_opts($opts_hr));
}

sub parent {
	my ($self, $opts_hr) = @_;

	$self->_validate_opts($opts_hr, ['number', 'pid']);

	return $self->_get_data($self->{'library_url'}.'search/api/v5.0/asyncpdf/parent'.
		$self->_construct_opts($opts_hr));
}
1;
