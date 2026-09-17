use strict;
use warnings;

use lib 't/lib';

use File::Temp ();
use Mojo::IOLoop;
use Test::More;
use VPNDetection;
use VPNDetectionTest::Origin;

# The dataset transfers: the redirect, what the second request carries, and the
# ways a transfer can end badly.

my $DATASET = 'x' x 4096;

# A test origin that answers the download endpoint with a 302 and then serves the
# dataset from a second path, which is how the real API works. $storage decides
# what that second request gets.
sub origin_for {
    my ($storage) = @_;
    return VPNDetectionTest::Origin->new(sub {
        my ($c, $o) = @_;
        if ($c->req->url->path->to_string eq '/api/v1/database/download') {
            $c->res->headers->location($o->url . '/dataset');
            return $c->rendered(302);
        }
        $storage->($c);
    });
}

sub whole_dataset {
    my ($c) = @_;
    $c->res->headers->content_type('application/octet-stream');
    $c->render(data => $DATASET);
}

sub temp_path {
    my $dir = File::Temp->newdir;
    return ($dir, $dir->dirname . '/cdn_ip_v1.csv.gz');
}

subtest 'a dataset is streamed to a path and lands whole' => sub {
    my $origin = origin_for(\&whole_dataset);
    my ($dir, $path) = temp_path();
    my $db = VPNDetection->new(base_url => $origin->url, api_key => 'secret-key')->database;

    my $written = $db->download('cdn_ip_v1', 'csvgz', $path);

    is($written, length $DATASET, 'the byte count is reported');
    is(-s $path, length $DATASET, 'and the file on disk is that long');
    ok(!-e "$path.part", 'the .part file did not outlive a successful transfer');
    open my $fh, '<', $path or die $!;
    binmode $fh;
    is(do { local $/; <$fh> }, $DATASET, 'the bytes are the dataset');
    is_deeply([$origin->paths], ['/api/v1/database/download', '/dataset'],
        'the link was fetched, then the file');
};

subtest 'the presigned request carries no credential and no encoding preference' => sub {
    my $origin = origin_for(\&whole_dataset);
    my ($dir, $path) = temp_path();
    VPNDetection->new(base_url => $origin->url, api_key => 'secret-key')
        ->database->download('cdn_ip_v1', 'csvgz', $path);

    my ($api, $storage) = $origin->requests;
    is($api->{headers}{Authorization}, 'Bearer secret-key', 'the API call is authenticated');
    # Mojo::UserAgent strips Authorization when it follows a redirect ITSELF
    # (Transactor::redirect removes it along with Cookie, Host and Referer), but
    # this client never follows one: the transfer is a request of its own, so
    # leaving the key off is this library's job rather than the framework's.
    ok(!exists $storage->{headers}{Authorization},
        'and the object storage request carries no Authorization');
    ok(!exists $storage->{headers}{'X-Api-Key'}, 'nor an X-Api-Key');
    is_deeply($storage->{query}, {}, 'nor an apikey query parameter');

    # Mojo::UserAgent asks for gzip on every request it builds. A dataset file is
    # already compressed, so the only thing that would buy is a Content-Length
    # counting bytes that never reach the sink, and that length is the only
    # evidence a transfer arrived whole.
    is($api->{headers}{'Accept-Encoding'}, 'gzip', 'a JSON call still negotiates compression');
    ok(!exists $storage->{headers}{'Accept-Encoding'}, 'a transfer does not');
};

subtest 'the bytes variant agrees with the streamed copy' => sub {
    my $origin = origin_for(\&whole_dataset);
    my ($dir, $path) = temp_path();
    my $db = VPNDetection->new(base_url => $origin->url)->database;

    my $streamed = $db->download('cdn_ip_v1', 'csvgz', $path);
    my $bytes = $db->download_bytes('cdn_ip_v1', 'csvgz');

    is(length $bytes, $streamed, 'the same length');
    open my $fh, '<', $path or die $!;
    binmode $fh;
    is($bytes, do { local $/; <$fh> }, 'and the same bytes');
};

subtest 'a truncated transfer fails loudly and leaves nothing behind' => sub {
    # Announces the whole dataset, sends a third of it, then hangs up. Nothing in
    # the protocol distinguishes that from a complete body except the length that
    # was promised, so a client that does not check it writes a short file and
    # reports success.
    my $origin = origin_for(sub {
        my ($c) = @_;
        $c->res->headers->content_type('application/octet-stream');
        $c->res->headers->content_length(length $DATASET);
        $c->write(substr($DATASET, 0, 1365) => sub { shift->finish });
    });
    my ($dir, $path) = temp_path();
    my $db = VPNDetection->new(base_url => $origin->url, timeout => 5)->database;

    my $written = eval { $db->download('cdn_ip_v1', 'csvgz', $path) };

    ok(!defined $written, 'the transfer did not report success');
    isa_ok($@, 'VPNDetection::Error', 'it failed with');
    like($@->message, qr/ended after 1365 of 4096 bytes/, 'and says how short it stopped');
    ok(!-e $path, 'no short file reads as a whole dataset');
    ok(!-e "$path.part", 'and no partial file survives either');
    # Retries are budgeted for the part before any byte reaches the caller.
    # Repeating a transfer whose bytes were already written would append a second
    # copy to them, and a doubled file passes every length check there is.
    is(scalar(grep { $_ eq '/dataset' } $origin->paths), 1, 'a half-written body was not fetched again');
};

subtest 'object storage failing before the first byte is retried, and the file holds one copy' => sub {
    my $attempts = 0;
    my $origin = origin_for(sub {
        my ($c) = @_;
        return $c->render(text => 'SlowDown', status => 503) if $attempts++ < 1;
        whole_dataset($c);
    });
    my ($dir, $path) = temp_path();
    my $db = VPNDetection->new(base_url => $origin->url, retries => 2)->database;

    my $written = eval { $db->download('cdn_ip_v1', 'csvgz', $path) };

    is(scalar(grep { $_ eq '/dataset' } $origin->paths), 2, 'the 503 was retried');
    is($written, length $DATASET, 'the transfer then succeeded');
    is(-s $path, length $DATASET, 'with exactly one copy on disk');
};

subtest 'a dataset the organization does not license is refused once' => sub {
    my $origin = VPNDetectionTest::Origin->new(sub {
        shift->render(json => { rc => 'NOT_LICENSED' }, status => 403);
    });
    my $db = VPNDetection->new(base_url => $origin->url, api_key => 'k', retries => 3)->database;
    my ($dir, $path) = temp_path();

    for my $call (
        ['download', sub { $db->download('hosting_ip_v1', 'csvgz', $path) }],
        ['download_bytes', sub { $db->download_bytes('hosting_ip_v1', 'csvgz') }],
    ) {
        my ($name, $run) = @$call;
        $origin->reset;
        my $got = eval { $run->() };
        ok(!defined $got, "$name failed");
        is($@->kind, 'forbidden', "$name: classified as forbidden");
        is($@->status, 403, "$name: carries the status");
        # The API says WHICH refusal this is, under `rc`. Falling back to the
        # status means the envelope went unread.
        is($@->message, 'NOT_LICENSED', "$name: carries the API's rc");
        is($@->retryable, 0, "$name: a license refusal is not worth retrying");
        is($origin->count, 1, "$name: and was asked exactly once");
    }
    ok(!-e "$path.part", 'a refused download leaves no partial file');
};

subtest 'object storage refusing the link is reported as such' => sub {
    my $origin = origin_for(sub {
        shift->render(text => 'AccessDenied', status => 403);
    });
    my ($dir, $path) = temp_path();
    my $db = VPNDetection->new(base_url => $origin->url)->database;

    my $written = eval { $db->download('cdn_ip_v1', 'csvgz', $path) };

    ok(!defined $written, 'the transfer failed');
    like($@->message, qr/object storage refused the download link with status 403/,
        'and names where the refusal came from');
    is(scalar(grep { $_ eq '/dataset' } $origin->paths), 1, 'a refusal is not retried');
    ok(!-e "$path.part", 'leaving no partial file');
};

subtest 'no response size cap applies to a dataset' => sub {
    # Mojo aborts a response past max_message_size, counting every byte it parses
    # whether or not it keeps any of them. 2 GiB by default, but
    # MOJO_MAX_MESSAGE_SIZE in the ENVIRONMENT lowers it for every response in
    # the process, exactly as MOJO_MAX_REDIRECTS does for redirects, so a
    # transfer that does not set its own limit is at the mercy of a machine we do
    # not own. One kilobyte here stands in for a 2 GiB dataset.
    local $ENV{MOJO_MAX_MESSAGE_SIZE} = 1024;
    my $origin = origin_for(\&whole_dataset);
    my ($dir, $path) = temp_path();

    my $written = VPNDetection->new(base_url => $origin->url)
        ->database->download('cdn_ip_v1', 'csvgz', $path);

    is($written, length $DATASET, 'a dataset four times the cap still arrived');
    is(-s $path, length $DATASET, 'and reached the disk');
};

subtest 'a transfer outlives the per-request timeout that bounds a lookup' => sub {
    my $megabytes = 24;
    my $origin = origin_for(sub {
        my ($c) = @_;
        $c->res->headers->content_type('application/octet-stream');
        $c->res->headers->content_length($megabytes * 1024 * 1024);
        my $left = $megabytes;
        my $write;
        $write = sub {
            my $writer = shift;
            return $writer->finish unless $left--;
            $writer->write('y' x (1024 * 1024) => sub { $write->(shift) });
        };
        $c->write('' => sub { $write->(shift) });
    });
    my ($dir, $path) = temp_path();
    # One second per request, against a body that takes longer than that to
    # arrive. request_timeout bounds the whole response and Mojo has no
    # per-transaction form of it, so without lifting it a dataset is cut off at
    # whatever bound suits a lookup.
    my $client = VPNDetection->new(base_url => $origin->url, timeout => 1);

    my $written = $client->database->download('cdn_ip_v1', 'csvgz', $path);

    is($written, $megabytes * 1024 * 1024, "all ${megabytes} MiB arrived");
    is(-s $path, $megabytes * 1024 * 1024, 'and reached the disk');
};

subtest 'the per-request timeout is restored after a transfer' => sub {
    my $origin = origin_for(\&whole_dataset);
    my ($dir, $path) = temp_path();
    my $ua = Mojo::UserAgent->new;
    my $client = VPNDetection->new(base_url => $origin->url, timeout => 7, ua => $ua);

    $client->database->download('cdn_ip_v1', 'csvgz', $path);

    is($ua->request_timeout, 7, 'the agent is left as the caller configured it');
};

subtest 'an unwritable destination costs no request' => sub {
    my $origin = origin_for(\&whole_dataset);
    my $db = VPNDetection->new(base_url => $origin->url)->database;

    eval { $db->download('cdn_ip_v1', 'csvgz', '/nonexistent-directory/cdn_ip_v1.csv.gz') };

    like($@, qr/cannot open/, 'the destination is refused up front');
    is($origin->count, 0, 'so no quota was spent finding out');
};

subtest 'the promise forms transfer too' => sub {
    my $origin = origin_for(\&whole_dataset);
    my ($dir, $path) = temp_path();
    my $db = VPNDetection->new(base_url => $origin->url)->database;

    my ($written, $bytes);
    $db->download_p('cdn_ip_v1', 'csvgz', $path)
        ->then(sub { $written = shift; $db->download_bytes_p('cdn_ip_v1', 'csvgz') })
        ->then(sub { $bytes = shift })
        ->wait;

    is($written, length $DATASET, 'download_p resolves with the byte count');
    is($bytes, $DATASET, 'download_bytes_p resolves with the bytes');
};

subtest 'a transfer refuses arguments it cannot use' => sub {
    my $db = VPNDetection->new->database;

    eval { $db->download('cdn_ip_v1', 'csvgz') };
    like($@, qr/expected a destination path/, 'download needs somewhere to write');
    eval { $db->download('', 'csvgz', '/tmp/x') };
    like($@, qr/expected a dataset id/, 'and a dataset id');
    eval { $db->download_bytes('cdn_ip_v1') };
    like($@, qr/expected a format/, 'download_bytes needs a format');
    eval { $db->download_bytes('cdn_ip_v1', 'csvgz', retres => 1) };
    like($@, qr/unknown option/, 'and refuses a typo rather than ignoring it');
};

subtest 'an unpublished format is refused before the network' => sub {
    my $origin = origin_for(\&whole_dataset);
    my ($dir, $path) = temp_path();
    my $db = VPNDetection->new(base_url => $origin->url, api_key => 'k')->database;

    is_deeply([VPNDetection::Database::FORMATS], ['csvgz', 'mmdb'], 'the published formats are exported');
    for my $format ('zip', 'MMDB', 'csv.gz') {
        for my $call (
            [checksums => sub { $db->checksums('cdn_ip_v1', $format) }],
            [download_url => sub { $db->download_url('cdn_ip_v1', $format) }],
            [download => sub { $db->download('cdn_ip_v1', $format, $path) }],
            [download_bytes => sub { $db->download_bytes('cdn_ip_v1', $format) }],
        ) {
            eval { $call->[1]->() };
            like($@, qr/'\Q$format\E' is not a published format; expected one of csvgz, mmdb/,
                "$call->[0] refuses '$format', naming what it takes");
        }
    }
    is($origin->count, 0, 'and not one request was spent finding out');
    ok(!-e "$path.part", 'nor was a .part file left behind');

    $db->download_url('cdn_ip_v1', $_) for VPNDetection::Database::FORMATS;
    is($origin->count, 2, 'while every published format still reaches the API');
};

done_testing();
