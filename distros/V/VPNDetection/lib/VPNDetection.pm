package VPNDetection;

use strict;
use warnings;

use Carp ();
use Exporter 'import';
use Mojo::IOLoop;
use Mojo::Promise;
use Mojo::URL;
use Mojo::UserAgent;
use Mojo::Util ();
use Scalar::Util ();

use VPNDetection::Bogon ();
use VPNDetection::Cache;
use VPNDetection::Database;
use VPNDetection::Error;
use VPNDetection::Oauth;
use VPNDetection::Result;

our $VERSION = '3.3.2';
our @EXPORT_OK = ('is_bogon');

use constant DEFAULT_BASE_URL => 'https://api.vpndetection.io';

# The most addresses POST /batch takes in one call; a larger batch is sent in
# chunks of this size.
use constant BATCH_MAX => 1000;

# Seconds before the first retry; each later one waits twice the one before.
use constant BACKOFF_BASE => 0.25;

# The longest Retry-After honored, in seconds: 2**31 - 1 ms, about 24.8 days,
# the same bound as the .NET SDK's.
use constant LONGEST_WAIT => 2_147_483.647;

my %OPTIONS = map { $_ => 1 } qw(
    api_key base_url cache_size cache_ttl concurrency retries timeout ua
);

sub new {
    my ($class, %args) = @_;
    my @unknown = sort grep { !$OPTIONS{$_} } keys %args;
    Carp::croak("VPNDetection->new: unknown option(s): @unknown") if @unknown;

    my $concurrency = defined $args{concurrency} ? $args{concurrency} : 8;
    my $retries = defined $args{retries} ? $args{retries} : 2;
    my $cache_size = defined $args{cache_size} ? $args{cache_size} : 10_000;
    Carp::croak('VPNDetection->new: concurrency must be at least 1') if $concurrency < 1;
    Carp::croak('VPNDetection->new: retries cannot be negative') if $retries < 0;
    # Mojo arms a negative or non-numeric bound as a timer that fires at once, so
    # every call would fail as a network error.
    my $timeout = defined $args{timeout} ? $args{timeout} : 30;
    Carp::croak('VPNDetection->new: timeout must be a number of seconds, 0 or more')
        unless Scalar::Util::looks_like_number($timeout) && $timeout >= 0;

    my $self = bless {
        api_key => $args{api_key},
        base_url => _base_url($args{base_url}),
        concurrency => $concurrency,
        retries => $retries,
        timeout => $timeout,
        cache => $cache_size > 0 ? VPNDetection::Cache->new(
            max => $cache_size,
            ttl => defined $args{cache_ttl} ? $args{cache_ttl} : 3600,
        ) : undef,
        ua => $args{ua} || Mojo::UserAgent->new,
    }, $class;

    # Mojo::UserAgent does not follow redirects by default, but MOJO_MAX_REDIRECTS
    # in the environment turns that on for every agent in the process. Setting it
    # here is what stops the database download's 302 being chased into a
    # multi-gigabyte transfer, on a machine whose environment we do not own.
    $self->{ua}->max_redirects(0);
    $self->{ua}->request_timeout($self->{timeout});
    $self->{ua}->transactor->name("vpndetection-perl/$VERSION");
    return $self;
}

# Both a method and an exportable function, so the address is the LAST argument
# either way: is_bogon($ip) and $client->is_bogon($ip) reach the same code.
sub is_bogon {
    my $ip = pop;
    Carp::croak('is_bogon: expected an IP address') if !defined $ip || ref $ip;
    return VPNDetection::Bogon::is_bogon($ip);
}

# Classify one address. A bogon is answered locally and never reaches the
# network; everything else is served, then cached for this client.
sub lookup {
    my $self = shift;
    $self->_assert_blocking_ok('lookup');
    return $self->_wait($self->lookup_p(@_));
}

sub lookup_p {
    my ($self, $ip, %options) = @_;
    Carp::croak('lookup: expected an IP address') if !defined $ip || !length $ip;
    $self->_check_options('lookup', \%options, 'retries', 'timeout');

    return Mojo::Promise->resolve(VPNDetection::Bogon::bogon_result($ip))
        if VPNDetection::Bogon::is_bogon($ip);

    if ($self->{cache}) {
        my $hit = $self->{cache}->get($ip);
        return Mojo::Promise->resolve($hit) if $hit;
    }

    my $url = $self->_url('/' . Mojo::Util::url_escape($ip, '^A-Za-z0-9\-._~:'));
    my $retries = defined $options{retries} ? $options{retries} : $self->{retries};
    return $self->_retry_p($retries, sub { $self->_json_p($url, undef, $options{timeout}) })->then(sub {
        my $result = VPNDetection::Result->from_wire(shift);
        # Only a served answer is cached. Errors never are, and bogons never
        # reach this far.
        $self->{cache}->set($ip, $result) if $self->{cache};
        return $result;
    });
}

# The address our edge observed this client calling from. Deliberately not
# cached: the cache is keyed by address, and which address this is IS the
# question.
sub my_ip {
    my $self = shift;
    $self->_assert_blocking_ok('my_ip');
    return $self->_wait($self->my_ip_p(@_));
}

sub my_ip_p {
    my ($self, %options) = @_;
    $self->_check_options('my_ip', \%options, 'retries', 'timeout');

    my $url = $self->_url('/myip');
    my $retries = defined $options{retries} ? $options{retries} : $self->{retries};
    return $self->_retry_p($retries, sub { $self->_json_p($url, undef, $options{timeout}) })
        ->then(sub { VPNDetection::Result->from_wire(shift) });
}

# What this key is entitled to and what it has spent. Deliberately not cached:
# the whole point is the number, and a cached one is wrong within seconds.
sub my_entitlement {
    my $self = shift;
    $self->_assert_blocking_ok('my_entitlement');
    return $self->_wait($self->my_entitlement_p(@_));
}

sub my_entitlement_p {
    my ($self, %options) = @_;
    $self->_check_options('my_entitlement', \%options, 'retries', 'timeout');

    my $url = $self->_url('/api/v1/entitlement');
    my $retries = defined $options{retries} ? $options{retries} : $self->{retries};
    return $self->_retry_p($retries, sub { $self->_json_p($url, undef, $options{timeout}) });
}

# Classify many addresses concurrently, keyed by address rather than positional,
# so duplicates collapse to one request and the caller never lines two lists up.
sub lookup_batch {
    my $self = shift;
    $self->_assert_blocking_ok('lookup_batch');
    return $self->_wait($self->lookup_batch_p(@_));
}

sub lookup_batch_p {
    my ($self, $ips, %options) = @_;
    Carp::croak('lookup_batch: expected an array reference of addresses')
        if ref $ips ne 'ARRAY';
    $self->_check_options('lookup_batch', \%options, 'retries', 'concurrency', 'timeout');

    my $limit = defined $options{concurrency} ? $options{concurrency} : $self->{concurrency};
    Carp::croak('lookup_batch: concurrency must be at least 1') if $limit < 1;
    my $retries = defined $options{retries} ? $options{retries} : $self->{retries};

    # Bogons are answered locally and cached answers are reused; everything else
    # goes to the batch endpoint in chunks of up to 1000 addresses, with at most
    # `limit` chunks in flight. Keyed by address rather than positional, so
    # duplicates in the input collapse to a single entry and the caller never has
    # to line two lists up.
    my %seen;
    my @unique = grep { defined && length && !$seen{$_}++ } @$ips;
    my %answers;
    my @pending;
    for my $ip (@unique) {
        if (VPNDetection::Bogon::is_bogon($ip)) {
            $answers{$ip} = VPNDetection::Bogon::bogon_result($ip);
            next;
        }
        my $hit = $self->{cache} ? $self->{cache}->get($ip) : undef;
        if ($hit) {
            $answers{$ip} = $hit;
            next;
        }
        push @pending, $ip;
    }
    my @queue;
    push @queue, [splice @pending, 0, BATCH_MAX] while @pending;

    my $batch = {
        queue => \@queue, answers => \%answers, active => 0, limit => $limit,
        retries => $retries, timeout => $options{timeout}, promise => Mojo::Promise->new,
    };
    $self->_dispatch($batch);
    return $batch->{promise};
}

# The licensed dataset downloads. Built per call rather than held, so the client
# and its sub-API never form a reference cycle.
sub database {
    my ($self) = @_;
    return VPNDetection::Database->_new($self);
}

# The OAuth device-flow sign-in, built per call for the same reason.
sub oauth {
    my ($self) = @_;
    return VPNDetection::Oauth->_new($self);
}

# Keeps exactly `limit` chunks in flight: every answer starts the next one, so a
# per-call concurrency is a real ceiling rather than an option that was accepted
# and ignored. A failing address carries its error as its value, so one bad
# entry cannot lose the rest of the answers: the API reports a per-entry failure
# with the status the single lookup would have answered, and a chunk that fails
# as a whole marks every address in it.
sub _dispatch {
    my ($self, $batch) = @_;
    if (!@{$batch->{queue}} && !$batch->{active}) {
        $batch->{promise}->resolve($batch->{answers});
        return;
    }
    while ($batch->{active} < $batch->{limit} && @{$batch->{queue}}) {
        my $chunk = shift @{$batch->{queue}};
        $batch->{active}++;
        $self->_lookup_chunk_p($chunk, $batch->{retries}, $batch->{timeout})->then(sub {
            my $answers = shift;
            $batch->{answers}{$_} = $answers->{$_} for keys %$answers;
            $self->_settled($batch);
        });
    }
}

# One POST /batch, mapped back onto the addresses it was asked about. A
# chunk-level failure - the call refused, the transport failing, the retries
# exhausted - becomes every address's error, exactly as it would have been had
# each been looked up alone. Never rejects: the failure is the value.
sub _lookup_chunk_p {
    my ($self, $chunk, $retries, $timeout) = @_;
    my $url = $self->_url('/batch');
    return $self->_retry_p($retries, sub { $self->_json_p($url, { ips => $chunk }, $timeout) })->then(
        sub {
            my $body = shift;
            my $results = ref $body->{results} eq 'HASH' ? $body->{results} : {};
            my $errors = ref $body->{errors} eq 'HASH' ? $body->{errors} : {};
            my %answers;
            for my $ip (@$chunk) {
                if (ref $results->{$ip} eq 'HASH') {
                    my $result = VPNDetection::Result->from_wire($results->{$ip});
                    $self->{cache}->set($ip, $result) if $self->{cache};
                    $answers{$ip} = $result;
                }
                elsif (ref $errors->{$ip} eq 'HASH') {
                    $answers{$ip} = VPNDetection::Error->from_entry(
                        $errors->{$ip}{status}, $errors->{$ip}{error},
                    );
                }
                else {
                    $answers{$ip} = VPNDetection::Error->new(
                        kind => 'server_error', status => 200,
                        message => "the batch answer did not include $ip",
                    );
                }
            }
            return \%answers;
        },
        sub {
            my $error = VPNDetection::Error->wrap(shift);
            return { map { $_ => $error } @$chunk };
        },
    );
}

# Releasing the slot happens in the SAME handler that records the answer. A
# second `then` would leave a gap in which a dying handler strands the slot, and
# a batch that never releases one never finishes.
sub _settled {
    my ($self, $batch) = @_;
    $batch->{active}--;
    $self->_dispatch($batch);
}

# Recurses through $self rather than through a self-referential closure, which
# in Perl would be a reference cycle the interpreter never collects. $may_retry,
# when given, can veto a retry the error alone would allow; $tries counts the
# retries already made.
sub _retry_p {
    my ($self, $left, $attempt, $may_retry, $tries) = @_;
    $tries //= 0;
    return $attempt->()->catch(sub {
        my $error = VPNDetection::Error->wrap(shift);
        die $error if $left <= 0 || !$error->retryable || ($may_retry && !$may_retry->());
        # The wait is a TIMER, never a sleep: this promise shares an event loop
        # with every other request in the batch, and sleeping here would stall
        # all of them.
        return Mojo::Promise->timer(_retry_delay($error->retry_after, $tries))
            ->then(sub { $self->_retry_p($left - 1, $attempt, $may_retry, $tries + 1) });
    });
}

# The server's Retry-After when it gave a usable one, otherwise the backoff:
# 250 ms, doubling per retry, capped from the seventh. A Retry-After past
# LONGEST_WAIT is waited out on the backoff too, still rate_limited, rather than
# holding the call for as long as any server asks.
sub _retry_delay {
    my ($retry_after, $tries) = @_;
    return $retry_after
        if defined $retry_after && $retry_after > 0 && $retry_after <= LONGEST_WAIT;
    return BACKOFF_BASE * 2**($tries < 6 ? $tries : 6);
}

# $timeout is the call's own bound, or undef for the client's.
sub _json_p {
    my ($self, $url, $body, $timeout) = @_;
    my $sent = defined $body ? $self->_post_p($url, $body, $timeout) : $self->_get_p($url, $timeout);
    return $sent->then(sub {
        my $res = shift->res;
        die VPNDetection::Error->from_response($res->code, $res->headers, $res->json)
            unless $res->is_success;
        my $decoded = $res->json;
        die VPNDetection::Error->new(
            kind => 'server_error', status => $res->code,
            message => 'the API did not answer with a JSON object',
        ) unless ref $decoded eq 'HASH';
        return $decoded;
    });
}

sub _get_p {
    my ($self, $url, $timeout) = @_;
    return $self->_start_p($self->{ua}->build_tx(GET => $url => $self->_headers), $timeout);
}

# The one request with a body: the batch. Mojo encodes the JSON and sets the
# content type.
sub _post_p {
    my ($self, $url, $body, $timeout) = @_;
    my $tx = $self->{ua}->build_tx(POST => $url => $self->_headers => json => $body);
    return $self->_start_p($tx, $timeout);
}

# One dataset transfer. Every chunk is handed to $on_chunk and none is kept, so a
# body costs the same in memory whether it is 10 KB or 1.79 GB. Resolves with the
# number of bytes handed over.
sub _stream_p {
    my ($self, $url, $on_chunk) = @_;
    # Built here rather than through _get_p, which is the only place the API key
    # is ever attached: the presigned link authorizes itself, so carrying the key
    # would hand it to a host with no business holding it.
    my $tx = $self->{ua}->build_tx(GET => $url);

    # Mojo asks for gzip on every request it builds. A dataset file is already
    # compressed, so the only thing that would buy is a Content-Length counting
    # bytes that never reach the sink, and that length is the only evidence the
    # transfer arrived whole.
    $tx->req->headers->remove('Accept-Encoding');
    # Mojo aborts a response past max_message_size, counting every byte it parses
    # whether or not it keeps any of them. The default is 2 GiB, which the
    # catalog is already within an order of magnitude of, and
    # MOJO_MAX_MESSAGE_SIZE lowers it for every response in the process, on a
    # machine whose environment we do not own.
    $tx->res->max_message_size(0);

    my $received = 0;
    # Unsubscribing Mojo's own reader is what stops the body being collected into
    # the message. The subscriber hangs off the transaction, so holding the
    # transaction strongly inside it would be a cycle the interpreter never
    # collects; the user agent keeps it alive for as long as bytes are arriving.
    my $weak = $tx;
    Scalar::Util::weaken($weak);
    $tx->res->content->unsubscribe('read')->on(read => sub {
        my (undef, $bytes) = @_;
        # An error body is neither written out nor held: the status is what
        # separates a lapsed link from a refused one, and nothing bounds the size
        # of what a storage host puts in the body of a refusal.
        return unless $weak && ($weak->res->code || 0) == 200;
        $received += length $bytes;
        $on_chunk->($bytes);
    });

    return $self->_start_p($tx, 0)->then(sub {
        my $res = shift->res;
        die VPNDetection::Error->from_response($res->code, $res->headers, {
            error => 'object storage refused the download link with status ' . $res->code,
        }) unless $res->code == 200;

        # A body that stops early reaches Perl as an ordinary end of stream: the
        # status was 200 and Mojo reports no error, so without this a half
        # transfer is a short file nobody notices.
        my $declared = $res->headers->content_length;
        die VPNDetection::Error->new(
            kind => 'network',
            message => "the transfer ended after $received of $declared bytes",
        ) if defined $declared && length $declared && $declared != $received;
        return $received;
    });
}

# request_timeout bounds the WHOLE response and Mojo::UserAgent has no
# per-transaction form of it, yet a call may bring its own bound and a transfer
# must have none (0): 30 seconds is right for a lookup and wrong for a gigabyte.
# So it is set only across the hand-over, where start_p arms the timer
# synchronously - and set EXPLICITLY each time, because Mojo runs a loop tick
# inside start_p when the loop is idle, and a retry started in that tick would
# otherwise inherit this call's bound.
#
# A rejection is a plain string when the request never got far enough to have a
# status, which is exactly the transport failure the retry rule treats as worth
# another attempt.
sub _start_p {
    my ($self, $tx, $timeout) = @_;
    my $ua = $self->{ua};
    my $bound = $ua->request_timeout;
    $ua->request_timeout(defined $timeout ? $timeout : $self->{timeout});
    my $promise = eval { $ua->start_p($tx) };
    my $failed = $@;
    $ua->request_timeout($bound);
    die VPNDetection::Error->wrap($failed) unless $promise;
    return $promise->catch(sub {
        die VPNDetection::Error->new(kind => 'network', message => "$_[0]");
    });
}

sub _headers {
    my ($self) = @_;
    my %headers = (Accept => 'application/json');
    # One scheme, though the API offers three. Sending the same key as a bearer
    # token, a header and a query parameter at once is three times the exposure
    # for one credential, and query strings end up in logs.
    $headers{Authorization} = "Bearer $self->{api_key}"
        if defined $self->{api_key} && length $self->{api_key};
    return \%headers;
}

sub _url {
    my ($self, $path, %query) = @_;
    my $url = Mojo::URL->new($self->{base_url} . $path);
    $url->query(%query) if %query;
    return $url;
}

sub _wait {
    my ($self, $promise) = @_;
    my ($value, $error, $failed);
    $promise->then(sub { $value = shift }, sub { ($error, $failed) = (shift, 1) })->wait;
    die $error if $failed;
    return $value;
}

# Checked BEFORE the promise is built, not after: Mojo::UserAgent starts a
# transaction as soon as it is created, so croaking later would still have spent
# a request from the caller's allowance.
sub _assert_blocking_ok {
    my ($self, $method) = @_;
    return unless Mojo::IOLoop->is_running;
    Carp::croak(
        "VPNDetection::$method cannot block inside a running Mojo::IOLoop; "
        . "call ${method}_p instead, which returns a Mojo::Promise"
    );
}

sub _check_options {
    my ($self, $method, $options, @allowed) = @_;
    my %allowed = map { $_ => 1 } @allowed;
    my @unknown = sort grep { !$allowed{$_} } keys %$options;
    Carp::croak("VPNDetection::$method: unknown option(s): @unknown") if @unknown;
    # A negative or non-numeric bound would fire at once and fail the very call
    # it was meant to protect.
    my $timeout = $options->{timeout};
    Carp::croak("VPNDetection::$method: timeout must be a number of seconds, 0 or more")
        if defined $timeout && !(Scalar::Util::looks_like_number($timeout) && $timeout >= 0);
}

sub _base_url {
    my ($url) = @_;
    $url = DEFAULT_BASE_URL unless defined $url && length $url;
    $url =~ s{/+\z}{};
    return $url;
}

1;

__END__

=head1 NAME

VPNDetection - the official Perl client for the VPNDetection API

=head1 SYNOPSIS

    use VPNDetection;

    my $client = VPNDetection->new;
    my $result = $client->lookup('45.83.91.1');

    say 'VPN' if $result->is_vpn;

=head1 DESCRIPTION

Classifies an IP address as VPN infrastructure, a residential, datacenter or
mobile proxy, a Tor node, a hosting provider, a CDN or a privacy relay.

Which fields come back is decided by the plan behind your key. An absent field
means "not in your plan" and is B<not> the same as false; see
L<VPNDetection::Result/ABSENT IS NOT FALSE>, which is the one thing to read
before writing an C<if>.

=head1 METHODS

=head2 new

    my $client = VPNDetection->new(%options);

=over 4

=item api_key

Your API key. Omit it for the free tier, which answers C<ip> and C<is_vpn> and
allows 1000 requests per day per source address.

=item base_url

Defaults to C<https://api.vpndetection.io>.

=item cache_size

Addresses held in this client's cache. Defaults to 10000; B<0 disables caching>.

=item cache_ttl

How long an answer stays fresh, in seconds. Defaults to 3600.

=item concurrency

Requests in flight during a batch. Defaults to 8, and is overridable per call.

=item retries

Attempts after a retryable failure. Defaults to 2, and is overridable per call.
Each retry waits the server's C<Retry-After> when it sent one, otherwise a
backoff of 250 ms that doubles per retry, up to 16 seconds. A C<Retry-After>
longer than about 24.8 days is waited out on that backoff instead.

=item timeout

Per-request timeout in seconds. Defaults to 30, and is overridable per call. It
bounds each attempt, so a retried call can take longer in total, and it is
lifted for a dataset transfer.

=item ua

Your own L<Mojo::UserAgent>, for a proxy or custom TLS settings. The client sets
C<max_redirects> to 0 on whichever agent it is given: the database download
endpoint answers C<302> and that redirect is the answer, so following it would
pull a multi-gigabyte dataset into memory.

=back

The cache belongs to the client instance and is never shared. Two clients
holding different keys are on different plans and entitled to different fields,
so a shared cache would serve one of them the other's shape.

=head2 lookup

    my $result = $client->lookup($ip, %options);

Returns a L<VPNDetection::Result>, or dies with a L<VPNDetection::Error>.
C<retries> and C<timeout> are the per-call options, as they are on C<my_ip> and
C<my_entitlement>.

=head2 my_ip

    my $me = $client->my_ip;

Classifies the address this client is calling from, returning a
L<VPNDetection::Result>.

The same answer C<lookup> would give for that address, at the same cost against
your allowance. The address is the one our edge observed, so a call made through
a proxy or a VPN reports the exit it left through - usually the point of asking.

Deliberately B<not cached>. The cache is keyed by address, and which address this
is IS the question: a machine that moves between networks would otherwise be told
where it used to be.

=head2 my_entitlement

    my $ent = $client->my_entitlement;
    printf "%d of %d\n", $ent->{usage}{requests}, $ent->{usage}{quota};

What this client's API key is entitled to, and how much of it has been used, as a
hash reference with C<org_id>, C<apikey>, C<plan> and C<usage> keys.

Named for what it answers rather than C<me>, which sits one letter from C<my_ip>
and means something quite different: one is which address you are calling FROM,
the other is what the key you are calling WITH may spend.

Unlike a lookup there is no useful unauthenticated answer, so a client built
without an API key gets an unauthorized error rather than a partial one.

Usage counts against the allowance window - the anniversary of the subscription,
not the calendar month and not the billing period - and it is the same number a
lookup is gated on. C<hard_limit> is C<undef> when we never stop serving, which
is not the same as a limit of zero.

Deliberately B<not cached>: the whole point is what has been spent, and a cached
answer is a wrong one within seconds of the next request.

=head2 lookup_batch

    my $answers = $client->lookup_batch(\@ips, %options);

Returns a hash reference keyed by address. Duplicates in C<@ips> collapse to one
request, bogons never reach the network, and an address that failed carries its
L<VPNDetection::Error> as its value instead of failing the batch. C<retries>,
C<concurrency> and C<timeout> are the per-call options, and the timeout bounds
each chunk.

There is no cap on how many addresses one call takes: everything not answered
locally goes out in chunks of up to 1000, the most one request carries.

Perl hashes have no insertion order, so iterate your own list if order matters:

    for my $ip (@ips) {
        my $answer = $answers->{$ip};
    }

=head2 is_bogon

    $client->is_bogon('10.0.0.1');    # 1

Also exportable, for code with no client to hand:

    use VPNDetection 'is_bogon';
    is_bogon('10.0.0.1');

=head2 database

    my $databases = $client->database->list;

The licensed dataset downloads. See L<VPNDetection::Database>.

=head2 oauth

    my $device = $client->oauth->device_authorization('your-client-id');

Signs a person in on their own machine with the OAuth device flow, so a program
can be handed one of their API keys instead of asking for it. See
L<VPNDetection::Oauth>.

=head1 NON-BLOCKING USE

Every call has a C<_p> twin returning a L<Mojo::Promise>: C<lookup_p>,
C<lookup_batch_p>, and the same on L<VPNDetection::Database> and
L<VPNDetection::Oauth>. The blocking forms
are those promises plus a C<wait>, so nothing is duplicated and both paths retry,
cache and short-circuit identically.

    $client->lookup_p('45.83.91.1')
        ->then(sub { say shift->is_vpn })
        ->catch(sub { warn shift })
        ->wait;

Inside an already running L<Mojo::IOLoop> - a Mojolicious application, say - the
blocking forms cannot work and croak saying so. Use the C<_p> forms there.

=head1 SEE ALSO

L<VPNDetection::Result>, L<VPNDetection::Error>, L<VPNDetection::Database>,
L<VPNDetection::Oauth>.

=head1 LICENSE

MIT. Copyright Mslm Dev.

=cut
