#!/usr/bin/perl

use strict;
use warnings;
use Benchmark qw/:all/;
use WWW::Form::UrlEncoded;
use WWW::Form::UrlEncoded::PP;
use URL::Encode::XS;
use Text::QueryString;


my @query_string = (
    "foo=bar",
    "foo=bar&bar=1",
    "foo=bar;bar=1",
    "foo=bar&foo=baz",
    "foo=bar&foo=baz&bar=baz",
    "foo_only",
    "foo&bar=baz",
    '%E6%97%A5%E6%9C%AC%E8%AA%9E=%E3%81%AB%E3%81%BB%E3%82%93%E3%81%94&%E3%81%BB%E3%81%92%E3%81%BB%E3%81%92=%E3%81%B5%E3%81%8C%E3%81%B5%E3%81%8C',
);

my $xs = Text::QueryString->new;

cmpthese(timethese(-1, {
    text_qs => sub {
        foreach my $qs (@query_string) {
            my @q = $xs->parse($qs);
        }
    },
    wwwform_xs => sub {
        foreach my $qs (@query_string) {
            my @q = WWW::Form::UrlEncoded::XS::parse_urlencoded($qs);
        }
    },
    wwwform_xs_ref => sub {
        foreach my $qs (@query_string) {
            my $q = WWW::Form::UrlEncoded::XS::parse_urlencoded_arrayref($qs);
        }
    },
    wwwform_pp => sub {
        foreach my $qs (@query_string) {
            my @q = WWW::Form::UrlEncoded::PP::parse_urlencoded($qs);
        }
    },
    urlencode_xs => sub {
        foreach my $qs (@query_string) {
            my $q = URL::Encode::XS::url_params_flat($qs);
        }
    },
}));


__END__
Benchmark: running text_qs, urlencode_xs, wwwform_pp, wwwform_xs, wwwform_xs_ref for at least 1 CPU seconds...
   text_qs:  1 wallclock secs ( 1.11 usr +  0.00 sys =  1.11 CPU) @ 51661.26/s (n=57344)
urlencode_xs:  1 wallclock secs ( 1.11 usr +  0.00 sys =  1.11 CPU) @ 96863.96/s (n=107519)
wwwform_pp:  1 wallclock secs ( 1.15 usr +  0.00 sys =  1.15 CPU) @ 10387.83/s (n=11946)
wwwform_xs:  2 wallclock secs ( 1.10 usr +  0.00 sys =  1.10 CPU) @ 86884.55/s (n=95573)
wwwform_xs_ref:  1 wallclock secs ( 1.06 usr +  0.00 sys =  1.06 CPU) @ 95466.98/s (n=101195)
                  Rate wwwform_pp text_qs wwwform_xs wwwform_xs_ref urlencode_xs
wwwform_pp     10388/s         --    -80%       -88%           -89%         -89%
text_qs        51661/s       397%      --       -41%           -46%         -47%
wwwform_xs     86885/s       736%     68%         --            -9%         -10%
wwwform_xs_ref 95467/s       819%     85%        10%             --          -1%
urlencode_xs   96864/s       832%     87%        11%             1%           --



