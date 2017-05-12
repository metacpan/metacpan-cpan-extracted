#!/usr/bin/perl
use strict;
use warnings;

use Benchmark qw/cmpthese/;
use URI::Escape;
use URI::Escape::XS;
use URI::XSEscape;

my $orig_text = 'I said this: you / them ~ us & me _will_ "do-it" NOW!';
my $orig_utf8 = 'http://www.google.co.jp/search?q=小飼弾';
my $orig_code = 'I%20said%20this%3a%20you%20%2f%20them%20~%20us%20%26%20me%20_will_%20%22do-it%22%20NOW%21';

my $orig_in = '!:/~&_-';
my $orig_ni = '^a-zA-Z0-9';

my @cases = (
    uri_escape => sub {
        cmpthese(
            1000000 => {
                'URI::Escape'     => sub {     URI::Escape::uri_escape($orig_text) },
                'URI::Escape::XS' => sub { URI::Escape::XS::uri_escape($orig_text) },
                'URI::XSEscape'   => sub {   URI::XSEscape::uri_escape($orig_text) },
            },
        );
    },
    uri_escape_in => sub {
        cmpthese(
            1000000 => {
                'URI::Escape'     => sub {     URI::Escape::uri_escape($orig_text, $orig_in) },
                'URI::Escape::XS' => sub { URI::Escape::XS::uri_escape($orig_text, $orig_in) },
                'URI::XSEscape'   => sub {   URI::XSEscape::uri_escape($orig_text, $orig_in) },
            },
        );
    },
    uri_escape_not_in => sub {
        cmpthese(
            1000000 => {
                'URI::Escape'     => sub {     URI::Escape::uri_escape($orig_text, $orig_ni) },
                'URI::Escape::XS' => sub { URI::Escape::XS::uri_escape($orig_text, $orig_ni) },
                'URI::XSEscape'   => sub {   URI::XSEscape::uri_escape($orig_text, $orig_ni) },
            },
        );
    },
    uri_escape_utf8 => sub {
        cmpthese(
            1000000 => {
                'URI::Escape'     => sub {     URI::Escape::uri_escape_utf8($orig_utf8) },
              # 'URI::Escape::XS' => sub { URI::Escape::XS::uri_escape_utf8($orig_utf8) },
                'URI::XSEscape'   => sub {   URI::XSEscape::uri_escape_utf8($orig_utf8) },
            },
        );
    },
    uri_unescape => sub {
        cmpthese(
            1000000 => {
                'URI::Escape'     => sub {     URI::Escape::uri_unescape($orig_code) },
                'URI::Escape::XS' => sub { URI::Escape::XS::uri_unescape($orig_code) },
                'URI::XSEscape'   => sub {   URI::XSEscape::uri_unescape($orig_code) },
            },
        );
    },
);

exit main(@ARGV);

sub main {
    my @argv = @_;

    my $only = shift @argv;
    my @versions = map { sprintf("%s %s", $_, $_->VERSION) } qw{URI::Escape URI::Escape::XS URI::XSEscape};
    print join(' / ', @versions), "\n";

    while (my ($name, $code) = splice(@cases, 0, 2)) {
        next if $only && $only ne $name;
        print "-- $name\n";
        $code->();
        print "\n";
    }
    return 0;
}

