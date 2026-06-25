#!perl
use v5.24;
use strictures 2;

use Test2::V1               qw( is ok done_testing );
use Test2::Tools::Exception qw( dies );

use HTTP::Response;
use Test::LWP::UserAgent;

BEGIN { $WebService::OPNsense::VERSION = '0.001' }
use WebService::OPNsense;

# Helper: build an OPNsense object with a mock handler
sub _build_opn {
    my ($handler) = @_;
    my $ua = Test::LWP::UserAgent->new;
    $ua->add_handler( request_send => $handler );
    return WebService::OPNsense->new(
        base_url => 'https://opnsense.example.com',
        username => 'key',
        password => 'secret',
        ua       => $ua,
    );
}

# providers (GET, 200, decoded data)
{
    my $captured;
    my $opn = _build_opn(
        sub {
            my ($req) = @_;
            $captured = $req->uri->as_string;
            HTTP::Response->new(
                200, 'OK',
                [ 'Content-Type' => 'application/json' ],
                '{"rows":[{"name":"file","enabled":"1"},{"name":"ftp","enabled":"0"}]}',
            );
        }
    );
    my $data = $opn->backup->providers;
    is(
        $captured,
        'https://opnsense.example.com/api/core/backup/providers',
        'providers URL path'
    );
    is( ref $data,                 'HASH', 'providers returns hashref' );
    is( $data->{rows}[0]{name},    'file', 'providers first row name' );
    is( $data->{rows}[0]{enabled}, '1',    'providers first row enabled' );
    is( $data->{rows}[1]{name},    'ftp',  'providers second row name' );
}

# providers (GET, 200, empty content)
{
    my $opn = _build_opn(
        sub {
            HTTP::Response->new(
                200, 'OK',
                [ 'Content-Type' => 'application/json' ],
                '',
            );
        }
    );
    ok(
        !defined $opn->backup->providers,
        'providers empty content returns undef'
    );
}

# backups with host (GET, 200)
{
    my $captured;
    my $opn = _build_opn(
        sub {
            my ($req) = @_;
            $captured = $req->uri->as_string;
            HTTP::Response->new(
                200, 'OK',
                [ 'Content-Type' => 'application/json' ],
                '{"rows":[{"id":"20200601","description":"nightly"}]}',
            );
        }
    );
    my $data = $opn->backup->backups('myfirewall');
    is(
        $captured,
        'https://opnsense.example.com/api/core/backup/backups/myfirewall',
        'backups URL path with host'
    );
    is( ref $data,            'HASH',     'backups returns hashref' );
    is( $data->{rows}[0]{id}, '20200601', 'backups row id' );
}

# backups 404 (GET, suppressed)
{
    my $opn = _build_opn(
        sub {
            HTTP::Response->new( 404, 'Not Found' );
        }
    );
    ok(
        !defined $opn->backup->backups('missing'),
        'backups 404 returns undef'
    );
}

# delete_backup (POST, 200, decoded data)
{
    my ( $captured, $method );
    my $opn = _build_opn(
        sub {
            my ($req) = @_;
            $captured = $req->uri->as_string;
            $method   = $req->method;
            HTTP::Response->new(
                200, 'OK',
                [ 'Content-Type' => 'application/json' ],
                '{"result":"deleted"}',
            );
        }
    );
    my $data = $opn->backup->delete_backup('bak-20200601');
    is( $method, 'POST', 'delete_backup uses POST' );
    is(
        $captured,
        'https://opnsense.example.com/api/core/backup/deleteBackup/bak-20200601',
        'delete_backup URL path'
    );
    is( $data->{result}, 'deleted', 'delete_backup result' );
}

# delete_backup error (POST, 500, Exception)
{
    my $opn = _build_opn(
        sub {
            HTTP::Response->new(
                500, 'Internal Server Error',
                [ 'Content-Type' => 'application/json' ],
                '{"error":"delete failed"}',
            );
        }
    );
    my $e = eval { $opn->backup->delete_backup('bad-bak'); undef } || $@;
    ok(
        $e->isa('WebService::OPNsense::Exception'),
        'delete_backup 500 throws Exception'
    );
    is( $e->http_status, 500,             'exception http_status' );
    is( $e->message,     'delete failed', 'exception message' );
}

# revert_backup (POST, 200, decoded data)
{
    my ( $captured, $method );
    my $opn = _build_opn(
        sub {
            my ($req) = @_;
            $captured = $req->uri->as_string;
            $method   = $req->method;
            HTTP::Response->new(
                200, 'OK',
                [ 'Content-Type' => 'application/json' ],
                '{"result":"reverted"}',
            );
        }
    );
    my $data = $opn->backup->revert_backup('bak-20200601');
    is( $method, 'POST', 'revert_backup uses POST' );
    is(
        $captured,
        'https://opnsense.example.com/api/core/backup/revertBackup/bak-20200601',
        'revert_backup URL path'
    );
    is( $data->{result}, 'reverted', 'revert_backup result' );
}

done_testing;
