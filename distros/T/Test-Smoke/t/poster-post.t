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
require URI;
require HTTP::Daemon;
require HTTP::Status; HTTP::Status->import('RC_OK', 'RC_NOT_IMPLEMENTED');
require HTTP::Response;
require HTTP::Headers;

my $debug = $ENV{SMOKE_DEBUG};

my ($pid, $daemon, $url);

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
                    };
                    $data = $@ if $@;
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
                    diag("<<<Error: @{[$r->as_string]}>>>");
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

    my $poster = Test::Smoke::Poster->new(
        'LWP::UserAgent',
        ddir        => 't',
        jsnfile     => 'testsuite.jsn',
        smokedb_url => "${url}report",
        v           => $debug ? 2 : 0,
    );
    isa_ok($poster, 'Test::Smoke::Poster::LWP_UserAgent');

    ok(write_json($poster->json_filename, $sysinfo), "write_json");
    my $response = eval { $poster->post() };
    $response = $@ if $@;
    is($response, 42, "Got id (LWP::Useragent: ${url}report)")
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

    my $poster = Test::Smoke::Poster->new(
        'curl',
        ddir        => 't',
        jsnfile     => 'testsuite.jsn',
        smokedb_url => qq{"${url}report"},
        curlbin     => $curlbin,
        ($needs_globoff ? (curlargs => ['--globoff']) : ()),
        v           => $debug ? 2 : 0,
    );
    isa_ok($poster, 'Test::Smoke::Poster::Curl');

    ok(write_json($poster->json_filename, $sysinfo), "write_json");
    my $response = eval { $poster->post() };
    $response = $@ if $@;
    is($response, 42, "Got id (curl: ${url}report) curl v$cv")
        or diag(explain({poster => $poster, response => $response}));

    unlink $poster->json_filename;
}

SKIP: {
    skip("Could not load HTTP::Tiny", 3) if ! has_module('HTTP::Tiny');
    skip("HTTP::Tiny too old $HTTP::Tiny::VERSION (IPv6 support >= 0.042)", 3)
        if    $sockhost eq '::'
          and version->parse($HTTP::Tiny::VERSION) < version->parse("0.042");

    my $poster = Test::Smoke::Poster->new(
        'HTTP::Tiny',
        ddir        => 't',
        jsnfile     => 'testsuite.jsn',
        smokedb_url => "${url}report",
        v           => $debug ? 2 : 0,
    );
    isa_ok($poster, 'Test::Smoke::Poster::HTTP_Tiny');

    ok(write_json($poster->json_filename, $sysinfo), "write_json");
    my $response = eval { $poster->post() };
    $response = $@ if $@;
    is($response, 42, "Got id (HTTP::Tiny: ${url}report")
        or diag(explain({poster => $poster, response => $response}));

    unlink $poster->json_filename;
}

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
