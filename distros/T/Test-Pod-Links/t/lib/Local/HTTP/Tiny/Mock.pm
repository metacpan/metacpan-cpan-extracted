# vim: ts=4 sts=4 sw=4 et: syntax=perl
#
# Copyright (c) 2018-2026 Sven Kirmess
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

package Local::HTTP::Tiny::Mock;

our $VERSION = '0.001';

## no critic (CodeLayout::RequireTrailingCommaAtNewline)
## no critic (ErrorHandling::RequireCarping)
## no critic (ValuesAndExpressions::ProhibitEmptyQuotes
## no critic (ValuesAndExpressions::ProhibitImplicitNewlines)
## no critic (ValuesAndExpressions::ProhibitNoisyQuotes)

sub new {
    my $class = shift;
    return bless { history => [], get_history => [] }, $class;
}

my %HEAD;
my %GET;

sub head {
    my ( $self, $url ) = @_;

    die "URL '$url' is not cached" if !exists $HEAD{$url};

    push @{ $self->{history} }, $url;

    return $HEAD{$url};
}

sub get {
    my ( $self, $url ) = @_;

    die "URL '$url' is not cached for GET" if !exists $GET{$url};

    push @{ $self->{get_history} }, $url;

    return $GET{$url};
}

sub history {
    my ($self) = @_;

    return @{ $self->{history} };
}

sub get_history {
    my ($self) = @_;

    return @{ $self->{get_history} };
}

# perl -e 'use HTTP::Tiny; use Data::Dumper; print Dumper(HTTP::Tiny->new->head(q{https://www.perl.com/}));'
$HEAD{'https://www.perl.com/'} = {
    'headers' => {
        'content-length'            => '34005',
        'last-modified'             => 'Tue, 03 Apr 2018 02:02:18 GMT',
        'server'                    => 'nginx/1.13.7',
        'strict-transport-security' => 'max-age=15768000',
        'etag'                      => '"5ac2e0aa-84d5"',
        'content-type'              => 'text/html; charset=utf-8',
        'accept-ranges'             => 'bytes',
        'date'                      => 'Thu, 05 Apr 2018 22:50:21 GMT'
    },
    'url'      => 'https://www.perl.com/',
    'success'  => 1,
    'status'   => '200',
    'reason'   => 'OK',
    'protocol' => 'HTTP/1.1'
};

# perl -e 'use HTTP::Tiny; use Data::Dumper; print Dumper(HTTP::Tiny->new->head(q{https://metacpan.org/}));'
$HEAD{'https://metacpan.org/'} = {
    'success' => 1,
    'status'  => '200',
    'headers' => {
        'x-runtime'     => '0.012686',
        'x-timer'       => 'S1522968843.555952,VS0,VE0',
        'x-served-by'   => 'cache-lax8643-LAX, cache-hhn1545-HHN',
        'accept-ranges' => 'bytes',
        'via'           => [
            '1.1 varnish',
            '1.1 varnish'
        ],
        'content-type'        => 'text/html; charset=utf-8',
        'fastly-debug-digest' => '41c60e499702ce5b59471b9153e25a9ccc17f0887904eabc77efaf500adbe74d',
        'vary'                => 'Accept-Encoding',
        'server'              => 'nginx',
        'x-cache'             => 'HIT, HIT',
        'content-length'      => '13923',
        'date'                => 'Thu, 05 Apr 2018 22:54:02 GMT',
        'connection'          => 'keep-alive',
        'x-cache-hits'        => '1, 1277',
        'age'                 => '1413159',
        'cache-control'       => 'max-age=3600'
    },
    'protocol' => 'HTTP/1.1',
    'url'      => 'https://metacpan.org/',
    'reason'   => 'OK'
};

# perl -e 'use HTTP::Tiny; use Data::Dumper; print Dumper(HTTP::Tiny->new->head(q{http://cpanmin.us/}));'
$HEAD{'http://cpanmin.us/'} = {
    'reason'  => 'OK',
    'success' => 1,
    'url'     => 'http://cpanmin.us/',
    'headers' => {
        'content-security-policy'     => 'default-src \'none\'; style-src \'unsafe-inline\'; sandbox',
        'x-cache'                     => 'MISS, HIT',
        'expires'                     => 'Wed, 04 Apr 2018 16:02:51 GMT',
        'x-fastly-request-id'         => 'c6ae3d6f15c0d2e948539d73715380bee338617d',
        'x-cache-hits'                => '0, 1',
        'x-github-request-id'         => '1238:351B:67B7F:6CFA4:5AC4F5FE',
        'x-served-by'                 => 'cache-hhn1547-HHN, cache-hhn1521-HHN',
        'age'                         => '8',
        'content-length'              => '305338',
        'fastly-debug-digest'         => 'bba650958a21f2868bfac60b2c744937a01da1469e3f622a590ee63ad3806ab1',
        'x-geo-block-list'            => '',
        'cache-control'               => 'max-age=300',
        'source-age'                  => '0',
        'date'                        => 'Thu, 05 Apr 2018 22:54:53 GMT',
        'access-control-allow-origin' => '*',
        'x-timer'                     => 'S1522968893.020961,VS0,VE13',
        'vary'                        => 'Authorization,Accept-Encoding',
        'connection'                  => 'keep-alive',
        'x-xss-protection'            => '1; mode=block',
        'x-frame-options'             => 'deny',
        'etag'                        => '"7f81ee80ff791bee22137c232511f07adb38bbe2"',
        'accept-ranges'               => 'bytes',
        'content-type'                => 'text/plain; charset=utf-8',
        'via'                         => [
            '1.1 varnish',
            '1.1 varnish'
        ],
        'x-content-type-options' => 'nosniff'
    },
    'protocol' => 'HTTP/1.1',
    'status'   => '200'
};

# perl -e 'use HTTP::Tiny; use Data::Dumper; print Dumper(HTTP::Tiny->new->head(q{https://www.cpan.org/}));'
$HEAD{'https://www.cpan.org/'} = {
    'status'   => '200',
    'reason'   => 'OK',
    'protocol' => 'HTTP/1.1',
    'url'      => 'https://www.cpan.org/',
    'headers'  => {
        'content-length'            => '8497',
        'x-timer'                   => 'S1522968933.593499,VS0,VE0',
        'x-cache'                   => 'HIT',
        'via'                       => '1.1 varnish',
        'vary'                      => 'Accept-Encoding',
        'date'                      => 'Thu, 05 Apr 2018 22:55:32 GMT',
        'connection'                => 'keep-alive',
        'x-cache-hits'              => '2',
        'accept-ranges'             => 'bytes',
        'content-type'              => 'text/html',
        'etag'                      => '"2131-56921a5f9c4c0"',
        'cache-control'             => 'public, max-age=900, stale-while-revalidate=90, stale-if-error=172800',
        'strict-transport-security' => 'max-age=15724800;',
        'age'                       => '366',
        'x-served-by'               => 'cache-hhn1547-HHN',
        'server'                    => 'Apache/2.4.29 (Unix)',
        'last-modified'             => 'Thu, 05 Apr 2018 22:42:03 GMT'
    },
    'success' => 1
};

# perl -e 'use HTTP::Tiny; use Data::Dumper; print Dumper(HTTP::Tiny->new->head(q{http://192.0.2.7/}));'
$HEAD{'http://192.0.2.7/'} = {
    'url'     => 'http://192.0.2.7/',
    'success' => '',
    'reason'  => 'Internal Exception',
    'content' => 'Could not connect to \'192.0.2.7:80\': Connection timed out
',
    'headers' => {
        'content-type'   => 'text/plain',
        'content-length' => 58
    },
    'status' => 599
};

# news.ycombinator.com answers HEAD requests with a '405 Not Allowed' but
# serves the same URL on a GET request.
# perl -e 'use HTTP::Tiny; use Data::Dumper; print Dumper(HTTP::Tiny->new->head(q{https://news.ycombinator.com/}));'
$HEAD{'https://news.ycombinator.com/'} = {
    'headers' => {
        'connection'     => 'keep-alive',
        'content-length' => '150',
        'content-type'   => 'text/html; charset=utf-8',
        'date'           => 'Wed, 09 Sep 2026 12:52:21 GMT',
        'server'         => 'nginx'
    },
    'url'      => 'https://news.ycombinator.com/',
    'success'  => '',
    'status'   => '405',
    'reason'   => 'Not Allowed',
    'protocol' => 'HTTP/1.1'
};

# perl -e 'use HTTP::Tiny; use Data::Dumper; print Dumper(HTTP::Tiny->new->get(q{https://news.ycombinator.com/}));'
# (the content was removed)
$GET{'https://news.ycombinator.com/'} = {
    'headers' => {
        'cache-control'             => 'private; max-age=0',
        'connection'                => 'keep-alive',
        'content-type'              => 'text/html; charset=utf-8',
        'date'                      => 'Wed, 09 Sep 2026 12:52:21 GMT',
        'referrer-policy'           => 'origin',
        'server'                    => 'nginx',
        'strict-transport-security' => 'max-age=31556900',
        'transfer-encoding'         => 'chunked',
        'vary'                      => 'Accept-Encoding',
        'x-content-type-options'    => 'nosniff',
        'x-frame-options'           => 'DENY',
        'x-xss-protection'          => '1; mode=block'
    },
    'url'      => 'https://news.ycombinator.com/',
    'success'  => 1,
    'status'   => '200',
    'reason'   => 'OK',
    'protocol' => 'HTTP/1.1'
};

# A URL that is broken for HEAD and for GET.
$HEAD{'https://www.example.net/not_found'} = {
    'headers' => {
        'content-type' => 'text/html; charset=utf-8',
        'server'       => 'nginx'
    },
    'url'      => 'https://www.example.net/not_found',
    'success'  => '',
    'status'   => '405',
    'reason'   => 'Not Allowed',
    'protocol' => 'HTTP/1.1'
};

$GET{'https://www.example.net/not_found'} = {
    'headers' => {
        'content-type' => 'text/html; charset=utf-8',
        'server'       => 'nginx'
    },
    'url'      => 'https://www.example.net/not_found',
    'success'  => '',
    'status'   => '404',
    'reason'   => 'Not Found',
    'protocol' => 'HTTP/1.1'
};

1;
