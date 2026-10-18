#!perl

# vim: ts=4 sts=4 sw=4 et: syntax=perl
#
# Copyright (c) 2026 Sven Kirmess
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use Cwd            ();
use File::Basename ();
use File::Spec     ();
use lib File::Spec->catdir( File::Basename::dirname( Cwd::abs_path __FILE__ ), 'lib' );

use WebService::UptimeKuma::Push;

use Local::HTTP::Mock;

note('new( server => ..., token => ... )');
{
    my $kuma = WebService::UptimeKuma::Push->new( server => 'https://kuma.example.net:3001', token => 'abc123' );
    isa_ok( $kuma, 'WebService::UptimeKuma::Push', 'new returned object' );
    is( $kuma->server, 'https://kuma.example.net:3001',                 'server' );
    is( $kuma->token,  'abc123',                                        'token' );
    is( $kuma->url,    'https://kuma.example.net:3001/api/push/abc123', 'url' );
    is( $kuma->error,  undef,                                           'error is undef' );
}

note('new( server => ... ) with trailing slash and path');
{
    my $kuma = WebService::UptimeKuma::Push->new( server => 'http://example.net/kuma//', token => 'abc' );
    is( $kuma->server, 'http://example.net/kuma',              'trailing slashes are removed' );
    is( $kuma->url,    'http://example.net/kuma/api/push/abc', 'url' );
}

note('new( url => ... )');
{
    for my $url (
        'https://kuma.example.net:3001/api/push/abc123',
        'https://kuma.example.net:3001/api/push/abc123/',
        'https://kuma.example.net:3001/api/push/abc123?status=up&msg=OK&ping=',
      )
    {
        my $kuma = WebService::UptimeKuma::Push->new( url => $url );
        is( $kuma->server, 'https://kuma.example.net:3001',                 "server from $url" );
        is( $kuma->token,  'abc123',                                        "token from $url" );
        is( $kuma->url,    'https://kuma.example.net:3001/api/push/abc123', "url from $url" );
    }
}

note('token is escaped');
{
    my $kuma = WebService::UptimeKuma::Push->new( server => 'https://kuma.example.net', token => 'a b/c' );
    is( $kuma->url, 'https://kuma.example.net/api/push/a%20b%2Fc', 'url escapes the token' );
}

note('new( http => ... )');
{
    my $http = Local::HTTP::Mock->new( Local::HTTP::Mock->ok );
    my $kuma = WebService::UptimeKuma::Push->new( url => 'https://kuma.example.net/api/push/abc', http => $http );
    ok( $kuma->up, 'up returns true' );
    is_deeply( [ $http->urls ], ['https://kuma.example.net/api/push/abc?status=up'], 'the http object is used' );
}

note('new( timeout => ... )');
{
    my $kuma = WebService::UptimeKuma::Push->new( url => 'https://kuma.example.net/api/push/abc', timeout => 3 );
    isa_ok( $kuma, 'WebService::UptimeKuma::Push', 'new returned object' );
}

#
done_testing();

exit 0;
