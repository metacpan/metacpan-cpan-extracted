#! perl -w
use strict;
use version;
$|++;

# fork() and JSON::XS don't go well together on Windows
BEGIN { $ENV{PERL_JSON_BACKEND} = 'JSON::PP' if $^O eq 'MSWin32'; }

use Test::More;
use Test::NoWarnings ();

use URI::Escape qw/uri_unescape/;
use Config;
use Errno qw/EINTR/;
use URI;
use Test::Smoke::Util::LoadAJSON;
use Test::Smoke::Poster;
use Test::Smoke::Util qw/whereis/;
use Test::Smoke::Util::FindHelpers 'has_module';

if (!has_module('HTTP::Daemon')) {
    plan skip_all => "Need 'HTTP::Daemon' for this test!";
}
use File::Copy qw/copy/;
use File::Temp qw/tempdir/;
use File::Spec::Functions;
require URI;
require HTTP::Daemon;
require HTTP::Status; HTTP::Status->import('RC_OK', 'RC_NOT_IMPLEMENTED');
require HTTP::Response;
require HTTP::Headers;

my $debug = $ENV{SMOKE_DEBUG};

my ($pid, $daemon, $url);

my $tempdir = tempdir(CLEANUP => 1);
my $timeout = 60;
my $jsnfile = 'testsuite.jsn';
my $sockhost;
{
    $daemon = HTTP::Daemon->new() || die "Could not initialize a Daemon";
    $url = URI->new($daemon->url);
    $sockhost = $daemon->sockhost;
    note(
        "HTTP::Daemon ($HTTP::Daemon::VERSION): ",
        $sockhost eq '::' ? "IPv6" : "IPv4",
        " (" , $url->host, ")"
    );

    # Some sockets are exclusive v4 or v6
    # IPv6 doesn't work, so force IPv4 localhost HTTP::Daemon < 6.05
    if ($HTTP::Daemon::VERSION <= 6.07) {
        # Check $daemon->sockhost for either '0.0.0.0' (ipv4) or '::' (ipv6)
        if ($sockhost eq '::') {
            $url->host('[::1]');
        }
        else {
            $url->host('127.0.0.1');
        }
    }

    $pid = fork();
    if ($pid) { # Continue
        note("Temporary daemon at: $url");
    }
    else { # HTTP-Server for dummies
        while (my $c = $daemon->accept) {
            while (my $r = $c->get_request) {
                if ($r->method eq 'POST' && $r->uri->path eq '/report') {
                    (my $json = uri_unescape($r->decoded_content)) =~ s/^json=//;
                    my $data;
                    $data  =  2 if $r->header('User-Agent') =~ /Test::Smoke/;
                    eval {
                        $data += 40 if decode_json($json)->{sysinfo} eq $^O;
                        1;
                    } or $data = $@ || 'decode_json-error';
                    my $response = HTTP::Response->new(
                        RC_OK(), "OK",
                        HTTP::Headers->new('Content-Type', 'application/json'),
                        encode_json({id => $data}),
                    );
                    $c->send_response($response);
                }
                elsif ($r->method eq 'POST' && $r->uri->path eq '/api/report') {
                    my $json = encode_json(decode_json($r->decoded_content)->{report_data});
                    my $data;
                    $data  =  2 if $r->header('User-Agent') =~ /Test::Smoke/;
                    eval {
                        $data += 40 if decode_json($json)->{sysinfo} eq $^O;
                        1;
                    } or $data = $@ || 'decode_json-error';
                    my $response = HTTP::Response->new(
                        RC_OK(), "OK",
                        HTTP::Headers->new('Content-Type', 'application/json'),
                        encode_json({id => $data}),
                    );
                    $c->send_response($response);
                }
                else {
                    my $response = HTTP::Response->new(
                        RC_NOT_IMPLEMENTED(), 'NOT IMPLEMENTED',
                        HTTP::Headers->new('Content-Type', 'application/json'),
                        uri_unescape($r->decoded_content),
                    );
                    $c->send_response($response);
                    note(">>>Error: @{[$r->as_string]}<<<")
                        unless $r->uri->path eq '/api/report-error';
                }
                $c->close;
            }
        }
    }
}
END {
    unlink "t/$jsnfile";
    if ($pid) {
        note("tear down: $pid");
        $daemon->close;
        kill 9, $pid;
    }
}

# We want to address our daemon directly
for my $envv (qw<ALL_PROXY HTTP_PROXY HTTPS_PROXY>) {
    delete($ENV{$envv})     if exists($ENV{$envv});
    delete($ENV{lc($envv)}) if exists($ENV{lc($envv)});
}

my $sysinfo = { sysinfo => $^O };
SKIP: {
    skip("Could not load LWP::UserAgent", 3) if !has_module('LWP::UserAgent');

    (my $sdb_url = $url->clone)->path('/report');
    my $poster = Test::Smoke::Poster->new(
        'LWP::UserAgent',
        ddir        => $tempdir,
        jsnfile     => $jsnfile,
        smokedb_url => $sdb_url->as_string,
        v           => $debug ? 2 : 0,
    );
    isa_ok($poster, 'Test::Smoke::Poster::LWP_UserAgent');

    ok(write_json($poster->json_filename, $sysinfo), "write_json");
    my $response = eval { $poster->post() };
    $response = $@ if $@;
    is($response, 42, "Got id (LWP::Useragent: $sdb_url")
        or diag(explain({poster => $poster, response => $response}));

    unlink $poster->json_filename;
}

SKIP: {
    skip("Could not load LWP::UserAgent", 3) if !has_module('LWP::UserAgent');

    (my $sdb_url = $url->clone)->path('/api/report');
    my $poster = Test::Smoke::Poster->new(
        'LWP::UserAgent',
        ddir        => $tempdir,
        jsnfile     => $jsnfile,
        smokedb_url => $sdb_url->as_string,
        v           => $debug ? 2 : 0,
    );
    isa_ok($poster, 'Test::Smoke::Poster::LWP_UserAgent');

    ok(write_json($poster->json_filename, $sysinfo), "write_json");
    my $response = eval { $poster->post() };
    $response = $@ if $@;
    is($response, 42, "Got id (LWP::Useragent: $sdb_url")
        or diag(explain({poster => $poster, response => $response}));

    unlink $poster->json_filename;
}

SKIP: {
    my $curlbin = whereis('curl');
    skip("Could not find curl", 3) if !$curlbin;
    my $curl_version = qx{$curlbin --version};
    my $cv = $curl_version =~ m{curl ([0-9.]+)} ? $1 : '0';

    my $is_v6_address = $url =~ m{^ https?://\[ [0-9a-fA-F:]+ \] /? }x;
    my $needs_globoff = $is_v6_address &&
        (version->parse($cv) < version->parse("7.68.0"));

    (my $sdb_url = $url->clone)->path('/report');
    my $poster = Test::Smoke::Poster->new(
        'curl',
        ddir        => $tempdir,
        jsnfile     => $jsnfile,
        smokedb_url => $sdb_url->as_string,
        curlbin     => $curlbin,
        ($needs_globoff ? (curlargs => ['--globoff', '-s']) : ()),
        v           => $debug ? 2 : 0,
    );
    isa_ok($poster, 'Test::Smoke::Poster::Curl');

    ok(write_json($poster->json_filename, $sysinfo), "write_json");
    my $response = eval { $poster->post() };
    $response = $@ if $@;
    is($response, 42, "Got id (curl: $sdb_url curl v$cv")
        or diag(explain({poster => $poster, response => $response}));

    unlink $poster->json_filename;
}

SKIP: {
    my $curlbin = whereis('curl');
    skip("Could not find curl", 3) if !$curlbin;
    my $curl_version = qx{$curlbin --version};
    my $cv = $curl_version =~ m{curl ([0-9.]+)} ? $1 : '0';

    my $is_v6_address = $url =~ m{^ https?://\[ [0-9a-fA-F:]+ \] /? }x;
    my $needs_globoff = $is_v6_address &&
        (version->parse($cv) < version->parse("7.68.0"));

    (my $sdb_url = $url->clone)->path('/api/report');
    my $poster = Test::Smoke::Poster->new(
        'curl',
        ddir        => $tempdir,
        jsnfile     => $jsnfile,
        smokedb_url => $sdb_url->as_string,
        curlbin     => $curlbin,
        ($needs_globoff ? (curlargs => ['--globoff', '-s']) : ()),
        v           => $debug ? 2 : 0,
    );
    isa_ok($poster, 'Test::Smoke::Poster::Curl');

    ok(write_json($poster->json_filename, $sysinfo), "write_json");
    my $response = eval { $poster->post() };
    $response = $@ if $@;
    is($response, 42, "Got id (curl: $sdb_url curl v$cv")
        or diag(explain({poster => $poster, response => $response}));

    unlink $poster->json_filename;
}

SKIP: {
    skip("Could not load HTTP::Tiny", 3) if ! has_module('HTTP::Tiny');
    skip("HTTP::Tiny too old $HTTP::Tiny::VERSION (IPv6 support >= 0.042)", 3)
        if    $sockhost eq '::'
          and version->parse($HTTP::Tiny::VERSION) < version->parse("0.042");

    (my $sdb_url = $url->clone)->path('/report');
    my $poster = Test::Smoke::Poster->new(
        'HTTP::Tiny',
        ddir        => $tempdir,
        jsnfile     => $jsnfile,
        smokedb_url => $sdb_url->as_string,
        v           => $debug ? 2 : 0,
    );
    isa_ok($poster, 'Test::Smoke::Poster::HTTP_Tiny');

    ok(write_json($poster->json_filename, $sysinfo), "write_json");
    my $response = eval { $poster->post() };
    $response = $@ if $@;
    is($response, 42, "Got id (HTTP::Tiny: $sdb_url")
        or diag(explain({poster => $poster, response => $response}));

    unlink $poster->json_filename;
}

SKIP: {
    skip("Could not load HTTP::Tiny", 3) if ! has_module('HTTP::Tiny');
    skip("HTTP::Tiny too old $HTTP::Tiny::VERSION (IPv6 support >= 0.042)", 3)
        if    $sockhost eq '::'
          and version->parse($HTTP::Tiny::VERSION) < version->parse("0.042");

    (my $sdb_url = $url->clone)->path('/api/report');
    my $poster = Test::Smoke::Poster->new(
        'HTTP::Tiny',
        ddir        => $tempdir,
        jsnfile     => $jsnfile,
        smokedb_url => $sdb_url->as_string,
        v           => $debug ? 2 : 0,
    );
    isa_ok($poster, 'Test::Smoke::Poster::HTTP_Tiny');

    ok(write_json($poster->json_filename, $sysinfo), "write_json");
    my $response = eval { $poster->post() };
    $response = $@ if $@;
    is($response, 42, "Got id (HTTP::Tiny: $sdb_url")
        or diag(explain({poster => $poster, response => $response}));

    unlink $poster->json_filename;
}

SKIP: {
    skip("Could not load HTTP::Tiny", 3) if ! has_module('HTTP::Tiny');
    skip("HTTP::Tiny too old $HTTP::Tiny::VERSION (IPv6 support >= 0.042)", 3)
        if    $sockhost eq '::'
          and version->parse($HTTP::Tiny::VERSION) < version->parse("0.042");

    # Capture the log statements
    $Test::Smoke::LogMixin::USE_TIMESTAMP = 0;
    open(my $out, '>', \my $outbuffer);
    my $old_out = select($out);

    # Prepare a .patch-file and archive directory
    my $patch_level = "654321";
    my $adir = catdir($tempdir, "archive");
    mkdir($adir) or die "Cannot mkdir($adir): $!";
    open(my $pl, '>', catfile($tempdir, '.patch'));
    print {$pl} $patch_level;
    close($pl);
    my $qfile = catfile($tempdir, "archive.qfile");

    # Set a URL that is not supported by the test-daemon,
    # so we get an error.
    (my $sdb_url = $url->clone)->path('/api/report-error');
    my $poster = Test::Smoke::Poster->new(
        'HTTP::Tiny',
        ddir        => $tempdir,
        jsnfile     => $jsnfile,
        qfile       => $qfile,
        smokedb_url => $sdb_url->as_string,
        v           => $debug ? 2 : 0,
    );
    isa_ok($poster, 'Test::Smoke::Poster::HTTP_Tiny');

    # Prepare the Queue.
    require Test::Smoke::PostQueue;
    my $queue = Test::Smoke::PostQueue->new(
        adir   => $adir,
        qfile  => $qfile,
        poster => $poster,
        v      => 1,
    );
    isa_ok($queue, 'Test::Smoke::PostQueue');

    # Try to post, but it should fail, and queue this report.
    ok(write_json($poster->json_filename, $sysinfo), "write_json");
    my $response = eval { $poster->post() };
    $response = $@ if $@;
    is(
        $response,
        undef,
        "Posting the report failed (ok)"
    ) or diag(explain({poster => $poster, response => $response}));

    # Copy the jsn to "the archive" $adir.
    copy($poster->json_filename, catfile($adir, "jsn$patch_level.jsn"));

    # Check the queue
    ok(-e $qfile, "Queue exists");
    open(my $fh, '<', $qfile) or die "Cannot open($qfile): $!";
    chomp(my @q = <$fh>);
    close($fh);
    is_deeply(\@q, [ $patch_level ], "Queue has the correct items");

    # Fix the poster URL and handle the queue
    $sdb_url->path('/report');
    $poster->smokedb_url($sdb_url->as_string);
    $queue->handle();
    is(-s $qfile, 0, "All queue items reposted");

    select($old_out);

    is($outbuffer, <<EOL, "Logfile ok");
POST failed: 501 NOT IMPLEMENTED ({"report_data": {"sysinfo":"$^O"}})
Posted 654321 from queue: report_id = 42
EOL

    unlink $poster->json_filename;
}

ENDTEST:
Test::NoWarnings::had_no_warnings();
$Test::NoWarnings::do_end_test = 0;
done_testing();

sub write_json {
    my ($file, $content) = @_;
    my $encoded = encode_json($content);

    open my $fh, '>', $file or die "Cannot create($file): $!";
    print $fh $encoded;
    close $fh;
    return 1;
}
