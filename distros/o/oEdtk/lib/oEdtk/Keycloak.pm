package oEdtk::Keycloak;

use strict;
use warnings;

our $VERSION   = 2.1111;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(get_token);

# The Keycloak client is corporate data and now lives in oEUser::Keycloak. This
# generic module is a thin delegate so callers using the old oEdtk::Keycloak name
# keep working. oEUser is an optional companion distribution: it is loaded on
# demand, and a missing one fails cleanly rather than breaking the oEdtk load.
sub _delegate {
	my ( $sub, @args ) = @_;
	my $loaded;
	{
		local $SIG{__DIE__};    # a caught die must not reach oEdtk::Tracking's handler
		$loaded = eval { require oEUser::Keycloak; 1 };
	}
	die "oEdtk::Keycloak requires the companion distribution oEUser "
		. "(oEUser::Keycloak is not installed): $@"
		unless $loaded;
	return oEUser::Keycloak->can($sub)->(@args);
}

sub get_token { return _delegate( 'get_token', @_ ) }

1;

=head1 NAME

oEdtk::Keycloak - delegate to the oEUser Keycloak client

=head1 SYNOPSIS

    use oEdtk::Keycloak qw(get_token);

    my $token = get_token($cfg);    # see oEUser::Keycloak

=head1 DESCRIPTION

The Keycloak client is corporate; it lives in C<oEUser::Keycloak>. This module
keeps the old C<oEdtk::Keycloak> name available to existing callers and forwards
every function to the companion distribution, which is loaded on demand. When
oEUser is not installed, the call fails with a clear message.

=head1 FUNCTIONS

=over 4

=item get_token

Forwards to C<oEUser::Keycloak::get_token> and returns its result.

=back

=head1 AUTHOR

The oEdtk team.

=cut
