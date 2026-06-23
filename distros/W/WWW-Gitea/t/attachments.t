#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use HTTP::Response;
use JSON::MaybeXS qw(encode_json);
use WWW::Gitea;

# A fake LWP::UserAgent that captures the request and returns a canned,
# successful attachment response. Network-free.
{
    package Fake::UA;
    sub new { bless { captured => undef }, shift }
    sub captured { $_[0]->{captured} }
    sub request {
        my ($self, $req) = @_;
        $self->{captured} = $req;
        return HTTP::Response->new(
            200, 'OK',
            [ 'Content-Type' => 'application/json' ],
            JSON::MaybeXS::encode_json({
                id                   => 99,
                name                 => 'asset.bin',
                size                 => 11,
                download_count       => 0,
                uuid                 => 'uuid-99',
                browser_download_url => 'https://gitea.example.com/dl/uuid-99',
                created_at           => '2026-06-22T12:00:00Z',
            }),
        );
    }
}

my $fake = Fake::UA->new;
my $gitea = WWW::Gitea->new(
    url   => 'https://gitea.example.com',
    token => 'SECRET',
    ua    => $fake,
);

# --- upload from raw content ---------------------------------------------

my $asset = $gitea->releases->create_asset('getty', 'p5-www-gitea', 5,
    content => 'hello world', name => 'asset.bin');

isa_ok( $asset, 'WWW::Gitea::Attachment', 'create_asset returns Attachment' );
is( $asset->id,   99,          'parsed attachment id' );
is( $asset->name, 'asset.bin', 'parsed attachment name' );
is( $asset->uuid, 'uuid-99',   'parsed attachment uuid' );

my $req = $fake->captured;
ok( $req, 'request was captured' );
is( $req->method, 'POST', 'upload uses POST' );
like( $req->uri, qr{/repos/getty/p5-www-gitea/releases/5/assets\b},
    'upload URL hits the release assets endpoint' );
like( $req->uri->query // '', qr/\bname=asset\.bin\b/,
    'name query parameter present on the URL' );
like( $req->header('Content-Type'), qr{^multipart/form-data},
    'Content-Type is multipart/form-data' );
is( $req->header('Authorization'), 'token SECRET', 'auth header applied to upload' );

my $body = $req->content;
like( $body, qr/name="attachment"/,
    'multipart field name is attachment' );
like( $body, qr/hello world/,
    'raw content appears in the multipart body' );

# --- upload from a file on disk ------------------------------------------

my ($fh, $filename) = tempfile(UNLINK => 1);
print {$fh} "file payload here";
close $fh;

my $fake2 = Fake::UA->new;
my $gitea2 = WWW::Gitea->new(
    url   => 'https://gitea.example.com',
    token => 'SECRET',
    ua    => $fake2,
);

my $asset2 = $gitea2->releases->create_asset('getty', 'p5-www-gitea', 5,
    file => $filename, name => 'fromfile.txt');

isa_ok( $asset2, 'WWW::Gitea::Attachment', 'file upload returns Attachment' );

my $req2 = $fake2->captured;
is( $req2->method, 'POST', 'file upload uses POST' );
like( $req2->header('Content-Type'), qr{^multipart/form-data},
    'file upload Content-Type is multipart/form-data' );
like( $req2->content, qr/name="attachment"/,
    'file upload multipart field name is attachment' );
like( $req2->content, qr/file payload here/,
    'file contents appear in the multipart body' );

# --- create without file or content croaks --------------------------------

eval { $gitea->releases->create_asset('getty', 'p5-www-gitea', 5, name => 'x') };
like( $@, qr/file or content required/, 'create_asset requires file or content' );

done_testing;
