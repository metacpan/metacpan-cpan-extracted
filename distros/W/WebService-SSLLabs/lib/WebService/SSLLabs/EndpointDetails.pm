package WebService::SSLLabs::EndpointDetails;

use strict;
use warnings;
use WebService::SSLLabs::Cert();
use WebService::SSLLabs::Suites();
use WebService::SSLLabs::SimDetails();
use WebService::SSLLabs::Protocol();
use WebService::SSLLabs::Chain();
use WebService::SSLLabs::Key();
use WebService::SSLLabs::DrownHost();

our $VERSION = '0.30';

sub new {
    my ( $class, $json ) = @_;
    my $self = $json;
    bless $self, $class;
    $self->{key}  = WebService::SSLLabs::Key->new( $self->{key} );
    $self->{cert} = WebService::SSLLabs::Cert->new( $self->{cert} );
    my @protocols = @{ $self->{protocols} };
    $self->{protocols} = [];
    foreach my $protocol (@protocols) {
        push @{ $self->{protocols} },
          WebService::SSLLabs::Protocol->new($protocol);
    }
    $self->{suites} = WebService::SSLLabs::Suites->new( $self->{suites} );
    if ( defined $self->{sims} ) {
        $self->{sims} = WebService::SSLLabs::SimDetails->new( $self->{sims} );
    }
    $self->{chain} = WebService::SSLLabs::Chain->new( $self->{chain} );
    my @drown_hosts;
    if ( defined $self->{drownHosts} ) {
        @drown_hosts = @{ $self->{drownHosts} };
    }
    $self->{drownHosts} = [];
    foreach my $drown_host (@drown_hosts) {
        push @{ $self->{drownHosts} },
          WebService::SSLLabs::DrownHost->new($drown_host);
    }
    return $self;
}

sub host_start_time {
    my ($self) = @_;
    return $self->{hostStartTime};
}

sub key {
    my ($self) = @_;
    return $self->{key};
}

sub cert {
    my ($self) = @_;
    return $self->{cert};
}

sub chain {
    my ($self) = @_;
    return $self->{chain};
}

sub protocols {
    my ($self) = @_;
    return @{ $self->{protocols} };
}

sub suites {
    my ($self) = @_;
    return $self->{suites};
}

sub server_signature {
    my ($self) = @_;
    return $self->{serverSignature};
}

sub prefix_delegation {
    my ($self) = @_;
    return $self->{prefixDelegation} ? 1 : 0;
}

sub non_prefix_delegation {
    my ($self) = @_;
    return $self->{nonPrefixDelegation} ? 1 : 0;
}

sub vuln_beast {
    my ($self) = @_;
    return $self->{vulnBeast} ? 1 : 0;
}

sub reneg_support {
    my ($self) = @_;
    return $self->{renegSupport};
}

sub sts_response_header {
    my ($self) = @_;
    return $self->{stsResponseHeader};
}

sub sts_max_age {
    my ($self) = @_;
    return $self->{stsMaxAge};
}

sub sts_subdomains {
    my ($self) = @_;
    return $self->{stsSubdomains} ? 1 : 0;
}

sub pkp_response_header {
    my ($self) = @_;
    return $self->{pkpResponseHeader};
}

sub session_resumption {
    my ($self) = @_;
    return $self->{sessionResumption};
}

sub compression_methods {
    my ($self) = @_;
    return $self->{compressionMethods};
}

sub supports_npn {
    my ($self) = @_;
    return $self->{supportsNpn} ? 1 : 0;
}

sub npn_protocols {
    my ($self) = @_;
    return $self->{npnProtocols};
}

sub session_tickets {
    my ($self) = @_;
    return $self->{sessionTickets};
}

sub ocsp_stapling {
    my ($self) = @_;
    return $self->{ocspStaplings} ? 1 : 0;
}

sub stapling_revocation_status {
    my ($self) = @_;
    return $self->{staplingRevocationStatus};
}

sub stapling_revocation_error_message {
    my ($self) = @_;
    return $self->{staplingRevocationErrorMessage};
}

sub sni_required {
    my ($self) = @_;
    return $self->{sniRequired} ? 1 : 0;
}

sub http_status_code {
    my ($self) = @_;
    return $self->{httpStatusCode};
}

sub supports_rc4 {
    my ($self) = @_;
    return $self->{supportsRc4} ? 1 : 0;
}

sub rc4_only {
    my ($self) = @_;
    return $self->{rc4Only} ? 1 : 0;
}

sub forward_secrecy {
    my ($self) = @_;
    return $self->{forwardSecrecy};
}

sub rc4_with_modern {
    my ($self) = @_;
    return $self->{rc4WithModern} ? 1 : 0;
}

sub sims {
    my ($self) = @_;
    return $self->{sims};
}

sub heartbleed {
    my ($self) = @_;
    return $self->{heartbleed} ? 1 : 0;
}

sub heartbeat {
    my ($self) = @_;
    return $self->{heartbeat} ? 1 : 0;
}

sub open_ssl_ccs {
    my ($self) = @_;
    return $self->{openSslCcs};
}

sub openssl_lucky_minus_20 {
    my ($self) = @_;
    return $self->{openSSLLuckyMinus20};
}

sub poodle {
    my ($self) = @_;
    return $self->{poodle} ? 1 : 0;
}

sub poodle_tls {
    my ($self) = @_;
    return $self->{poodleTls};
}

sub fallback_scsv {
    my ($self) = @_;
    return $self->{fallbackScsv} ? 1 : 0;
}

sub freak {
    my ($self) = @_;
    return $self->{freak} ? 1 : 0;
}

sub has_sct {
    my ($self) = @_;
    return $self->{hasSct};
}

sub dh_primes {
    my ($self) = @_;
    if ( defined $self->{dhPrimes} ) {
        return @{ $self->{dhPrimes} };
    }
    else {
        return ();
    }
}

sub dh_uses_known_primes {
    my ($self) = @_;
    return $self->{dhUsesKnownPrimes};
}

sub dh_ys_reuse {
    my ($self) = @_;
    return $self->{dhYsReuse} ? 1 : 0;
}

sub logjam {
    my ($self) = @_;
    return $self->{logjam} ? 1 : 0;
}

sub chacha20_preference {
    my ($self) = @_;
    return $self->{chaCha20Preference} ? 1 : 0;
}

sub hsts_policy {
    my ($self) = @_;
    return $self->{hstsPolicy};
}

sub hpkp_policy {
    my ($self) = @_;
    return $self->{hpkpPolicy};
}

sub hpkp_ro_policy {
    my ($self) = @_;
    return $self->{hpkpRoPolicy};
}

sub drown_hosts {
    my ($self) = @_;
    if ( defined $self->{drownHosts} ) {
        return @{ $self->{drownHosts} };
    }
    else {
        return ();
    }
}

sub drown_errors {
    my ($self) = @_;
    return $self->{drownErrors} ? 1 : 0;
}

sub drown_vulnerable {
    my ($self) = @_;
    return $self->{drownVulnerable} ? 1 : 0;
}

sub protocol_intolerance {
    my ($self) = @_;
    return $self->{protocolIntolerance};
}

sub misc_intolerance {
    my ($self) = @_;
    return $self->{miscIntolerance};
}

1;
__END__

=head1 NAME

WebService::SSLLabs::EndpointDetails - EndpointDetails object

=head1 VERSION

Version 0.30

=head1 SUBROUTINES/METHODS

=head2 new

a new C<WebService::SSLLabs::EndpointDetails> object, accepts a hash ref as it's parameter.

=head2 host_start_time

endpoint assessment starting time, in milliseconds since 1970. This field is useful when test results are retrieved in several HTTP invocations. Then, you should check that the hostStartTime value matches the startTime value of the host.

=head2 key

returns the connected L<Key|WebService::SSLLabs::Key> object

=head2 cert

returns the connected L<Cert|WebService::SSLLabs::Cert> object

=head2 chain

returns the connected L<Chain|WebService::SSLLabs::Chain> object

=head2 protocols

returns the list of supported protocols as L<Protocol|WebService::SSLLabs::Protocol> objects

=head2 suites

returns the L<Suites|WebService::SSLLabs::Suites> object

=head2 server_signature

Contents of the HTTP Server response header when known. This field could be absent for one of two reasons: 1) the HTTP request failed (check httpStatusCode) or 2) there was no Server response header returned.

=head2 prefix_delegation

true if this endpoint is reachable via a hostname with the www prefix

=head2 non_prefix_delegation

true if this endpoint is reachable via a hostname without the www prefix

=head2 vuln_beast

true if the endpoint is vulnerable to the BEAST attack

=head2 reneg_support

this is an integer value that describes the endpoint support for renegotiation:

=over 2

=item bit 0 (1) - set if insecure client-initiated renegotiation is supported

=item bit 1 (2) - set if secure renegotiation is supported

=item bit 2 (4) - set if secure client-initiated renegotiation is supported

=item bit 3 (8) - set if the server requires secure renegotiation support

=back

=head2 sts_response_header

the contents of the Strict-Transport-Security (STS) response header, if seen

=head2 sts_max_age

the maxAge parameter extracted from the STS parameters;
 
=over 2

=item undef if STS not seen, 

=item -1 if the specified value is invalid (e.g., not a zero or a positive integer; the maximum value currently supported is 2,147,483,647)

=back

=head2 sts_subdomains

true if the includeSubDomains STS parameter is set; undef if STS not seen

=head2 pkp_response_header

the contents of the Public-Key-Pinning response header, if seen

=head2 session_resumption

this is an integer value that describes endpoint support for session resumption. The possible values are:

=over 2

=item 0 - session resumption is not enabled and we're seeing empty session IDs

=item 1 - endpoint returns session IDs, but sessions are not resumed

=item 2 - session resumption is enabled

=back

=head2 compression_methods

integer value that describes supported compression methods

=over 2

=item bit 0 is set for DEFLATE

=back

=head2 supports_npn

true if the server supports NPN

=head2 npn_protocols

space separated list of supported protocols

=head2 session_tickets

indicates support for Session Tickets

=over 2

=item bit 0 (1) - set if session tickets are supported

=item bit 1 (2) - set if the implementation is faulty [not implemented]

=item bit 2 (4) - set if the server is intolerant to the extension

=back

=head2 ocsp_stapling

true if OCSP stapling is deployed on the server

=head2 stapling_revocation_status

same as Cert.revocationStatus, but for the stapled OCSP response.

=head2 stapling_revocation_error_message

description of the problem with the stapled OCSP response, if any.

=head2 sni_required

if SNI support is required to access the web site.

=head2 http_status_code

status code of the final HTTP response seen. When submitting HTTP requests, redirections are followed, but only if they lead to the same hostname. If this field is not available, that means the HTTP request failed.

=head2 http_forwarding

available on a server that responded with a redirection to some other hostname.

=head2 supports_rc4

true if the server supports at least one RC4 suite.

=head2 rc4_only

true if only RC4 suites are supported.

=head2 forward_secrecy

indicates support for Forward Secrecy

=over 2

=item bit 0 (1) - set if at least one browser from our simulations negotiated a Forward Secrecy suite.

=item bit 1 (2) - set based on Simulator results if FS is achieved with modern clients. For example, the server supports ECDHE suites, but not DHE.

=item bit 2 (4) - set if all simulated clients achieve FS. In other words, this requires an ECDHE + DHE combination to be supported.

=back

=head2 rc4_with_modern

true if RC4 is used with modern clients.

=head2 sims

instance of L<SimDetails|WebService::SSLLabs::SimDetails>.

=head2 heartbleed

true if the server is vulnerable to the Heartbleed attack.

=head2 heartbeat

true if the server supports the Heartbeat extension.

=head2 open_ssl_ccs

results of the CVE-2014-0224 test:

=over 2

=item -1 - test failed

=item 0 - unknown

=item 1 - not vulnerable

=item 2 - possibly vulnerable, but not exploitable

=item 3 - vulnerable and exploitable

=back

=head2 openssl_lucky_minus_20

=over 2

=item -1 - test failed

=item 0 - unknown

=item 1 - not vulnerable

=item 2 - vulnerable and insecure

=back

=head2 poodle

true if the endpoint is vulnerable to POODLE; false otherwise

=head2 poodle_tls

results of the POODLE TLS test:

=over 2

=item -3 - timeout

=item -2 - TLS not supported

=item -1 - test failed

=item 0 - unknown

=item 1 - not vulnerable

=item 2 - vulnerable

=back

=head2 fallback_scsv

true if the server supports TLS_FALLBACK_SCSV, false if it doesn't. This field will not be available if the server's support for TLS_FALLBACK_SCSV can't be tested because it supports only one protocol version (e.g., only TLS 1.2).

=head2 freak

true of the server is vulnerable to the FREAK attack, meaning it supports 512-bit key exchange.

=head2 has_sct

information about the availability of certificate transparency information (embedded SCTs):

=over 2

=item bit 0 (1) - SCT in certificate

=item bit 1 (2) - SCT in the stapled OCSP response

=item bit 2 (4) - SCT in the TLS extension (ServerHello)

=back

=head2 dh_primes

list of hex-encoded DH primes used by the server

=head2 dh_uses_known_primes

whether the server uses known DH primes:

=over 2

=item 0 - no

=item 1 - yes, but they're not weak

=item 2 - yes and they're weak

=back

=head2 dh_ys_reuse

true if the DH ephemeral server value is reused.

=head2 logjam

true if the server uses DH parameters weaker than 1024 bits.

=head2 chacha20_preference

true if the server takes into account client preferences when deciding if to use ChaCha20 suites

=head2 hsts_policy

returns server's HSTS policy as a HASH. Experimental.

=head2 hpkp_policy

returns server's HPKP policy as a HASH. Experimental.

=head2 hpkp_ro_policy

returns server's HPKP Report Only policy as a HASH. Experimental.

=head2 drown_hosts

list of L<DrownHost|WebService::SSLLabs::DrownHost> objects. Experimental.

=head2 drown_errors

true if error occurred in drown test.

=head2 drown_vulnerable

true if server vulnerable to drown attack.

=head2 protocol_intolerance

indicates protocol version intolerance issues

=over 2

=item bit 0 (1) - TLS 1.0

=item bit 1 (2) - TLS 1.1

=item bit 2 (4) - TLS 1.2

=item bit 3 (8) - TLS 1.3

=item bit 4 (16) - TLS 1.152

=item bit 5 (32) - TLS 2.152

=back

=head2 misc_intolerance

indicates protocol version intolerance issues

=over 2

=item bit 0 (1) - extension intolerance

=item bit 1 (2) - long handshake intolerance

=item bit 2 (4) - long handshake intolerance workaround success

=back

=head1 DIAGNOSTICS

None

=head1 CONFIGURATION AND ENVIRONMENT

WebService::SSLLabs::EndpointDetails requires no configuration files or environment variables.

=head1 DEPENDENCIES

WebService::SSLLabs::EndpointDetails requires no non-core modules

=head1 INCOMPATIBILITIES

None reported

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-net-ssllabs at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-SSLLabs>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

David Dick, C<< <ddick at cpan.org> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::SSLLabs::EndpointDetails


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-SSLLabs>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-SSLLabs>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-SSLLabs>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-SSLLabs/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to Ivan Ristic and the team at L<https://www.qualys.com> for providing the service at L<https://www.ssllabs.com>

POD was extracted from the API help at L<https://github.com/ssllabs/ssllabs-scan/blob/stable/ssllabs-api-docs.md>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 David Dick.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
