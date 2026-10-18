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

use Local::HTTP::Mock;
use Local::Test::Exception qw(exception);

use WebService::UptimeKuma::Push;

my $url = 'https://kuma.example.net/api/push/abc';

note('missing arguments');
{
    like( exception { WebService::UptimeKuma::Push->new }, qr{\QMissing argument: 'server'\E}, 'new throws an exception without arguments' );
    like( exception { WebService::UptimeKuma::Push->new( server => 'https://kuma.example.net' ) },               qr{\QMissing argument: 'token'\E},  'new throws an exception without token' );
    like( exception { WebService::UptimeKuma::Push->new( token  => 'abc' ) },                                    qr{\QMissing argument: 'server'\E}, 'new throws an exception without server' );
    like( exception { WebService::UptimeKuma::Push->new( server => 'https://kuma.example.net', token => q{} ) }, qr{\QMissing argument: 'token'\E},  'new throws an exception with empty token' );
}

note('odd number of arguments');
{
    like( exception { WebService::UptimeKuma::Push->new($url) }, qr{\Qusage: new( url => URL, [ARGS] )\E}, 'new throws an exception with an odd number of arguments' );
}

note('invalid url');
{
    like( exception { WebService::UptimeKuma::Push->new( url => undef ) }, qr{\Qurl must be defined\E}, 'new throws an exception with undefined url' );

    for my $invalid ( 'https://kuma.example.net/', 'https://kuma.example.net/api/push/', 'ftp://kuma.example.net/api/push/abc', 'kuma.example.net/api/push/abc' ) {
        like( exception { WebService::UptimeKuma::Push->new( url => $invalid ) }, qr{\QNot an Uptime Kuma push URL: '$invalid'\E}, "new throws an exception for url $invalid" );
    }

    like( exception { WebService::UptimeKuma::Push->new( url => $url, token  => 'abc' ) },                      qr{\QCannot specify url together with server or token\E}, 'new throws an exception with url and token' );
    like( exception { WebService::UptimeKuma::Push->new( url => $url, server => 'https://kuma.example.net' ) }, qr{\QCannot specify url together with server or token\E}, 'new throws an exception with url and server' );
}

note('invalid server');
{
    like( exception { WebService::UptimeKuma::Push->new( server => 'kuma.example.net', token => 'abc' ) }, qr{\Qserver must be a http or https URL: 'kuma.example.net'\E}, 'new throws an exception for server without scheme' );
}

note('invalid http / timeout');
{
    like( exception { WebService::UptimeKuma::Push->new( url => $url, http => {} ) }, qr{\Qhttp must be an object with a get method\E}, 'new throws an exception if http is not an object' );
    like( exception { WebService::UptimeKuma::Push->new( url => $url, http => bless {},               'Local::Nothing' ) }, qr{\Qhttp must be an object with a get method\E},  'new throws an exception if http has no get method' );
    like( exception { WebService::UptimeKuma::Push->new( url => $url, http => Local::HTTP::Mock->new, timeout => 3 ) },     qr{\QCannot specify http together with timeout\E}, 'new throws an exception with http and timeout' );

    for my $timeout ( undef, 0, -1, 'abc', q{} ) {
        my $name = defined $timeout ? "'$timeout'" : 'undef';
        like( exception { WebService::UptimeKuma::Push->new( url => $url, timeout => $timeout ) }, qr{\Qtimeout must be a positive number\E}, "new throws an exception with timeout $name" );
    }
}

note('unknown arguments');
{
    like( exception { WebService::UptimeKuma::Push->new( url => $url, invalid_argument => 17 ) }, qr{\QUnknown argument: 'invalid_argument'\E}, 'new throws an exception for an invalid argument' );
    like( exception { WebService::UptimeKuma::Push->new( url => $url, invalid_argument => 17, another_arg => 1 ) }, qr{\QUnknown arguments: 'another_arg', 'invalid_argument'\E}, 'new throws an exception for invalid arguments' );
}

#
done_testing();

exit 0;
