package WebService::Kramerius::API4::VC;

use strict;
use warnings;

use base qw(WebService::Kramerius::API4::Base);

our $VERSION = 0.02;

sub pid {
	my ($self, $pid) = @_;

	return $self->_get_data($self->{'library_url'}.'search/api/v5.0/vc/'.$pid);
}

sub vc {
	my ($self, $opts_hr) = @_;

	$self->_validate_opts($opts_hr, ['langCode', 'sort']);

	return $self->_get_data($self->{'library_url'}.'search/api/v5.0/vc'.
		$self->_construct_opts($opts_hr));
}

1;
