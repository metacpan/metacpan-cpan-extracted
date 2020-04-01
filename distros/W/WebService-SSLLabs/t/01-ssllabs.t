#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN {
    use_ok( 'WebService::SSLLabs' ) || print "Bail out!\n";
}

my $lab = WebService::SSLLabs->new();
SKIP: {
	my $info;
	eval {
		$info = $lab->info();
	} or do {
		chomp $@;
		skip("Failed to info:$@", 6);
	};
	if (defined $info->version()) {
		ok($info->version() =~ /^\d+\.\d+\.\d+/smx, "\$info->version() is a major.minor.patch version number:" . $info->version());
	}
	ok($info->criteria_version() =~ /^2\d{3}\w*?/smx, "\$info->criteria_version() is a date based version number");
	ok($info->max_assessments() =~ /^\d+/smx, "\$info->max_assessments() is a number");
	ok($info->current_assessments() =~ /^\d+/smx, "\$info->current_assessments() is a number");
	ok(($info->messages())[0] =~ /^\w+ \w+/smx, "\$info->messages() is a list of messages");
	ok($info->new_assessment_cool_off() =~ /^\d+/smx, "\$info->new_assessment_cool_off() is a number");
	my $certs;
	eval {
		$certs = $lab->get_root_certs_raw();
	} or do {
		chomp $@;
		skip("Failed to get_root_certs_raw:$@", 1);
	};
	ok($certs =~ /BEGIN[ ]CERTIFICATE/smx, "\$info->get_root_certs_raw() is a scalar containing certificates");
}
my $hostName = 'ssllabs.com';
my $host;
my @endpoints;
SKIP: {
	eval {
		while(not $host = $lab->analyze(host => $hostName)->complete()) {
		   sleep $lab->previous_eta();
		}
		1;
	} or do {
		chomp $@;
		skip("Failed to analyze:$@", 33);
	};
	ok($lab->previous_eta() =~ /^\d+$/, "\$lab->previous_eta() is a number of seconds");
	if ($host->ready()) {
		ok($lab->max_assessments() =~ /^\d+$/, "\$lab->max_assessments() returned a number");
		ok($lab->current_assessments() =~ /^\d+$/, "\$lab->current_assessments() returned a number");
		ok($lab->current_assessments() <= $lab->max_assessments(), "\$lab->current_assessments() is less than or equal to \$lab->max_assessments()");
		foreach my $endpoint ($host->endpoints()) {
			if ($endpoint->ready()) {
				ok(1, "" . $host->host() . ' at ' . $endpoint->ip_address() . ' gets a ' . $endpoint->grade());
			} else {
				ok(1, "" . $host->host() . ' at ' . $endpoint->ip_address() . ' returned an error:' . $endpoint->status_message());
			}  
		}
	} else {
		ok(1, "" . $host->host() . ' returned an error:' . $host->status_message());
	}
	ok($host->host() eq $hostName, "\$host->host() is correct");
	ok($host->port() == 443, "\$host->port() is correct");
	ok($host->start_time() =~ /^\d+/smx, "\$host->start_time() is a number");
	ok($host->criteria_version() =~ /^2\d{3}\w*?/smx, "\$host->criteria_ersion() is a date based version number");
	ok($host->engine_version() =~ /^\d+\.\d+\.\d+/smx, "\$host->engine_version() is a major.minor.patch version");
	ok($host->is_public() =~ /^[01]$/smx, "\$host->is_public() is a 0 or a 1");
	ok($host->status() eq 'READY', "\$host->status() is 'READY'");
	if (defined $host->status_message()) {
		ok($host->status_message() =~ /\w/, "\$host->status_message() is text");
	}
	ok(uc $host->protocol() eq 'HTTP', "\$host->protocol() is 'HTTP'");
	ok($host->test_time() =~ /^\d+/smx, "\$host->test_time() is a number");
	foreach my $endpoint ($host->endpoints()) {
		next unless ($endpoint->ready());
		ok($endpoint->eta() =~ /^-?\d+$/smx, "\$endpoint->eta() is a number");
		ok($endpoint->grade_trust_ignored() =~ /^[ABCDEFMT][+-]?$/smx, "\$endpoint->grade_trust_ignored() is an A+-F or M or a T");
		ok($endpoint->duration() =~ /^\d+$/smx, "\$endpoint->duration() is a number");
		ok($endpoint->status_message() eq 'Ready', "\$endpoint->status_message() is 'Ready'");
		if (defined $endpoint->server_name()) {
			ok($endpoint->server_name() =~ /^[\w\.\-]+$/, "\$endpoint->server_name() looks like a fully qualified hostname");
		} else {
			ok(1, "\$endpoint->server_name() is not defined for '$host'");
		}
		ok($endpoint->delegation() =~ /^\d+$/smx, "\$endpoint->delegation() is a number");
		ok($endpoint->grade() =~ /^[ABCDEFMT][-+]?$/smx, "\$endpoint->grade() is an A+-F or M or a T.  '$host' gets a '" . $endpoint->grade() . "'");
		ok($endpoint->is_exceptional() =~ /^[01]$/smx, "\$endpoint->is_exceptional() is a 0 or a 1");
		ok($endpoint->has_warnings() =~ /^[01]$/smx, "\$endpoint->has_warnings() is a 0 or a 1");
		ok($endpoint->progress() =~ /^-?\d+$/smx, "\$endpoint->progress() is a number");
		push @endpoints, $endpoint;
	}
}
foreach my $endpoint (@endpoints) {
	SKIP: {
		my $endpoint_details;
		eval {
			$endpoint_details = $lab->get_endpoint_data(host => $hostName, 's' => $endpoint->ip_address())->details();
		} or do {
			chomp $@;
			skip("Failed to get_endpoint_data:$@", 480);
		};
		ok(ref $endpoint_details eq 'WebService::SSLLabs::EndpointDetails', "\$lab->get_endpoint_data() returns a WebService::SSLLabs::EndpointDetails object");
		my $suites = $endpoint_details->suites();
		ok(ref $suites eq 'WebService::SSLLabs::Suites', "\$endpoint_details->suites() returns a WebService::SSLLabs::Suites object");
		ok($suites->preference() =~ /^\d+/smx, "\$suites->preference() is a number");
		foreach my $suite ($suites->list()) {
			ok($suite->name() =~ /^[A-Z0-9_]+$/, "\$suite->name() looks like a suite name");
			ok($suite->id() =~ /^\d+$/, "\$suite->id() looks like a number");
			ok($suite->cipher_strength() =~ /^\d+$/, "\$suite->cipher_strength() looks like a number");
			ok((!defined $suite->q() or ((defined $suite->q()) and ($suite->q() == 0))), "\$suite->q() is 0 or undefined");
			if (defined $suite->ecdh_strength()) {
				ok($suite->ecdh_strength() =~ /^\d+$/, "\$suite->ecdh_strength() looks like a number");
				ok($suite->ecdh_bits() =~ /^\d+$/, "\$suite->ecdh_bits() looks like a number");
				ok(!(defined $suite->dh_strength()), "\$suite->dh_strength() is not defined");
				ok(!(defined $suite->dh_p()), "\$suite->dh_p() is not defined");
				ok(!(defined $suite->dh_g()), "\$suite->dh_g() is not defined");
				ok(!(defined $suite->dh_ys()), "\$suite->dh_ys() is not defined");
			} elsif (defined $suite->dh_strength()) {
				ok($suite->dh_strength() =~ /^\d+$/, "\$suite->dh_strength() looks like a number");
				ok($suite->dh_p() =~ /^\d+$/, "\$suite->dh_p() looks like a number");
				ok($suite->dh_g() =~ /^\d+$/, "\$suite->dh_g() looks like a number");
				ok($suite->dh_ys() =~ /^\d+$/, "\$suite->dh_ys() looks like a number");
			}
			last;
		}
		my $sims = $endpoint_details->sims();
		if (defined $sims) {
			ok(ref $sims eq 'WebService::SSLLabs::SimDetails', "\$endpoint_details->sims() returns a WebService::SSLLabs::SimDetails object");
			foreach my $result ($sims->results()) {
				ok(ref $result eq 'WebService::SSLLabs::Simulation', "\$sims->results() returns a list of WebService::SSLLabs::Simulation objects");
				my $client = $result->client();
				ok(ref $client eq 'WebService::SSLLabs::SimClient', "\$result->client() returns a WebService::SSLLabs::SimClient object");
				ok($client->id() =~ /^\d+$/smx, "\$client->id() looks like a number");
				ok($client->name() =~ /^\w+ /smx, "\$client->name() looks like text");
				if (defined $client->platform()) {
					ok($client->platform() =~ /^\w+ /smx, "\$client->platform() looks like text:" . $client->platform());
				}
				ok(($client->version() =~ /\d/smx) || (q[] eq $client->version()), "\$client->version() is a version number of some sort or an empty string");
				ok($client->is_reference() =~ /^[01]$/smx, "\$client->is_reference() is a 0 or is a 1");
				ok($result->error_code() =~ /^[01]$/smx, "\$result->error_code() is a 0 or is a 1");
				ok($result->attempts() =~ /^\d+$/smx, "\$result->attempts() is a number");
				if (defined $result->protocol_id()) {
					ok($result->protocol_id() =~ /^\d+$/smx, "\$result->protocol_id() is a number");
				}
				if (defined $result->suite_id()) {
					ok($result->suite_id() =~ /^\d+$/smx, "\$result->suite_id() is a number");
				}
				if (defined $result->kx_info()) {
					ok($result->kx_info() =~ /^\w+/, "\$result->kx_info() looks like text");
				}
			}
		}
		foreach my $protocol ($endpoint_details->protocols()) {
			ok($protocol->id() =~ /^\d+$/smx, "\$protocol->id() looks like a number");
			ok($protocol->name() =~ /^(?:SSL|TLS)$/smx, "\$protocol->name() is SSL or TLS");
			ok($protocol->version() =~ /^\d+(?:\.\d+)?$/smx, "\$protocol->version() looks like SSL or TLS version number");
			if (defined $protocol->v2_suites_disabled()) {
				ok($protocol->v2_suites_disabled() =~ /^[01]$/smx, "\$protocol->v2_suites_disabled() is a 0 or is a 1");
			} else {
				ok(1, "\$protocol->v2_suites_disabled() is unknown");
			}
			if (defined $protocol->q()) {
				ok($protocol->q() == 0, "\$protocol->q() is a 0");
			} else {
				ok(1, "\$protocol->q() is unknown");
			}
		}
		my $chain = $endpoint_details->chain();
		ok(ref $chain eq 'WebService::SSLLabs::Chain', "\$endpoint_details->chain() returns a WebService::SSLLabs::Chain object");
		if (defined $chain->issues()) {
			ok($chain->issues() =~ /^\d+$/smx, "\$chain->issues() looks like a number");
		}
		foreach my $chain_cert ($chain->certs()) {
			ok(ref $chain_cert eq 'WebService::SSLLabs::ChainCert', "\$chain->certs() returns a list of WebService::SSLLabs::ChainCert objects");
			ok($chain_cert->subject() =~ /^\w+=[*\w]+[ \.]\w+/smx, "\$chain_cert->subject() looks like a distinguished name (DN)");
			ok($chain_cert->label() =~ /^[*\w]+/smx, "\$chain_cert->label() is ok");
			ok($chain_cert->not_before() =~ /^\d+/smx, "\$chain_cert->not_before() is a number");
			ok($chain_cert->not_after() =~ /^\d+/smx, "\$chain_cert->not_after() is a number");
			ok($chain_cert->issuer_subject() =~ /^\w+=\w+ \w+/smx, "\$chain_cert->issuer_subject() looks like a distinguished name (DN)");
			ok($chain_cert->issuer_label() =~ /^\w \w+/smx, "\$chain_cert->issuer_label() looks like text");
			ok($chain_cert->sig_alg() =~ /^\w+$/, "\$chain_cert->sig_alg() looks good");
			ok($chain_cert->issues() =~ /^\d+/smx, "\$chain_cert->issues() is a number");
			ok($chain_cert->key_alg() =~ /^\w+$/, "\$chain_cert->key_alg() looks good");
			ok($chain_cert->key_size() =~ /^\d+$/, "\$chain_cert->key_size() is a number");
			ok($chain_cert->key_strength() =~ /^\d+$/, "\$chain_cert->key_strength() is a number");
			if (defined $chain_cert->revocation_status()) {
				ok($chain_cert->revocation_status() =~ /^\d+/smx, "\$chain_cert->revocation_status() is a number");
			}
			if(defined $chain_cert->crl_revocation_status()) {
				ok($chain_cert->crl_revocation_status() =~ /^\d+/smx, "\$chain_cert->crl_revocation_status() is a number");
			}
			ok($chain_cert->ocsp_revocation_status() =~ /^\d+/smx, "\$chain_cert->ocsp_revocation_status() is a number");
			ok($chain_cert->raw() =~ /^[-][-][-][-][-]BEGIN[ ]CERTIFICATE[-]/smx, "\$chain_cert->raw() is a certificate");
		}
		my $key = $endpoint_details->key();
		ok(ref $key eq 'WebService::SSLLabs::Key', "\$endpoint_details->key() returns a WebService::SSLLabs::Key object");
		ok($key->size() =~ /^\d+$/smx, "\$key->size() is a number");
		ok($key->strength() =~ /^\d+$/smx, "\$key->strength() is a number");
		ok($key->alg() =~ /^(?:RSA|DSA|EC)$/smx, "\$key->alg() is correct");
		ok($key->debian_flaw() =~ /^[01]$/, "\$key->debian_flaw() is a 0 or is a 1");
		if (defined $key->q()) {
			ok($key->q() == 0, "\$key->q() is correct");
		}
		my $cert = $endpoint_details->cert();
		ok(ref $cert eq 'WebService::SSLLabs::Cert', "\$endpoint_details->cert() returns a WebService::SSLLabs::Cert object");
		ok($cert->issuer_subject() =~ /^\w+=\w+ \w+/smx, "\$cert->issuer_subject() looks like a distinguished name (DN)");
		ok($cert->issues() =~ /^\d+/smx, "\$cert->issues() is a number");
		ok((grep { $_ eq $hostName } $cert->alt_names()), "\$cert->alt_names() correctly returns a list, of which one element is '$hostName'");
		ok($cert->ocsp_revocation_status() =~ /^\d+/smx, "\$cert->ocsp_revocation_status() is a number");
		ok(ref (($cert->ocsp_uris())[0]) eq 'URI::http', "\$cert->ocsp_uris() correctly returns a list of URI::http");
		ok($cert->revocation_info() =~ /^\d+/smx, "\$cert->revocation_info() is a number");
		ok($cert->sgc() =~ /^\d+/smx, "\$cert->sgc() is a number");
		if (defined $cert->validation_type()) {
			ok($cert->validation_type() =~ /^\w$/smx, "\$cert->validation_type() is a number:" . $cert->validation_type());
		} else {
			ok(1, "\$cert->validation_type() is not defined for '$hostName'");
		}
		ok($cert->sct() =~ /^[01]$/, "\$cert->sct() is a 0 or a 1");
		ok($cert->must_staple() =~ /^[012]$/, "\$cert->must_staple() is a 0, 1 or 2");
		ok($cert->sig_alg() =~ /^\w+$/, "\$cert->sig_alg() looks good");
		ok((grep { $_ eq $hostName } $cert->common_names()), "\$cert->common_names() correctly returns a list of common_names, of which one element is equal to '$hostName'");
		ok(ref (($cert->crl_uris())[0]) eq 'URI::http', "\$cert->crl_uris() correctly returns a list of URI::http");
		ok($cert->issuer_label() =~ /^\w+ \w+/smx, "\$cert->issuer_label() looks like a description");
		ok($cert->subject() =~ /^\w+=[*\w]*[ \.]\w+/smx, "\$cert->subject() looks like a distinguished name (DN)");
		ok($cert->not_before() =~ /^\d+/smx, "\$cert->not_before() is a number");
		ok($cert->revocation_status() =~ /^\d+/smx, "\$cert->revocation_status() is a number");
		ok($cert->not_after() =~ /^\d+/smx, "\$cert->not_after() is a number");
		ok($cert->crl_revocation_status() =~ /^\d+/smx, "\$cert->crl_revocation_status() is a number");
		ok($endpoint_details->supports_npn() =~ /^[01]$/smx, "\$endpoint_details->supports_npn() is a 0 or is a 1");
		if (defined $endpoint_details->npn_protocols()) {
			ok($endpoint_details->npn_protocols() =~ /\w/smx, "\$endpoint_details->npn_protocols() looks good");
		}
		ok($endpoint_details->poodle_tls() =~ /^(?:-2|-1|0|1|2)$/smx, "\$endpoint_details->poodle_tls() is -2,-1,0,1 or 2");
		if (defined $endpoint_details->ocsp_stapling()) {
			ok($endpoint_details->ocsp_stapling() =~ /^[01]$/smx, "\$endpoint_details->ocsp_stapling() is a 0 or is a 1");
		}
		ok($endpoint_details->poodle() =~ /^[01]$/smx, "\$endpoint_details->poodle() is a 0 or is a 1");
		if (defined $endpoint_details->sts_max_age()) {
			ok($endpoint_details->sts_max_age() =~ /^\d+$/smx, "\$endpoint_details->sts_max_age() is a number");
		}
		ok($endpoint_details->http_status_code() =~ /^[2345]\d{2}$/smx, "\$endpoint_details->http_status_code() is an http status code");
		ok($endpoint_details->supports_rc4() =~ /^[01]$/smx, "\$endpoint_details->supports_rc4() is a 0 or is a 1");
		ok($endpoint_details->compression_methods() =~ /^\d+$/smx, "\$endpoint_details->compression_methods() is a number");
		ok($endpoint_details->prefix_delegation() =~ /^[01]$/smx, "\$endpoint_details->prefix_delegation() is a 0 or is a 1");
		ok($endpoint_details->host_start_time() =~ /^\d+$/smx, "\$endpoint_details->host_start_time() is a number");
		ok($endpoint_details->forward_secrecy() =~ /^\d+$/smx, "\$endpoint_details->forward_secrecy() is a number");
		ok($endpoint_details->sni_required() =~ /^[01]$/smx, "\$endpoint_details->sni_required() is a 0 or is a 1");
		ok($endpoint_details->open_ssl_ccs() =~ /^(?:-1|0|1|2|3)$/smx, "\$endpoint_details->open_ssl_ccs() is -1,0,1,2 or 3");
		ok($endpoint_details->heartbeat() =~ /^[01]$/smx, "\$endpoint_details->heartbeat() is a 0 or is a 1");
		ok($endpoint_details->rc4_with_modern() =~ /^[01]$/smx, "\$endpoint_details->rc4_with_modern() is a 0 or is a 1");
		if (defined $endpoint_details->sts_response_header()) {
			ok($endpoint_details->sts_response_header() =~ /^(max[-]age=\d+|)$/smx, "\$endpoint_details->sts_response_header() looks good:" . $endpoint_details->sts_response_header());
		}
		ok($endpoint_details->sts_subdomains() =~ /^[01]$/smx, "\$endpoint_details->sts_subdomains() is a 0 or is a 1");
		if (defined $endpoint_details->pkp_response_header()) {
			ok($endpoint_details->pkp_response_header() =~ /\w/smx, "\$endpoint_details->pkp_response_header() looks good");
		}
		ok($endpoint_details->vuln_beast() =~ /^[01]$/smx, "\$endpoint_details->vuln_beast() is a 0 or is a 1");
		ok($endpoint_details->fallback_scsv() =~ /^[01]$/smx, "\$endpoint_details->fallback_scsv() is a 0 or is a 1");
		ok($endpoint_details->heartbleed() =~ /^[01]$/smx, "\$endpoint_details->heartbleed() is a 0 or is a 1");
		ok($endpoint_details->freak() =~ /^[01]$/smx, "\$endpoint_details->freak() is a 0 or is a 1");
		if (defined $endpoint_details->dh_primes()) {
			ok(scalar $endpoint_details->dh_primes() >= 0, "\$endpoint_details->dh_primes() is a list of numbers");
		}
		if (defined $endpoint_details->dh_uses_known_primes()) {
			ok($endpoint_details->dh_uses_known_primes() =~ /^(?:0|1|2)$/smx, "\$endpoint_details->dh_uses_known_primes() is a 0, 1 or 2");
		}
		if (defined $endpoint_details->dh_ys_reuse()) {
			ok($endpoint_details->dh_ys_reuse() =~ /^[01]$/smx, "\$endpoint_details->dh_ys_reuse() is a 0 or is a 1");
		}
		if (defined $endpoint_details->stapling_revocation_status()) {
			ok($endpoint_details->stapling_revocation_status() =~ /^\d+/smx, "\$endpoint_details->stapling_revocation_status() is a number");
		}
		if (defined $endpoint_details->stapling_revocation_error_message()) {
			ok($endpoint_details->stapling_revocation_error_message() =~ /\w/smx, "\$endpoint_details->stapling_revocation_error_message() is text");
		}
		if (defined $endpoint_details->logjam()) {
			ok($endpoint_details->logjam() =~ /^[01]$/smx, "\$endpoint_details->logjam() is a 0 or is a 1");
		}
		ok($endpoint_details->chacha20_preference() =~ /^[01]$/smx, "\$endpoint_details->chacha20_preference() is a 0 or is a 1");
		ok($endpoint_details->non_prefix_delegation() =~ /^[01]$/smx, "\$endpoint_details->non_prefix_delegation() is a 0 or is a 1");
		ok(($endpoint_details->session_tickets() =~ /^\d+$/smx) && ($endpoint_details->session_tickets() < 8), "\$endpoint_details->sessionTickets() is a number less than 8");
		ok(($endpoint_details->has_sct() =~ /^\d+$/smx) && ($endpoint_details->has_sct() < 8), "\$endpoint_details->has_sct() is a number less than 8");
		if ($endpoint_details->reneg_support()) {
			ok(($endpoint_details->reneg_support() =~ /^\d+$/smx) && ($endpoint_details->reneg_support() < 16), "\$endpoint_details->reneg_support() is a number less than 16");
		}
		ok($endpoint_details->session_resumption() =~ /^\d+$/smx && ($endpoint_details->session_resumption() < 3), "\$endpoint_details->session_resumption() is a number less than 3");
		if (defined $endpoint_details->server_signature()) {
			ok($endpoint_details->server_signature() =~ /^\w+/smx, "\$endpoint_details->server_signature() looks good");
		}
		ok($endpoint_details->rc4_only() =~ /^[01]$/smx, "\$endpoint_details->rc4_only() is a 0 or is a 1");
		ok(ref $endpoint_details->hsts_policy() eq 'HASH', "\$endpoint_details->hsts_policy() is a HASH - EXPERIMENTAL");
		ok(ref $endpoint_details->hpkp_policy() eq 'HASH', "\$endpoint_details->hpkp_policy() is a HASH - EXPERIMENTAL");
		ok(ref $endpoint_details->hpkp_ro_policy() eq 'HASH', "\$endpoint_details->hpkp_ro_policy() is a HASH - EXPERIMENTAL");
		ok($endpoint_details->openssl_lucky_minus_20() =~ /^(-1|0|1|2)$/smx, "\$endpoint_details->openssl_lucky_minus_20() is -1, 0, 1 or 2");
		ok($endpoint_details->protocol_intolerance() =~ /^\d+$/smx, "\$endpoint_details->protocol_intolerance() is a number");
		ok($endpoint_details->misc_intolerance() =~ /^\d+$/smx, "\$endpoint_details->misc_intolerance() is a number");
	}
}

SKIP: {
	my $statusCodes;
	eval {
		$statusCodes = $lab->get_status_codes();
	} or do {
		chomp $@;
		skip("Failed to get_status_codes:$@", 1);
	};
	my %status_details = $statusCodes->status_details();
	ok($status_details{TESTING_HEARTBLEED} eq 'Testing Heartbleed', "\$statusCodes->status_details() correctly returns the English translation as a HASH");
}

done_testing();
