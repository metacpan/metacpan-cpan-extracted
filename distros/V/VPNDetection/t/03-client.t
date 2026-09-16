use strict;
use warnings;

use lib 't/lib';

use Mojo::IOLoop;
use Mojo::JSON ();
use Test::More;
use Time::HiRes ();
use VPNDetection;
use VPNDetectionTest::Origin;

# The Perl-specific surface, as distinct from the shared corpus in
# t/02-conformance.t.

subtest 'a batch honors the per-call concurrency, measured as peak in flight' => sub {
    # Peak in flight is the only measurement that separates a real ceiling from
    # an option that was accepted and ignored: counting total requests passes
    # either way.
    my $origin = VPNDetectionTest::Origin->new(sub {
        my ($c) = @_;
        VPNDetectionTest::Origin::slow_json($c, VPNDetectionTest::Origin::batch_body($c), 0.05);
    });
    # Enough addresses for nine chunks of the batch endpoint's 1000, so a
    # concurrency of six has something to bound: one request per chunk, and only
    # the chunks overlap.
    my @addresses = map { sprintf '9.%d.%d.%d', 1 + int($_ / 65536), int($_ / 256) % 256, $_ % 256 } 0 .. 8000;

    my $client = VPNDetection->new(base_url => $origin->url, cache_size => 0, concurrency => 2);
    $client->lookup_batch(\@addresses, concurrency => 6);
    is($origin->count, 9, 'one request per chunk of 1000');
    is($origin->peak_in_flight, 6, 'the per-call ceiling was reached and not exceeded');

    $origin->reset;
    $client->lookup_batch(\@addresses);
    is($origin->peak_in_flight, 2, 'without an override the client default applies exactly');

    $origin->reset;
    $client->lookup_batch(\@addresses, concurrency => 1);
    is($origin->peak_in_flight, 1, 'concurrency 1 is genuinely serial');
};

subtest 'retries are configurable per call' => sub {
    my $origin = VPNDetectionTest::Origin->new(sub {
        shift->render(json => { error => 'lookup failed' }, status => 500);
    });
    my $client = VPNDetection->new(base_url => $origin->url, cache_size => 0, retries => 0);

    eval { $client->lookup('9.9.9.9', retries => 2) };
    isa_ok($@, 'VPNDetection::Error', 'still failed');
    is($origin->count, 3, 'one attempt plus two retries, not the client default of none');

    $origin->reset;
    eval { $client->lookup('9.9.9.9') };
    is($origin->count, 1, 'the client default still applies without an override');
};

subtest 'a 429 is retried only when it carries Retry-After' => sub {
    my $attempts = 0;
    my $origin = VPNDetectionTest::Origin->new(sub {
        my ($c) = @_;
        my $retryable = $c->req->url->path->to_string eq '/9.9.9.1';
        if (++$attempts == 1) {
            $c->res->headers->header('Retry-After' => 0) if $retryable;
            return $c->render(json => { error => 'too many' }, status => 429);
        }
        $c->render(json => { ip => '9.9.9.1', is_vpn => \0 });
    });
    my $client = VPNDetection->new(base_url => $origin->url, cache_size => 0, retries => 2);

    my $result = $client->lookup('9.9.9.1');
    is($result->is_vpn, 0, 'a rate limit was waited out');
    is($origin->count, 2, 'exactly one retry');

    $attempts = 0;
    $origin->reset;
    my $spent = eval { $client->lookup('9.9.9.2') };
    ok(!defined $spent, 'a spent quota fails');
    is($@->kind, 'quota_exceeded', 'and is classified as such');
    is($origin->count, 1, 'a 429 without Retry-After is never retried');
};

subtest 'a Retry-After wait does not block the event loop' => sub {
    my $attempts = 0;
    my $origin = VPNDetectionTest::Origin->new(sub {
        my ($c) = @_;
        if (++$attempts == 1) {
            $c->res->headers->header('Retry-After' => 1);
            return $c->render(json => { error => 'slow down' }, status => 429);
        }
        $c->render(json => { ip => '9.9.9.3', is_vpn => \0 });
    });
    my $client = VPNDetection->new(base_url => $origin->url, cache_size => 0, retries => 1);

    # A sleep inside a promise handler would freeze every other transfer sharing
    # this loop, the origin in this test included. A timer does not, and a
    # recurring tick is the difference made visible.
    my $ticks = 0;
    my $ticker = Mojo::IOLoop->recurring(0.05 => sub { $ticks++ });
    my $result = $client->lookup('9.9.9.3');
    Mojo::IOLoop->remove($ticker);

    is($result->is_vpn, 0, 'the retry succeeded');
    cmp_ok($ticks, '>=', 5, "the loop kept running through the wait (ticked $ticks times)");
};

subtest 'the download redirect is never followed' => sub {
    my $origin = VPNDetectionTest::Origin->new(sub {
        my ($c, $o) = @_;
        if ($c->req->url->path->to_string eq '/api/v1/database/download') {
            $c->res->headers->location($o->url . '/huge');
            return $c->rendered(302);
        }
        # A real dataset file: announces gigabytes and then stalls. A client that
        # followed the redirect hangs here, and is caught by the request count
        # rather than by a transfer.
        $c->res->headers->content_length(8 * 1024 * 1024 * 1024);
        $c->res->headers->content_type('application/octet-stream');
        $c->render_later;
        $c->write('x' x 1024);
    });
    my $client = VPNDetection->new(base_url => $origin->url, cache_size => 0, timeout => 3);

    my $url = $client->database->download_url('vpn_ip_extended_v1', 'mmdb');
    is($url, $origin->url . '/huge', 'the Location is the answer');
    is(scalar(grep { $_ eq '/huge' } $origin->paths), 0, 'the dataset itself was never requested');
    is($origin->count, 1, 'exactly one request was made');
};

subtest 'the API key reaches the wire, and only one way' => sub {
    my $origin = VPNDetectionTest::Origin->new(sub {
        shift->render(json => { ip => '9.9.9.4', is_vpn => \0 });
    });

    VPNDetection->new(base_url => $origin->url, api_key => 'secret-key')->lookup('9.9.9.4');
    my ($keyed) = $origin->requests;
    is($keyed->{headers}{Authorization}, 'Bearer secret-key', 'sent as a bearer token');

    $origin->reset;
    VPNDetection->new(base_url => $origin->url)->lookup('9.9.9.4');
    my ($keyless) = $origin->requests;
    # A keyless client that sends an empty Bearer, an empty X-Api-Key and
    # apikey= earns a 401 from an API that would otherwise have answered.
    ok(!exists $keyless->{headers}{Authorization}, 'no empty Authorization without a key');
    ok(!exists $keyless->{headers}{'X-Api-Key'}, 'no empty X-Api-Key');
    is_deeply($keyless->{query}, {}, 'no apikey query parameter');
};

subtest 'database responses are unwrapped at the right depth' => sub {
    # A license covers a dataset FAMILY, and the id a download takes hangs off
    # `versions`. An earlier spec claimed the list answered {id, formats}, which
    # it never did, so `list` handed back a shape that could not be downloaded.
    my $family = {
        base => 'vpn_ip', name => 'VPN IP', summary => 'IP ranges observed as VPN infrastructure.',
        license_type => 'standard', starts => '2026-09-04T07:49:45.118Z', expires => undef,
        in_term => 1, standing => 'licensed',
        versions => [{
            id => 'vpn_ip_v1', version => 1, summary => 'IP ranges observed as VPN infrastructure.',
            formats => [{ format => 'csvgz', bytes => 111013959 }],
            sample_formats => ['csvgz'],
        }],
    };
    my %bodies = (
        '/api/v1/database/checksum' => {
            id => 'vpn_ip_v1', format => 'mmdb',
            checksums => { md5 => 'm', sha1 => 's1', sha256 => 's256', sha512 => 's512' },
        },
        '/api/v1/database/list' => { databases => [$family] },
        '/api/v1/database/downloads' => { downloads => [{ dataset_id => 'vpn_ip_v1' }] },
        '/api/v1/database/metadata' => { id => 'vpn_ip_v1', entries => 42 },
    );
    my $origin = VPNDetectionTest::Origin->new(sub {
        my ($c) = @_;
        $c->render(json => $bodies{ $c->req->url->path->to_string });
    });
    my $db = VPNDetection->new(base_url => $origin->url, api_key => 'k')->database;

    # `checksums` returns the WHOLE digest set. Reading a top-level sha256 shipped
    # broken in another SDK: it returned undef against a healthy API.
    my $sums = $db->checksums('vpn_ip_v1', 'mmdb');
    is_deeply($sums, $bodies{'/api/v1/database/checksum'}{checksums}, 'the whole digest set');
    is($sums->{sha256}, 's256', 'the digest a caller actually wants is there');

    my $databases = $db->list;
    is_deeply($databases, [$family], 'list unwraps databases');
    is($databases->[0]{base}, 'vpn_ip', 'a family is keyed by base, not by a dataset id');
    is($databases->[0]{versions}[0]{id}, 'vpn_ip_v1', 'and the id to download hangs off versions');
    ok(!exists $databases->[0]{docsGroup}, 'docsGroup is a docs-site slug, not API surface');
    is_deeply($db->downloads, [{ dataset_id => 'vpn_ip_v1' }], 'downloads unwraps downloads');
    is($db->metadata('vpn_ip_v1')->{entries}, 42, 'metadata is the whole document');
};

subtest 'absent and false are different values, natively' => sub {
    my $origin = VPNDetectionTest::Origin->new(sub {
        shift->render(json => { ip => '9.9.9.5', is_vpn => \0, is_hosting => \0 });
    });
    my $result = VPNDetection->new(base_url => $origin->url)->lookup('9.9.9.5');

    is($result->is_hosting, 0, 'a served false is 0');
    is($result->has('is_hosting'), 1, 'and the plan carries it');
    is($result->is_relay, undef, 'an unserved field is undef');
    is($result->has('is_relay'), 0, 'and the plan does not carry it');
    ok(!$result->is_hosting && !$result->is_relay,
        'both are false in boolean context, which is exactly the trap');
    ok(defined $result->is_hosting, 'a served false is DEFINED');
    ok(!defined $result->is_relay, 'an absent field is not');
    is($result->is_hosting // 0, 0, 'defined-or reads a served false as false');
    is($result->is_relay // 0, 0, 'and reads an absent field as false too');
    is_deeply([$result->fields], ['is_vpn', 'is_hosting'], 'fields lists what was served');
    is_deeply([sort keys %{ $result->raw }], ['ip', 'is_hosting', 'is_vpn'], 'raw is the wire body');
    # raw keeps the JSON booleans, so it re-encodes to true/false rather than 1/0.
    like(Mojo::JSON::encode_json($result->raw), qr/"is_hosting":false/, 'raw round-trips as JSON');
    eval { $result->has('is_bananas') };
    like($@, qr/unknown field/, 'has croaks on a name that is not a field');
};

subtest 'presence is exists, not defined' => sub {
    # An explicit null is a field the API DID serve, so the plan carries it and
    # `has` must say so. Testing `defined` instead would report it as missing,
    # and no other case separates the two because the API sends no nulls today.
    my $origin = VPNDetectionTest::Origin->new(sub {
        my ($c) = @_;
        $c->res->headers->content_type('application/json');
        $c->render(data => '{"ip":"9.9.9.10","is_vpn":false,"vpn":null}');
    });
    my $result = VPNDetection->new(base_url => $origin->url)->lookup('9.9.9.10');

    is($result->has('vpn'), 1, 'a served null is still a served field');
    ok(!defined $result->vpn, 'even though its value is undef');
    is($result->has('hosting'), 0, 'an unserved field is still absent');
};

subtest 'an IPv6 address reaches the API with its colons intact' => sub {
    my $origin = VPNDetectionTest::Origin->new(sub {
        shift->render(json => { ip => '2606:4700:4700::1111', is_vpn => \0 });
    });
    VPNDetection->new(base_url => $origin->url)->lookup('2606:4700:4700::1111');

    # A colon is legal in a path segment, and production answers a literal one.
    # Percent-escaping it would be a silent behavior change on every v6 lookup.
    my ($request) = $origin->requests;
    is($request->{path}, '/2606:4700:4700::1111', 'the path is not over-escaped');
};

subtest 'an unknown option is refused rather than ignored' => sub {
    eval { VPNDetection->new(concurency => 32) };
    like($@, qr/unknown option/, 'a typo in a constructor option croaks');
    eval { VPNDetection->new->lookup_batch(['1.1.1.1'], concurency => 32) };
    like($@, qr/unknown option/, 'a typo in a per-call option croaks');
};

subtest 'the cache expires and evicts' => sub {
    my $origin = VPNDetectionTest::Origin->new(sub {
        shift->render(json => { ip => '9.9.9.6', is_vpn => \0 });
    });

    my $stale = VPNDetection->new(base_url => $origin->url, cache_ttl => 0.05);
    $stale->lookup('9.9.9.6');
    Time::HiRes::sleep(0.1);
    $stale->lookup('9.9.9.6');
    is($origin->count, 2, 'an expired answer is fetched again');

    $origin->reset;
    my $small = VPNDetection->new(base_url => $origin->url, cache_size => 2);
    $small->lookup($_) for qw(9.9.9.6 9.9.9.7 9.9.9.8 9.9.9.6);
    is($origin->count, 4, 'the least recently used address was evicted');
};

subtest 'the non-blocking API works where the blocking one cannot' => sub {
    my $origin = VPNDetectionTest::Origin->new(sub {
        shift->render(json => { ip => '9.9.9.9', is_vpn => \1 });
    });
    my $client = VPNDetection->new(base_url => $origin->url);

    my $seen;
    $client->lookup_p('9.9.9.9')->then(sub { $seen = shift })->wait;
    is($seen->is_vpn, 1, 'lookup_p resolves with a result');

    # Inside a running loop the blocking form cannot block, so it says so
    # instead of returning undef.
    my $croaked;
    Mojo::IOLoop->next_tick(sub {
        eval { $client->lookup('1.2.3.4') };
        $croaked = $@;
        Mojo::IOLoop->stop;
    });
    Mojo::IOLoop->start;
    like($croaked, qr/lookup_p/, 'blocking inside a running loop points at the promise form');
};


subtest 'my_ip classifies the calling address and is never cached' => sub {
    # The cache is keyed by address, and which address this is IS the question:
    # a machine that moves between networks would otherwise be told where it
    # used to be.
    my $origin = VPNDetectionTest::Origin->new(sub {
        my ($c) = @_;
        is($c->req->url->path->to_string, '/myip', 'asked for the myip route');
        $c->render(json => { ip => '45.83.91.1', is_vpn => \1 });
    });
    my $client = VPNDetection->new(base_url => $origin->url);

    my $result = $client->my_ip;
    is($result->ip, '45.83.91.1', 'answers the observed address');
    ok($result->is_vpn, 'and classifies it');

    $client->my_ip;
    is($origin->count, 2, 'a second call goes to the network again');
};

subtest 'my_entitlement reports the plan and the usage, and is never cached' => sub {
    # The whole point is what has been spent, so a cached answer is a wrong one
    # within seconds of the next request.
    my $body = {
        org_id => '85bb51e4-2eb6-4a31-8e4d-02ba8b98fe61',
        apikey => {
            id            => '0ab424cc-7619-4dad-b027-afacdc2cedb0',
            expires       => undef,
            allowed_cidrs => [],
        },
        plan  => { key => 'max', tier => 'max' },
        usage => {
            requests     => 580,
            quota        => 5_000_000,
            hard_limit   => undef,
            window_start => '2026-09-04T07:00:00Z',
            window_end   => '2026-10-04T07:00:00Z',
        },
    };
    my $origin = VPNDetectionTest::Origin->new(sub {
        my ($c) = @_;
        is($c->req->url->path->to_string, '/api/v1/entitlement', 'asked for the account route');
        $c->render(json => $body);
    });
    my $client = VPNDetection->new(base_url => $origin->url);

    my $account = $client->my_entitlement;
    is($account->{plan}{key},     'max',     'reports the plan');
    is($account->{plan}{tier},    'max',     'and the field tier');
    is($account->{usage}{requests}, 580,     'and what has been spent');
    is($account->{usage}{quota}, 5_000_000,  'and what the plan includes');
    # Undef means NEVER stop, which is not the same as a limit of zero.
    is($account->{usage}{hard_limit}, undef, 'a null hard limit stays null');
    is_deeply($account->{apikey}{allowed_cidrs}, [], 'an empty allowlist means unrestricted');

    $client->my_entitlement;
    is($origin->count, 2, 'a second call goes to the network again');
};

subtest 'my_entitlement surfaces an unauthorized key' => sub {
    # Unlike a lookup there is no useful unauthenticated answer.
    my $origin = VPNDetectionTest::Origin->new(sub {
        shift->render(json => { error => 'invalid API key' }, status => 401);
    });
    my $client = VPNDetection->new(base_url => $origin->url, retries => 0);

    eval { $client->my_entitlement };
    isa_ok($@, 'VPNDetection::Error', 'refused');
    is($@->kind, 'unauthorized', 'and says why');
};

done_testing();
