package t::lib::Test;

use strict;

use vars qw{@ISA @EXPORT};
BEGIN {
	require Exporter;
	@ISA    = qw{ Exporter };
	@EXPORT = qw{ user_owns_cpan };
}

use CPAN::Inject;

sub user_owns_cpan {
	eval {
		CPAN::Inject->from_cpan_config;
	};
	if ( $@ and $@ =~ /The sources directory is not owned by the current user/ ) {
		return '';
	} else {
		return 1;
	}
}

1;
