#!/usr/bin/perl

use strict;
use warnings;
use Benchmark qw/:all/;
use URI;
use URI::Escape;
use URL::Encode::XS qw/url_encode/;
use WWW::Form::UrlEncoded::XS qw/build_urlencoded/;

my $base = q!http://api.example.com!;
my $path = q!/path/to/endpoint!;
my %param = (
    token => 'b a r',
    message => 'foo bar baz hoge hoge hoge hoge hogehoge',
    hoge => '日本語ですよー',
    arrayref => [qw/1 2 5/]
);

warn build_urlencoded(
    s_id => 1,
    type => 'foo',
    hoge => "bar",
    %param
);

cmpthese(timethese(-2, {
    'use_uri' => sub {
        my $uri = URI->new($base . $path);
        $uri->query_form(
            s_id => 1,
            type => 'foo',
            %param
        );
        $uri->as_string;
    },
    'concat_uri_escape' => sub {
        my @qs = (
            s_id => 1,
            type => 'foo',
            %param
        );
        my $uri = $base . $path . '?';
        while ( @qs ) {
            my $k = shift @qs;
            my $v = shift @qs;
            if ( ref $v && ref $v eq 'ARRAY') {
                $uri .= uri_escape($k) . '='. uri_escape($_) . '&' for @$v;
            }
            else {
                $uri .= uri_escape($k) . '='. uri_escape($v) . '&'
            }
        }
        substr($uri,-1,1,"");
        $uri;

    },
    'concat_url_encode_xs' => sub {
        my @qs = (
            s_id => 1,
            type => 'foo',
            %param
        );
        my $uri = $base . $path . '?';
        while ( @qs ) {
            my $k = shift @qs;
            my $v = shift @qs;
            if ( ref $v && ref $v eq 'ARRAY') {
                $uri .= url_encode($k) . '='. url_encode($_) . '&' for @$v;
            }
            else {
                $uri .= url_encode($k) . '='. url_encode($v) . '&'
            }
        }
        substr($uri,-1,1,"");
        $uri;
    },
    'build_urlencoded_xs' => sub {
        my $uri = $base . $path . '?' . build_urlencoded(
            s_id => 1,
            type => 'foo',
            %param
        );
        $uri;
    },
    'use_uri2' => sub {
        my $uri = URI->new($base . $path . "?" . build_urlencoded(
            s_id => 1,
            type => 'foo',
            %param
        ));
        $uri->as_string;
    },

}));

__END__
Benchmark: running build_urlencoded_xs, concat_uri, concat_url_encode_xs, use_uri for at least 2 CPU seconds...
build_urlencoded_xs:  2 wallclock secs ( 2.08 usr +  0.00 sys =  2.08 CPU) @ 482635.58/s (n=1003882)
concat_uri:  3 wallclock secs ( 2.21 usr +  0.00 sys =  2.21 CPU) @ 19460.18/s (n=43007)
concat_url_encode_xs:  3 wallclock secs ( 2.12 usr +  0.00 sys =  2.12 CPU) @ 119165.09/s (n=252630)
   use_uri:  2 wallclock secs ( 2.17 usr +  0.00 sys =  2.17 CPU) @ 12387.10/s (n=26880)
                         Rate use_uri concat_uri concat_url_encode_xs build_urlencoded_xs
use_uri               12387/s      --       -36%                 -90%                -97%
concat_uri            19460/s     57%         --                 -84%                -96%
concat_url_encode_xs 119165/s    862%       512%                   --                -75%
build_urlencoded_xs  482636/s   3796%      2380%                 305%                  --
