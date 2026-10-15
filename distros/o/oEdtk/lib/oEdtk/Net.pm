package oEdtk::Net;

# Shared HTTP transport settings for the clients that talk to corporate HTTP
# services: the ECM injector here, and the oEUser-side Keycloak / Emailing /
# DisseminationPlan clients. The fork hard-coded the transport security of every
# one of them (host-name verification off, a corporate CA pinned); here that is
# centralised and made safe by default.
#
# Keys read from the configuration hash:
#   EDTK_SSL_VERIFY   0 (or no/false/off) disables peer and host-name
#                     verification; anything else, and the default when unset,
#                     keeps them ON.
#   EDTK_SSL_CA_PATH  CA bundle: a file (SSL_ca_file) or a directory
#                     (SSL_ca_path). Empty or unset: the system trust store.

use strict;
use warnings;

use feature 'signatures';
no warnings 'experimental::signatures';

use Exporter 'import';
our @EXPORT_OK = qw( ua_ssl_opts make_ua );

use IO::Socket::SSL qw( SSL_VERIFY_PEER SSL_VERIFY_NONE );
use LWP::UserAgent;

our $VERSION = 2.1111;

use constant DEFAULT_VERIFY => 1;

# A missing or empty value keeps the default; only an explicit false-looking
# value disables verification.
sub _verify_enabled ($value) {
	return DEFAULT_VERIFY unless defined $value && length $value;
	return 0 if $value =~ /^(?:0|no|false|off)$/i;
	return 1;
}

# LWP / IO::Socket::SSL options derived from the configuration. Verification is
# on by default; the CA location is passed through when configured.
sub ua_ssl_opts ($cfg) {
	my $verify = _verify_enabled( $cfg->{'EDTK_SSL_VERIFY'} );
	my %ssl    = (
		verify_hostname => $verify,
		SSL_verify_mode => $verify ? SSL_VERIFY_PEER : SSL_VERIFY_NONE,
	);
	my $ca = $cfg->{'EDTK_SSL_CA_PATH'};
	if ( defined $ca && length $ca ) {
		if   ( -d $ca ) { $ssl{SSL_ca_path} = $ca }
		else            { $ssl{SSL_ca_file} = $ca }
	}
	return \%ssl;
}

# A UserAgent using the options above, with an optional timeout (seconds).
sub make_ua ( $cfg, $timeout = undef ) {
	my $ua = LWP::UserAgent->new( ssl_opts => ua_ssl_opts( $cfg // {} ) );
	$ua->timeout($timeout) if defined $timeout;
	return $ua;
}

1;

=head1 NAME

oEdtk::Net - shared HTTP transport settings for the service clients

=head1 SYNOPSIS

    use oEdtk::Net qw(make_ua);

    my $ua = make_ua( $cfg );          # TLS verification on, system trust store
    my $ua = make_ua( $cfg, 500 );     # ... with a 500 s timeout

=head1 DESCRIPTION

The service clients share one transport policy. The fork disabled host-name
verification and pinned a corporate CA directory in every client; here that is
centralised and made safe by default: peer and host-name verification are ON
unless C<EDTK_SSL_VERIFY> asks otherwise, and the CA bundle is taken from
C<EDTK_SSL_CA_PATH> when set (a file becomes C<SSL_ca_file>, a directory becomes
C<SSL_ca_path>). With an empty C<EDTK_SSL_CA_PATH> the system trust store is used.

The oEUser-side clients reach this module through their local name
L<oEUser::Net>, a thin delegate.

=head1 FUNCTIONS

=over 4

=item ua_ssl_opts( $cfg )

Return the C<ssl_opts> hashref for LWP::UserAgent derived from the
configuration.

=item make_ua( $cfg, $timeout )

Return an LWP::UserAgent using those options. C<$timeout> is optional.

=back

=head1 AUTHOR

The oEdtk team.

=cut
