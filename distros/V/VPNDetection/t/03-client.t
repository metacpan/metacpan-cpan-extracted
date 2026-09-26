use strict;
use warnings;

use lib 't/lib';

use File::Temp ();
use Mojo::IOLoop;
use Mojo::JSON ();
use Mojo::UserAgent;
use Test::More;
use Time::HiRes ();
use VPNDetection;
use VPNDetectionTest;
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

subtest 'a concurrency below 1 is refused before any request' => sub {
    # A batch that can put no chunk in flight never finishes, so this is refused
    # up front rather than discovered by a caller left waiting.
    my $origin = VPNDetectionTest::Origin->new(sub { shift->render(json => {}) });
    my $client = VPNDetection->new(base_url => $origin->url, cache_size => 0);
    for my $bad (0, -1) {
        # Raced against a timer: accepted, it would be a batch that never ends.
        my $batch = eval { $client->lookup_batch_p(['9.9.9.1', '9.9.9.2'], concurrency => $bad) };
        like($@, qr/concurrency must be at least 1/, "lookup_batch refuses concurrency => $bad");
        Mojo::Promise->race($batch, Mojo::Promise->timer(1))->wait if $batch;
        eval { VPNDetection->new(concurrency => $bad) };
        like($@, qr/concurrency must be at least 1/, "new refuses concurrency => $bad");
    }
    is($origin->count, 0, 'and not one request was spent finding out');
};

for my $body (qw(stall_body trickle_body)) {
subtest "a per-call timeout below the client one fires on a $body" => sub {
    my $origin = VPNDetectionTest::Origin->new(\&{"VPNDetectionTest::Origin::$body"});
    my $client = VPNDetection->new(
        base_url => $origin->url, api_key => 'k', cache_size => 0, retries => 0, timeout => 3,
    );
    my $db = $client->database;
    my %calls = (
        lookup => sub { $client->lookup('9.9.9.9', @_) },
        my_ip => sub { $client->my_ip(@_) },
        my_entitlement => sub { $client->my_entitlement(@_) },
        lookup_batch => sub { $client->lookup_batch(['9.9.9.9'], @_)->{'9.9.9.9'} },
        'database->list' => sub { $db->list(@_) },
        'database->metadata' => sub { $db->metadata('vpn_ip_v1', @_) },
        'database->checksums' => sub { $db->checksums('vpn_ip_v1', 'mmdb', @_) },
        'database->downloads' => sub { $db->downloads(@_) },
        'database->download_url' => sub { $db->download_url('vpn_ip_v1', 'mmdb', @_) },
    );

    for my $name (sort keys %calls) {
        my $started = Time::HiRes::time();
        my $answer = eval { $calls{$name}->(timeout => 0.25) };
        my $error = $@ || $answer;
        my $elapsed = Time::HiRes::time() - $started;

        isa_ok($error, 'VPNDetection::Error', $name);
        is($error->kind, 'network', "$name: surfaces as a transport failure");
        is($error->retryable, 1, "$name: and is worth another attempt");
        cmp_ok($elapsed, '>=', 0.2, "$name: the call waited for it");
        cmp_ok($elapsed, '<', 1.5, "$name: the call's 0.25s fired, not the client's 3s");
    }

    # A per-call value left on something the client shares would pass the loop
    # above and leave every later call on the wrong bound.
    my $bounded = VPNDetection->new(base_url => $origin->url, cache_size => 0, retries => 0, timeout => 0.25);
    my $started = Time::HiRes::time();
    eval { $bounded->lookup('9.9.9.9') };
    my $elapsed = Time::HiRes::time() - $started;
    is(ref $@ && $@->kind, 'network', "without an override the client's own bound fires");
    cmp_ok($elapsed, '>=', 0.2, 'after waiting for it');
    cmp_ok($elapsed, '<', 1.5, 'at its 0.25s');
};
}

subtest 'a per-call timeout bounds every attempt of that call and nothing after it' => sub {
    my $origin = VPNDetectionTest::Origin->new(sub {
        my ($c) = @_;
        return VPNDetectionTest::Origin::stall_body($c) if $c->req->url->path->to_string eq '/9.9.9.9';
        VPNDetectionTest::Origin::slow_json($c, { ip => '9.9.9.8', is_vpn => \0 }, 0.5);
    });
    my $ua = Mojo::UserAgent->new;
    my $client = VPNDetection->new(
        base_url => $origin->url, cache_size => 0, retries => 1, timeout => 3, ua => $ua,
    );

    my $started = Time::HiRes::time();
    eval { $client->lookup('9.9.9.9', timeout => 0.25) };
    my $elapsed = Time::HiRes::time() - $started;
    is($@->kind, 'network', 'the call timed out');
    is($origin->count, 2, 'once, and once more on the retry');
    cmp_ok($elapsed, '<', 1.5, "the retry kept the call's bound rather than taking the client's");
    is($ua->request_timeout, 3, 'the agent is left as the client configured it');

    # Slower than the last call's bound and well inside the client's, so this
    # fails only if that bound outlived the call it was given to.
    is($client->lookup('9.9.9.8')->ip, '9.9.9.8', 'the next call is bounded by the client again');
};

subtest "a request started inside another call's window takes its own bound" => sub {
    my $origin = VPNDetectionTest::Origin->new(sub {
        my ($c) = @_;
        $c->render(json => { ip => substr($c->req->url->path->to_string, 1), is_vpn => \0 });
    });
    my $ua = Mojo::UserAgent->new;
    my $client = VPNDetection->new(base_url => $origin->url, cache_size => 0, timeout => 3, ua => $ua);
    my (%bound, $nested);
    $ua->on(start => sub {
        my (undef, $tx) = @_;
        my $path = $tx->req->url->path->to_string;
        $bound{$path} = $ua->request_timeout;
        # The bound is swapped around start_p, and Mojo runs a loop tick in there
        # when the loop is idle. Starting a request from this event puts it inside
        # that window as deterministically as a retry landing in the tick would.
        $nested ||= $client->lookup_p('9.9.9.8') if $path eq '/9.9.9.9';
    });

    $client->lookup('9.9.9.9', timeout => 0.25);
    $nested->wait;

    is($bound{'/9.9.9.9'}, 0.25, 'the call took its own bound');
    is($bound{'/9.9.9.8'}, 3, "and the request started inside its window took the client's, not the call's");
};

subtest 'a per-call timeout is refused where it cannot work' => sub {
    my $origin = VPNDetectionTest::Origin->new(sub { shift->render(json => {}) });
    my $client = VPNDetection->new(base_url => $origin->url, api_key => 'k');
    my $dir = File::Temp->newdir;
    my $path = $dir->dirname . '/vpn_ip_v1.mmdb';

    for my $bad (-1, 'soon') {
        eval { $client->lookup('9.9.9.9', timeout => $bad) };
        like($@, qr/timeout must be a number of seconds/, "lookup refuses timeout => $bad");
        eval { $client->database->list(timeout => $bad) };
        like($@, qr/timeout must be a number of seconds/, "database->list refuses timeout => $bad");
    }
    # A transfer runs as long as the file takes. A bound would cut it off, and
    # one spent on the link alone would read as bounding a transfer it does not.
    eval { $client->database->download('vpn_ip_v1', 'mmdb', $path, timeout => 5) };
    like($@, qr/unknown option\(s\): timeout/, 'download refuses one outright');
    eval { $client->database->download_bytes('vpn_ip_v1', 'mmdb', timeout => 5) };
    like($@, qr/unknown option\(s\): timeout/, 'and so does download_bytes');
    is($origin->count, 0, 'and not one request was spent finding out');
    ok(!-e "$path.part", 'nor was a .part file left behind');
};

subtest 'a client-wide timeout is refused where it cannot work' => sub {
    my $origin = VPNDetectionTest::Origin->new(sub {
        shift->render(json => { ip => '9.9.9.9', is_vpn => \0 });
    });

    for my $bad (-1, 'soon') {
        my $client = eval { VPNDetection->new(base_url => $origin->url, api_key => 'k', timeout => $bad) };
        like($@, qr/VPNDetection->new: timeout must be a number of seconds/, "new refuses timeout => $bad");
        ok(!$client, "and builds no client for timeout => $bad");
    }
    is($origin->count, 0, 'and not one request was spent finding out');
    # 0 is no bound at all, which is a choice rather than a mistake.
    my $unbounded = eval { VPNDetection->new(base_url => $origin->url, api_key => 'k', timeout => 0) };
    is($@, '', 'while new accepts timeout => 0');
    is($unbounded && $unbounded->lookup('9.9.9.9')->ip, '9.9.9.9', 'and that client answers');
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

subtest 'a retry without Retry-After backs off, doubling' => sub {
    my @at;
    my $origin = VPNDetectionTest::Origin->new(sub {
        push @at, Time::HiRes::time();
        shift->render(json => { error => 'unavailable' }, status => 503);
    });
    my $client = VPNDetection->new(base_url => $origin->url, cache_size => 0, retries => 2);

    eval { $client->lookup('9.9.9.4') };
    my $error = $@;
    is(ref $error && $error->kind, 'server_error', 'the call failed as the server did');
    is(scalar @at, 3, 'one attempt plus two retries');
    my ($first, $second) = ($at[1] - $at[0], $at[2] - $at[1]);
    cmp_ok($first, '>=', 0.24, sprintf 'the first retry waited %.3f s, at least 250 ms', $first);
    cmp_ok($first, '<', 0.45, 'and not the doubled wait');
    cmp_ok($second, '>=', 0.49, sprintf 'the second waited %.3f s, at least 500 ms', $second);
};

subtest 'the retry schedule, and the longest Retry-After honored' => sub {
    my @backoff = map { VPNDetection::_retry_delay(undef, $_) } 0 .. 7;
    is_deeply(\@backoff, [0.25, 0.5, 1, 2, 4, 8, 16, 16], 'doubling from 250 ms, capped from the seventh');
    is(VPNDetection::_retry_delay(3, 4), 3, 'a Retry-After is waited as given');
    is(VPNDetection::_retry_delay(0, 1), 0.5, 'a Retry-After of 0 waits the backoff');
    is(VPNDetection::_retry_delay(2_147_483.647, 0), 2_147_483.647, 'up to 2**31 - 1 ms');
    is(VPNDetection::_retry_delay(2_147_484, 0), 0.25, 'and one past it waits the backoff');
    is(VPNDetection::_retry_delay(9223372036854775807, 1), 0.5, 'as does one no timer should hold');
};

subtest 'a Retry-After past the bound is waited out on the backoff' => sub {
    my $attempts = 0;
    my $origin = VPNDetectionTest::Origin->new(sub {
        my ($c) = @_;
        if (++$attempts == 1) {
            $c->res->headers->header('Retry-After' => '9223372036854775807');
            return $c->render(json => { error => 'slow down' }, status => 429);
        }
        $c->render(json => { ip => '9.9.9.5', is_vpn => \0 });
    });
    my $client = VPNDetection->new(base_url => $origin->url, cache_size => 0, retries => 1);

    # Raced against a timer: honored as given, this wait would never end.
    my ($result, $timed_out);
    my $started = Time::HiRes::time();
    Mojo::Promise->race(
        $client->lookup_p('9.9.9.5')->then(sub { $result = shift }),
        Mojo::Promise->timer(5)->then(sub { $timed_out = 1 }),
    )->wait;
    ok(!$timed_out, 'the call did not wait on the server');
    is($result && $result->is_vpn, 0, 'the retry succeeded');
    is($origin->count, 2, 'after exactly one retry');
    cmp_ok(Time::HiRes::time() - $started, '<', 2, 'having waited the backoff');
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

subtest 'every closed vocabulary is listed at runtime, as the pinned spec publishes it' => sub {
    # Read off the properties that use each vocabulary, so a value the spec gains
    # or drops reddens this on the next re-pin rather than leaving a list quietly short.
    plan skip_all => 'the distribution does not ship spec/' if VPNDetectionTest::is_distribution();
    is_deeply([VPNDetection::Database::FORMATS],
        VPNDetectionTest::spec_enum(qw(components schemas DatabaseFormatSize properties format)), 'FORMATS');
    is_deeply([VPNDetection::Database::STANDINGS],
        VPNDetectionTest::spec_enum(qw(components schemas Database properties standing)), 'STANDINGS');
    is_deeply([VPNDetection::Database::LICENSE_TYPES],
        VPNDetectionTest::spec_enum(qw(components schemas Database properties license_type)), 'LICENSE_TYPES');
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

subtest 'concurrent misses for one address share one request' => sub {
    # 3.3.2 sent one request per caller: twenty concurrent lookups of one
    # address were twenty requests. The origin holds each answer, so the calls
    # genuinely overlap, and records what each batch asked for.
    my @batches;
    my $origin = VPNDetectionTest::Origin->new(sub {
        my ($c) = @_;
        if ($c->req->url->path->to_string eq '/batch') {
            push @batches, [sort @{ $c->req->json->{ips} }];
            VPNDetectionTest::Origin::slow_json($c, VPNDetectionTest::Origin::batch_body($c, 1), 0.2);
            return;
        }
        my ($ip) = $c->req->url->path->to_string =~ m{^/(.+)$};
        return $c->render(status => 500, json => { error => 'boom' }) if $ip eq '9.9.9.9';
        VPNDetectionTest::Origin::slow_json($c, { ip => $ip, is_vpn => \1 }, 0.2);
    });
    my $client = VPNDetection->new(base_url => $origin->url, retries => 0);

    my @results;
    Mojo::Promise->all(map { $client->lookup_p('9.9.9.1') } 1 .. 20)
        ->then(sub { @results = map { $_->[0] } @_ })->wait;
    is($origin->count, 1, 'twenty concurrent lookups of one address send one request');
    is(scalar(grep { $_->is_vpn } @results), 20, 'and every caller gets its answer');

    # A batch waits for a lookup already in flight instead of sending it.
    $origin->reset;
    my ($single, $batch);
    Mojo::Promise->all(
        $client->lookup_p('9.9.9.2')->then(sub { $single = shift }),
        $client->lookup_batch_p(['9.9.9.2', '9.9.9.3'])->then(sub { $batch = shift }),
    )->wait;
    is_deeply([sort $origin->paths], ['/9.9.9.2', '/batch'], 'the lookup and the batch each sent once');
    is_deeply($batches[-1], ['9.9.9.3'], 'the batch left out the address the lookup was fetching');
    is($batch->{'9.9.9.2'}, $single, 'and took the lookup\'s answer for it');

    # A lookup waits for a batch that boarded its address before sending.
    $origin->reset;
    my ($late, $first);
    Mojo::Promise->all(
        $client->lookup_batch_p(['9.9.9.4', '9.9.9.5'])->then(sub { $first = shift }),
        $client->lookup_p('9.9.9.5')->then(sub { $late = shift }),
    )->wait;
    is_deeply([$origin->paths], ['/batch'], 'a lookup of an address a batch is fetching sends nothing');
    is($late, $first->{'9.9.9.5'}, 'and takes the batch\'s answer');

    # A failure reaches every waiter, and is cached for none.
    $origin->reset;
    my @failed;
    Mojo::Promise->all(map {
        $client->lookup_p('9.9.9.9')->then(sub { push @failed, 'resolved' }, sub { push @failed, shift })
    } 1 .. 5)->wait;
    is($origin->count, 1, 'five concurrent lookups of a failing address send one request');
    is(scalar(grep { ref $_ && $_->kind eq 'server_error' } @failed), 5, 'and all five fail with its error');
    eval { $client->lookup('9.9.9.9') };
    is($origin->count, 2, 'the failure was not cached');

    # Without a cache every lookup is served, so nothing is shared.
    $origin->reset;
    my $uncached = VPNDetection->new(base_url => $origin->url, cache_size => 0);
    Mojo::Promise->all(map { $uncached->lookup_p('9.9.9.6') } 1 .. 5)->wait;
    is($origin->count, 5, 'a client with no cache shares nothing');
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
